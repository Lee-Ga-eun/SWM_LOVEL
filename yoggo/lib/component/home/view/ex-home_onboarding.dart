// import 'dart:io';

// import 'package:audioplayers/audioplayers.dart';
// import 'package:firebase_remote_config/firebase_remote_config.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// import 'package:amplitude_flutter/amplitude.dart';
// import 'package:flutter/material.dart';
// import 'package:in_app_review/in_app_review.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:yoggo/component/bookIntro/view/ex-book_intro_onboarding.dart';
// import 'package:yoggo/component/home/viewModel/home_dummy_model.dart';

// import 'package:yoggo/size_config.dart';
// import 'dart:async';

// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../Repositories/Repository.dart';
// import '../../bookIntro/viewModel/book_intro_cubit.dart';
// import '../../bookIntro/viewModel/book_voice_cubit.dart';
// import '../../notice/view/notice.dart';
// import '../../voice.dart';
// import '../viewModel/home_screen_cubit.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import '../../globalCubit/user/user_cubit.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'dart:convert';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

// class HomeOnboarding extends StatefulWidget {
//   final AudioPlayer bgmPlayer;
//   const HomeOnboarding({Key? key, required this.bgmPlayer}) : super(key: key);

//   @override
//   _HomeOnboardingState createState() => _HomeOnboardingState();
// }

// class _HomeOnboardingState extends State<HomeOnboarding> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   late String token;
//   late int userId;
//   bool wantDelete = false;
//   double dropdownHeight = 0.0;
//   // @override
//   // void didChangeDependencies() {
//   //   super.didChangeDependencies();
//   // }

//   @override
//   void initState() {
//     super.initState();
//     getToken(); // 앱 최초 사용 접속 : 온보딩 화면 보여주기
//   }

//   static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

//   static Amplitude amplitude = Amplitude.getInstance();

//   Future<void> getToken() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       token = prefs.getString('token')!;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     //final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
//     final userCubit = context.watch<UserCubit>();
//     final dataCubit = context.watch<DataCubit>();
//     final sw = (MediaQuery.of(context).size.width -
//         MediaQuery.of(context).padding.left -
//         MediaQuery.of(context).padding.right);
//     final sh = (MediaQuery.of(context).size.height -
//         MediaQuery.of(context).padding.top -
//         MediaQuery.of(context).padding.bottom);
//     SizeConfig().init(context);
//     final bookList = [
//       HomeDummyModel(
//           id: 5,
//           title: "Snow White and the Seven Dwarfs",
//           thumbUrl: 'lib/images/5-0.png'),
//       HomeDummyModel(
//           id: 10,
//           title: "The Sun and the Wind",
//           thumbUrl: 'lib/images/10-0.png'),
//       HomeDummyModel(
//           id: 8, title: "Puss in Boots", thumbUrl: 'lib/images/8-0.png'),
//       HomeDummyModel(
//           id: 11, title: "Trick or Treat!", thumbUrl: 'lib/images/11-0.png'),
//     ];

//     final userState = userCubit.state;
//     final dataRepository = RepositoryProvider.of<DataRepository>(context);

//     SizeConfig().init(context);
//     _sendHomeInOnboardingViewEvent();

//     return Scaffold(
//       body: Stack(children: [
//         Container(
//           decoration: const BoxDecoration(
//             color: Color(0xFFFFFAE4),
//           ),
//           child: SafeArea(
//             bottom: false,
//             top: false,
//             minimum: EdgeInsets.only(
//                 left: 2 * SizeConfig.defaultSize!,
//                 right: 2 * SizeConfig.defaultSize!),
//             child: Column(
//               children: [
//                 Expanded(
//                   flex: SizeConfig.defaultSize!.toInt(),
//                   child: Stack(
//                     alignment: Alignment.centerLeft,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'LOVEL',
//                             style: TextStyle(
//                               fontFamily: 'Modak',
//                               fontSize: SizeConfig.defaultSize! * 5,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Positioned(
//                         //left: 20,
//                         top: SizeConfig.defaultSize! * 2,
//                         child: InkWell(
//                           onTap: () {
//                             userCubit.fetchUser();

