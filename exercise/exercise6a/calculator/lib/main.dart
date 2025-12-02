import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const ButtonCalculatorScreen(),
    );
  }
}

// Part 1: Button-based Calculator Screen
class ButtonCalculatorScreen extends StatefulWidget {
  const ButtonCalculatorScreen({super.key});

  @override
  State<ButtonCalculatorScreen> createState() => _ButtonCalculatorScreenState();
}

class _ButtonCalculatorScreenState extends State<ButtonCalculatorScreen> {
  String display = '0';
  String expression = '';
  List<double> numbers = [];
  List<String> operators = [];
  bool shouldResetDisplay = false;

  double evaluateExpression(List<double> nums, List<String> ops) {
    List<double> values = List.from(nums);
    List<String> operations = List.from(ops);

    // First pass: handle × and ÷
    int i = 0;
    while (i < operations.length) {
      if (operations[i] == '×' || operations[i] == '÷') {
        double result;
        if (operations[i] == '×') {
          result = values[i] * values[i + 1];
        } else {
          if (values[i + 1] == 0) {
            return double.nan;
          }
          result = values[i] / values[i + 1];
        }
        values[i] = result;
        values.removeAt(i + 1);
        operations.removeAt(i);
      } else {
        i++;
      }
    }

    // Second pass: handle + and -
    double result = values[0];
    for (int i = 0; i < operations.length; i++) {
      if (operations[i] == '+') {
        result += values[i + 1];
      } else if (operations[i] == '-') {
        result -= values[i + 1];
      }
    }

    return result;
  }

