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
      home: const BuyOperationPage(),
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
