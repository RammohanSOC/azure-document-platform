const { app } = require('@azure/functions');
const { ServiceBusClient } = require('@azure/service-bus');
const { DefaultAzureCredential } = require('@azure/identity');

// Blob trigger: fires on any new blob landing in incoming/.
// Publishes a lightweight message onto the document-processing queue —
// the Document Processor function does the actual work (keeps this
// function thin, so retries/backpressure live in Service Bus, not here).
app.storageBlob('blobUploadTrigger', {
  path: 'incoming/{name}',
  connection: 'AzureWebJobsStorage',
  handler: async (blob, context) => {
    const blobName = context.triggerMetadata.name;
    context.log(`New blob detected: ${blobName}, size: ${blob.length} bytes`);

    const sbNamespace = process.env.SERVICEBUS_FQDN;
    const queueName = process.env.SERVICEBUS_QUEUE_NAME;
    const credential = new DefaultAzureCredential(); // managed identity in Azure

    const sbClient = new ServiceBusClient(sbNamespace, credential);
    const sender = sbClient.createSender(queueName);

    try {
      await sender.sendMessages({
        body: {
          documentId: crypto.randomUUID(),
          blobPath: `incoming/${blobName}`,
          fileName: blobName,
          fileSizeBytes: blob.length,
          uploadedAt: new Date().toISOString(),
        },
        contentType: 'application/json',
        messageId: blobName, // duplicate detection uses this within the 10-min window
      });
      context.log(`Queued ${blobName} for processing`);
    } finally {
      await sender.close();
      await sbClient.close();
    }
  },
});
