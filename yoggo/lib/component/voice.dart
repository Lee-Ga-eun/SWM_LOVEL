import 'package:amplitude_flutter/amplitude.dart';
import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/globalCubit/user/user_state.dart';
import 'package:yoggo/constants.dart';
import 'package:yoggo/size_config.dart';
import 'package:yoggo/widgets/custom_dialog.dart';
import 'globalCubit/user/user_cubit.dart';
import 'rec_re.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

class VoiceProfile extends StatefulWidget {
  // final String infenrencedVoice;
  final AudioPlayer bgmPlayer;

  const VoiceProfile({
    super.key,
    required this.bgmPlayer,
    // required this.infenrencedVoice,
  });

  @override
  _VoiceProfileState createState() => _VoiceProfileState();
}

class _VoiceProfileState extends State<VoiceProfile> {
  AudioPlayer audioPlayer = AudioPlayer();
  late String token;
  late String inferenceUrl = "";
  late bool isLoading = true;
  late bool wantRemake = false;
  // void playAudio(String audioUrl) async {
  //   await audioPlayer.play(UrlSource(audioUrl));
  // }
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    getToken();
    _sendVoiceViewEvent();
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token')!;
      getVoiceInfo(token);
    });
  }

  Future<void> getVoiceInfo(String token) async {
    var response = await http.get(
      Uri.parse('${dotenv.get("API_SERVER")}user/inference'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != [] && data.isNotEmpty) {
        // 데이터가 빈 값이 아닌 경우
        setState(() {
          isLoading = false;
          inferenceUrl = data[0];
        });
      } else {
        setState(() {
          isLoading = true;
          //loadData(token);
          Future.delayed(const Duration(seconds: 1), () {
            getVoiceInfo(token);
          });
        });
      }
    }
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static Amplitude amplitude = Amplitude.getInstance();

  @override
  Widget build(BuildContext context) {
    final sw = (MediaQuery.of(context).size.width -
        MediaQuery.of(context).padding.left -
        MediaQuery.of(context).padding.right);
    final sh = (MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom);

    final userCubit = context.watch<UserCubit>();
    final UserState userState = userCubit.state;
    SizeConfig().init(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFAE4),
            ),
            child: SafeArea(
              bottom: false,
              top: true,
              // minimum: EdgeInsets.only(left: 7 * SizeConfig.defaultSize!),
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 1.5 * SizeConfig.defaultSize!,
                          ),
                          InkWell(
                            onTap: () async {
                              audioPlayer.stop();
                              dispose();
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              bool playingBgm =
                                  prefs.getBool('playingBgm') ?? true;
                              if (playingBgm) {
                                widget.bgmPlayer.resume();
                              }
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            child: Image.asset(
                              'lib/images/left.png',
                              width: 3 * SizeConfig.defaultSize!, // 이미지의 폭 설정
                            ),
                          ),
                        ]),
                  ),
                  Expanded(
                      flex: 12,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/images/icon/${userState.image}.png',
                            height: SizeConfig.defaultSize! * 15,
                          ),
                          Text(
                            userState.userName,
                            style: TextStyle(
                                color: black,
                                fontFamily: 'Suit',
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.defaultSize! * 2.4),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 3 * SizeConfig.defaultSize!,
                          ),
                          Container(
                            padding: EdgeInsets.only(
                                left: 1 * SizeConfig.defaultSize!,
                                right: 1 * SizeConfig.defaultSize!),
                            width: 35 * sizec,
                            height: 16 * sizec,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 1, color: Color(0xFFDDDDDD)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: 1 * SizeConfig.defaultSize!,
                                  right: 1 * SizeConfig.defaultSize!),
                              child: userState.inferenceUrl == null && isLoading
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                          Text(
                                            "목소리-제작중".tr(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize:
                                                  2.4 * SizeConfig.defaultSize!,
                                              fontFamily: 'Suit',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          SizedBox(
                                            height: 2 * SizeConfig.defaultSize!,
                                          ),
                                          const CircularProgressIndicator(
                                              color: Color(0xFFFFA91A)),
                                        ])
                                  : Text(
                                      "The most beautiful things in the world cannot be seen or touched, they are felt with the heart.",
                                      style: TextStyle(
                                          color: black,
                                          fontFamily: 'Suit',
                                          fontWeight: FontWeight.w500,
                                          fontSize:
                                              SizeConfig.defaultSize! * 2.4),
                                      textAlign: TextAlign.left,
                                    ),
                            ),
                          ),
                          SizedBox(
                            height: 3 * sizec,
                          ),
                          GestureDetector(
                            onTap: () async {
                              setState(() {
                                isPlaying = !isPlaying; // 재생/중지 상태를 토글
                                if (isPlaying) {
                                  _sendVoicePlayClickEvent(userState.voiceId!);
                                  audioPlayer.play(
                                      userState.inferenceUrl == null
                                          ? UrlSource(inferenceUrl)
                                          : UrlSource(userState.inferenceUrl!));
                                } else {
                                  audioPlayer.stop();
                                }
                              });
                            },
                            child: Container(
                                width: 35 * SizeConfig.defaultSize!,
                                height: 5.8 * SizeConfig.defaultSize!,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        1.4 * SizeConfig.defaultSize!),
                                    color: orangeDark),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '목소리듣기'.tr(),
                                        style: TextStyle(
                                          color: white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: SizeConfig.defaultSize! * 2,
                                          //fontFamily: 'font-point'.tr(),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 1.2 * sizec,
                                      ),
                                      Image.asset(
                                        'lib/images/play.png',
                                        width: 2.5 * SizeConfig.defaultSize!,
                                      ),
                                    ],
                                  ),
                                )),
                          ),
                          TextButton(
                            onPressed: () async {
                              _sendVoiceRerecClickEvent(userState.voiceId);
                              audioPlayer.stop();
                              setState(() {
                                wantRemake = true;
                              });
                            },
                            child: Text(
                              '재녹음'.tr(),
                              style: TextStyle(
                                color: orangeDark,
                                fontFamily: 'Suit',
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                fontSize: SizeConfig.defaultSize! * 2,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10 * SizeConfig.defaultSize!,
                          ),
                        ],
                      ))
                ],
              ),
            ),
          ),
          Visibility(
            visible: wantRemake,
            child: CustomDialog(
              '주의하세요!'.tr(),
              '재녹음-경고'.tr(),
              '답변-긍정-대문자'.tr(),
              '답변-부정'.tr(),
              () {
                _sendVoiceRemakeYesClickEvent();
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecRe(
                      bgmPlayer: widget.bgmPlayer,
                    ),
                  ),
                );
              },
              () {
                setState(() {
                  _sendVoiceRemakeNoClickEvent();
                  wantRemake = false;
                });
              },
            ),
          )
        ],
      ),
    );
  }

  Future<void> _sendVoiceRerecClickEvent(voiceId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'voice_rerec_click',
        parameters: <String, dynamic>{
          'voiceId': voiceId,
        },
      );
      await amplitude.logEvent(
        'voice_rerec_click',
        eventProperties: {
          'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendVoiceScriptClickEvent(voiceId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'voice_script_click',
        parameters: <String, dynamic>{
          'voiceId': voiceId,
        },
      );
      await amplitude.logEvent(
        'voice_script_click',
        eventProperties: {
          'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendVoiceIconClickEvent(voiceId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'voice_icon_click',
        parameters: <String, dynamic>{
          'voiceId': voiceId,
        },
      );
      await amplitude.logEvent(
        'voice_icon_click',
        eventProperties: {
          'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendVoiceNameClickEvent(voiceId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'voice_name_click',
        parameters: <String, dynamic>{
          'voiceId': voiceId,
        },
      );
      await amplitude.logEvent(
        'voice_name_click',
        eventProperties: {
          'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendVoicePlayClickEvent(voiceId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'voice_play_click',
        parameters: <String, dynamic>{
          'voiceId': voiceId,
        },
      );
      await amplitude.logEvent(
        'voice_play_click',
        eventProperties: {
          'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendVoiceViewEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'voice_view',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'voice_view',
        eventProperties: {},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendVoiceRemakeNoClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'voice_remake_no_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'voice_remake_no_click',
        eventProperties: {},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendVoiceRemakeYesClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'voice_remake_yes_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'voice_remake_yes_click',
        eventProperties: {},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }
}
