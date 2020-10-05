import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moneymanagerv3/models/account.dart';
import 'package:moneymanagerv3/providers/accounts.dart';
import 'package:provider/provider.dart';

class Accounts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(15),
          child: Text(
            'Accounts',
            style: TextStyle(color: Colors.white, fontSize: 20),
            textAlign: TextAlign.left,
          ),
        ),
        FutureBuilder(
          future:
              Provider.of<AccountsState>(context, listen: false).getAccounts(),
          builder: (ctx, dataSnapshot) {
            // Display the waiting progress bar
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            // Error handling
            if (dataSnapshot.hasError) {
              return Text(
                dataSnapshot.error.toString(),
                style: TextStyle(color: Colors.white),
              );
            }

            return Consumer<AccountsState>(
              builder: (context, accountsState, _) =>
                  AccountList(accountsState.accounts),
            );
          },
        ),
      ],
    );
  }
}

class AddAccountScreen extends StatefulWidget {
  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  bool _validatedName = false;
  bool _validatedBalance = false;
  bool _negative = false;
  double balance = 0.0;
  String name = "";
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
                SizedBox(height: 40),
                SizedBox(
                  width: 100,
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

class AccountList extends StatefulWidget {
  final List<Account> accounts;
  AccountList(this.accounts);
  @override
  _AccountListState createState() => _AccountListState();
}

class _AccountListState extends State<AccountList> {
  int _index = 0;
  PageController pageController = PageController(viewportFraction: 0.5);
  Future<void> _showDeleteDialog(
      BuildContext context, String accountName, int accountId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete $accountName account'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete $accountName?'),
                Text(
                    'This will automatically delete the transactions linked with $accountName account.'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<AccountsState>(context, listen: false)
                    .deleteAccount(accountId);
                setState(() {
                  _index = 0;
                });
                pageController.jumpTo(0);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.length > 1 && widget.accounts[0].id != 0) {
      double sum = 0.0;
      widget.accounts.forEach((element) {
        sum += element.balance;
      });
      Account allAccount = Account(id: 0, name: 'All Accounts', balance: sum);
      widget.accounts.insert(0, allAccount);
    }
    return Stack(
      children: [
        Container(
          child: SizedBox(
            height: 130,
            // card height
            child: PageView.builder(
              itemCount: widget.accounts.length,
              controller: pageController,
              onPageChanged: (int index) {
                setState(() => _index = index);
                Provider.of<AccountsState>(context, listen: false)
                    .changeActiveAccount(widget.accounts[index].id);
              },
              itemBuilder: (_, i) {
                return Transform.scale(
                  scale: i == _index ? 1 : 0.9,
                  child: GestureDetector(
                    onLongPress: () {
                      if (widget.accounts[i].id != 0 && i == _index)
                        _showDeleteDialog(context, widget.accounts[i].name,
                            widget.accounts[i].id);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment(-1.0, -4.0),
                              end: Alignment(1.0, 4.0),
                              colors: [
                                Color(0xFF141619),
                                Color(0xFF181a1e),
                              ]),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                                color: i == _index
                                    ? Colors.blue[800]
                                    : Color(0xFF131418),
                                offset: Offset(1.0, 1.0),
                                blurRadius: i == _index ? 5.0 : 15,
                                spreadRadius: i == _index ? 0 : 1),
                            BoxShadow(
                                color: i == _index
                                    ? Colors.blue[800]
                                    : Color(0xFF131418),
                                offset: Offset(-1.0, -1.0),
                                blurRadius: i == _index ? 5.0 : 15,
                                spreadRadius: i == _index ? 0 : 1),
                          ]),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "${widget.accounts[i].name}",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                            textAlign: TextAlign.left,
                          ),
                          Text(
                            "Rs. " +
                                widget.accounts[i].balance
                                    .toString()
                                    .split(".")[0] +
                                (widget.accounts[i].balance
                                            .toString()
                                            .split(".")[1] ==
                                        "0"
                                    ? ""
                                    : widget.accounts[i].balance
                                        .toString()
                                        .split(".")[1]),
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: widget.accounts.length == 0
              ? (MediaQuery.of(context).size.width - 140) / 2
              : 25,
          child: GestureDetector(
            onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => AddAccountScreen()),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.blue[800],
              ),
              height: 60,
              padding: widget.accounts.length == 0
                  ? EdgeInsets.all(20)
                  : EdgeInsets.zero,
              width: widget.accounts.length == 0 ? null : 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.accounts.length == 0)
                    Text('Add account',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  if (widget.accounts.length == 0) SizedBox(width: 5),
                  Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
