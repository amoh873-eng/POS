import 'package:flutter/material.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<Map<String, dynamic>> _cart = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS')),
      body: Row(
        children: [
          Expanded(flex: 2, child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.2),
            itemCount: 12,
            itemBuilder: (_, i) => Card(child: InkWell(onTap: () => setState(() => _cart.add({'name': 'Product ${i+1}', 'price': (i+1)*10.0, 'qty': 1})), child: Center(child: Text('P${i+1}')))),
          )),
          Expanded(child: Card(margin: const EdgeInsets.all(12), child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(12), child: Text('Cart')),
              Expanded(child: ListView(children: _cart.map((e) => ListTile(title: Text(e['name']), trailing: Text('${e['price']}'))).toList())),
              Padding(padding: const EdgeInsets.all(12), child: ElevatedButton(onPressed: () {}, child: const Text('Pay'))),
            ],
          ))),
        ],
      ),
    );
  }
}
