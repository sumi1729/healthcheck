import 'dart:math';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/health_record.dart';

class ResultRow {
  final String label;
  final String start;
  final String end;

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
    final records = await DatabaseHelper().getRecordsForDate(_selectedDate);
    _rows = _computeRows(records);
    _isLoading = false;
    notifyListeners();
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '－';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h時$m分';
  }

  List<ResultRow> _computeRows(List<HealthRecord> records) {
    final rows = <ResultRow>[];

    DateTime? first(String type) =>
        records.where((r) => r.eventType == type).map((r) => r.dateTime).firstOrNull;

    List<DateTime> all(String type) =>
        records.where((r) => r.eventType == type).map((r) => r.dateTime).toList();

    rows.add(ResultRow('睡眠', _fmt(first(EventType.sleep)), _fmt(first(EventType.wakeUp))));
    rows.add(ResultRow('労働', _fmt(first(EventType.workStart)), _fmt(first(EventType.workEnd))));

    final napStarts = all(EventType.napStart);
    final napEnds = all(EventType.napEnd);
    final napCount = max(napStarts.length, napEnds.length);
    if (napCount == 0) {
      rows.add(ResultRow('昼寝', '－', '－'));
    } else {
      for (int i = 0; i < napCount; i++) {
        rows.add(ResultRow(
          '昼寝',
          _fmt(i < napStarts.length ? napStarts[i] : null),
          _fmt(i < napEnds.length ? napEnds[i] : null),
        ));
      }
    }

    final midStarts = all(EventType.midSleepStart);
    final midEnds = all(EventType.midSleepEnd);
    final midCount = max(midStarts.length, midEnds.length);
    if (midCount == 0) {
      rows.add(ResultRow('中途覚醒', '－', '－'));
    } else {
      for (int i = 0; i < midCount; i++) {
        rows.add(ResultRow(
          '中途覚醒',
          _fmt(i < midStarts.length ? midStarts[i] : null),
          _fmt(i < midEnds.length ? midEnds[i] : null),
        ));
      }
    }

    return rows;
  }
}
