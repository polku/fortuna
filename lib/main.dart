import 'package:flutter/material.dart';
import 'db_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Investment Tracker',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PortfolioPage(),
    const BuyOperationPage(),
    const OperationsListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Operations',
          ),
        ],
      ),
    );
  }
}

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DbHelper.instance.getPositions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No positions'));
          }
          final positions = snapshot.data!;
          double total = 0;
          for (var p in positions) {
            final qty = p['quantity'] as num;
            total += qty * 100;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total: \u20ac${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    final pos = positions[index];
                    final qty = pos['quantity'] as num;
                    final value = qty * 100;
                    return ListTile(
                      title: Text(pos['isin']),
                      subtitle: Text('Qty: ${qty.toString()}'),
                      trailing:
                          Text('\u20ac${value.toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BuyOperationPage extends StatefulWidget {
  const BuyOperationPage({Key? key}) : super(key: key);

  @override
  _BuyOperationPageState createState() => _BuyOperationPageState();
}

class _BuyOperationPageState extends State<BuyOperationPage> {
  final _formKey = GlobalKey<FormState>();
  final _isinController = TextEditingController();
  final _valueController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _isinController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveOperation() async {
    if (_formKey.currentState?.validate() != true || _selectedDate == null) {
      return;
    }
    await DbHelper.instance.insertOperation({
      'isin': _isinController.text,
      'date': _selectedDate!.millisecondsSinceEpoch,
      'value_unit': double.parse(_valueController.text),
      'quantity': double.parse(_quantityController.text),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Operation saved')),
    );
    _formKey.currentState?.reset();
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Buy Operation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _isinController,
                decoration: const InputDecoration(labelText: 'ISIN'),
                validator: (v) => v == null || v.isEmpty ? 'Enter ISIN' : null,
              ),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Unit Value'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.isEmpty ? 'Enter value' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.isEmpty ? 'Enter quantity' : null,
              ),
              Row(
                children: [
                  Text(_selectedDate == null
                      ? 'No date chosen'
                      : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text('Select Date'),
                  )
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveOperation,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OperationsListPage extends StatefulWidget {
  const OperationsListPage({Key? key}) : super(key: key);

  @override
  State<OperationsListPage> createState() => _OperationsListPageState();
}

class _OperationsListPageState extends State<OperationsListPage> {
  late Future<List<Map<String, dynamic>>> _operations;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _operations = DbHelper.instance.getOperations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operations')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _operations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No operations'));
          }
          final ops = snapshot.data!;
          return ListView.builder(
            itemCount: ops.length,
            itemBuilder: (context, index) {
              final op = ops[index];
              final date = DateTime.fromMillisecondsSinceEpoch(op['date']);
              return ListTile(
                title: Text(op['isin']),
                subtitle: Text(
                    "${date.toLocal().toString().split(' ')[0]} - ${op['quantity']} x ${op['value_unit']}")
              );
            },
          );
        },
      ),
    );
  }
}
