import 'dart:ffi';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/globalCubit/user/user_state.dart';
import 'package:yoggo/component/home/view/home.dart';
import 'package:yoggo/component/bookPage/view/book_page.dart';
import 'package:yoggo/component/rec_info_1.dart';
import 'package:yoggo/size_config.dart';
// import 'package:yoggo/component/shop.dart';
import 'package:yoggo/component/shop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'globalCubit/user/user_cubit.dart';

class BookEnd extends StatefulWidget {
  final int voiceId; //detail_screen에서 받아오는 것들
  final int contentVoiceId; //detail_screen에서 받아오는 것들
  final int contentId; //detail_screen에서 받아오는 것들
  final bool isSelected;
  final int lastPage;
  final String title;
  final AudioPlayer bgmPlayer;

  const BookEnd({
    super.key,
    required this.voiceId, // detail_screen에서 받아오는 것들 초기화
    required this.contentVoiceId, // detail_screen에서 받아오는 것들 초기화
    required this.contentId, // detail_screen에서 받아오는 것들 초기화
    required this.isSelected,
    required this.lastPage,
    required this.title,
    required this.bgmPlayer,
  });

  @override
  _BookEndState createState() => _BookEndState();
}

class _BookEndState extends State<BookEnd> {
  @override
  void initState() {
    super.initState();
    requestReview();
    _sendBookEndViewEvent(
        widget.contentVoiceId, widget.contentId, widget.voiceId, widget.title);
    // TODO: Add initialization code
  }

  @override
  void dispose() {
    // TODO: Add cleanup code
    super.dispose();
  }

