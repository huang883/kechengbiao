import 'package:drift/drift.dart';
import 'package:schedule_core/schedule_core.dart';
import 'database.dart' show ScheduleDatabase;
import 'codec.dart';

class DriftTaskRepository implements TaskRepository {
  final ScheduleDatabase _db;
  DriftTaskRepository(this._db);

  List<Variable> _values(TaskEvent task) => [
    Variable<String>(task.title),
    Variable<String>(dateText(task.date)),
    Variable<String>(task.startTime),
    Variable<String>(task.endTime),
    Variable<String>(task.description),
    Variable<int>(task.completed ? 1 : 0),
    Variable<int>(task.reminderMinutes),
    Variable<String>(task.repeatRule),
    Variable<String>(task.id),
  ];

  TaskEvent _decode(QueryRow row) => TaskEvent(
    id: row.read<String>('id'),
    title: row.read<String>('title'),
    date: DateTime.parse('${row.read<String>('event_date')}T00:00:00Z'),
    startTime: row.readNullable<String>('start_time'),
    endTime: row.readNullable<String>('end_time'),
    description: row.read<String>('description'),
    completed: row.read<int>('completed') == 1,
    reminderMinutes: row.readNullable<int>('reminder_minutes'),
    repeatRule: row.readNullable<String>('repeat_rule'),
  );

  @override
  Future<void> create(TaskEvent task) async {
    await _db.customInsert(
      '''INSERT INTO task_events
      (title,event_date,start_time,end_time,description,completed,reminder_minutes,repeat_rule,id)
      VALUES (?,?,?,?,?,?,?,?,?)''',
      variables: _values(task),
      updates: {_db.taskEvents},
    );
  }

  @override
  Future<void> update(TaskEvent task) async {
    final count = await _db.customUpdate(
      '''UPDATE task_events SET title=?,event_date=?,start_time=?,
      end_time=?,description=?,completed=?,reminder_minutes=?,repeat_rule=? WHERE id=?''',
      variables: _values(task),
      updates: {_db.taskEvents},
    );
    if (count == 0) fail('notFound', 'Task does not exist');
  }

  @override
  Future<TaskEvent?> read(String id) async {
    final result = await rows(_db, 'SELECT * FROM task_events WHERE id=?', [
      id,
    ]);
    return result.isEmpty ? null : _decode(result.single);
  }

  @override
  Future<List<TaskEvent>> list({
    DateTime? from,
    DateTime? through,
    bool? completed,
  }) async {
    if (from != null &&
        through != null &&
        dateText(from).compareTo(dateText(through)) > 0) {
      fail('invalidRange', 'Task date range is reversed');
    }
    final conditions = <String>[];
    final args = <Object>[];
    if (from != null) {
      conditions.add('event_date>=?');
      args.add(dateText(from));
    }
    if (through != null) {
      conditions.add('event_date<=?');
      args.add(dateText(through));
    }
    if (completed != null) {
      conditions.add('completed=?');
      args.add(completed ? 1 : 0);
    }
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    return (await rows(
      _db,
      'SELECT * FROM task_events $where ORDER BY event_date,start_time,id',
      args,
    )).map(_decode).toList();
  }

  @override
  Future<void> setCompleted(String id, bool completed) async {
    final count = await _db.customUpdate(
      'UPDATE task_events SET completed=? WHERE id=?',
      variables: bind([completed ? 1 : 0, id]),
      updates: {_db.taskEvents},
    );
    if (count == 0) fail('notFound', 'Task does not exist');
  }

  @override
  Future<void> delete(String id) async {
    await _db.customUpdate(
      'DELETE FROM task_events WHERE id=?',
      variables: bind([id]),
      updates: {_db.taskEvents},
    );
  }
}
