import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/image_picker_widget.dart';

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

  // Images
  final List<String> _imagePaths = [];
  final List<File> _selectedImageFiles = [];

  String? _selectedCategory;
  static const List<String> _categories = [
    'Football',
    'Basketball',
    'Tennis',
    'Volleyball',
    'Other',
  ];

  LatLng? _pickedLocation;

  Future<void> _pickLocation() async {
    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      return;
    }

    // Get current location as starting point
    Position? currentPosition;
    try {
      currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      // If we can't get current position, use a default location
      currentPosition = null;
    }

    final LatLng initialLocation = currentPosition != null
        ? LatLng(currentPosition.latitude, currentPosition.longitude)
        : const LatLng(37.422, -122.084); // Default to a location

    final LatLng? result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationPickerDialog(initialLocation: initialLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _pickedLocation = result;
      });
    }
  }

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

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Upload images to Supabase if any selected
        List<String> finalImageUrls = List.from(_imagePaths);

        if (_selectedImageFiles.isNotEmpty) {
          final courtId = DateTime.now().millisecondsSinceEpoch.toString();
          final uploadedUrls = await SupabaseService.uploadImages(
            imageFiles: _selectedImageFiles,
            courtId: courtId,
          );
          finalImageUrls.addAll(uploadedUrls);
        }

        // If no images, use default
        if (finalImageUrls.isEmpty) {
          finalImageUrls = [
            'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3',
          ];
        }

        final now = DateTime.now();
        final doc = <String, dynamic>{
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'location': _pickedLocation != null
              ? GeoPoint(_pickedLocation!.latitude, _pickedLocation!.longitude)
              : null,
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
          'images': finalImageUrls,
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
          'approved': false,
        };

        await FirebaseFirestore.instance.collection('venues').add(doc);

        // Hide loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Court saved successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        // Hide loading dialog
        Navigator.pop(context);

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
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_pickedLocation == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'No location selected',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Location Selected',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickLocation,
                  icon: const Icon(Icons.location_on),
                  label: Text(
                    _pickedLocation == null
                        ? 'Pick Location'
                        : 'Update Location',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
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
              ImagePickerWidget(
                initialImages: _imagePaths,
                onImagesChanged: (images) {
                  setState(() {
                    _imagePaths.clear();
                    _imagePaths.addAll(images);
                  });
                },
                onFilesChanged: (files) {
                  setState(() {
                    _selectedImageFiles.clear();
                    _selectedImageFiles.addAll(files);
                  });
                },
                maxImages: 5,
                imageSize: 100,
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

class LocationPickerDialog extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerDialog({super.key, required this.initialLocation});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    _updateMarkers();
  }

  void _updateMarkers() {
    _markers = [
      Marker(
        point: _selectedLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                  _updateMarkers();
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.courtly_owner',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          // Current location button
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton.small(
              onPressed: () async {
                try {
                  final position = await Geolocator.getCurrentPosition();
                  setState(() {
                    _selectedLocation = LatLng(
                      position.latitude,
                      position.longitude,
                    );
                    _mapController.move(_selectedLocation, 15.0);
                    _updateMarkers();
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not get current location'),
                    ),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, _selectedLocation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm Location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
