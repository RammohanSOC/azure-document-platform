# Azure Secure Document Processing Platform

Terraform-driven, privately-networked document ingest/processing platform.
App Service (web) → Front Door + WAF → Blob (incoming/processed/rejected) →
Service Bus (`document-processing` queue, DLQ) → Functions (upload-processor,
document-processor) → Azure SQL, all secrets in Key Vault, all data-plane
traffic over Private Endpoints, egress from the Functions subnet forced
through Azure Firewall.

## Repo layout

```
terraform/
  modules/           # networking, keyvault, storage, sql, servicebus, app-service, functions, frontdoor, monitoring
  environments/dev/  # root module — wires modules together, backend, providers
application/         # Express web app (App Service)
functions/           # upload-processor, document-processor (Node v4 programming model)
database/            # schema.sql, grant-access.sql (SQL AAD user grants)
.github/workflows/   # terraform-plan, terraform-apply, application-deploy (all OIDC, no stored secrets)
```

## Known IaC nuance you should be able to explain in an interview

**App Service ↔ Front Door dependency cycle.** The App Service origin restriction
uses the `X-Azure-FDID` header to accept traffic only from *your* Front Door
instance. But Front Door's origin config needs the App Service hostname, and
the FDID restriction needs Front Door's resource GUID — a genuine two-resource
cycle. Fixed with the standard two-phase apply: `front_door_id` defaults to
`""` (restriction falls back to the `AzureFrontDoor.Backend` service tag only),
then after first apply you re-run with the real value:

```bash
terraform apply
terraform output front_door_id
terraform apply -var="front_door_id=<value-from-above>"
```

## Your task checklist

### 1 — Bootstrap remote state (one-time, per subscription)
```bash
az group create -n rg-tfstate -l centralindia
az storage account create -n sttfstatedocplat -g rg-tfstate -l centralindia \
  --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create -n tfstate --account-name sttfstatedocplat --auth-mode login
```

### 2 — Create the OIDC federated identity for GitHub Actions (no client secrets)
```bash
az ad app create --display-name "gha-docplat-dev" --query appId -o tsv
# Use the returned appId below
az ad sp create --id <appId>
az role assignment create --assignee <appId> --role Contributor \
  --scope /subscriptions/<sub-id>
az ad app federated-credential create --id <appId> --parameters '{
  "name": "gha-main-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<org>/<repo>:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```
Add `<appId>` as `AZURE_CLIENT_ID`, your tenant as `AZURE_TENANT_ID`, and the
subscription as `AZURE_SUBSCRIPTION_ID` in GitHub repo secrets. Also add
`SQL_AAD_ADMIN_LOGIN`, `SQL_AAD_ADMIN_OBJECT_ID`, `ALERT_EMAIL`,
`KV_ADMIN_OBJECT_IDS` (JSON list).

### 3 — First Terraform apply
```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars   # fill in real IDs
terraform init
terraform plan
terraform apply
```

### 4 — Close the Front Door origin-restriction loop
```bash
terraform output front_door_id
terraform apply -var="front_door_id=<value>"
```

### 5 — Grant SQL access to managed identities
```bash
sqlcmd -S $(terraform output -raw sql_server_fqdn) -d sqldb-docplat-dev \
  -G -i ../../../database/grant-access.sql   # -G = AAD interactive auth
```
Then apply `database/schema.sql` the same way.

### 6 — Deploy application + functions
Push to `main` — `application-deploy.yml` builds, `npm audit`s, zips, and
deploys via `azure/webapps-deploy` and `azure/functions-action` using the same
OIDC identity.

### 7 — Failure testing (do these, capture screenshots/logs for your portfolio)

| Test | Action | Expected |
|---|---|---|
| App outage | `az webapp stop -n app-docplat-dev -g rg-docplat-dev` | 5xx alert fires within ~15 min window |
| Poison message | Publish a malformed message to `document-processing` via Service Bus Explorer | Retries up to `max_delivery_count=5`, then lands in `$DeadLetterQueue`, DLQ alert fires immediately |
| Key Vault lockout | Remove the document-processor Function's "Key Vault Secrets User" role assignment | Function throws on SQL connection resolution; shows in App Insights `exceptions` |
| WAF | `curl "https://<front-door-hostname>/?id=1' OR '1'='1"` | 403 from Front Door, entry in `FrontDoorWebApplicationFirewallLog` |
| Storage lockdown | Confirm `az storage account show -n <name> --query publicNetworkAccess` returns `Disabled` | App still works (goes over Private Endpoint); direct public blob URL access fails |

### 8 — DR (South India secondary, optional/next phase)
Duplicate `terraform/environments/dev` as `environments/dr` with
`location = "southindia"`, point it at Geo-Replicated SQL / RA-GRS storage
already configured (`geo_backup_enabled = true`, `GRS` replication in this
codebase), and test:
```bash
az sql db failover-group set-primary --name <fg-name> -g rg-docplat-dev --allow-data-loss
```

## Cost-conscious defaults already applied

- SQL: `GP_S_Gen5_1` **serverless**, `min_capacity = 0.5`, auto-pause after 60 min
- Service Bus: **Premium** (required for Private Endpoints) — the one line item
  you can't shrink further and still get PEs; drop to Standard + service
  endpoints instead if you want to cut this cost during early iteration
- Firewall: `enable_firewall = false` lets you skip Azure Firewall (~$1.25/hr)
  entirely while iterating on the rest of the stack
