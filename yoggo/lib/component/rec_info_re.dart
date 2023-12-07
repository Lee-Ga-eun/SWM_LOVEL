import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:yoggo/size_config.dart';
import 'globalCubit/user/user_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:amplitude_flutter/amplitude.dart';

class RecReInfo extends StatefulWidget {
  const RecReInfo({super.key});

  @override
  _RecInfoState createState() => _RecInfoState();
}

String mypath = '';

class _RecInfoState extends State<RecReInfo> {
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
  @override
  void initState() {
    super.initState();
    _sendRecInfoReViewEvent();
    audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        currentPosition = position;
        progress =
            currentPosition.inMicroseconds / totalDuration.inMicroseconds;
      });
    });

    // TODO: Add initialization code
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
        bottom: true,
        child: Column(
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
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Navigator.push(
                              //   context,
                              //   // 설득 & 광고 페이지로 가야하는데 일단은 홈으로 빠지게 하겠음
                              //   MaterialPageRoute(
                              //     builder: (context) => const HomeScreen(),
                              //   ),
                              // );
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
                      child: Container(color: const Color.fromARGB(0, 0, 0, 0)))
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
                              3 *
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
                                    playStart ? Icons.pause : Icons.play_arrow,
                                    size: SizeConfig.defaultSize! * 3.5),
                                onTap: () async {
                                  if (playStart) {
                                    audioPlayer.pause();
                                    setState(() {
                                      playStart = false;
                                    });
                                  } else {
                                    if (Platform.isAndroid) {
                                      audioPlayer
                                          .play(AssetSource('샘플음성-안드로이드'.tr()));
                                    } else {
                                      audioPlayer
                                          .play(AssetSource('샘플음성-애플'.tr()));
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
                              progressColor: Color.fromARGB(255, 255, 169, 26),
                            ),
                          ],
                        ),
                      ),
                    ])),

            //     Column(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           SizedBox(
            //             height: 2 * SizeConfig.defaultSize!,
            //           ),
            //           Text(
            //             '녹음-안내',
            //             style: TextStyle(
            //               fontSize: SizeConfig.defaultSize! * 2.2,
            //               fontFamily: 'font-basic'.tr(),
            //             ),
            //           ).tr(),
            //           SizedBox(
            //             height: 1.8 * SizeConfig.defaultSize!,
            //           ),
            //           Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               crossAxisAlignment: CrossAxisAlignment.center,
            //               children: [
            //                 Column(
            //                   mainAxisAlignment: MainAxisAlignment.center,
            //                   // crossAxisAlignment: CrossAxisAlignment.center,
            //                   children: [
            //                     const Image(
            //                       image: AssetImage('lib/images/quite.png'),
            //                     ),
            //                     SizedBox(
            //                       height: SizeConfig.defaultSize! * 2,
            //                     ),
            //                     Text(
            //                       "녹음-안내-1",
            //                       style: TextStyle(
            //                           fontSize: SizeConfig.defaultSize! *
            //                               2 *
            //                               double.parse('font-ratio'.tr()),
            //                           fontWeight: FontWeight.w400,
            //                           fontFamily: 'font-basic'.tr()),
            //                       textAlign: TextAlign.center,
            //                     ).tr()
            //                   ],
            //                 ),
            //                 SizedBox(
            //                   width: SizeConfig.defaultSize! * 4,
            //                 ),
            //                 Column(
            //                   children: [
            //                     const Image(
            //                       image: AssetImage('lib/images/speach1.png'),
            //                     ),
            //                     SizedBox(
            //                       height: SizeConfig.defaultSize! * 2,
            //                     ),
            //                     Text(
            //                       "녹음-안내-2",
            //                       style: TextStyle(
            //                         fontSize: SizeConfig.defaultSize! *
            //                             2 *
            //                             double.parse('font-ratio'.tr()),
            //                         fontWeight: FontWeight.w400,
            //                         fontFamily: 'font-basic'.tr(),
            //                       ),
            //                       textAlign: TextAlign.center,
            //                     ).tr()
            //                   ],
            //                 ),
            //                 SizedBox(
            //                   width: SizeConfig.defaultSize! * 4,
            //                 ),
            //                 Column(
            //                   children: [
            //                     const Image(
            //                       image: AssetImage('lib/images/thumbsUp.png'),
            //                     ),
            //                     SizedBox(
            //                       height: SizeConfig.defaultSize! * 2,
            //                     ),
            //                     Text(
            //                       "녹음-안내-3",
            //                       style: TextStyle(
            //                         fontSize: SizeConfig.defaultSize! *
            //                             2 *
            //                             double.parse('font-ratio'.tr()),
            //                         fontWeight: FontWeight.w400,
            //                         fontFamily: 'font-basic'.tr(),
            //                       ),
            //                       textAlign: TextAlign.center,
            //                     ).tr()
            //                   ],
            //                 ),
            //                 SizedBox(
            //                   width: SizeConfig.defaultSize! * 4,
            //                 ),
            //                 Column(
            //                   children: [
            //                     const Image(
            //                       image: AssetImage('lib/images/infinite.png'),
            //                     ),
            //                     SizedBox(
            //                       height: SizeConfig.defaultSize! * 2,
            //                     ),
            //                     Text(
            //                       "녹음-안내-4",
            //                       style: TextStyle(
            //                         fontSize: SizeConfig.defaultSize! *
            //                             2 *
            //                             double.parse('font-ratio'.tr()),
            //                         fontWeight: FontWeight.w400,
            //                         fontFamily: 'font-basic'.tr(),
            //                       ),
            //                       textAlign: TextAlign.center,
            //                     ).tr(),
            //                     // Positioned(
            //                     //     child: IconButton(
            //                     //   padding: EdgeInsets.only(
            //                     //       left: SizeConfig.defaultSize! * 13,
            //                     //       top: SizeConfig.defaultSize! * 2),
            //                     //   icon: Icon(
            //                     //     Icons.arrow_circle_right_outlined,
            //                     //     size: SizeConfig.defaultSize! * 4,
            //                     //     color: Colors.black,
            //                     //   ),
            //                     //   onPressed: () {
            //                     //     Navigator.push(
            //                     //       context,
            //                     //       MaterialPageRoute(
            //                     //         builder: (context) => const Rec(
            //                     //             // 다음 화면으로 contetnVoiceId를 가지고 이동
            //                     //             ),
            //                     //       ),
            //                     //     );
            //                     //   },
            //                     // ))
            //                   ],
            //                 ),
            //               ])
            //         ])),
            Expanded(flex: 2, child: Container())
          ],
        ),
      ),
    ));
  }

  Future<void> _sendRecInfoReViewEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_info_re_view',
        parameters: <String, dynamic>{},
      );

      await amplitude.logEvent(
        'rec_info_re_view',
        eventProperties: {},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }
}
