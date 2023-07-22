import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'component/intro.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  //runApp(const App());
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  bool isDebug = kDebugMode;
  if (isDebug) {
    analytics.setAnalyticsCollectionEnabled(true);
  }
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])
      .then((_) {
    runApp(const App());
  });
}

class App extends StatefulWidget {
  const App({super.key});
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _initialized = false;

  // static const platformChannel = MethodChannel('com.example.yoggo/channel');

  // Future<void> sendMessageToKotlin() async {
  //   try {
  //     final String response =
  //         await platformChannel.invokeMethod('sendMessage', {
  //       'message': 'Hello from Flutter',
  //     });
  //     print('Received response from Kotlin: $response');
  //   } catch (e) {
  //     print('Error sending message to Kotlin: $e');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    initialize();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  }

  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 6)); // 3초 동안 대기
    setState(() {
      _initialized = true; // 초기화 완료 상태 업데이트
    });
  }

  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      // Firebase 초기화 실패 시 에러 처리
      print('Failed to initialize Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // sendMessageToKotlin();
    return const MaterialApp(home: SplashScreen() // 초기화 상태에 따라 화면 표시
        );
  }
}
