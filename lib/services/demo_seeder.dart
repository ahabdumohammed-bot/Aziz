import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/medication_model.dart';
import '../models/adherence_log_model.dart';

/// Populates Firestore with 3 demo user profiles, their medications,
/// and 30 days of realistic adherence logs — perfect for screenshots.
///
/// HOW TO USE:
///   await DemoSeeder.seed();
///
/// Demo accounts created:
///   alice@mediremind.com  / Demo1234!
///   bob@mediremind.com    / Demo1234!
///   carol@mediremind.com  / Demo1234!
class DemoSeeder {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static const _password = 'Demo1234!';

  static final List<Map<String, dynamic>> _users = [
    {
      'email': 'alice@mediremind.com',
      'fullName': 'Alice Johnson',
      'age': 52,
      'condition': 'Type 2 Diabetes',
    },
    {
      'email': 'bob@mediremind.com',
      'fullName': 'Bob Martinez',
      'age': 67,
      'condition': 'Hypertension & High Cholesterol',
    },
    {
      'email': 'carol@mediremind.com',
      'fullName': 'Carol Williams',
      'age': 38,
      'condition': 'Thyroid Disorder',
    },
  ];

  static final _medicationsPerUser = [
    // Alice — Diabetes
    [
      {
        'medName': 'Metformin',
        'dosage': '500 mg',
        'frequency': 'Twice daily',
        'scheduledTime': '8:00 AM',
        'category': 'Diabetes',
        'color': '#4A90D9',
      },
      {
        'medName': 'Glipizide',
        'dosage': '5 mg',
        'frequency': 'Once daily',
        'scheduledTime': '7:30 AM',
        'category': 'Diabetes',
        'color': '#7B68EE',
      },
      {
        'medName': 'Vitamin D3',
        'dosage': '1000 IU',
        'frequency': 'Once daily',
        'scheduledTime': '9:00 AM',
        'category': 'Vitamin',
        'color': '#F5A623',
      },
    ],
    // Bob — Hypertension & Cholesterol
    [
      {
        'medName': 'Lisinopril',
        'dosage': '10 mg',
        'frequency': 'Once daily',
        'scheduledTime': '8:00 AM',
        'category': 'Blood Pressure',
        'color': '#E74C3C',
      },
      {
        'medName': 'Atorvastatin',
        'dosage': '20 mg',
        'frequency': 'Once daily',
        'scheduledTime': '9:00 PM',
        'category': 'Cholesterol',
        'color': '#2ECC71',
      },
      {
        'medName': 'Amlodipine',
        'dosage': '5 mg',
        'frequency': 'Once daily',
        'scheduledTime': '8:00 AM',
        'category': 'Blood Pressure',
        'color': '#E67E22',
      },
      {
        'medName': 'Aspirin',
        'dosage': '81 mg',
        'frequency': 'Once daily',
        'scheduledTime': '8:00 AM',
        'category': 'Cardiac',
        'color': '#C0392B',
      },
    ],
    // Carol — Thyroid
    [
      {
        'medName': 'Levothyroxine',
        'dosage': '75 mcg',
        'frequency': 'Once daily',
        'scheduledTime': '6:30 AM',
        'category': 'Thyroid',
        'color': '#9B59B6',
      },
      {
        'medName': 'Calcium Carbonate',
        'dosage': '500 mg',
        'frequency': 'Twice daily',
        'scheduledTime': '1:00 PM',
        'category': 'Supplement',
        'color': '#1ABC9C',
      },
    ],
  ];

  /// Adherence patterns per user (30-day): true = Taken, false = Missed
  /// Alice: 87% adherence, Bob: 72% adherence, Carol: 95% adherence
  static List<bool> _generatePattern(int daysBack, double adherenceRate) {
    final rng = adherenceRate;
    return List.generate(daysBack, (i) {
      // Use deterministic pseudo-random based on index and rate
      final val = ((i * 7 + 13) % 100) / 100.0;
      return val < rng;
    });
  }

