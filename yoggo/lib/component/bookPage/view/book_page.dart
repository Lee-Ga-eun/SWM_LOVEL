import 'package:amplitude_flutter/amplitude.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:yoggo/component/bookPage/viewModel/book_page_cubit.dart';
import 'package:yoggo/component/bookPage/viewModel/book_page_model.dart';
import 'dart:convert';
import 'dart:async';
import 'package:yoggo/size_config.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../Repositories/Repository.dart';
import '../../book_end.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../globalCubit/user/user_cubit.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:percent_indicator/percent_indicator.dart';

class BookPage extends StatefulWidget {
  final int contentVoiceId; //detail_screen에서 받아오는 것들
  final bool isSelected;
  final int lastPage;
  final int voiceId;
  final int contentId;
  final String title;
  final AudioPlayer bgmPlayer;

  const BookPage(
      {super.key,
      required this.contentVoiceId, // detail_screen에서 받아오는 것들 초기화
      required this.voiceId, // detail_screen에서 받아오는 것들 초기화
      required this.contentId, // detail_screen에서 받아오는 것들 초기화
      required this.isSelected,
      required this.lastPage,
      required this.title,
      required this.bgmPlayer});

  @override
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> with WidgetsBindingObserver {
  // List<BookPage> pages = []; // 책 페이지 데이터 리스트
  //List<Map<String, dynamic>> pages = [];
  int currentPageIndex = 0; // 현재 페이지 인덱스
  Color iconColor = Colors.black;
  bool isPlaying = false;
  //bool pauseFunction = false;
  AudioPlayer audioPlayer = AudioPlayer();
  AudioPlayer effectPlayer = AudioPlayer();
  bool autoplayClicked = true;
  bool changeKorean = false;
  bool reportClicked = false;
  bool _isChanged = false;
  bool _isChangedLanguage = false;
  String reportContent = '';
  bool isKeyboardVisible = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드에 들어갔을 때 실행할 로직
      audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 복귀했을 때 실행할 로직
      resumeAudio();
    }
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
    audioPlayer.onPlayerComplete.listen((event) {
      if (autoplayClicked) {
        if (currentPageIndex != widget.lastPage - 1) {
          effectPlayer.play(AssetSource('sound/book-turn.wav'));

          Future.delayed(const Duration(milliseconds: 500)).then((_) {
            nextPage();
          });
        } else {
          setState(() {
            iconColor = Colors.green;
          });
        }
      } else {}
    });
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Amplitude amplitude = Amplitude.getInstance();

