class Entry {
  final int? id;
  final String name;
  final double amount;
  final DateTime date;

  Entry({this.id, required this.name, required this.amount, required this.date});

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'amount': amount,
        'date': dateKey(date),
      };

  factory Entry.fromMap(Map<String, Object?> m) => Entry(
        id: m['id'] as int?,
        name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.parse(m['date'] as String),
      );

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class ParseItem {
  final String name;
  final double amount;
  final bool ok;
  const ParseItem(this.name, this.amount, this.ok);
}