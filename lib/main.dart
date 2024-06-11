import 'package:daliy_colcker/components/calendar_page.dart';
import 'package:daliy_colcker/services/notification_service.dart';
import 'package:daliy_colcker/services/time_selection_service.dart';
import 'package:daliy_colcker/services/work_time_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initializeNotifications();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '打卡應用',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PunchClockPage(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('zh', 'CN'), // Chinese
      ],
    );
  }
}

class PunchClockPage extends StatefulWidget {
  @override
  _PunchClockPageState createState() => _PunchClockPageState();
}

class _PunchClockPageState extends State<PunchClockPage> {
  TimeOfDay? _selectedWorkStartTime;
  TimeOfDay? _selectedWorkEndTime;
  bool _autoCalculateEndTime = false;
  int _selectedWorkDuration = 9;
  bool _useCurrentTime = false;
  TextEditingController _workHoursController = TextEditingController();
  @override
  void initState() {
    super.initState();
    NotificationService.sendNotification("歡迎使用打卡應用", "成功開啟應用！");
    _loadWorkTime();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('打卡應用'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center( // 使用 Center 来使内容居中
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 设置子组件居中对齐
            children: <Widget>[
            SizedBox(height: 50.0),
              Card(
                elevation: 4.0,
                child: ListTile(
                  leading: Icon(Icons.work, color: Colors.blue),
                  title: Text('上班時間'),
                  subtitle: Text(_selectedWorkStartTime == null ? '未設置' : _selectedWorkStartTime!.format(context)),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _selectTime(context, isStartTime: true),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Card(
                elevation: 4.0,
                child: ListTile(
                  leading: Icon(Icons.home, color: Colors.red),
                  title: Text('下班時間'),
                  subtitle: Text(_selectedWorkEndTime == null ? '未設置' : _selectedWorkEndTime!.format(context)),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _selectTime(context, isStartTime: false),
                  ),
                ),
              ),
              Card(
                elevation: 4.0,
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.purple),
                  title: Text('查看上下班時間日曆'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CalendarPage()),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.0),
              CheckboxListTile(
                title: Text('自動計算下班時間'),
                value: _autoCalculateEndTime,
                onChanged: (bool? value) {
                  setState(() {
                    _autoCalculateEndTime = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('選擇現在時間'),
                value: _useCurrentTime,
                onChanged: (bool? value) {
                  setState(() {
                    _useCurrentTime = value!;
                  });
                },
              ),
              ListTile(
                title: Text('選擇工作時常'),
                subtitle: Text('$_selectedWorkDuration 小時'),
                onTap: _showWorkDurationPicker,
              ),
              SizedBox(height: 16.0),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _punchIn,
                child: Text('現在打卡'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // 使用 backgroundColor 替代 primary
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _punchOut,
                child: Text('打卡下班'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // 使用 backgroundColor 替代 primary
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _clearTimeSettings,
                child: Text('清空時間設置'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // 使用 backgroundColor 替代 primary
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // 在 _PunchClockPageState 類中添加清空時間設置的方法
  void _clearTimeSettings() async {
    setState(() {
      _selectedWorkStartTime = null;
      _selectedWorkEndTime = null;
    });
    
    // 使用 SharedPreferences 直接清除時間設置
    final prefs = await SharedPreferences.getInstance();
    DateTime today = DateTime.now();
    String startDateKey = 'workStartTime:${today.year}-${today.month}-${today.day}';
    String endDateKey = 'workEndTime:${today.year}-${today.month}-${today.day}';
    await prefs.remove(startDateKey);
    await prefs.remove(endDateKey);
    
    Fluttertoast.showToast(msg: '時間設置已清空', fontSize: 16.0);
  }

  Future<void> _loadWorkTime() async {
    DateTime today = DateTime.now();
    String? workStartTimeStr = await WorkTimeStorageService.loadWorkTime(today, isStartTime: true);
    String? workEndTimeStr = await WorkTimeStorageService.loadWorkTime(today, isStartTime: false);

    if (workStartTimeStr != null) {
      List<String> startTimeParts = workStartTimeStr.split(':');
      _selectedWorkStartTime = TimeOfDay(hour: int.parse(startTimeParts[0]), minute: int.parse(startTimeParts[1]));
    } else {
      _selectedWorkStartTime = null; // 没有设置上班时间
    }

    if (workEndTimeStr != null) {
      List<String> endTimeParts = workEndTimeStr.split(':');
      _selectedWorkEndTime = TimeOfDay(hour: int.parse(endTimeParts[0]), minute: int.parse(endTimeParts[1]));
    } else {
      _selectedWorkEndTime = null; // 没有设置下班时间
    }

    setState(() {});
  }

  Future<void> _selectTime(BuildContext context, {required bool isStartTime}) async {
  final TimeOfDay? picked = await TimeSelectionService.selectTime(context, isStartTime: isStartTime);
  if (picked != null) {
    setState(() {
      if (isStartTime) {
        _selectedWorkStartTime = picked;
      } else {
        _selectedWorkEndTime = picked;
      }
    });
    DateTime today = DateTime.now();
    DateTime selectedDateTime = DateTime(today.year, today.month, today.day, picked.hour, picked.minute);
    
    // 如果選擇的時間已經過去，則將其設置為明天的該時間
    if (selectedDateTime.isBefore(today)) {
      selectedDateTime = selectedDateTime.add(Duration(days: 1));
    }
    
    await WorkTimeStorageService.saveWorkTime(selectedDateTime, picked, isStartTime: isStartTime);
    String message = isStartTime ? "上班時間設置成功" : "下班時間設置成功";
    NotificationService.sendNotification(message, "您設定的時間為：${picked.format(context)}");

    if (!isStartTime) {
      // 下班前十分鐘的提醒
      DateTime tenMinutesBefore = selectedDateTime.subtract(Duration(minutes: 10));
      await NotificationService.scheduleNotification(
        tenMinutesBefore,
        "準備下班",
        "再過10分鐘就可以下班了，記得收拾東西！"
      );
      
      // 下班時間到達時的提醒
      await NotificationService.scheduleNotification(
        selectedDateTime,
        "下班時間到了！",
        "記得按門鎖並打下班卡！"
      );
    }
  }
}
  void _setEndTimeBasedOnDuration() {
    if (_selectedWorkStartTime != null) {
      final int endHour = (_selectedWorkStartTime!.hour + _selectedWorkDuration) % 24;
      _selectedWorkEndTime = TimeOfDay(hour: endHour, minute: _selectedWorkStartTime!.minute);

      // 保存下班时间
      DateTime today = DateTime.now();
      DateTime selectedEndDateTime = DateTime(today.year, today.month, today.day, _selectedWorkEndTime!.hour, _selectedWorkEndTime!.minute);
      
      // 如果计算出的下班时间已经过去，则将其设置为明天的该时间
      if (selectedEndDateTime.isBefore(today)) {
        selectedEndDateTime = selectedEndDateTime.add(Duration(days: 1));
      }

      WorkTimeStorageService.saveWorkTime(selectedEndDateTime, _selectedWorkEndTime!, isStartTime: false);
      setState(() {});
    }
  }
  void _punchIn() {
  TimeOfDay timeNow = TimeOfDay.now();
  TimeOfDay selectedTime = _useCurrentTime ? timeNow : _selectedWorkStartTime ?? timeNow;
  setState(() {
    _selectedWorkStartTime = selectedTime;
  });
  WorkTimeStorageService.saveWorkTime(DateTime.now(), selectedTime, isStartTime: true);
  NotificationService.sendNotification("打卡成功", "您的上班時間為：${selectedTime.format(context)}");

  if (_autoCalculateEndTime) {
    _setEndTimeBasedOnDuration();
  }
}

void _punchOut() {
  TimeOfDay timeNow = TimeOfDay.now();
  TimeOfDay selectedTime = _useCurrentTime ? timeNow : _selectedWorkEndTime ?? timeNow;
  if (!_useCurrentTime && (_selectedWorkEndTime != null && timeNow.hour < _selectedWorkEndTime!.hour)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('提示'),
            content: Text('還沒到下班時間呢～'),
            actions: <Widget>[
              TextButton(
                child: Text('好的'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }
    setState(() {
      _selectedWorkEndTime = selectedTime;
    });
    WorkTimeStorageService.saveWorkTime(DateTime.now(), selectedTime, isStartTime: false);
    NotificationService.sendNotification("打下班卡成功", "您的下班時間為：${selectedTime.format(context)}");

    // 保存下班卡狀態
    _savePunchOutStatus();
  }

  Future<void> _savePunchOutStatus() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime today = DateTime.now();
    String key = 'punchOutStatus:${today.year}-${today.month}-${today.day}';
    await prefs.setBool(key, true);
  }
  void _showWorkDurationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: _selectedWorkDuration - 1),
            itemExtent: 32.0,
            backgroundColor: Colors.white,
            onSelectedItemChanged: (int value) {
              setState(() {
                _selectedWorkDuration = value + 1;
                if (_autoCalculateEndTime) {
                  _setEndTimeBasedOnDuration();
                }
              });
            },
            children: List<Widget>.generate(24, (int index) {
              return Center(
                child: Text('${index + 1} 小時'),
              );
            }),
          ),
        );
      },
    );
  }

}