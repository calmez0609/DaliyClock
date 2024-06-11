import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeSelectionService {
  static Future<TimeOfDay?> selectTime(BuildContext context, {required bool isStartTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      cancelText: '取消',
      confirmText: '確定',
      helpText: isStartTime ? '選擇上班時間' : '選擇下班時間',
    );
    return picked;
  }
}