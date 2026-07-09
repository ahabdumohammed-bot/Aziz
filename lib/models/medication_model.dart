import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationModel {
  final String medId;
  final String userId;
  final String medName;
  final String dosage;
  final String frequency;
  final String scheduledTime;
  final DateTime startDate;
  final String category; // e.g. "Diabetes", "Blood Pressure", "Vitamin"
  final String color;   // hex color for card UI

  MedicationModel({
    required this.medId,
    required this.userId,
    required this.medName,
    required this.dosage,
    required this.frequency,
    required this.scheduledTime,
    required this.startDate,
    this.category = '',
    this.color = '#4A90D9',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'medName': medName,
      'dosage': dosage,
      'frequency': frequency,
      'scheduledTime': scheduledTime,
      'startDate': Timestamp.fromDate(startDate),
      'category': category,
      'color': color,
    };
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parsedDate;
    if (map['startDate'] is Timestamp) {
      parsedDate = (map['startDate'] as Timestamp).toDate();
    } else if (map['startDate'] is String) {
      parsedDate = DateTime.parse(map['startDate']);
    } else {
      parsedDate = DateTime.now();
    }
    return MedicationModel(
      medId: documentId,
      userId: map['userId'] ?? '',
      medName: map['medName'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '',
      startDate: parsedDate,
      category: map['category'] ?? '',
      color: map['color'] ?? '#4A90D9',
    );
  }
}
