import 'package:flutter/material.dart';
import 'package:moneymanagerv3/providers/accounts.dart';
import 'package:moneymanagerv3/screens/accounts.dart';
import 'package:moneymanagerv3/screens/transactions.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:moneymanagerv3/models/Transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AccountsState(),
      child: MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: MyApp()),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool connectedToDB = false;
  var provider;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool isFirstTime = true;
  void showAddScreen(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => AddTransactionScreen());
  }

  Future<void> showAlert(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Color(0xFF0078d4)),
              SizedBox(width: 10),
              Text('Info', style: TextStyle(color: Color(0xFF0078d4)))
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Add an account before adding a transaction record'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showTutorialAlert() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Color(0xFF0078d4)),
              SizedBox(width: 10),
              Text('Info', style: TextStyle(color: Color(0xFF0078d4)))
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Long press on an account card or a transaction to delete it'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> checkIfFirstTime() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      isFirstTime = prefs.get('isFirst') ?? true;
    });
    if (isFirstTime) {
      prefs.setBool('isFirst', false);
      showTutorialAlert();
    }
  }

  @override
  void initState() {
    super.initState();
    checkIfFirstTime();
  }

  @override
  Widget build(BuildContext context) {
    if (provider == null || connectedToDB == false) {
      provider = Provider.of<AccountsState>(context, listen: false);
      provider.initializeAccountTable().then((value) {
        setState(() {
          connectedToDB = value;
        });
      });
    }
    return Scaffold(
        appBar: AppBar(
          title: Text('Money Manager'),
          backgroundColor: Color(0xFF16181C),
        ),
        backgroundColor: Color(0xFF16181C),
        body: SafeArea(
            child: connectedToDB
                ? MainScreen()
                : Center(
                    child: CircularProgressIndicator(),
                  )),
        floatingActionButton: connectedToDB
            ? FloatingActionButton(
                onPressed: () =>
                    Provider.of<AccountsState>(context, listen: false)
                                .accounts
                                .length >
                            0
                        ? showAddScreen(context)
                        : showAlert(context),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                backgroundColor: Colors.blue[800],
              )
            : null);
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [
        Accounts(),
        Transactions(),
      ],
    ));
  }
}

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String name;
  double amount;
  DateTime date = DateTime.now();
  bool _validatedAmount = false;
  bool _validatedName = false;
  bool _validatedAccount = false;

  bool _negative = false;
  String accountSelected;
  int accountIDSelected;
  TextEditingController dateController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(DateTime.now()));

  List<bool> _selection = [true, false];

  _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.utc(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(), // This will change to light theme.
          child: child,
        );
      },
    );
    if (picked != null && picked != date) {
      setState(() {
        date = picked;
      });
      dateController.text = DateFormat('dd MMM yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          title: Text(
            'Add a Transaction',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF16181C),
        ),
        backgroundColor: Color(0xFF16181C),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Center(
                  child: ToggleButtons(
                    children: <Widget>[
                      Row(
                        children: [
                          SizedBox(width: 20),
                          Text('Expense',
                              style: TextStyle(
                                  color: _selection[0]
                                      ? Color(0xFF16181C)
                                      : Colors.white)),
                          Icon(Icons.expand_less,
                              color: _selection[0]
                                  ? Color(0xFF16181C)
                                  : Colors.white),
                          SizedBox(width: 10),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(width: 10),
                          Icon(Icons.expand_more,
                              color: _selection[1]
                                  ? Color(0xFF16181C)
                                  : Colors.white),
                          Text('Income',
                              style: TextStyle(
                                  color: _selection[1]
                                      ? Color(0xFF16181C)
                                      : Colors.white)),
                          SizedBox(width: 20),
                        ],
                      ),
                    ],
                    color: Color(0xFF16181C),
                    selectedBorderColor: Colors.white,
                    borderColor: Colors.white,
                    fillColor: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    borderWidth: 2,
                    isSelected: _selection,
                    onPressed: (int index) {
                      setState(() {
                        _selection[0] = index == 0 ? true : false;
                        _selection[1] = index == 1 ? true : false;
                      });
                    },
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  cursorColor: Colors.white,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      name = value;
                    });
                  },
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 1),
                    ),
                    errorText:
                        _validatedName ? "Transaction name required" : null,
                    labelStyle: TextStyle(color: Colors.white),
                    labelText: 'Transaction Name',
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.numberWithOptions(
                    signed: false,
                  ),
                  onChanged: (value) {
                    setState(() {
                      amount = value.isEmpty ? null : double.parse(value);
                    });
                  },
                  cursorColor: Colors.white,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 1),
                    ),
                    errorText: _validatedAmount
                        ? "Amount required"
                        : _negative ? "Negative number not allowed" : null,
                    labelStyle: TextStyle(color: Colors.white),
                    labelText: 'Amount',
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  cursorColor: Colors.white,
                  style: TextStyle(color: Colors.white),
                  onTap: () => _selectDate(context),
                  readOnly: true,
                  controller: dateController,
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    labelStyle: TextStyle(color: Colors.white),
                    labelText: 'Date',
                  ),
                ),
                SizedBox(height: 20),
                DropdownButton(
                  hint: accountSelected == null
                      ? Text(
                          'Select an Account',
                          style: TextStyle(
                              color: _validatedAccount
                                  ? Colors.red
                                  : Colors.white),
                        )
                      : Text(
                          accountSelected,
                          style: TextStyle(color: Colors.white),
                        ),
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  iconSize: 30.0,
                  style: TextStyle(color: Color(0xFF16181C)),
                  items: Provider.of<AccountsState>(context, listen: false)
                      .accounts
                      .where((element) => element.id != 0)
                      .map(
                    (val) {
                      return DropdownMenuItem<String>(
                        value: val.id.toString(),
                        child: Text(val.name,
                            style: TextStyle(color: Color(0xFF16181C))),
                      );
                    },
                  ).toList(),
                  onChanged: (val) {
                    setState(
                      () {
                        accountSelected = Provider.of<AccountsState>(context,
                                listen: false)
                            .accounts
                            .where((element) => element.id == int.parse(val))
                            .first
                            .name;
                        accountIDSelected = int.parse(val);
                      },
                    );
                  },
                ),
                SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 100,
                    child: RaisedButton(
                        onPressed: () {
                          if (name == null || name == "")
                            setState(() {
                              _validatedName = true;
                            });
                          else
                            setState(() {
                              _validatedName = false;
                            });
                          if (amount == null)
                            setState(() {
                              _validatedAmount = true;
                            });
                          else
                            setState(() {
                              _validatedAmount = false;
                            });
                          if (amount == null || amount < 0.0)
                            setState(() {
                              _negative = true;
                            });
                          else
                            setState(() {
                              _negative = false;
                            });
                          if (accountSelected == null)
                            setState(() {
                              _validatedAccount = true;
                            });
                          else
                            setState(() {
                              _validatedAccount = false;
                            });
                          if (!_negative &&
                              !_validatedAmount &&
                              !_validatedName &&
                              !_validatedAccount) {
                            TransactionModel transaction = TransactionModel(
                                name: name,
                                amount: amount,
                                date: date,
                                type: _selection[0] ? "EXPENSE" : "INCOME",
                                account: accountIDSelected);
                            Provider.of<AccountsState>(context, listen: false)
                                .addTransaction(transaction)
                                .then((result) {
                              if (result) {
                                Navigator.pop(context);
                              } else {
                                final snackBar = SnackBar(
                                  content: Text('Something went wrong!'),
                                  action: SnackBarAction(
                                      label: 'Okay', onPressed: () {}),
                                );
                                Scaffold.of(context).showSnackBar(snackBar);
                              }
                            });
                          }
                        },
                        color: Colors.white,
                        child: Text(
                          'Submit',
                          style: TextStyle(color: Color(0xFF16181C)),
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreens extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(),
    );
  }
}
