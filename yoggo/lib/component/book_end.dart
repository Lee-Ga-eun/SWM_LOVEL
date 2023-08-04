import 'package:amplitude_flutter/amplitude.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yoggo/component/globalCubit/user/user_state.dart';
import 'package:yoggo/component/home/view/home.dart';
import 'package:yoggo/component/book_page.dart';
import 'package:yoggo/component/rec_info.dart';
import 'package:yoggo/size_config.dart';
import 'package:yoggo/component/sub.dart';

import 'globalCubit/user/user_cubit.dart';

class BookEnd extends StatefulWidget {
  final int voiceId; //detail_screen에서 받아오는 것들
  final int contentVoiceId; //detail_screen에서 받아오는 것들
  final int contentId; //detail_screen에서 받아오는 것들
  final bool isSelected;
  final int lastPage;
  BookEnd({
    super.key,
    required this.voiceId, // detail_screen에서 받아오는 것들 초기화
    required this.contentVoiceId, // detail_screen에서 받아오는 것들 초기화
    required this.contentId, // detail_screen에서 받아오는 것들 초기화
    required this.isSelected,
    required this.lastPage,
  });

  @override
  _BookEndState createState() => _BookEndState();
}

class _BookEndState extends State<BookEnd> {
  @override
  void initState() {
    super.initState();
    // TODO: Add initialization code
  }

