import 'dart:io';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/bookIntro/view/book_intro.dart';
import 'package:yoggo/component/globalCubit/user/user_state.dart';
import 'package:yoggo/component/home/viewModel/home_screen_book_model.dart';
// import 'package:yoggo/component/sub.dart';
import 'package:yoggo/component/shop.dart';
import 'package:yoggo/component/rec_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yoggo/size_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../Repositories/Repository.dart';
import '../../bookIntro/viewModel/book_intro_cubit.dart';
import '../../bookIntro/viewModel/book_voice_cubit.dart';
import '../../voice.dart';
import '../viewModel/home_screen_cubit.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../globalCubit/user/user_cubit.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // late Future<List<bookModel>> webtoons;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late String token;
  late int userId;
  bool showEmail = false;
  bool showSignOutConfirmation = false;
  bool wantDelete = false;
  double dropdownHeight = 0.0;
  bool isDataFetched = false; // 데이터를 받아온 여부를 나타내는 플래그
  bool showFirstOverlay = false; // Initially show the overlay
  bool showSecondOverlay = false; // Initially show the overlay
  bool showBanner = false;
  bool showFairy = false;
  bool showToolTip = false;
  // 받을 수 있는 포인트 day : availableGetPoint // 1일차, 2일차 ...
  // 마지막으로 받은 날짜: lastPointYMD // 2023년9월22일
  // 마지막으로 받은 포인트의 일수: lastPointDay --> 1일차, 2일차, 3일차... --> 마지막 기록이 1일차이면 2일차 포인트를 받게 해야한다
  late int availableGetPoint;
  String lastPointYMD = '';
  int lastPointDay = -1;
  String formattedTime = '';
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  // }

  @override
  void initState() {
    super.initState();
    getToken();
    _checkFirstTimeAccess(); // 앱 최초 사용 접속 : 온보딩 화면 보여주기
    Future.delayed(Duration.zero, () async {
      await saveRewardStatus();
    });
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
    bool haveClickedBook = prefs.getBool('haveClickedBook') ?? false;
    // bool haveClickedFairy = prefs.getBool('haveClickedFairy') ?? false;
    if (haveClickedBook) {
      setState(() {
        showFairy = haveClickedBook;
      });
    }
    if (isFirstTime) {
      setState(() {
        showFirstOverlay = true;
        showSecondOverlay = false;
      });
      // Set isFirstTime to false after showing overlay
      await prefs.setBool('isFirstTime', false);
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await _googleSignIn.disconnect();
  }

  void deleteAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var tokens = prefs.getString('token')!;
    var response = await http.get(
      Uri.parse('${dotenv.get("API_SERVER")}auth/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $tokens',
      },
    );
    if (response.statusCode == 200) {
      logout();
    }
  }

  void pointFunction() {
    // AppBar 아이콘 클릭
  }

  Future<void> saveRewardStatus() async {
    DateTime currentTime = DateTime.now();

    formattedTime = DateFormat('yyyy-MM-dd').format(currentTime);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('availableGetPoint') == null) {
      // 첫사용자인 경우
      prefs.setInt('availableGetPoint', 1); // 1일차 포인트를 받을 수 있음
      availableGetPoint = 1;
    } else {
      availableGetPoint = prefs.getInt('availableGetPoint')!;
    }

    if (prefs.getString('lastPointYMD') == null) {
      // 내가 마지막으로 받은 날짜
      prefs.setString('lastPointYMD', ''); //
      lastPointYMD = '';
    } else {
      lastPointYMD = prefs.getString('lastPointYMD')!;
    }
    if (prefs.getInt('lastPointDay') == null) {
      // 내가 마지막으로 받은 일차
      prefs.setInt('lastPointDay', 0); // 일차
      lastPointDay = 0;
    } else {
      lastPointDay = prefs.getInt('lastPointDay')!;
    }
  }

  bool openCalendar = false;

  void _openCalendarFunc() async {
    print(token);
    setState(() {
      showSecondOverlay = false;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime currentTime = DateTime.now();
    formattedTime = DateFormat('yyyy-MM-dd').format(currentTime);
    lastPointYMD = prefs.getString('lastPointYMD')!;
    availableGetPoint = prefs.getInt('availableGetPoint')!;
    // print(lastPointYMD);
    // print(formattedTime);
    if (lastPointDay == 7 && prefs.getString('lastPointYMD') != formattedTime) {
      //저장된 lastPointDay가 7이고 다음 날 들어왔으면 --> 즉 포인트 다시 리셋되어야 하면
      setState(() {
        lastPointDay = 0;
        prefs.setInt('lastPointDay', 0);
        prefs.setInt('availableGetPoint', 1);
        lastPointDay = prefs.getInt('lastPointDay')!;
        availableGetPoint = prefs.getInt('availableGetPoint')!;
      });
    }

    setState(() {
      openCalendar = true;
    });
  }

  void _closeCalendarFunc() {
    setState(() {
      openCalendar = false;
    });
  }

  Future<String> plusPoint(int plusPoint) async {
    final url = '${dotenv.get("API_SERVER")}point/plus';
    final response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'point': plusPoint + 0}));
    if (response.statusCode == 200) {
      // UserCubit().fetchUser();
      context.read<UserCubit>().fetchUser();
      return response.statusCode.toString();
    } else if (response.statusCode == 400) {
      return json.decode(response.body)[0].toString();
    } else {
      throw Exception('Failed to fetch data');
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

    final userState = userCubit.state;
    final dataRepository = RepositoryProvider.of<DataRepository>(context);

    SizeConfig().init(context);
    _sendHomeViewEvent();

    return BlocProvider(
        create: (context) =>
            dataCubit..loadHomeBookData(), // DataCubit 생성 및 데이터 로드
        // child: DataList(
        //   record:
        //   purchase:
        // ),
        //final userCubit = context.watch<UserCubit>();
        //final userState = userCubit.state;
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
                child: Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: const Color.fromARGB(255, 255, 169, 26),
                    size: SizeConfig.defaultSize! * 10,
                  ),
                ),
              );
            } else {
              return Scaffold(
                key: _scaffoldKey,
                drawer: SizedBox(
                  width: 33 * SizeConfig.defaultSize!,
                  child: _Drawer(userState, userCubit, context),
                ),
                body: Stack(children: [
                  if (openCalendar)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _openCalendarFunc,
                        child: Container(
                          color: const Color.fromARGB(255, 251, 251, 251)
                              .withOpacity(0.5), // 반투명 배경색 설정
                        ),
                      ),
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('lib/images/bkground.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      top: false,
                      minimum: EdgeInsets.only(
                          left: 2 * SizeConfig.defaultSize!,
                          right: 2 * SizeConfig.defaultSize!),
                      child: Column(
                        children: [
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
                                Positioned(
                                  //left: 20,
                                  top: SizeConfig.defaultSize! * 2,
                                  child: InkWell(
                                    onTap: () {
                                      userCubit.fetchUser();

                                      _sendHbgClickEvent();
                                      _scaffoldKey.currentState?.openDrawer();
                                      userCubit.fetchUser();
                                    },
                                    child: Image.asset(
                                      'lib/images/hamburger.png',
                                      width: 3.5 *
                                          SizeConfig.defaultSize!, // 이미지의 폭 설정
                                      height: 3.5 *
                                          SizeConfig.defaultSize!, // 이미지의 높이 설정
                                    ),
                                  ),
                                ),
                                userState.purchase // 구독이면 캘린더 보여주지 않음
                                    ? Container()
                                    : Positioned(
                                        right: SizeConfig.defaultSize! * 12,
                                        top: SizeConfig.defaultSize! * 2,
                                        child: InkWell(
                                          onTap: () {
                                            lastPointYMD == formattedTime
                                                ? _sendCalClickEvent(
                                                    userState.point,
                                                    availableGetPoint,
                                                    'Already Claimed')
                                                : _sendCalClickEvent(
                                                    userState.point,
                                                    availableGetPoint,
                                                    'Not Claimed Yet');
                                            _openCalendarFunc();
                                          },
                                          child: Image.asset(
                                            'lib/images/calendar.png',
                                            width: 4.7 *
                                                SizeConfig
                                                    .defaultSize!, // 이미지의 폭 설정
                                            height: 4.7 *
                                                SizeConfig
                                                    .defaultSize!, // 이미지의 높이 설정
                                          ),
                                        ),
                                      ),
                                userState.purchase
                                    ? Container()
                                    : Positioned(
                                        //구독이면 포인트 보여주지 않음
                                        top: 2.2 * SizeConfig.defaultSize!,
                                        right: 1 * SizeConfig.defaultSize!,
                                        child: Stack(children: [
                                          GestureDetector(
                                            onTap: () {
                                              _sendHomePointClickEvent(
                                                  userState.point);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Purchase()),
                                              );
                                            },
                                            child: Container(
                                              width:
                                                  10 * SizeConfig.defaultSize!,
                                              height:
                                                  4 * SizeConfig.defaultSize!,
                                              decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                      128, 255, 255, 255),
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(SizeConfig
                                                              .defaultSize! *
                                                          1))),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width: 0.5 *
                                                          SizeConfig
                                                              .defaultSize!,
                                                    ),
                                                    SizedBox(
                                                        width: 2 *
                                                            SizeConfig
                                                                .defaultSize!,
                                                        child: Image.asset(
                                                            'lib/images/oneCoin.png')),
                                                    Container(
                                                      width: 7 *
                                                          SizeConfig
                                                              .defaultSize!,
                                                      alignment:
                                                          Alignment.center,
                                                      // decoration: BoxDecoration(color: Colors.blue),
                                                      child: Text(
                                                        '${userState.point + 0}',
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'lilita',
                                                            fontSize: SizeConfig
                                                                    .defaultSize! *
                                                                2),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    )
                                                  ]),
                                            ),
                                          ),
                                        ]),
                                      ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: SizeConfig.defaultSize!.toInt() * 4,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: SizeConfig.defaultSize! * 30,
                                    child: BlocProvider(
                                      create: (context) => dataCubit
                                        ..loadHomeBookData(), // DataCubit 생성 및 데이터 로드
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: state.length,
                                        //  itemCount: 4,
                                        itemBuilder: (context, index) {
                                          var book = state[index];
                                          return GestureDetector(
                                            onTap: () async {
                                              _sendBookClickEvent(book.id);
                                              SharedPreferences prefs =
                                                  await SharedPreferences
                                                      .getInstance();
                                              await prefs.setBool(
                                                  'haveClickedBook', true);
                                              setState(() {
                                                showFairy = true;
                                              });
                                              // showFairy = true;
                                              // print(showFairy);
                                              // --------
                                              // userState.purchase == true ||
                                              //         book.lock == false ||
                                              //         (book.title ==
                                              //                 'Snow White and the Seven Dwarfs' ||
                                              //             book.title ==
                                              //                 'The Little Match Girl') // 구독자인지 확인하기 and 포인트로 푼 책인지 확인하기
                                              //     ?
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder:
                                                        (context) =>
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
                                                              child: BookIntro(
                                                                title:
                                                                    book.title,
                                                                thumb: book
                                                                    .thumbUrl,
                                                                id: book.id,
                                                                summary: book
                                                                    .summary,
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
                                            child: book.lock &&
                                                    !userState.purchase
                                                // 사용자가 포인트로 책을 풀었거나, 무료 공개 책이면 lock 해제
                                                ? lockedBook(book)
                                                : unlockedBook(book), //구독자아님
                                          );
                                        },
                                        separatorBuilder: (context, index) =>
                                            SizedBox(
                                                width: 2 *
                                                    SizeConfig.defaultSize!),
                                      ),
                                    ),
                                  ), //첫 줄 종료
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
                  //         child: const Text('YES'),
                  //       ),
                  //       TextButton(
                  //         onPressed: () {
                  //           // 1초 후에 다음 페이지로 이동
                  //           setState(() {
                  //             wantDelete = false;
                  //           });
                  //         },
                  //         child: const Text('No'),
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
                  GestureDetector(
                      onTap: () {
                        _sendHomeFirstClickEvent();
                        setState(() {
                          // Toggle the value of showOverlay when the overlay is tapped
                          showFirstOverlay = false;
                          showSecondOverlay = true;
                        });
                        // OneSignal.Notifications.requestPermission(true);
                      },
                      child: Stack(children: [
                        Visibility(
                          visible: showFirstOverlay, // 첫번째 온보딩화면
                          child: Stack(
                            children: [
                              Container(
                                color: Colors.white.withOpacity(0.6),
                              ),
                              SafeArea(
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: SizeConfig.defaultSize!.toInt(),
                                      child: Container(),
                                    ),
                                    Expanded(
                                        flex:
                                            SizeConfig.defaultSize!.toInt() * 2,
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              left: SizeConfig.defaultSize!,
                                              right: SizeConfig.defaultSize!,
                                              // top: SizeConfig.defaultSize! * 10,
                                              // 안내 글씨
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: TextButton(
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        MaterialStateProperty
                                                            .all<Color>(
                                                      const Color.fromARGB(
                                                          255, 255, 169, 26),
                                                    ),
                                                    padding:
                                                        MaterialStateProperty.all<
                                                            EdgeInsetsGeometry>(
                                                      EdgeInsets.symmetric(
                                                        vertical: SizeConfig
                                                                .defaultSize! *
                                                            2.1, // 수직 방향 패딩
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: null,
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                          width: SizeConfig
                                                                  .defaultSize! *
                                                              11),
                                                      Text(
                                                        'Hello, Welcome to LOVEL! \nHere, you can discover free books to read and 4,500 points that can \nunlock premium books. Please click on a book you like and start reading!',
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Molengo',
                                                            color: Colors.black,
                                                            fontSize: SizeConfig
                                                                    .defaultSize! *
                                                                2),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: SizeConfig.defaultSize! * 0,
                                              bottom:
                                                  SizeConfig.defaultSize! * 6.8,
                                              child: Image.asset(
                                                'lib/images/fairy.png',
                                                width: SizeConfig.defaultSize! *
                                                    17,
                                              ),
                                            ),
                                            Positioned(
                                              left:
                                                  SizeConfig.defaultSize! * 42,
                                              top: SizeConfig.defaultSize! * 2,
                                              child: Image.asset(
                                                'lib/images/overlayClick.png',
                                                width: SizeConfig.defaultSize! *
                                                    10,
                                              ),
                                            ),
                                          ],
                                        )),
                                    Expanded(
                                      flex: 1,
                                      child: Container(),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ])),
                  GestureDetector(
                    onTap: () {
                      _sendHomeCalTooltipClickEvent();
                      // _sendHomeSecondClickEvent();
                      _openCalendarFunc();
                      setState(() {
                        showSecondOverlay = false;
                      });
                    },
                    child: Stack(children: [
                      SafeArea(
                          minimum: EdgeInsets.only(
                            left: 3 * SizeConfig.defaultSize!,
                            right: 3 * SizeConfig.defaultSize!,
                          ),
                          child: Visibility(
                            visible: !showFirstOverlay &&
                                showSecondOverlay, // 두번째 온보딩화면(캘린더 가르키기)
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 5 * SizeConfig.defaultSize!,
                                  top: 6.5 * SizeConfig.defaultSize!,
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.asset(
                                          'lib/images/textOrangeBubble.png',
                                          width: SizeConfig.defaultSize! * 27,
                                        ),
                                        Container(
                                          padding: EdgeInsets.only(
                                              top:
                                                  SizeConfig.defaultSize! * 1.2,
                                              right: SizeConfig.defaultSize! *
                                                  0.8),
                                          child: Text(
                                            'You can earn points\nthrough attendance checks!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontFamily: 'Molengo',
                                                fontSize:
                                                    SizeConfig.defaultSize! *
                                                        2),
                                          ),
                                        )
                                      ]),
                                ),
                              ],
                            ),
                          )),
                    ]),
                  ),
                  if (openCalendar)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _openCalendarFunc,
                        child: Stack(children: [
                          Container(
                            color: const Color.fromARGB(255, 251, 251, 251)
                                .withOpacity(0.5), // 반투명 배경색 설정
                          ),
                          Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 55 * SizeConfig.defaultSize!,
                                height: 35 * SizeConfig.defaultSize!,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            SizeConfig.defaultSize!)),
                                    color:
                                        const Color.fromARGB(255, 255, 255, 255)
                                            .withOpacity(1),
                                  ),
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: SizeConfig.defaultSize! * 4.5,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(
                                                  SizeConfig.defaultSize!),
                                              topLeft: Radius.circular(
                                                  SizeConfig.defaultSize!)),
                                          color: const Color.fromARGB(
                                              255, 255, 167, 26),
                                        ),
                                      ),
                                      Padding(
                                        //첫줄가로
                                        padding: EdgeInsets.only(
                                          top: SizeConfig.defaultSize! * 0.9,
                                          left: SizeConfig.defaultSize! * 1.5,
                                        ),
                                        child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                              'Attend daily and claim your rewards!',
                                              style: TextStyle(
                                                fontFamily: 'Molengo',
                                                fontSize: 2.2 *
                                                    SizeConfig.defaultSize!,
                                              ),
                                            )),
                                      ),
                                      Padding(
                                        //첫줄가로
                                        padding: EdgeInsets.only(
                                            top: SizeConfig.defaultSize! * 0.8,
                                            right:
                                                SizeConfig.defaultSize! * 1.5),
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: GestureDetector(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: SizeConfig
                                                            .defaultSize! *
                                                        1.5,
                                                    bottom: SizeConfig
                                                            .defaultSize! *
                                                        1.5),
                                                child: Icon(Icons.clear,
                                                    size: 3 *
                                                        SizeConfig
                                                            .defaultSize!),
                                              ),
                                              onTap: () {
                                                _sendCalXClickEvent(
                                                    userState.point);
                                                _closeCalendarFunc();
                                              }),
                                        ),
                                      ),
                                      Padding(
                                        //첫번째줄가로
                                        padding: EdgeInsets.only(
                                            left: SizeConfig.defaultSize! * 6,
                                            top: SizeConfig.defaultSize! * 11),
                                        child: Container(
                                          height: SizeConfig.defaultSize! * 0.5,
                                          width: SizeConfig.defaultSize! * 30,
                                          color: const Color.fromARGB(
                                              255, 204, 165, 107),
                                        ),
                                      ),
                                      Padding(
                                        //두번째줄가로
                                        padding: EdgeInsets.only(
                                            left: SizeConfig.defaultSize! * 6,
                                            top: SizeConfig.defaultSize! * 17),
                                        child: Container(
                                          height: SizeConfig.defaultSize! * 0.5,
                                          width: SizeConfig.defaultSize! * 30,
                                          color: const Color.fromARGB(
                                              255, 204, 165, 107),
                                        ),
                                      ),
                                      Padding(
                                        //두번째줄세로
                                        padding: EdgeInsets.only(
                                            left: SizeConfig.defaultSize! * 36,
                                            top: SizeConfig.defaultSize! * 10),
                                        child: Container(
                                          width: SizeConfig.defaultSize! * 0.5,
                                          height: SizeConfig.defaultSize! * 7.5,
                                          color: const Color.fromARGB(
                                              255, 204, 165, 107),
                                        ),
                                      ),
                                      Padding(
                                        //두번째줄세로
                                        padding: EdgeInsets.only(
                                            left: SizeConfig.defaultSize! * 6,
                                            top: SizeConfig.defaultSize! * 17),
                                        child: Container(
                                          width: SizeConfig.defaultSize! * 0.5,
                                          height: SizeConfig.defaultSize! * 7,
                                          color: const Color.fromARGB(
                                              255, 204, 165, 107),
                                        ),
                                      ),
                                      Padding(
                                        //세번째줄가로
                                        padding: EdgeInsets.only(
                                            left: SizeConfig.defaultSize! * 6,
                                            top:
                                                SizeConfig.defaultSize! * 23.2),
                                        child: Container(
                                          height: SizeConfig.defaultSize! * 0.5,
                                          width: SizeConfig.defaultSize! * 40,
                                          color: const Color.fromARGB(
                                              255, 204, 165, 107),
                                        ),
                                      ), //선 끝
                                      //1일차
                                      eachDayPoint(
                                          top: 6,
                                          left: 3,
                                          coinImage: 'lib/images/oneCoin.png',
                                          compare: 1,
                                          height: 10,
                                          point: '100',
                                          topPadding: 0.5,
                                          lastPointYMD: lastPointYMD),
                                      //2일차
                                      eachDayPoint(
                                          top: 6,
                                          left: 16,
                                          coinImage: 'lib/images/oneCoin.png',
                                          compare: 2,
                                          height: 10,
                                          point: '100',
                                          topPadding: 0.5,
                                          lastPointYMD: lastPointYMD),
                                      //3일차
                                      eachDayPoint(
                                          top: 6,
                                          left: 29,
                                          coinImage:
                                              'lib/images/threeCoins.png',
                                          compare: 3,
                                          height: 10,
                                          point: '300',
                                          topPadding: 0.5,
                                          lastPointYMD: lastPointYMD),
                                      eachDayPoint(
                                          // 4일차
                                          top: 18,
                                          left: 3,
                                          coinImage: 'lib/images/oneCoin.png',
                                          compare: 4,
                                          height: 10,
                                          point: '100',
                                          topPadding: 0.5,
                                          lastPointYMD: lastPointYMD),
                                      eachDayPoint(
                                          // 5일차
                                          top: 18,
                                          left: 16,
                                          coinImage: 'lib/images/oneCoin.png',
                                          compare: 5,
                                          height: 10,
                                          point: '100',
                                          topPadding: 0.5,
                                          lastPointYMD: lastPointYMD),
                                      eachDayPoint(
                                          // 6일차
                                          top: 18,
                                          left: 29,
                                          coinImage:
                                              'lib/images/threeCoins.png',
                                          compare: 6,
                                          height: 10,
                                          point: '300',
                                          topPadding: 0.5,
                                          lastPointYMD: lastPointYMD),
                                      // 7일차
                                      eachDayPoint(
                                          // 6일차
                                          top: 6,
                                          left: 42,
                                          coinImage: 'lib/images/treasure.png',
                                          compare: 7,
                                          height: 22,
                                          point: '1000',
                                          topPadding: 6.5,
                                          lastPointYMD: lastPointYMD),
                                      Container(
                                        padding: EdgeInsets.only(
                                          // top: SizeConfig.defaultSize! * 1,
                                          bottom: SizeConfig.defaultSize! * 0.9,
                                        ),
                                        // left: SizeConfig.defaultSize! * 19),
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: TextButton(
                                            style: ButtonStyle(
                                              shape: MaterialStateProperty.all<
                                                      RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0.3 * sh))),
                                              padding: MaterialStatePropertyAll(
                                                  EdgeInsets.only(
                                                      right: SizeConfig
                                                              .defaultSize! *
                                                          4,
                                                      left: SizeConfig
                                                              .defaultSize! *
                                                          4,
                                                      top: 0.018 * sh,
                                                      bottom: 0.018 * sh)),
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(
                                                const Color.fromARGB(
                                                    255, 255, 169, 26),
                                              ), // 배경색 설정
                                            ),
                                            onPressed: () async {
                                              _sendCalClaimClickEvent(
                                                  userState.point);
                                              SharedPreferences prefs =
                                                  await SharedPreferences
                                                      .getInstance();
                                              DateTime currentDate =
                                                  DateTime.now();
                                              String formattedDate =
                                                  DateFormat('yyyy-MM-dd')
                                                      .format(currentDate);
                                              int tmp = prefs
                                                  .getInt('availableGetPoint')!;
                                              final scores = [
                                                100,
                                                100,
                                                300,
                                                100,
                                                100,
                                                300,
                                                1000
                                              ];
                                              // 포인트 증가 & 큐빗 반영

                                              print(
                                                  '다음 받을 수 있는 일차 $tmp'); // 다음날 받을 수 있는
                                              // print(
                                              //     '다음 날 받게 될 포인트 점수 ${scores[availableGetPoint - 1]}');
                                              print(
                                                  '마지막으로 받은 일차 $lastPointDay ');
                                              print('현재 날짜 $formattedDate');
                                              print(
                                                  '마지막으로 받은 시간 ${prefs.getString('lastPointYMD')}');

                                              if (formattedDate !=
                                                      prefs.getString(
                                                          'lastPointYMD') &&
                                                  tmp != lastPointDay &&
                                                  availableGetPoint != 1) {
                                                // 지금 접속한 날짜와 마지막으로 포인트 받은 날짜가 동일하면 아무것도 일어나지 않는다
                                                // 다를 경우에만 변화가 생긴다
                                                // 포인트를 이미 받지 않은 상태여야 한다
                                                setState(() {
                                                  if (lastPointDay + 1 != 8) {
                                                    lastPointDay += 1;
                                                    lastPointYMD =
                                                        formattedDate;

                                                    prefs.setInt(
                                                        'availableGetPoint',
                                                        tmp + 1);
                                                    prefs.setString(
                                                        'lastPointYMD',
                                                        formattedDate); // 시간 현재 시간으로 업데이트
                                                    prefs.setInt('lastPointDay',
                                                        lastPointDay);
                                                    _sendCalClaimSuccessEvent(
                                                        userState.point,
                                                        lastPointDay,
                                                        scores[
                                                            lastPointDay - 1]);
                                                    plusPoint(scores[
                                                        lastPointDay - 1]);
                                                  } else {
                                                    // 7일차가 되려고 하면
                                                  }
                                                });
                                              }
                                              if (availableGetPoint == 1) {
                                                // 1일차를 받아야 하는 사용자일 때만 적용됨
                                                // 처음 접속한 사용자인 경우
                                                prefs.setInt(
                                                    'availableGetPoint',
                                                    2); // 다음에 받을 수 있는 건 2일차 포인트
                                                prefs.setString('lastPointYMD',
                                                    formattedDate); // 받은 날짜 저장
                                                prefs.setInt('lastPointDay', 1);
                                                availableGetPoint = 2;
                                                setState(() {
                                                  plusPoint(scores[0]);
                                                  _sendCalClaimSuccessEvent(
                                                      userState.point,
                                                      1,
                                                      scores[0]);
                                                  lastPointYMD = formattedDate;
                                                  lastPointDay = 1;
                                                  availableGetPoint = 2;
                                                });
                                              }
                                              if (OneSignal.Notifications
                                                      .permission !=
                                                  true) {
                                                OneSignal.Notifications
                                                    .requestPermission(true);
                                              }
                                              // print(lastPointDay);
                                              // print(availableGetPoint);
                                              // print(formattedDate);
                                            },
                                            child: Text(
                                              'CLAIM NOW',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize:
                                                      SizeConfig.defaultSize! *
                                                          2.2,
                                                  fontFamily: 'Lilita'),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )),
                        ]),
                      ),
                    ),
                ]
                    //   ),
                    ),
              );
            }
          },
        ));
  }

  Padding eachDayPoint({
    top,
    left,
    coinImage,
    compare,
    height,
    point,
    topPadding,
    lastPointYMD,
  }) {
    // print(lastPointYMD +
    //     formattedTime +
    //     compare.toString() +
    //     availableGetPoint.toString());
    return Padding(
      padding: EdgeInsets.only(
          top: SizeConfig.defaultSize! * top,
          left: SizeConfig.defaultSize! * left),
      child: Stack(children: [
        Container(
          width: SizeConfig.defaultSize! * 10.5,
          height: SizeConfig.defaultSize! * (height + 0.5),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: lastPointYMD != formattedTime &&
                          compare == availableGetPoint
                      ? [const Color(0xFFFEEC9A), const Color(0xFFF39E09)]
                      : [
                          const Color.fromARGB(255, 222, 220, 220),
                          const Color.fromARGB(255, 222, 220, 220)
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.all(Radius.circular(15))),
        ),
        Positioned(
            top: SizeConfig.defaultSize! * 0.75,
            left: SizeConfig.defaultSize! * 0.75,
            child: Container(
              width: SizeConfig.defaultSize! * 9,
              height: SizeConfig.defaultSize! * (height - 1),
              decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 222, 220, 220),
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Padding(
                padding: EdgeInsets.only(
                    top: SizeConfig.defaultSize! * topPadding,
                    bottom: compare != 7 ? SizeConfig.defaultSize! * 0 : 0),
                child: Stack(alignment: Alignment.topCenter, children: [
                  Image.asset(
                    coinImage,
                    height: SizeConfig.defaultSize! * 6,
                  ),
                  lastPointDay >= compare
                      ? Image.asset(
                          'lib/images/completed.png',
                          width: SizeConfig.defaultSize! * 8,
                        )
                      : Container(),
                  Align(
                    alignment: compare != 7
                        ? Alignment.bottomCenter
                        : Alignment.center,
                    child: Text(
                      point,
                      style: TextStyle(
                          fontFamily: 'Lilita',
                          fontSize: SizeConfig.defaultSize! * 1.9),
                    ),
                  ),
                ]),
              ),
            ))
      ]),
    );
  }

  Drawer _Drawer(
      UserState userState, UserCubit userCubit, BuildContext context) {
    return Drawer(
        child: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/images/bkground.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
              width: 30 * SizeConfig.defaultSize!,
              height: 11 * SizeConfig.defaultSize!,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5)),
              child: SafeArea(
                minimum: EdgeInsets.only(
                  left: 3 * SizeConfig.defaultSize!,
                  //right: 3 * SizeConfig.defaultSize!,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.defaultSize! * 3),
                    Text(
                      ' Welcome! ',
                      style: TextStyle(
                          fontSize: SizeConfig.defaultSize! * 1.8,
                          fontFamily: 'Molengo'),
                    ),
                    SizedBox(height: SizeConfig.defaultSize!),
                    Padding(
                      padding:
                          EdgeInsets.only(left: SizeConfig.defaultSize! * 1),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: SizeConfig.defaultSize! * 2.3,
                          ),
                          SizedBox(
                            width: SizeConfig.defaultSize! * 0.5,
                          ),
                          Text(
                            userState.userName,
                            style: TextStyle(
                                fontSize: SizeConfig.defaultSize! * 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
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
                        height: 2 * SizeConfig.defaultSize!,
                      ),
                      Text(
                        'Voice Profile',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 1.8 * SizeConfig.defaultSize!,
                          fontFamily: 'Molengo',
                          fontWeight: FontWeight.w400,
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
                                          color: Colors.white.withOpacity(0.5),
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
                                        child: Image.asset(
                                          'lib/images/icons/${userState.voiceIcon}-c.png',
                                          height: SizeConfig.defaultSize! * 8,
                                        )),
                                    Positioned(
                                      left: 9.5 * SizeConfig.defaultSize!,
                                      top: 2.3 * SizeConfig.defaultSize!,
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
                                    Positioned(
                                      left: 10.2 * SizeConfig.defaultSize!,
                                      top: 6 * SizeConfig.defaultSize!,
                                      child: GestureDetector(
                                          onTap: () {
                                            userCubit.fetchUser();
                                            _sendHbgVoiceClickEvent();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const VoiceProfile(),
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
                                                  child: Text(
                                                'Edit this voice',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 1.4 *
                                                      SizeConfig.defaultSize!,
                                                  fontFamily: 'Molengo',
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              )))),
                                    )
                                  ],
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                _sendHbgAddVoiceClickEvent();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => userState.purchase
                                        ? const RecInfo()
                                        : const Purchase(),
                                  ),
                                );
                              },
                              child: Container(
                                  width: 27 * SizeConfig.defaultSize!,
                                  height: 4 * SizeConfig.defaultSize!,
                                  decoration: ShapeDecoration(
                                    color: Colors.white.withOpacity(0.5),
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
                        height: 2 * SizeConfig.defaultSize!,
                      ),
                      // 친구에게 string 공유
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding:
                              EdgeInsets.all(0.5 * SizeConfig.defaultSize!),
                          child: Text(
                            'Invite Friends',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 1.8 * SizeConfig.defaultSize!,
                              fontFamily: 'Molengo',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        onTap: () async {
                          final result = await Share.shareWithResult(
                              "LOVEL - Fairy Tales with Voice\n📚 Read Fairy tales with your voice 🦄\n\nPlayStore : https://play.google.com/store/apps/details?id=com.sayit.yoggo\n\nAppStore : https://apps.apple.com/us/app/LOVEL/id6454792622");

                          if (result.status == ShareResultStatus.success) {
                            print('Thank you for sharing our application!');
                          }
                        },
                      ),

                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding:
                              EdgeInsets.all(0.5 * SizeConfig.defaultSize!),
                          child: Text(
                            Platform.isAndroid
                                ? 'Rate on PlayStore'
                                : 'Rate on AppStore',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 1.8 * SizeConfig.defaultSize!,
                              fontFamily: 'Molengo',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        onTap: () async {
                          final InAppReview inAppReview = InAppReview.instance;

                          if (await inAppReview.isAvailable()) {
                            print('available');
                            Platform.isIOS
                                ? inAppReview.requestReview()
                                : inAppReview.openStoreListing();
                          }
                        },
                      )
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
            height: SizeConfig.defaultSize! * 22,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(children: [
                  Container(
                    width: SizeConfig.defaultSize! * 22,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  CachedNetworkImage(
                    imageUrl: book.thumbUrl,
                  ),
                ])),
          ),
        ),
        SizedBox(
          height: SizeConfig.defaultSize! * 1,
        ),
        SizedBox(
          width: SizeConfig.defaultSize! * 20,
          child: Text(
            book.title,
            style: TextStyle(
              fontFamily: 'GenBkBasR',
              fontSize: SizeConfig.defaultSize! * 2,
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
            height: SizeConfig.defaultSize! * 22,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(children: [
                CachedNetworkImage(
                  imageUrl: book.thumbUrl,
                ),
                Container(
                  width: SizeConfig.defaultSize! * 22,
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
                        width: SizeConfig.defaultSize! * 6,
                      )),
                )
              ]),
            ),
          ),
        ),
        SizedBox(
          height: SizeConfig.defaultSize! * 1,
        ),
        SizedBox(
          width: SizeConfig.defaultSize! * 20,
          child: Text(
            book.title,
            style: TextStyle(
              fontFamily: 'GenBkBasR',
              fontSize: SizeConfig.defaultSize! * 2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
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

  Future<void> _sendCalClaimClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'cal_claim_click',
        parameters: <String, dynamic>{'point_now': pointNow},
      );
      await amplitude.logEvent(
        'cal_claim_click',
        eventProperties: {'point_now': pointNow},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendCalClaimSuccessEvent(pointNow, dayNow, pointGet) async {
    try {
      // 이벤트 로깅
      await analytics
          .logEvent(name: 'cal_claim_success', parameters: <String, dynamic>{
        'point_now': pointNow,
        'day_now': dayNow,
      });
      await amplitude.logEvent(
        'cal_claim_success',
        eventProperties: {
          'point_now': pointNow,
          'day_now': dayNow,
          'point_get': pointGet
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendCalXClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'cal_x_click',
        parameters: <String, dynamic>{'point_now': pointNow},
      );
      await amplitude.logEvent(
        'cal_x_click',
        eventProperties: {'point_now': pointNow},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendCalClickEvent(pointNow, dayNow, alreadyClaimed) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'cal_click',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'day_now': dayNow,
          'already_claimed': alreadyClaimed
        },
      );
      await amplitude.logEvent(
        'cal_click',
        eventProperties: {
          'point_now': pointNow,
          'day_now': dayNow,
          'already_claimed': alreadyClaimed
        },
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
}
