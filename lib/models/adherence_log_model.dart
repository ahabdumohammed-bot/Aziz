import 'package:cloud_firestore/cloud_firestore.dart';

class AdherenceLogModel {
  final String logId;
  final String userId; // required for collection-group queries
  final String medId;
  final String medName; // denormalized for easy display
  final DateTime scheduledTime;
  final DateTime? actualTakenTime;
  final String status; // "Taken" | "Missed" | "Snoozed"

  AdherenceLogModel({
    required this.logId,
    required this.userId,
    required this.medId,
    this.medName = '',
    required this.scheduledTime,
    this.actualTakenTime,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'medId': medId,
      'medName': medName,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'actualTakenTime':
          actualTakenTime != null ? Timestamp.fromDate(actualTakenTime!) : null,
      'status': status,
    };
  }

  factory AdherenceLogModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    DateTime parseTs(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    DateTime? parseOptTs(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return null;
    }

    return AdherenceLogModel(
      logId: documentId,
      userId: map['userId'] ?? '',
      medId: map['medId'] ?? '',
      medName: map['medName'] ?? '',
      scheduledTime: parseTs(map['scheduledTime']),
      actualTakenTime: parseOptTs(map['actualTakenTime']),
      status: map['status'] ?? 'Missed',
    );
  }
}
