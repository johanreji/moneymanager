import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:moneymanagerv3/models/account.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AccountsState extends ChangeNotifier {
  Future<Database> _database;
  List<Account> accounts = [];
  Future<bool> initializeAccountTable() async {
    _database = openDatabase(
      join(await getDatabasesPath(), 'moneymanager.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE accounts(id INTEGER PRIMARY KEY, name TEXT, balance REAL)",
        );
      },
      version: 1,
    );
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
    notifyListeners();
    return;
  }
}
