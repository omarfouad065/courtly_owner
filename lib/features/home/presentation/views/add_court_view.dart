import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddCourtView extends StatefulWidget {
  const AddCourtView({super.key});

  @override
  State<AddCourtView> createState() => _AddCourtViewState();
}

class _AddCourtViewState extends State<AddCourtView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hourlyController = TextEditingController();
  final TextEditingController _dailyController = TextEditingController();
  final TextEditingController _weeklyController = TextEditingController();

  // Facilities
  bool _cafe = false;
  bool _changingRooms = false;
  bool _lighting = false;
  bool _parking = false;
  bool _showers = false;
  final TextEditingController _maxPlayersController = TextEditingController();

  // Availability (placeholder for advanced picker)
  Map<String, List<Map<String, TimeOfDay>>> _availability = {
    'monday': [],
    'tuesday': [],
    'wednesday': [],
    'thursday': [],
    'friday': [],
    'saturday': [],
    'sunday': [],
  };

  String _availabilitySummary() {
    final days = _availability.entries.where((e) => e.value.isNotEmpty);
    if (days.isEmpty) return 'No availability set';
    return days
        .map(
          (e) =>
              '${e.key[0].toUpperCase()}${e.key.substring(1)}: ${e.value.map((slot) => '${slot['start']!.format(context)}-${slot['end']!.format(context)}').join(', ')}',
        )
        .join(' | ');
  }

  Future<void> _showAvailabilityPicker() async {
    final result = await showDialog<Map<String, List<Map<String, TimeOfDay>>>>(
      context: context,
      builder: (context) => _AvailabilityPickerDialog(initial: _availability),
    );
    if (result != null) {
      setState(() {
        _availability = result;
      });
    }
  }

  // Images (placeholder for file upload)
  final List<String> _imagePaths = [];

  String? _selectedCategory;
  static const List<String> _categories = [
    'Football',
    'Basketball',
    'Tennis',
    'Volleyball',
    'Other',
  ];

  LatLng? _pickedLocation;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _hourlyController.dispose();
    _dailyController.dispose();
    _weeklyController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
          return;
        }
        final now = DateTime.now();
        final doc = <String, dynamic>{
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'location': _pickedLocation != null
              ? '[${_pickedLocation!.latitude}° N, ${_pickedLocation!.longitude}° W]'
              : '',
          'category': _selectedCategory,
          'description': _descriptionController.text.trim(),
          'availability': _availability.map(
            (day, slots) => MapEntry(
              day,
              slots
                  .map(
                    (slot) =>
                        '${slot['start']!.format(context)}-${slot['end']!.format(context)}',
                  )
                  .toList(),
            ),
          ),
          'facilities': {
            'cafe': _cafe,
            'changing_rooms': _changingRooms,
            'lighting': _lighting,
            'parking': _parking,
            'showers': _showers,
            'maxPlayers': _maxPlayersController.text.trim(),
          },
          'images': _imagePaths.isNotEmpty
              ? _imagePaths
              : [
                  'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3',
                ],
          'pricing': {
            'hourly': int.tryParse(_hourlyController.text.trim()) ?? 0,
            'daily': int.tryParse(_dailyController.text.trim()) ?? 0,
            'weekly': int.tryParse(_weeklyController.text.trim()) ?? 0,
          },
          'ownerId': user.uid,
          'isActive': true,
          'createdAt': now,
          'updatedAt': now,
          'rating': 0,
          'reviewCount': 0,
        };
        await FirebaseFirestore.instance.collection('venues').add(doc);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Court saved successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving court: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Court')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              // Location Picker
              const SizedBox(height: 16),
              const Text('Location'),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      // TODO: Implement Google Maps picker
                      // For now, set a dummy location
                      setState(() {
                        _pickedLocation = const LatLng(37.422, -122.084);
                      });
                    },
                    child: const Text('Pick Location'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickedLocation == null
                          ? 'No location selected'
                          : 'Lat: 	${_pickedLocation!.latitude}, Lng: ${_pickedLocation!.longitude}',
                    ),
                  ),
                ],
              ),
              // Category Dropdown
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Availability'),
              TextButton(
                onPressed: _showAvailabilityPicker,
                child: const Text('Set Availability'),
              ),
              Text(_availabilitySummary()),
              const SizedBox(height: 16),
              const Text('Facilities'),
              CheckboxListTile(
                title: const Text('Cafe'),
                value: _cafe,
                onChanged: (v) => setState(() => _cafe = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Changing Rooms'),
                value: _changingRooms,
                onChanged: (v) => setState(() => _changingRooms = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Lighting'),
                value: _lighting,
                onChanged: (v) => setState(() => _lighting = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Parking'),
                value: _parking,
                onChanged: (v) => setState(() => _parking = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Showers'),
                value: _showers,
                onChanged: (v) => setState(() => _showers = v ?? false),
              ),
              TextFormField(
                controller: _maxPlayersController,
                decoration: const InputDecoration(labelText: 'Max Players'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Images (file upload placeholder)'),
              TextButton(
                onPressed: () {
                  // TODO: Implement file picker for images
                },
                child: const Text('Upload Images'),
              ),
              const SizedBox(height: 16),
              const Text('Pricing'),
              TextFormField(
                controller: _hourlyController,
                decoration: const InputDecoration(labelText: 'Hourly'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _dailyController,
                decoration: const InputDecoration(labelText: 'Daily'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _weeklyController,
                decoration: const InputDecoration(labelText: 'Weekly'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Save Court'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityPickerDialog extends StatefulWidget {
  final Map<String, List<Map<String, TimeOfDay>>> initial;
  const _AvailabilityPickerDialog({required this.initial});

  @override
  State<_AvailabilityPickerDialog> createState() =>
      _AvailabilityPickerDialogState();
}

class _AvailabilityPickerDialogState extends State<_AvailabilityPickerDialog> {
  late Map<String, List<Map<String, TimeOfDay>>> _slots;
  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    _slots = Map.fromEntries(
      _days.map(
        (d) => MapEntry(
          d,
          List<Map<String, TimeOfDay>>.from(widget.initial[d] ?? []),
        ),
      ),
    );
  }

  void _addSlot(String day) async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 17, minute: 0),
    );
    if (end == null) return;
    setState(() {
      _slots[day]!.add({'start': start, 'end': end});
    });
  }

  void _removeSlot(String day, int idx) {
    setState(() {
      _slots[day]!.removeAt(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Availability'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: _days
              .map(
                (day) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(day[0].toUpperCase() + day.substring(1)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addSlot(day),
                        ),
                      ],
                    ),
                    ..._slots[day]!.asMap().entries.map(
                      (entry) => Row(
                        children: [
                          Text(
                            '${entry.value['start']!.format(context)} - ${entry.value['end']!.format(context)}',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () => _removeSlot(day, entry.key),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _slots),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
