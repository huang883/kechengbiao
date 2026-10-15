// Adapted from flutter_pomodoro_cat (MIT), Copyright (c) 2020 antigones.
// See assets/licenses/pomodoro_cat.txt and docs/POMODORO_SOURCE.md.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/notifications.dart';
import 'focus_bridge.dart';

enum FocusPhase { focus, shortBreak, longBreak }

class PomodoroController extends ChangeNotifier {
  final FocusBridge? focusBridge;
  Map<String, dynamic> focusStatus = {};
  bool _refreshing = false, _disposed = false;
  bool get restricted => focusStatus['active'] != null;
  bool get focusReady => focusStatus['ready'] == true;
  int get exitsRemaining => (focusStatus['remaining'] as num?)?.toInt() ?? 2;
  Map? get nativeSession => focusStatus['active'] as Map?;
  final SharedPreferences? preferences;
  final NotificationService? notifications;
  final DateTime Function() clock;
  PomodoroController({
    this.focusBridge,
    this.preferences,
    this.notifications,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  static const storageKey = 'pomodoro_v1';
  FocusPhase phase = FocusPhase.focus;
  int focusMinutes = 25,
      shortMinutes = 5,
      longMinutes = 15,
      longEvery = 4,
      rounds = 0;
  int remainingMs = 25 * 60000;
  DateTime? deadline;
  bool reminders = true, busy = false;
  String? warning, completion;
  Map<String, List<int>> totals = {};
  Future<void> _writes = Future.value();
  bool get running =>
      restricted ? nativeSession!['state'] == 'running' : deadline != null;
  int get durationMinutes => switch (phase) {
    FocusPhase.focus => focusMinutes,
    FocusPhase.shortBreak => shortMinutes,
    FocusPhase.longBreak => longMinutes,
  };
  String get phaseTitle => switch (phase) {
    FocusPhase.focus => '专注',
    FocusPhase.shortBreak => '短休息',
    FocusPhase.longBreak => '长休息',
  };
  int get leftMs => restricted
      ? math.max(
          0,
          (nativeSession!['planned'] as num).toInt() -
              (nativeSession!['timer_ms'] as num).toInt(),
        )
      : deadline == null
      ? remainingMs
      : math.max(0, deadline!.difference(clock()).inMilliseconds);
  int get seconds => (leftMs / 1000).ceil();
  // Preserve upstream MM:SS format; total minutes may exceed 59 after customization.
  String get display =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  double get progress =>
      (1 - leftMs / (durationMinutes * 60000)).clamp(0.0, 1.0);
  String day(DateTime d) {
    final c = d.toUtc().add(const Duration(hours: 8));
    return '${c.year}-${c.month.toString().padLeft(2, '0')}-${c.day.toString().padLeft(2, '0')}';
  }

  List<int> get today {
    final old = totals[day(clock())] ?? [0, 0];
    final t = focusStatus['today'] as Map?;
    return [
      old[0] + ((t?['count'] as num?)?.toInt() ?? 0),
      old[1] + (((t?['ms'] as num?)?.toInt() ?? 0) ~/ 60000),
    ];
  }

  Future<void> initialize() async {
    final raw = preferences?.getString(storageKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        int number(String key, int fallback, int max) =>
            j[key] is int && (j[key] as int) >= 1 && (j[key] as int) <= max
            ? j[key] as int
            : fallback;
        focusMinutes = number('focus', 25, 180);
        shortMinutes = number('short', 5, 60);
        longMinutes = number('long', 15, 60);
        longEvery = number('every', 4, 12);
        phase = FocusPhase.values[(j['phase'] as int).clamp(0, 2)];
        rounds = math.max(0, j['rounds'] as int);
        remainingMs = (j['remaining'] as int).clamp(0, durationMinutes * 60000);
        deadline = j['deadline'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['deadline'] as int);
        reminders = j['reminders'] as bool;
        totals = (j['totals'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, List<int>.from(v as List)),
        );
      } catch (_) {
        phase = FocusPhase.focus;
        deadline = null;
        remainingMs = durationMinutes * 60000;
        warning = '上次计时记录无法读取，已恢复待开始状态。';
      }
    }
    if (focusBridge != null) {
      // A legacy wall-clock deadline does not prove application restriction.
      if (phase == FocusPhase.focus) {
        deadline = null;
        remainingMs = durationMinutes * 60000;
      }
      await refreshFocus();
    }
    if (!_finishIfDue()) {
      await _alarm();
    } else {
      await _save();
    }
    notifyListeners();
  }

  bool _finishIfDue() {
    if (deadline == null || clock().isBefore(deadline!)) return false;
    final at = deadline!;
    deadline = null;
    if (phase == FocusPhase.focus) {
      rounds++;
      final t = totals.putIfAbsent(day(at), () => [0, 0]);
      t[0]++;
      t[1] += focusMinutes;
      phase = rounds % longEvery == 0
          ? FocusPhase.longBreak
          : FocusPhase.shortBreak;
      completion = '专注完成！准备开始$phaseTitle。';
    } else {
      phase = FocusPhase.focus;
      completion = '休息结束，准备开始下一次专注。';
    }
    remainingMs = durationMinutes * 60000;
    return true;
  }

  Future<void> refreshFocus() async {
    if (focusBridge == null || _refreshing || _disposed) return;
    _refreshing = true;
    try {
      focusStatus = await focusBridge!.status();
      if (restricted) {
        phase = FocusPhase.focus;
        deadline = null;
        focusMinutes = ((nativeSession!['planned'] as num).toInt() / 60000)
            .round();
      } else {
        final latest = focusStatus['latest'] as Map?;
        final id = latest?['id'] as String?;
        if (id != null &&
            preferences?.getString('focus_last_handled') != id &&
            _handledId != id) {
          _handledId = id;
          deadline = null;
          if (latest!['state'] == 'completed') {
            rounds++;
            phase = rounds % longEvery == 0
                ? FocusPhase.longBreak
                : FocusPhase.shortBreak;
            completion = '专注完成！限制已解除，准备开始$phaseTitle。';
          } else {
            phase = FocusPhase.focus;
            completion = latest['state'] == 'early_exit'
                ? '已提前退出，应用限制已解除。'
                : '本次专注已中断，未扣除普通退出次数。';
          }
          remainingMs = durationMinutes * 60000;
          await preferences?.setString('focus_last_handled', id);
          await _save();
        }
      }
      if (focusStatus['fault'] != null) {
        warning = focusStatus['fault'].toString();
      }
    } catch (e) {
      warning = '无法读取专注状态：$e。可在系统辅助功能设置中关闭限制。';
    } finally {
      _refreshing = false;
      if (!_disposed) notifyListeners();
    }
  }

  String? _handledId;
  Future<void> focusAction(String method, [Map<String, dynamic>? args]) async {
    if (busy || focusBridge == null) return;
    busy = true;
    notifyListeners();
    try {
      await focusBridge!.call(method, args);
      await refreshFocus();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void tick() {
    if (focusBridge != null) unawaited(refreshFocus());
    if (_finishIfDue()) unawaited(_save());
    notifyListeners();
  }

  Future<void> _save() {
    final raw = jsonEncode({
      'phase': phase.index,
      'focus': focusMinutes,
      'short': shortMinutes,
      'long': longMinutes,
      'every': longEvery,
      'rounds': rounds,
      'remaining': remainingMs,
      'deadline': deadline?.millisecondsSinceEpoch,
      'reminders': reminders,
      'totals': totals,
    });
    return _writes = _writes.catchError((Object _) {}).then((_) async {
      try {
        await preferences?.setString(storageKey, raw);
      } catch (_) {
        warning = '计时仍可使用，但保存失败，退出后可能无法恢复。';
      }
    });
  }

  Future<void> _alarm() async {
    try {
      final exact = await notifications?.setPomodoroAlarm(
        reminders ? deadline : null,
        '$phaseTitle结束',
        phase == FocusPhase.focus ? '做得好，休息一下吧。' : '准备开始下一次专注吧。',
      );
      if (exact == false && running && reminders && warning == null) {
        warning = '后台提醒可能延迟，可开启精确提醒；倒计时会按实际时间恢复。';
      }
    } catch (_) {
      warning = '计时正常，结束提醒未能设置。请检查系统通知权限。';
    }
  }

  Future<void> start() async {
    if (busy || running) return;
    if (focusBridge != null && phase == FocusPhase.focus) {
      if (reminders) await notifications?.requestPermission();
      await focusAction(restricted ? 'resume' : 'start', {
        'planned': focusMinutes * 60000,
        'notify': reminders,
      });
      return;
    }
    busy = true;
    notifyListeners();
    try {
      warning = null;
      if (reminders &&
          notifications != null &&
          !(await notifications!.requestPermission())) {
        warning = '未获通知权限：仍会计时，返回页面可查看结果。';
      }
      completion = null;
      deadline = clock().add(Duration(milliseconds: remainingMs));
      await _save();
      await _alarm();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (busy || !running) return;
    if (restricted) {
      await focusAction('pause');
      return;
    }
    if (_finishIfDue()) {
      await _save();
      await _alarm();
      notifyListeners();
      return;
    }
    remainingMs = leftMs;
    deadline = null;
    await _save();
    await _alarm();
    notifyListeners();
  }

  Future<void> select(FocusPhase value) async {
    if (restricted) throw StateError('请通过提前退出结束本次专注');
    phase = value;
    deadline = null;
    remainingMs = durationMinutes * 60000;
    completion = null;
    await _save();
    await _alarm();
    notifyListeners();
  }

  Future<void> reset() => select(phase);
  Future<void> skip() => select(
    phase == FocusPhase.focus ? FocusPhase.shortBreak : FocusPhase.focus,
  );
  Future<void> configure(int focus, int short, int long, int every) async {
    if (restricted) throw StateError('请在本次专注结束后修改时长');
    if (focus < 1 ||
        focus > 180 ||
        short < 1 ||
        short > 60 ||
        long < 1 ||
        long > 60 ||
        every < 2 ||
        every > 12) {
      throw const FormatException('专注1—180分钟，休息1—60分钟，长休息间隔2—12次');
    }
    focusMinutes = focus;
    shortMinutes = short;
    longMinutes = long;
    longEvery = every;
    await reset();
  }

  Future<void> setReminders(bool value) async {
    reminders = value;
    await focusBridge?.call('reminders', {'enabled': value});
    warning = null;
    if (value &&
        notifications != null &&
        !(await notifications!.requestPermission())) {
      warning = '未获通知权限，请在系统设置中允许通知。';
    }
    await _save();
    await _alarm();
    notifyListeners();
  }

  Future<void> requestExact() async {
    await notifications?.requestPomodoroExactPermission();
    warning = null;
    await _alarm();
    notifyListeners();
  }
}
