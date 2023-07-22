import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:yoggo/component/purchase.dart';
import 'package:yoggo/component/record_info.dart';
import '../component/reader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yoggo/size_config.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class BookIntro extends StatefulWidget {
  final String title, thumb, summary;
  final int id;
//  bool? record;
  // bool? purchase;

  const BookIntro({
    // super.key,
    Key? key,
    required this.title,
    required this.thumb,
    required this.id,
    required this.summary,
    //  this.purchase,
    // this.record,
  }) : super(key: key);

  @override
  _BookIntroState createState() => _BookIntroState();
}

class _BookIntroState extends State<BookIntro> {
  bool isSelected = true;
  bool isClicked0 = true;
  bool isClicked1 = false;
  bool isClicked2 = false;
  bool isPurchased = false;
  bool wantPurchase = false;
  bool goRecord = false;
  bool completeInference = true;
  late int inferenceId;
  late String token;
  String text = '';
  int voiceId = 10;
  //String voices='';
  List<dynamic> voices = [];
  int cvi = 0;
  bool canChanged = true;
  int lastPage = 0;
  int contentId = 1;

  Future<void> fetchPageData() async {
    final url = 'https://yoggo-server.fly.dev/content/${widget.id}';
    final response = await http.get(Uri.parse(url));
    if (mounted) {
      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);
        // print(responseData);
        Map<String, dynamic> data = responseData[0];
        voices = data['voice'];
        for (var voice in voices) {
          if (voice['voiceId'] == 1) {
            cvi = voice['contentVoiceId'];
          }
        }
        final contentText = data['voice'][0]['voiceName'];
        lastPage = data['last'];
        contentId = data['contentId'];
        setState(() {
          text = contentText;
          voiceId = data['voice'][0]['contentVoiceId'];
        });
      } else {}
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPageData();
    //getToken();
  }

  // Future<void> getToken() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     token = prefs.getString('token')!;
  //     purchaseInfo(token);
  //   });
  // }
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  Future<void> _sendVoiceClickEvent(contentVoiceId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'voice_click',
        parameters: <String, dynamic>{'contentVoiceId': contentVoiceId},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookStartClickEvent(contentVoiceId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_start_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': widget.id
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendHomeBookExitClickEvent(contentVoiceId) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'home_book_exit_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'pageId': 0,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

//구매한 사람인지, 이 책이 인퍼런스되어 있는지 확인
  Future<String> purchaseInfo(String token) async {
    var url = Uri.parse(
        'https://yoggo-server.fly.dev/user/purchaseInfo/${widget.id}');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        isPurchased = json.decode(response.body)['purchase'];
        inferenceId = json.decode(response.body)['inference'];
      });
      return response.body;
    } else {
      throw Exception('Failed to fetch data');
    }
  }

//인퍼런스 안 되어 있다면 시작하도록
  Future<void> startInference(String token) async {
    var url = Uri.parse('https://yoggo-server.fly.dev/producer/book');
    Map data = {'contentId': widget.id};
    var response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data));
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          inferenceId = json.decode(response.body)['id'];
        });
      }
    } else {
      throw Exception('Failed to start inference');
    }
  }

