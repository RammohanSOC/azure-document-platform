const { app } = require('@azure/functions');
const { BlobServiceClient } = require('@azure/storage-blob');
const { DefaultAzureCredential } = require('@azure/identity');
const sql = require('mssql');

// Service Bus trigger: consumes document-processing queue messages.
// Reads the blob, "processes" it (placeholder validation), writes the
// result to Azure SQL, then moves the blob to processed/ or rejected/.
// On unhandled exception the function throws -> Service Bus redelivers
// per max_delivery_count, then dead-letters automatically.
app.serviceBusQueue('serviceBusQueueTrigger', {
  connection: 'SERVICEBUS_CONNECTION', // configured for identity-based connection in host.json
  queueName: process.env.SERVICEBUS_QUEUE_NAME || 'document-processing',
  handler: async (message, context) => {
    const { documentId, blobPath, fileName, fileSizeBytes, uploadedAt } = message;
    context.log(`Processing document ${documentId} (${fileName})`);

    const credential = new DefaultAzureCredential();
    const blobServiceClient = new BlobServiceClient(process.env.STORAGE_BLOB_ENDPOINT, credential);

    const sourceContainer = blobServiceClient.getContainerClient('incoming');
    const sourceBlob = sourceContainer.getBlockBlobClient(fileName);

    let status = 'processed';
    let processingResult = 'OK';

    try {
      const exists = await sourceBlob.exists();
      if (!exists) {
        throw new Error(`Blob ${fileName} not found in incoming/`);
      }

      // --- placeholder document validation/processing logic goes here ---
      if (fileSizeBytes === 0) {
        status = 'rejected';
        processingResult = 'Empty file';
      }

      const destContainer = blobServiceClient.getContainerClient(status === 'rejected' ? 'rejected' : 'processed');
      const destBlob = destContainer.getBlockBlobClient(fileName);
      await destBlob.beginCopyFromURL(sourceBlob.url);
      await sourceBlob.delete();

      await writeMetadata({
        documentId, fileName, fileSizeBytes, uploadedAt,
        blobPath: `${status}/${fileName}`, status, processingResult,
      });

      context.log(`Document ${documentId} -> ${status}`);
    } catch (err) {
      context.error(`Failed processing ${documentId}: ${err.message}`);
      throw err; // let Service Bus retry / dead-letter per queue policy
    }
  },
});

async function writeMetadata({ documentId, fileName, fileSizeBytes, uploadedAt, blobPath, status, processingResult }) {
  const credential = new DefaultAzureCredential();
  const token = await credential.getToken('https://database.windows.net/.default');

  const pool = await sql.connect({
    server: process.env.SQL_SERVER_FQDN,
    database: process.env.SQL_DATABASE_NAME,
    options: { encrypt: true },
    authentication: {
      type: 'azure-active-directory-access-token',
      options: { token: token.token },
    },
  });

  await pool.request()
    .input('documentId', sql.UniqueIdentifier, documentId)
    .input('fileName', sql.NVarChar, fileName)
    .input('fileSizeBytes', sql.BigInt, fileSizeBytes)
    .input('uploadedAt', sql.DateTime2, uploadedAt)
    .input('blobPath', sql.NVarChar, blobPath)
    .input('status', sql.NVarChar, status)
    .input('processingResult', sql.NVarChar, processingResult)
    .query(`
      MERGE Documents AS target
      USING (SELECT @documentId AS DocumentId) AS src
      ON target.DocumentId = src.DocumentId
      WHEN MATCHED THEN
        UPDATE SET Status = @status, ProcessedAt = SYSUTCDATETIME(), BlobPath = @blobPath
      WHEN NOT MATCHED THEN
        INSERT (DocumentId, FileName, FileSizeBytes, UploadedAt, ProcessedAt, BlobPath, Status)
        VALUES (@documentId, @fileName, @fileSizeBytes, @uploadedAt, SYSUTCDATETIME(), @blobPath, @status);

      INSERT INTO ProcessingResults (DocumentId, Result, CreatedAt)
      VALUES (@documentId, @processingResult, SYSUTCDATETIME());
    `);

  await pool.close();
}
