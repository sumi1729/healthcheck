import 'dart:math';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/health_record.dart';

/// 実績テーブルの時刻セル。未登録は dateTime=null（「－」表示）。
/// isPreviousDay が true のとき「前日」を時刻の前に小さく表示する。
class TimeCell {
  final DateTime? dateTime;
  final bool isPreviousDay;

  const TimeCell(this.dateTime, this.isPreviousDay);
  static const empty = TimeCell(null, false);
}

class ResultRow {
  final String label;
  final TimeCell start;
  final TimeCell end;

  ResultRow(this.label, this.start, this.end);
}

class ResultsViewModel extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  List<ResultRow> _rows = [];
  bool _isLoading = false;

  DateTime get selectedDate => _selectedDate;
  List<ResultRow> get rows => _rows;
  bool get isLoading => _isLoading;

  ResultsViewModel() {
    loadRecords();
  }

  Future<void> setDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();
    await loadRecords();
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();
    final day = LogicalDay.dateOnly(_selectedDate);
    // 前日夕方の就寝や、就寝を内包親とする中途覚醒を解決するため文脈を広めに取得。
    final start = day.subtract(const Duration(days: 2));
    final end = day.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    final context = await DatabaseHelper().getRecordsInRange(start, end);
    final dayRecords =
        context.where((r) => _isSameDay(_logicalDayOf(r, context), day)).toList();
    _rows = _computeRows(dayRecords, day);
    _isLoading = false;
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// レコードの業務日を求める。中途覚醒は直前の就寝（内包セッション）の業務日を継承。
  DateTime _logicalDayOf(HealthRecord r, List<HealthRecord> context) {
    switch (r.eventType) {
      case EventType.sleep:
        return LogicalDay.ofSleep(r.dateTime);
      case EventType.midSleepStart:
      case EventType.midSleepEnd:
        HealthRecord? enclosing;
        for (final e in context) {
          if (e.eventType == EventType.sleep && !e.dateTime.isAfter(r.dateTime)) {
            if (enclosing == null || e.dateTime.isAfter(enclosing.dateTime)) {
              enclosing = e;
            }
          }
        }
        return enclosing == null
            ? LogicalDay.ofCalendar(r.dateTime)
            : LogicalDay.ofSleep(enclosing.dateTime);
      default:
        return LogicalDay.ofCalendar(r.dateTime);
    }
  }

  /// 実時刻からセルを生成。表示日より前の暦日なら「前日」フラグを立てる。
  TimeCell _toCell(DateTime? dt, DateTime day) {
    if (dt == null) return TimeCell.empty;
    return TimeCell(dt, LogicalDay.dateOnly(dt).isBefore(day));
  }

  List<ResultRow> _computeRows(List<HealthRecord> records, DateTime day) {
    final rows = <ResultRow>[];

    DateTime? first(String type) =>
        records.where((r) => r.eventType == type).map((r) => r.dateTime).firstOrNull;

    List<DateTime> all(String type) =>
        records.where((r) => r.eventType == type).map((r) => r.dateTime).toList();

    rows.add(ResultRow('睡眠', _toCell(first(EventType.sleep), day),
        _toCell(first(EventType.wakeUp), day)));
    rows.add(ResultRow('労働', _toCell(first(EventType.workStart), day),
        _toCell(first(EventType.workEnd), day)));

    _addPairedRows(rows, '昼寝', all(EventType.napStart), all(EventType.napEnd), day);
    _addPairedRows(rows, '中途覚醒', all(EventType.midSleepStart),
        all(EventType.midSleepEnd), day);

    return rows;
  }

  /// 開始・終了をインデックス順にペアリング。データなしでも1行表示。
  void _addPairedRows(List<ResultRow> rows, String label, List<DateTime> starts,
      List<DateTime> ends, DateTime day) {
    final count = max(starts.length, ends.length);
    if (count == 0) {
      rows.add(ResultRow(label, TimeCell.empty, TimeCell.empty));
      return;
    }
    for (int i = 0; i < count; i++) {
      rows.add(ResultRow(
        label,
        _toCell(i < starts.length ? starts[i] : null, day),
        _toCell(i < ends.length ? ends[i] : null, day),
      ));
    }
  }
}
