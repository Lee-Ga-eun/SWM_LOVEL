import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../main.dart';
import 'package:yoggo/size_config.dart';
import 'package:audioplayers/audioplayers.dart';

class FairytalePage extends StatefulWidget {
  final int voiceId; //detail_screen에서 받아오는 것들
  final bool isSelected;
  final int lastPage;
  const FairytalePage({
    super.key,
    required this.voiceId, // detail_screen에서 받아오는 것들 초기화
    required this.isSelected,
    required this.lastPage,
  });

  @override
  _FairyTalePageState createState() => _FairyTalePageState();
}

class _FairyTalePageState extends State<FairytalePage> {
  // List<BookPage> pages = []; // 책 페이지 데이터 리스트
  List<Map<String, dynamic>> pages = [];

  int currentPageIndex = 0; // 현재 페이지 인덱스
  bool isPlaying = true;
  bool pauseFunction = false;

  AudioPlayer audioPlayer = AudioPlayer();
  // Source audioUrl = UrlSource('');

  @override
  void initState() {
    super.initState();
    // 책 페이지 데이터 미리 불러오기
    fetchAllBookPages();
  }

  Future<void> fetchAllBookPages() async {
    // API에서 모든 책 페이지 데이터를 불러와 pages 리스트에 저장
    final response = await http.get(Uri.parse(
        'https://yoggo-server.fly.dev/content/page?contentVoiceId=${widget.voiceId}'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData is List<dynamic>) {
        setState(() {
          pages = List<Map<String, dynamic>>.from(jsonData);
          // print(pages);
        });
      }
    } else {
      // 에러 처리
    }
  }

  void nextPage() {
    setState(() {
      isPlaying = true;
      stopAudio();
      pauseFunction = false;
      if (currentPageIndex < widget.lastPage) {
        currentPageIndex++;
        if (currentPageIndex == widget.lastPage) {
          currentPageIndex -= 1;
        }
      }
    });
  }

  void previousPage() {
    setState(() {
      if (currentPageIndex > 0) {
        currentPageIndex--;
        isPlaying = true;
        pauseFunction = false;
        stopAudio();
      }
    });
  }

  void stopAudio() async {
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
  void dispose() {
    // audioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(currentPageIndex);
    print(widget.lastPage);
    if (pages.isEmpty) {
      return const CircularProgressIndicator();
    }
    return Scaffold(
      body: Stack(
        children: [
          // 현재 페이지 위젯
          Visibility(
            visible: true,
            child: PageWidget(
              page: currentPageIndex < widget.lastPage
                  ? pages[currentPageIndex]
                  : pages[widget.lastPage - 1],
              audioUrl: supabaseAudioUrl + pages[currentPageIndex]['audioUrl'],
              currentPage: currentPageIndex,
              audioPlayer: audioPlayer,
              pauseFunction: pauseFunction,
            ),
          ),
          // 다음 페이지 위젯
          Visibility(
            visible: false,
            child: PageWidget(
              page: currentPageIndex < widget.lastPage
                  ? currentPageIndex == widget.lastPage - 1
                      ? pages[currentPageIndex]
                      : pages[currentPageIndex + 1]
                  : pages[widget.lastPage - 1],
              audioUrl: supabaseAudioUrl + pages[currentPageIndex]['audioUrl'],
              currentPage: currentPageIndex,
              audioPlayer: audioPlayer,
              pauseFunction: pauseFunction,
            ),
          ),
          // 이전 페이지 위젯
          Visibility(
            visible: false,
            child: PageWidget(
              page: currentPageIndex != 0
                  ? pages[currentPageIndex - 1]
                  : pages[0],
              audioUrl: supabaseAudioUrl + pages[currentPageIndex]['audioUrl'],
              currentPage: currentPageIndex,
              audioPlayer: audioPlayer,
              pauseFunction: pauseFunction,
            ),
          ),
          Positioned(
              top: 5,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.cancel,
                  color: Colors.white,
                  size: 35,
                ),
                onPressed: () {
                  stopAudio();
                  Navigator.of(context).pop();
                },
              )),

          // 오른쪽 화살표 버튼
          Positioned(
            bottom: 5,
            right: 10,
            child: currentPageIndex != widget.lastPage - 1
                ? IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: nextPage,
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.check,
                      color: Color.fromARGB(255, 77, 204, 81),
                    ),
                    onPressed: () {
                      stopAudio();
                      Navigator.of(context).pop();
                      // Navigator.push(
                      //   context,
                      //   //결제가 끝나면 RecordInfo로 가야 함
                      //   MaterialPageRoute(
                      //     builder: (context) => ReaderEnd(
                      //       voiceId: widget.voiceId,
                      //       lastPage: widget.lastPage,
                      //       isSelected: widget.isSelected,
                      //     ),
                      //   ),
                      // );
                    },
                  ),
          ),
          // 왼쪽 화살표 버튼
          Positioned(
            bottom: 5,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: previousPage,
            ),
          ),
          // 중간 스탑 버튼
          Align(
              alignment: Alignment.bottomCenter,
              child: IconButton(
                icon: isPlaying
                    ? const Icon(Icons.pause)
                    : const Icon(Icons.play_arrow),
                onPressed: () {
                  pauseFunction = true;
                  if (isPlaying) {
                    pauseAudio();
                    //audioPlayer.stop();
                  } else {
                    resumeAudio();
                  }
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
              ))
        ],
      ),
    );
  }
}

