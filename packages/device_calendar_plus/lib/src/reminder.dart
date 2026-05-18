/// A reminder/alarm for a calendar event.
///
/// Reminders fire a notification at the specified time before the event starts.
class Reminder {
  /// Minutes before the event start when the reminder fires.
  ///
  /// Must be non-negative. A value of 0 means "at the time of the event".
  /// Common values: 5, 10, 15, 30, 60 (1 hour), 1440 (1 day).
  final int minutesBefore;

  const Reminder({required this.minutesBefore});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder && other.minutesBefore == minutesBefore;

  @override
  int get hashCode => minutesBefore.hashCode;

  @override
  String toString() => 'Reminder(minutesBefore: $minutesBefore)';
}
