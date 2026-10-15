import 'package:campus_time/features/pomodoro/focus_bridge.dart';
import 'package:campus_time/features/pomodoro/focus_pages.dart';
import 'package:campus_time/features/pomodoro/focus_stats.dart';
import 'package:campus_time/features/pomodoro/pomodoro_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFocus extends FocusBridge {
  int arms = 0, exits = 0, cancels = 0, remaining = 2;
  bool active = true;
  Map<String, dynamic>? startArguments;
  @override
  Future<dynamic> call(String method, [Map<String, dynamic>? args]) async {
    switch (method) {
      case 'start':
        startArguments = args;
        active = true;
        return null;
      case 'armExit':
        return 'token-${++arms}';
      case 'confirmExit':
        exits++;
        remaining--;
        active = false;
        return null;
      case 'cancelExit':
        cancels++;
        return null;
      case 'status':
        return {
          'active': active
              ? {
                  'id': 'a',
                  'planned': 60000,
                  'timer_ms': 10000,
                  'state': 'running',
                }
              : null,
          'remaining': remaining,
          'ready': true,
        };
      default:
        return null;
    }
  }
}

void main() {
  test('native focus respects disabled completion reminders', () async {
    final bridge = FakeFocus()..active = false;
    final timer = PomodoroController(focusBridge: bridge)..reminders = false;
    await timer.start();
    expect(bridge.startArguments?['notify'], false);
    expect(timer.restricted, true);
    timer.dispose();
  });

  test('statistics split midnight/month/year without attributing early exit to completed', () {
    final from = DateTime.utc(2026, 12, 31, 23, 59).millisecondsSinceEpoch;
    final to = DateTime.utc(2027, 1, 1, 0, 1).millisecondsSinceEpoch;
    final data = {
      'sessions': [
        {
          'id': 'c',
          'started': from,
          'ended': to,
          'state': 'completed',
          'timer_ms': 120000,
        },
        {
          'id': 'e',
          'started': from,
          'ended': to,
          'state': 'early_exit',
          'timer_ms': 120000,
        },
        {
          'id': 'i',
          'started': from,
          'ended': to,
          'state': 'permission_revoked',
          'timer_ms': 120000,
        },
      ],
      'segments': [
        for (final id in ['c', 'e', 'i'])
          {
            'session_id': id,
            'start': from,
            'end': to,
            'timer_ms': 120000,
            'restricted_ms': 120000,
          },
      ],
    };
    final old = FocusStatistics(
      data,
      FocusRange.year,
      DateTime.utc(2026, 12, 31),
    );
    final next = FocusStatistics(
      data,
      FocusRange.year,
      DateTime.utc(2027, 1, 1),
    );
    expect(old.completedMs, 60000);
    expect(next.completedMs, 60000);
    expect(old.restrictedMs + next.restrictedMs, 360000);
    expect(old.completedCount, 0);
    expect(next.completedCount, 1);
    expect(next.earlyCount, 1);
    expect(next.interruptedCount, 1);
    expect(next.averageMs, 120000);
    expect(next.records(next.buckets.first), hasLength(3));
  });
  test('integer allocation conserves fractional milliseconds and pause contributes only restriction', () {
    final start = DateTime.utc(
      2026,
      10,
      14,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
    final data = {
      'sessions': [
        {
          'id': 'x',
          'started': start,
          'ended': start + 3,
          'state': 'completed',
          'timer_ms': 1,
        },
      ],
      'segments': [
        {
          'session_id': 'x',
          'start': start,
          'end': start + 3,
          'timer_ms': 1,
          'restricted_ms': 3,
        },
      ],
    };
    final stats = FocusStatistics(
      data,
      FocusRange.month,
      DateTime.utc(2026, 10, 15),
    );
    expect(stats.completedMs, 1);
    expect(stats.restrictedMs, 3);
    expect(stats.buckets[13].restrictedMs, 1);
    expect(stats.buckets[14].restrictedMs, 2);
    expect(
      FocusStatistics.makeBuckets(
        FocusRange.week,
        DateTime.utc(2026, 10, 15),
      ).first.start.weekday,
      DateTime.monday,
    );
    expect(
      FocusStatistics.makeBuckets(FocusRange.month, DateTime.utc(2028, 2, 15)),
      hasLength(29),
    );
    expect(
      FocusStatistics.makeBuckets(FocusRange.years, DateTime.utc(2026)),
      hasLength(5),
    );
  });
  testWidgets(
    'exit dialog gates confirmation, cancellation and reopening reset gate',
    (tester) async {
      final bridge = FakeFocus();
      final timer = PomodoroController(focusBridge: bridge);
      await timer.refreshFocus();
      var elapsed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: c,
                  builder: (_) => FocusExitDialog(
                    timer: timer,
                    elapsedMilliseconds: () => elapsed,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('确认退出（5s）'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      elapsed = 4999;
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('继续专注'));
      await tester.pumpAndSettle();
      expect(bridge.exits, 0);
      expect(bridge.cancels, 1);
      elapsed = 0;
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(bridge.arms, 2);
      expect(find.text('确认退出（5s）'), findsOneWidget);
      elapsed = 5000;
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('确认退出'), findsOneWidget);
      // No automatic exit when countdown finishes.
      expect(bridge.exits, 0);
      await tester.tap(find.text('确认退出'));
      await tester.pumpAndSettle();
      expect(bridge.exits, 1);
      expect(timer.exitsRemaining, 1);
      timer.dispose();
    },
  );
  testWidgets('zero quota does not arm a countdown or expose confirm button', (
    tester,
  ) async {
    final bridge = FakeFocus()..remaining = 0;
    final timer = PomodoroController(focusBridge: bridge);
    await timer.refreshFocus();
    await tester.pumpWidget(MaterialApp(home: FocusExitDialog(timer: timer)));
    expect(find.text('本月提前退出机会已用完'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(bridge.arms, 0);
    await tester.pumpWidget(const SizedBox());
    timer.dispose();
  });
  test(
    'protected session cannot reset, skip, change phase or configure duration',
    () async {
      final timer = PomodoroController(focusBridge: FakeFocus());
      await timer.refreshFocus();
      await expectLater(timer.reset(), throwsStateError);
      await expectLater(timer.skip(), throwsStateError);
      await expectLater(timer.configure(10, 5, 15, 4), throwsStateError);
      expect(timer.focusMinutes, 1);
      timer.dispose();
    },
  );
}