//                             _scaffoldKey.currentState?.openDrawer();
//                             userCubit.fetchUser();
//                           },
//                           child: Image.asset(
//                             'lib/images/hamburger.png',
//                             width: 3.5 * SizeConfig.defaultSize!, // 이미지의 폭 설정
//                             height: // 이미지의 높이 설정
//                                 3.5 * SizeConfig.defaultSize!,
//                             colorBlendMode: BlendMode.srcATop,
//                             color: const Color.fromARGB(153, 255, 255, 255),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         right: SizeConfig.defaultSize! * 12.5,
//                         top: SizeConfig.defaultSize! * 2,
//                         child: InkWell(
//                           onTap: () {},
//                           child: Image.asset(
//                             'lib/images/calendarOrange.png',
//                             width: 4 * SizeConfig.defaultSize!, // 이미지의 폭 설정
//                             height: 4 * SizeConfig.defaultSize!,
//                             colorBlendMode: BlendMode.srcATop,
//                             color: const Color.fromARGB(
//                                 153, 255, 255, 255), // 이미지의 높이 설정
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         //구독이면 포인트 보여주지 않음
//                         top: 2.2 * SizeConfig.defaultSize!,
//                         right: 1 * SizeConfig.defaultSize!,
//                         child: Stack(children: [
//                           Container(
//                             width: 10 * SizeConfig.defaultSize!,
//                             height: 4 * SizeConfig.defaultSize!,
//                             decoration: BoxDecoration(
//                                 color: const Color.fromARGB(128, 255, 255, 255),
//                                 borderRadius: BorderRadius.all(Radius.circular(
//                                     SizeConfig.defaultSize! * 1))),
//                             child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 children: [
//                                   SizedBox(
//                                     width: 0.5 * SizeConfig.defaultSize!,
//                                   ),
//                                   SizedBox(
//                                       width: 2 * SizeConfig.defaultSize!,
//                                       child: Image.asset(
//                                           'lib/images/oneCoin.png',
//                                           colorBlendMode: BlendMode.srcATop,
//                                           color: const Color.fromARGB(
//                                               153, 255, 255, 255))),
//                                   Container(
//                                     width: 7 * SizeConfig.defaultSize!,
//                                     alignment: Alignment.center,
//                                     // decoration: BoxDecoration(color: Colors.blue),
//                                     child: Text(
//                                       '${userState.point + 0}',
//                                       style: TextStyle(
//                                           fontFamily: 'lilita',
//                                           fontSize: SizeConfig.defaultSize! * 2,
//                                           color: Colors.grey),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   )
//                                 ]),
//                           ),
//                         ]),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   flex: SizeConfig.defaultSize!.toInt() * 4,
//                   child: SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         SizedBox(
//                           height: SizeConfig.defaultSize! * 30,
//                           child: ListView.separated(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: 4,
//                             //  itemCount: 4,
//                             itemBuilder: (context, index) {
//                               var book = bookList[index];
//                               return GestureDetector(
//                                 onTap: () async {
//                                   SharedPreferences prefs =
//                                       await SharedPreferences.getInstance();
//                                 }, //onTap 종료
//                                 child: index == 3
//                                     // 사용자가 포인트로 책을 풀었거나, 무료 공개 책이면 lock 해제
//                                     ? lockedBook(book)
//                                     : unlockedBook(book), //구독자아님
//                               );
//                             },
//                             separatorBuilder: (context, index) =>
//                                 SizedBox(width: 2 * SizeConfig.defaultSize!),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         GestureDetector(
//             onTap: () async {
//               _sendHomeFirstClickEvent();

//               _sendBookClickEvent(10);
//               widget.bgmPlayer.pause();
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => MultiBlocProvider(
//                             providers: [
//                               BlocProvider<BookVoiceCubit>(
//                                 create: (context) =>
//                                     BookVoiceCubit(dataRepository)
//                                       ..loadBookVoiceData(10),
//                               ),
//                               BlocProvider<BookIntroCubit>(
//                                 create: (context) =>
//                                     // BookIntroCubit(),
//                                     // DataCubit()..loadHomeBookData()
//                                     BookIntroCubit(dataRepository)
//                                       ..loadBookIntroData(10),
//                               )
//                             ],
//                             child: BookIntroOnboarding(
//                               id: 10,
//                               title: 'The Sun and the Wind',
//                               showOnboarding: true,
//                               bgmPlayer: widget.bgmPlayer,
//                             ))),
//               );
//             },
//             child: Stack(children: [
//               Visibility(
//                 visible: true,
//                 child: Stack(
//                   children: [
//                     Container(
//                       color: Colors.white.withOpacity(0),
//                     ),
//                     SafeArea(
//                       child: Column(
//                         children: [
//                           Expanded(
//                             flex: SizeConfig.defaultSize!.toInt(),
//                             child: Container(),
//                           ),
//                           Expanded(
//                               flex: SizeConfig.defaultSize!.toInt() * 2,
//                               child: Stack(
//                                 children: [
//                                   Positioned.fill(
//                                     left: SizeConfig.defaultSize!,
//                                     right: SizeConfig.defaultSize!,
//                                     child: Align(
//                                       alignment: Alignment.bottomCenter,
//                                       child: TextButton(
//                                         style: ButtonStyle(
//                                           backgroundColor:
//                                               MaterialStateProperty.all<Color>(
//                                             const Color.fromARGB(
//                                                 255, 255, 169, 26),
//                                           ),
//                                           padding: MaterialStateProperty.all<
//                                               EdgeInsetsGeometry>(
//                                             EdgeInsets.symmetric(
//                                               vertical:
//                                                   SizeConfig.defaultSize! *
//                                                       2, // 수직 방향 패딩
//                                             ),
//                                           ),
//                                         ),
//                                         onPressed: null,
//                                         child: Row(
//                                           children: [
//                                             SizedBox(
//                                                 width: SizeConfig.defaultSize! *
//                                                     11),
//                                             Text(
//                                               "온보딩-뉴",
//                                               style: TextStyle(
//                                                   fontFamily: 'font-basic'.tr(),
//                                                   color: Colors.black,
//                                                   fontSize:
//                                                       SizeConfig.defaultSize! *
//                                                           2),
//                                             ).tr()
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     left: SizeConfig.defaultSize! * 0,
//                                     bottom: SizeConfig.defaultSize! * 4.5,
//                                     child: Image.asset(
//                                       'lib/images/fairy.png',
//                                       width: SizeConfig.defaultSize! * 17,
//                                     ),
//                                   ),
//                                   Positioned(
//                                     left: SizeConfig.defaultSize! * 42,
//                                     top: SizeConfig.defaultSize! * 2,
//                                     child: Image.asset(
//                                       'lib/images/finger.png',
//                                       width: SizeConfig.defaultSize! * 10,
//                                     ),
//                                   ),
//                                 ],
//                               )),
//                           Expanded(
//                             flex: 1,
//                             child: Container(),
//                           )
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ])),
//       ]),
//     );
//   }

