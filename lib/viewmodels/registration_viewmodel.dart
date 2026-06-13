import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/health_record.dart';

/// 登録処理の結果。success=false のとき message にダイアログ文言を持つ。
class SaveResult {
  final bool success;
  final String? message;

  const SaveResult._(this.success, this.message);
  factory SaveResult.ok() => const SaveResult._(true, null);
  factory SaveResult.error(String message) => SaveResult._(false, message);
}

class RegistrationViewModel extends ChangeNotifier {
  String _selectedEventType = EventType.all.first;
  DateTime _selectedDateTime = DateTime.now();

  String get selectedEventType => _selectedEventType;
  DateTime get selectedDateTime => _selectedDateTime;

  void setEventType(String eventType) {
    _selectedEventType = eventType;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      _selectedDateTime.hour,
      _selectedDateTime.minute,
    );
    notifyListeners();
  }

  void setTime(TimeOfDay time) {
    _selectedDateTime = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
      time.hour,
      time.minute,
    );
    notifyListeners();
  }

  Future<SaveResult> save() async {
    final type = _selectedEventType;
    final when = _selectedDateTime;

    if (type == EventType.midSleepStart || type == EventType.midSleepEnd) {
      final error = await _validateMidSleep(when);
      if (error != null) return SaveResult.error(error);
    }

    await DatabaseHelper().insert(HealthRecord(eventType: type, dateTime: when));
    return SaveResult.ok();
  }

  /// 中途覚醒の登録可否を判定。登録不可ならエラーメッセージ、可なら null。
  /// 判定: 登録日時の直前にある就寝/起床境界が「就寝」かつ当日/前日なら有効。
  /// （複数日連続睡眠はない前提のため、前々日以前の就寝は記録漏れとみなす）
  Future<String?> _validateMidSleep(DateTime t) async {
    final boundary = await DatabaseHelper().getLatestSleepBoundaryBefore(t);
    if (boundary == null) return '就寝時間が登録されていません';
    if (boundary.eventType == EventType.wakeUp) return '中途覚醒登録時間外です';

    // boundary は就寝。就寝が前々日以前なら、その日の就寝が未登録とみなす。
    final sleepDay = LogicalDay.dateOnly(boundary.dateTime);
    final targetDay = LogicalDay.dateOnly(t);
    if (targetDay.difference(sleepDay).inDays > 1) {
      return '就寝時間が登録されていません';
    }
    return null;
  }

  void reset() {
    _selectedEventType = EventType.all.first;
    _selectedDateTime = DateTime.now();
    notifyListeners();
  }
}
