import 'package:flutter/material.dart';
// ignore: unused_import
import 'dart:collection';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(ExpenseTrackerApp());

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        hintColor: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ExpenseHomePage(),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ExpenseHomePageState createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final List<Map<String, dynamic>> _expenses = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDate;

  void _addExpense() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text);

    if (title.isEmpty ||
        amount == null ||
        amount <= 0 ||
        _selectedDate == null) {
      return;
    }

    setState(() {
      _expenses.add({
        'title': title,
        'amount': amount,
        'date': _selectedDate,
      });
    });

    Navigator.of(context).pop();
  }

  void _openAddExpenseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          color: Colors.purple[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                      labelText: 'Title',
                      fillColor: Colors.white,
                      filled: true),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Amount',
                      fillColor: Colors.white,
                      filled: true),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'No Date Chosen!'
                            : 'Picked Date: ${DateFormat.yMd().format(_selectedDate!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: Text(
                        'Choose Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: _addExpense,
                  child: Text('Add Expense'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _deleteExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });
  }

  BarChartData _getBarChartData() {
    final Map<String, double> categoryTotals = {};

    for (var expense in _expenses) {
      final dateKey = DateFormat.yMMMd().format(expense['date']);
      categoryTotals.update(dateKey, (value) => value + expense['amount'],
          ifAbsent: () => expense['amount']);
    }

    final barGroups = categoryTotals.entries.map((entry) {
      final index = categoryTotals.keys.toList().indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.purple[300],
            width: 16,
            borderRadius: BorderRadius.circular(4),
          )
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    return BarChartData(
      barGroups: barGroups,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < categoryTotals.keys.length) {
                return Text(categoryTotals.keys.elementAt(index),
                    style: TextStyle(fontSize: 10));
              }
              return Text('');
            },
            reservedSize: 40,
          ),
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
      barTouchData: BarTouchData(enabled: true),
      maxY: categoryTotals.values.isNotEmpty
          ? categoryTotals.values.reduce((a, b) => a > b ? a : b) * 1.2
          : 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[300],
        title: Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _openAddExpenseModal(context),
          )
        ],
      ),
      body: Column(
        children: [
          if (_expenses.isNotEmpty)
            SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: BarChart(
                  _getBarChartData(),
                ),
              ),
            ),
          Expanded(
            child: _expenses.isEmpty
                ? Center(
                    child: Text('No expenses added yet!',
                        style:
                            TextStyle(fontSize: 18, color: Colors.purple[700])),
                  )
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (ctx, index) {
                      final expense = _expenses[index];
                      return Card(
                        color: Colors.purple[50],
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(expense['title'],
                              style: TextStyle(color: Colors.purple[700])),
                          subtitle: Text(
                            DateFormat.yMMMd().format(expense['date']),
                            style: TextStyle(color: Colors.purple[500]),
                          ),
                          trailing: Text(
                            '\$${expense['amount'].toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.amber[800]),
                          ),
                          leading: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteExpense(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _openAddExpenseModal(context),
      ),
    );
  }
}
