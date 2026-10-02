// Non-web implementation: there is no localStorage on VM/native platforms.
// In-memory persistence lives in PrinterSettingsStore._mem, so this backend
// intentionally stays stateless while keeping the same read/write contract.
class PrinterSettingsIo {
  static Future<String?> read() async => null;

  static Future<void> write(String value) async {}
}