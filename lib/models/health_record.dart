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

/// 業務日（論理日）計算ヘルパー。
/// - 就寝: 18時以降は翌日を業務日とする（前日18:00〜当日17:59 → 当日）
/// - 起床・労働・昼寝: 暦日
/// - 中途覚醒: 内包する就寝の業務日を継承（算出ロジックは ResultsViewModel 側）
class LogicalDay {
  const LogicalDay._();

  /// 時刻を切り捨てて日付のみにする。
  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// 就寝の業務日。18時以降は翌日扱い。
  static DateTime ofSleep(DateTime dt) =>
      dt.hour >= 18 ? dateOnly(dt).add(const Duration(days: 1)) : dateOnly(dt);

  /// 暦日（起床・その他イベント）。
  static DateTime ofCalendar(DateTime dt) => dateOnly(dt);
}
