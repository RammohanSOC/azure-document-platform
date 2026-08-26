-- Azure SQL schema for the Secure Document Processing Platform
-- Run via sqlcmd, Azure Data Studio, or a CI/CD migration step (not Terraform —
-- schema changes belong in application migrations, not infra state).

CREATE TABLE Customers (
    CustomerId      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    Name            NVARCHAR(200)    NOT NULL,
    Email           NVARCHAR(320)    NOT NULL UNIQUE,
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE Documents (
    DocumentId      UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    CustomerId      UNIQUEIDENTIFIER NULL REFERENCES Customers(CustomerId),
    FileName        NVARCHAR(400)    NOT NULL,
    FileSizeBytes   BIGINT           NOT NULL,
    BlobPath        NVARCHAR(1000)   NOT NULL,
    Status          NVARCHAR(20)     NOT NULL DEFAULT 'uploaded'
                     CHECK (Status IN ('uploaded','processing','processed','rejected')),
    UploadedAt      DATETIME2        NOT NULL,
    ProcessedAt     DATETIME2        NULL,
    CONSTRAINT UQ_Documents_BlobPath UNIQUE (BlobPath)
);
CREATE INDEX IX_Documents_Status ON Documents(Status);
CREATE INDEX IX_Documents_CustomerId ON Documents(CustomerId);

CREATE TABLE ProcessingResults (
    ResultId        BIGINT IDENTITY(1,1) PRIMARY KEY,
    DocumentId       UNIQUEIDENTIFIER NOT NULL REFERENCES Documents(DocumentId),
    Result          NVARCHAR(2000)   NOT NULL,
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE AuditLogs (
    AuditId         BIGINT IDENTITY(1,1) PRIMARY KEY,
    DocumentId       UNIQUEIDENTIFIER NULL REFERENCES Documents(DocumentId),
    Actor           NVARCHAR(200)    NOT NULL,   -- managed identity / user UPN
    Action          NVARCHAR(100)    NOT NULL,   -- e.g. 'upload', 'status-check', 'download'
    Details         NVARCHAR(2000)   NULL,
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_AuditLogs_DocumentId ON AuditLogs(DocumentId);
