import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

class EditPricingView extends StatefulWidget {
  final String venueId;
  final Map<String, dynamic> venueData;

  const EditPricingView({
    super.key,
    required this.venueId,
    required this.venueData,
  });

  @override
  State<EditPricingView> createState() => _EditPricingViewState();
}

class _EditPricingViewState extends State<EditPricingView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hourlyController;
  late TextEditingController _dailyController;
  late TextEditingController _weeklyController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final pricing = widget.venueData['pricing'] as Map<String, dynamic>? ?? {};
    _hourlyController = TextEditingController(
      text: (pricing['hourly'] ?? 0).toString(),
    );
    _dailyController = TextEditingController(
      text: (pricing['daily'] ?? 0).toString(),
    );
    _weeklyController = TextEditingController(
      text: (pricing['weekly'] ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _hourlyController.dispose();
    _dailyController.dispose();
    _weeklyController.dispose();
    super.dispose();
  }

  Future<void> _savePricing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('venues')
          .doc(widget.venueId)
          .update({
            'pricing': {
              'hourly': int.tryParse(_hourlyController.text.trim()) ?? 0,
              'daily': int.tryParse(_dailyController.text.trim()) ?? 0,
              'weekly': int.tryParse(_weeklyController.text.trim()) ?? 0,
            },
            'updatedAt': DateTime.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pricing updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating pricing: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Pricing'),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Court Pricing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set your court rental rates. All prices should be in your local currency.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _hourlyController,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  suffixText: 'per hour',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Hourly rate is required';
                  }
                  final rate = int.tryParse(value.trim());
                  if (rate == null || rate < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dailyController,
                decoration: const InputDecoration(
                  labelText: 'Daily Rate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixText: 'per day',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Daily rate is required';
                  }
                  final rate = int.tryParse(value.trim());
                  if (rate == null || rate < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weeklyController,
                decoration: const InputDecoration(
                  labelText: 'Weekly Rate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.date_range),
                  suffixText: 'per week',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Weekly rate is required';
                  }
                  final rate = int.tryParse(value.trim());
                  if (rate == null || rate < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pricing Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPricingRow('Hourly', _hourlyController.text),
                      _buildPricingRow('Daily', _dailyController.text),
                      _buildPricingRow('Weekly', _weeklyController.text),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePricing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Pricing'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingRow(String label, String value) {
    final rate = int.tryParse(value.trim()) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            rate > 0 ? '\$$rate' : 'Not set',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: rate > 0 ? AppColors.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
