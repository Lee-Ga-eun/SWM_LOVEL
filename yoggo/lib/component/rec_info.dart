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

import '../constants.dart';

class RecInfo extends StatefulWidget {
  final int contentId;
  final AudioPlayer bgmPlayer;

  const RecInfo({super.key, required this.contentId, required this.bgmPlayer});

  @override
  _RecInfoState createState() => _RecInfoState();
}

String mypath = '';

class _RecInfoState extends State<RecInfo> {
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
              color: Color(0xFFFFFAE4),
            ),
            child: SafeArea(
                bottom: false,
                top: true,
                // minimum: EdgeInsets.only(left: 7 * SizeConfig.defaultSize!),
                child: Column(children: [
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
                  // SizedBox(
                  //   height: 5 * SizeConfig.defaultSize!,
                  // ),
                  Expanded(
                      flex: 10,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '녹음안내-설명2'.tr(),
                              style: TextStyle(
                                  color: black,
                                  fontFamily: 'Suit',
                                  fontWeight: FontWeight.w400,
                                  fontSize: SizeConfig.defaultSize! * 2.2),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: 3 * SizeConfig.defaultSize!,
                            ),
                            Container(
                              width: SizeConfig.defaultSize! * 36,
                              height: SizeConfig.defaultSize! * 7,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      SizeConfig.defaultSize! * 8),
                                  color: Colors.white),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Row(children: [
                                      SizedBox(
                                          width: SizeConfig.defaultSize! * 2),
                                      GestureDetector(
                                          child: Icon(
                                              playStart
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              size:
                                                  SizeConfig.defaultSize! * 3),
                                          onTap: () async {
                                            if (playStart) {
                                              audioPlayer.pause();
                                              setState(() {
                                                playStart = false;
                                              });
                                            } else {
                                              if (Platform.isAndroid) {
                                                audioPlayer.play(AssetSource(
                                                    '샘플음성-안드로이드'.tr()));
                                              } else {
                                                audioPlayer.play(AssetSource(
                                                    '샘플음성-애플'.tr()));
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
                                            fontSize:
                                                1.8 * SizeConfig.defaultSize!),
                                      ),
                                      Text(
                                        '샘플음성-길이'.tr(),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize:
                                                1.8 * SizeConfig.defaultSize!),
                                      ),
                                    ]),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: LinearPercentIndicator(
                                      width: SizeConfig.defaultSize! * 18,
                                      animation: false,
                                      lineHeight: SizeConfig.defaultSize! * 0.6,
                                      barRadius: Radius.circular(15),
                                      percent: progress,
                                      progressColor:
                                          Color.fromARGB(255, 255, 169, 26),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 3 * SizeConfig.defaultSize!,
                            ),
                            Container(
                              padding: EdgeInsets.only(
                                  //       top: 5 * SizeConfig.defaultSize!,
                                  //       bottom: 6 * SizeConfig.defaultSize!,
                                  left: 1 * SizeConfig.defaultSize!,
                                  right: 1 * SizeConfig.defaultSize!),
                              width: 35 * sizec,
                              height: 45 * sizec,
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 1, color: Color(0xFFDDDDDD)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "녹음대본".tr(),
                                style: TextStyle(
                                    color: black,
                                    fontFamily: 'Suit',
                                    fontWeight: FontWeight.w400,
                                    fontSize: SizeConfig.defaultSize! * 2),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ])),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
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
                                ),
                              ),
                            );
                          },
                          child: Container(
                              width: 35 * SizeConfig.defaultSize!,
                              height: 5.8 * SizeConfig.defaultSize!,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      1.4 * SizeConfig.defaultSize!),
                                  color: orangeDark),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '녹음안내-이동버튼2'.tr(),
                                    style: TextStyle(
                                      color: white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: SizeConfig.defaultSize! * 2,
                                      fontFamily: 'Suit',
                                    ),
                                  ),
                                ],
                              )),
                        ),
                        SizedBox(
                          height: 2 * sizec,
                        )
                      ],
                    ),
                  ),
                ]))));
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
