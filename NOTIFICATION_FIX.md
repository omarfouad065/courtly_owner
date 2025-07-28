# Enhanced Notification System Documentation

## Problem
The app was sending approval notifications every time it restarted, even for courts that were already approved. This happened because the notification system was using local memory to track approval status, which got reset on app restart.

## Solution
The notification system now tracks approval status changes using fields in the venue document itself to ensure notifications are only sent when the court status actually changes from "pending" to "approved" for the first time.

### Key Changes

1. **Persistent Tracking**: The system now stores approval notification status in the venue document under:
   ```
   venues/{venueId}/
     approvalNotificationSent: boolean
     approvalNotificationTimestamp: timestamp
   ```

2. **Smart Notification Logic**: Notifications are only sent when:
   - Court is approved (`approved: true`)
   - No previous notification has been sent for this approval (`approvalNotificationSent: false`)

3. **Reset Capability**: If a court is disapproved and then approved again, the system can send a new notification.

## 🎯 **New Notification Types Added**

### 1. **Booking Status Notifications**
- ✅ **Booking Confirmed** - When a booking is confirmed
- ❌ **Booking Cancelled** - When a user cancels their booking (both pending and confirmed)
- 📊 **Daily Summary** - End of day booking and revenue summary

### 2. **Financial Notifications**
- 💰 **Payment Received** - When payment is confirmed for a booking
- 📈 **Revenue Tracking** - Daily revenue summaries

### 3. **Review Notifications**
- ⭐ **New Review** - When someone leaves a review for your court
- 🏆 **Rating Updates** - When court rating changes

### 4. **System Notifications**
- 🧪 **Test Notifications** - For debugging and testing
- 📊 **Statistics** - Notification statistics and analytics

## New Methods Added

### Core Notification Methods
- `resetApprovalNotification(String venueId)`: Reset notification status for a specific venue
- `resetAllApprovalNotifications()`: Reset all approval notifications for the current user's venues

### New Notification Methods
- `sendDailyBookingSummary()`: Send daily booking and revenue summary
- `sendPaymentConfirmation(String bookingId, double amount, String courtName)`: Send payment confirmation
- `sendReviewNotification(String courtName, double rating, String reviewText)`: Send review notification
- `triggerDailySummary()`: Manually trigger daily summary (for testing)
- `sendTestNotification(String message)`: Send test notification
- `scheduleDailySummaries()`: Schedule daily summary notifications
- `getNotificationStats()`: Get notification statistics

### Debug Logging

The system now includes debug logging to help track notification behavior:
- "Sending approval notification for court: {courtName} (ID: {venueId})"
- "Skipping approval notification for court ID: {venueId} (already sent)"
- "Resetting approval notification status for court ID: {venueId} (no longer approved)"

## Firestore Structure

```
venues/
  {venueId}/
    approved: boolean                    # Court approval status
    approvalNotificationSent: boolean    # Whether notification was sent
    approvalNotificationTimestamp: timestamp  # When notification was sent
    name: string
    ownerId: string
    # ... other venue fields

users/
  {userId}/
    notifications/                      # General notifications
      {notificationId}/
        message: string
        timestamp: timestamp
        read: boolean
        type: string                    # New field for notification type
```

## Notification Types

The system now supports different notification types:
- `booking_confirmed` - Booking confirmation notifications
- `booking_cancelled` - Booking cancellation notifications
- `court_approved` - Court approval notifications
- `payment_received` - Payment confirmation notifications
- `new_review` - Review notifications
- `daily_summary` - Daily summary notifications
- `general` - General notifications

## Usage Examples

### Testing Notifications
```dart
// Send a test notification
await notifier.sendTestNotification('This is a test notification');

// Trigger daily summary manually
await notifier.triggerDailySummary();

// Get notification statistics
final stats = await notifier.getNotificationStats();
print('Total notifications: ${stats['total']}');
print('Unread notifications: ${stats['unread']}');
```

### Payment Notifications
```dart
// When payment is received
await notifier.sendPaymentConfirmation(
  'bookingId123',
  150.0,
  'Tennis Court 1'
);
```

### Review Notifications
```dart
// When a new review is posted
await notifier.sendReviewNotification(
  'Tennis Court 1',
  4.5,
  'Great court, excellent service!'
);
```

## Testing

To test the fix:
1. Restart the app multiple times
2. Check that approval notifications are not sent repeatedly
3. Use the debug logs to verify the behavior
4. Test new notification types using the provided methods
5. Use `resetApprovalNotification()` to test notification sending

## Migration

If you have existing venues that were approved before this fix, you may want to reset their notification status to test the new system:

```dart
// Reset a specific venue
await notifier.resetApprovalNotification('venueId');

// Reset all venues for current user
await notifier.resetAllApprovalNotifications();
```

## Future Enhancements

Consider adding these notifications in the future:
- ⏰ **Booking Reminders** - 1 hour before booking time
- 📅 **Upcoming Bookings** - Daily summary of today's bookings
- 🎯 **Revenue Milestones** - When you reach certain revenue targets
- 🔧 **Maintenance Alerts** - When court needs attention
- 📸 **Photo Updates** - When new photos are added
- 💰 **Pricing Changes** - When pricing is updated 