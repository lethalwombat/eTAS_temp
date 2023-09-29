CREATE USER [data_factory] FROM EXTERNAL PROVIDER;
GO

ALTER ROLE db_datareader ADD MEMBER [data_factory];
ALTER ROLE db_datawriter ADD MEMBER [data_factory];
GO
