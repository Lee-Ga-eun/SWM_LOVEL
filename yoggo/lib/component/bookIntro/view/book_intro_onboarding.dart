import 'package:amplitude_flutter/amplitude.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/bookIntro/viewModel/book_voice_cubit.dart';
import 'package:yoggo/component/bookIntro/viewModel/book_voice_model.dart';
import 'package:yoggo/component/home/viewModel/home_screen_cubit.dart';
import 'package:yoggo/component/shop.dart';
import 'package:yoggo/component/rec_info_1.dart';
import '../../../Repositories/Repository.dart';
import '../../bookPage/view/book_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yoggo/size_config.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../globalCubit/user/user_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../shop.dart';
import '../viewModel/book_intro_model.dart';
import '../viewModel/book_intro_cubit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io' show File, Platform;
import 'dart:math';

class BookIntroOnboarding extends StatefulWidget {
  final String title;
  final int id;
  final AudioPlayer bgmPlayer;
  final bool showOnboarding;

  const BookIntroOnboarding({
    // super.key,
    Key? key,
    required this.title,
    required this.id,
    required this.showOnboarding,
    required this.bgmPlayer,
  }) : super(key: key);

  @override
  _BookIntroOnboardingState createState() => _BookIntroOnboardingState();
}

class _BookIntroOnboardingState extends State<BookIntroOnboarding> {
  bool isSelected = true;
  //static bool isClicked = false;
  //static bool isClicked0 = true;
  // ValueNotifier<bool> isClicked = ValueNotifier<bool>(false);
  // ValueNotifier<bool> isClicked0 = ValueNotifier<bool>(true);
  // ValueNotifier<bool> isClicked1 = ValueNotifier<bool>(false);
  // ValueNotifier<bool> isClicked2 = ValueNotifier<bool>(false);
  ValueNotifier<bool> canChanged = ValueNotifier<bool>(true);
  ValueNotifier<bool> wantInference = ValueNotifier<bool>(false);
  ValueNotifier<bool> wantRecord = ValueNotifier<bool>(false);

  //static bool isClicked1 = false;
  //static bool isClicked2 = false;
  bool isPurchased = false;
  bool isLoading = false;
  bool wantPurchase = false;
  bool wantBuyBook = false;
  bool buyPoints = false;
  bool animation = false;
  String lackingPoint = '';
  // bool wantRecord = false;
  //bool wantInference = false;
  bool completeInference = true;
  //late String voiceIcon = "😃";
  //late String voiceName = "";
  static int inferenceId = 0;
  late String token;
  String text = '';
  //int contentVoiceId = 10;
  //String voices='';
  // List<dynamic> voices = [];
  //int cvi = 21; // 여기를 성우의 디폴트 값을 넣어줘야 함
  //int vi = 0;
  //bool canChanged = true;
  // int lastPage = 0;
  final audioPlayer = AudioPlayer();
  //late BookVoiceModel clickedVoice;

  @override
  void dispose() {
    // isClicked.dispose();
    // isClicked0.dispose();
    // isClicked1.dispose();
    // isClicked2.dispose();
    wantInference.dispose();
    wantRecord.dispose();
    canChanged.dispose();
    super.dispose();
  }

