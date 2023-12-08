import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/rec_info.dart';
import 'package:yoggo/size_config.dart';
import 'globalCubit/user/user_cubit.dart';
import 'package:amplitude_flutter/amplitude.dart';
import 'package:easy_localization/easy_localization.dart';
import '../component/rec.dart';
import 'dart:io' show File, Platform;
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';

class RecInfo extends StatefulWidget {
  final int contentId;
  final AudioPlayer bgmPlayer;

  const RecInfo({super.key, required this.contentId, required this.bgmPlayer});

  @override
  _RecInfoState createState() => _RecInfoState();
}

String mypath = '';

class _RecInfoState extends State<RecInfo> {
  @override
  void initState() {
    super.initState();
    _sendRecInfoViewEvent();
    // TODO: Add initialization code
    //advancedPlayer = new AudioPlayer();
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Amplitude amplitude = Amplitude.getInstance();

  @override
  void dispose() {
    // TODO: Add cleanup code
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          SizedBox(
                            height: 0.5 * SizeConfig.defaultSize!,
                          ),
                          Text(
                            '녹음안내-설명1',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: SizeConfig.defaultSize! *
                                  3 *
                                  double.parse('font-ratio'.tr()),
                              fontFamily: 'font-basic'.tr(),
                            ),
                          ).tr(),
                        ])),
                Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () {
                          // print("TAP");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecInfo2(
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
                                  "녹음안내-이동버튼1",
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
