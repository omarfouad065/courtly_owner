# Notification Fix Documentation

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

### New Methods Added

- `resetApprovalNotification(String venueId)`: Reset notification status for a specific venue
- `resetAllApprovalNotifications()`: Reset all approval notifications for the current user's venues

### Debug Logging

The system now includes debug logging to help track notification behavior:
- "Sending approval notification for court: {courtName} (ID: {venueId})"
- "Skipping approval notification for court ID: {venueId} (already sent)"
- "Resetting approval notification status for court ID: {venueId} (no longer approved)"

### Firestore Structure

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
```

## Testing

To test the fix:
1. Restart the app multiple times
2. Check that approval notifications are not sent repeatedly
3. Use the debug logs to verify the behavior
4. If needed, use `resetApprovalNotification()` to test notification sending

## Migration

If you have existing venues that were approved before this fix, you may want to reset their notification status to test the new system:

```dart
// Reset a specific venue
await notifier.resetApprovalNotification('venueId');

// Reset all venues for current user
await notifier.resetAllApprovalNotifications();
``` 