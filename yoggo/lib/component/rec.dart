import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/rec_loading.dart';
import 'package:yoggo/size_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:amplitude_flutter/amplitude.dart' as Amp;

import 'globalCubit/user/user_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

class Rec extends StatefulWidget {
  final int contentId;
  final void Function(String path)? onStop;
  final AudioPlayer bgmPlayer;

  const Rec(
      {Key? key, this.onStop, required this.contentId, required this.bgmPlayer})
      : super(key: key);

  @override
  State<Rec> createState() => _RecState();
}

class _RecState extends State<Rec> {
  late String token;
  bool stopped = false;
  String path_copy = '';
  int _recordDuration = 0;
  Timer? _timer;
  final _Rec = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  String? path = '';
  //StreamSubscription<Amplitude>? _amplitudeSub;
  //Amplitude? _amplitude;
  AudioPlayer audioPlayer = AudioPlayer();
  bool _waiting = false;

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
    _recordSub = _Rec.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    // _amplitudeSub = _Rec
    //     .onAmplitudeChanged(const Duration(milliseconds: 300))
    //     .listen((amp) => setState(() => _amplitude = amp));

    getToken();
    super.initState();
    _sendRecViewEvent();
  }

  Future<int> getId() async {
    var url = Uri.parse('${dotenv.get("API_SERVER")}user/id');
    var response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    var responseData = json.decode(response.body);
    var id = responseData[0];
    return id;
  }

  Future<void> _start(userId, purchase, record) async {
    try {
      if (await _Rec.hasPermission()) {
        var myAppDir = await getAppDirectory();
        var id = await getId();
        var playerExtension = Platform.isAndroid ? '$id.wav' : '$id.flac';
        await _Rec.start(
          path: '$myAppDir/$playerExtension',
          encoder: Platform.isAndroid
              ? AudioEncoder.wav
              : AudioEncoder.flac, // by default
        );

        if (Platform.isAndroid) ('$myAppDir/$playerExtension');
        _recordState = RecordState.record;
        _recordDuration = 0;

        _startTimer();
        _sendRecStartClickEvent();
      }
    } catch (e) {
      if (kDebugMode) {}
    }
  }

  Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _stop(userId, purchase, record) async {
    setState(() {
      stopped = true;
    });
    _timer?.cancel();
    _recordDuration = 0;
    //  if (Platform.isAndroid) stopRecording();
    path = await _Rec.stop(); //path받기
    _sendRecStopClickEvent();
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
    await _Rec.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await _Rec.resume();
  }

  void playAudio() async {
    await audioPlayer.play(DeviceFileSource(path_copy));
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Amp.Amplitude amplitude = Amp.Amplitude.getInstance();

  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    SizeConfig().init(context);
    return MaterialApp(
        home: Scaffold(
      body: Stack(
        children: [
          Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFAE4),
              ),
              child: SafeArea(
                  bottom: false,
                  top: false,
                  minimum: EdgeInsets.only(
                      left: 3 * SizeConfig.defaultSize!,
                      right: 3 * SizeConfig.defaultSize!),
                  child: Stack(children: [
                    Column(children: [
                      Expanded(
                          // HEADER
                          flex: 24,
                          child: Row(children: [
                            Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: Icon(Icons.clear,
                                      size: 3 * SizeConfig.defaultSize!),
                                  onPressed: () async {
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
                                    color: const Color.fromARGB(0, 0, 0, 0)))
                          ])),
                      Expanded(
                        // BODY
                        flex: 62,
                        child: Container(
                            // color: Color.fromARGB(250, 0, 100, 0),
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          // crossAxisAlignment: CrossAxisAlignment.,
                          children: [
                            Text(
                              '녹음-대본',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 2.1 * SizeConfig.defaultSize!,
                                fontFamily: 'font-thin'.tr(),
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ).tr()
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
                      child: SizedBox(
                        width: SizeConfig.defaultSize! * 200,
                        child: AlertDialog(
                          titlePadding: EdgeInsets.only(
                            top: SizeConfig.defaultSize! * 7,
                            bottom: SizeConfig.defaultSize! * 2,
                          ),
                          actionsPadding: EdgeInsets.only(
                            left: SizeConfig.defaultSize! * 5,
                            right: SizeConfig.defaultSize! * 5,
                            bottom: SizeConfig.defaultSize! * 5,
                            top: SizeConfig.defaultSize! * 3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                SizeConfig.defaultSize! * 3),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.9),
                          title: Center(
                            child: Text(
                              '녹음-완료문의',
                              style: TextStyle(
                                fontSize: SizeConfig.defaultSize! * 2.5,
                                fontFamily: 'font-basic'.tr(),
                              ),
                            ).tr(),
                          ),
                          actions: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    path = ''; // 이 버전을 원하지 않는 경우 path 초기화
                                    _sendRecRerecClickEvent();
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Rec(
                                                contentId: widget.contentId,
                                                bgmPlayer: widget.bgmPlayer,
                                              )),
                                    );
                                  },
                                  child: Container(
                                    width: SizeConfig.defaultSize! * 24,
                                    height: SizeConfig.defaultSize! * 4.5,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          SizeConfig.defaultSize! * 3),
                                      color: const Color(0xFFFFA91A),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '답변-부정',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'font-basic'.tr(),
                                          fontSize:
                                              2.2 * SizeConfig.defaultSize!,
                                        ),
                                      ).tr(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width:
                                        SizeConfig.defaultSize! * 4), // 간격 조정
                                GestureDetector(
                                  onTap: () {
                                    // 1초 후에 다음 페이지로 이동
                                    // if (path != null) {
                                    //   // 녹음을 해도 괜찮다고 판단했을 경우 백엔드에 보낸다
                                    //   widget.onStop?.call(path!);
                                    //   path_copy = path!.split('/').last;
                                    //   await sendRecord(path, path_copy);
                                    _sendRecKeepClickEvent();
                                    // }
                                    // Future.delayed(const Duration(seconds: 1),
                                    //     () async {
                                    //   print(userState.record);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => RecLoading(
                                                contentId: widget.contentId,
                                                onStop: widget.onStop,
                                                bgmPlayer: widget.bgmPlayer,
                                                path: path!,
                                              )),
                                    );
                                    // });
                                  },
                                  child: Container(
                                    width: SizeConfig.defaultSize! * 24,
                                    height: SizeConfig.defaultSize! * 4.5,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          SizeConfig.defaultSize! * 3),
                                      color: const Color(0xFFFFA91A),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '답변-긍정',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'font-basic'.tr(),
                                          fontSize:
                                              2.2 * SizeConfig.defaultSize!,
                                        ),
                                      ).tr(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
    _Rec.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    late Widget icon;

    if (_recordState != RecordState.stop) {
      _waiting = false;
      icon = Icon(
        Icons.stop,
        size: 5 * SizeConfig.defaultSize!,
        color: const Color.fromARGB(255, 255, 0, 0),
      );
    } else if (_waiting) {
      icon = const CircularProgressIndicator(color: Color(0xFFFFA91A));
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.circle,
          size: 5 * SizeConfig.defaultSize!,
          color: const Color.fromARGB(255, 255, 0, 0));
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
            if (_recordState != RecordState.stop) {
              _stop(userState.userId, userState.purchase, userState.record);
            } else {
              setState(() {
                _waiting = true;
              });
              _start(userState.userId, userState.purchase, userState.record);
            }
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
      "녹음-대기",
      style: TextStyle(
        fontSize: SizeConfig.defaultSize! * 1.8,
        fontFamily: 'font-basic'.tr(),
      ),
    ).tr();
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

  Future<void> _sendRecStartClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_start_click',
        parameters: <String, dynamic>{},
      );
      amplitude.logEvent('rec_start_click', eventProperties: {});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecStopClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_stop_click',
        parameters: <String, dynamic>{},
      );

      amplitude.logEvent('rec_stop_click', eventProperties: {});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecViewEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_view',
        parameters: <String, dynamic>{},
      );
      amplitude.logEvent('rec_view', eventProperties: {});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecRerecClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_rerec_click',
        parameters: <String, dynamic>{},
      );
      amplitude.logEvent('rec_rerec_click', eventProperties: {});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecKeepClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_keep_click',
        parameters: <String, dynamic>{
          //'voiceId': voiceId,
        },
      );
      amplitude.logEvent('rec_keep_click', eventProperties: {});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력r
      print('Failed to log event: $e');
    }
  }
}