//   Column unlockedBook(HomeDummyModel book) {
//     return Column(
//       children: [
//         Container(
//           clipBehavior: Clip.hardEdge,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           height: SizeConfig.defaultSize! * 22,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: Stack(children: [
//               Container(
//                 width: SizeConfig.defaultSize! * 22,
//                 color: Colors.white.withOpacity(0.6),
//               ),
//               Image.asset(book.thumbUrl),
//               book.id != 10
//                   ? Container(
//                       width: SizeConfig.defaultSize! * 22,
//                       color: Colors.white.withOpacity(0.6),
//                     )
//                   : Container()
//             ]),
//           ),
//         ),
//         SizedBox(
//           height: SizeConfig.defaultSize! * 1,
//         ),
//         SizedBox(
//           width: SizeConfig.defaultSize! * 20,
//           child: Text(
//             book.title,
//             style: TextStyle(
//               fontFamily: 'GenBkBasR',
//               fontSize: SizeConfig.defaultSize! * 2,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 2,
//           ),
//         ),
//       ],
//     );
//   }

//   Column lockedBook(HomeDummyModel book) {
//     return Column(
//       children: [
//         Hero(
//           tag: book.id,
//           child: Container(
//             clipBehavior: Clip.hardEdge,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             height: SizeConfig.defaultSize! * 22,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Stack(children: [
//                 Image.asset(book.thumbUrl),

//                 // CachedNetworkImage(
//                 //   imageUrl: book.thumbUrl,
//                 // ),
//                 Container(
//                   width: SizeConfig.defaultSize! * 22,
//                   color: Colors.white.withOpacity(0.6),
//                 ),
//                 Align(
//                   alignment: Alignment.topLeft,
//                   child: Padding(
//                       padding: EdgeInsets.only(
//                           left: SizeConfig.defaultSize! * 0.5,
//                           top: SizeConfig.defaultSize! * 0.5),
//                       child: Image.asset(
//                         'lib/images/locked.png',
//                         width: SizeConfig.defaultSize! * 6,
//                       )),
//                 ),
//                 book.id != 10
//                     ? Container(
//                         width: SizeConfig.defaultSize! * 22,
//                         color: Colors.white.withOpacity(0.6),
//                       )
//                     : Container()

//                 // CachedNetworkIma
//               ]),
//             ),
//           ),
//         ),
//         SizedBox(
//           height: SizeConfig.defaultSize! * 1,
//         ),
//         SizedBox(
//           width: SizeConfig.defaultSize! * 20,
//           child: Text(
//             book.title,
//             style: TextStyle(
//               fontFamily: 'GenBkBasR',
//               fontSize: SizeConfig.defaultSize! * 2,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 2,
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _sendHomeInOnboardingViewEvent() async {
//     try {
//       // 이벤트 로깅
//       await analytics.logEvent(
//         name: 'home_in_onboarding_view',
//         parameters: <String, dynamic>{},
//       );
//       await amplitude.logEvent(
//         'home_in_onboarding_view',
//         eventProperties: {},
//       );
//     } catch (e) {
//       print('Failed to log event: $e');
//     }
//   }

//   Future<void> _sendBookClickEvent(contentId) async {
//     try {
//       // 이벤트 로깅
//       await analytics.logEvent(
//         name: 'book_click',
//         parameters: <String, dynamic>{
//           'contentId': contentId,
//         },
//       );
//       await amplitude.logEvent(
//         'book_click',
//         eventProperties: {
//           'contentId': contentId,
//         },
//       );
//     } catch (e) {
//       print('Failed to log event: $e');
//     }
//   }

//   Future<void> _sendHomeFirstClickEvent() async {
//     try {
//       // 이벤트 로깅
//       await analytics.logEvent(
//         name: 'home_first_click',
//         parameters: <String, dynamic>{},
//       );
//       await amplitude.logEvent(
//         'home_first_click',
//         eventProperties: {},
//       );
//     } catch (e) {
//       print('Failed to log event: $e');
//     }
//   }
// }
