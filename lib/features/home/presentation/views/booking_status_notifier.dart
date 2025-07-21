import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BookingStatusNotifier {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<QuerySnapshot>? _bookingSubscription;
  StreamSubscription<QuerySnapshot>? _venueSubscription;
  final Map<String, String> _lastStatuses = {};
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
              doc.id: (doc.data() as Map<String, dynamic>)['name'] ?? 'Court',
          };
          _listenToBookings();
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
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending')
                .toString()
                .toLowerCase();
            final bookingId = doc.id;
            final lastStatus = _lastStatuses[bookingId];
            if (lastStatus != null &&
                lastStatus == 'pending' &&
                status == 'confirmed') {
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
              final message =
                  '$userName has a confirmed booking for $courtName.';
              _showBookingConfirmedNotification(courtName, userName);
              _writeNotificationToFirestore(message);
            }
            _lastStatuses[bookingId] = status;
          }
        });
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

  Future<void> _writeNotificationToFirestore(String message) async {
    if (_ownerId == null) return;
    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_ownerId)
        .collection('notifications');
    await notificationsRef.add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}

// Usage Example (e.g., in your main.dart or after user login):
// final notifier = BookingStatusNotifier();
// await notifier.initialize();
// notifier.startListening();
//
// Remember to call notifier.stopListening() when the user logs out or the app is disposed.
