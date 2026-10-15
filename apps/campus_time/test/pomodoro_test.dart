import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_time/features/pomodoro/pomodoro_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'deadline countdown pauses, resumes and survives reopening without drift',
    () async {
      var now = DateTime.utc(2026, 10, 13, 1);
      final prefs = await SharedPreferences.getInstance();
      final t = PomodoroController(preferences: prefs, clock: () => now);
      await t.initialize();
      await t.start();
      now = now.add(const Duration(seconds: 61));
      expect(t.display, '23:59');
      await t.pause();
      now = now.add(const Duration(hours: 2));
      expect(t.display, '23:59');
      await t.start();
      now = now.add(const Duration(seconds: 59));
      final restored = PomodoroController(preferences: prefs, clock: () => now);
      await restored.initialize();
      expect(restored.display, '23:00');
      expect(restored.running, isTrue);
      await restored.reset();
      expect(restored.display, '25:00');
      expect(restored.today, [0, 0]);
      t.dispose();
      restored.dispose();
    },
  );
  test('four completions lead to long rest; missed background time completes only one stage', () async {
    var now = DateTime.utc(2026, 10, 13, 1);
    final t = PomodoroController(clock: () => now);
    await t.initialize();
    await t.configure(1, 1, 2, 4);
    for (var n = 1; n <= 4; n++) {
      await t.start();
      now = now.add(const Duration(minutes: 1));
      t.tick();
      t.tick();
      expect(t.today, [n, n]);
      expect(t.phase, n == 4 ? FocusPhase.longBreak : FocusPhase.shortBreak);
      expect(t.running, isFalse);
      if (n < 4) {
        await t.start();
        now = now.add(const Duration(minutes: 1));
        t.tick();
        expect(t.phase, FocusPhase.focus);
      }
    }
    await t.start();
    now = now.add(const Duration(days: 2));
    t.tick();
    expect(t.phase, FocusPhase.focus);
    expect(t.rounds, 4);
    expect(t.running, isFalse);
    t.dispose();
  });
  test(
    'expired process restoration records once; skip and reset never count',
    () async {
      var now = DateTime.utc(2026, 10, 13, 15, 59);
      final prefs = await SharedPreferences.getInstance();
      final t = PomodoroController(preferences: prefs, clock: () => now);
      await t.initialize();
      await t.configure(1, 1, 2, 4);
      await t.start();
      now = now.add(const Duration(minutes: 2));
      final a = PomodoroController(preferences: prefs, clock: () => now);
      await a.initialize();
      expect(a.today, [1, 1]);
      final b = PomodoroController(preferences: prefs, clock: () => now);
      await b.initialize();
      expect(b.today, [1, 1]);
      await b.select(FocusPhase.focus);
      await b.start();
      await b.skip();
      await b.reset();
      expect(b.rounds, 1);
      await expectLater(b.configure(0, 5, 15, 4), throwsFormatException);
      expect(b.focusMinutes, 1);
      t.dispose();
      a.dispose();
      b.dispose();
    },
  );
}
