/// Spark cannot enable Firebase Storage. File pickers still work in the UI;
/// the bytes are not uploaded. Set to false after enabling Storage on Blaze.
const bool simulateFileUploads = true;

/// No reviewer or Functions backend. Institutions can publish without a
/// custom claim. Set to false when a trusted verification flow exists.
const bool simulateInstitutionVerification = true;
