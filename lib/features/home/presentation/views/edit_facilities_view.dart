import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

class EditFacilitiesView extends StatefulWidget {
  final String venueId;
  final Map<String, dynamic> venueData;

  const EditFacilitiesView({
    super.key,
    required this.venueId,
    required this.venueData,
  });

  @override
  State<EditFacilitiesView> createState() => _EditFacilitiesViewState();
}

class _EditFacilitiesViewState extends State<EditFacilitiesView> {
  bool _cafe = false;
  bool _changingRooms = false;
  bool _lighting = false;
  bool _parking = false;
  bool _showers = false;
  late TextEditingController _maxPlayersController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentFacilities();
  }

  void _loadCurrentFacilities() {
    final facilities =
        widget.venueData['facilities'] as Map<String, dynamic>? ?? {};
    _cafe = facilities['cafe'] ?? false;
    _changingRooms = facilities['changing_rooms'] ?? false;
    _lighting = facilities['lighting'] ?? false;
    _parking = facilities['parking'] ?? false;
    _showers = facilities['showers'] ?? false;
    _maxPlayersController = TextEditingController(
      text: (facilities['maxPlayers'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _maxPlayersController.dispose();
    super.dispose();
  }

  Future<void> _saveFacilities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('venues')
          .doc(widget.venueId)
          .update({
            'facilities': {
              'cafe': _cafe,
              'changing_rooms': _changingRooms,
              'lighting': _lighting,
              'parking': _parking,
              'showers': _showers,
              'maxPlayers': _maxPlayersController.text.trim(),
            },
            'updatedAt': DateTime.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facilities updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating facilities: $e')),
        );
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
        title: const Text('Edit Facilities'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Court Facilities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the facilities and amenities available at your court.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Cafe/Restaurant'),
                      subtitle: const Text('Food and beverage services'),
                      value: _cafe,
                      onChanged: (value) {
                        setState(() {
                          _cafe = value ?? false;
                        });
                      },
                      secondary: const Icon(Icons.restaurant),
                    ),
                    CheckboxListTile(
                      title: const Text('Changing Rooms'),
                      subtitle: const Text(
                        'Locker rooms and changing facilities',
                      ),
                      value: _changingRooms,
                      onChanged: (value) {
                        setState(() {
                          _changingRooms = value ?? false;
                        });
                      },
                      secondary: const Icon(Icons.room),
                    ),
                    CheckboxListTile(
                      title: const Text('Lighting'),
                      subtitle: const Text('Floodlights for evening play'),
                      value: _lighting,
                      onChanged: (value) {
                        setState(() {
                          _lighting = value ?? false;
                        });
                      },
                      secondary: const Icon(Icons.lightbulb),
                    ),
                    CheckboxListTile(
                      title: const Text('Parking'),
                      subtitle: const Text('Free parking available'),
                      value: _parking,
                      onChanged: (value) {
                        setState(() {
                          _parking = value ?? false;
                        });
                      },
                      secondary: const Icon(Icons.local_parking),
                    ),
                    CheckboxListTile(
                      title: const Text('Showers'),
                      subtitle: const Text('Shower facilities available'),
                      value: _showers,
                      onChanged: (value) {
                        setState(() {
                          _showers = value ?? false;
                        });
                      },
                      secondary: const Icon(Icons.shower),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Capacity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxPlayersController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Players',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                        hintText: 'e.g., 10',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Facilities Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFacilityRow('Cafe', _cafe),
                    _buildFacilityRow('Changing Rooms', _changingRooms),
                    _buildFacilityRow('Lighting', _lighting),
                    _buildFacilityRow('Parking', _parking),
                    _buildFacilityRow('Showers', _showers),
                    const Divider(),
                    _buildFacilityRow(
                      'Max Players',
                      _maxPlayersController.text.isNotEmpty,
                      value: _maxPlayersController.text,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveFacilities,
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
                    : const Text('Save Facilities'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityRow(String label, bool isAvailable, {String? value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (value != null && value.isNotEmpty)
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
          else
            Icon(
              isAvailable ? Icons.check_circle : Icons.cancel,
              color: isAvailable ? Colors.green : Colors.grey,
              size: 20,
            ),
        ],
      ),
    );
  }
}
