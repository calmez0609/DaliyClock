import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WorkTimeStorageService {
  static Future<void> saveWorkTime(DateTime date, TimeOfDay time, {required bool isStartTime}) async {
    final prefs = await SharedPreferences.getInstance();
    final keyPrefix = isStartTime ? 'workStartTime' : 'workEndTime';
    final dateFormat = DateFormat('yyyy-MM-dd');
    final key = '$keyPrefix:${dateFormat.format(date)}';
    await prefs.setString(key, '${time.hour}:${time.minute}');
  }

  static Future<String?> loadWorkTime(DateTime date, {required bool isStartTime}) async {
    final prefs = await SharedPreferences.getInstance();
    final keyPrefix = isStartTime ? 'workStartTime' : 'workEndTime';
    final dateFormat = DateFormat('yyyy-MM-dd');
    final key = '$keyPrefix:${dateFormat.format(date)}';
    return prefs.getString(key);
  }
}