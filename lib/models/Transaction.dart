class TransactionModel {
  int id;
  String name;
  double amount;
  String type;
  DateTime date;
  int account;
  String accountName;
  List<int> tagIds;
  TransactionModel(
      {this.id,
      this.name,
      this.amount,
      this.type,
      this.date,
      this.account,
      this.accountName,
      this.tagIds});
}
