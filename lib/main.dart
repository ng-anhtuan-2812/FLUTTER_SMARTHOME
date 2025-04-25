import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Để tạo Session ID ngẫu nhiên
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: '  KEY',
    anonKey:
    '  KEY );


// Khởi tạo OneSignal
  OneSignal.initialize(""); // Thay bằng App ID của bạn
  OneSignal.Notifications.requestPermission(true); // Yêu cầu quyền thông báo

  // (Tùy chọn) Debug trạng thái đăng ký
  OneSignal.User.pushSubscription.addObserver((state) {
    print("Push Subscription State: ${state.current.jsonRepresentation()}");
  });


  // Xử lý thông báo khi ứng dụng ở foreground
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print("Thông báo nhận được khi ứng dụng đang mở: ${event.notification.body}");
    event.preventDefault(); // Ngăn thông báo hiển thị mặc định
    // Hiển thị thông báo tùy chỉnh nếu cần, ví dụ:
    // Lưu ý: ScaffoldMessenger cần BuildContext, nên cần xử lý trong widget
  });


  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SmartHomeApp(),
    ),
  );
}

// Theme Provider để hỗ trợ Dark Mode
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  static final _lightTheme = ThemeData.light().copyWith(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.grey[100],
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
      labelMedium: TextStyle(fontSize: 14, color: Colors.grey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static final _darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.blueGrey,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey[900],
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
      labelMedium: TextStyle(fontSize: 14, color: Colors.grey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Home Controller',
          theme: themeProvider.themeData,
          home: const MainPage(),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const ChatBotPage(),
    const NotificationPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'SMART HOME CONTROLLER',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(context.watch<ThemeProvider>().isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 8,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Smart Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'ChatBot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông Báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}




class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  NotificationPageState createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  final supabase = Supabase.instance.client;
  late RealtimeChannel channel;

  @override
  @override
  void initState() {
    super.initState();
    fetchNotifications();

    channel = supabase.channel('realtime:notification');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notification',
      callback: (payload) {
        print("📥 Nhận realtime payload: ${payload.newRecord}");

        setState(() {
          notifications.insert(0, {
            'id': payload.newRecord['id']?.toString() ?? '',
            'created_at': payload.newRecord['created_at']?.toString() ?? '',
            'content': payload.newRecord['content']?.toString() ?? '',
          });
        });
      },
    );

    channel.subscribe((status, [error]) {
      print("📡 Trạng thái subscribe: $status");
      if (error != null) {
        print("⚠️ Lỗi khi subscribe: $error");
      }
    });
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await supabase
          .from('notification')
          .select('id, created_at, content')
          .order('created_at', ascending: false);

      print("📦 Dữ liệu từ Supabase: $response");

      setState(() {
        notifications = response.map<Map<String, dynamic>>((notification) {
          final contentJson = notification['content'] as Map<String, dynamic>;
          return {
            'id': notification['id'].toString(),
            'created_at': notification['created_at'].toString(),
            'content': contentJson['title'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print("❌ Lỗi lấy dữ liệu thông báo từ Supabase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thông báo: $e')),
      );
    }
  }

  @override
  void dispose() {
    channel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'THÔNG BÁO',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                child: Text(
                  'Chưa có thông báo mới',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.notifications,
                          color: Colors.orange),
                      title: Text(
                        notification['content'],
                        style: TextStyle(
                          color: Theme.of(context).brightness ==
                              Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${notification['id']}\nThời gian: ${notification['created_at']}',
                        style: TextStyle(
                          color: Theme.of(context).brightness ==
                              Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}





class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  late RealtimeChannel channel;
  bool _isLoading = true;
  bool _hasError = false;

  // Danh sách các phòng với trạng thái động
  List<Map<String, dynamic>> sections = [
    {
      "title": "PHÒNG KHÁCH",
      "route": const RoomDetailPage(roomName: "PHÒNG KHÁCH", roomId: "room1"),
      "image": "assets/images/livingroom.jpg",
      "isLightOn": false,
      "isAcOn": false,
      "roomId": "room1",
    },
    {
      "title": "PHÒNG NGỦ",
      "route": const RoomDetailPage(roomName: "PHÒNG NGỦ", roomId: "room2"),
      "image": "assets/images/bedroom.jpg",
      "isLightOn": false,
      "isAcOn": false,
      "roomId": "room2",
    },
    {
      "title": "NHÀ BẾP",
      "route": const RoomDetailPage(roomName: "NHÀ BẾP", roomId: "room3"),
      "image": "assets/images/kitchen.jpg",
      "isLightOn": false,
      "isAcOn": false,
      "roomId": "room3",
    },
    {
      "title": "PHÒNG LÀM VIỆC",
      "route": const RoomDetailPage(roomName: "PHÒNG LÀM VIỆC", roomId: "room4"),
      "image": "assets/images/workingroom.jpg",
      "isLightOn": false,
      "isAcOn": false,
      "roomId": "room4",
    },
    {
      "title": "CẢNH BÁO CHÁY",
      "route": const FireAlertPage(),
      "image": "assets/images/fire_alert.png",
    },
    {
      "title": "KIỂM SOÁT RA VÀO",
      "route": const AccessControlPage(),
      "image": "assets/images/access_control.png",
    },
  ];

  bool _imagesPrecached = false;

  @override
  void initState() {
    super.initState();
    _fetchSwitchesData();
    _setupRealtimeSubscription();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      for (var section in sections) {
        precacheImage(AssetImage(section["image"]), context);
      }
      _imagesPrecached = true;
    }
  }

  Future<void> _fetchSwitchesData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      for (var section in sections) {
        if (section.containsKey("roomId")) {
          final roomId = section["roomId"];
          final switchesResponse = await supabase
              .from('switches_control')
              .select('switch_id, state')
              .eq('room_id', roomId);

          bool isLightOn = false;
          bool isAcOn = false;

          for (var switchData in switchesResponse) {
            final switchId = switchData['switch_id'];
            final state = switchData['state'] ?? false;
            if (switchId.endsWith('_1')) {
              isLightOn = state;
            } else if (switchId.endsWith('_2')) {
              isAcOn = state;
            }
          }

          setState(() {
            section["isLightOn"] = isLightOn;
            section["isAcOn"] = isAcOn;
          });
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi lấy dữ liệu switches từ Supabase: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải trạng thái thiết bị: $e')),
      );
    }
  }

  void _setupRealtimeSubscription() {
    channel = supabase.channel('realtime:switches_control');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'switches_control',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final roomId = newRecord['room_id'];
        final switchId = newRecord['switch_id'];
        final state = newRecord['state'] ?? false;

        setState(() {
          for (var section in sections) {
            if (section["roomId"] == roomId) {
              if (switchId.endsWith('_1')) {
                section["isLightOn"] = state;
              } else if (switchId.endsWith('_2')) {
                section["isAcOn"] = state;
              }
            }
          }
        });
      },
    ).subscribe((status, [error]) {
      print("📡 Trạng thái subscribe switches_control: $status");
      if (error != null) {
        print("⚠️ Lỗi khi subscribe: $error");
      }
    });
  }

  Widget _buildRoomCard(Map<String, dynamic> section, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => section["route"]),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                section["image"] ?? 'assets/images/placeholder.jpg',
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.blue[100],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section["title"],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black54),
                      ],
                    ),
                  ),
                  if (section.containsKey("isLightOn"))
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: section["isLightOn"] ? Colors.yellow : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          section["isLightOn"] ? 'Đèn bật' : 'Đèn tắt',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  if (section.containsKey("isAcOn"))
                    Row(
                      children: [
                        Icon(
                          Icons.ac_unit,
                          color: section["isAcOn"] ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          section["isAcOn"] ? 'Máy lạnh bật' : 'Máy lạnh tắt',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lỗi tải dữ liệu từ Supabase',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchSwitchesData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'NHÀ THÔNG MINH',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              physics: const NeverScrollableScrollPhysics(),
              cacheExtent: 1000,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: sections.length,
              itemBuilder: (context, index) => _buildRoomCard(sections[index], primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}





class RoomDetailPage extends StatefulWidget {
  final String roomName;
  final String roomId;

  const RoomDetailPage({super.key, required this.roomName, required this.roomId});

  @override
  RoomDetailPageState createState() => RoomDetailPageState();
}

class RoomDetailPageState extends State<RoomDetailPage> {
  Map<String, dynamic> sensorData = {};
  bool isLightOn = false;
  bool isAcOn = false;
  bool isFireSafe = true;
  String lastUpdateTime = "Đang cập nhật...";
  List<Map<String, dynamic>> historyData = [];
  bool _isLoading = true;
  bool _hasError = false;

  final supabase = Supabase.instance.client;
  late RealtimeChannel channel;

  int selectedHoursRange = 6; // Default: 6 hours

  // Thông tin OneSignal
  final String oneSignalAppId = ""; // Thay bằng App ID của bạn
  final String oneSignalApiKey = ""; // Thay bằng API Key của bạn

  @override
  void initState() {
    super.initState();
    _fetchSensorDataWithRetry();
    _fetchHistoryData();
    _setupRealtimeSubscription();
  }

  Future<void> _fetchSensorDataWithRetry({int retryCount = 3}) async {
    const retryDelay = Duration(seconds: 2);
    for (int attempt = 1; attempt <= retryCount; attempt++) {
      try {
        final sensorResponse = await supabase
            .from('sensor_data')
            .select('temperature, humidity, fire, timestamp')
            .eq('room_id', widget.roomId)
            .order('timestamp', ascending: false)
            .limit(1)
            .single();

        final switchesResponse = await supabase
            .from('switches_control')
            .select('switch_id, state')
            .eq('room_id', widget.roomId);

        setState(() {
          sensorData = {
            'temperature': sensorResponse['temperature'] ?? 0.0,
            'humidity': sensorResponse['humidity'] ?? 0.0,
          };
          isFireSafe = sensorResponse['fire'] ?? true;
          lastUpdateTime = "Cập nhật: ${sensorResponse['timestamp']}";
          for (var switchData in switchesResponse) {
            final switchId = switchData['switch_id'];
            final state = switchData['state'] ?? false;
            if (switchId.endsWith('_1')) {
              isLightOn = state;
            } else if (switchId.endsWith('_2')) {
              isAcOn = state;
            }
          }
          _isLoading = false;
          _hasError = false;
        });

        // Nếu phát hiện cháy, gửi thông báo và lưu lịch sử
        if (!isFireSafe) {
          await _sendFireAlert(widget.roomId, sensorResponse['timestamp']);
        }

        return;
      } catch (e) {
        print("Lỗi lấy dữ liệu từ Supabase (thử lần $attempt/$retryCount): $e");
        if (attempt == retryCount) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            lastUpdateTime = "Lỗi tải dữ liệu";
          });
        } else {
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  Future<void> _fetchHistoryData() async {
    try {
      final now = DateTime.now().toUtc();
      final hoursAgo = now.subtract(Duration(hours: selectedHoursRange));
      final response = await supabase
          .from('sensor_data')
          .select('temperature, humidity, timestamp')
          .eq('room_id', widget.roomId)
          .gte('timestamp', hoursAgo.toIso8601String())
          .order('timestamp', ascending: true);

      setState(() {
        historyData = response.map<Map<String, dynamic>>((entry) {
          final timestamp = DateTime.parse(entry['timestamp']).toLocal();
          return {
            'timestamp': timestamp,
            'temperature': (entry['temperature'] ?? 0.0).toDouble(),
            'humidity': (entry['humidity'] ?? 0.0).toDouble(),
          };
        }).toList();
      });
    } catch (e) {
      print("Lỗi lấy dữ liệu lịch sử từ Supabase: $e");
      setState(() {
        historyData = [];
      });
    }
  }

  void _setupRealtimeSubscription() {
    channel = supabase.channel('realtime:sensor_data:${widget.roomId}');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'sensor_data',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: widget.roomId,
      ),
      callback: (payload) async {
        final newRecord = payload.newRecord;
        setState(() {
          sensorData = {
            'temperature': newRecord['temperature'] ?? 0.0,
            'humidity': newRecord['humidity'] ?? 0.0,
          };
          isFireSafe = newRecord['fire'] ?? true;
          lastUpdateTime = "Cập nhật: ${newRecord['timestamp']}";
          historyData.add({
            'timestamp': DateTime.parse(newRecord['timestamp']).toLocal(),
            'temperature': (newRecord['temperature'] ?? 0.0).toDouble(),
            'humidity': (newRecord['humidity'] ?? 0.0).toDouble(),
          });
          if (historyData.length > 100) {
            historyData = historyData.sublist(historyData.length - 100);
          }
        });

        // Nếu phát hiện cháy, gửi thông báo và lưu lịch sử
        if (!isFireSafe) {
          await _sendFireAlert(widget.roomId, newRecord['timestamp']);
        }
      },
    ).subscribe();
  }

  // Gửi thông báo đẩy qua OneSignal và lưu lịch sử cảnh báo vào bảng OneSignalFire
  Future<void> _sendFireAlert(String roomId, String timestamp) async {
    const String oneSignalApiUrl = 'https://onesignal.com/api/v1/notifications';
    final Map<String, dynamic> notificationData = {
      'app_id': oneSignalAppId,
      'included_segments': ['Subscribed Users'],
      'contents': {
        'en': 'Cảnh báo cháy ở phòng $roomId!',
      },
      'headings': {
        'en': 'Cảnh báo cháy!',
      },
    };

    try {
      // Gửi thông báo qua OneSignal
      final response = await http.post(
        Uri.parse(oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $oneSignalApiKey',
        },
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200) {
        print('Thông báo cháy đã được gửi cho phòng $roomId');
      } else {
        print('Lỗi khi gửi thông báo: ${response.statusCode} - ${response.body}');
      }

      // Lưu lịch sử cảnh báo vào bảng OneSignalFire
      await supabase.from('OneSignalFire').insert({
        'room_id': roomId,
        'timestamp': timestamp,
      });
    } catch (e) {
      print('Lỗi khi gửi thông báo hoặc lưu lịch sử: $e');
    }
  }

  Future<void> toggleDevice(String device, bool state) async {
    try {
      String switchId = device == 'light'
          ? 'switch${widget.roomId.replaceAll("room", "")}_1'
          : 'switch${widget.roomId.replaceAll("room", "")}_2';

      String mqttTopic;
      String roomType;
      switch (widget.roomId) {
        case 'room1':
          roomType = 'livingroom';
          break;
        case 'room2':
          roomType = 'bedroom';
          break;
        case 'room3':
          roomType = 'kitchen';
          break;
        case 'room4':
          roomType = 'workingroom';
          break;
        default:
          roomType = 'unknown';
      }
      mqttTopic = 'home/switches/$roomType/$switchId';

      final existingRecord = await supabase
          .from('switches_control')
          .select()
          .eq('room_id', widget.roomId)
          .eq('switch_id', switchId)
          .maybeSingle();

      if (existingRecord != null) {
        await supabase.from('switches_control').update({
          'state': state,
          'timestamp': DateTime.now().toIso8601String(),
        }).eq('room_id', widget.roomId).eq('switch_id', switchId);
      } else {
        await supabase.from('switches_control').insert({
          'room_id': widget.roomId,
          'switch_id': switchId,
          'state': state,
          'timestamp': DateTime.now().toIso8601String(),
          'mqtt_topic': mqttTopic,
        });
      }

      setState(() {
        if (device == 'light') isLightOn = state;
        else if (device == 'ac') isAcOn = state;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$device đã được ${state ? "bật" : "tắt"}')),
      );
    } catch (e) {
      print("Lỗi cập nhật $device lên Supabase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi cập nhật $device: $e")),
      );
      await _fetchSensorDataWithRetry();
    }
  }

  Widget _buildSensorCard(String label, String value, IconData icon, {Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color ?? Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              value,
              style: TextStyle(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(String label, IconData icon, bool isOn, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 120,
      height: 86,
      decoration: BoxDecoration(
        color: isOn ? Theme.of(context).primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: isOn ? Colors.white : Colors.black),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOn ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateTemperatureStats() {
    double sum = 0;
    double minVal = double.infinity;
    double maxVal = -double.infinity;
    double lastVal = 0;
    int count = 0;
    final now = DateTime.now();
    final hoursAgo = now.subtract(Duration(hours: selectedHoursRange));

    for (var data in historyData) {
      final DateTime timestamp = data['timestamp'];
      final double temp = data['temperature'].clamp(15.0, 45.0);
      final double xVal = timestamp.difference(hoursAgo).inMinutes / 60.0;
      if (xVal >= 0 && xVal <= selectedHoursRange * 2) {
        count++;
        sum += temp;
        if (temp < minVal) minVal = temp;
        if (temp > maxVal) maxVal = temp;
        lastVal = temp;
      }
    }
    return {
      'mean': count > 0 ? sum / count : 0,
      'min': count > 0 ? minVal : 15,
      'max': count > 0 ? maxVal : 45,
      'last': lastVal,
    };
  }

  Map<String, double> _calculateHumidityStats() {
    double sum = 0;
    double minVal = double.infinity;
    double maxVal = -double.infinity;
    double lastVal = 0;
    int count = 0;
    final now = DateTime.now();
    final hoursAgo = now.subtract(Duration(hours: selectedHoursRange));

    for (var data in historyData) {
      final DateTime timestamp = data['timestamp'];
      final double hum = data['humidity'].clamp(0.0, 100.0);
      final double xVal = timestamp.difference(hoursAgo).inMinutes / 60.0;
      if (xVal >= 0 && xVal <= selectedHoursRange * 2) {
        count++;
        sum += hum;
        if (hum < minVal) minVal = hum;
        if (hum > maxVal) maxVal = hum;
        lastVal = hum;
      }
    }
    return {
      'mean': count > 0 ? sum / count : 0,
      'min': count > 0 ? minVal : 0,
      'max': count > 0 ? maxVal : 100,
      'last': lastVal,
    };
  }

  LineChartData _buildTemperatureChartData() {
    final now = DateTime.now();
    final hoursAgo = now.subtract(Duration(hours: selectedHoursRange));
    final spots = <FlSpot>[];

    for (var data in historyData) {
      final DateTime timestamp = data['timestamp'];
      final double temp = data['temperature'].clamp(15.0, 45.0);
      final double xVal = timestamp.difference(hoursAgo).inMinutes / 60.0;
      if (xVal >= 0 && xVal <= selectedHoursRange * 2) {
        spots.add(FlSpot(xVal, temp));
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 10,
        verticalInterval: 2,
        getDrawingHorizontalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.3),
        getDrawingVerticalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.3),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            interval: 10,
            getTitlesWidget: (value, meta) {
              if ([15, 25, 35, 45].contains(value.toInt())) {
                return Text('${value.toInt()}°C', style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 2,
            getTitlesWidget: (value, meta) {
              final hour = (now.hour - selectedHoursRange + value.toInt()) % 24;
              return Text('${hour}h', style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: selectedHoursRange * 2.0,
      minY: 15,
      maxY: 45,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 1,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.blueAccent : Theme.of(context).primaryColor,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
            return LineTooltipItem(
              '${spot.y.toStringAsFixed(1)}°C',
              const TextStyle(color: Colors.white, fontSize: 12),
            );
          }).toList(),
        ),
      ),
    );
  }

  LineChartData _buildHumidityChartData() {
    final now = DateTime.now();
    final hoursAgo = now.subtract(Duration(hours: selectedHoursRange));
    final spots = <FlSpot>[];

    for (var data in historyData) {
      final DateTime timestamp = data['timestamp'];
      final double hum = data['humidity'].clamp(0.0, 100.0);
      final double xVal = timestamp.difference(hoursAgo).inMinutes / 60.0;
      if (xVal >= 0 && xVal <= selectedHoursRange * 2) {
        spots.add(FlSpot(xVal, hum));
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 25,
        verticalInterval: 2,
        getDrawingHorizontalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.3),
        getDrawingVerticalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.3),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            interval: 25,
            getTitlesWidget: (value, meta) {
              if ([0, 25, 50, 75, 100].contains(value.toInt())) {
                return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 2,
            getTitlesWidget: (value, meta) {
              final hour = (now.hour - selectedHoursRange + value.toInt()) % 24;
              return Text('${hour}h', style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: selectedHoursRange * 2.0,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 1,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.blueAccent : Theme.of(context).primaryColor,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
            return LineTooltipItem(
              '${spot.y.toStringAsFixed(1)}%',
              const TextStyle(color: Colors.white, fontSize: 12),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    final tempStats = _calculateTemperatureStats();
    final humStats = _calculateHumidityStats();

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            widget.roomName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Roboto', color: Colors.white),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lỗi tải dữ liệu từ Supabase',
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _fetchSensorDataWithRetry();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(lastUpdateTime, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: textColor)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildSensorCard(
                  'Nhiệt độ',
                  sensorData.isEmpty ? 'Đang tải...' : '${sensorData['temperature']?.toStringAsFixed(1) ?? '--'}°C',
                  Icons.thermostat,
                ),
                _buildSensorCard(
                  'Độ ẩm',
                  sensorData.isEmpty ? 'Đang tải...' : '${sensorData['humidity']?.toStringAsFixed(1) ?? '--'}%',
                  Icons.water_drop,
                ),
                _buildSensorCard(
                  'Cảnh báo cháy',
                  isFireSafe ? 'An toàn' : 'Nguy hiểm',
                  Icons.warning,
                  color: isFireSafe ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Điều khiển',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Roboto', color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton('Đèn', Icons.lightbulb, isLightOn, () async => await toggleDevice('light', !isLightOn)),
                _buildControlButton('Máy lạnh', Icons.ac_unit, isAcOn, () async => await toggleDevice('ac', !isAcOn)),
              ],
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Thống kê nhiệt độ theo realtime',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Roboto', color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
                    child: Stack(
                      children: [
                        LineChart(_buildTemperatureChartData()),
                        if (historyData.isEmpty)
                          Center(
                            child: Text(
                              'Không có dữ liệu nhiệt độ',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Trung bình', style: TextStyle(color: textColor, fontSize: 12))),
                      DataColumn(label: Text('Thấp nhất', style: TextStyle(color: textColor, fontSize: 12))),
                      DataColumn(label: Text('Cao nhất', style: TextStyle(color: textColor, fontSize: 12))),
                      DataColumn(label: Text('Gần đây', style: TextStyle(color: textColor, fontSize: 12))),
                    ],
                    rows: [
                      DataRow(
                        cells: [
                          DataCell(Text('${tempStats['mean']!.toStringAsFixed(1)}°C', style: TextStyle(color: textColor, fontSize: 12))),
                          DataCell(Text('${tempStats['min']!.toStringAsFixed(1)}°C', style: TextStyle(color: textColor, fontSize: 12))),
                          DataCell(Text('${tempStats['max']!.toStringAsFixed(1)}°C', style: TextStyle(color: textColor, fontSize: 12))),
                          DataCell(Text('${tempStats['last']!.toStringAsFixed(1)}°C', style: TextStyle(color: textColor, fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Thống kê độ ẩm theo realtime',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Roboto', color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
                    child: Stack(
                      children: [
                        LineChart(_buildHumidityChartData()),
                        if (historyData.isEmpty)
                          Center(
                            child: Text(
                              'Không có dữ liệu độ ẩm',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Trung bình', style: TextStyle(color: textColor, fontSize: 12))),
                      DataColumn(label: Text('Thấp nhất', style: TextStyle(color: textColor, fontSize: 12))),
                      DataColumn(label: Text('Cao nhất', style: TextStyle(color: textColor, fontSize: 12))),
                      DataColumn(label: Text('Gần đây', style: TextStyle(color: textColor, fontSize: 12))),
                    ],
                    rows: [
                      DataRow(
                        cells: [
                          DataCell(Text('${humStats['mean']!.toStringAsFixed(1)}%', style: TextStyle(color: textColor, fontSize: 12))),
                          DataCell(Text('${humStats['min']!.toStringAsFixed(1)}%', style: TextStyle(color: textColor, fontSize: 12))),
                          DataCell(Text('${humStats['max']!.toStringAsFixed(1)}%', style: TextStyle(color: textColor, fontSize: 12))),
                          DataCell(Text('${humStats['last']!.toStringAsFixed(1)}%', style: TextStyle(color: textColor, fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 2, label: Text('2h')),
                  ButtonSegment<int>(value: 4, label: Text('4h')),
                  ButtonSegment<int>(value: 6, label: Text('6h')),
                ],
                selected: {selectedHoursRange},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    selectedHoursRange = newSelection.first;
                    _fetchHistoryData();
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                  foregroundColor: Theme.of(context).primaryColor,
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: Theme.of(context).primaryColor,
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class FireAlertPage extends StatefulWidget {
  const FireAlertPage({super.key});

  @override
  FireAlertPageState createState() => FireAlertPageState();
}

class FireAlertPageState extends State<FireAlertPage> {
  final TextEditingController phoneController = TextEditingController();
  List<Map<String, String>> fireAlerts = []; // Danh sách thuê bao đăng ký
  List<Map<String, String>> fireHistory = []; // Danh sách lịch sử cảnh báo cháy

  final supabase = Supabase.instance.client;
  late RealtimeChannel channel;
  late RealtimeChannel fireHistoryChannel;

  @override
  void initState() {
    super.initState();
    fetchFireAlerts();
    fetchFireHistory();

    // Theo dõi bảng fire_alerts (thuê bao đăng ký)
    channel = supabase.channel('realtime:fire_alerts');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'fire_alerts',
      callback: (payload) {
        setState(() {
          fireAlerts.insert(0, {
            'time': payload.newRecord['timestamp']?.toString() ?? '',
            'phone': payload.newRecord['phone_number']?.toString() ?? '',
            'status': payload.newRecord['status']?.toString() ?? '',
          });
        });
      },
    ).subscribe();

    // Theo dõi bảng OneSignalFire (lịch sử cảnh báo cháy)
    fireHistoryChannel = supabase.channel('realtime:onesignalfire');
    fireHistoryChannel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'OneSignalFire',
      callback: (payload) {
        setState(() {
          fireHistory.insert(0, {
            'room_id': payload.newRecord['room_id']?.toString() ?? '',
            'timestamp': payload.newRecord['timestamp']?.toString() ?? '',
          });
        });
      },
    ).subscribe();
  }

  Future<void> fetchFireAlerts() async {
    try {
      final response = await supabase
          .from('fire_alerts')
          .select('timestamp, phone_number, status')
          .order('timestamp', ascending: false);

      setState(() {
        fireAlerts = response.map((alert) => {
          'time': alert['timestamp']?.toString() ?? '',
          'phone': alert['phone_number']?.toString() ?? '',
          'status': alert['status']?.toString() ?? '',
        }).toList();
      });
    } catch (e) {
      print("Lỗi lấy dữ liệu cảnh báo cháy từ Supabase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu cảnh báo cháy: $e')),
      );
    }
  }

  Future<void> fetchFireHistory() async {
    try {
      final response = await supabase
          .from('OneSignalFire')
          .select('room_id, timestamp')
          .order('timestamp', ascending: false);

      setState(() {
        fireHistory = response.map((entry) => {
          'room_id': entry['room_id']?.toString() ?? '',
          'timestamp': entry['timestamp']?.toString() ?? '',
        }).toList();
      });
    } catch (e) {
      print("Lỗi lấy dữ liệu lịch sử cảnh báo cháy từ Supabase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu lịch sử cảnh báo cháy: $e')),
      );
    }
  }

  bool _validatePhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^0\d{9,10}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  Future<void> sendPhoneNumber(String phoneNumber) async {
    try {
      await supabase.from('fire_alerts').insert({
        'phone_number': phoneNumber,
        'status': 'Đã gửi',
        'timestamp': DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm số điện thoại thành công!')),
      );
    } catch (e) {
      print("Lỗi cập nhật số điện thoại lên Supabase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void addPhoneNumber() async {
    final phoneNumber = phoneController.text.trim();
    if (phoneNumber.isNotEmpty) {
      if (_validatePhoneNumber(phoneNumber)) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: Text('Bạn muốn thêm số $phoneNumber?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  await sendPhoneNumber(phoneNumber);
                  Navigator.pop(context);
                  setState(() {
                    phoneController.clear();
                  });
                },
                child: const Text('Thêm'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Số điện thoại không hợp lệ. Vui lòng nhập lại (bắt đầu bằng 0, dài 10 hoặc 11 số).')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
    }
  }

  Widget _buildAlertCard(Map<String, String> alert) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          alert['status'] == 'Đã gửi' ? Icons.check_circle : Icons.error,
          color: alert['status'] == 'Đã gửi' ? Colors.green : Colors.red,
        ),
        title: Text(
          'SĐT: ${alert["phone"]}',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        subtitle: Text(
          'Thời gian: ${alert["time"]}',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildFireHistoryItem(Map<String, String> history) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(
          Icons.warning,
          color: Colors.red,
        ),
        title: Text(
          'Phòng: ${history["room_id"]}',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        subtitle: Text(
          'Thời gian cảnh báo: ${history["timestamp"]}',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.unsubscribe();
    fireHistoryChannel.unsubscribe();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'CẢNH BÁO CHÁY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nhập số điện thoại',
                          prefixIcon: const Icon(Icons.phone),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => phoneController.clear(),
                          ),
                          border: const OutlineInputBorder(),
                          hintText: 'VD: 0123456789',
                          hintStyle: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: addPhoneNumber,
                        child: const Text('Thêm số điện thoại'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Lịch sử thuê bao được đăng ký cảnh báo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200, // Đặt chiều cao cố định cho danh sách
                child: fireAlerts.isEmpty
                    ? Center(
                  child: Text(
                    'Chưa có thuê bao nào',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: fireAlerts.length,
                  itemBuilder: (context, index) => _buildAlertCard(fireAlerts[index]),
                ),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Lịch sử cảnh báo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200, // Đặt chiều cao cố định cho danh sách
                child: fireHistory.isEmpty
                    ? Center(
                  child: Text(
                    'Chưa có cảnh báo cháy nào',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: fireHistory.length,
                  itemBuilder: (context, index) => _buildFireHistoryItem(fireHistory[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class AccessControlPage extends StatefulWidget {
  const AccessControlPage({super.key});

  @override
  AccessControlPageState createState() => AccessControlPageState();
}

class AccessControlPageState extends State<AccessControlPage> {
  List<Map<String, String>> accessHistory = [];
  final TextEditingController _rfidController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _filterStatus = 'Tất cả';

  final supabase = Supabase.instance.client;
  late RealtimeChannel channel;

  @override
  void initState() {
    super.initState();
    fetchAccessHistory();

    channel = supabase.channel('realtime:rfid_logs');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'rfid_logs',
      callback: (payload) async {
        final userId = payload.newRecord['user_id']?.toString() ?? '';
        final user = await supabase
            .from('users')
            .select('user_name')
            .eq('user_id', userId)
            .maybeSingle();

        setState(() {
          accessHistory.insert(0, {
            'time': payload.newRecord['timestamp']?.toString() ?? '',
            'card': userId,
            'name': user?['user_name']?.toString() ?? 'Không xác định',
            'status': payload.newRecord['action'] == 'IN' ? 'Hợp lệ' : 'Ra ngoài',
            'mqtt_topic': payload.newRecord['mqtt_topic']?.toString() ?? '',
          });
        });
      },
    ).subscribe();
  }

  Future<void> fetchAccessHistory() async {
    try {
      final response = await supabase
          .from('rfid_logs')
          .select('timestamp, user_id, action, mqtt_topic')
          .order('timestamp', ascending: false);

      final List<Map<String, String>> history = [];
      for (var entry in response) {
        final userId = entry['user_id']?.toString() ?? '';
        final user = await supabase
            .from('users')
            .select('user_name')
            .eq('user_id', userId)
            .maybeSingle();

        history.add({
          'time': entry['timestamp']?.toString() ?? '',
          'card': userId,
          'name': user?['user_name']?.toString() ?? 'Không xác định',
          'status': entry['action'] == 'IN' ? 'Hợp lệ' : 'Ra ngoài',
          'mqtt_topic': entry['mqtt_topic']?.toString() ?? '',
        });
      }

      setState(() {
        accessHistory = history;
      });
    } catch (e) {
      print("Lỗi lấy lịch sử kiểm soát ra vào từ Supabase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải lịch sử kiểm soát: $e')),
      );
    }
  }

  Future<bool> checkUserExists(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print("Lỗi kiểm tra user_id: $e");
      return false;
    }
  }

  Future<void> registerEntryExit(String rfid, String name) async {
    try {
      final rfidRegex = RegExp(r'^rfid\d{3}$');
      if (!rfidRegex.hasMatch(rfid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Mã RFID không hợp lệ. Vui lòng nhập mã bắt đầu bằng "rfid" và có 7 ký tự (ví dụ: rfid001).')),
        );
        return;
      }

      if (name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập tên người dùng.')),
        );
        return;
      }

      bool userExists = await checkUserExists(rfid);
      if (userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Mã RFID $rfid đã tồn tại trong hệ thống. Vui lòng sử dụng mã khác.')),
        );
        return;
      }

      await supabase.from('users').insert({
        'user_id': rfid,
        'user_name': name.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm người dùng $name với mã RFID $rfid')),
      );
      _rfidController.clear();
      _nameController.clear();
    } catch (e) {
      print("Lỗi đăng ký người dùng: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi đăng ký người dùng: $e')));
    }
  }

  Widget _buildHistoryCard(Map<String, String> entry) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          entry['status'] == 'Hợp lệ' ? Icons.check_circle : Icons.exit_to_app,
          color: entry['status'] == 'Hợp lệ' ? Colors.green : Colors.red,
        ),
        title: Text(
          'Tên: ${entry["name"]}',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        subtitle: Text(
          'Mã RFID: ${entry["card"]}\nThời gian: ${entry["time"]}',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.unsubscribe();
    _rfidController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _filterStatus == 'Tất cả'
        ? accessHistory
        : accessHistory.where((entry) => entry['status'] == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'KIỂM SOÁT RA VÀO',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đăng ký người dùng mới',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rfidController,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Mã RFID',
                        hintText: 'VD: rfid001',
                        border: const OutlineInputBorder(),
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tên người dùng',
                        border: const OutlineInputBorder(),
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final rfid = _rfidController.text.trim();
                        final name = _nameController.text.trim();
                        if (rfid.isNotEmpty && name.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận'),
                              content: Text('Đăng ký $name với mã $rfid?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await registerEntryExit(rfid, name);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Đăng ký'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text('Vui lòng nhập đầy đủ mã RFID và tên')),
                          );
                        }
                      },
                      child: const Text('Đăng ký'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Lịch sử kiểm soát ra vào',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]!
                          : Colors.grey[600]!,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    underline: const SizedBox(), // Ẩn đường viền mặc định
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    dropdownColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.white,
                    items: ['Tất cả', 'Hợp lệ', 'Ra ngoài'].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                    },
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: 16,
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return ['Tất cả', 'Hợp lệ', 'Ra ngoài'].map((status) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            status,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            filteredHistory.isEmpty
                ? Center(
              child: Text(
                'Chưa có lịch sử ra vào',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            )
                : ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) =>
                  _buildHistoryCard(filteredHistory[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  ChatBotPageState createState() => ChatBotPageState();
}

class ChatBotPageState extends State<ChatBotPage> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String _webhookUrl = '';
  String _sessionId = '';
  static const String _chatHistoryKey = 'chat_history';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
    _loadSettings();
    _loadChatHistory();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadSettings() async {
    final url = await ApiUrlManager.getWebhookUrl();
    final sessionId = await ApiUrlManager.getSessionId();
    setState(() {
      _webhookUrl = url;
      _sessionId = sessionId;
    });
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? history = prefs.getStringList(_chatHistoryKey);
    if (history != null) {
      setState(() {
        _messages.addAll(
            history.map((item) => Map<String, String>.from(jsonDecode(item))).toList());
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, String>> history = List.from(_messages);
    if (history.length > 6) {
      history = history.sublist(history.length - 6);
    }
    await prefs.setStringList(
        _chatHistoryKey, history.map((item) => jsonEncode(item)).toList());
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _webhookUrl.isEmpty || _sessionId.isEmpty) {
      setState(() {
        _messages.add({
          "sender": "bot",
          "text": "Vui lòng nhập tin nhắn và kiểm tra cài đặt.",
          "time": DateTime.now().toString().substring(11, 16),
        });
      });
      await _flutterTts.speak("Vui lòng nhập tin nhắn và kiểm tra cài đặt.");
      await _saveChatHistory();
      return;
    }

    setState(() {
      _messages.add({
        "sender": "user",
        "text": message,
        "time": DateTime.now().toString().substring(11, 16),
      });
      _textController.clear();
    });
    await _saveChatHistory();

    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);
    const Duration timeoutDuration = Duration(seconds: 10);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final postResponse = await http
            .post(
          Uri.parse(_webhookUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode([
            {
              'sessionId': _sessionId,
              'action': 'sendMessage',
              'chatInput': message,
            }
          ]),
        )
            .timeout(timeoutDuration);

        if (postResponse.statusCode == 200) {
          final responseData = jsonDecode(postResponse.body);
          final botResponse = responseData.isNotEmpty && responseData[0].containsKey('output')
              ? responseData[0]['output']
              : "Không có phản hồi từ server.";
          setState(() {
            _messages.add({
              "sender": "bot",
              "text": botResponse,
              "time": DateTime.now().toString().substring(11, 16),
            });
          });
          await _flutterTts.speak(botResponse);
          await _saveChatHistory();
          return;
        } else {
          if (attempt == maxRetries) {
            setState(() {
              _messages.add({
                "sender": "bot",
                "text": "Lỗi POST: ${postResponse.statusCode}",
                "time": DateTime.now().toString().substring(11, 16),
              });
            });
            await _flutterTts.speak("Lỗi khi gửi tin nhắn.");
            await _saveChatHistory();
          }
        }
      } catch (e) {
        if (attempt == maxRetries) {
          setState(() {
            _messages.add({
              "sender": "bot",
              "text": "Lỗi kết nối: $e",
              "time": DateTime.now().toString().substring(11, 16),
            });
          });
          await _flutterTts.speak("Lỗi kết nối.");
          await _saveChatHistory();
        }
      }

      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _textController.text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Widget _buildChatBubble(Map<String, String> message) {
    final isUser = message["sender"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.android, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft:
                  isUser ? const Radius.circular(12) : const Radius.circular(0),
                  bottomRight:
                  isUser ? const Radius.circular(0) : const Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message["text"] ?? "",
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message["time"] ?? "",
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'CHATBOT',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa lịch sử chat'),
                  content: const Text('Bạn có chắc muốn xóa tất cả tin nhắn?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          _messages.clear();
                        });
                        await _saveChatHistory();
                        Navigator.pop(context);
                      },
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Text(
                'Bắt đầu trò chuyện nào!',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            )
                : ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildChatBubble(_messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(_isListening ? 8 : 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red : Colors.grey,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white),
                  ),
                  onPressed: _listen,
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final TextEditingController _urlController = TextEditingController();
  String _currentWebhookUrl = '';
  String _currentSessionId = ''; // Biến để hiển thị Session ID
  List<String> _urlHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _generateAndSaveSessionId(); // Tạo Session ID mới mỗi khi mở app
  }

  Future<void> _generateAndSaveSessionId() async {
    const uuid = Uuid();
    final newSessionId = uuid.v4().replaceAll('-', ''); // Tạo UUID v4 và bỏ dấu gạch nối
    await ApiUrlManager.setSessionId(newSessionId); // Lưu Session ID mới
    setState(() {
      _currentSessionId = newSessionId; // Cập nhật Session ID để hiển thị
    });
    print('Session ID mới đã được tạo: $newSessionId'); // Debug để kiểm tra
  }

  Future<void> _loadSettings() async {
    final webhookUrl = await ApiUrlManager.getWebhookUrl();
    final urlHistory = await ApiUrlManager.getWebhookUrlHistory();
    final sessionId = await ApiUrlManager.getSessionId(); // Lấy Session ID hiện tại
    setState(() {
      _currentWebhookUrl = webhookUrl;
      _urlController.text = webhookUrl;
      _urlHistory = urlHistory;
      _currentSessionId = sessionId.isNotEmpty ? sessionId : _currentSessionId; // Hiển thị Session ID nếu có
    });
  }

  Future<void> _saveSettings() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Lưu cài đặt mới?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                await ApiUrlManager.setWebhookUrl(newUrl);
                setState(() {
                  _currentWebhookUrl = newUrl;
                  _urlHistory = [
                    newUrl,
                    ..._urlHistory.where((url) => url != newUrl)
                  ];
                  if (_urlHistory.length > 4) {
                    _urlHistory = _urlHistory.sublist(0, 4);
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã lưu Webhook URL: $newUrl')),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Webhook URL hợp lệ')),
      );
    }
  }

  Future<void> _useHistoryUrl(String url) async {
    await ApiUrlManager.setWebhookUrl(url);
    setState(() {
      _currentWebhookUrl = url;
      _urlController.text = url;
      _urlHistory = [url, ..._urlHistory.where((u) => u != url)];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sử dụng Webhook URL: $url')),
    );
  }

  Widget _buildHistoryCard(String item, String currentItem, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          item,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        trailing: Icon(
          item == currentItem ? Icons.check_circle : Icons.history,
          color: item == currentItem ? Colors.green : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'CÀI ĐẶT',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cài đặt Webhook URL',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Webhook URL',
                        hintText: 'VD: https://your-webhook-url.com',
                        border: const OutlineInputBorder(),
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      readOnly: true, // Không cho phép chỉnh sửa
                      controller: TextEditingController(text: _currentSessionId), // Hiển thị Session ID
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Session ID (Tự động tạo)',
                        border: const OutlineInputBorder(),
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Lưu cài đặt'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Lịch sử Webhook URL',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _urlHistory.isEmpty
                ? Center(
              child: Text(
                'Chưa có lịch sử Webhook URL',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            )
                : ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _urlHistory.length,
              itemBuilder: (context, index) => _buildHistoryCard(
                _urlHistory[index],
                _currentWebhookUrl,
                    () => _useHistoryUrl(_urlHistory[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}



class ApiUrlManager {
  static const String _webhookUrlKey = 'webhook_url';
  static const String _webhookUrlHistoryKey = 'webhook_url_history';
  static const String _sessionIdKey = 'session_id';

  static const String defaultWebhookUrl = 'https://n8n-home.xyz/webhook/chat';

  static Future<String> getWebhookUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_webhookUrlKey) ?? defaultWebhookUrl;
  }

  static Future<String> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionIdKey) ?? ''; // Trả về rỗng nếu chưa có
  }

  static Future<List<String>> getWebhookUrlHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_webhookUrlHistoryKey) ?? [];
  }

  static Future<void> setWebhookUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webhookUrlKey, url);
    List<String> history = prefs.getStringList(_webhookUrlHistoryKey) ?? [];
    history = [url, ...history.where((u) => u != url)];
    if (history.length > 4) history = history.sublist(0, 4);
    await prefs.setStringList(_webhookUrlHistoryKey, history);
  }

  static Future<void> setSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
  }
}
