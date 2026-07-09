import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/wellbeing_service.dart';
import '../models/medication_model.dart';
import '../models/adherence_log_model.dart';
import '../widgets/wellbeing_card.dart';
import '../widgets/medication_card.dart';
import '../theme/app_theme.dart';
import 'add_medication_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'games_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _wellbeingService = WellbeingService();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProgressScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GamesScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _logAdherence(MedicationModel med, String status) async {
    final user = _authService.currentUser;
    if (user != null) {
      final log = AdherenceLogModel(
        logId: '',
        userId: user.userId,
        medId: med.medId,
        medName: med.medName,
        scheduledTime: DateTime.now(),
        actualTakenTime: status == 'Taken' ? DateTime.now() : null,
        status: status,
      );
      await _firestoreService.logAdherence(user.userId, log);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'Taken' ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('${med.medName} marked as $status'),
            ],
          ),
          backgroundColor:
              status == 'Taken' ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final String todayDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediRemind'),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
              child: Text(
                _getInitials(user?.fullName ?? 'U'),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Greeting
              if (user != null)
                Text(
                  'Hello, ${user.fullName.split(' ').first} 👋',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              const SizedBox(height: 4),
              WellbeingCard(quote: _wellbeingService.getTodayQuote()),
              const SizedBox(height: 20),
              Text(
                todayDate,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Schedule",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (user != null)
                    StreamBuilder<List<MedicationModel>>(
                      stream: _firestoreService.getMedications(user.userId),
                      builder: (context, snap) {
                        final count = snap.data?.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count meds',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: user == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<MedicationModel>>(
                        stream: _firestoreService.getMedications(user.userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.medication_outlined,
                                      size: 64,
                                      color: Colors.grey.withValues(alpha: 0.4)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No medications scheduled.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const AddMedicationScreen()),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Medication'),
                                  ),
                                ],
                              ),
                            );
                          }
                          final meds = snapshot.data!;
                          return ListView.builder(
                            itemCount: meds.length,
                            itemBuilder: (context, index) {
                              final med = meds[index];
                              return MedicationCard(
                                medication: med,
                                onTake: () => _logAdherence(med, 'Taken'),
                                onSkip: () => _logAdherence(med, 'Missed'),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_outlined),
            activeIcon: Icon(Icons.sports_esports),
            label: 'Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        onTap: _onItemTapped,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
