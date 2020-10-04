import 'package:flutter/material.dart';
import 'package:moneymanagerv3/providers/accounts.dart';
import 'package:moneymanagerv3/screens/accounts.dart';
import 'package:moneymanagerv3/screens/transactions.dart';
import 'package:provider/provider.dart';
import 'models/account.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AccountsState(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
//
//  void showAddScreen(BuildContext context) {
//    showModalBottomSheet(
//        context: context,
//        isScrollControlled: true,
//        builder: (BuildContext context) => AddTransactionScreen());
//  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
          appBar: AppBar(
            title: Text('Money Manager'),
            backgroundColor: Color(0xFF16181C),
          ),
          backgroundColor: Color(0xFF16181C),
          body: MainScreen()
//        floatingActionButton: connectedToDB
//            ? FloatingActionButton(
//                onPressed: () {
//                  showAddScreen(context);
//                },
//                child: Icon(
//                  Icons.add,
//                  color: Color(0xFF16181C),
//                ),
//                backgroundColor: Colors.white,
//              )
//            : null,
          ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool connectedToDB = false;
  var provider;
  @override
  Widget build(BuildContext context) {
    if (provider == null) {
      provider = Provider.of<AccountsState>(context, listen: false);
      provider.initializeAccountTable().then((value) {
        setState(() {
          connectedToDB = value;
        });
      });
    }
    return Container(
        child: connectedToDB
            ? Column(
                children: [
                  Accounts(),
                  Transactions(),
                ],
              )
            : Center(child: CircularProgressIndicator()));
  }
}

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String name;
  double balance;
  bool _validatedBalance = false;
  bool _validatedName = false;
  bool _negative = false;
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
            'Add an account',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF16181C),
        ),
        backgroundColor: Color(0xFF16181C),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.only(top: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                TextField(
                  cursorColor: Colors.white,
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
                    errorText: _validatedName ? "Account name required" : null,
                    labelStyle: TextStyle(color: Colors.white),
                    labelText: 'Account Name',
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.numberWithOptions(
                    signed: false,
                  ),
                  onChanged: (value) {
                    setState(() {
                      balance = value.isEmpty ? null : double.parse(value);
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
                    errorText: _validatedBalance
                        ? "Balance amount required"
                        : _negative ? "Negative number not allowed" : null,
                    labelStyle: TextStyle(color: Colors.white),
                    labelText: 'Running Balance',
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 150,
                  child: RaisedButton(
                      onPressed: () {
                        if (name == "")
                          setState(() {
                            _validatedName = true;
                          });
                        else
                          setState(() {
                            _validatedName = false;
                          });
                        if (balance == null)
                          setState(() {
                            _validatedBalance = true;
                          });
                        else
                          setState(() {
                            _validatedBalance = false;
                          });
                        if (balance < 0.0)
                          setState(() {
                            _negative = true;
                          });
                        else
                          setState(() {
                            _negative = false;
                          });
                        if (!_negative &&
                            !_validatedBalance &&
                            !_validatedName) {
                          Account account =
                              Account(name: name, balance: balance);
                          Provider.of<AccountsState>(context, listen: false)
                              .addAccount(account)
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