  static Future<void> seed() async {
    print('🌱 DemoSeeder: Starting...');

    for (int u = 0; u < _users.length; u++) {
      final userData = _users[u];
      final email = userData['email'] as String;
      final String fullName = userData['fullName'] as String;
      final int age = userData['age'] as int;
      final String condition = userData['condition'] as String;

      // Create Firebase Auth account
      String uid;
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: _password,
        );
        uid = cred.user!.uid;
        print('✅ Created auth: $email → $uid');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Sign in to get uid
          final cred = await _auth.signInWithEmailAndPassword(
            email: email,
            password: _password,
          );
          uid = cred.user!.uid;
          print('ℹ️  Auth exists: $email → $uid');
        } else {
          print('❌ Auth error for $email: ${e.message}');
          continue;
        }
      }

      // Save user profile
      final user = UserModel(
        userId: uid,
        email: email,
        fullName: fullName,
        age: age,
        condition: condition,
        createdAt: DateTime.now().subtract(Duration(days: 45)),
      );
      await _db.collection('users').doc(uid).set(user.toMap());
      print('✅ User profile saved: $fullName');

      // Adherence rates: Alice=87%, Bob=72%, Carol=95%
      final adherenceRates = [0.87, 0.72, 0.95];
      final adherenceRate = adherenceRates[u];

      // Add medications
      final meds = _medicationsPerUser[u];
      for (final medData in meds) {
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final med = MedicationModel(
          medId: '',
          userId: uid,
          medName: medData['medName']!,
          dosage: medData['dosage']!,
          frequency: medData['frequency']!,
          scheduledTime: medData['scheduledTime']!,
          startDate: startDate,
          category: medData['category']!,
          color: medData['color']!,
        );

        // Check if medication already exists
        final existing = await _db
            .collection('users')
            .doc(uid)
            .collection('medications')
            .where('medName', isEqualTo: med.medName)
            .get();

        String medId;
        if (existing.docs.isNotEmpty) {
          medId = existing.docs.first.id;
          print('ℹ️  Med exists: ${med.medName}');
        } else {
          final ref = await _db
              .collection('users')
              .doc(uid)
              .collection('medications')
              .add(med.toMap());
          medId = ref.id;
          print('✅ Medication saved: ${med.medName} → $medId');
        }

        // Generate 30 days of adherence logs
        final pattern = _generatePattern(30, adherenceRate);
        var batch = _db.batch();
        int logsAdded = 0;

        for (int day = 29; day >= 0; day--) {
          final taken = pattern[29 - day];
          final scheduledDate =
              DateTime.now().subtract(Duration(days: day));
          final scheduled = DateTime(
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
            8,
            0,
          );

          final status = taken ? 'Taken' : 'Missed';
          final log = AdherenceLogModel(
            logId: '',
            userId: uid,
            medId: medId,
            medName: med.medName,
            scheduledTime: scheduled,
            actualTakenTime: taken
                ? scheduled.add(const Duration(minutes: 5))
                : null,
            status: status,
          );

          final logRef = _db
              .collection('users')
              .doc(uid)
              .collection('medications')
              .doc(medId)
              .collection('adherenceLogs')
              .doc();
          batch.set(logRef, log.toMap());
          logsAdded++;

          // Firestore batch max is 500 — commit and re-create at 400
          if (logsAdded % 400 == 0) {
            await batch.commit();
            batch = _db.batch();
            print('  💾 Batch committed ($logsAdded logs)');
          }
        }
        await batch.commit();
        print('  📋 ${med.medName}: $logsAdded adherence logs written');
      }

      // Sign out after seeding each user to allow next createUserWithEmailAndPassword
      await _auth.signOut();
    }

    print('🎉 DemoSeeder: Complete! 3 users seeded with full medication & adherence data.');
    print('');
    print('Demo accounts:');
    for (final u in _users) {
      print('  ${u['email']} / $_password  (${u['fullName']})');
    }
  }

  /// Check if demo data already exists
  static Future<bool> isSeeded() async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: 'alice@mediremind.com')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
