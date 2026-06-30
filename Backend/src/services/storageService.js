const storageProvider = require('./storageProvider');

/**
 * Uploads a file buffer to the active storage provider.
 * Keeps backward compatible signature for existing controllers.
 */
exports.uploadFile = async (fileBuffer, folder, options = {}) => {
  return storageProvider.upload(fileBuffer, folder, options);
};

/**
 * Generates a signed URL for private download retrieval.
 */
exports.getSignedUrl = (publicId, expiresInSeconds = 300) => {
  return storageProvider.getSignedUrl(publicId, expiresInSeconds);
};

/**
 * Deletes a file from the active storage provider.
 */
exports.deleteFile = async (publicId, resourceType = 'image') => {
  return storageProvider.delete(publicId, resourceType);
};