  Future<void> fetchPageData() async {
    await dotenv.load(fileName: ".env");

    final url = '${dotenv.get("API_SERVER")}content/v2/${widget.id}';
    final response = await http.get(Uri.parse(url));
    if (mounted) {
      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);
        // print(responseData);
        Map<String, dynamic> data = responseData[0];
        // voices = data['voice'];
        // for (var voice in voices) {
        //   if (voice['voiceId'] == 1) {
        //     cvi = voice['contentVoiceId'];
        //     vi = 1;
        //   }
        // }
        final contentText = data['voice'][0]['voiceName'];
        //  lastPage = data['last'];
        //  contentId = data['contentId'];

        setState(() {
          text = contentText;
          // contentVoiceId = data['voice'][0]['contentVoiceId'];
        });
      } else {}
    }
  }

  BookVoiceModel? clickedVoice;

  late int contentId;
  //late BookVoiceCubit bookVoiceCubit;
  @override
  void initState() {
    super.initState();
    UserCubit().fetchUser();

    //  cvi = 0;
    contentId = widget.id;
    //bookVoiceCubit.loadBookVoiceData(contentId);
    // contentId = widget.id; // contentId는 init에서
    // fetchPageData();
    getToken();
    _sendBookIntroInOnboardingViewEvent(contentId, widget.title);
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Amplitude amplitude = Amplitude.getInstance();
  // static Analytics_config.analytics.logEvent("suhwanc");

  Future<void> _sendBookMyVoiceInOnboardingClickEvent(contentId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_my_voice_in_onboarding_click',
        parameters: <String, dynamic>{'contentId': contentId, 'title': title},
      );
      amplitude.logEvent(
        'book_my_voice_in_onboarding_click',
        eventProperties: {'contentId': contentId, 'title': title},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookVoiceInOnboardingClickEvent(
      contentVoiceId, contentId, title, voiceId) async {
    try {
      // 이벤트 로깅
      print('book voice click: $contentVoiceId, $voiceId');
      await analytics.logEvent(
        name: 'book_voice_in_onboarding_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId,
        },
      );

      await amplitude.logEvent(
        'book_voice_in_onboarding_click',
        eventProperties: {
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroInOnboardingViewEvent(
    contentId,
    title,
  ) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_in_onboarding_view',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_in_onboarding_view',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroXInOnboardingClickEvent(
    contentId,
    title,
  ) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_x_in_onboarding_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_x_in_onboarding_click',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      //token = prefs.getString('token')!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = (MediaQuery.of(context).size.width -
        MediaQuery.of(context).padding.left -
        MediaQuery.of(context).padding.right);
    final sh = (MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom);
    double thumbSize = min(0.7 * sh, 0.4 * sw);
    final bookIntroCubit = context.watch<BookIntroCubit>();

    bookIntroCubit.loadBookIntroData(widget.id);
    return BlocBuilder<BookIntroCubit, List<BookIntroModel>>(
        builder: (context, bookIntro) {
      final userCubit = context.watch<UserCubit>();
      final userState = userCubit.state;
      SizeConfig().init(context);

      return Scaffold(
          backgroundColor: const Color(0xFFF1ECC9).withOpacity(1),
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    opacity: 0.6,
                    image: AssetImage('lib/images/bkground.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    // left: 0.5 * SizeConfig.defaultSize!,
                    top: SizeConfig.defaultSize!,
                  ),
                  child: SafeArea(
                    bottom: false,
                    top: false,
                    minimum: EdgeInsets.only(
                        top: SizeConfig.defaultSize!,
                        right: 3 * SizeConfig.defaultSize!,
                        left: 3 * SizeConfig.defaultSize!),
                    child: Column(children: [
                      Expanded(
                          // HEADER
                          flex: 11,
                          child: Row(children: [
                            Expanded(
                                flex: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.all(
                                            0.2 * SizeConfig.defaultSize!),
                                        icon: Icon(Icons.clear,
                                            color: Colors.grey,
                                            size: 3 * SizeConfig.defaultSize!),
                                        onPressed: () async {
                                          _sendBookIntroXInOnboardingClickEvent(
                                              widget.id,
                                              'The Sun and the Wind');
                                          audioPlayer.stop();
                                          SharedPreferences prefs =
                                              await SharedPreferences
                                                  .getInstance();
                                          bool playingBgm =
                                              prefs.getBool('playingBgm') ??
                                                  true;
                                          if (playingBgm) {
                                            widget.bgmPlayer.resume();
                                          }
                                          Navigator.popUntil(context,
                                              (route) => route.isFirst);
                                        },
                                      )
                                    ])),
                            Expanded(
                                flex: 11,
                                child: Container(
                                  alignment: Alignment.center,
                                  //color: Colors.black12,
                                  child: Text(
                                    'The Sun and the Wind',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 3.2 * SizeConfig.defaultSize!,
                                        fontFamily: 'EmilysCandy',
                                        fontWeight: FontWeight.w200),
                                  ),
                                )),
                            Expanded(flex: 1, child: Container())
                          ])),
                      Expanded(
                          // BODY
                          flex: 70,
                          child: Row(children: [
                            Expanded(
                              // 썸네일 사진
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    color: const Color.fromARGB(0, 0, 0, 0),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                          begin: 30 * SizeConfig.defaultSize!,
                                          end: 30 * SizeConfig.defaultSize!),
                                      duration:
                                          const Duration(milliseconds: 300),
                                      builder: (context, value, child) {
                                        return Stack(children: [
                                          Container(
                                            width: thumbSize,
                                            // height: thumbSize,
                                            clipBehavior: Clip.hardEdge,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: child,
                                          ),
                                          Positioned(
                                            left: SizeConfig.defaultSize!,
                                            top: SizeConfig.defaultSize!,
                                            child: Container(
                                              width:
                                                  6.2 * SizeConfig.defaultSize!,
                                              height:
                                                  3.5 * SizeConfig.defaultSize!,
                                              //clipBehavior: Clip.hardEdge,
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    128, 255, 255, 255),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Center(
                                                  child: Text('3 p',
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontFamily:
                                                              'GenBkBasR',
                                                          fontSize: 2 *
                                                              SizeConfig
                                                                  .defaultSize!))),
                                            ),
                                          )
                                        ]);
                                      },
                                      child: Image.asset('lib/images/10-0.png',
                                          colorBlendMode: BlendMode.srcATop,
                                          color: const Color.fromARGB(
                                              153, 255, 255, 255)),
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.defaultSize! * 3),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: SizeConfig.defaultSize! * 2,
                            ),
                            Expanded(
                                // 제목, 성우, 요약
                                flex: 3,
                                child: Container(
                                    height:
                                        thumbSize + SizeConfig.defaultSize! * 3,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Text(
                                          //   title,
                                          //   style: TextStyle(
                                          //       fontSize: 3.2 * SizeConfig.defaultSize!,
                                          //       fontFamily: 'BreeSerif'),
                                          // ),
                                          // SizedBox(
                                          //   height: SizeConfig.defaultSize! * 2,
                                          // ),
                                          SizedBox(
                                            height: userState.purchase
                                                ? 1 * SizeConfig.defaultSize!
                                                : 1.5 * SizeConfig.defaultSize!,
                                          ),
                                          Column(
                                            children: [
                                              Container(
                                                  width:
                                                      SizeConfig.defaultSize! *
                                                          34,
                                                  padding: EdgeInsets.only(
                                                      left: SizeConfig
                                                              .defaultSize! *
                                                          1.2,
                                                      top: SizeConfig
                                                          .defaultSize!,
                                                      bottom: SizeConfig
                                                          .defaultSize!),
                                                  // color: Colors.red,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.4),
                                                    borderRadius: BorderRadius
                                                        .circular(SizeConfig
                                                                .defaultSize! *
                                                            3),
                                                  ),
                                                  child: Row(
                                                    //  mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      GestureDetector(
                                                          // purchase & record
                                                          // no start Inference
                                                          onTap: () {
                                                            // bookVoiceCubit
                                                            //     .changeBookVoiceData(contentId);
                                                            _sendBookMyVoiceInOnboardingClickEvent(
                                                              contentId,
                                                              "The Sun and the Wind",
                                                            );
                                                            Navigator
                                                                .pushReplacement(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          RecInfo(
                                                                            contentId:
                                                                                10,
                                                                            bgmPlayer:
                                                                                widget.bgmPlayer,
                                                                          )),
                                                            );
                                                          },
                                                          child: Column(
                                                              children: [
                                                                Padding(
                                                                    padding: EdgeInsets.only(
                                                                        right: 0 *
                                                                            SizeConfig
                                                                                .defaultSize!),
                                                                    child: Image
                                                                        .asset(
                                                                      'lib/images/icons/grinning-face-c.png',
                                                                      height:
                                                                          SizeConfig.defaultSize! *
                                                                              7,
                                                                    )),
                                                                SizedBox(
                                                                    height: SizeConfig
                                                                            .defaultSize! *
                                                                        0.3),
                                                                Text('My Voice',
                                                                    style: TextStyle(
                                                                        fontFamily: 'GenBkBasR',
                                                                        fontWeight: FontWeight.bold,
                                                                        //     FontWeight.w800,
                                                                        fontSize: 1.8 * SizeConfig.defaultSize!))
                                                              ])),
                                                      SizedBox(
                                                        // color: ,
                                                        width: 1.5 *
                                                            SizeConfig
                                                                .defaultSize!,
                                                      ),
                                                      GestureDetector(
                                                        //Jolly
                                                        onTap: () async {},
                                                        child:
                                                            //   ValueListenableBuilder<
                                                            //       bool>(
                                                            // valueListenable:
                                                            //     isClicked0,
                                                            // builder: (context,
                                                            //     value, child) {
                                                            //   return
                                                            Center(
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .only(
                                                                  right: 0 *
                                                                      SizeConfig
                                                                          .defaultSize!,
                                                                ),
                                                                child:
                                                                    Image.asset(
                                                                  'lib/images/emma.png',
                                                                  height: SizeConfig
                                                                          .defaultSize! *
                                                                      6.5,
                                                                  colorBlendMode:
                                                                      BlendMode
                                                                          .srcATop,
                                                                  color: const Color
                                                                      .fromARGB(
                                                                      150,
                                                                      255,
                                                                      255,
                                                                      255),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: SizeConfig
                                                                        .defaultSize! *
                                                                    0.3,
                                                              ),
                                                              Text(
                                                                'Emma',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontFamily:
                                                                        'GenBkBasR',
                                                                    fontSize: 1.8 *
                                                                        SizeConfig
                                                                            .defaultSize!,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal),
                                                              ),
                                                            ],
                                                          ),
                                                          //);
                                                          //},
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 1.5 *
                                                            SizeConfig
                                                                .defaultSize!,
                                                      ),
                                                      // Morgan
                                                      GestureDetector(
                                                        onTap: () async {},
                                                        child: Center(
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .only(
                                                                  right: 0 *
                                                                      SizeConfig
                                                                          .defaultSize!,
                                                                ),
                                                                child:
                                                                    Image.asset(
                                                                  'lib/images/sophia.png',
                                                                  height: SizeConfig
                                                                          .defaultSize! *
                                                                      6.5,
                                                                  colorBlendMode:
                                                                      BlendMode
                                                                          .srcATop,
                                                                  color: const Color
                                                                      .fromARGB(
                                                                      150,
                                                                      255,
                                                                      255,
                                                                      255),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: SizeConfig
                                                                        .defaultSize! *
                                                                    0.3,
                                                              ),
                                                              Text(
                                                                'Sophia',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontFamily:
                                                                      'GenBkBasR',
                                                                  fontSize: 1.8 *
                                                                      SizeConfig
                                                                          .defaultSize!,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          //);
                                                          //},
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 1.5 *
                                                            SizeConfig
                                                                .defaultSize!,
                                                      ),
                                                      // Eric
                                                      GestureDetector(
                                                          onTap: () async {},
                                                          child: Center(
                                                            child: Column(
                                                              children: [
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .only(
                                                                    right: 0 *
                                                                        SizeConfig
                                                                            .defaultSize!,
                                                                  ),
                                                                  child: Image
                                                                      .asset(
                                                                    'lib/images/james.png',
                                                                    height:
                                                                        SizeConfig.defaultSize! *
                                                                            6.5,
                                                                    colorBlendMode:
                                                                        BlendMode
                                                                            .srcATop,
                                                                    color: const Color
                                                                        .fromARGB(
                                                                        150,
                                                                        255,
                                                                        255,
                                                                        255),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: SizeConfig
                                                                          .defaultSize! *
                                                                      0.3,
                                                                ),
                                                                Text(
                                                                  'James',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontFamily:
                                                                        'GenBkBasR',
                                                                    fontSize: 1.8 *
                                                                        SizeConfig
                                                                            .defaultSize!,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                          //},
                                                          //),
                                                          ),
                                                    ],
                                                  ) //;
                                                  // }),
                                                  ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: 1.5 *
                                                  SizeConfig
                                                      .defaultSize! //userState.purchase
                                              //? 4
                                              //: 4 * SizeConfig.defaultSize!,
                                              ),
                                          Expanded(
                                              flex: 3,
                                              child: Scrollbar(
                                                thumbVisibility: true,
                                                trackVisibility: true,
                                                child: ListView(children: [
                                                  Padding(
                                                    // Summary
                                                    padding: EdgeInsets.only(
                                                      right: 1 *
                                                          SizeConfig
                                                              .defaultSize!,
                                                      top: 0 *
                                                          SizeConfig
                                                              .defaultSize!,
                                                    ),
                                                    child: Text(
                                                      "Learn a wonderful lesson with 'The Sun and the Wind'! See how the Sun and the Wind teach us that being gentle and kind is the coolest way to succeed!",
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontFamily:
                                                              'font-book'.tr(),
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: SizeConfig
                                                                  .defaultSize! *
                                                              2.1),
                                                    ),
                                                  ),
                                                ]),
                                              )),
                                          SizedBox(
                                            height:
                                                SizeConfig.defaultSize! * 1.5,
                                          ),
                                          Expanded(
                                              flex: 2,
                                              child: Stack(children: [
                                                // 다른 위젯들...
                                                Align(
                                                    alignment:
                                                        Alignment.topCenter,
                                                    // right: SizeConfig.defaultSize! * 12,
                                                    // top: SizeConfig.defaultSize! * 1.4,
                                                    child: GestureDetector(
                                                        onTap: () async {},
                                                        child: Container(
                                                            width: 31.1 *
                                                                SizeConfig
                                                                    .defaultSize!,
                                                            height: 4.5 *
                                                                SizeConfig
                                                                    .defaultSize!,
                                                            decoration:
                                                                ShapeDecoration(
                                                              color: const Color
                                                                  .fromARGB(50,
                                                                  255, 169, 26),
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            30),
                                                              ),
                                                            ),
                                                            child: Stack(
                                                                children: [
                                                                  Positioned(
                                                                      right: 1 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      top: 0.75 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .chevron_right,
                                                                        color: Colors
                                                                            .grey,
                                                                        size: SizeConfig.defaultSize! *
                                                                            3,
                                                                      )),
                                                                  Center(
                                                                    child: Text(
                                                                      '책-시작',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .grey,
                                                                          fontSize: 2.3 *
                                                                              SizeConfig.defaultSize! *
                                                                              double.parse('font-ratio'.tr()),
                                                                          fontFamily: 'font-button'.tr()),
                                                                    ).tr(),
                                                                  ),
                                                                ]))))
                                              ]))
                                        ])))
                          ])),
                    ]),
                  ),
                ),
              ),
              Positioned(
                left: SizeConfig.defaultSize! * 52,
                top: SizeConfig.defaultSize! * 19,
                child: Image.asset(
                  'lib/images/finger.png',
                  width: SizeConfig.defaultSize! * 10,
                ),
              ),
            ],
          ));
    }); //);
  }
}
