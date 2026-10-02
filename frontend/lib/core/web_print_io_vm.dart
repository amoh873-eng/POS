// Non-web implementation: thermal receipt printing requires a browser
// print dialog, so the same contract as before applies — it is a no-op
// that returns false on Android/iOS/Desktop and in VM tests.
bool printThermalReceipt(String dataUri, {int mm = 80}) => false;