import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BookingStatusNotifier {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<QuerySnapshot>? _bookingSubscription;
  StreamSubscription<QuerySnapshot>? _venueSubscription;
  StreamSubscription<QuerySnapshot>? _approvalSubscription;
  final Map<String, String> _lastStatuses = {};
  final Map<String, bool> _lastApprovalStatus = {};
  List<String> _venueIds = [];
  Map<String, String> _venueNames = {};
  String? _ownerId;

  Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _ownerId = user.uid;

    // Listen to venues owned by the current user
    _venueSubscription?.cancel();
    _venueSubscription = FirebaseFirestore.instance
        .collection('venues')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .listen((venueSnapshot) {
          _venueIds = venueSnapshot.docs.map((doc) => doc.id).toList();
          _venueNames = {
            for (var doc in venueSnapshot.docs)
              doc.id: (doc.data())['name'] ?? 'Court',
          };
          _listenToBookings();
          _listenToApprovals(venueSnapshot.docs);
        });
  }

  void _listenToBookings() {
    _bookingSubscription?.cancel();
    if (_venueIds.isEmpty) return;
    // Listen to bookings for all owned venues
    _bookingSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where(
          'venueId',
          whereIn: _venueIds.length > 10 ? _venueIds.sublist(0, 10) : _venueIds,
        )
        .snapshots()
        .listen((snapshot) async {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final status = (data['status'] ?? 'pending')
                .toString()
                .toLowerCase();
            final bookingId = doc.id;
            final lastStatus = _lastStatuses[bookingId];

            // Handle different booking status changes
            if (lastStatus != null && lastStatus != status) {
              final venueId = data['venueId'] as String?;
              final userId = data['userId'] as String?;
              String courtName = 'Court';
              String userName = 'A user';

              if (venueId != null && _venueNames.containsKey(venueId)) {
                courtName = _venueNames[venueId]!;
              }
              if (userId != null) {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get();
                if (userDoc.exists) {
                  final userData = userDoc.data() as Map<String, dynamic>;
                  userName = userData['name'] ?? userName;
                }
              }

              // Handle different status changes
              if (lastStatus == 'pending' && status == 'confirmed') {
                final message =
                    '$userName has a confirmed booking for $courtName.';
                _showBookingConfirmedNotification(courtName, userName);
                _writeNotificationToFirestore(message, 'booking_confirmed');
              } else if (lastStatus == 'confirmed' && status == 'cancelled') {
                final message =
                    '$userName cancelled their booking for $courtName.';
                _showBookingCancelledNotification(courtName, userName);
                _writeNotificationToFirestore(message, 'booking_cancelled');
              } else if (lastStatus == 'pending' && status == 'cancelled') {
                final message =
                    '$userName cancelled their pending booking for $courtName.';
                _showBookingCancelledNotification(courtName, userName);
                _writeNotificationToFirestore(message, 'booking_cancelled');
              }
            }
            _lastStatuses[bookingId] = status;
          }
        });
  }

  /// Send daily booking summary notification
  Future<void> sendDailyBookingSummary() async {
    if (_ownerId == null || _venueIds.isEmpty) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    int totalBookings = 0;
    double totalRevenue = 0;
    Map<String, int> bookingsPerCourt = {};

    for (final venueId in _venueIds) {
      final bookingsRef = FirebaseFirestore.instance
          .collection('bookings')
          .where('venueId', isEqualTo: venueId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'confirmed');

      final snapshot = await bookingsRef.get();
      final courtName = _venueNames[venueId] ?? 'Court';

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalBookings++;
        final amount = data['totalAmount'] ?? 0;
        if (amount is int) {
          totalRevenue += amount.toDouble();
        } else if (amount is double) {
          totalRevenue += amount;
        }
        bookingsPerCourt[courtName] = (bookingsPerCourt[courtName] ?? 0) + 1;
      }
    }

    if (totalBookings > 0) {
      final message =
          'Today: $totalBookings bookings, EGP ${totalRevenue.toStringAsFixed(2)} revenue';
      _showDailySummaryNotification(totalBookings, totalRevenue);
      _writeNotificationToFirestore(message, 'daily_summary');
    }
  }

  /// Send payment confirmation notification
  Future<void> sendPaymentConfirmation(
    String bookingId,
    double amount,
    String courtName,
  ) async {
    final message =
        'Payment received: EGP ${amount.toStringAsFixed(2)} for $courtName';
    _showPaymentNotification(amount, courtName);
    _writeNotificationToFirestore(message, 'payment_received');
  }

  /// Send review notification
  Future<void> sendReviewNotification(
    String courtName,
    double rating,
    String reviewText,
  ) async {
    final message =
        'New review for $courtName: ${rating.toStringAsFixed(1)} stars';
    _showReviewNotification(courtName, rating);
    _writeNotificationToFirestore(message, 'new_review');
  }

  void _listenToApprovals(List<QueryDocumentSnapshot> docs) async {
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final approved = data['approved'] == true;
      final venueId = doc.id;

      // Check if we've already sent a notification for this approval
      // We'll use a field in the venue document itself to track this
      final hasNotificationBeenSent = data['approvalNotificationSent'] == true;

      // Only send notification if:
      // 1. Court is approved
      // 2. We haven't sent a notification for this approval yet
      if (approved && !hasNotificationBeenSent) {
        final courtName = data['name'] ?? 'Court';
        print(
          'Sending approval notification for court: $courtName (ID: $venueId)',
        );
        _showApprovalNotification(courtName);
        _writeNotificationToFirestore(
          'Your court "$courtName" has been approved!',
          'court_approved',
        );

        // Mark that we've sent a notification for this approval
        // Update the venue document to track this
        await FirebaseFirestore.instance
            .collection('venues')
            .doc(venueId)
            .update({
              'approvalNotificationSent': true,
              'approvalNotificationTimestamp': FieldValue.serverTimestamp(),
            });
      } else if (approved && hasNotificationBeenSent) {
        print(
          'Skipping approval notification for court ID: $venueId (already sent)',
        );
      } else if (!approved && hasNotificationBeenSent) {
        // If court is no longer approved, reset the notification status
        // so that if it gets approved again, we can send a new notification
        print(
          'Resetting approval notification status for court ID: $venueId (no longer approved)',
        );
        await FirebaseFirestore.instance
            .collection('venues')
            .doc(venueId)
            .update({
              'approvalNotificationSent': false,
              'approvalNotificationTimestamp': null,
            });
      }

      _lastApprovalStatus[venueId] = approved;
    }
  }

  /// Reset approval notification status for a specific venue
  /// This can be useful for testing or if you want to resend notifications
  Future<void> resetApprovalNotification(String venueId) async {
    await FirebaseFirestore.instance.collection('venues').doc(venueId).update({
      'approvalNotificationSent': false,
      'approvalNotificationTimestamp': null,
    });
  }

  /// Reset all approval notifications for the current user's venues
  Future<void> resetAllApprovalNotifications() async {
    if (_ownerId == null) return;

    final venuesRef = FirebaseFirestore.instance
        .collection('venues')
        .where('ownerId', isEqualTo: _ownerId);

    final snapshot = await venuesRef.get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'approvalNotificationSent': false,
        'approvalNotificationTimestamp': null,
      });
    }
  }

  /// Schedule daily summary notifications
  /// Call this method to set up daily summary notifications
  Future<void> scheduleDailySummaries() async {
    // This would typically be called once when the app starts
    // In a real app, you might use a background task or cloud function
    // For now, we'll just set up the structure
    print('Daily summary notifications scheduled');
  }

  /// Manually trigger a daily summary (for testing)
  Future<void> triggerDailySummary() async {
    await sendDailyBookingSummary();
  }

  /// Send a test notification (for debugging)
  Future<void> sendTestNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Notification channel for testing',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(
      999,
      'Test Notification',
      message,
      platformChannelSpecifics,
      payload: 'test',
    );
  }

  /// Get notification statistics for the current user
  Future<Map<String, dynamic>> getNotificationStats() async {
    if (_ownerId == null) return {};

    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_ownerId)
        .collection('notifications');

    final snapshot = await notificationsRef.get();
    final notifications = snapshot.docs;

    Map<String, int> typeCounts = {};
    int totalUnread = 0;

    for (final doc in notifications) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] ?? 'general';
      final read = data['read'] ?? false;

      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      if (!read) totalUnread++;
    }

    return {
      'total': notifications.length,
      'unread': totalUnread,
      'byType': typeCounts,
    };
  }

  void stopListening() {
    _bookingSubscription?.cancel();
    _bookingSubscription = null;
    _venueSubscription?.cancel();
    _venueSubscription = null;
  }

  Future<void> _showBookingConfirmedNotification(
    String courtName,
    String userName,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'booking_channel',
          'Booking Notifications',
          channelDescription: 'Notification channel for booking updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(
      0,
      'Booking Confirmed!',
      '$userName has a confirmed booking for $courtName.',
      platformChannelSpecifics,
      payload: 'booking_confirmed',
    );
  }

  Future<void> _showApprovalNotification(String courtName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'approval_channel',
          'Approval Notifications',
          channelDescription: 'Notification channel for court approval updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(
      1,
      'Court Approved!',
      'Your court "$courtName" has been approved.',
      platformChannelSpecifics,
      payload: 'court_approved',
    );
  }

  Future<void> _showBookingCancelledNotification(
    String courtName,
    String userName,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'booking_channel',
          'Booking Notifications',
          channelDescription: 'Notification channel for booking updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(
      2,
      'Booking Cancelled',
      '$userName cancelled their booking for $courtName.',
      platformChannelSpecifics,
      payload: 'booking_cancelled',
    );
  }

  Future<void> _showDailySummaryNotification(
    int totalBookings,
    double totalRevenue,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'summary_channel',
          'Summary Notifications',
          channelDescription: 'Notification channel for daily summaries',
          importance: Importance.none,
          priority: Priority.low,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(
      3,
      'Daily Summary',
      'Today: $totalBookings bookings, EGP ${totalRevenue.toStringAsFixed(2)} revenue',
      platformChannelSpecifics,
      payload: 'daily_summary',
    );
  }

  Future<void> _showPaymentNotification(double amount, String courtName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'payment_channel',
          'Payment Notifications',
          channelDescription: 'Notification channel for payment updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(
      4,
      'Payment Received!',
      'EGP ${amount.toStringAsFixed(2)} received for $courtName',
      platformChannelSpecifics,
      payload: 'payment_received',
    );
  }

  Future<void> _showReviewNotification(String courtName, double rating) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'review_channel',
          'Review Notifications',
          channelDescription: 'Notification channel for review updates',
          importance: Importance.none,
          priority: Priority.low,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(
      5,
      'New Review!',
      '$courtName received a ${rating.toStringAsFixed(1)} star review',
      platformChannelSpecifics,
      payload: 'new_review',
    );
  }

  Future<void> _writeNotificationToFirestore(
    String message, [
    String? type,
  ]) async {
    if (_ownerId == null) return;
    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_ownerId)
        .collection('notifications');
    await notificationsRef.add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': type ?? 'general',
    });
  }
}

// Usage Example (e.g., in your main.dart or after user login):
// final notifier = BookingStatusNotifier();
// await notifier.initialize();
// notifier.startListening();
//
// Remember to call notifier.stopListening() when the user logs out or the app is disposed.
