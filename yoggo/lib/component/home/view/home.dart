import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;

import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/bookIntro/view/book_intro.dart';
import 'package:yoggo/component/bookIntro/view/book_intro_onboarding.dart';
import 'package:yoggo/component/globalCubit/user/user_state.dart';
import 'package:yoggo/component/home/view/ex-home_onboarding.dart';
import 'package:yoggo/component/home/viewModel/home_screen_book_model.dart';
import 'package:yoggo/widgets/navigation_bar.dart';
// import 'package:yoggo/component/sub.dart';
// import 'package:yoggo/component/shop.dart';
import 'package:yoggo/component/shop.dart';

import 'package:yoggo/component/rec_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yoggo/size_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yoggo/widgets/custom_text.dart';
import '../../../Repositories/Repository.dart';
import '../../bookIntro/viewModel/book_intro_cubit.dart';
import '../../bookIntro/viewModel/book_voice_cubit.dart';
import '../../notice/view/notice.dart';
import '../../voice.dart';
import '../viewModel/home_screen_cubit.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../globalCubit/user/user_cubit.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // late Future<List<bookModel>> webtoons;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late String token;
  late int userId;
  bool showEmail = false;
  bool showSignOutConfirmation = false;
  bool wantDelete = false;
  double dropdownHeight = 0.0;
  bool isDataFetched = false;
  late bool playingBgm;
  bool _isChanged = false;
  //bool showSecondOverlay = false; // Initially show the overlay
  //bool showBanner = false;
  //bool showFairy = false;
  bool neverRequestedPermission = false;
  //bool showToolTip = false;
  bool reportClicked = false;
  bool isKeyboardVisible = false;
  String reportContent = '';

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  // }

  AudioPlayer bgmPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    bgmPlayer.setReleaseMode(ReleaseMode.loop);
    WidgetsBinding.instance.addObserver(this);

    getToken();
    _checkFirstTimeAccess(); // 앱 최초 사용 접속 : 온보딩 화면 보여주기

    // _loadAd();
  }

  @override
  void dispose() {
    super.dispose();
    bgmPlayer.pause();
  }

  // void _loadAd() {
  //   RewardedAd.load(
  //       adUnitId: _adUnitId,
  //       request: AdRequest(),
  //       rewardedAdLoadCallback: RewardedAdLoadCallback(
  //         onAdLoaded: (RewardedAd ad) {
  //           print('Ad was loaded.');
  //           _rewardedAd = ad;

  //           // final serverSideVerificationOptions = ServerSideVerificationOptions(
  //           //     customData: 'SAMPLE_CUSTOM_DATA_STRING');
  //           // RewardedAd.setServerSideVerificationOptions(
  //           //     serverSideVerificationOptions);

  //           // ad.fullScreenContentCallback = FullScreenContentCallback(
  //           //   onAdClicked: () {
  //           //     print('Ad was clicked.');
  //           //   },
  //           //   onAdDismissedFullScreenContent: () {
  //           //     print('Ad dismissed fullscreen content.');
  //           //     rewardedAd = null;
  //           //   },
  //           //   onAdFailedToShowFullScreenContent: (AdError error) {
  //           //     print('Ad failed to show fullscreen content: $error');
  //           //     rewardedAd = null;
  //           //   },
  //           //   onAdImpression: () {
  //           //     print('Ad recorded an impression.');
  //           //   },
  //           //   onAdShowedFullScreenContent: () {
  //           //     print('Ad showed fullscreen content.');
  //           //   },
  //           // );
  //         },
  //         onAdFailedToLoad: (LoadAdError error) {
  //           print('Ad failed to load: $error');
  //           _rewardedAd = null;
  //         },
  //       ));
  // }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        // 앱이 일시 중지될 때
        bgmPlayer.pause();
        break;
      case AppLifecycleState.resumed:
        // 앱이 재개될 때
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool playingBgm = prefs.getBool('playingBgm') ?? true;
        if (playingBgm) {
          bgmPlayer.resume();
        }
        break;
      default:
        break;
    }
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Amplitude amplitude = Amplitude.getInstance();

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token')!;
      //userInfo(token);
      //getVoiceInfo(token);
    });
  }

  Future<void> _checkFirstTimeAccess() async {
    // 앱 최초 사용 접속 : 온보딩 화면 보여주기
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    playingBgm = prefs.getBool('playingBgm') ?? true;
    //bool haveClickedBook = prefs.getBool('haveClickedBook') ?? false;
    neverRequestedPermission = true;

    if (isFirstTime) {
      // Set isFirstTime to false after showing overlay
      if (playingBgm) await bgmPlayer.play(AssetSource('sound/Christmas.wav'));

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //       builder: (context) => HomeOnboarding(
      //             bgmPlayer: bgmPlayer,
      //           )),
      // );
      await prefs.setBool('isFirstTime', false);
    } else {
      if (playingBgm) await bgmPlayer.play(AssetSource('sound/Christmas.wav'));
    }
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
            borderRadius: BorderRadius.circular(SizeConfig.defaultSize! * 3),
          ),
          backgroundColor: Colors.white.withOpacity(0.9),
          title: Center(
            child: CustomText(
              '앱종료-질문'.tr(),
              style: TextStyle(
                fontSize: SizeConfig.defaultSize! * 2.5,
                //fontFamily: 'font-basic'.tr(),
              ),
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Container(
                    width: SizeConfig.defaultSize! * 24,
                    height: SizeConfig.defaultSize! * 4.5,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(SizeConfig.defaultSize! * 3),
                      color: const Color(0xFFFFA91A),
                    ),
                    child: Center(
                        child: CustomText(
                      '답변-부정'.tr(),
                      style: TextStyle(
                        color: Colors.black,
                        //fontFamily: 'font-basic'.tr(),
                        fontSize: 2.2 * SizeConfig.defaultSize!,
                      ),
                    )),
                  ),
                ),
                SizedBox(width: SizeConfig.defaultSize! * 4), // 간격 조정
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Container(
                    width: SizeConfig.defaultSize! * 24,
                    height: SizeConfig.defaultSize! * 4.5,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(SizeConfig.defaultSize! * 3),
                      color: const Color(0xFFFFA91A),
                    ),
                    child: Center(
                        child: CustomText(
                      '답변-긍정'.tr(),
                      style: TextStyle(
                        color: Colors.black,
                        //fontFamily: 'font-basic'.tr(),
                        fontSize: 2.2 * SizeConfig.defaultSize!,
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return shouldExit ?? false; // Return false if shouldExit is null
  }

  Future<void> sendReport() async {
    await dotenv.load(fileName: ".env");
    // API에서 모든 책 페이지 데이터를 불러와 pages 리스트에 저장
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token')!;
    if (reportContent != '') {
      final url = Uri.parse('${dotenv.get("API_SERVER")}user/report');
      final body = jsonEncode({
        'contentId': 0,
        'voiceId': 0,
        'pageNum': 0,
        'report': reportContent
      });

      var response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // if (jsonData is List<dynamic>) {
        //   setState(() {
        //     // pages = List<Map<String, dynamic>>.from(jsonData);
        //   });
        // }
        print(jsonData);
      } else {
        // 에러 처리
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final userCubit = context.watch<UserCubit>();
    final dataCubit = context.watch<DataCubit>();
    final sw = (MediaQuery.of(context).size.width -
        MediaQuery.of(context).padding.left -
        MediaQuery.of(context).padding.right);
    final sh = (MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom);
    SizeConfig().init(context);
    KeyboardVisibilityController().onChange.listen((bool visible) {
      setState(() {
        isKeyboardVisible = visible;
      });
    });

    final userState = userCubit.state;
    final dataRepository = RepositoryProvider.of<DataRepository>(context);

    SizeConfig().init(context);
    _sendHomeViewEvent();

    return WillPopScope(
        onWillPop: () async {
          bool shouldExit = await _showExitConfirmationDialog(context);
          return shouldExit; // Return true to exit the app, false to stay in the app
        },
        child: BlocProvider(
            create: (context) =>
                dataCubit..loadHomeBookData(), // DataCubit 생성 및 데이터 로드
            child: BlocBuilder<DataCubit, List<HomeScreenBookModel>>(
              builder: (context, state) {
                if (state.isEmpty) {
                  _sendHomeLoadingViewEvent();
                  return Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('lib/images/bkground.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LoadingAnimationWidget.fourRotatingDots(
                            color: //const Color.fromARGB(255, 255, 0, 0),
                                Color.fromARGB(255, 255, 169, 26),
                            size: 100, //SizeConfig.defaultSize! * 10,
                          ),
                          SizedBox(
                            height: SizeConfig.defaultSize! * 2,
                          ),
                          CustomText(
                            '로딩2'.tr(),
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'font-basic'.tr(),
                                fontSize: SizeConfig.defaultSize! *
                                    2.5 *
                                    double.parse('font-ratio'.tr()),
                                decoration: TextDecoration.none),
                          )
                        ],
                      ));
                } else {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    key: _scaffoldKey,
                    drawer: SizedBox(
                      width: SizeConfig.defaultSize! * 33,
                      child: _Drawer(userState, userCubit, context),
                    ),
                    bottomNavigationBar: CustomBottomNavigationBar(
                      index: 2,
                      bgmPlayer: bgmPlayer,
                    ),
                    body: Stack(children: [
                      // if (openCalendar)
                      //   Positioned.fill(
                      //     child: GestureDetector(
                      //       onTap: _openCalendarFunc,
                      //       child: Container(
                      //         color: const Color.fromARGB(255, 251, 251, 251)
                      //             .withOpacity(0.5), // 반투명 배경색 설정
                      //       ),
                      //     ),
                      //   ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          // image: DecorationImage(
                          //   opacity: 1.0,
                          //   image: AssetImage('lib/images/bkground.png'),
                          //   fit: BoxFit.cover,
                          // ),
                        ),
                        child: SafeArea(
                          top: true,
                          bottom: false,
                          // minimum: EdgeInsets.only(
                          //     left: 2 * SizeConfig.defaultSize!,
                          //     right: 2 * SizeConfig.defaultSize!),
                          child: Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.topLeft,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'LOVEL',
                                          style: TextStyle(
                                              fontFamily: 'Modak',
                                              fontSize:
                                                  SizeConfig.defaultSize! * 4,
                                              color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      //left: 20,
                                      top: SizeConfig.defaultSize! * 0.5,
                                      left: SizeConfig.defaultSize! * 2,
                                      child: InkWell(
                                        onTap: () {
                                          userCubit.fetchUser();

                                          _sendHbgClickEvent();
                                          _scaffoldKey.currentState
                                              ?.openDrawer();
                                          userCubit.fetchUser();
                                        },
                                        child: Image.asset(
                                          'lib/images/hamburger.png',
                                          width: 4.5 *
                                              SizeConfig
                                                  .defaultSize!, // 이미지의 폭 설정
                                          height: // 이미지의 높이 설정
                                              4.5 * SizeConfig.defaultSize!,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: SizeConfig.defaultSize! * 0.2,
                                      right: SizeConfig.defaultSize! * 1,
                                      child: userState.record &&
                                              userState.purchase
                                          ? GestureDetector(
                                              onTap: () {
                                                userCubit.fetchUser();
                                                _sendHbgVoiceClickEvent();
                                                bgmPlayer.pause();

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        VoiceProfile(
                                                      bgmPlayer: bgmPlayer,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Image.asset(
                                                'lib/images/icon/${userState.image}.png',
                                                width: 5.5 *
                                                    SizeConfig
                                                        .defaultSize!, // 이미지의 폭 설정
                                                height: // 이미지의 높이 설정
                                                    5.5 *
                                                        SizeConfig.defaultSize!,
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                _sendHbgAddVoiceClickEvent();
                                                userState.purchase
                                                    ? bgmPlayer.pause()
                                                    : null;
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        userState.purchase
                                                            ? RecInfo(
                                                                contentId: 0,
                                                                bgmPlayer:
                                                                    bgmPlayer,
                                                              )
                                                            : Purchase(
                                                                bgmPlayer:
                                                                    bgmPlayer,
                                                              ),
                                                  ),
                                                );
                                              },
                                              child: Image.asset(
                                                'lib/images/icon/${userState.image}.png',
                                                width: 5.5 *
                                                    SizeConfig
                                                        .defaultSize!, // 이미지의 폭 설정
                                                height: // 이미지의 높이 설정
                                                    5.5 *
                                                        SizeConfig.defaultSize!,
                                              ),
                                            ),
                                    ),
                                    //userState.purchase // 구독이면 캘린더 보여주지 않음
                                    // ? Container()
                                    //:
                                    // Positioned(
                                    //     right: SizeConfig.defaultSize! * 10,
                                    //     top: SizeConfig.defaultSize! * 0.2,
                                    //     child: SizedBox(
                                    //         width: 8 * SizeConfig.defaultSize!,
                                    //         height: 8 * SizeConfig.defaultSize!,
                                    //         child: Container(
                                    //             decoration: BoxDecoration(
                                    //                 gradient: RadialGradient(
                                    //                     radius: 0.5,
                                    //                     // begin: Alignment.topCenter,
                                    //                     // end: Alignment.bottomCenter,
                                    //                     colors: [
                                    //               const Color.fromARGB(255, 255,
                                    //                   0, 0), // 흐린 배경의 시작 색상
                                    //               Color.fromARGB(0, 255, 255,
                                    //                   255), // 투명한 중간 색상
                                    //             ]))))),
                                    // Positioned(
                                    //   right: SizeConfig.defaultSize! * 12.5,
                                    //   top: SizeConfig.defaultSize! * 2,
                                    //   child: InkWell(
                                    //     onTap: () {
                                    //       lastPointYMD == formattedTime
                                    //           ? _sendCalClickEvent(
                                    //               userState.point,
                                    //               availableGetPoint,
                                    //               'Already Claimed')
                                    //           : _sendCalClickEvent(
                                    //               userState.point,
                                    //               availableGetPoint,
                                    //               'Not Claimed Yet');
                                    //       _openCalendarFunc();
                                    //     },
                                    //     child: Image.asset(
                                    //       'lib/images/calendarOrange.png',
                                    //       width: 4 *
                                    //           SizeConfig
                                    //               .defaultSize!, // 이미지의 폭 설정
                                    //       height: 4 * SizeConfig.defaultSize!,
                                    //       // 이미지의 높이 설정
                                    //     ),
                                    //   ),
                                    // ),

                                    // Visibility(
                                    //     visible: lastPointYMD != formattedTime,
                                    //     child: Positioned(
                                    //         right: SizeConfig.defaultSize! * 12,
                                    //         top: 0.05 * sh,
                                    //         child: Image.asset(
                                    //           'lib/images/redButton.png',
                                    //           width: 0.02 * sw,
                                    //         ))),
                                    //userState.purchase
                                    // ? Container()
                                    //:
                                    //   Positioned(
                                    //     //구독이면 포인트 보여주지 않음
                                    //     top: 2.2 * SizeConfig.defaultSize!,
                                    //     right: 1 * SizeConfig.defaultSize!,
                                    //     child: Stack(children: [
                                    //       GestureDetector(
                                    //         onTap: () {
                                    //           _sendHomePointClickEvent(
                                    //               userState.point);
                                    //           Navigator.push(
                                    //             context,
                                    //             MaterialPageRoute(
                                    //                 builder: (context) =>
                                    //                     Purchase(
                                    //                      )),
                                    //           );
                                    //         },
                                    //         child: Container(
                                    //           width: 10 * SizeConfig.defaultSize!,
                                    //           height: 4 * SizeConfig.defaultSize!,
                                    //           decoration: BoxDecoration(
                                    //               color: const Color.fromARGB(
                                    //                   128, 255, 255, 255),
                                    //               borderRadius: BorderRadius.all(
                                    //                   Radius.circular(SizeConfig
                                    //                           .defaultSize! *
                                    //                       1))),
                                    //           child: Row(
                                    //               mainAxisAlignment:
                                    //                   MainAxisAlignment.start,
                                    //               children: [
                                    //                 SizedBox(
                                    //                   width: 0.5 *
                                    //                       SizeConfig.defaultSize!,
                                    //                 ),
                                    //                 SizedBox(
                                    //                     width: 2 *
                                    //                         SizeConfig
                                    //                             .defaultSize!,
                                    //                     child: Image.asset(
                                    //                       'lib/images/oneCoin.png',
                                    //                     )),
                                    //                 Container(
                                    //                   width: 7 *
                                    //                       SizeConfig.defaultSize!,
                                    //                   alignment: Alignment.center,
                                    //                   // decoration: BoxDecoration(color: Colors.blue),
                                    //                   child: Text(
                                    //                     '${userState.point + 0}',
                                    //                     style: TextStyle(
                                    //                         fontFamily: 'lilita',
                                    //                         fontSize: SizeConfig
                                    //                                 .defaultSize! *
                                    //                             2,
                                    //                         color: Colors.black),
                                    //                     textAlign:
                                    //                         TextAlign.center,
                                    //                   ),
                                    //                 )
                                    //               ]),
                                    //         ),
                                    //       ),
                                    //     ]),
                                    //   ),
                                    //
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 12,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                          padding: EdgeInsets.only(
                                              left: SizeConfig.defaultSize! * 2,
                                              top: SizeConfig.defaultSize! * 2),
                                          height: SizeConfig.defaultSize! * 25,
                                          color: Color(0xFFFFF0DF),
                                          child: Column(children: [
                                            Row(
                                              children: [
                                                Image.asset(
                                                    'lib/images/duck.png',
                                                    width: 2.5 *
                                                        SizeConfig
                                                            .defaultSize!),
                                                SizedBox(
                                                    width: SizeConfig
                                                            .defaultSize! *
                                                        0.7),
                                                CustomText('내 책',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 1.8 *
                                                            SizeConfig
                                                                .defaultSize!)),
                                              ],
                                            ),
                                            SizedBox(
                                                height:
                                                    SizeConfig.defaultSize! *
                                                        1.5),
                                            BlocProvider(
                                              create: (context) => dataCubit
                                                ..loadHomeBookData(), // DataCubit 생성 및 데이터 로드
                                              child: Container(
                                                height:
                                                    SizeConfig.defaultSize! *
                                                        18,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: state.length,
                                                  //  itemCount: 4,
                                                  itemBuilder:
                                                      (context, index) {
                                                    var book = state[index];
                                                    return GestureDetector(
                                                      onTap: () async {
                                                        _sendBookClickEvent(
                                                            book.id);
                                                        SharedPreferences
                                                            prefs =
                                                            await SharedPreferences
                                                                .getInstance();
                                                        bgmPlayer.pause();
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  MultiBlocProvider(
                                                                    providers: [
                                                                      BlocProvider<
                                                                          BookVoiceCubit>(
                                                                        create: (context) => BookVoiceCubit(
                                                                            dataRepository)
                                                                          ..loadBookVoiceData(
                                                                              book.id),
                                                                      ),
                                                                      BlocProvider<
                                                                          BookIntroCubit>(
                                                                        create: (context) =>
                                                                            // BookIntroCubit(),
                                                                            // DataCubit()..loadHomeBookData()
                                                                            BookIntroCubit(dataRepository)..loadBookIntroData(book.id),
                                                                      )
                                                                    ],
                                                                    child:
                                                                        BookIntro(
                                                                      id: book
                                                                          .id,
                                                                      title: book
                                                                          .title,
                                                                      thumbUrl:
                                                                          book.thumbUrl,
                                                                      bgmPlayer:
                                                                          bgmPlayer,
                                                                    ),
                                                                  )),
                                                        );
                                                        // : Navigator.push(
                                                        //     //구독자가 아니면 purchase로 보낸다?
                                                        //     context,
                                                        //     MaterialPageRoute(
                                                        //       builder: (context) =>
                                                        //           userState.purchase
                                                        //               ? BlocProvider(
                                                        //                   create: (context) =>
                                                        //                       // BookIntroCubit(),
                                                        //                       // DataCubit()..loadHomeBookData()
                                                        //                       BookIntroCubit()..loadBookIntroData(book.id),
                                                        //                   child:
                                                        //                       BookIntro(
                                                        //                     title: book
                                                        //                         .title,
                                                        //                     thumb: book
                                                        //                         .thumbUrl,
                                                        //                     id: book
                                                        //                         .id,
                                                        //                     summary: book
                                                        //                         .summary,
                                                        //                   ),
                                                        //                 )
                                                        //               : const Purchase(),
                                                        //     ));
                                                      }, //onTap 종료
                                                      child: book.lock
                                                          // 사용자가 포인트로 책을 풀었거나, 무료 공개 책이면 lock 해제
                                                          ? Container()
                                                          : unlockedBook(
                                                              book), //구독자아님
                                                    );
                                                  },
                                                  separatorBuilder: (context,
                                                          index) =>
                                                      SizedBox(
                                                          width: 2 *
                                                              SizeConfig
                                                                  .defaultSize!),
                                                ),
                                              ),
                                            ),
                                            //첫 줄 종료
                                          ])),
                                      Container(
                                          padding: EdgeInsets.only(
                                              left: SizeConfig.defaultSize! * 2,
                                              top: SizeConfig.defaultSize! * 2),
                                          height: SizeConfig.defaultSize! * 25,
                                          color: Color(0xFFFEF8D6),
                                          child: Column(children: [
                                            Row(
                                              children: [
                                                Image.asset(
                                                    'lib/images/bear.png',
                                                    width: 2.5 *
                                                        SizeConfig
                                                            .defaultSize!),
                                                SizedBox(
                                                    width: SizeConfig
                                                            .defaultSize! *
                                                        0.7),
                                                CustomText('클래식 고전',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 1.8 *
                                                            SizeConfig
                                                                .defaultSize!))
                                              ],
                                            ),
                                            SizedBox(
                                                height:
                                                    SizeConfig.defaultSize! *
                                                        1.5),
                                            BlocProvider(
                                              create: (context) => dataCubit
                                                ..loadHomeBookData(), // DataCubit 생성 및 데이터 로드
                                              child: Container(
                                                height:
                                                    SizeConfig.defaultSize! *
                                                        18,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: state.length,
                                                  //  itemCount: 4,
                                                  itemBuilder:
                                                      (context, index) {
                                                    var book = state[index];
                                                    return GestureDetector(
                                                      onTap: () async {
                                                        _sendBookClickEvent(
                                                            book.id);
                                                        SharedPreferences
                                                            prefs =
                                                            await SharedPreferences
                                                                .getInstance();
                                                        bgmPlayer.pause();
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  MultiBlocProvider(
                                                                    providers: [
                                                                      BlocProvider<
                                                                          BookVoiceCubit>(
                                                                        create: (context) => BookVoiceCubit(
                                                                            dataRepository)
                                                                          ..loadBookVoiceData(
                                                                              book.id),
                                                                      ),
                                                                      BlocProvider<
                                                                          BookIntroCubit>(
                                                                        create: (context) =>
                                                                            // BookIntroCubit(),
                                                                            // DataCubit()..loadHomeBookData()
                                                                            BookIntroCubit(dataRepository)..loadBookIntroData(book.id),
                                                                      )
                                                                    ],
                                                                    child:
                                                                        BookIntro(
                                                                      id: book
                                                                          .id,
                                                                      title: book
                                                                          .title,
                                                                      thumbUrl:
                                                                          book.thumbUrl,
                                                                      bgmPlayer:
                                                                          bgmPlayer,
                                                                    ),
                                                                  )),
                                                        );
                                                        // : Navigator.push(
                                                        //     //구독자가 아니면 purchase로 보낸다?
                                                        //     context,
                                                        //     MaterialPageRoute(
                                                        //       builder: (context) =>
                                                        //           userState.purchase
                                                        //               ? BlocProvider(
                                                        //                   create: (context) =>
                                                        //                       // BookIntroCubit(),
                                                        //                       // DataCubit()..loadHomeBookData()
                                                        //                       BookIntroCubit()..loadBookIntroData(book.id),
                                                        //                   child:
                                                        //                       BookIntro(
                                                        //                     title: book
                                                        //                         .title,
                                                        //                     thumb: book
                                                        //                         .thumbUrl,
                                                        //                     id: book
                                                        //                         .id,
                                                        //                     summary: book
                                                        //                         .summary,
                                                        //                   ),
                                                        //                 )
                                                        //               : const Purchase(),
                                                        //     ));
                                                      }, //onTap 종료
                                                      child: book.author ==
                                                              "classic"
                                                          ? book.lock
                                                              // 사용자가 포인트로 책을 풀었거나, 무료 공개 책이면 lock 해제
                                                              ? Row(
                                                                  children: [
                                                                      lockedBook(
                                                                          book),
                                                                      SizedBox(
                                                                          width:
                                                                              2 * SizeConfig.defaultSize!)
                                                                    ])
                                                              : Row(
                                                                  children: [
                                                                      unlockedBook(
                                                                          book),
                                                                      SizedBox(
                                                                          width:
                                                                              2 * SizeConfig.defaultSize!)
                                                                    ])
                                                          : Container(), //구독자아님
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            //첫 줄 종료
                                          ])),
                                      Container(
                                          padding: EdgeInsets.only(
                                              left: SizeConfig.defaultSize! * 2,
                                              top: SizeConfig.defaultSize! * 2),
                                          height: SizeConfig.defaultSize! * 25,
                                          color: Color(0xFFFFFFFF),
                                          child: Column(children: [
                                            Row(
                                              children: [
                                                Image.asset(
                                                    'lib/images/pencil.png',
                                                    width: 2.5 *
                                                        SizeConfig
                                                            .defaultSize!),
                                                SizedBox(
                                                    width: SizeConfig
                                                            .defaultSize! *
                                                        0.7),
                                                CustomText('어거스틴 작가 모음전',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 1.8 *
                                                            SizeConfig
                                                                .defaultSize!))
                                              ],
                                            ),
                                            SizedBox(
                                                height:
                                                    SizeConfig.defaultSize! *
                                                        1.5),
                                            BlocProvider(
                                              create: (context) => dataCubit
                                                ..loadHomeBookData(), // DataCubit 생성 및 데이터 로드
                                              child: Container(
                                                height:
                                                    SizeConfig.defaultSize! *
                                                        18,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: state.length,
                                                  //  itemCount: 4,
                                                  itemBuilder:
                                                      (context, index) {
                                                    var book = state[index];
                                                    return GestureDetector(
                                                      onTap: () async {
                                                        _sendBookClickEvent(
                                                            book.id);
                                                        SharedPreferences
                                                            prefs =
                                                            await SharedPreferences
                                                                .getInstance();
                                                        bgmPlayer.pause();
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  MultiBlocProvider(
                                                                    providers: [
                                                                      BlocProvider<
                                                                          BookVoiceCubit>(
                                                                        create: (context) => BookVoiceCubit(
                                                                            dataRepository)
                                                                          ..loadBookVoiceData(
                                                                              book.id),
                                                                      ),
                                                                      BlocProvider<
                                                                          BookIntroCubit>(
                                                                        create: (context) =>
                                                                            // BookIntroCubit(),
                                                                            // DataCubit()..loadHomeBookData()
                                                                            BookIntroCubit(dataRepository)..loadBookIntroData(book.id),
                                                                      )
                                                                    ],
                                                                    child:
                                                                        BookIntro(
                                                                      id: book
                                                                          .id,
                                                                      title: book
                                                                          .title,
                                                                      thumbUrl:
                                                                          book.thumbUrl,
                                                                      bgmPlayer:
                                                                          bgmPlayer,
                                                                    ),
                                                                  )),
                                                        );
                                                        // : Navigator.push(
                                                        //     //구독자가 아니면 purchase로 보낸다?
                                                        //     context,
                                                        //     MaterialPageRoute(
                                                        //       builder: (context) =>
                                                        //           userState.purchase
                                                        //               ? BlocProvider(
                                                        //                   create: (context) =>
                                                        //                       // BookIntroCubit(),
                                                        //                       // DataCubit()..loadHomeBookData()
                                                        //                       BookIntroCubit()..loadBookIntroData(book.id),
                                                        //                   child:
                                                        //                       BookIntro(
                                                        //                     title: book
                                                        //                         .title,
                                                        //                     thumb: book
                                                        //                         .thumbUrl,
                                                        //                     id: book
                                                        //                         .id,
                                                        //                     summary: book
                                                        //                         .summary,
                                                        //                   ),
                                                        //                 )
                                                        //               : const Purchase(),
                                                        //     ));
                                                      }, //onTap 종료
                                                      child: book.author ==
                                                              "augustine"
                                                          ? book.lock
                                                              // 사용자가 포인트로 책을 풀었거나, 무료 공개 책이면 lock 해제
                                                              ? Row(
                                                                  children: [
                                                                      lockedBook(
                                                                          book),
                                                                      SizedBox(
                                                                          width:
                                                                              2 * SizeConfig.defaultSize!)
                                                                    ])
                                                              : Row(
                                                                  children: [
                                                                      unlockedBook(
                                                                          book),
                                                                      SizedBox(
                                                                          width:
                                                                              2 * SizeConfig.defaultSize!)
                                                                    ])
                                                          : Container(),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            //첫 줄 종료
                                          ])),

                                      Container(
                                          padding: EdgeInsets.only(
                                              left: SizeConfig.defaultSize! * 2,
                                              top: SizeConfig.defaultSize! * 2),
                                          height: SizeConfig.defaultSize! * 25,
                                          color: Color(0xFFEBF4FF),
                                          child: Column(children: [
                                            Row(
                                              children: [
                                                Image.asset(
                                                    'lib/images/vane.png',
                                                    width: 2.5 *
                                                        SizeConfig
                                                            .defaultSize!),
                                                SizedBox(
                                                    width: SizeConfig
                                                            .defaultSize! *
                                                        0.7),
                                                CustomText('LOVEL 오리지널',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 1.8 *
                                                            SizeConfig
                                                                .defaultSize!))
                                              ],
                                            ),
                                            SizedBox(
                                                height:
                                                    SizeConfig.defaultSize! *
                                                        1.5),
                                            BlocProvider(
                                              create: (context) => dataCubit
                                                ..loadHomeBookData(), // DataCubit 생성 및 데이터 로드
                                              child: Container(
                                                height:
                                                    SizeConfig.defaultSize! *
                                                        18,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: state.length,
                                                  //  itemCount: 4,
                                                  itemBuilder:
                                                      (context, index) {
                                                    var book = state[index];
                                                    return GestureDetector(
                                                      onTap: () async {
                                                        _sendBookClickEvent(
                                                            book.id);
                                                        SharedPreferences
                                                            prefs =
                                                            await SharedPreferences
                                                                .getInstance();
                                                        bgmPlayer.pause();
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  MultiBlocProvider(
                                                                    providers: [
                                                                      BlocProvider<
                                                                          BookVoiceCubit>(
                                                                        create: (context) => BookVoiceCubit(
                                                                            dataRepository)
                                                                          ..loadBookVoiceData(
                                                                              book.id),
                                                                      ),
                                                                      BlocProvider<
                                                                          BookIntroCubit>(
                                                                        create: (context) =>
                                                                            // BookIntroCubit(),
                                                                            // DataCubit()..loadHomeBookData()
                                                                            BookIntroCubit(dataRepository)..loadBookIntroData(book.id),
                                                                      )
                                                                    ],
                                                                    child:
                                                                        BookIntro(
                                                                      id: book
                                                                          .id,
                                                                      title: book
                                                                          .title,
                                                                      thumbUrl:
                                                                          book.thumbUrl,
                                                                      bgmPlayer:
                                                                          bgmPlayer,
                                                                    ),
                                                                  )),
                                                        );
                                                        // : Navigator.push(
                                                        //     //구독자가 아니면 purchase로 보낸다?
                                                        //     context,
                                                        //     MaterialPageRoute(
                                                        //       builder: (context) =>
                                                        //           userState.purchase
                                                        //               ? BlocProvider(
                                                        //                   create: (context) =>
                                                        //                       // BookIntroCubit(),
                                                        //                       // DataCubit()..loadHomeBookData()
                                                        //                       BookIntroCubit()..loadBookIntroData(book.id),
                                                        //                   child:
                                                        //                       BookIntro(
                                                        //                     title: book
                                                        //                         .title,
                                                        //                     thumb: book
                                                        //                         .thumbUrl,
                                                        //                     id: book
                                                        //                         .id,
                                                        //                     summary: book
                                                        //                         .summary,
                                                        //                   ),
                                                        //                 )
                                                        //               : const Purchase(),
                                                        //     ));
                                                      }, //onTap 종료
                                                      child: book.author ==
                                                              "original"
                                                          ? book.lock
                                                              // 사용자가 포인트로 책을 풀었거나, 무료 공개 책이면 lock 해제
                                                              ? Row(
                                                                  children: [
                                                                      lockedBook(
                                                                          book),
                                                                      SizedBox(
                                                                          width:
                                                                              2 * SizeConfig.defaultSize!)
                                                                    ])
                                                              : Row(
                                                                  children: [
                                                                      unlockedBook(
                                                                          book),
                                                                      SizedBox(
                                                                          width:
                                                                              2 * SizeConfig.defaultSize!)
                                                                    ])
                                                          : Container(), //구독자아님
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            //첫 줄 종료
                                          ])),

                                      // SizedBox(
                                      //   //두 번째 줄 시작
                                      //   height: SizeConfig.defaultSize! * 36,
                                      //   child: BlocProvider(
                                      //       create: (context) => DataCubit(
                                      //           dataRepository)
                                      //         ..loadHomeBookData(), // DataCubit 생성 및 데이터 로드
                                      //       child: ListView.separated(
                                      //         scrollDirection: Axis.horizontal,
                                      //         itemCount: state.length - 4,
                                      //         itemBuilder: (context, index) {
                                      //           var book = state[index + 4];
                                      //           return GestureDetector(
                                      //             onTap: () async {
                                      //               _sendBookClickEvent(book.id);
                                      //               SharedPreferences prefs =
                                      //                   await SharedPreferences
                                      //                       .getInstance();
                                      //               await prefs.setBool(
                                      //                   'haveClickedBook', true);
                                      //               setState(() {
                                      //                 showFairy = true;
                                      //               });

                                      //               Navigator.push(
                                      //                 context,
                                      //                 MaterialPageRoute(
                                      //                   builder: (context) =>
                                      //                       BlocProvider(
                                      //                     create: (context) =>

                                      //                         BookIntroCubit(
                                      //                             dataRepository)
                                      //                           ..loadBookIntroData(
                                      //                               book.id),
                                      //                     child: BookIntro(
                                      //                       title: book.title,
                                      //                       thumb: book.thumbUrl,
                                      //                       id: book.id,
                                      //                       summary: book.summary,
                                      //                     ),
                                      //                   ),
                                      //                 ),
                                      //               );

                                      //             },
                                      //             child: book.lock &&
                                      //                     !userState.purchase
                                      //                 // 사용자가 포인트로 책을 풀었거나, 무료 공개 책이면 lock 해제
                                      //                 ? lockedBook(book)
                                      //                 : unlockedBook(book), //구독자아님
                                      //           );
                                      //         },
                                      //         separatorBuilder: (context, index) =>
                                      //             SizedBox(
                                      //                 width: 2 *
                                      //                     SizeConfig.defaultSize!),
                                      //       )),
                                      // ),
                                      // 아래 줄에 또 다른 책을 추가하고 싶으면 주석을 해지하면 됨
                                      // Container(
                                      //   color: Colors.yellow,
                                      //   height: 300,
                                      //   child: const Center(
                                      //     child: Text(
                                      //       'Scrollable Content 2',
                                      //       style: TextStyle(fontSize: 24),
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                                //),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Visibility(
                      //   visible: wantDelete,
                      //   child: AlertDialog(
                      //     title: const Text('Delete Account'),
                      //     content:
                      //         const Text('Do you want to DELETE your account?'),
                      //     actions: [
                      //       TextButton(
                      //         onPressed: () {
                      //           // 1초 후에 다음 페이지로 이동
                      //           userCubit.logout();
                      //           OneSignal.shared.removeExternalUserId();
                      //           deleteAccount();
                      //           Future.delayed(const Duration(seconds: 1), () {
                      //             setState(() {
                      //               wantDelete = false;
                      //             });
                      //           });
                      //         },
                      //         child: const Text('답변-긍정-대문자'),
                      //       ),
                      //       TextButton(
                      //         onPressed: () {
                      //           // 1초 후에 다음 페이지로 이동
                      //           setState(() {
                      //             wantDelete = false;
                      //           });
                      //         },
                      //         child: const Text('답변-부정'),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // Container(
                      //   color: Colors.white.withOpacity(0.6),
                      //   child: GestureDetector(
                      //     onTap: ,
                      //   ),
                      // )
                      SafeArea(
                        child: Visibility(
                            visible: reportClicked,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: sw * 0.1,
                                top: isKeyboardVisible ? sh * 0.1 : sh * 0.3,
                              ),
                              child: Container(
                                  width: sw * 0.8,
                                  height: sh * 0.3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        SizeConfig.defaultSize! * 2),
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  child: Stack(children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                          // right: SizeConfig.defaultSize!,
                                          top: sh * 0.12,
                                          bottom: sh * 0.05),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.only(
                                                // left: SizeConfig.defaultSize! * 3,
                                                right:
                                                    SizeConfig.defaultSize! * 2,
                                              ),
                                              width: 0.6 * sw,
                                              child: TextField(
                                                onChanged: (value) {
                                                  setState(() {
                                                    reportContent = value;
                                                  });
                                                },
                                                decoration: InputDecoration(
                                                    contentPadding: EdgeInsets.all(
                                                        10), // 입력 텍스트와 외곽선 사이의 간격 조정
                                                    hintText: '오류제보'.tr(),
                                                    filled: true,
                                                    fillColor:
                                                        Colors.grey[200]),
                                              ),
                                            ),
                                            Container(
                                              child: GestureDetector(
                                                onTap: () {
                                                  _sendErrorReportSendClickEvent();
                                                  sendReport();
                                                  setState(() {
                                                    reportClicked = false;
                                                  });
                                                },
                                                child: Container(
                                                  width:
                                                      SizeConfig.defaultSize! *
                                                          10,
                                                  height:
                                                      SizeConfig.defaultSize! *
                                                          4.5,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius
                                                        .circular(SizeConfig
                                                                .defaultSize! *
                                                            1),
                                                    color:
                                                        const Color(0xFFFFA91A),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '오류제출'.tr(),
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontFamily:
                                                            'font-basic'.tr(),
                                                        fontSize: 2 *
                                                            SizeConfig
                                                                .defaultSize! *
                                                            double.parse(
                                                                'font-ratio'
                                                                    .tr()),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]),
                                    ),
                                    Positioned(
                                      top: sh * 0.00,
                                      right: sw * 0.000,
                                      child: IconButton(
                                        padding: EdgeInsets.all(sh * 0.01),
                                        alignment: Alignment.centerLeft,
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.black,
                                          size: 3 * SizeConfig.defaultSize!,
                                        ),
                                        onPressed: () {
                                          _sendErrorReportXClickEvent();
                                          setState(() {
                                            reportClicked = false;
                                          });
                                          //고민
                                        },
                                      ),
                                    ),
                                  ])),
                            )),
                      ),
                    ]
                        //   ),
                        ),
                  );
                }
              },
            )));
  }

  Drawer _Drawer(
      UserState userState, UserCubit userCubit, BuildContext context) {
    return Drawer(
        child: Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFAE4),
        // image: DecorationImage(
        //   image: AssetImage('lib/images/bkground.png'),
        //   fit: BoxFit.cover,
        // ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Column(
            children: [
              SafeArea(
                minimum: EdgeInsets.only(
                  left: 3 * SizeConfig.defaultSize!,
                ),
                //right: 3 * SizeConfig.defaultSize!),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ),
                      SizedBox(
                        height: 3 * SizeConfig.defaultSize!,
                      ),
                      CustomText(
                        '프로필'.tr(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 2 * SizeConfig.defaultSize!,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 1 * SizeConfig.defaultSize!,
                      ),
                      userState.record && userState.purchase
                          ? GestureDetector(
                              onTap: () {
                                _sendHbgVoiceBoxClickEvent();
                              },
                              child: SizedBox(
                                width: 23 * SizeConfig.defaultSize!,
                                height: 11 * SizeConfig.defaultSize!,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      child: Container(
                                        width: 23 * SizeConfig.defaultSize!,
                                        height: 11 * SizeConfig.defaultSize!,
                                        decoration: ShapeDecoration(
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                        left: 1.2 * SizeConfig.defaultSize!,
                                        top: 1.5 * SizeConfig.defaultSize!,
                                        // child: Transform.translate(
                                        //     offset: Offset(
                                        //         0.5,
                                        //         -0.7 *
                                        //             SizeConfig.defaultSize!),
                                        child: GestureDetector(
                                          onTap: () {
                                            userCubit.fetchUser();
                                            _sendHbgVoiceClickEvent();
                                            bgmPlayer.pause();

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VoiceProfile(
                                                  bgmPlayer: bgmPlayer,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Image.asset(
                                            'lib/images/icons/${userState.voiceIcon}-c.png',
                                            height: SizeConfig.defaultSize! * 8,
                                          ),
                                        )),
                                    Positioned(
                                      left: 9.5 * SizeConfig.defaultSize!,
                                      top: 2.3 * SizeConfig.defaultSize!,
                                      child: GestureDetector(
                                        onTap: () {
                                          userCubit.fetchUser();
                                          _sendHbgVoiceClickEvent();
                                          bgmPlayer.pause();

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VoiceProfile(
                                                bgmPlayer: bgmPlayer,
                                              ),
                                            ),
                                          );
                                        },
                                        child: SizedBox(
                                          width: 12.2 * SizeConfig.defaultSize!,
                                          height: 2 * SizeConfig.defaultSize!,
                                          child: Text(
                                            userState.voiceName!,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize:
                                                  2 * SizeConfig.defaultSize!,
                                              fontFamily: 'Molengo',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 10.2 * SizeConfig.defaultSize!,
                                      top: 6 * SizeConfig.defaultSize!,
                                      child: GestureDetector(
                                          onTap: () {
                                            userCubit.fetchUser();
                                            _sendHbgVoiceClickEvent();
                                            bgmPlayer.pause();

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VoiceProfile(
                                                  bgmPlayer: bgmPlayer,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                              width:
                                                  11 * SizeConfig.defaultSize!,
                                              height:
                                                  3 * SizeConfig.defaultSize!,
                                              decoration: ShapeDecoration(
                                                color: const Color(0xFFFFA91A),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: Center(
                                                child: CustomText(
                                                  '프로필-수정'.tr(),
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 1.4 *
                                                        SizeConfig.defaultSize!,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ))),
                                    )
                                  ],
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                _sendHbgAddVoiceClickEvent();
                                userState.purchase ? bgmPlayer.pause() : null;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => userState.purchase
                                        ? RecInfo(
                                            contentId: 0,
                                            bgmPlayer: bgmPlayer,
                                          )
                                        : Purchase(
                                            bgmPlayer: bgmPlayer,
                                          ),
                                  ),
                                );
                              },
                              child: Container(
                                  width: 27 * SizeConfig.defaultSize!,
                                  height: 4 * SizeConfig.defaultSize!,
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: SizeConfig.defaultSize! * 2.5,
                                    color: const Color(0xFFFFA91A),
                                  ))),

                      SizedBox(
                        height: 1.5 * SizeConfig.defaultSize!,
                      ),
                      // 친구에게 string 공유
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: 0.5 * SizeConfig.defaultSize!,
                              top: 0.5 * SizeConfig.defaultSize!,
                              bottom: 0.5 * SizeConfig.defaultSize!),
                          child: CustomText(
                            '공지사항'.tr(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 2 * SizeConfig.defaultSize!,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Notice(),
                            ),
                          );
                        },
                      ),

                      SizedBox(
                        height: 1.5 * SizeConfig.defaultSize!,
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: 0.5 * SizeConfig.defaultSize!,
                              top: 0.5 * SizeConfig.defaultSize!,
                              bottom: 0.5 * SizeConfig.defaultSize!),
                          child: CustomText(
                            '친구초대'.tr(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 2 * SizeConfig.defaultSize!,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onTap: () async {
                          _sendInviteFriendsClickEvent(userState.point);
                          final result =
                              await Share.shareWithResult('친구초대문구'.tr());
                          if (result.status == ShareResultStatus.success) {
                            _sendInviteFriendsSuccessEvent(userState.point);
                          }
                        },
                      ),
                      SizedBox(
                        height: 1.5 * SizeConfig.defaultSize!,
                      ),

                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: 0.5 * SizeConfig.defaultSize!,
                              top: 0.5 * SizeConfig.defaultSize!,
                              bottom: 0.5 * SizeConfig.defaultSize!),
                          child: CustomText(
                            Platform.isAndroid
                                ? '별점-구글플레이'.tr()
                                : '별점-앱스토어'.tr(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 2 * SizeConfig.defaultSize!,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onTap: () async {
                          final InAppReview inAppReview = InAppReview.instance;
                          _sendAppReviewClickEvent(userState.point);
                          if (await inAppReview.isAvailable()) {
                            print('available');
                            inAppReview.openStoreListing(
                                appStoreId: '6454792622');
                          }
                        },
                      ),
                      SizedBox(
                        height: 1.5 * SizeConfig.defaultSize!,
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: 0.5 * SizeConfig.defaultSize!,
                              top: 0.5 * SizeConfig.defaultSize!,
                              bottom: 0.5 * SizeConfig.defaultSize!),
                          child: CustomText(
                            '리포트'.tr(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 2 * SizeConfig.defaultSize!,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onTap: () async {
                          _sendErrorReportClickEvent();
                          setState(() {
                            _scaffoldKey.currentState?.closeDrawer();

                            reportClicked = true;
                          });
                        },
                      ),
                      SizedBox(
                        height: 1.0 * SizeConfig.defaultSize!,
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              '배경음악'.tr(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 2 * SizeConfig.defaultSize!,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: playingBgm,
                                activeColor: CupertinoColors.activeOrange,
                                onChanged: (bool? value) async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  setState(() {
                                    print(value);
                                    playingBgm = value ?? false;
                                    if (playingBgm)
                                      bgmPlayer.play(
                                          AssetSource('sound/Christmas.wav'));
                                    else {
                                      bgmPlayer.stop();
                                    }
                                    prefs.setBool('playingBgm', playingBgm);
                                    _isChanged = true;
                                  });
                                  Future.delayed(
                                          const Duration(milliseconds: 1500))
                                      .then((_) {
                                    setState(() {
                                      _isChanged = false;
                                    });
                                  });
                                },
                              ),
                            ),
                          ]),

                      // IconButton(
                      //     onPressed: () {
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (context) => CheckVoice(
                      //             infenrencedVoice: '48',
                      //           ),
                      //         ),
                      //       );
                      //     },
                      //     icon: const Icon(Icons.check)),

                      // userState.login
                      //     ? GestureDetector(
                      //         behavior: HitTestBehavior.opaque,
                      //         child: Padding(
                      //           padding: EdgeInsets.all(
                      //               0.5 * SizeConfig.defaultSize!),
                      //           child: Text(
                      //             'Sign Out',
                      //             style: TextStyle(
                      //               color: Colors.black,
                      //               fontSize: 1.8 * SizeConfig.defaultSize!,
                      //               fontFamily: 'Molengo',
                      //               fontWeight: FontWeight.w400,
                      //             ),
                      //           ),
                      //         ),
                      //         onTap: () {
                      //           _sendSignOutClickEvent();

                      //           setState(() {
                      //             showSignOutConfirmation =
                      //                 !showSignOutConfirmation; // dropdown 상태 토글
                      //           });
                      //         },
                      //       )
                      //     : GestureDetector(
                      //         behavior: HitTestBehavior.opaque,
                      //         child: Padding(
                      //           padding: EdgeInsets.all(
                      //               0.2 * SizeConfig.defaultSize!),
                      //           child: Container(
                      //               child: Text(
                      //             'Sign In',
                      //             style: TextStyle(
                      //               color: Colors.black,
                      //               fontSize: 1.8 * SizeConfig.defaultSize!,
                      //               fontFamily: 'Molengo',
                      //               fontWeight: FontWeight.w400,
                      //             ),
                      //           )),
                      //         ),
                      //         onTap: () {
                      //           _sendSignInClickEvent();

                      //           // dropdown 상태 토글
                      //           Navigator.push(
                      //             context,
                      //             MaterialPageRoute(
                      //                 builder: (context) => Platform.isIOS
                      //                     ? const Login()
                      //                     : const LoginAnd()),
                      //           );
                      //         }),
                      //    userState.login && showSignOutConfirmation
                      // userState.login && showSignOutConfirmation
                      //     ? GestureDetector(
                      //         behavior: HitTestBehavior.opaque,
                      //         onTap: () {
                      //           _sendSignOutReallyClickEvent();
                      //           logout();
                      //           userCubit.logout();
                      //           OneSignal.shared.removeExternalUserId();
                      //           _scaffoldKey.currentState?.closeDrawer();
                      //           setState(() {
                      //             showSignOutConfirmation =
                      //                 !showSignOutConfirmation;
                      //           });
                      //         },
                      //         child: Container(
                      //           margin: EdgeInsets.all(
                      //               0.5 * SizeConfig.defaultSize!),
                      //           padding: EdgeInsets.all(
                      //               0.3 * SizeConfig.defaultSize!),
                      //           color: Colors
                      //               .transparent, // 배경 터치 가능하게 하려면 배경 색상을 투명하게 설정
                      //           child: Text(
                      //             'Do you want to Sign Out?',
                      //             style: TextStyle(
                      //               color: const Color(0xFF599FED),
                      //               fontSize: 1.2 * SizeConfig.defaultSize!,
                      //               fontFamily: 'Molengo',
                      //               fontWeight: FontWeight.w400,
                      //             ),
                      //           ),
                      //         ),
                      //       )
                      //     : Container(),
                      // SizedBox(
                      //   height: 1 * SizeConfig.defaultSize!,
                      // ),
                      // userState.login
                      //     ? GestureDetector(
                      //         behavior: HitTestBehavior.opaque,
                      //         child: Padding(
                      //           padding: EdgeInsets.all(
                      //               0.5 * SizeConfig.defaultSize!),
                      //           child: Text(
                      //             'Delete Account',
                      //             style: TextStyle(
                      //               color: Colors.black,
                      //               fontSize: 1.8 * SizeConfig.defaultSize!,
                      //               fontFamily: 'Molengo',
                      //               fontWeight: FontWeight.w400,
                      //             ),
                      //           ),
                      //         ),
                      //         onTap: () {
                      //           setState(() {
                      //             _scaffoldKey.currentState?.closeDrawer();
                      //             wantDelete = true;
                      //           });
                      //         },
                      //       )
                      //     : Container(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    ));
  }

  Column unlockedBook(HomeScreenBookModel book) {
    return Column(
      children: [
        Hero(
          tag: book.id,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            height: SizeConfig.defaultSize! * 12,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(children: [
                  Container(
                    width: SizeConfig.defaultSize! * 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  Image(
                      image:
                          FileImage(File(book.thumbUrl.replaceAll("'", "")))),

                  // CachedNetworkImage(
                  //   imageUrl: book.thumbUrl,
                  // ),
                ])),
          ),
        ),
        SizedBox(
          height: SizeConfig.defaultSize! * 1,
        ),
        SizedBox(
          width: SizeConfig.defaultSize! * 12,
          child: CustomText(
            book.title,
            style: TextStyle(
              fontSize: SizeConfig.defaultSize! * 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Column lockedBook(HomeScreenBookModel book) {
    return Column(
      children: [
        Hero(
          tag: book.id,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            height: SizeConfig.defaultSize! * 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(children: [
                Image(
                    image: FileImage(File(book.thumbUrl.replaceAll("'", "")))),

                // CachedNetworkImage(
                //   imageUrl: book.thumbUrl,
                // ),
                Container(
                  width: SizeConfig.defaultSize! * 12,
                  color: Colors.white.withOpacity(0.6),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                      padding: EdgeInsets.only(
                          left: SizeConfig.defaultSize! * 0.5,
                          top: SizeConfig.defaultSize! * 0.5),
                      child: Image.asset(
                        'lib/images/locked.png',
                        width: SizeConfig.defaultSize! * 3,
                      )),
                ),
                if (book.isNew == true)
                  Positioned(
                      right: SizeConfig.defaultSize! * 0,
                      top: SizeConfig.defaultSize! * 0,
                      child: Image.asset(
                        'lib/images/new.png',
                        width: SizeConfig.defaultSize! * 3,
                      )),
                if (book.badge == "offer")
                  Positioned(
                      right: SizeConfig.defaultSize! * 1,
                      bottom: SizeConfig.defaultSize! * 1,
                      child: Image.asset(
                        'lib/images/specialOffer.png',
                        width: SizeConfig.defaultSize! * 2,
                      )),

                // CachedNetworkIma
              ]),
            ),
          ),
        ),
        SizedBox(
          height: SizeConfig.defaultSize! * 1,
        ),
        SizedBox(
          width: SizeConfig.defaultSize! * 12,
          child: CustomText(
            book.title,
            style: TextStyle(
              //fontFamily: 'GenBkBasR',
              fontSize: SizeConfig.defaultSize! * 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Future<void> _sendErrorReportClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'error_report_click',
        parameters: <String, dynamic>{},
      );
      amplitude.logEvent(
        'error_report_click',
        eventProperties: <String, dynamic>{},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendErrorReportSendClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'error_report_send_click',
        parameters: <String, dynamic>{},
      );
      amplitude.logEvent(
        'error_report_send_click',
        eventProperties: <String, dynamic>{},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendErrorReportXClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'error_report_x_click',
        parameters: <String, dynamic>{},
      );
      amplitude.logEvent(
        'error_report_x_click',
        eventProperties: <String, dynamic>{},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendSignOutReallyClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'sign_out_really_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'sign_out_really_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendSignOutClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'sign_out_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'sign_out_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendSignInClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'sign_in_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'sign_in_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHbgVoiceClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'hbg_voice_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'hbg_voice_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHbgAddVoiceClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'hbg_add_voice_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'hbg_add_voice_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHbgVoiceBoxClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'hbg_voice_box_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'hbg_voice_box_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHbgNameClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'hbg_name_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'hbg_name_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHomeViewEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'home_view',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'home_view',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookClickEvent(contentId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
        },
      );
      await amplitude.logEvent(
        'book_click',
        eventProperties: {
          'contentId': contentId,
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBannerClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'banner_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'banner_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendFairyClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'fairy_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'fairy_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendToolTipClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'tooltip_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'tooltip_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHbgClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'hbg_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'hbg_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHomeLoadingViewEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'home_loading_view',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'home_loading_view',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHomeFirstClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'home_first_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'home_first_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHomeSecondClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'home_second_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'home_second_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHomeCalTooltipClickEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'home_cal_tooltip_click',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent(
        'home_cal_tooltip_click',
        eventProperties: {},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHomePointClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'home_point_click',
        parameters: <String, dynamic>{'point_now': pointNow},
      );
      await amplitude.logEvent(
        'home_point_click',
        eventProperties: {'point_now': pointNow},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendInviteFriendsClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics
          .logEvent(name: 'invite_friends_click', parameters: <String, dynamic>{
        'point_now': pointNow,
      });
      await amplitude.logEvent(
        'invite_friends_click',
        eventProperties: {
          'point_now': pointNow,
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendInviteFriendsSuccessEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
          name: 'invite_friends_success',
          parameters: <String, dynamic>{
            'point_now': pointNow,
          });
      await amplitude.logEvent(
        'invite_friends_success',
        eventProperties: {
          'point_now': pointNow,
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendAppReviewClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics
          .logEvent(name: 'app_review_click', parameters: <String, dynamic>{
        'point_now': pointNow,
      });
      await amplitude.logEvent(
        'app_review_click',
        eventProperties: {
          'point_now': pointNow,
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }
}
