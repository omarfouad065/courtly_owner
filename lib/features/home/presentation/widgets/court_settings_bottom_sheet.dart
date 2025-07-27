import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../views/court_management_view.dart';

class CourtSettingsBottomSheet extends StatelessWidget {
  final String venueId;
  final Map<String, dynamic> venueData;

  const CourtSettingsBottomSheet({
    super.key,
    required this.venueId,
    required this.venueData,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Handle bar for dragging
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            const CourtSettingsHeader(),
            const SizedBox(height: 20),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    CourtSettingsListTile(
                      icon: Icons.edit,
                      title: 'Edit Court',
                      subtitle: 'Modify court details and information',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourtManagementView(
                              venueId: venueId,
                              venueData: venueData,
                            ),
                          ),
                        );
                      },
                    ),
                    CourtSettingsListTile(
                      icon: Icons.photo_library,
                      title: 'Manage Images',
                      subtitle: 'Add, remove, or reorder court images',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image management coming soon!'),
                          ),
                        );
                      },
                    ),
                    CourtSettingsListTile(
                      icon: Icons.schedule,
                      title: 'Availability Settings',
                      subtitle: 'Set court availability and time slots',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Availability settings coming soon!'),
                          ),
                        );
                      },
                    ),
                    CourtSettingsListTile(
                      icon: Icons.attach_money,
                      title: 'Pricing Settings',
                      subtitle: 'Update hourly, daily, and weekly rates',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pricing settings coming soon!'),
                          ),
                        );
                      },
                    ),
                    CourtSettingsListTile(
                      icon: Icons.analytics,
                      title: 'View Analytics',
                      subtitle: 'Check booking statistics and revenue',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Analytics coming soon!'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    CourtDeleteButton(venueId: venueId),
                    const SizedBox(height: 20), // Bottom padding for scroll
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourtSettingsHeader extends StatelessWidget {
  const CourtSettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.settings, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          'Court Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class CourtSettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const CourtSettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class CourtDeleteButton extends StatelessWidget {
  final String venueId;

  const CourtDeleteButton({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _handleDeleteCourt(context),
        child: const Text('Delete Court'),
      ),
    );
  }

  Future<void> _handleDeleteCourt(BuildContext context) async {
    Navigator.pop(context);

    // Check if there are any bookings
    final bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('venueId', isEqualTo: venueId)
        .limit(1)
        .get();

    if (bookings.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: There are bookings for this court.'),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Court'),
        content: const Text(
          'Are you sure you want to delete this court? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Court deleted successfully.')),
      );
    }
  }
}
