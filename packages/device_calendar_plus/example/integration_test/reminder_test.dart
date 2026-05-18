import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Integration tests for reminders/alarms.
///
/// These tests verify that reminders are correctly written and read back
/// on real devices. No mocking — exercises the full native calendar API.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final plugin = DeviceCalendar.instance;

  String? testCalendarId;

  setUpAll(() async {
    await plugin.requestPermissions();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    testCalendarId = await plugin.createCalendar(
      name: 'Reminder Test $timestamp',
    );
  });

  tearDownAll(() async {
    if (testCalendarId != null) {
      await plugin.deleteCalendar(testCalendarId!);
    }
  });

  testWidgets('Create event with reminders and read them back', (tester) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 14, 0);
    final end = DateTime(now.year, now.month, now.day, 15, 0);

    final eventId = await plugin.createEvent(
      calendarId: testCalendarId!,
      title: 'Reminder Test Event',
      startDate: start,
      endDate: end,
      reminders: [
        Reminder(minutesBefore: 10),
        Reminder(minutesBefore: 60),
      ],
    );

    expect(eventId, isNotEmpty);

    // Read the event back
    final event = await plugin.getEvent(eventId);
    expect(event, isNotNull);
    expect(event!.reminders, isNotNull);
    expect(event.reminders!.length, 2);

    // Verify the values (order may differ per platform)
    final minutes = event.reminders!.map((r) => r.minutesBefore).toSet();
    expect(minutes, contains(10));
    expect(minutes, contains(60));
  });

  testWidgets('Create event without reminders has null/empty reminders',
      (tester) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 16, 0);
    final end = DateTime(now.year, now.month, now.day, 17, 0);

    final eventId = await plugin.createEvent(
      calendarId: testCalendarId!,
      title: 'No Reminder Event',
      startDate: start,
      endDate: end,
    );

    final event = await plugin.getEvent(eventId);
    expect(event, isNotNull);
    // No reminders set — should be null (no reminders key in map)
    expect(event!.reminders, isNull);
  });

  testWidgets('Update event to add reminders', (tester) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 18, 0);
    final end = DateTime(now.year, now.month, now.day, 19, 0);

    // Create without reminders
    final eventId = await plugin.createEvent(
      calendarId: testCalendarId!,
      title: 'Update Reminder Event',
      startDate: start,
      endDate: end,
    );

    // Update to add reminders
    await plugin.updateEvent(
      eventId: eventId,
      reminders: [Reminder(minutesBefore: 15), Reminder(minutesBefore: 1440)],
    );

    // Read back
    final event = await plugin.getEvent(eventId);
    expect(event, isNotNull);
    expect(event!.reminders, isNotNull);
    expect(event.reminders!.length, 2);

    final minutes = event.reminders!.map((r) => r.minutesBefore).toSet();
    expect(minutes, contains(15));
    expect(minutes, contains(1440));
  });

  testWidgets('Update event to clear reminders', (tester) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 20, 0);
    final end = DateTime(now.year, now.month, now.day, 21, 0);

    // Create with a reminder
    final eventId = await plugin.createEvent(
      calendarId: testCalendarId!,
      title: 'Clear Reminder Event',
      startDate: start,
      endDate: end,
      reminders: [Reminder(minutesBefore: 30)],
    );

    // Verify reminder exists
    var event = await plugin.getEvent(eventId);
    expect(event!.reminders, isNotNull);
    expect(event.reminders!.length, 1);

    // Update with empty list to clear
    await plugin.updateEvent(
      eventId: eventId,
      reminders: [],
    );

    // Read back — should have no reminders
    event = await plugin.getEvent(eventId);
    expect(event, isNotNull);
    expect(event!.reminders, isNull);
  });

  testWidgets('Reminder with minutesBefore=0 (at time of event)',
      (tester) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 10, 30);
    final end = DateTime(now.year, now.month, now.day, 11, 30);

    final eventId = await plugin.createEvent(
      calendarId: testCalendarId!,
      title: 'Zero Minute Reminder',
      startDate: start,
      endDate: end,
      reminders: [Reminder(minutesBefore: 0)],
    );

    final event = await plugin.getEvent(eventId);
    expect(event, isNotNull);
    expect(event!.reminders, isNotNull);
    expect(event.reminders!.length, 1);
    expect(event.reminders![0].minutesBefore, 0);
  });

  testWidgets('Reminders appear in listEvents results', (tester) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 12, 0);
    final end = DateTime(now.year, now.month, now.day, 13, 0);

    final eventId = await plugin.createEvent(
      calendarId: testCalendarId!,
      title: 'List Events Reminder',
      startDate: start,
      endDate: end,
      reminders: [Reminder(minutesBefore: 5)],
    );

    // Fetch via listEvents
    final events = await plugin.listEvents(
      start.subtract(Duration(hours: 1)),
      end.add(Duration(hours: 1)),
      calendarIds: [testCalendarId!],
    );

    final event = events.firstWhere((e) => e.eventId == eventId);
    expect(event.reminders, isNotNull);
    expect(event.reminders!.any((r) => r.minutesBefore == 5), isTrue);
  });
}
