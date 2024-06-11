// 文件名: calendar_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

Future<String> _getWorkTimesForDay(DateTime date) async {
  final prefs = await SharedPreferences.getInstance();
  String key = DateFormat('yyyy-MM-dd').format(date);
  String? workStartTimeStr = prefs.getString('workStartTime:$key');
  String? workEndTimeStr = prefs.getString('workEndTime:$key');
  bool? punchOutStatus = prefs.getBool('punchOutStatus:$key');
  String punchOutStatusStr = punchOutStatus == true ? '下班卡: (O)' : '下班卡: (X)';

  // 格式化時間顯示，確保分鐘數始終為兩位數
  String formattedWorkStartTime = _formatTimeOfDay(workStartTimeStr);
  String formattedWorkEndTime = _formatTimeOfDay(workEndTimeStr);

  return "上班時間: ${formattedWorkStartTime}\n下班時間: ${formattedWorkEndTime}\n$punchOutStatusStr";
}

String _formatTimeOfDay(String? timeOfDayStr) {
  if (timeOfDayStr == null) return '未設置';
  List<String> parts = timeOfDayStr.split(':');
  String formattedTime = '${parts[0]}:${parts[1].padLeft(2, '0')}';
  return formattedTime;
}

Future<void> _showWorkTimeDialog(DateTime date) async {
  String workTimes = await _getWorkTimesForDay(date);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(DateFormat('yyyy-MM-dd').format(date)),
        content: Text(workTimes),
        actions: <Widget>[
          TextButton(
            child: Text('關閉'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('上下班時間日曆'),
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _showWorkTimeDialog(selectedDay);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }
}