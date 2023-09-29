CREATE USER [ts1-testing-dev-ingest-datafactory1] FROM EXTERNAL PROVIDER;
GO

ALTER ROLE db_datareader ADD MEMBER [ts1-testing-dev-ingest-datafactory1];
ALTER ROLE db_datawriter ADD MEMBER [ts1-testing-dev-ingest-datafactory1];
GO
