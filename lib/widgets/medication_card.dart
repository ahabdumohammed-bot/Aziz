import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../theme/app_theme.dart';

class MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onTake;
  final VoidCallback onSkip;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onTake,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.medication,
            size: 40,
            color: AppTheme.primaryBlue.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${medication.medName}, ${medication.dosage}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  medication.scheduledTime,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                width: 90,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: onTake,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Take', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 90,
                height: 36,
                child: OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
