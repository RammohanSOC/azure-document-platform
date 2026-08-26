# document-processor Function App — settings

Identity-based Service Bus trigger requires these app settings (already wired via
Terraform outputs where noted):

| App Setting                              | Value                                             |
|-------------------------------------------|----------------------------------------------------|
| `SERVICEBUS_CONNECTION__fullyQualifiedNamespace` | `${SERVICEBUS_FQDN}` (Terraform output)     |
| `SQL_SERVER_FQDN`                          | `module.sql.sql_server_fqdn`                       |
| `SQL_DATABASE_NAME`                        | `module.sql.sql_database_name`                     |
| `STORAGE_BLOB_ENDPOINT`                    | Key Vault reference (already set by Terraform)      |

The Function App's managed identity needs "Azure Service Bus Data Owner" (granted by the
servicebus module) and must be added as a contained SQL user (see `database/grant-access.sql`).
