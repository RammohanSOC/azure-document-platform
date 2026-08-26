-- Grant Managed Identity access to Azure SQL (run once per environment as the
-- AAD admin — replace names with your actual App Service / Function App names).
-- This is why the SQL connection string in Key Vault uses
-- "Authentication=Active Directory Managed Identity" instead of a SQL login.

CREATE USER [app-docplat-dev] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [app-docplat-dev];
ALTER ROLE db_datawriter ADD MEMBER [app-docplat-dev];

CREATE USER [func-upload-docplat-dev] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [func-upload-docplat-dev];

CREATE USER [func-docproc-docplat-dev] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [func-docproc-docplat-dev];
ALTER ROLE db_datawriter ADD MEMBER [func-docproc-docplat-dev];
