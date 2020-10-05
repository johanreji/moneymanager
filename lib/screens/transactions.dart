import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanagerv3/models/Transaction.dart';
import 'package:moneymanagerv3/providers/accounts.dart';
import 'package:provider/provider.dart';

class Transactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text(
                'Transactions',
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.left,
              ),
            ),
            FutureBuilder(
              future: Provider.of<AccountsState>(context, listen: false)
                  .getTransactions(),
              builder: (ctx, dataSnapshot) {
                // Display the waiting progress bar
                if (dataSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
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
                      TransactionList(accountsState.transactions),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionList extends StatefulWidget {
  final List<TransactionModel> transactions;
  TransactionList(this.transactions);

  @override
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.offset > 20) {
        Provider.of<AccountsState>(context, listen: false)
            .transformAccounts(true);
      } else {
        Provider.of<AccountsState>(context, listen: false)
            .transformAccounts(false);
      }
    });
  }

  Future<void> _showDeleteDialog(
      BuildContext context, TransactionModel transaction) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete transaction'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete ${transaction.name}?'),
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
                    .deleteTransaction(transaction);
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
    int activeId =
        Provider.of<AccountsState>(context, listen: false).activeAccountId;
    List<TransactionModel> transactions = activeId == 0
        ? widget.transactions
        : widget.transactions
            .where((element) => element.id == activeId)
            .toList();
    return Expanded(
      child: transactions.length == 0
          ? Center(
              child: Text(
                'No transaction found.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              controller: scrollController,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, i) {
                bool showDate = i == 0
                    ? true
                    : transactions[i]
                                .date
                                .difference(widget.transactions[i - 1].date)
                                .inDays !=
                            0
                        ? true
                        : false;

                return GestureDetector(
                  onLongPress: () {
                    _showDeleteDialog(context, transactions[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDate)
                          Text(
                              '${transactions[i].date.difference(DateTime.now()).inDays == 0 ? "Today" : transactions[i].date.difference(DateTime.now()).inDays == -1 ? "Yesterday" : DateFormat('dd MMM yyyy').format(transactions[i].date)}',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                        if (showDate) SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              transactions[i].name,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Rs. ' +
                                  transactions[i]
                                      .amount
                                      .toString()
                                      .split(".")[0] +
                                  (transactions[i]
                                              .amount
                                              .toString()
                                              .split(".")[1] ==
                                          "0"
                                      ? ""
                                      : transactions[i]
                                          .amount
                                          .toString()
                                          .split(".")[1]),
                              style: TextStyle(
                                  color: transactions[i].type == "EXPENSE"
                                      ? Color(0xFFCA5010)
                                      : Color(0xFF407855),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (i == transactions.length - 1) SizedBox(height: 60)
                      ],
                    ),
                  ),
                );
              },
              itemCount: transactions.length,
            ),
    );
  }
}
