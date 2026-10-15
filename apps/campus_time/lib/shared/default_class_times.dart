import 'package:schedule_core/schedule_core.dart';

/// 海南师范大学 2026—2027 校历中提供的作息，可在设置中修改。
List<ClassTimeConfig> defaultClassTimes(String semesterId) {
  const times = [
    ('08:00', '08:45'),
    ('08:55', '09:40'),
    ('10:00', '10:45'),
    ('10:55', '11:40'),
    ('14:30', '15:15'),
    ('15:25', '16:10'),
    ('16:25', '17:10'),
    ('17:20', '18:05'),
    ('19:30', '20:15'),
    ('20:20', '21:05'),
    ('21:10', '21:55'),
  ];
  return [
    for (var i = 0; i < times.length; i++)
      ClassTimeConfig(
        semesterId: semesterId,
        section: i + 1,
        startTime: times[i].$1,
        endTime: times[i].$2,
      ),
  ];
}
