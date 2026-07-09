class UserModel {
  final String userId;
  final String email;
  final String fullName;
  final int age;
  final String condition; // e.g. "Type 2 Diabetes", "Hypertension"
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.fullName,
    this.age = 0,
    this.condition = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'age': age,
      'condition': condition,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parsedDate;
    if (map['createdAt'] is String) {
      parsedDate = DateTime.parse(map['createdAt']);
    } else {
      parsedDate = DateTime.now();
    }
    return UserModel(
      userId: documentId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      age: map['age'] ?? 0,
      condition: map['condition'] ?? '',
      createdAt: parsedDate,
    );
  }
}
