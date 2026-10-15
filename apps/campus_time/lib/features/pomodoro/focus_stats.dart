import 'dart:math' as math;

enum FocusRange { week, month, year, years }

String focusReason(String state) => switch (state) {
  'completed' => '正常完成',
  'early_exit' => '主动提前退出',
  'running' => '专注中',
  'paused' => '已暂停（限制继续）',
  'permission_revoked' => '权限撤销',
  'safety_exit' => '安全退出',
  'storage_error' => '存储异常',
  'device_restarted' => '设备重启',
  'app_updated' => '应用更新',
  'clock_changed' => '系统时间或时区变化',
  'clock_or_service_gap' => '时钟变化或服务运行空档',
  'process_interrupted' => '进程中断',
  _ => '限制服务中断',
};
String focusDuration(num ms) {
  final seconds = ms ~/ 1000;
  return seconds < 60 ? '$seconds 秒' : '${seconds ~/ 60} 分 ${seconds % 60} 秒';
}

class FocusBucket {
  final DateTime start, end;
  final String label;
  int completedMs = 0, restrictedMs = 0, timerMs = 0;
  FocusBucket(this.start, this.end, this.label);
}

class FocusStatistics {
  final List<Map<String, dynamic>> sessions, segments;
  final List<FocusBucket> buckets;
  FocusStatistics(Map data, FocusRange range, DateTime now)
    : sessions = (data['sessions'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      segments = (data['segments'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      buckets = makeBuckets(range, now) {
    final completed = sessions
        .where((s) => s['state'] == 'completed')
        .map((s) => s['id'])
        .toSet();
    for (final segment in segments) {
      final start = (segment['start'] as num).toInt(),
          end = (segment['end'] as num).toInt();
      if (end <= start) continue;
      for (final b in buckets) {
        final lo = math.max(start, b.start.millisecondsSinceEpoch);
        final hi = math.min(end, b.end.millisecondsSinceEpoch);
        if (hi <= lo) continue;
        // Difference of cumulative integers conserves milliseconds at boundaries.
        int share(String key) =>
            ((segment[key] as num).toInt() * (hi - start) ~/ (end - start)) -
            ((segment[key] as num).toInt() * (lo - start) ~/ (end - start));
        b.timerMs += share('timer_ms');
        b.restrictedMs += share('restricted_ms');
        if (completed.contains(segment['session_id'])) {
          b.completedMs += share('timer_ms');
        }
      }
    }
  }
  static List<FocusBucket> makeBuckets(FocusRange range, DateTime now) {
    DateTime day(int y, int m, int d) =>
        now.isUtc ? DateTime.utc(y, m, d) : DateTime(y, m, d);
    final today = day(now.year, now.month, now.day);
    return switch (range) {
      FocusRange.week => [
        for (var i = 0; i < 7; i++)
          FocusBucket(
            day(today.year, today.month, today.day - now.weekday + 1 + i),
            day(today.year, today.month, today.day - now.weekday + 2 + i),
            ['一', '二', '三', '四', '五', '六', '日'][i],
          ),
      ],
      FocusRange.month => [
        for (var i = 1; i <= day(now.year, now.month + 1, 0).day; i++)
          FocusBucket(
            day(now.year, now.month, i),
            day(now.year, now.month, i + 1),
            '$i',
          ),
      ],
      FocusRange.year => [
        for (var i = 1; i <= 12; i++)
          FocusBucket(day(now.year, i, 1), day(now.year, i + 1, 1), '$i月'),
      ],
      FocusRange.years => [
        for (var y = now.year - 4; y <= now.year; y++)
          FocusBucket(day(y, 1, 1), day(y + 1, 1, 1), '$y'),
      ],
    };
  }

  List<Map<String, dynamic>> records([FocusBucket? bucket]) {
    final lo = (bucket?.start ?? buckets.first.start).millisecondsSinceEpoch;
    final hi = (bucket?.end ?? buckets.last.end).millisecondsSinceEpoch;
    final ids = segments
        .where((s) => (s['end'] as num) > lo && (s['start'] as num) < hi)
        .map((s) => s['session_id'])
        .toSet();
    return sessions
        .where(
          (s) =>
              ids.contains(s['id']) ||
              ((s['started'] as num) >= lo && (s['started'] as num) < hi),
        )
        .toList();
  }

  List<Map<String, dynamic>> get ended => sessions
      .where(
        (s) =>
            s['ended'] != null &&
            (s['ended'] as num) >= buckets.first.start.millisecondsSinceEpoch &&
            (s['ended'] as num) < buckets.last.end.millisecondsSinceEpoch,
      )
      .toList();
  int get completedCount =>
      ended.where((s) => s['state'] == 'completed').length;
  int get earlyCount => ended.where((s) => s['state'] == 'early_exit').length;
  int get interruptedCount => ended
      .where((s) => s['state'] != 'completed' && s['state'] != 'early_exit')
      .length;
  int get completedMs => buckets.fold(0, (s, b) => s + b.completedMs);
  int get restrictedMs => buckets.fold(0, (s, b) => s + b.restrictedMs);
  int get timerMs => buckets.fold(0, (s, b) => s + b.timerMs);
  int get averageMs => completedCount == 0
      ? 0
      : ended
                .where((s) => s['state'] == 'completed')
                .fold<int>(
                  0,
                  (sum, s) => sum + (s['timer_ms'] as num).toInt(),
                ) ~/
            completedCount;
}