  String formatResult(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(2);
    }
  }

  String formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toString();
    }
  }

  void updateExpression() {
    if (numbers.isEmpty) {
      expression = '';
      return;
    }
    
    StringBuffer exp = StringBuffer();
    exp.write(formatNumber(numbers[0]));
    
    for (int i = 0; i < operators.length; i++) {
      exp.write(' ${operators[i]} ');
      if (i + 1 < numbers.length) {
        exp.write(formatNumber(numbers[i + 1]));
      }
    }
    
    expression = exp.toString();
  }

  void onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        // Clear all
        display = '0';
        expression = '';
        numbers.clear();
        operators.clear();
        shouldResetDisplay = false;
      } else if (value == '+' || value == '-' || value == '×' || value == '÷') {
        // Operator pressed
        if (display != 'Error') {
          if (numbers.isEmpty || !shouldResetDisplay) {
            numbers.add(double.parse(display));
            updateExpression();
          }
          operators.add(value);
          updateExpression();
          expression += ' $value';
          shouldResetDisplay = true;
        }
      } else if (value == '=') {
        // Calculate final result
        if (numbers.isNotEmpty && !shouldResetDisplay) {
          numbers.add(double.parse(display));
          updateExpression();
        }
        
        if (numbers.length > 1 && operators.length == numbers.length - 1) {
          double result = evaluateExpression(numbers, operators);
          display = formatResult(result);
          expression += ' = $display';
          
          // Reset for next calculation
          numbers.clear();
          operators.clear();
          shouldResetDisplay = true;
        }
      } else if (value == '.') {
        // Decimal point
        if (!display.contains('.')) {
          if (shouldResetDisplay) {
            display = '0.';
            shouldResetDisplay = false;
          } else {
            display += '.';
          }
        }
      } else {
        // Number pressed
        if (shouldResetDisplay || display == '0' || display == 'Error') {
          display = value;
          shouldResetDisplay = false;
        } else {
          display += value;
        }
      }
    });
  }

  Widget buildButton(String label, {Color? backgroundColor, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 70,
        height: 70,
        child: ElevatedButton(
          onPressed: () => onButtonPressed(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Colors.white,
            foregroundColor: textColor ?? Colors.black,
            elevation: 2,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Button Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FormCalculatorScreen(),
                ),
              );
            },
            tooltip: 'Switch to Form Calculator',
          ),
        ],
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.black87,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Expression display
                  if (expression.isNotEmpty)
                    Text(
                      expression,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w300,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  const SizedBox(height: 8),
                  // Current number display
                  Text(
                    display,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Buttons
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Row 1: 7 8 9 x
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildButton('7'),
                      buildButton('8'),
                      buildButton('9'),
                      buildButton('×', backgroundColor: Colors.grey[300]),
                    ],
                  ),
                  // Row 2: 4 5 6 /
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildButton('4'),
                      buildButton('5'),
                      buildButton('6'),
                      buildButton('÷', backgroundColor: Colors.grey[300]),
                    ],
                  ),
                  // Row 3: 1 2 3 +
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildButton('1'),
                      buildButton('2'),
                      buildButton('3'),
                      buildButton('+', backgroundColor: Colors.grey[300]),
                    ],
                  ),
                  // Row 4: = 0 C -
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildButton('=', backgroundColor: Colors.orange, textColor: Colors.white),
                      buildButton('0'),
                      buildButton('C', backgroundColor: Colors.grey[300]),
                      buildButton('-', backgroundColor: Colors.grey[300]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Part 2: Form-based Calculator Screen
class FormCalculatorScreen extends StatefulWidget {
  const FormCalculatorScreen({super.key});

  @override
  State<FormCalculatorScreen> createState() => _FormCalculatorScreenState();
}

class _FormCalculatorScreenState extends State<FormCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numberController = TextEditingController();
  final List<double> numbers = [];
  final List<String> operators = [];
  String result = '';
  String expression = '';
  String selectedOperation = '+';

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void addNumber() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        double num = double.parse(_numberController.text);
        numbers.add(num);
        
        // Update expression display
        if (expression.isEmpty) {
          expression = num.toString();
        } else {
          expression += ' $selectedOperation $num';
        }
        
        _numberController.clear();
        result = '';
      });
    }
  }

  void addOperator() {
    if (numbers.isNotEmpty && _numberController.text.isEmpty) {
      setState(() {
        operators.add(selectedOperation);
      });
    }
  }

  void calculate() {
    // Add the last number if there's one in the text field
    if (_numberController.text.isNotEmpty) {
      if (_formKey.currentState!.validate()) {
        double num = double.parse(_numberController.text);
        numbers.add(num);
        if (expression.isEmpty) {
          expression = num.toString();
        } else {
          expression += ' $selectedOperation $num';
        }
        _numberController.clear();
      } else {
        return;
      }
    }

    if (numbers.isEmpty) {
      setState(() {
        result = 'Please enter at least one number';
      });
      return;
    }

    if (numbers.length == 1) {
      setState(() {
        double finalResult = numbers[0];
        if (finalResult == finalResult.toInt()) {
          result = 'Result: ${finalResult.toInt()}';
        } else {
          result = 'Result: ${finalResult.toStringAsFixed(2)}';
        }
        expression += ' = $result';
      });
      return;
    }

    setState(() {
      // Parse operators from expression
      List<String> operatorList = [];
      for (int i = 0; i < expression.length; i++) {
        if (expression[i] == '+' || expression[i] == '-' || expression[i] == '×' || expression[i] == '÷') {
          operatorList.add(expression[i]);
        }
      }

      // Evaluate with proper order of operations
      List<double> values = List.from(numbers);
      List<String> operations = List.from(operatorList);

      // First pass: handle × and ÷
      int i = 0;
      while (i < operations.length) {
        if (operations[i] == '×' || operations[i] == '÷') {
          double calcResult;
          if (operations[i] == '×') {
            calcResult = values[i] * values[i + 1];
          } else {
            if (values[i + 1] != 0) {
              calcResult = values[i] / values[i + 1];
            } else {
              result = 'Error: Division by zero';
              expression = '';
              numbers.clear();
              operators.clear();
              return;
            }
          }
          values[i] = calcResult;
          values.removeAt(i + 1);
          operations.removeAt(i);
        } else {
          i++;
        }
      }

      // Second pass: handle + and -
      double calcResult = values[0];
      for (int i = 0; i < operations.length; i++) {
        if (operations[i] == '+') {
          calcResult += values[i + 1];
        } else if (operations[i] == '-') {
          calcResult -= values[i + 1];
        }
      }

      // Format result
      if (calcResult == calcResult.toInt()) {
        result = 'Result: ${calcResult.toInt()}';
      } else {
        result = 'Result: ${calcResult.toStringAsFixed(2)}';
      }
      
      expression += ' = ${calcResult == calcResult.toInt() ? calcResult.toInt() : calcResult.toStringAsFixed(2)}';
    });
  }

  void clearFields() {
    setState(() {
      _numberController.clear();
      numbers.clear();
      operators.clear();
      result = '';
      expression = '';
      selectedOperation = '+';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Switch to Button Calculator',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter Numbers',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Expression display
              if (expression.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Text(
                    expression,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              
              // Number input
              TextFormField(
                controller: _numberController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Enter Number',
                  hintText: 'Enter a number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.calculate),
                  suffixIcon: _numberController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _numberController.clear();
                            });
                          },
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
              
              // Operation selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedOperation,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: '+', child: Text('+ Addition')),
                      DropdownMenuItem(value: '-', child: Text('- Subtraction')),
                      DropdownMenuItem(value: '×', child: Text('× Multiplication')),
                      DropdownMenuItem(value: '÷', child: Text('÷ Division')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedOperation = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Add number button
              ElevatedButton.icon(
                onPressed: addNumber,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Numbers added count
              if (numbers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Numbers added: ${numbers.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),
              
              // Calculate button
              ElevatedButton(
                onPressed: calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Calculate',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              
              // Clear button
              OutlinedButton(
                onPressed: clearFields,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Clear All',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
              
              // Result display
              if (result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Text(
                    result,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}