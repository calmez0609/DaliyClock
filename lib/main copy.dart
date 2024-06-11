import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AwesomeNotifications().initialize(
    'resource://drawable/res_app_icon',
    [
      NotificationChannel(
        channelKey: 'scheduled_channel',
        channelName: 'Scheduled Notifications',
        channelDescription: 'Notifications for punch clock reminders',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
      ),
    ],
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Punch Clock App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PunchClockPage(),
    );
  }
}

class PunchClockPage extends StatefulWidget {
  @override
  _PunchClockPageState createState() => _PunchClockPageState();
}

class _PunchClockPageState extends State<PunchClockPage> {
  String _punchInTime = "You have not punched in yet";
  String _punchOutTime = "You have not punched out yet";

  @override
  void initState() {
    super.initState();
    _loadPunchTimes();
  }

  Future<void> _loadPunchTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _punchInTime = prefs.getString('punchInTime') ?? "You have not punched in yet";
      _punchOutTime = prefs.getString('punchOutTime') ?? "You have not punched out yet";
    });
  }

  Future<void> _punchIn() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('punchInTime', now.toString());
    setState(() {
      _punchInTime = "Punched in at: ${now.toString()}";
    });
    _showToast("Punched in successfully");
    _scheduleNotification(now, 'Time to punch in!', 'Don't forget to punch in for work!');
  }

  Future<void> _punchOut() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('punchOutTime', now.toString());
    setState(() {
      _punchOutTime = "Punched out at: ${now.toString()}";
    });
    _showToast("Punched out successfully");
    _scheduleNotification(now, 'Time to punch out!', 'Don't forget to lock the door and punch out!');
  }

  Future<void> _scheduleNotification(DateTime scheduledTime, String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: createUniqueId(),
        channelKey: 'scheduled_channel',
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime.add(Duration(minutes: -10))),
    );
  }

  Future<void> _showToast(String message) async {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  int createUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Punch Clock'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_punchInTime),
            ElevatedButton(
              onPressed: _punchIn,
              child: Text('Punch In'),
            ),
            Text(_punchOutTime),
            ElevatedButton(
              onPressed: _punchOut,
              child: Text('Punch Out'),
            ),
          ],
        ),
      ),
    );
  }
}