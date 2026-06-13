import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/health_record.dart';

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

  Future<void> save() async {
    await DatabaseHelper().insert(HealthRecord(
      eventType: _selectedEventType,
      dateTime: _selectedDateTime,
    ));
  }

  void reset() {
    _selectedEventType = EventType.all.first;
    _selectedDateTime = DateTime.now();
    notifyListeners();
  }
}