  Future<void> fetchAllBookPages() async {
    await dotenv.load(fileName: ".env");
    // API에서 모든 책 페이지 데이터를 불러와 pages 리스트에 저장
    final url =
        '${dotenv.get("API_SERVER")}content/page?contentVoiceId=${widget.contentVoiceId}';
    final response = await http.get(Uri.parse(url));

    // final response = await http.get(Uri.parse(
    //     'https://yoggo-server.fly.dev/content/page?contentVoiceId=${widget.contentVoiceId}'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData is List<dynamic>) {
        setState(() {
          // pages = List<Map<String, dynamic>>.from(jsonData);
        });
      }
    } else {
      // 에러 처리
    }
  }

  Future<void> sendReport() async {
    await dotenv.load(fileName: ".env");
    // API에서 모든 책 페이지 데이터를 불러와 pages 리스트에 저장
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token')!;
    if (reportContent != '') {
      final url = Uri.parse('${dotenv.get("API_SERVER")}user/report');
      final body = jsonEncode({
        'contentId': widget.contentId,
        'voiceId': widget.voiceId,
        'pageNum': currentPageIndex + 1,
        'report': reportContent
      });

      var response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body);
    }
  }

  void playAudio(audioPath) async {
    if (!isPlaying) {
      await audioPlayer.stop();
      // String filePath =
      //await widget.audioPlayer.play(UrlSource(audioUrl));
      //await widget.audioPlayer.play(DeviceFileSource(filePath));
      String filePath = audioPath.replaceAll("'", "");
      print(DeviceFileSource(filePath));
      await audioPlayer.play(DeviceFileSource(filePath));
      isPlaying = true;
    }
  }

  void nextPage() async {
    await stopAudio();
    setState(() {
      //isPlaying = true;
      //awiat stopAudio();
      //pauseFunction = false;
      if (currentPageIndex < widget.lastPage) {
        currentPageIndex++;
        if (currentPageIndex == widget.lastPage) {
          currentPageIndex -= 1;
        }
      }
      isPlaying = false;
    });
  }

  void previousPage() {
    setState(() {
      if (currentPageIndex > 0) {
        currentPageIndex--;
        isPlaying = true;
        //pauseFunction = false;
        stopAudio();
      }
    });
    isPlaying = false;
  }

  stopAudio() async {
    await audioPlayer.stop();
  }

  void pauseAudio() async {
    print("pause");
    //  isPlaying = false;
    await audioPlayer.stop();
    // isPlaying = false;
    // setState(() {
    //   isPlaying = true;
    // });
  }

  void resumeAudio() async {
    print("resume");
    //  isPlaying = true;
    await audioPlayer.resume();
    // isPlaying = true;
    // setState(() {
    //   isPlaying = false;
    // });
  }

  @override
  void dispose() async {
    //await stopAudio();
    audioPlayer.stop();
    audioPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    final dataRepository = RepositoryProvider.of<DataRepository>(context);
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

    return WillPopScope(
        onWillPop: () async {
          await WakelockPlus.disable();
          print('screen off');
          return true; // Return true to exit the app, false to stay in the app
        },
        child: BlocProvider(create: (context) {
          final bookPageCubit = BookPageCubit(dataRepository);
          bookPageCubit.loadBookPageData(widget.contentVoiceId);
          return bookPageCubit;
        }, child: BlocBuilder<BookPageCubit, List<BookPageModel>>(
            builder: (context, bookPage) {
          if (bookPage.isEmpty) {
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('lib/images/bkground.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                          padding: EdgeInsets.only(
                              left: 0.15 * sw, right: 0.15 * sw),
                          child: Stack(children: [
                            Positioned(
                              left: 0.2 * sw,
                              child: LinearPercentIndicator(
                                curve: Curves.fastOutSlowIn,
                                width: 0.5 * sw,
                                animation: true,
                                lineHeight: 0.05 * sh,
                                animationDuration: 6000,
                                percent: 1,
                                center: Text(""),
                                linearStrokeCap: LinearStrokeCap.roundAll,
                                progressColor:
                                    Color.fromARGB(255, 255, 169, 26),
                              ),
                            ),
                            Positioned(
                              child: LinearPercentIndicator(
                                curve: Curves.fastOutSlowIn,
                                width: 0.5 * sw,
                                animation: true,
                                lineHeight: 0.05 * sh,
                                animationDuration: 2000,
                                percent: 1,
                                center: Text(""),
                                linearStrokeCap: LinearStrokeCap.roundAll,
                                progressColor:
                                    Color.fromARGB(255, 255, 169, 26),
                              ),
                            ),
                          ])),

                      SizedBox(
                        height: SizeConfig.defaultSize! * 2,
                      ),

                      Text(
                        '책-페이지-로딩',
                        style: TextStyle(
                            fontFamily: 'font-basic'.tr(),
                            fontSize: SizeConfig.defaultSize! * 2.5),
                        textAlign: TextAlign.center,
                      ).tr()
                      //: Container()
                    ],
                  ),
                ),
              ),
            );
          } else {
            _sendBookPageViewEvent(widget.contentVoiceId, widget.contentId,
                widget.voiceId, currentPageIndex + 1, widget.title);
            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: //SingleChildScrollView(
                  //child:
                  Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('lib/images/bkground.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    bottom: false,
                    minimum: EdgeInsets.only(
                        left: SizeConfig.defaultSize!,
                        right: SizeConfig.defaultSize!),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.defaultSize!),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            //HEADER
                            flex: 14,
                            child: Row(
                              // mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: IconButton(
                                    padding: EdgeInsets.all(
                                        0.2 * SizeConfig.defaultSize!),
                                    alignment: Alignment.centerLeft,
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.black,
                                      size: 3 * SizeConfig.defaultSize!,
                                    ),
                                    onPressed: () async {
                                      // stopAudio();
                                      dispose();
                                      _sendBookPageXClickEvent(
                                          widget.contentVoiceId,
                                          widget.contentId,
                                          widget.voiceId,
                                          currentPageIndex + 1,
                                          widget.title);
                                      WakelockPlus.disable();
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      bool playingBgm =
                                          prefs.getBool('playingBgm') ?? true;
                                      if (playingBgm) {
                                        widget.bgmPlayer.resume();
                                      }

                                      Navigator.popUntil(
                                          context, (route) => route.isFirst);
                                      //고민
                                    },
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${currentPageIndex + 1} / ${widget.lastPage}',
                                      style: TextStyle(
                                          fontFamily: 'GenBkBasR',
                                          fontSize:
                                              SizeConfig.defaultSize! * 2),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        context.locale.toString() == "ko_KR"
                                            ? SizedBox(
                                                width:
                                                    SizeConfig.defaultSize! * 5,
                                                height:
                                                    SizeConfig.defaultSize! * 5,
                                                child: Stack(
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child: CupertinoSwitch(
                                                        value: changeKorean,
                                                        activeColor:
                                                            CupertinoColors
                                                                .activeOrange,
                                                        onChanged:
                                                            (bool? value) {
                                                          changeKorean
                                                              ? _sendBookTranslateOffClickEvent(
                                                                  widget
                                                                      .contentId,
                                                                  widget
                                                                      .voiceId,
                                                                  widget
                                                                      .contentVoiceId,
                                                                  currentPageIndex,
                                                                  widget.title)
                                                              : _sendBookTranslateOnClickEvent(
                                                                  widget
                                                                      .contentId,
                                                                  widget
                                                                      .voiceId,
                                                                  widget
                                                                      .contentVoiceId,
                                                                  currentPageIndex,
                                                                  widget.title);

                                                          setState(() {
                                                            changeKorean =
                                                                value ?? false;
                                                            _isChangedLanguage =
                                                                true;
                                                          });
                                                          Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          1500))
                                                              .then((_) {
                                                            setState(() {
                                                              _isChangedLanguage =
                                                                  false;
                                                            });
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    Align(
                                                        alignment: Alignment
                                                            .bottomCenter,
                                                        child: Text('한글 번역',
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'font-basic'
                                                                        .tr(),
                                                                fontSize: SizeConfig
                                                                        .defaultSize! *
                                                                    1.25 *
                                                                    double.parse(
                                                                        'font-ratio'
                                                                            .tr()))))
                                                  ],
                                                ))
                                            : Container(),
                                        SizedBox(
                                            width: SizeConfig.defaultSize!),
                                        SizedBox(
                                            width: SizeConfig.defaultSize! * 5,
                                            height: SizeConfig.defaultSize! * 5,
                                            child: Stack(children: [
                                              Transform.scale(
                                                scale: 0.8,
                                                child: CupertinoSwitch(
                                                  value: autoplayClicked,
                                                  activeColor: CupertinoColors
                                                      .activeOrange,
                                                  onChanged: (bool? value) {
                                                    autoplayClicked
                                                        ? _sendBookAutoPlayOffClickEvent(
                                                            widget.contentId,
                                                            widget.voiceId,
                                                            widget
                                                                .contentVoiceId,
                                                            currentPageIndex,
                                                            widget.title)
                                                        : _sendBookAutoPlayOnClickEvent(
                                                            widget.contentId,
                                                            widget.voiceId,
                                                            widget
                                                                .contentVoiceId,
                                                            currentPageIndex,
                                                            widget.title);

                                                    setState(() {
                                                      autoplayClicked =
                                                          value ?? false;
                                                      _isChanged = true;
                                                    });
                                                    Future.delayed(
                                                            const Duration(
                                                                milliseconds:
                                                                    1500))
                                                        .then((_) {
                                                      setState(() {
                                                        _isChanged = false;
                                                      });
                                                    });
                                                  },
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: Text('자동 재생',
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'font-basic'
                                                                    .tr(),
                                                            fontSize: SizeConfig
                                                                    .defaultSize! *
                                                                1.25 *
                                                                double.parse(
                                                                    'font-ratio'
                                                                        .tr())))
                                                    .tr(),
                                              )
                                            ])),
                                        SizedBox(
                                            width: SizeConfig.defaultSize!),
                                        Container(
                                          width: SizeConfig.defaultSize! * 5,
                                          height: SizeConfig.defaultSize! * 5,
                                          child: GestureDetector(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Icon(Icons.error_outline,
                                                      color: Colors.black,
                                                      size: SizeConfig
                                                              .defaultSize! *
                                                          3),
                                                  Text('오류 제보',
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'font-basic'
                                                                      .tr(),
                                                              fontSize: SizeConfig
                                                                      .defaultSize! *
                                                                  1.25 *
                                                                  double.parse(
                                                                      'font-ratio'
                                                                          .tr())))
                                                      .tr()
                                                ],
                                              ),
                                              onTap: () {
                                                // print('report');
                                                _sendBookErrorReportClickEvent(
                                                    widget.contentId,
                                                    widget.voiceId,
                                                    widget.contentVoiceId,
                                                    currentPageIndex,
                                                    widget.title);
                                                setState(() {
                                                  reportClicked = true;
                                                });
                                              }),
                                        )
                                      ]),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                              // BoDY
                              flex: 74,
                              child: PageWidget(
                                // page: currentPageIndex < widget.lastPage
                                //     ? bookPage[currentPageIndex]
                                //     : bookPage[widget.lastPage - 1],
                                text: currentPageIndex < widget.lastPage
                                    ? bookPage[currentPageIndex].text
                                    : bookPage[widget.lastPage - 1].text,
                                // imageUrl: currentPageIndex < widget.lastPage
                                //     ? bookPage[currentPageIndex].imageUrl
                                //     : bookPage[widget.lastPage - 1].imageUrl,
                                textKr: currentPageIndex < widget.lastPage
                                    ? bookPage[currentPageIndex].textKr
                                    : bookPage[widget.lastPage - 1].textKr,
                                position: currentPageIndex < widget.lastPage
                                    ? bookPage[currentPageIndex].position
                                    : bookPage[widget.lastPage - 1].position,
                                audioUrl: bookPage[currentPageIndex].audioUrl,
                                audioPath:
                                    bookPage[currentPageIndex].audioLocalPath,
                                filePath: currentPageIndex < widget.lastPage
                                    ? bookPage[currentPageIndex].imageLocalPath
                                    : bookPage[widget.lastPage - 1]
                                        .imageLocalPath,
                                realCurrent: true,
                                currentPage: currentPageIndex,
                                audioPlayer: audioPlayer,
                                //pauseFunction: pauseFunction,
                                previousPage: previousPage,
                                currentPageIndex: currentPageIndex,
                                nextPage: nextPage,
                                lastPage: widget.lastPage,
                                voiceId: widget.voiceId,
                                contentVoiceId: widget.contentVoiceId,
                                contentId: widget.contentId,
                                isSelected: widget.isSelected,
                                dispose: dispose,
                                stopAudio: stopAudio,
                                title: widget.title,
                                changeKorean: changeKorean,
                                playAudio: playAudio,
                              )),
                          Expanded(
                            flex: 12,
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 1,
                                    // bottom: 5,
                                    // left: 10,
                                    child: Container(
                                      // [<-]
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .start, // 아이콘을 맨 왼쪽으로 정렬
                                        children: [
                                          IconButton(
                                              padding: EdgeInsets.all(0.2 *
                                                  SizeConfig.defaultSize!),
                                              icon: currentPageIndex == 0
                                                  ? Icon(
                                                      Icons.arrow_back,
                                                      color: Colors.black
                                                          .withOpacity(0),
                                                    )
                                                  : Icon(
                                                      Icons.arrow_back,
                                                      size: 3 *
                                                          SizeConfig
                                                              .defaultSize!,
                                                    ),
                                              onPressed: () {
                                                effectPlayer.play(AssetSource(
                                                    'sound/book-turn.wav'));
                                                _sendBookNextClickEvent(
                                                    widget.contentVoiceId,
                                                    widget.contentId,
                                                    widget.voiceId,
                                                    currentPageIndex + 1,
                                                    widget.title);
                                                _sendBookBackClickEvent(
                                                    widget.contentVoiceId,
                                                    widget.contentId,
                                                    widget.voiceId,
                                                    currentPageIndex + 1,
                                                    widget.title);

                                                Future.delayed(const Duration(
                                                        milliseconds: 500))
                                                    .then((_) {
                                                  previousPage();
                                                });
                                              })
                                        ],
                                      ),
                                    )),
                                Expanded(
                                    flex: 8,
                                    child: Container(
                                        color:
                                            const Color.fromARGB(0, 0, 0, 0))),
                                Expanded(
                                    flex: 1,
                                    child: currentPageIndex !=
                                            widget.lastPage - 1
                                        ? Container(
                                            // [->]
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .end, // 아이콘을 맨 왼쪽으로 정렬
                                              children: [
                                                IconButton(
                                                    padding: EdgeInsets.all(
                                                        0.2 *
                                                            SizeConfig
                                                                .defaultSize!),
                                                    icon: Icon(
                                                      Icons.arrow_forward,
                                                      size: 3 *
                                                          SizeConfig
                                                              .defaultSize!,
                                                    ),
                                                    onPressed: () async {
                                                      effectPlayer.play(AssetSource(
                                                          'sound/book-turn.wav'));
                                                      _sendBookNextClickEvent(
                                                          widget.contentVoiceId,
                                                          widget.contentId,
                                                          widget.voiceId,
                                                          currentPageIndex + 1,
                                                          widget.title);

                                                      Future.delayed(
                                                              const Duration(
                                                                  milliseconds:
                                                                      500))
                                                          .then((_) {
                                                        nextPage();
                                                      });
                                                    })
                                              ],
                                            ),
                                          )
                                        : Container(
                                            // [V]
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .end, // 아이콘을 맨 왼쪽으로 정렬
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(0.2 *
                                                      SizeConfig
                                                          .defaultSize!), // 패딩 크기를 원하는 값으로 조정해주세요
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.check,
                                                      color: iconColor,
                                                      size: 3 *
                                                          SizeConfig
                                                              .defaultSize!,
                                                    ),
                                                    // 결제와 목소리 등록을 완료한 사용자는 바로 종료시킨다
                                                    // 결제만 한 사용자는 등록을 하라는 메시지를 보낸다 // 아직 등록하지 않았어요~~
                                                    // 결제를 안 한 사용자는 결제하는 메시지를 보여준다 >> 목소리로 할 수 있아요~~
                                                    onPressed: () {
                                                      dispose();
                                                      _sendBookLastClickEvent(
                                                          widget.contentVoiceId,
                                                          widget.contentId,
                                                          widget.voiceId,
                                                          currentPageIndex + 1,
                                                          widget.title);

                                                      if (userState.record != null &&
                                                          userState.record ==
                                                              true &&
                                                          userState.purchase ==
                                                              true) {
                                                        //Navigator.pop(context);

                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    BookEnd(
                                                              voiceId: widget
                                                                  .voiceId,
                                                              contentVoiceId: widget
                                                                  .contentVoiceId,
                                                              contentId: widget
                                                                  .contentId,
                                                              lastPage: widget
                                                                  .lastPage,
                                                              isSelected: widget
                                                                  .isSelected,
                                                              title:
                                                                  widget.title,
                                                              bgmPlayer: widget
                                                                  .bgmPlayer,
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        Navigator.push(
                                                          context,
                                                          //결제가 끝나면 RecInfo로 가야 함
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    BookEnd(
                                                              contentVoiceId: widget
                                                                  .contentVoiceId,
                                                              contentId: widget
                                                                  .contentId,
                                                              voiceId: widget
                                                                  .voiceId,
                                                              lastPage: widget
                                                                  .lastPage,
                                                              isSelected: widget
                                                                  .isSelected,
                                                              title:
                                                                  widget.title,
                                                              bgmPlayer: widget
                                                                  .bgmPlayer,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                )
                                              ],
                                            ),
                                          )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    minimum: EdgeInsets.only(
                        left: SizeConfig.defaultSize!,
                        right: SizeConfig.defaultSize!),
                    child: Padding(
                        padding: EdgeInsets.only(
                          left: sw * 0.1,
                          top: isKeyboardVisible ? sh * 0.1 : sh * 0.3,
                        ),
                        child: Visibility(
                          visible: reportClicked,
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
                                            right: SizeConfig.defaultSize! * 2,
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
                                                fillColor: Colors.grey[200]),
                                          ),
                                        ),
                                        Container(
                                          child: GestureDetector(
                                            onTap: () {
                                              _sendBookErrorReportSendClickEvent(
                                                  widget.contentId,
                                                  widget.voiceId,
                                                  widget.contentVoiceId,
                                                  currentPageIndex,
                                                  widget.title);
                                              sendReport();
                                              setState(() {
                                                reportClicked = false;
                                              });
                                            },
                                            child: Container(
                                              width:
                                                  SizeConfig.defaultSize! * 10,
                                              height:
                                                  SizeConfig.defaultSize! * 4.5,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        SizeConfig
                                                                .defaultSize! *
                                                            1),
                                                color: const Color(0xFFFFA91A),
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
                                                            'font-ratio'.tr()),
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
                                      _sendBookErrorReportXClickEvent(
                                          widget.contentId,
                                          widget.voiceId,
                                          widget.contentVoiceId,
                                          currentPageIndex,
                                          widget.title);
                                      setState(() {
                                        reportClicked = false;
                                      });
                                      //고민
                                    },
                                  ),
                                ),
                              ])),
                        )),
                  )
                ],
              ),
            );
          }
        })));
  }

  Future<void> _sendBookAutoPlayOnClickEvent(
      contentId, voiceId, contentVoiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      print('on!!');
      await analytics.logEvent(
        name: 'book_autoplay_on_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_autoplay_on_click',
        eventProperties: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookTranslateOnClickEvent(
      contentId, voiceId, contentVoiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      print('on!!');
      await analytics.logEvent(
        name: 'book_translate_on_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_translate_on_click',
        eventProperties: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookErrorReportClickEvent(
      contentId, voiceId, contentVoiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_error_report_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_error_report_click',
        eventProperties: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookErrorReportSendClickEvent(
      contentId, voiceId, contentVoiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_error_report_send_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_error_report_send_click',
        eventProperties: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookErrorReportXClickEvent(
      contentId, voiceId, contentVoiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_error_report_x_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_error_report_x_click',
        eventProperties: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookAutoPlayOffClickEvent(
      contentId, voiceId, contentVoiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      // print('off');
      await analytics.logEvent(
        name: 'book_autoplay_off_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_autoplay_off_click',
        eventProperties: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookTranslateOffClickEvent(
      contentId, voiceId, contentVoiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      // print('off');
      await analytics.logEvent(
        name: 'book_translate_off_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_translate_off_click',
        eventProperties: <String, dynamic>{
          'contentId': contentId,
          'voiceId': voiceId,
          'contentVoiceId': contentVoiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookPageViewEvent(
      contentVoiceId, contentId, voiceId, pageId, title) async {
    try {
      // 이벤트 로깅ㄱ
      await analytics.logEvent(
        name: 'book_page_view',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_page_view',
        eventProperties: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookPageLoadingViewEvent(
      contentVoiceId, contentId, voiceId, title) async {
    try {
      await analytics.logEvent(
        name: 'book_page_loading_view',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_page_loading_view',
        eventProperties: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookPageXClickEvent(
      contentVoiceId, contentId, voiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_page_x_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_page_x_click',
        eventProperties: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookLastClickEvent(
      contentVoiceId, contentId, voiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_last_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_last_click',
        eventProperties: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookNextClickEvent(
      contentVoiceId, contentId, voiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_next_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_next_click',
        eventProperties: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookBackClickEvent(
      contentVoiceId, contentId, voiceId, pageId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_back_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
      amplitude.logEvent(
        'book_back_click',
        eventProperties: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'voiceId': voiceId,
          'pageId': pageId,
          'title': title
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }
}

class PageWidget extends StatefulWidget {
  //final Map<String, dynamic> page;
  final String text;
  // final String imageUrl;
  final int position;
  final String audioUrl;
  final String textKr;
  final int currentPage;
  final AudioPlayer audioPlayer;
  //final bool pauseFunction;
  final bool realCurrent;
  final previousPage;
  final int currentPageIndex;
  final nextPage;
  final int lastPage;
  final bool? purchase;
  final bool? record;
  final int voiceId; //detail_screen에서 받아오는 것들
  final int contentVoiceId; //detail_screen에서 받아오는 것들
  final int contentId; //detail_screen에서 받아오는 것들
  final bool isSelected;
  final dispose;
  final stopAudio;
  bool changeKorean;
  final String filePath;
  final audioPath;
  final String title;
  final playAudio;

  PageWidget({
    Key? key,
    //  required this.page,
    required this.text,
    required this.textKr,
    //  required this.imageUrl,
    required this.position,
    required this.audioUrl,
    required this.currentPage,
    required this.audioPlayer,
    //required this.pauseFunction,
    required this.realCurrent,
    required this.previousPage,
    required this.currentPageIndex,
    required this.nextPage,
    required this.lastPage,
    this.purchase,
    required this.voiceId,
    required this.contentVoiceId,
    required this.contentId,
    required this.isSelected,
    required this.changeKorean,
    this.record,
    required this.dispose,
    required this.stopAudio,
    required this.filePath,
    required this.audioPath,
    required this.title,
    required this.playAudio,
  }) : super(key: key);

  @override
  _PageWidgetState createState() => _PageWidgetState();
}

class _PageWidgetState extends State<PageWidget> {
  final Amplitude amplitude = Amplitude.getInstance();
  Color iconColor = Colors.black;
  ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    SizeConfig().init(context);

    // print('지금 나와야하는 그림 ${widget.filePath}');
    // var nowImage = widget.filePath;
    var nowImage = '';
    nowImage = widget.filePath.replaceAll("'", "");
    Future.delayed(const Duration(milliseconds: 500)).then((_) {
      widget.playAudio(widget.audioPath);
    });
    //playAudio(widget.audioUrl);
    widget.audioPlayer.onPlayerComplete.listen((event) {
      iconColor = Colors.green;
      if (widget.currentPageIndex == widget.lastPage - 1) {
        WakelockPlus.disable();
        print('screen off');
      }
    });
    return Container(
      //color: Colors.red,
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'lib/images/gray.png',
                    ),
                  ),
                  // Positioned.fill(
                  //   child:
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image(
                      image: FileImage(File(nowImage)),
                    ),
                    //File('/Users/iga-eun/Library/Developer/CoreSimulator/Devices/7F898527-8EDA-4F3B-8DB7-7540CDC6DC56/data/Containers/Data/Application/149D45B5-47F9-4354-8392-AA13CFEB73FD/Library/Caches/libCachedImageData/c7e8f7f0-5c10-11ee-bf53-17b03fffd053.png'))),
                    //   File('/Users/iga-eun/Library/Developer/CoreSimulator/Devices/7F898527-8EDA-4F3B-8DB7-7540CDC6DC56/data/Containers/Data/Application/51BD51C0-88A3-4805-BDEE-B9DA1AE95AEA/Library/Caches/libCachedImageData/c63ef170-5c10-11ee-bf53-17b03fffd053.png'))),
                    // CachedNetworkImage(
                    //   imageUrl: widget.imageUrl,
                    //   fit: BoxFit.cover,
                    // ),
                  ),
                  //),
                ],
              )),
          Expanded(
            flex: 3,
            child: Container(
              //color: position == 2 ? Colors.red : Colors.white,
              child: Padding(
                padding: EdgeInsets.only(
                    right: 0.5 * SizeConfig.defaultSize!,
                    left: 2 * SizeConfig.defaultSize!),
                child: Scrollbar(
                  controller: ScrollController(),
                  thumbVisibility: true,
                  trackVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.right,
                  child: SingleChildScrollView(
                      child: Padding(
                          padding: EdgeInsets.only(
                              right: 1 * SizeConfig.defaultSize!),
                          child: Text(
                            widget.changeKorean ? widget.textKr : widget.text,
                            style: TextStyle(
                                fontSize: widget.changeKorean
                                    ? 1.85 * SizeConfig.defaultSize!
                                    : 2.1 * SizeConfig.defaultSize!,
                                height: 1.4,
                                fontFamily: widget.changeKorean
                                    ? 'SCDream'
                                    : 'font-book'.tr(),
                                fontWeight: FontWeight.w400),
                          ))),
                ),
              ), // 글자를 1번 화면에 배치
            ),
          ),
        ],
      ),
    );
  }
}
