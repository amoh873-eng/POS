import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/money_display.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  List _accounts = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final r = await widget.api.get('/api/accounting/accounts');
      if (!mounted) return;
      setState(() { _accounts = r['data'] ?? []; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  Future<void> _seed() async {
    try {
      await widget.api.get('/api/accounting/seed-basic');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شجرة الحسابات'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (_accounts.isEmpty && !_loading)
            TextButton.icon(onPressed: _seed, icon: const Icon(Icons.auto_fix_high, color: Colors.white), label: const Text('إنشاء شجرة افتراضية', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(child: Text(_err!, style: const TextStyle(color: Colors.red)))
              : _accounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('لا توجد حسابات بعد', style: TextStyle(color: Colors.grey, fontSize: 18)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _seed, child: const Text('بدء تهيئة شجرة الحسابات')),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) => _AccountNode(account: _accounts[index]),
                    ),
    );
  }
}

class _AccountNode extends StatefulWidget {
  const _AccountNode({required this.account, this.level = 0});
  final Map account;
  final int level;

  @override
  State<_AccountNode> createState() => _AccountNodeState();
}

class _AccountNodeState extends State<_AccountNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final children = (widget.account['children'] as List?) ?? [];
    final hasChildren = children.isNotEmpty;
    final isGroup = widget.account['isGroup'] ?? false;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16, right: 16 + (widget.level * 20.0)),
          leading: Icon(
            isGroup ? (hasChildren && _expanded ? Icons.folder_open : Icons.folder) : Icons.account_balance_wallet,
            color: isGroup ? Colors.amber : Colors.blue,
          ),
          title: Text(
            '${widget.account['code']} - ${widget.account['nameAr'] ?? widget.account['name_ar']}',
            style: TextStyle(fontWeight: isGroup ? FontWeight.bold : FontWeight.normal),
          ),
          subtitle: Text(widget.account['type'] ?? ''),
          trailing: MoneyDisplay(amount: (widget.account['balance'] ?? 0.0).toDouble()),
          onTap: hasChildren ? () => setState(() => _expanded = !_expanded) : null,
        ),
        if (hasChildren && _expanded)
          ...children.map((child) => _AccountNode(account: child, level: widget.level + 1)),
        const Divider(height: 1),
      ],
    );
  }
}
