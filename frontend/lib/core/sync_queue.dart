enum SyncState { pending, synced, failed }

class SyncItem {
  final String clientId;
  final String type;
  final String payloadJson;
  SyncState state;
  int attempts;
  String? lastError;
  SyncItem({required this.clientId, required this.type, required this.payloadJson, this.state = SyncState.pending, this.attempts = 0, this.lastError});
  Map<String, dynamic> toJson() => {'client_id': clientId, 'type': type, 'payload_json': payloadJson};
}

class SyncQueue {
  final List<SyncItem> _queue = [];
  List<SyncItem> get pending => _queue.where((e) => e.state == SyncState.pending).toList();
  void enqueue(SyncItem item) => _queue.add(item);
  void markSynced(String clientId) {
    final i = _queue.indexWhere((e) => e.clientId == clientId);
    if (i != -1) _queue[i].state = SyncState.synced;
  }
}
