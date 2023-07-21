import 'package:flutter/material.dart';
import 'package:yoggo/component/home_screen.dart';
import 'package:yoggo/component/reader.dart';
import 'package:yoggo/component/record_info.dart';
import 'package:yoggo/size_config.dart';
import 'package:yoggo/component/purchase.dart';

class ReaderEnd extends StatefulWidget {
  final int voiceId; //detail_screen에서 받아오는 것들
  final bool isSelected;
  final record = true;
  final purchase = true;
  final int lastPage;
  const ReaderEnd({
    super.key,
    required this.voiceId, // detail_screen에서 받아오는 것들 초기화
    required this.isSelected,
    required this.lastPage,
    // this.record,
    // this.purchase,
  });

  @override
  _ReaderEndState createState() => _ReaderEndState();
}

class _ReaderEndState extends State<ReaderEnd> {
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

  @override
  Widget build(BuildContext context) {
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
            widget.purchase != null
                ? (widget.purchase == true && widget.record == false
                    ? notRecordUser()
                    : widget.purchase == true && widget.record == true
                        ? allPass()
                        : notPurchaseUser())
                : Container(),
            Expanded(
                flex: SizeConfig.defaultSize!.toInt(),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                    padding:
                        EdgeInsets.only(bottom: SizeConfig.defaultSize! * 4),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FairytalePage(
                            // 다음 화면으로 contetnVoiceId를 가지고 이동
                            voiceId: widget.voiceId,
                            lastPage: widget.lastPage,
                            isSelected: widget.isSelected,
                            // record: widget.record,
                            // purchase: widget.purchase,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
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
                    'lib/images/congratulate1.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  ),
                  Text(
                    'Congratulations on \n completing the reading',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Molengo',
                        fontSize: SizeConfig.defaultSize! * 2.5),
                  ),
                  Image.asset(
                    'lib/images/congratulate2.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  )
                ],
              ),
            ],
          ),
        ));
  }

  Expanded notPurchaseUser() {
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
                    'lib/images/congratulate1.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  ),
                  Text(
                    'Congratulations on \n completing the reading',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Molengo',
                        fontSize: SizeConfig.defaultSize! * 2.5),
                  ),
                  Image.asset(
                    'lib/images/congratulate2.png',
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
                    borderRadius: BorderRadius.all(
                        Radius.circular(SizeConfig.defaultSize! * 3)),
                    border: Border.all(
                      color: const Color.fromARGB(
                          152, 97, 1, 152), // Border의 색상을 지정합니다.
                      width:
                          SizeConfig.defaultSize! * 0.3, // Border의 두께를 지정합니다.
                    ),
                  ),
                  height: SizeConfig.defaultSize! * 11,
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
                          height: SizeConfig.defaultSize!,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(152, 97, 1, 152),
                            borderRadius: BorderRadius.all(
                                Radius.circular(SizeConfig.defaultSize!)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: SizeConfig.defaultSize! * 5,
                              right: SizeConfig.defaultSize! * 5,
                              top: SizeConfig.defaultSize! * 0.2,
                              bottom: SizeConfig.defaultSize! * 0.2,
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  //결제가 끝나면 RecordInfo로 가야 함
                                  MaterialPageRoute(
                                    builder: (context) => const Purchase(),
                                  ),
                                );
                              },
                              child: Text(
                                'Go to Record',
                                style: TextStyle(
                                    fontFamily: 'Molengo',
                                    fontSize: SizeConfig.defaultSize! * 2.3,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
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

  Expanded notRecordUser() {
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
                    'lib/images/congratulate1.png',
                    width: SizeConfig.defaultSize! * 5,
                    alignment: Alignment.topCenter,
                  ),
                  Text(
                    'Congratulations on \n completing the reading',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Molengo',
                        fontSize: SizeConfig.defaultSize! * 2.5),
                  ),
                  Image.asset(
                    'lib/images/congratulate2.png',
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
                    borderRadius: BorderRadius.all(
                        Radius.circular(SizeConfig.defaultSize! * 3)),
                    border: Border.all(
                      color: const Color.fromARGB(
                          152, 97, 1, 152), // Border의 색상을 지정합니다.
                      width:
                          SizeConfig.defaultSize! * 0.3, // Border의 두께를 지정합니다.
                    ),
                  ),
                  height: SizeConfig.defaultSize! * 11,
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
                          height: SizeConfig.defaultSize!,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(152, 97, 1, 152),
                            borderRadius: BorderRadius.all(
                                Radius.circular(SizeConfig.defaultSize!)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: SizeConfig.defaultSize! * 5,
                              right: SizeConfig.defaultSize! * 5,
                              top: SizeConfig.defaultSize! * 0.2,
                              bottom: SizeConfig.defaultSize! * 0.2,
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  //결제가 끝나면 RecordInfo로 가야 함
                                  MaterialPageRoute(
                                    builder: (context) => const RecordInfo(),
                                  ),
                                );
                              },
                              child: Text(
                                'Go to Record',
                                style: TextStyle(
                                    fontFamily: 'Molengo',
                                    fontSize: SizeConfig.defaultSize! * 2.3,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
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
}
