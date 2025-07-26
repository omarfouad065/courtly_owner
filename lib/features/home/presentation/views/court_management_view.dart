import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

class CourtManagementView extends StatefulWidget {
  final String venueId;
  final Map<String, dynamic> venueData;

  const CourtManagementView({
    super.key,
    required this.venueId,
    required this.venueData,
  });

  @override
  State<CourtManagementView> createState() => _CourtManagementViewState();
}

class _CourtManagementViewState extends State<CourtManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAvailable = true;
  Map<String, List<Map<String, TimeOfDay>>> _availability = {
    'monday': [],
    'tuesday': [],
    'wednesday': [],
    'thursday': [],
    'friday': [],
    'saturday': [],
    'sunday': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVenueData();
  }

  void _loadVenueData() {
    setState(() {
      _isAvailable = widget.venueData['isActive'] ?? true;
      final availability =
          widget.venueData['availability'] as Map<String, dynamic>?;
      if (availability != null) {
        _availability = availability.map((day, slots) {
          List<Map<String, TimeOfDay>> timeSlots = [];
          if (slots is List) {
            for (var slot in slots) {
              if (slot is String) {
                final times = slot.split('-');
                if (times.length == 2) {
                  final startTime = _parseTimeString(times[0]);
                  final endTime = _parseTimeString(times[1]);
                  if (startTime != null && endTime != null) {
                    timeSlots.add({'start': startTime, 'end': endTime});
                  }
                }
              }
            }
          }
          return MapEntry(day, timeSlots);
        });
      }
    });
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final cleanTime = timeStr.trim();

      // Handle 12-hour format with AM/PM
      if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
        final timePart = cleanTime
            .replaceAll('AM', '')
            .replaceAll('PM', '')
            .trim();
        final parts = timePart.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          // Convert to 24-hour format
          if (cleanTime.contains('PM') && hour != 12) {
            hour += 12;
          } else if (cleanTime.contains('AM') && hour == 12) {
            hour = 0;
          }

          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      // Handle 24-hour format (HH:MM)
      final parts = cleanTime.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time: $timeStr - $e');
    }
    return null;
  }

  // Helper to format TimeOfDay as 24-hour string
  String _formatTimeOfDay24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _updateAvailability() async {
    try {
      final availabilityMap = _availability.map(
        (day, slots) => MapEntry(
          day,
          slots
              .map(
                (slot) =>
                    '${_formatTimeOfDay24(slot['start']!)}-${_formatTimeOfDay24(slot['end']!)}',
              )
              .toList(),
        ),
      );

      await FirebaseFirestore.instance
          .collection('venues')
          .doc(widget.venueId)
          .update({
            'isActive': _isAvailable,
            'availability': availabilityMap,
            'updatedAt': DateTime.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Availability updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating availability: $e')),
      );
    }
  }

  void _addTimeSlot(String day) {
    showDialog(
      context: context,
      builder: (context) => _TimeSlotDialog(
        onAdd: (start, end) {
          setState(() {
            _availability[day]!.add({'start': start, 'end': end});
          });
        },
      ),
    );
  }

  void _removeTimeSlot(String day, int index) {
    setState(() {
      _availability[day]!.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Manage ${widget.venueData['name'] ?? 'Court'}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Availability'),
            Tab(text: 'Time Slots'),
            Tab(text: 'Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailabilityTab(),
          _buildTimeSlotsTab(),
          _buildBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Court Available'),
              subtitle: Text(
                _isAvailable ? 'Court is open for bookings' : 'Court is closed',
              ),
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
                _updateAvailability();
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('venueId', isEqualTo: widget.venueId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildStatsCard(0, 0, 0);
              }
              final bookings = snapshot.data!.docs;
              final now = DateTime.now();
              final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
              int totalBookings = 0;
              int thisWeek = 0;
              double revenue = 0;
              for (var doc in bookings) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['status'] ?? 'pending')
                    .toString()
                    .toLowerCase();
                if (status == 'confirmed') {
                  totalBookings++;
                  final startTime = (data['startTime'] as Timestamp).toDate();
                  if (startTime.isAfter(startOfWeek)) {
                    thisWeek++;
                  }
                  final amount = data['totalAmount'];
                  if (amount is int) {
                    revenue += amount.toDouble();
                  } else if (amount is double) {
                    revenue += amount;
                  }
                }
              }
              return _buildStatsCard(totalBookings, thisWeek, revenue);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int totalBookings, int thisWeek, double revenue) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total Bookings', totalBookings.toString()),
                _buildStatItem('This Week', thisWeek.toString()),
                _buildStatItem('Revenue', ' EGP ${revenue.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimeSlotsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _availability.length,
              itemBuilder: (context, index) {
                final day = _availability.keys.elementAt(index);
                final slots = _availability[day]!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(
                      day.substring(0, 1).toUpperCase() + day.substring(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      ...slots.asMap().entries.map((entry) {
                        final slotIndex = entry.key;
                        final slot = entry.value;
                        return ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(
                            '${slot['start']!.format(context)} - ${slot['end']!.format(context)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeTimeSlot(day, slotIndex),
                          ),
                        );
                      }),
                      ListTile(
                        leading: const Icon(
                          Icons.add,
                          color: AppColors.primary,
                        ),
                        title: const Text('Add Time Slot'),
                        onTap: () => _addTimeSlot(day),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: _updateAvailability,
              child: const Text('Save Schedule'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('venueId', isEqualTo: widget.venueId)
          .orderBy('startTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No bookings found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final bookings = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index].data() as Map<String, dynamic>;
            final startTime = (booking['startTime'] as Timestamp).toDate();
            final endTime = (booking['endTime'] as Timestamp).toDate();
            final status = booking['status'] ?? 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status),
                  child: Icon(_getStatusIcon(status), color: Colors.white),
                ),
                title: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(booking['userId'])
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const Text('Unknown User');
                    }
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    return Text(
                      userData['name'] ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatDateTime(startTime)} - ${_formatTime(endTime)}',
                    ),
                    Text(
                      'Status: ${status.toUpperCase()}',
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  'EGP ${booking['totalAmount']?.toString() ?? '0'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _TimeSlotDialog extends StatefulWidget {
  final Function(TimeOfDay start, TimeOfDay end) onAdd;

  const _TimeSlotDialog({required this.onAdd});

  @override
  State<_TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<_TimeSlotDialog> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Time Slot'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Start Time'),
            trailing: TextButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                );
                if (time != null) {
                  setState(() {
                    _startTime = time;
                  });
                }
              },
              child: Text(_startTime.format(context)),
            ),
          ),
          ListTile(
            title: const Text('End Time'),
            trailing: TextButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                );
                if (time != null) {
                  setState(() {
                    _endTime = time;
                  });
                }
              },
              child: Text(_endTime.format(context)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(_startTime, _endTime);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
