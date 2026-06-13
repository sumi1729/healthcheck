class HealthRecord {
  final int? id;
  final String eventType;
  final DateTime dateTime;

  const HealthRecord({
    this.id,
    required this.eventType,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'event_type': eventType,
        'date_time': dateTime.millisecondsSinceEpoch,
      };

  factory HealthRecord.fromMap(Map<String, dynamic> map) => HealthRecord(
        id: map['id'] as int?,
        eventType: map['event_type'] as String,
        dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int),
      );
}

class EventType {
  static const String wakeUp = '起床';
  static const String sleep = '就寝';
  static const String workStart = '出勤';
  static const String workEnd = '退勤';
  static const String napStart = '昼寝開始';
  static const String napEnd = '昼寝終了';
  static const String midSleepStart = '中途覚醒開始';
  static const String midSleepEnd = '中途覚醒終了';

  static const List<String> all = [
    wakeUp,
    sleep,
    workStart,
    workEnd,
    napStart,
    napEnd,
    midSleepStart,
    midSleepEnd,
  ];
}
