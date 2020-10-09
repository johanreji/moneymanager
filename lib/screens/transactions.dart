import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanagerv3/models/Transaction.dart';
import 'package:moneymanagerv3/models/tags.dart';
import 'package:moneymanagerv3/providers/accounts.dart';
import 'package:provider/provider.dart';

class Transactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(15),
        child: FutureBuilder(
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
//      if (scrollController.offset > 20) {
//        Provider.of<AccountsState>(context, listen: false)
//            .transformAccounts(true);
//      } else {
//        Provider.of<AccountsState>(context, listen: false)
//            .transformAccounts(false);
//      }
    });
  }

  void showFilterScreen(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => FilterScreen());
  }

  @override
  Widget build(BuildContext context) {
    int activeId =
        Provider.of<AccountsState>(context, listen: false).activeAccountId;
    List<int> filteredTagIds =
        Provider.of<AccountsState>(context).filteredTagIds;
    List<bool> filteredTypes =
        Provider.of<AccountsState>(context).filteredTypes;
    List<TransactionModel> transactions = activeId == 0
        ? widget.transactions
        : widget.transactions
            .where((element) => element.account == activeId)
            .toList();
    if (!filteredTypes[0] || !filteredTypes[1])
      transactions = transactions
          .where((element) => filteredTypes[0]
              ? element.type == "EXPENSE"
              : false || filteredTypes[1] ? element.type == "INCOME" : false)
          .toList();
    if (filteredTagIds.length > 0)
      transactions = transactions
          .where((element) =>
              filteredTagIds.indexWhere((id) => element.tagIds.contains(id)) >=
              0)
          .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          padding: EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions',
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.left,
              ),
              GestureDetector(
                onTap: () => showFilterScreen(context),
                child: Icon(
                  Icons.filter_list,
                  color:
                      filteredTagIds.length > 0 || filteredTypes.contains(false)
                          ? Colors.blue[800]
                          : Colors.white,
                  size: 16,
                ),
              )
            ],
          ),
        ),
        Expanded(
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
                    return TransactionItem(
                      transaction: transactions[i],
                      index: i,
                      length: transactions.length,
                      showDate: showDate,
                    );
                  },
                  itemCount: transactions.length,
                ),
        ),
      ],
    );
  }
}

class FilterScreen extends StatelessWidget {
  _selectDate(BuildContext context, DateTime intialDate) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: intialDate,
      firstDate: DateTime.utc(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(), // This will change to light theme.
          child: child,
        );
      },
    );
    if (picked != null) {
      Provider.of<AccountsState>(context, listen: false)
          .changeFilterDate(picked);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<int> filteredTagIds =
        Provider.of<AccountsState>(context).filteredTagIds;
    List<Tag> tags = Provider.of<AccountsState>(context).tags;
    List<bool> filteredType = Provider.of<AccountsState>(context).filteredTypes;
    DateTime filteredDate = Provider.of<AccountsState>(context).filteredDate;
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Color(0xFF16181C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.drag_handle,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Filter by tags',
            style: TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.left,
          ),
          Container(
            height: 40,
            margin: EdgeInsets.only(top: 10),
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => ActionChip(
                      shape:
                          StadiumBorder(side: BorderSide(color: Colors.white)),
                      label: Text(
                        tags[index].name,
                        style: TextStyle(
                            color: filteredTagIds.contains(tags[index].id)
                                ? Color(0xFF16181C)
                                : Colors.white),
                      ),
                      backgroundColor: filteredTagIds.contains(tags[index].id)
                          ? Colors.white
                          : Color(0xFF131418),
                      onPressed: () =>
                          Provider.of<AccountsState>(context, listen: false)
                              .toggleFilterTag(tags[index].id),
                    ),
                separatorBuilder: (context, _) => SizedBox(width: 5),
                itemCount: tags.length),
          ),
          SizedBox(height: 30),
          Text(
            'Filter by type',
            style: TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: 10),
          Center(
            child: ToggleButtons(
              children: <Widget>[
                Row(
                  children: [
                    SizedBox(width: 20),
                    Text('Expense',
                        style: TextStyle(
                            color: filteredType[0]
                                ? Color(0xFF16181C)
                                : Colors.white)),
                    Icon(Icons.expand_less,
                        color:
                            filteredType[0] ? Color(0xFF16181C) : Colors.white),
                    SizedBox(width: 10),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(width: 10),
                    Icon(Icons.expand_more,
                        color:
                            filteredType[1] ? Color(0xFF16181C) : Colors.white),
                    Text('Income',
                        style: TextStyle(
                            color: filteredType[1]
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
              isSelected: filteredType,
              onPressed: Provider.of<AccountsState>(context, listen: false)
                  .toggleFilterType,
            ),
          ),
//          SizedBox(height: 40),
//          Row(
//            crossAxisAlignment: CrossAxisAlignment.center,
//            children: [
//              Text(
//                'Jump to date',
//                style: TextStyle(color: Colors.white, fontSize: 14),
//                textAlign: TextAlign.left,
//              ),
//              Spacer(),
//              GestureDetector(
//                onTap: () => _selectDate(context, filteredDate),
//                child: Row(
//                  children: [
//                    Text(
//                      '${filteredDate.difference(DateTime.now()).inDays == 0 ? "Today" : filteredDate.difference(DateTime.now()).inDays == -1 ? "Yesterday" : DateFormat('dd MMM yyyy').format(filteredDate)}',
//                      style: TextStyle(color: Colors.white, fontSize: 14),
//                      textAlign: TextAlign.left,
//                    ),
//                  ],
//                ),
//              ),
//              SizedBox(width: 10),
//              Icon(
//                Icons.edit,
//                color: Colors.white,
//                size: 16,
//              )
//            ],
//          ),
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final int index;
  final int length;
  final bool showDate;
  TransactionItem({this.transaction, this.index, this.length, this.showDate});

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
    List<Tag> tags = Provider.of<AccountsState>(context, listen: false).tags;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        _showDeleteDialog(context, transaction);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            border: Border(
                bottom: (index == length - 1)
                    ? BorderSide.none
                    : BorderSide(color: Colors.white70))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate)
              Text(
                  '${transaction.date.difference(DateTime.now()).inDays == 0 ? "Today" : transaction.date.difference(DateTime.now()).inDays == -1 ? "Yesterday" : DateFormat('dd MMM yyyy').format(transaction.date)}',
                  style: TextStyle(color: Colors.blue[800], fontSize: 14)),
            if (showDate) SizedBox(height: 15),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      transaction.name,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rs. ' +
                          transaction.amount.toString().split(".")[0] +
                          (transaction.amount.toString().split(".")[1] == "0"
                              ? ""
                              : transaction.amount.toString().split(".")[1]),
                      style: TextStyle(
                          color: transaction.type == "EXPENSE"
                              ? Color(0xFFCA5010)
                              : Color(0xFF407855),
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        height: 30.0,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: transaction.tagIds.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: 5),
                            itemBuilder: (context, index) => Chip(
                                  label: Text(
                                    '${tags.where((element) => element.id == transaction.tagIds[index]).first.name}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                )),
                      ),
                    ),
                    Spacer(),
                    Text(
                      (transaction.type == "EXPENSE" ? 'From ' : 'To ') +
                          transaction.accountName,
                      style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            if (index == length - 1) SizedBox(height: 60)
          ],
        ),
      ),
    );
  }
}