class PageWidget extends StatefulWidget {
  final Map<String, dynamic> page;
  final String audioUrl;
  final int currentPage;
  final AudioPlayer audioPlayer;
  final bool pauseFunction;

  const PageWidget({
    Key? key,
    required this.page,
    required this.audioUrl,
    required this.currentPage,
    required this.audioPlayer,
    required this.pauseFunction,
  }) : super(key: key);

  @override
  _PageWidgetState createState() => _PageWidgetState();
}

class _PageWidgetState extends State<PageWidget> {
  @override
  Widget build(BuildContext context) {
    //   final pageNum = widget.page['pageNum'] as int;
    final text = widget.page['text'] as String;
    final imageUrl = contentUrl + widget.page['imageUrl'];
    final imagePostion = widget.page['position'];

    widget.audioPlayer.stop();

    void playAudio(String audioUrl) async {
      await widget.audioPlayer.play(UrlSource(audioUrl));
    }

    if (widget.pauseFunction != true) {
      // 일시정지 버튼이 아닐 때만
      playAudio(widget.audioUrl);
    }

    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/images/bkground.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.defaultSize!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: imagePostion == 1 ? 1 : 2,
                        child: Container(
                          //color: position == 1 ? Colors.red : Colors.white,
                          child: imagePostion == 1
                              ? Padding(
                                  padding: EdgeInsets.only(
                                      left: SizeConfig.defaultSize! * 2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        20), // 모서리를 원형으로 설정
                                    child: Image.network(
                                      imageUrl,
                                    ),
                                  ),
                                ) // // 그림을 1번 화면에 배치
                              : Padding(
                                  padding: EdgeInsets.only(
                                      left: SizeConfig.defaultSize! * 5,
                                      right: SizeConfig.defaultSize!),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          // textAlign: TextAlign.center,
                                          text,
                                          style: TextStyle(
                                              fontSize:
                                                  SizeConfig.defaultSize! * 2,
                                              fontFamily: 'BreeSerif'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ), // 글자를 2번 화면에 배치
                        ),
                      ),
                      Expanded(
                        flex: imagePostion == 0 ? 1 : 2,
                        child: Container(
                          //color: position == 2 ? Colors.red : Colors.white,
                          child: imagePostion == 0
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(20), // 모서리를 원형으로 설정
                                  child: Image.network(
                                    imageUrl,
                                  ),
                                ) // 그림을 2번 화면에 배치
                              : Padding(
                                  padding: EdgeInsets.only(
                                      right: SizeConfig.defaultSize! * 2,
                                      left: SizeConfig.defaultSize! * 2),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          text,
                                          style: TextStyle(
                                              fontSize:
                                                  SizeConfig.defaultSize! * 2,
                                              fontFamily: 'BreeSerif'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ), // 글자를 1번 화면에 배치
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
