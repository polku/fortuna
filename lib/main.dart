import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Widget _buildPage() {
    switch (_currentIndex) {
      case 0:
        return const PortfolioPage();
      case 1:
        return const BuyOperationPage();
      case 2:
        return const OperationsListPage();
      default:
        return const PortfolioPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
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

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({Key? key}) : super(key: key);

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  late Future<List<Map<String, dynamic>>> _positions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _positions = DbHelper.instance.getPositions();
  }

  Future<double> _fetchPrice(String ticker) async {
    final url =
        'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$ticker&apikey=demo';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final quote = data['Global Quote'] as Map<String, dynamic>?;
        final p = quote?['05. price'];
        if (p != null) return double.tryParse(p) ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  Future<void> _updatePrices() async {
    final current = await DbHelper.instance.getPositions();
    for (var p in current) {
      final ticker = p['ticker'] as String;
      final isin = p['isin'] as String?;
      final name = p['name'] as String? ?? ticker;
      final price = await _fetchPrice(ticker);
      await DbHelper.instance.upsertAsset(
          isin ?? ticker, ticker, name, price, DateTime.now().millisecondsSinceEpoch);
    }
    _load();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            onPressed: _updatePrices,
            icon: const Icon(Icons.refresh),
            tooltip: 'Update data',
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _positions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No positions'));
          }
          final positions = snapshot.data!;
          double totalValue = 0;
          double totalCost = 0;
          for (var p in positions) {
            final qty = p['quantity'] as num;
            final cost = p['cost'] as num;
            final price = p['price'] as num? ?? 0;
            totalValue += qty * price;
            totalCost += cost;
          }
          final totalGain = totalValue - totalCost;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total: \u20ac${totalValue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Gain/Loss: \u20ac${totalGain.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: totalGain >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    final pos = positions[index];
                    final qty = pos['quantity'] as num;
                    final cost = pos['cost'] as num;
                    final price = pos['price'] as num? ?? 0;
                    final value = qty * price;
                    final gain = value - cost;
                    final name = pos['name'] as String? ?? pos['ticker'];
                    return ListTile(
                      title: Text(name),
                      subtitle: Text('Qty: $qty'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\u20ac${value.toStringAsFixed(2)}'),
                          Text(
                            '\u20ac${gain.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: gain >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
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
  final _tickerController = TextEditingController();
  final _valueController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _tickerController.dispose();
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
      'ticker': _tickerController.text,
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
                controller: _tickerController,
                decoration: const InputDecoration(labelText: 'Ticker'),
                validator: (v) => v == null || v.isEmpty ? 'Enter ticker' : null,
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
                title: Text(op['ticker']),
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
