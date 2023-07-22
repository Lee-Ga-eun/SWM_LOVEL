import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yoggo/size_config.dart';
import '../../book_intro.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewModel/home_screen_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  Future<void> _sendAnalyticsEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'home_view',
        parameters: <String, dynamic>{
          //   'string': 'string',
          //   'int': 42,
          //   'long': 12345678910,
          //   'double': 42.0,
          //   'bool': true,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _sendAnalyticsEvent();
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
          bottom: false,
          top: false,
          minimum: EdgeInsets.only(left: 3 * SizeConfig.defaultSize!),
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
                  ],
                ),
              ),
              Expanded(
                flex: SizeConfig.defaultSize!.toInt() * 4,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: SizeConfig.defaultSize! * 28,
                        child: BlocProvider(
                            create: (context) => DataCubit(),
                            child: const DataList()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      //   ),
    );
  }
}

class DataList extends StatelessWidget {
  const DataList({super.key});
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static Future<void> _sendBookClickEvent(contentId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_click',
        parameters: <String, dynamic>{'contentId': contentId},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 데이터 큐빗을 가져오기.
    final dataCubit = context.watch<DataCubit>();

    // 데이터 큐빗을 통해 데이터를 로드.
    dataCubit.loadData();

    return BlocBuilder<DataCubit, List<BookModel>>(
      builder: (context, state) {
        if (state.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.length,
            itemBuilder: (context, index) {
              final book = state[index];
              return InkWell(
                onTap: () {
                  _sendBookClickEvent(book.id);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookIntro(
                          title: book.title,
                          thumb: book.thumbUrl,
                          id: book.id,
                          summary: book.summary,
                        ),
                      ));
                },
                child: Column(
                  children: [
                    Hero(
                      tag: book.id,
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10)),
                        height: SizeConfig.defaultSize! * 22,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: book.thumbUrl,
                            httpHeaders: const {
                              "User-Agent":
                                  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
                            },
                          ),
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
                            fontFamily: 'BreeSerif',
                            fontSize: SizeConfig.defaultSize! * 1.6),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) =>
                SizedBox(width: 2 * SizeConfig.defaultSize!),
          );
        }
      },
    );
  }
}

// import 'package:flutter/material.dart';
// //import 'package:yoggo/component/login_screen.dart';
// //import 'package:yoggo/component/purchase.dart';
// //import 'package:yoggo/component/record_info.dart';
// import 'package:yoggo/models/webtoon.dart';
// import 'package:yoggo/component/book_intro.dart';
// import 'package:yoggo/services/api_service.dart';
// //import 'package:google_sign_in/google_sign_in.dart';
// import 'package:yoggo/size_config.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'dart:async';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   late Future<List<bookModel>> webtoons;
//   double dropdownHeight = 0.0;
//   bool isDataFetched = false; // 데이터를 받아온 여부를 나타내는 플래그

//   @override
//   void initState() {
//     super.initState();
//     webtoons = ApiService.getTodaysToons();
//   }

//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('lib/images/bkground.png'),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: SafeArea(
//           bottom: false,
//           top: false,
//           minimum: EdgeInsets.only(left: 3 * SizeConfig.defaultSize!),
//           child: Column(
//             children: [
//               Expanded(
//                 flex: SizeConfig.defaultSize!.toInt(),
//                 child: Stack(
//                   alignment: Alignment.centerLeft,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           'LOVEL',
//                           style: TextStyle(
//                             fontFamily: 'Modak',
//                             fontSize: SizeConfig.defaultSize! * 5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 flex: SizeConfig.defaultSize!.toInt() * 4,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       SizedBox(
//                         height: SizeConfig.defaultSize! * 36,
//                         child: bookList(),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       //   ),
//     );
//   }

//   Container bookList() {
//     return Container(
//       child: FutureBuilder<List<bookModel>>(
//           future: webtoons,
//           builder: (context, snapshot) {
//             if (snapshot.hasData) {
//               return Column(
//                 children: [
//                   Expanded(
//                     child: ListView.separated(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: snapshot.data!.length,
//                       itemBuilder: (context, index) {
//                         var book = snapshot.data![index];
//                         return GestureDetector(
//                           onTap: () {
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => BookIntro(
//                                     title: book.title,
//                                     thumb: book.thumb,
//                                     id: book.id,
//                                     summary: book.summary,
//                                   ),
//                                 ));
//                           },
//                           child: Column(
//                             children: [
//                               Hero(
//                                 tag: book.id,
//                                 child: Container(
//                                   clipBehavior: Clip.hardEdge,
//                                   decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(10)),
//                                   height: SizeConfig.defaultSize! * 22,
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: CachedNetworkImage(
//                                       imageUrl: book.thumb,
//                                       httpHeaders: const {
//                                         "User-Agent":
//                                             "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(
//                                 height: SizeConfig.defaultSize! * 1,
//                               ),
//                               SizedBox(
//                                 width: SizeConfig.defaultSize! * 20,
//                                 child: Text(
//                                   book.title,
//                                   style: TextStyle(
//                                       fontFamily: 'BreeSerif',
//                                       fontSize: SizeConfig.defaultSize! * 1.6),
//                                   textAlign: TextAlign.center,
//                                   maxLines: 2,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                       separatorBuilder: (context, index) =>
//                           SizedBox(width: 2 * SizeConfig.defaultSize!),
//                     ),
//                   ),
//                 ],
//               );
//             } else {
//               return const Center(
//                 child: CircularProgressIndicator(
//                   color: Colors.orange,
//                 ),
//               );
//             }
//           }),
//     );
//   }
// }
