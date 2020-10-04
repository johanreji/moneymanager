import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:moneymanagerv3/models/Transaction.dart';
import 'package:moneymanagerv3/models/account.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AccountsState extends ChangeNotifier {
  Future<Database> _database;
  List<Account> accounts = [];
  List<TransactionModel> transactions = [];
  bool connectedToDB = false;
  bool hideAccount = false;
  int activeAccountId;
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
  }

  Future<bool> initializeAccountTable() async {
    _database = openDatabase(
      join(await getDatabasesPath(), 'moneymanager.db'),
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      version: 1,
    );
    connectedToDB = true;
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
      await getAccounts();
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
      await db.insert(
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
      await db.update(
        'accounts',
        {
          'name': account.name,
          'balance': account.balance,
        },
        where: "id = ?",
        whereArgs: [account.id],
      );
      await getAccounts();
      await getTransactions();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<void> getAccounts() async {
    final Database db = await _database;

    final List<Map<String, dynamic>> maps = await db?.query('accounts');

    accounts = List.generate(maps.length, (i) {
      return Account(
        id: maps[i]['id'],
        name: maps[i]['name'],
        balance: maps[i]['balance'],
      );
    });
    if (activeAccountId == null && accounts.length > 1) {
      activeAccountId = 0;
    } else if (activeAccountId == null && accounts.length == 1) {
      activeAccountId = accounts[0].id;
    }
    notifyListeners();
    return;
  }

  Future<void> getTransactions() async {
    final Database db = await _database;

    final List<Map<String, dynamic>> maps =
        await db?.query('transactions', orderBy: 'date DESC', limit: 50);

    transactions = List.generate(maps.length, (i) {
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
      );
    });
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
}
