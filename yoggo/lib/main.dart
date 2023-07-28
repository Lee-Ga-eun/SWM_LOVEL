import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yoggo/component/home/view/home_screen.dart';
import 'package:yoggo/component/intro.dart';
import 'component/globalCubit/user/user_cubit.dart';
import 'component/globalCubit/user/user_state.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

void main() async {
  // 사용자 Cubit을 초기화합니다.
  WidgetsFlutterBinding
      .ensureInitialized(); // ensureInitialized()를 호출하여 바인딩 초기화

//Remove this method to stop OneSignal Debugging
  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
  OneSignal.shared.setAppId("2d42b96d-78df-43fe-b6d1-3899c3684ac5");
// The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    print("Accepted permission: $accepted");
  });

  await OneSignal.shared.getDeviceState().then(
        (value) => {
          print('::::: one signal :::: ${value!.userId}'),
        },
      );

  await Firebase.initializeApp();
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // 푸시
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  // const AndroidInitializationSettings initializationSettingsAndroid =
  //     AndroidInitializationSettings('ic_launcher');

  // await flutterLocalNotificationsPlugin
  //     .resolvePlatformSpecificImplementation<
  //         AndroidFlutterLocalNotificationsPlugin>()
  //     ?.requestPermission(); //권한 허용?

  // final DarwinInitializationSettings initializationSettingsDarwin = //ios는 성공
  //     DarwinInitializationSettings(
  //   onDidReceiveLocalNotification:
  //       (int? id, String? title, String? body, String? payload) async {},
  // );
  // const LinuxInitializationSettings initializationSettingsLinux =
  //     LinuxInitializationSettings(defaultActionName: 'Open notification');
  // final InitializationSettings initializationSettings = InitializationSettings(
  //     android: initializationSettingsAndroid,
  //     iOS: initializationSettingsDarwin,
  //     macOS: initializationSettingsDarwin,
  //     linux: initializationSettingsLinux);
  // await flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  // );
  // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
//푸시 종료
  final userCubit = UserCubit();

  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])
      .then((_) {
    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<UserCubit>.value(value: userCubit),
          // Add more Cubits here if needed
        ],
        child: const App(),
      ),
    );
  });
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    initialize();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white.withOpacity(0), // 투명한 배경 색상으로 설정
    ));
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
    return MaterialApp(
      home: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (!state.isDataFetched) {
            //isDataFetched = true --> 데이터 불러왔단 뜻
            return const SplashScreen(); //token이 없는 경우
          } else {
            return const HomeScreen(); // token이 있는 경우
          }
        },
      ),
    );
  }
}
