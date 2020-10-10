import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:moneymanagerv3/models/Transaction.dart';
import 'package:moneymanagerv3/models/account.dart';
import 'package:moneymanagerv3/models/tags.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AccountsState extends ChangeNotifier {
  Future<Database> _database;
  List<Account> accounts = [];
  List<TransactionModel> transactions = [];
  List<TransactionModel> initialTransactions = [];
  List<Tag> tags = [];
  bool hideAccount = false;
  int activeAccountId;
  List<int> selectedTagIds = [];
  List<int> filteredTagIds = [];
  bool filterApplied = false;
  List<bool> filteredTypes = [true, true];
  DateTime filteredDate = DateTime.now();
  double scrollOffset = 0.0;
  static Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future _onCreate(Database db, int version) async {
    await db.execute(
      "CREATE TABLE accounts(id INTEGER PRIMARY KEY, name TEXT, balance REAL)",
    );
    await db.execute(
      "CREATE TABLE transactions(id INTEGER PRIMARY KEY, name TEXT, amount REAL, type TEXT, date INTEGER, account_id INTEGER, FOREIGN KEY(account_id) REFERENCES accounts(id))",
    );
    await db.execute(
      "CREATE TABLE tags(id INTEGER PRIMARY KEY, name TEXT, used_count INTEGER)",
    );
    await db.execute(
      "CREATE TABLE transaction_tag_map(id INTEGER PRIMARY KEY, transaction_id INTEGER, tag_id INTEGER )",
//          "FOREIGN KEY(tag_id) REFERENCES tags(id), FOREIGN KEY(transaction_id) REFERENCES transactions(id))",
    );
  }

  Future<bool> initializeAccountTable() async {
    _database = openDatabase(
      join(await getDatabasesPath(), 'moneymanager.db'),
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      version: 1,
    );
    notifyListeners();
    return true;
  }

  Future<bool> addAccount(Account account) async {
    final Database db = await _database;
    try {
      await db.insert(
        'accounts',
        {
          'name': account.name,
          'balance': account.balance,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      filteredTagIds = [];
      filteredTypes = [true, true];
      await getAccounts();
      await getTransactions();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    final Database db = await _database;
    Account account =
        accounts.where((element) => element.id == transaction.account).first;
    account.balance = transaction.type == "EXPENSE"
        ? account.balance - transaction.amount
        : account.balance + transaction.amount;
    try {
      int transactionId = await db.insert(
        'transactions',
        {
          'name': transaction.name,
          'amount': transaction.amount,
          'type': transaction.type,
          'date': transaction.date.millisecondsSinceEpoch,
          'account_id': transaction.account
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (transactionId != -1)
        await db.update(
          'accounts',
          {
            'name': account.name,
            'balance': account.balance,
          },
          where: "id = ?",
          whereArgs: [account.id],
        );
      if (transactionId != -1)
        selectedTagIds.forEach((tagId) async {
          await db.insert(
            'transaction_tag_map',
            {
              'tag_id': tagId,
              'transaction_id': transactionId,
            },
          );
        });
      filteredTagIds = [];
      filteredTypes = [true, true];
      await getAccounts();
      await getTransactions();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> addTag(String name) async {
    final Database db = await _database;
    try {
      int id = await db.insert(
        'tags',
        {
          'name': name,
          'used_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      selectedTagIds.add(id);
      await getTags();
      notifyListeners();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<void> getTags() async {
    final Database db = await _database;
    final List<Map<String, dynamic>> maps =
        await db?.query('tags', orderBy: 'used_count DESC');

    tags = List.generate(maps.length, (i) {
      return Tag(
        id: maps[i]['id'],
        name: maps[i]['name'],
        usedCount: maps[i]['used_count'],
      );
    });
    notifyListeners();
    return;
  }

  Future<void> getAccounts() async {
    final Database db = await _database;

    final List<Map<String, dynamic>> maps = await db?.query('accounts');

    accounts = List.generate(maps.length, (i) {
      return Account(
          id: maps[i]['id'],
          name: maps[i]['name'],
          balance: maps[i]['balance'],
          filteredBalance: 0.0);
    });
    if (activeAccountId == null && accounts.length > 1) {
      activeAccountId = 0;
    } else if (activeAccountId == null && accounts.length == 1) {
      activeAccountId = accounts[0].id;
    }
    notifyListeners();
    return;
  }

  Future<void> getTransactions({int filteredEpoch = 0}) async {
    final Database db = await _database;
//
//    final List<Map<String, dynamic>> maps =
//        await db?.query('transactions', orderBy: 'date DESC', limit: 50);
    final List<Map<String, dynamic>> maps = await db?.rawQuery(
        'SELECT tr.id,tr.name,tr.amount,tr.type,tr.account_id,tr.date, GROUP_CONCAT(ta.id) as tag_id from transactions tr '
        'LEFT JOIN transaction_tag_map tt ON (tr.id = tt.transaction_id) '
        'LEFT JOIN tags ta ON (tt.tag_id = ta.id) '
        'GROUP BY tr.id '
        'ORDER BY tr.date DESC ');

    transactions = List.generate(maps.length, (i) {
      List<int> tagIds = maps[i]['tag_id'] == null
          ? []
          : maps[i]['tag_id']
              .toString()
              .split(",")
              .map((e) => int.parse(e))
              .toList();
      return TransactionModel(
          id: maps[i]['id'],
          name: maps[i]['name'],
          amount: maps[i]['amount'],
          type: maps[i]['type'],
          date: DateTime.fromMillisecondsSinceEpoch(maps[i]['date']),
          account: maps[i]['account_id'],
          accountName: accounts
              .where((element) => element.id == maps[i]['account_id'])
              .first
              .name,
          tagIds: tagIds);
    });
    initialTransactions = transactions;
    await getTags();
    notifyListeners();
    return;
  }

  void transformAccounts(value) {
    if (value != hideAccount) {
      hideAccount = value;
      notifyListeners();
    }
  }

  void changeActiveAccount(int id) {
    activeAccountId = id;
    notifyListeners();
  }

  Future<void> deleteAccount(int id) async {
    final db = await _database;
    await db.delete(
      'transactions',
      where: "account_id = ?",
      whereArgs: [id],
    );
    await db.delete(
      'accounts',
      where: "id = ?",
      whereArgs: [id],
    );

    await getAccounts();
    await getTransactions();
    changeActiveAccount(0);
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    final db = await _database;
    Account account =
        accounts.where((element) => element.id == transaction.account).first;
    account.balance = transaction.type == "EXPENSE"
        ? account.balance + transaction.amount
        : account.balance - transaction.amount;
    await db.delete(
      'transactions',
      where: "id = ?",
      whereArgs: [transaction.id],
    );
    await db.update(
      'accounts',
      {
        'name': account.name,
        'balance': account.balance,
      },
      where: "id = ?",
      whereArgs: [transaction.account],
    );
    await getAccounts();
    await getTransactions();
  }

  Future<void> deleteTag(int id) async {
    final db = await _database;
    await db.delete(
      'transaction_tag_map',
      where: "tag_id = ?",
      whereArgs: [id],
    );
    await db.delete(
      'tags',
      where: "id = ?",
      whereArgs: [id],
    );
    selectedTagIds.remove(id);
    await getTags();
    await getTransactions();
    notifyListeners();
    return;
  }

  void toggleTag(int selectedId) {
    selectedTagIds.contains(selectedId)
        ? selectedTagIds.remove(selectedId)
        : selectedTagIds.add(selectedId);
    notifyListeners();
  }

  void clearSelectedTags() {
    selectedTagIds = [];
    notifyListeners();
  }

  void toggleFilter(int selectedTag, int selectedType) {
    if (selectedTag != null) {
      filteredTagIds.contains(selectedTag)
          ? filteredTagIds.remove(selectedTag)
          : filteredTagIds.add(selectedTag);
      if (filteredTagIds.length > 0) {
        transactions = transactions.where((element) {
          return filteredTagIds
                  .indexWhere((id) => element.tagIds.contains(id)) >=
              0;
        }).toList();
      } else
        transactions = initialTransactions;
    }

    if (selectedType != null) {
      filteredTypes[selectedType] = !filteredTypes[selectedType];
      if (!filteredTypes[0] || !filteredTypes[1]) {
        transactions = transactions.where((element) {
          return filteredTypes[0]
              ? element.type == "EXPENSE"
              : false || filteredTypes[1] ? element.type == "INCOME" : false;
        }).toList();
      } else
        transactions = initialTransactions;
    }
    double totalFilterBalance = 0.0;
    accounts.forEach((element) {
      element.filteredBalance = 0.0;
    });
    transactions.forEach((element) {
      if (element.type == "EXPENSE") {
        accounts[element.account].filteredBalance -= element.amount;
        totalFilterBalance = totalFilterBalance - element.amount;
      } else {
        accounts[element.account].filteredBalance += element.amount;
        totalFilterBalance = totalFilterBalance + element.amount;
      }
    });
    if (accounts.length > 1) {
      accounts[0].filteredBalance = totalFilterBalance;
    }
    notifyListeners();
  }

  void changeFilterDate(DateTime dateTime) {
    filteredDate = dateTime;
//    int filteredEpoch = filteredDate.millisecondsSinceEpoch;
//    await getTransactions(filteredEpoch: filteredEpoch);
    notifyListeners();
  }

  void setOffset(double offset) {
    scrollOffset = offset;
    notifyListeners();
  }
}