  @override
  void dispose() {
    // TODO: Add cleanup code
    super.dispose();
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Amplitude amplitude = Amplitude.getInstance(instanceName: "SayIT");

  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    SizeConfig().init(context);
    _sendBookEndViewEvent(userState.userId, widget.contentVoiceId,
        widget.contentId, widget.voiceId, userState.purchase, userState.record);
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
              flex: SizeConfig.defaultSize!.toInt(),
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
                flex: SizeConfig.defaultSize!.toInt(),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                    padding:
                        EdgeInsets.only(bottom: SizeConfig.defaultSize! * 4),
                    onPressed: () {
                      _sendBookAgainClickEvent(
                          userState.userId,
                          widget.contentVoiceId,
                          widget.contentId,
                          widget.voiceId,
                          userState.purchase,
                          userState.record);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookPage(
                            // 다음 화면으로 contetnVoiceId를 가지고 이동
                            contentId: widget.contentId,
                            contentVoiceId: widget.contentVoiceId,
                            voiceId: widget.voiceId,
                            lastPage: widget.lastPage,
                            isSelected: widget.isSelected,
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
                    padding:
                        EdgeInsets.only(bottom: SizeConfig.defaultSize! * 4),
                    onPressed: () {
                      _sendBookHomeClickEvent(
                          userState.userId,
                          widget.contentVoiceId,
                          widget.contentId,
                          widget.voiceId,
                          userState.purchase,
                          userState.record);
                      Navigator.of(context).popUntil((route) => route.isFirst);

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
                ]))
          ],
        ),
      ),
    );
  }

  Expanded allPass() {
    return Expanded(
        flex: SizeConfig.defaultSize!.toInt() * 3,
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
                    'Congratulations on \n completing the READING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Molengo',
                        fontSize: SizeConfig.defaultSize! * 2.5),
                  ),
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
      flex: SizeConfig.defaultSize!.toInt() * 3,
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
                    'Congratulations on \n completing the READING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Molengo',
                        fontSize: SizeConfig.defaultSize! * 2.5),
                  ),
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
                          'If you want to read a book in the voice of your parents,',
                          style: TextStyle(
                              fontFamily: 'Molengo',
                              fontSize: SizeConfig.defaultSize! * 2.3),
                        ),
                        SizedBox(
                          height: SizeConfig.defaultSize! * 1.5,
                        ),
                        InkWell(
                          onTap: () {
                            _sendBookEndSubClick(
                                userId,
                                widget.contentVoiceId,
                                widget.contentId,
                                widget.voiceId,
                                purchase,
                                record);
                            Navigator.push(
                              context,
                              //결제가 끝나면 RecInfo로 가야 함
                              MaterialPageRoute(
                                builder: (context) => const Purchase(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA91A),
                              borderRadius: BorderRadius.all(Radius.circular(
                                  SizeConfig.defaultSize! * 0.9)),
                            ),
                            width: SizeConfig.defaultSize! * 24,
                            height: 4.5 * SizeConfig.defaultSize!,
                            child: Center(
                              //Padding(
                              //   padding: EdgeInsets.only(
                              //     left: SizeConfig.defaultSize! * 5,
                              //     right: SizeConfig.defaultSize! * 5,
                              //     top: SizeConfig.defaultSize! * 0.5,
                              //     bottom: SizeConchild: fig.defaultSize! * 0.5,
                              //   ),
                              child: Text(
                                'Go to Record',
                                style: TextStyle(
                                  fontFamily: 'Molengo',
                                  fontSize: SizeConfig.defaultSize! * 2.3,
                                  color: Colors.black,
                                ),
                              ),
                            ),
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
      flex: SizeConfig.defaultSize!.toInt() * 3,
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
                    'Congratulations on \n completing the READING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Molengo',
                        fontSize: SizeConfig.defaultSize! * 2.5),
                  ),
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
                          'If you want to read a Book in the voice of your parents,',
                          style: TextStyle(
                              fontFamily: 'Molengo',
                              fontSize: SizeConfig.defaultSize! * 2.3),
                        ),
                        SizedBox(
                          height: SizeConfig.defaultSize! * 1.5,
                        ),
                        InkWell(
                          onTap: () {
                            _sendBookEndSubClick(
                                userId,
                                widget.contentVoiceId,
                                widget.contentId,
                                widget.voiceId,
                                purchase,
                                record);
                            Navigator.push(
                              context,
                              //결제가 끝나면 RecInfo로 가야 함
                              MaterialPageRoute(
                                builder: (context) => const RecInfo(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA91A),
                              borderRadius: BorderRadius.all(Radius.circular(
                                  SizeConfig.defaultSize! * 0.9)),
                            ),
                            width: SizeConfig.defaultSize! * 24,
                            height: 4.5 * SizeConfig.defaultSize!,
                            child: Center(
                              //Padding(
                              //   padding: EdgeInsets.only(
                              //     left: SizeConfig.defaultSize! * 5,
                              //     right: SizeConfig.defaultSize! * 5,
                              //     top: SizeConfig.defaultSize! * 0.5,
                              //     bottom: SizeConchild: fig.defaultSize! * 0.5,
                              //   ),
                              child: Text(
                                'Go to Record',
                                style: TextStyle(
                                  fontFamily: 'Molengo',
                                  fontSize: SizeConfig.defaultSize! * 2.3,
                                  color: Colors.black,
                                ),
                              ),
                            ),
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
      userId, contentVoiceId, contentId, voiceId, purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_end_view',
        parameters: <String, dynamic>{
          'userId': userId,
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
      amplitude.logEvent('book_end_view', eventProperties: {
        'userId': userId,
        'contentVoiceId': contentVoiceId,
        'contentId': contentId,
        'voiceId': voiceId,
        'purchase': purchase ? 'true' : 'false',
        'record': record ? 'true' : 'false',
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookEndSubClick(
      userId, contentVoiceId, contentId, voiceId, purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_end_sub_click',
        parameters: <String, dynamic>{
          'userId': userId,
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
      amplitude.logEvent('book_end_sub_click', eventProperties: {
        'userId': userId,
        'contentVoiceId': contentVoiceId,
        'contentId': contentId,
        'voiceId': voiceId,
        'purchase': purchase ? 'true' : 'false',
        'record': record ? 'true' : 'false',
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookAgainClickEvent(
      userId, contentVoiceId, contentId, voiceId, purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_again_click',
        parameters: <String, dynamic>{
          'userId': userId,
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
      amplitude.logEvent('book_again_click', eventProperties: {
        'userId': userId,
        'contentVoiceId': contentVoiceId,
        'contentId': contentId,
        'voiceId': voiceId,
        'purchase': purchase ? 'true' : 'false',
        'record': record ? 'true' : 'false',
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookHomeClickEvent(
      userId, contentVoiceId, contentId, voiceId, purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_home_click',
        parameters: <String, dynamic>{
          'userId': userId,
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
      amplitude.logEvent('book_home_click', eventProperties: {
        'userId': userId,
        'contentVoiceId': contentVoiceId,
        'contentId': contentId,
        'voiceId': voiceId,
        'purchase': purchase ? 'true' : 'false',
        'record': record ? 'true' : 'false',
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }
}