//인퍼런스 완료 되었는지 (ContentVoice) 확인
  Future<bool> checkInference(String token) async {
    var url = Uri.parse(
        'https://yoggo-server.fly.dev/content/inference/${widget.id}');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        completeInference = true;
      });
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // precacheImages(context);
    SizeConfig().init(context);
    if (cvi == 0) {
      return Scaffold(
        //backgroundColor: Colors.yellow, // 노란색 배경 설정
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/images/bkground.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: LoadingAnimationWidget.fourRotatingDots(
              color: Colors.white,
              size: SizeConfig.defaultSize! * 16,
            ),
          ),
          // Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Center(
          //       child: CircularProgressIndicator(
          //         backgroundColor: Colors.white,
          //         valueColor:
          //             const AlwaysStoppedAnimation<Color>(Colors.yellow),
          //         strokeWidth: 0.5 * SizeConfig.defaultSize!, // 동그라미 로딩의 크기 조정
          //       ),
          //     ),
          //     SizedBox(
          //       height: 1 * SizeConfig.defaultSize!,
          //     ),
          //     const Text('Loading a book'),
          //   ],
          // ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF1ECC9).withOpacity(1),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/images/bkground.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: SizeConfig.defaultSize!,
              top: SizeConfig.defaultSize!,
            ),
            child: SafeArea(
              bottom: false,
              top: false,
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          onPressed: () {
                            _sendHomeBookExitClickEvent(cvi);
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.white,
                            size: SizeConfig.defaultSize! * 4,
                          ),
                        )),
                  ),
                  //),

                  Expanded(
                    flex: 7,
                    child: Row(
                      children: [
                        Expanded(
                          // 썸네일 사진
                          flex: 5,
                          child: Container(
                            // color: Colors.green,
                            child: Hero(
                              tag: widget.id,
                              child: Center(
                                child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey
                                              .withOpacity(0.5), // 그림자 색상
                                          spreadRadius: 5, // 그림자의 확산 범위
                                          blurRadius: 7, // 그림자의 흐림 정도
                                          offset: const Offset(
                                              0, 3), // 그림자의 위치 (가로, 세로)
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                        clipBehavior: Clip.hardEdge,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Image.network(widget.thumb))),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          // 제목과 책 내용 요약
                          flex: 5,
                          child: Container(
                            //   color: Colors.orange,
                            child: ListView(
                              children: [
                                SizedBox(
                                  height: SizeConfig.defaultSize! * 2,
                                ),
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                      fontSize: SizeConfig.defaultSize! * 3.5,
                                      fontFamily: 'BreeSerif'),
                                ),
                                SizedBox(
                                  height: SizeConfig.defaultSize! * 0.3,
                                ),
                                Row(
                                  //  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    isPurchased
                                        ? GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                isClicked0 = false;
                                                isClicked1 = false;
                                                isClicked2 = false;
                                                canChanged = true;
                                              });
                                              // widget.record!
                                              //     ? inferenceId == 0
                                              //         ? {
                                              //             startInference(token),
                                              //             setState(() {
                                              //               canChanged = false;
                                              //               completeInference =
                                              //                   false;
                                              //             }),
                                              //           } //인퍼런스 요청 보내기
                                              //         : cvi = inferenceId
                                              //     : setState(() {
                                              //         goRecord = true;
                                              //       });
                                            },
                                            child: const Column(
                                              children: [
                                                // Padding(
                                                //   padding: EdgeInsets.only(
                                                //       right: 0.8 *
                                                //           SizeConfig
                                                //               .defaultSize!),
                                                //   child: Image.asset(
                                                //     'lib/images/mine.png',
                                                //     height: SizeConfig
                                                //             .defaultSize! *
                                                //         6.5,
                                                //   ),
                                                // ),
                                                // SizedBox(
                                                //     height: SizeConfig
                                                //             .defaultSize! *
                                                //         0.3),
                                                // const Text('mine'),
                                              ],
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                wantPurchase = true;
                                              });
                                            },
                                            child: const Column(
                                              children: [
                                                // Padding(
                                                //   padding: EdgeInsets.only(
                                                //       right: 0.8 *
                                                //           SizeConfig
                                                //               .defaultSize!),
                                                //   child: Image.asset(
                                                //     'lib/images/lock.png',
                                                //     height: SizeConfig
                                                //             .defaultSize! *
                                                //         6.5,
                                                //   ),
                                                // ),
                                                // SizedBox(
                                                //     height: SizeConfig
                                                //             .defaultSize! *
                                                //         0.3),
                                                // const Text('mine'),
                                              ],
                                            ),
                                          ),
                                    GestureDetector(
                                      onTap: () {
                                        cvi = voices[0][
                                            'contentVoiceId']; // 1, 2, 3 등 --> 이 값을 밑에 화살표 부분에 넘겨준 것
                                        _sendVoiceClickEvent(cvi);
                                        setState(() {
                                          isClicked0 = true;
                                          isClicked1 = !isClicked0;
                                          isClicked2 = !isClicked0;
                                          canChanged = true; // 클릭 상태
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.only(
                                                  right: 0.8 *
                                                      SizeConfig.defaultSize!),
                                              child: isClicked0
                                                  ? Container(
                                                      height: SizeConfig
                                                              .defaultSize! *
                                                          6.6,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: const Color
                                                                  .fromARGB(255,
                                                              77, 252, 255),
                                                          width: 3.0,
                                                        ),
                                                      ),
                                                      child: Image.asset(
                                                        'lib/images/jolly.png',
                                                        height: SizeConfig
                                                                .defaultSize! *
                                                            6.5,
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      'lib/images/jolly.png',
                                                      height: SizeConfig
                                                              .defaultSize! *
                                                          6.5,
                                                    )
                                              // Image.asset(
                                              //   'lib/images/jolly.png',
                                              //   color: isClicked0
                                              //       ? null
                                              //       : const Color.fromARGB(
                                              //           // 선택하면 색이 바껴야 하는데 전부 다 바껴서 문제
                                              //           255,
                                              //           255,
                                              //           66,
                                              //           129),
                                              //   height:
                                              //       SizeConfig.defaultSize! * 6.5,
                                              // ),
                                              ),
                                          SizedBox(
                                              height: SizeConfig.defaultSize! *
                                                  0.3),
                                          Text(voices[0]['voiceName']),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        cvi = voices[1][
                                            'contentVoiceId']; // 1, 2, 3 등 --> 이 값을 밑에 화살표 부분에 넘겨준 것
                                        _sendVoiceClickEvent(cvi);
                                        setState(() {
                                          isClicked1 = true;
                                          isClicked0 = !isClicked1;
                                          isClicked2 = !isClicked1;
                                          canChanged = true; // 클릭 상태
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.only(
                                                  right: 0.8 *
                                                      SizeConfig.defaultSize!),
                                              child: isClicked1
                                                  ? Container(
                                                      height: SizeConfig
                                                              .defaultSize! *
                                                          6.6,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: const Color
                                                                  .fromARGB(255,
                                                              77, 252, 255),
                                                          width: 3.0,
                                                        ),
                                                      ),
                                                      child: Image.asset(
                                                        'lib/images/morgan.png',
                                                        height: SizeConfig
                                                                .defaultSize! *
                                                            6.5,
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      'lib/images/morgan.png',
                                                      height: SizeConfig
                                                              .defaultSize! *
                                                          6.5,
                                                    )),
                                          SizedBox(
                                              height: SizeConfig.defaultSize! *
                                                  0.3),
                                          Text(voices[1]['voiceName']),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        cvi = voices[2][
                                            'contentVoiceId']; // 1, 2, 3 등 --> 이 값을 밑에 화살표 부분에 넘겨준 것
                                        _sendVoiceClickEvent(cvi);
                                        setState(() {
                                          isClicked2 = true;
                                          isClicked0 = !isClicked2;
                                          isClicked1 = !isClicked2;
                                          canChanged = true; // 클릭 상태
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.only(
                                                  right: 0.8 *
                                                      SizeConfig.defaultSize!),
                                              child: isClicked2
                                                  ? Container(
                                                      height: SizeConfig
                                                              .defaultSize! *
                                                          6.6,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: const Color
                                                                  .fromARGB(255,
                                                              77, 252, 255),
                                                          width: 3.0,
                                                        ),
                                                      ),
                                                      child: Image.asset(
                                                        'lib/images/eric.png',
                                                        height: SizeConfig
                                                                .defaultSize! *
                                                            6.5,
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      'lib/images/eric.png',
                                                      height: SizeConfig
                                                              .defaultSize! *
                                                          6.5,
                                                    )),
                                          SizedBox(
                                              height: SizeConfig.defaultSize! *
                                                  0.3),
                                          Text(voices[2]['voiceName']),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: SizeConfig.defaultSize! * 0.1,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      right: SizeConfig.defaultSize! * 4),
                                  child: Text(
                                    widget.summary,
                                    style: TextStyle(
                                        fontFamily: 'Prata',
                                        fontSize: SizeConfig.defaultSize! * 2),
                                  ),
                                ),
                                SizedBox(
                                  height: SizeConfig.defaultSize!,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(children: [
                      Expanded(
                        // 썸네일 사진
                        flex: 1,
                        child: Container(
                            //color: Colors.white,
                            ),
                      ),
                      Expanded(
                          // 썸네일 사진
                          flex: 1,
                          child: Container()),
                      Expanded(
                        // 제목과 책 내용 요약
                        flex: 1,
                        child: GestureDetector(
                          onTap: () async {
                            (cvi == 100000)
                                ? await checkInference(token)
                                    ? {
                                        _sendBookStartClickEvent(cvi),
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FairytalePage(
                                                // 다음 화면으로 contetnVoiceId를 가지고 이동
                                                voiceId: cvi,
                                                lastPage: lastPage,
                                                isSelected: true,
                                              ),
                                            ))
                                      }
                                    : setState(() {
                                        completeInference = false;
                                      })
                                : canChanged
                                    ? {
                                        _sendBookStartClickEvent(cvi),
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FairytalePage(
                                              // 다음 화면으로 contetnVoiceId를 가지고 이동

                                              //  record: widget.record!,
                                              // purchase: widget.purchase!,
                                              voiceId: cvi,
                                              lastPage: lastPage,
                                              isSelected: true,
                                            ),
                                          ),
                                        )
                                      }
                                    : null;
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            //alignment: Alignment.topRight,
                            children: [
                              Text(
                                'Selected?',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.defaultSize! * 2),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    right: SizeConfig.defaultSize! * 2),
                                child: Icon(
                                  Icons.arrow_circle_right_outlined,
                                  size: SizeConfig.defaultSize! * 5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ), // --------------------성우 아이콘 배치 완료  ---------
                    ]),
                  ),
                  //추가

                  //  ),
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: wantPurchase,
          child: AlertDialog(
            title: const Text('Register your voice!'),
            content: const Text('Click OK to go to voice registration.'),
            actions: [
              TextButton(
                onPressed: () {
                  // 1초 후에 다음 페이지로 이동
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      wantPurchase = false;
                    });
                  });
                },
                child: const Text('later'),
              ),
              TextButton(
                onPressed: () {
                  // 1초 후에 다음 페이지로 이동
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Purchase()),
                    );
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
        Visibility(
          visible: goRecord,
          child: AlertDialog(
            title: const Text('Register your voice!'),
            content: const Text(
                'After registering your voice, listen to the book with your voice.'),
            actions: [
              TextButton(
                onPressed: () {
                  // 1초 후에 다음 페이지로 이동
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      goRecord = false;
                    });
                  });
                },
                child: const Text('later'),
              ),
              TextButton(
                onPressed: () {
                  // 1초 후에 다음 페이지로 이동
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RecordInfo()),
                    );
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
        Visibility(
          visible: !completeInference,
          child: AlertDialog(
            title: const Text('Please wait a minute.'),
            content: const Text(
                "We're making a book with your voice. \nIf you want to read the book right now, please choose a different voice actor!"),
            actions: [
              TextButton(
                onPressed: () {
                  // 1초 후에 다음 페이지로 이동
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      completeInference = true;
                    });
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ]),
      //),
    );
  }
}
