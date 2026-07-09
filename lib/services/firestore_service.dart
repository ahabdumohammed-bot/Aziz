import 'dart:async';
import '../models/medication_model.dart';
import '../models/adherence_log_model.dart';
import '../models/user_model.dart';

/// In-memory local service — mirrors the FirestoreService API so all screens
/// compile and work without any Firestore connection.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // In-memory stores keyed by userId
  final Map<String, List<MedicationModel>> _medications = {};
  final Map<String, List<AdherenceLogModel>> _adherenceLogs = {};

  // ─── User ────────────────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    // No-op in local mode
  }

  Future<UserModel?> getUser(String uid) async => null;

  Stream<UserModel?> streamUser(String uid) => Stream.value(null);

  // ─── Medications ─────────────────────────────────────────────────────────

  Future<String> addMedication(MedicationModel medication) async {
    final id = 'med-${DateTime.now().millisecondsSinceEpoch}';
    final med = MedicationModel(
      medId: id,
      userId: medication.userId,
      medName: medication.medName,
      dosage: medication.dosage,
      frequency: medication.frequency,
      scheduledTime: medication.scheduledTime,
      startDate: medication.startDate,
      color: medication.color,
      category: medication.category,
    );
    _medications.putIfAbsent(medication.userId, () => []).add(med);
    _medicationsController(medication.userId);
    return id;
  }

  Future<void> setMedication(MedicationModel medication) async {
    final list = _medications[medication.userId] ?? [];
    final idx = list.indexWhere((m) => m.medId == medication.medId);
    if (idx >= 0) {
      list[idx] = medication;
    } else {
      list.add(medication);
    }
    _medications[medication.userId] = list;
    _medicationsController(medication.userId);
  }

  Future<void> deleteMedication(String userId, String medId) async {
    _medications[userId]?.removeWhere((m) => m.medId == medId);
    _medicationsController(userId);
  }

  // Stream controllers for real-time-like updates
  final Map<String, _StreamWrapper<List<MedicationModel>>> _medStreams = {};

  void _medicationsController(String userId) {
    _medStreams[userId]?.add(_medications[userId] ?? []);
  }

  Stream<List<MedicationModel>> getMedications(String userId) {
    if (!_medStreams.containsKey(userId)) {
      _medStreams[userId] = _StreamWrapper<List<MedicationModel>>(
        _medications[userId] ?? [],
      );
    }
    return _medStreams[userId]!.stream;
  }

  // ─── Adherence Logs ──────────────────────────────────────────────────────

  Future<void> logAdherence(String userId, AdherenceLogModel log) async {
    final id = 'log-${DateTime.now().millisecondsSinceEpoch}';
    final saved = AdherenceLogModel(
      logId: id,
      userId: log.userId,
      medId: log.medId,
      medName: log.medName,
      scheduledTime: log.scheduledTime,
      actualTakenTime: log.actualTakenTime,
      status: log.status,
    );
    _adherenceLogs.putIfAbsent(userId, () => []).add(saved);
    _logsController(userId);
  }

  final Map<String, _StreamWrapper<List<AdherenceLogModel>>> _logStreams = {};

  void _logsController(String userId) {
    final logs = _adherenceLogs[userId] ?? [];
    logs.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    _logStreams[userId]?.add(logs);
  }

  Stream<List<AdherenceLogModel>> getAdherenceLogs(String userId) {
    if (!_logStreams.containsKey(userId)) {
      _logStreams[userId] = _StreamWrapper<List<AdherenceLogModel>>(
        _adherenceLogs[userId] ?? [],
      );
    }
    return _logStreams[userId]!.stream;
  }

  Stream<List<AdherenceLogModel>> getMedicationLogs(
      String userId, String medId) {
    return getAdherenceLogs(userId).map(
      (logs) => logs.where((l) => l.medId == medId).toList(),
    );
  }

  Future<List<AdherenceLogModel>> getAllLogsForUser(String userId) async {
    final logs = _adherenceLogs[userId] ?? [];
    logs.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    return logs;
  }

  Stream<List<AdherenceLogModel>> streamAllLogsForUser(String userId) async* {
    yield await getAllLogsForUser(userId);
  }
}

/// A simple broadcast-stream wrapper that emits the latest value + updates.
class _StreamWrapper<T> {
  late T _current;
  final _controller =
      // ignore: close_sinks
      StreamController<T>.broadcast();

  _StreamWrapper(T initial) {
    _current = initial;
    // Emit initial after microtask so listeners attach first
    Future.microtask(() => _controller.add(_current));
  }

  void add(T value) {
    _current = value;
    _controller.add(value);
  }

  Stream<T> get stream => _controller.stream;
}


