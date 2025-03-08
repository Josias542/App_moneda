import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(CurrencyConverterApp());
}

class CurrencyConverterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => CurrencyConverterScreen(),
        '/history': (context) => ExchangeHistoryScreen(),
      },
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  @override
  _CurrencyConverterScreenState createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _convertedAmount = 0.0;
  List<String> _currencies = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchCurrencies();
  }

  Future<void> fetchCurrencies() async {
    final response = await http.get(Uri.parse('https://api.frankfurter.app/currencies'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _currencies = data.keys.toList();
        _fromCurrency = _currencies.first;
        _toCurrency = _currencies[1];
      });
    }
  }

  Future<void> convertCurrency() async {
    String date = "${_selectedDate.toIso8601String().split('T')[0]}";
    final response = await http.get(Uri.parse('https://api.frankfurter.app/$date?amount=${_amountController.text}&from=$_fromCurrency&to=$_toCurrency'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _convertedAmount = data['rates'][_toCurrency];
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conversor de Moneda'), actions: [
        IconButton(
          icon: Icon(Icons.history),
          onPressed: () => Navigator.pushNamed(context, '/history'),
        )
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Cantidad'),
            ),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text("Seleccionar Fecha: ${_selectedDate.toLocal()}".split(' ')[0]),
            ),
            DropdownButton<String>(
              value: _fromCurrency,
              items: _currencies.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _fromCurrency = newValue!;
                });
              },
            ),
            DropdownButton<String>(
              value: _toCurrency,
              items: _currencies.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _toCurrency = newValue!;
                });
              },
            ),
            ElevatedButton(
              onPressed: convertCurrency,
              child: Text('Convertir'),
            ),
            Text('Resultado: $_convertedAmount $_toCurrency')
          ],
        ),
      ),
    );
  }
}

class ExchangeHistoryScreen extends StatefulWidget {
  @override
  _ExchangeHistoryScreenState createState() => _ExchangeHistoryScreenState();
}

class _ExchangeHistoryScreenState extends State<ExchangeHistoryScreen> {
  String _baseCurrency = 'USD';
  Map<String, double> _exchangeRates = {};
  List<String> _currencies = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchCurrencies();
  }

  Future<void> fetchCurrencies() async {
    final response = await http.get(Uri.parse('https://api.frankfurter.app/currencies'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _currencies = data.keys.toList();
        _baseCurrency = _currencies.first;
        fetchExchangeHistory();
      });
    }
  }

  Future<void> fetchExchangeHistory() async {
    String date = "${_selectedDate.toIso8601String().split('T')[0]}";
    final response = await http.get(Uri.parse('https://api.frankfurter.app/$date?from=$_baseCurrency'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _exchangeRates = Map<String, double>.from(data['rates']);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        fetchExchangeHistory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial de Tasas de Cambio')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text("Seleccionar Fecha: ${_selectedDate.toLocal()}".split(' ')[0]),
            ),
            DropdownButton<String>(
              value: _baseCurrency,
              items: _currencies.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _baseCurrency = newValue!;
                  fetchExchangeHistory();
                });
              },
            ),
            Expanded(
              child: ListView(
                children: _exchangeRates.entries.map((entry) {
                  return ListTile(
                    title: Text('${entry.key}: ${entry.value}'),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}