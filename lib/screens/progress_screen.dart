import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/adherence_log_model.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'add_medication_screen.dart';
import 'games_screen.dart';
import 'profile_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<AdherenceLogModel>>(
                stream: _firestoreService.getAdherenceLogs(user.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snapshot.data ?? [];

                  // Calculate adherence
                  int taken = 0;
                  int total = logs.length;
                  for (var log in logs) {
                    if (log.status == 'Taken') taken++;
                  }

                  double adherencePercent =
                      total > 0 ? (taken / total) : 0.0;
                  int displayPercent = (adherencePercent * 100).round();

                  // Build per-day history (last 7 days with data)
                  final Map<String, List<AdherenceLogModel>> byDay = {};
                  for (final log in logs) {
                    final key = DateFormat('yyyy-MM-dd')
                        .format(log.scheduledTime);
                    byDay.putIfAbsent(key, () => []).add(log);
                  }
                  final sortedDays = byDay.keys.toList()
                    ..sort((a, b) => b.compareTo(a));
                  final recentDays = sortedDays.take(7).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularPercentIndicator(
                          radius: 80.0,
                          lineWidth: 16.0,
                          animation: true,
                          percent: adherencePercent.clamp(0.0, 1.0),
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$displayPercent%',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      color: AppTheme.primaryBlue,
                                    ),
                              ),
                              Text(
                                'Adherence',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: displayPercent >= 80
                              ? AppTheme.primaryBlue
                              : displayPercent >= 60
                                  ? Colors.orange
                                  : Colors.red,
                          backgroundColor: Colors.grey[200]!,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Overall',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayPercent >= 80
                              ? 'Great Job! 🎉'
                              : displayPercent >= 60
                                  ? 'Keep it up! 💪'
                                  : 'Needs Improvement',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: displayPercent >= 80
                                    ? Colors.green
                                    : displayPercent >= 60
                                        ? Colors.orange
                                        : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 32),

                        // Calendar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 10, 16),
                            lastDay: DateTime.utc(2030, 3, 14),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            calendarStyle: const CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                final hasTaken = logs.any((l) =>
                                    isSameDay(l.scheduledTime, date) &&
                                    l.status == 'Taken');
                                final hasMissed = logs.any((l) =>
                                    isSameDay(l.scheduledTime, date) &&
                                    l.status == 'Missed');

                                if (hasTaken || hasMissed) {
                                  return Positioned(
                                    bottom: 1,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: hasTaken
                                            ? AppTheme.primaryBlue
                                            : AppTheme.errorRed,
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // History section — real data
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'History',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (logs.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.history,
                                    color: Colors.grey),
                                SizedBox(width: 12),
                                Text('No adherence records yet.',
                                    style:
                                        TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        else
                          ...recentDays.map((dayKey) {
                            final dayLogs = byDay[dayKey]!;
                            final dayTaken = dayLogs
                                .where((l) => l.status == 'Taken')
                                .length;
                            final dayTotal = dayLogs.length;
                            final allTaken = dayTaken == dayTotal;
                            final date = DateTime.parse(dayKey);
                            final now = DateTime.now();
                            final isToday = isSameDay(date, now);
                            final isYesterday = isSameDay(
                                date,
                                now.subtract(
                                    const Duration(days: 1)));

                            String label;
                            if (isToday) {
                              label = 'Today';
                            } else if (isYesterday) {
                              label = 'Yesterday';
                            } else {
                              label = DateFormat('MMM d').format(date);
                            }

                            return _buildHistoryItem(
                              label,
                              '$dayTaken/$dayTotal doses taken',
                              allTaken,
                            );
                          }),
                      ],
                    ),
                  );
                },
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

  Widget _buildHistoryItem(
      String date, String subtitle, bool allTaken) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: allTaken ? AppTheme.primaryBlue : Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Icon(
              allTaken ? Icons.check : Icons.remove,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date,
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
