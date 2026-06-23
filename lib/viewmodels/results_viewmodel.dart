import 'dart:math';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/health_record.dart';

/// 実績テーブルの時刻セル。未登録は dateTime=null（「－」表示）。
/// isPreviousDay が true のとき「前日」を時刻の前に小さく表示する。
/// eventType はこのセルが表すイベント種別（タップ編集時の保存対象）。
/// recordId は既存レコードのID。null なら未登録（タップ編集で新規挿入）。
class TimeCell {
  final DateTime? dateTime;
  final bool isPreviousDay;
  final String eventType;
  final int? recordId;

  const TimeCell({
    this.dateTime,
    this.isPreviousDay = false,
    required this.eventType,
    this.recordId,
  });

  factory TimeCell.empty(String eventType) => TimeCell(eventType: eventType);
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

  /// レコードからセルを生成。表示日より前の暦日なら「前日」フラグを立てる。
  /// r が null（未登録）でも eventType を保持し、タップ編集で新規挿入できる。
  TimeCell _toCell(HealthRecord? r, String eventType, DateTime day) {
    if (r == null) return TimeCell.empty(eventType);
    return TimeCell(
      dateTime: r.dateTime,
      isPreviousDay: LogicalDay.dateOnly(r.dateTime).isBefore(day),
      eventType: eventType,
      recordId: r.id,
    );
  }

  List<ResultRow> _computeRows(List<HealthRecord> records, DateTime day) {
    final rows = <ResultRow>[];

    HealthRecord? first(String type) =>
        records.where((r) => r.eventType == type).firstOrNull;

    List<HealthRecord> all(String type) =>
        records.where((r) => r.eventType == type).toList();

    rows.add(ResultRow(
        '睡眠',
        _toCell(first(EventType.sleep), EventType.sleep, day),
        _toCell(first(EventType.wakeUp), EventType.wakeUp, day)));
    rows.add(ResultRow(
        '労働',
        _toCell(first(EventType.workStart), EventType.workStart, day),
        _toCell(first(EventType.workEnd), EventType.workEnd, day)));

    _addPairedRows(rows, '昼寝', EventType.napStart, EventType.napEnd,
        all(EventType.napStart), all(EventType.napEnd), day);
    _addPairedRows(rows, '中途覚醒', EventType.midSleepStart, EventType.midSleepEnd,
        all(EventType.midSleepStart), all(EventType.midSleepEnd), day);

    return rows;
  }

  /// 開始・終了をインデックス順にペアリング。データなしでも1行表示。
  void _addPairedRows(List<ResultRow> rows, String label, String startType,
      String endType, List<HealthRecord> starts, List<HealthRecord> ends, DateTime day) {
    final count = max(starts.length, ends.length);
    if (count == 0) {
      rows.add(ResultRow(
          label, TimeCell.empty(startType), TimeCell.empty(endType)));
      return;
    }
    for (int i = 0; i < count; i++) {
      rows.add(ResultRow(
        label,
        _toCell(i < starts.length ? starts[i] : null, startType, day),
        _toCell(i < ends.length ? ends[i] : null, endType, day),
      ));
    }
  }

  /// セルの時刻を編集する。既存レコードなら更新、未登録なら新規挿入。
  Future<void> editCell(TimeCell cell, DateTime newDateTime) async {
    if (cell.recordId != null) {
      await DatabaseHelper().update(HealthRecord(
        id: cell.recordId,
        eventType: cell.eventType,
        dateTime: newDateTime,
      ));
    } else {
      await DatabaseHelper().insert(HealthRecord(
        eventType: cell.eventType,
        dateTime: newDateTime,
      ));
    }
    await loadRecords();
  }

  /// セルの実績を削除する。未登録（recordId=null）なら何もしない。
  Future<void> deleteCell(TimeCell cell) async {
    if (cell.recordId == null) return;
    await DatabaseHelper().delete(cell.recordId!);
    await loadRecords();
  }
}
