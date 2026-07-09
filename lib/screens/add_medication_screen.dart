import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _frequency = 'Once daily';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _notificationService = NotificationService();
  bool _isSaving = false;

  void _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final user = _authService.currentUser;
        if (user != null) {
          final now = DateTime.now();
          final scheduledTimeStr = _selectedTime.format(context);
          
          final med = MedicationModel(
            medId: '', // Firestore generates this
            userId: user.userId,
            medName: _nameController.text.trim(),
            dosage: _dosageController.text.trim(),
            frequency: _frequency,
            scheduledTime: scheduledTimeStr,
            startDate: now,
          );
          
          await _firestoreService.addMedication(med);
          
          // Schedule Notification (Basic Implementation for today)
          final scheduledDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            _selectedTime.hour,
            _selectedTime.minute,
          );
          
          if (scheduledDateTime.isAfter(now)) {
            await _notificationService.scheduleNotification(
              id: scheduledDateTime.millisecondsSinceEpoch ~/ 1000,
              title: 'Time to take your medication!',
              body: '${med.medName} ${med.dosage} - Tap to confirm',
              scheduledTime: scheduledDateTime,
            );
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved Successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Medicine Name',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Aspirin',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.search),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Medicine Name cannot be empty' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Dosage',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dosageController,
                  decoration: InputDecoration(
                    hintText: 'e.g., 100 mg',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Frequency',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFreqButton('Once daily'),
                    const SizedBox(width: 8),
                    _buildFreqButton('Twice daily'),
                    const SizedBox(width: 8),
                    _buildFreqButton('As needed'),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Time',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _selectedTime.format(context),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Schedule'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreqButton(String label) {
    bool isSelected = _frequency == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequency = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : Colors.grey,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
