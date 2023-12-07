import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/globalCubit/user/user_cubit.dart';
import 'package:yoggo/size_config.dart';
import 'package:amplitude_flutter/amplitude.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../component/rec.dart';
import 'dart:io' show File, Platform;
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';

class RecInfo2 extends StatefulWidget {
  final int contentId;
  final AudioPlayer bgmPlayer;

  const RecInfo2({super.key, required this.contentId, required this.bgmPlayer});

  @override
  _RecInfo2State createState() => _RecInfo2State();
}

String mypath = '';

class _RecInfo2State extends State<RecInfo2> {
  //AudioPlayer advancedPlayer=
  AudioPlayer audioPlayer = AudioPlayer();
  final double _currentSliderValue = 0;
  bool playStart = false;
  late AnimationController _animationController;
  double percent = 0;
  AnimationController? _controller;
  Duration totalDuration = Duration(milliseconds: 18480);
  Duration currentPosition = Duration(seconds: 0);
  String currentSeconds = '00';

  double progress = 0;

  //Timer timer;

  @override
  void initState() {
    super.initState();
    _sendRecInfoViewEvent();
    audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        currentPosition = position;
        progress =
            currentPosition.inMicroseconds / totalDuration.inMicroseconds;
      });
    });

    audioPlayer.onDurationChanged.listen((Duration position) {
      setState(() {
        totalDuration = position;
      });
    });
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Amplitude amplitude = Amplitude.getInstance();

  @override
  void dispose() {
    // TODO: Add cleanup code

    audioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        currentPosition = Duration.zero;
        progress = 0;
        playStart = false;
      });
    });
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    final sw = (MediaQuery.of(context).size.width -
        MediaQuery.of(context).padding.left -
        MediaQuery.of(context).padding.right);
    final sh = (MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom);
    SizeConfig().init(context);
    return Scaffold(
        body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/images/bkground.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        minimum: EdgeInsets.only(
            left: 3 * SizeConfig.defaultSize!,
            right: 3 * SizeConfig.defaultSize!),
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                    // HEADER
                    flex: 2,
                    child: Row(children: [
                      Expanded(
                        flex: 1,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.clear,
                                    size: 3 * SizeConfig.defaultSize!),
                                onPressed: () async {
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
                              )
                            ]),
                      ),
                      Expanded(
                        flex: 8,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // 아이콘을 맨 왼쪽으로 정렬
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
                    flex: 7,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '녹음안내-설명2',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: SizeConfig.defaultSize! *
                                  2.8 *
                                  double.parse('font-ratio'.tr()),
                              fontFamily: 'font-basic'.tr(),
                            ),
                          ).tr(),
                          SizedBox(
                            height: 3 * SizeConfig.defaultSize!,
                          ),
                          Container(
                            width: SizeConfig.defaultSize! * 40,
                            height: SizeConfig.defaultSize! * 7,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    SizeConfig.defaultSize! * 8),
                                color: Colors.white),
                            child: Row(
                              children: [
                                SizedBox(width: SizeConfig.defaultSize! * 2),
                                GestureDetector(
                                    child: Icon(
                                        playStart
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: SizeConfig.defaultSize! * 3.5),
                                    onTap: () async {
                                      if (playStart) {
                                        audioPlayer.pause();
                                        setState(() {
                                          playStart = false;
                                        });
                                      } else {
                                        if (Platform.isAndroid) {
                                          audioPlayer.play(
                                              AssetSource('샘플음성-안드로이드'.tr()));
                                        } else {
                                          audioPlayer.play(
                                              AssetSource('샘플음성-애플'.tr()));
                                        }
                                        setState(() {
                                          playStart = true;
                                        });
                                      }
                                    }),
                                Text(
                                  '  0:${currentPosition.inSeconds < 10 ? '0' + currentPosition.inSeconds.toString() : currentPosition.inSeconds.toString()}',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 1.8 * SizeConfig.defaultSize!),
                                ),
                                Text(
                                  '샘플음성-길이'.tr(),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 1.8 * SizeConfig.defaultSize!),
                                ),
                                LinearPercentIndicator(
                                  width: SizeConfig.defaultSize! * 22,
                                  animation: false,
                                  lineHeight: SizeConfig.defaultSize! * 0.6,
                                  barRadius: Radius.circular(15),
                                  percent: progress,
                                  progressColor:
                                      Color.fromARGB(255, 255, 169, 26),
                                ),
                              ],
                            ),
                          ),
                        ])),
                Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () {
                          // print("TAP");
                          audioPlayer.stop();
                          setState(() {
                            playStart = false;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Rec(
                                contentId: widget.contentId,
                                bgmPlayer: widget.bgmPlayer,

                                // 다음 화면으로 contetnVoiceId를 가지고 이동
                              ),
                            ),
                          );
                        },
                        child: Container(
                            width: 31.1 * SizeConfig.defaultSize!,
                            height: 4.5 * SizeConfig.defaultSize!,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFFA91A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Stack(children: [
                              Positioned(
                                  right: 1 * SizeConfig.defaultSize!,
                                  top: 0.75 * SizeConfig.defaultSize!,
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: Colors.black,
                                    size: SizeConfig.defaultSize! * 3,
                                  )),
                              Center(
                                child: Text(
                                  "녹음안내-이동버튼2",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 2.3 *
                                          SizeConfig.defaultSize! *
                                          double.parse('font-ratio'.tr()),
                                      fontFamily: 'font-book'.tr()),
                                ).tr(),
                              ),
                            ])),
                      ),
                    ))
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _sendRecInfoViewEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_info_view',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'rec_info_view',
        eventProperties: {},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }
}