  void requestReview() async {
    Future.delayed(const Duration(seconds: 1), () async {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    });
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Amplitude amplitude = Amplitude.getInstance();

  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    SizeConfig().init(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/bkground.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: SizeConfig.defaultSize!,
            ),
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Row(
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
                  SizedBox(
                    height: SizeConfig.defaultSize! * 2,
                  ),
                ],
              ),
            ),
            userState.purchase != null
                ? (userState.purchase == true && userState.record == false
                    ? notRecordUser(userState.userId, userState.purchase,
                        userState.record, widget.voiceId)
                    : userState.purchase == true && userState.record == true
                        ? allPass()
                        : notPurchaseUser(userState.userId, userState.purchase,
                            userState.record, widget.voiceId))
                : Container(),
            Expanded(
                flex: 4,
                child: Column(
                  children: [
                    SizedBox(
                      height: SizeConfig.defaultSize! * 0.5,
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(
                        padding: EdgeInsets.all(0.2 * SizeConfig.defaultSize!),
                        onPressed: () {
                          _sendBookAgainClickEvent(widget.contentVoiceId,
                              widget.contentId, widget.voiceId, widget.title);
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookPage(
                                // 다음 화면으로 contetnVoiceId를 가지고 이동
                                contentId: widget.contentId,
                                contentVoiceId: widget.contentVoiceId,
                                voiceId: widget.voiceId,
                                lastPage: widget.lastPage,
                                isSelected: widget.isSelected,
                                title: widget.title,
                                bgmPlayer: widget.bgmPlayer,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.replay,
                          size: SizeConfig.defaultSize! * 4,
                        ),
                      ),
                      SizedBox(
                        width: SizeConfig.defaultSize! * 2,
                      ),
                      IconButton(
                        padding: EdgeInsets.all(0.2 * SizeConfig.defaultSize!),
                        onPressed: () async {
                          _sendBookHomeClickEvent(widget.contentVoiceId,
                              widget.contentId, widget.voiceId, widget.title);
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          bool playingBgm = prefs.getBool('playingBgm') ?? true;
                          if (playingBgm) {
                            widget.bgmPlayer.resume();
                          }

                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);

                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const HomeScreen(),
                          //   ),
                          // );
                        },
                        icon: Icon(
                          Icons.home,
                          size: SizeConfig.defaultSize! * 4,
                        ),
                      ),
                    ]),
                    SizedBox(
                      height: 3.5 * SizeConfig.defaultSize!,
                    )
                  ],
                ))
          ],
        ),
      ),
    );
  }

  Expanded allPass() {
    return Expanded(
        flex: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/images/congratulate2.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  ),
                  SizedBox(
                    width: SizeConfig.defaultSize! * 1.5,
                  ),
                  Text(
                    '완독-축하',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'font-basic'.tr(),
                        fontSize: SizeConfig.defaultSize! * 2.5),
                  ).tr(),
                  SizedBox(
                    width: SizeConfig.defaultSize! * 2,
                  ),
                  Image.asset(
                    'lib/images/congratulate1.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  )
                ],
              ),
            ],
          ),
        ));
  }

  Expanded notPurchaseUser(userId, purchase, record, cvi) {
    // 구매를 안 한 사용자
    return Expanded(
      flex: 10,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/images/congratulate2.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  ),
                  SizedBox(
                    width: SizeConfig.defaultSize! * 1.5,
                  ),
                  Text(
                    '완독-축하',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'font-basic'.tr(),
                        fontSize: SizeConfig.defaultSize! * 2.5),
                  ).tr(),
                  SizedBox(
                    width: SizeConfig.defaultSize! * 2,
                  ),
                  Image.asset(
                    'lib/images/congratulate1.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  )
                ],
              ),
              SizedBox(
                height: SizeConfig.defaultSize! * 3,
              ),
              Padding(
                padding: const EdgeInsets.only(),
                child: Container(
                  // color: Colors.yellow,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(100, 255, 255, 255),
                    borderRadius: BorderRadius.all(
                        Radius.circular(SizeConfig.defaultSize! * 2)

                        // border: Border.all(
                        //   color: const Color.fromARGB(
                        //       152, 97, 1, 152), // Border의 색상을 지정합니다.
                        //   width:
                        //       SizeConfig.defaultSize! * 0.3, // Border의 두께를 지정합니다.
                        ),
                  ),
                  height: SizeConfig.defaultSize! * 13.2,
                  width: SizeConfig.defaultSize! * 66.9,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: SizeConfig.defaultSize! * 3,
                      right: SizeConfig.defaultSize! * 3,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '완독-목소리',
                          style: TextStyle(
                              fontFamily: 'font-basic'.tr(),
                              fontSize: SizeConfig.defaultSize! * 2.3),
                        ).tr(),
                        SizedBox(
                          height: SizeConfig.defaultSize! * 1.5,
                        ),
                        InkWell(
                          onTap: () {
                            _sendBookEndSubClick(widget.contentVoiceId,
                                widget.contentId, widget.voiceId, widget.title);
                            Navigator.push(
                              context,
                              //결제가 끝나면 RecInfo로 가야 함
                              MaterialPageRoute(
                                builder: (context) => Purchase(
                                  bgmPlayer: widget.bgmPlayer,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA91A),
                              borderRadius: BorderRadius.all(
                                  Radius.circular(SizeConfig.defaultSize! * 3)),
                            ),
                            width: SizeConfig.defaultSize! * 24,
                            height: 4.5 * SizeConfig.defaultSize!,
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
                                //Padding(
                                //   padding: EdgeInsets.only(
                                //     left: SizeConfig.defaultSize! * 5,
                                //     right: SizeConfig.defaultSize! * 5,
                                //     top: SizeConfig.defaultSize! * 0.5,
                                //     bottom: SizeConchild: fig.defaultSize! * 0.5,
                                //   ),
                                child: Text(
                                  '완독-녹음',
                                  style: TextStyle(
                                    fontFamily: 'font-basic'.tr(),
                                    fontSize: SizeConfig.defaultSize! * 2.3,
                                    color: Colors.black,
                                  ),
                                ).tr(),
                              ),
                            ]),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }

  Expanded notRecordUser(userId, purchase, record, cvi) {
    // 녹음을 안 한 사용자
    return Expanded(
      flex: 10,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/images/congratulate2.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  ),
                  SizedBox(
                    width: SizeConfig.defaultSize! * 1.5,
                  ),
                  Text(
                    '완독-축하',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'font-basic'.tr(),
                        fontSize: SizeConfig.defaultSize! * 2.5),
                  ).tr(),
                  SizedBox(
                    width: SizeConfig.defaultSize! * 2,
                  ),
                  Image.asset(
                    'lib/images/congratulate1.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  )
                ],
              ),
              SizedBox(
                height: SizeConfig.defaultSize! * 3,
              ),
              Padding(
                padding: const EdgeInsets.only(),
                child: Container(
                  // color: Colors.yellow,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(100, 255, 255, 255),
                    borderRadius: BorderRadius.all(
                        Radius.circular(SizeConfig.defaultSize! * 2)

                        // border: Border.all(
                        //   color: const Color.fromARGB(
                        //       152, 97, 1, 152), // Border의 색상을 지정합니다.
                        //   width:
                        //       SizeConfig.defaultSize! * 0.3, // Border의 두께를 지정합니다.
                        ),
                  ),
                  height: SizeConfig.defaultSize! * 13.2,
                  width: SizeConfig.defaultSize! * 66.9,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: SizeConfig.defaultSize! * 3,
                      right: SizeConfig.defaultSize! * 3,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '완독-목소리',
                          style: TextStyle(
                              fontFamily: 'font-basic'.tr(),
                              fontSize: SizeConfig.defaultSize! * 2.3),
                        ).tr(),
                        SizedBox(
                          height: SizeConfig.defaultSize! * 1.5,
                        ),
                        InkWell(
                          onTap: () {
                            _sendBookEndSubClick(widget.contentVoiceId,
                                widget.contentId, widget.voiceId, widget.title);
                            Navigator.push(
                              context,
                              //결제가 끝나면 RecInfo로 가야 함
                              MaterialPageRoute(
                                builder: (context) => RecInfo(
                                  contentId: widget.contentId,
                                  bgmPlayer: widget.bgmPlayer,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA91A),
                              borderRadius: BorderRadius.all(
                                  Radius.circular(SizeConfig.defaultSize! * 3)),
                            ),
                            width: SizeConfig.defaultSize! * 24,
                            height: 4.5 * SizeConfig.defaultSize!,
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
                                //Padding(
                                //   padding: EdgeInsets.only(
                                //     left: SizeConfig.defaultSize! * 5,
                                //     right: SizeConfig.defaultSize! * 5,
                                //     top: SizeConfig.defaultSize! * 0.5,
                                //     bottom: SizeConchild: fig.defaultSize! * 0.5,
                                //   ),
                                child: Text(
                                  '완독-녹음',
                                  style: TextStyle(
                                    fontFamily: 'font-basic'.tr(),
                                    fontSize: SizeConfig.defaultSize! * 2.3,
                                    color: Colors.black,
                                  ),
                                ).tr(),
                              ),
                            ]),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }

  Future<void> _sendBookEndViewEvent(
      contentVoiceId, contentId, voiceId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_end_view',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'title': title,
        },
      );
      amplitude.logEvent('book_end_view', eventProperties: {
        'contentVoiceId': contentVoiceId,
        'contentId': contentId,
        'voiceId': voiceId,
        'title': title,
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookEndSubClick(
      contentVoiceId, contentId, voiceId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_end_sub_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'title': title,
        },
      );
      amplitude.logEvent('book_end_sub_click', eventProperties: {
        'contentVoiceId': contentVoiceId,
        'contentId': contentId,
        'voiceId': voiceId,
        'title': title,
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookAgainClickEvent(
      contentVoiceId, contentId, voiceId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_again_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'title': title,
        },
      );
      amplitude.logEvent('book_again_click', eventProperties: {
        'contentVoiceId': contentVoiceId,
        'contentId': contentId,
        'voiceId': voiceId,
        'title': title,
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookHomeClickEvent(
      contentVoiceId, contentId, voiceId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_home_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'title': title,
        },
      );
      amplitude.logEvent('book_home_click', eventProperties: {
        'contentVoiceId': contentVoiceId,
        'contentId': contentId,
        'voiceId': voiceId,
        'title': title,
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }
}
