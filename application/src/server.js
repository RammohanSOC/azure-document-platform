const express = require('express');
const multer = require('multer');
const { DefaultAzureCredential } = require('@azure/identity');
const { BlobServiceClient } = require('@azure/storage-blob');

const app = express();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 25 * 1024 * 1024 } });
const credential = new DefaultAzureCredential(); // Managed Identity in Azure, az login locally

const blobServiceClient = new BlobServiceClient(process.env.STORAGE_BLOB_ENDPOINT, credential);

app.use(express.json());
app.use(express.static('public'));

// Health check — also used as the Front Door / App Service health probe path
app.get('/status', (req, res) => res.status(200).json({ status: 'healthy' }));

app.post('/login', (req, res) => {
  // Placeholder: wire to Entra ID / MSAL for real auth. Out of scope for this sample.
  res.status(501).json({ message: 'Wire this up to Entra ID (MSAL) auth code flow.' });
});

app.post('/upload', upload.single('document'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file provided' });

    const containerClient = blobServiceClient.getContainerClient('incoming');
    const blockBlobClient = containerClient.getBlockBlobClient(req.file.originalname);
    await blockBlobClient.uploadData(req.file.buffer);

    res.status(202).json({ message: 'Uploaded, queued for processing', fileName: req.file.originalname });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Upload failed' });
  }
});

app.get('/documents', async (req, res) => {
  // Placeholder: query Documents table via mssql + AAD managed identity token,
  // same pattern as functions/document-processor/src/functions/serviceBusQueueTrigger.js
  res.status(501).json({ message: 'Wire this up to Azure SQL — see document-processor for the pattern.' });
});

app.get('/documents/:id/status', async (req, res) => {
  res.status(501).json({ message: 'Query Documents table by DocumentId.' });
});

app.get('/documents/:id/download', async (req, res) => {
  res.status(501).json({ message: 'Stream from processed/ container by blob path looked up via SQL.' });
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`docplat-web listening on ${port}`));
