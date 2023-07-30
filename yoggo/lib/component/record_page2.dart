import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/size_config.dart';
import './record_info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';

import 'globalCubit/user/user_cubit.dart';
import './record_request.dart';

class AudioRecorder extends StatefulWidget {
  final void Function(String path)? onStop;

  const AudioRecorder({Key? key, this.onStop}) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  late String token;
  bool stopped = false;
  String path_copy = '';
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  String? path = '';
  //StreamSubscription<Amplitude>? _amplitudeSub;
  //Amplitude? _amplitude;
  AudioPlayer audioPlayer = AudioPlayer();

  static const platformChannel = MethodChannel('com.sayit.yoggo/channel');

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token')!;
    });
  }

  // void sendPathToKotlin(path) async {
  //   try {
  //     await platformChannel.invokeMethod('setPath', {'path': path});
  //   } catch (e) {
  //     print('Error sending path to Kotlin: $e');
  //   }
  // }

  // Future<void> stopRecording() async {
  //   try {
  //     await platformChannel.invokeMethod('stopRecording');
  //     print('Recording stopped.'); // 녹음이 정상적으로 중지되었음을 출력합니다.
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  @override
  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    // _amplitudeSub = _audioRecorder
    //     .onAmplitudeChanged(const Duration(milliseconds: 300))
    //     .listen((amp) => setState(() => _amplitude = amp));

    getToken();
    super.initState();
  }

  Future<int> getId() async {
    var url = Uri.parse('https://yoggo-server.fly.dev/user/id');
    var response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    var responseData = json.decode(response.body);
    var id = responseData[0];
    return id;
  }

  Future<void> sendRecord(audioUrl, recordName) async {
    final UserCubit userCubit;
    var url = Uri.parse('https://yoggo-server.fly.dev/producer/record');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('recordUrl', audioUrl,
          contentType: MediaType('audio', 'x-wav')),
    );
    request.fields['recordName'] = recordName;
    var response = await request.send();
    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      //await prefs.setBool('record', true);
      //  await userCubit.fetchUser();
      print('Record sent successfully');
    } else {
      print('Failed to send record. Status code: ${response.statusCode}');
    }
  }

  Future<void> _start(purchase, record) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        var myAppDir = await getAppDirectory();
        var id = await getId();
        var playerExtension = Platform.isAndroid ? '$id.wav' : '$id.flac';
        await _audioRecorder.start(
          path: '$myAppDir/$playerExtension',
          encoder: Platform.isAndroid
              ? AudioEncoder.wav
              : AudioEncoder.flac, // by default
        );

        if (Platform.isAndroid) ('$myAppDir/$playerExtension');
        _recordState = RecordState.record;
        _recordDuration = 0;

        _startTimer();
        _sendRecStartClickEvent(purchase, record);
      }
    } catch (e) {
      if (kDebugMode) {}
    }
  }

  Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _stop(purchase, record) async {
    setState(() {
      stopped = true;
    });
    _timer?.cancel();
    _recordDuration = 0;
    //  if (Platform.isAndroid) stopRecording();
    path = await _audioRecorder.stop(); //path받기
    _sendRecStopClickEvent(purchase, record);
    //  sendPathToKotlin(path);
    // if (path != null) {
    //   widget.onStop?.call(path);
    //   path_copy = path.split('/').last;
    //   sendRecord(path, path_copy);
    // }
  }

  Future<void> _pause() async {
    playAudio();
    _timer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();
  }

  void playAudio() async {
    await audioPlayer.play(DeviceFileSource(path_copy));
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    SizeConfig().init(context);
    _sendRecIngViewEvent(userState.purchase, userState.record);
    return MaterialApp(
        home: Scaffold(
      body: Stack(
        children: [
          Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                image: AssetImage('lib/images/bkground.png'),
                fit: BoxFit.cover,
              )),
              child: SafeArea(
                  bottom: false,
                  top: false,
                  minimum: EdgeInsets.only(right: 3 * SizeConfig.defaultSize!),
                  child: Stack(children: [
                    Column(children: [
                      Expanded(
                          // HEADER
                          flex: 14,
                          child: Row(children: [
                            Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: Icon(Icons.clear,
                                      size: 3 * SizeConfig.defaultSize!),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                )),
                            Expanded(
                              flex: 8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'LOVEL',
                                    style: TextStyle(
                                      fontFamily: 'Modak',
                                      fontSize: SizeConfig.defaultSize! * 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                                flex: 1,
                                child: Container(
                                    color: Color.fromARGB(0, 0, 0, 0)))
                          ])),
                      Expanded(
                        // BODY
                        flex: 62,
                        child: Container(
                            // color: Color.fromARGB(250, 0, 100, 0),
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'As she emerges from the sea onto the shore, she realizes that\nher voice is gone, but she still recognizes its immeasurable beauty\nand preciousness. She expresses it in the following way:\n"Voice is an ineffable beauty. It is the purest and most precious gift.\nThough I have lost this cherished gift, I will embark on a journey\nto find true love through other means. Even without my voice,\nthe emotions and passions within me will not easily fade away.\nLove transcends language. In this quest to reclaim my precious voice,\nI will discover my true self and learn the ways of love and freedom."',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 2.1 * SizeConfig.defaultSize!,
                                fontFamily: 'Molengo',
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            )
                          ],
                        )),
                      ),
                      Expanded(
                        // FOOTER
                        flex: 24,
                        child: Row(children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                                // color: Color.fromARGB(250, 0, 100, 0)
                                ),
                          ),
                          Expanded(flex: 3, child: Container()),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                _buildRecordStopControl(),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                _buildText(),
                              ],
                            ),
                          ),
                          Expanded(flex: 1, child: Container())
                        ]),
                      ),
                    ]),
                    Visibility(
                      visible: stopped,
                      child: AlertDialog(
                        titlePadding: EdgeInsets.only(
                          left: SizeConfig.defaultSize! * 8,
                          right: SizeConfig.defaultSize! * 8,
                          top: SizeConfig.defaultSize! * 7,
                          bottom: SizeConfig.defaultSize! * 2,
                        ),
                        actionsPadding: EdgeInsets.only(
                          // left: SizeConfig.defaultSize! * 5,
                          // right: SizeConfig.defaultSize! * 5,
                          bottom: SizeConfig.defaultSize! * 5,
                          top: SizeConfig.defaultSize! * 3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              SizeConfig.defaultSize! * 3),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.9),
                        title: Text(
                          'Would you like to use the voice you just recorded?',
                          style: TextStyle(
                            fontSize: SizeConfig.defaultSize! * 2.5,
                            fontFamily: 'Molengo',
                          ),
                        ),
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  path = ''; // 이 버전을 원하지 않는 경우 path 초기화
                                  _sendRecRerecClickEvent(
                                      userState.purchase, userState.record);
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AudioRecorder()),
                                  );
                                },
                                child: Container(
                                  width: SizeConfig.defaultSize! * 24,
                                  height: SizeConfig.defaultSize! * 4.5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        SizeConfig.defaultSize! * 1.5),
                                    color: const Color(0xFFFFA91A),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No, Re-make',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Molengo',
                                        fontSize: 2.2 * SizeConfig.defaultSize!,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                  width: SizeConfig.defaultSize! * 4), // 간격 조정
                              GestureDetector(
                                onTap: () async {
                                  // 1초 후에 다음 페이지로 이동
                                  if (path != null) {
                                    // 녹음을 해도 괜찮다고 판단했을 경우 백엔드에 보낸다
                                    widget.onStop?.call(path!);
                                    path_copy = path!.split('/').last;
                                    await sendRecord(path, path_copy);
                                    _sendRecKeepClickEvent(
                                        userState.purchase, userState.record);
                                  }
                                  Future.delayed(const Duration(seconds: 1),
                                      () async {
                                    print(userState.record);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const recordRequest()),
                                    );
                                  });
                                },
                                child: Container(
                                  width: SizeConfig.defaultSize! * 24,
                                  height: SizeConfig.defaultSize! * 4.5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        SizeConfig.defaultSize! * 1.5),
                                    color: const Color(0xFFFFA91A),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Yes',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Molengo',
                                        fontSize: 2.2 * SizeConfig.defaultSize!,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ])))
        ],
      ),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    // _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    late Widget icon;

    if (_recordState != RecordState.stop) {
      icon = Icon(
        Icons.stop,
        size: 5 * SizeConfig.defaultSize!,
        color: Color.fromARGB(255, 255, 0, 0),
      );
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.circle,
          size: 5 * SizeConfig.defaultSize!,
          color: Color.fromARGB(255, 255, 0, 0));
    }

    return ClipOval(
      child: Material(
        child: InkWell(
          child: SizedBox(
            width: SizeConfig.defaultSize! * 5.2,
            height: SizeConfig.defaultSize! * 5.2,
            child: icon,
          ),
          onTap: () {
            (_recordState != RecordState.stop)
                ? _stop(userState.purchase, userState.record)
                : _start(userState.purchase, userState.record);
          },
        ),
      ),
    );
  }

  // Widget _buildPauseResumeControl() {
  //   if (_recordState == RecordState.stop) {
  //     return const SizedBox.shrink();
  //   }

  //   late Icon icon;
  //   late Color color;

  //   if (_recordState == RecordState.record) {
  //     icon = const Icon(Icons.pause, color: Colors.red, size: 30);
  //     color = Colors.red.withOpacity(0.1);
  //   } else {
  //     _stopRecording();
  //     // final theme = Theme.of(context);
  //     // icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
  //     // color = theme.primaryColor.withOpacity(0.1);
  //   }

  //   return ClipOval(
  //     child: Material(
  //       color: color,
  //       child: InkWell(
  //         child: SizedBox(width: 56, height: 56, child: icon),
  //         onTap: () {
  //           (_recordState == RecordState.pause) ? _resume() : _pause();
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return Text(
      "Waiting to record",
      style: TextStyle(
        fontSize: SizeConfig.defaultSize! * 1.8,
        fontFamily: 'Molengo',
      ),
    );
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: TextStyle(
          color: Colors.red,
          fontFamily: 'Oxygen',
          fontSize: 1.8 * SizeConfig.defaultSize!),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  Future<void> _sendRecStartClickEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_start_click',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecStopClickEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_stop_click',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecIngViewEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_ing_view',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecRerecClickEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_rerec_clic',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecKeepClickEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_keep_click',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
          //'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력r
      print('Failed to log event: $e');
    }
  }
}
