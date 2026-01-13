class Transaction {
  String id;
  String type;
  double amount;
  String category;
  String description;
  DateTime dateTime;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.dateTime,
  });

  // Konversi ke Map untuk penyimpanan SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id == '0' ? null : int.parse(id), // null untuk auto-increment
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date_time': dateTime.toIso8601String(), // Simpan sebagai string ISO
    };
  }

  // Membuat objek Transaction dari data SQLite
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id']?.toString() ?? '0', // Konversi ke string
      type: map['type']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      dateTime: DateTime.parse(map['date_time']?.toString() ?? 
                DateTime.now().toIso8601String()),
    );
  }

  // Untuk serialisasi JSON (menggunakan toMap)
  Map<String, dynamic> toJson() => toMap();

  // Untuk deserialisasi JSON (menggunakan fromMap)
  factory Transaction.fromJson(Map<String, dynamic> json) => 
      Transaction.fromMap(json);

  // Membuat salinan dengan perubahan opsional
  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? category,
    String? description,
    DateTime? dateTime,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}