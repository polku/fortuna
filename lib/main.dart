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

  final List<Widget> _pages = const [
    BuyOperationPage(),
    OperationsListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
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

class BuyOperationPage extends StatefulWidget {
  const BuyOperationPage({Key? key}) : super(key: key);

  @override
  _BuyOperationPageState createState() => _BuyOperationPageState();
}

class _BuyOperationPageState extends State<BuyOperationPage> {
  final _formKey = GlobalKey<FormState>();
  final _isinController = TextEditingController();
  final _valueController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _isinController.dispose();
    _valueController.dispose();
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
                subtitle: Text("${date.toLocal().toString().split(' ')[0]} - ${op['value_unit']}"),
              );
            },
          );
        },
      ),
    );
  }
}
