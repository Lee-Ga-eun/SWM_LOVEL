import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:yoggo/component/calendar.dart';
import 'package:yoggo/component/home/view/home.dart';
import 'package:yoggo/component/shop.dart';
import 'package:yoggo/constants.dart';
import 'package:yoggo/main.dart';
import 'package:yoggo/size_config.dart';
import 'package:yoggo/widgets/custom_text.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final AudioPlayer bgmPlayer;
  final int index;

  const CustomBottomNavigationBar({
    super.key,
    required this.index,
    required this.bgmPlayer,
  });
  @override
  _CustomBottomNavigationBarState createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _currentIndex = 2;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Calendar(
                    bgmPlayer: widget.bgmPlayer,
                  )),
        );
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Purchase(
                    bgmPlayer: widget.bgmPlayer,
                  )),
        );
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Purchase(
                    bgmPlayer: widget.bgmPlayer,
                  )),
        );
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Purchase(
                    bgmPlayer: widget.bgmPlayer,
                  )),
        );
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 39 * SizeConfig.defaultSize!,
        height: 7 * SizeConfig.defaultSize!,
        padding: EdgeInsets.only(
            top: 1 * SizeConfig.defaultSize!,
            left: 2.5 * SizeConfig.defaultSize!,
            right: 2.5 * SizeConfig.defaultSize!),
        decoration: const BoxDecoration(
          color: Color(0xffFFFFFF),
          boxShadow: [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 7,
              offset: Offset(0, -4),
              spreadRadius: 0,
            )
          ],
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(22),
            topLeft: Radius.circular(22),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                if (_currentIndex != 0) {
                  if (_currentIndex == 2) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            Calendar(bgmPlayer: widget.bgmPlayer),
                        transitionDuration:
                            const Duration(seconds: 0), // 애니메이션 시간을 0으로 설정
                      ),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            Calendar(bgmPlayer: widget.bgmPlayer),
                        transitionDuration:
                            const Duration(seconds: 0), // 애니메이션 시간을 0으로 설정
                      ),
                    );
                  }
                }
              },
              child: Column(children: [
                Image.asset('lib/images/calendar.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!),
                CustomText('출석체크',
                    style: TextStyle(
                        fontSize: SizeConfig.defaultSize! * 1.2,
                        color: _currentIndex == 0 ? black : grey))
              ]),
            ),
            GestureDetector(
              onTap: () {
                if (_currentIndex != 1) {
                  if (_currentIndex == 2) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            Purchase(bgmPlayer: widget.bgmPlayer),
                        transitionDuration:
                            const Duration(seconds: 0), // 애니메이션 시간을 0으로 설정
                      ),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            Purchase(bgmPlayer: widget.bgmPlayer),
                        transitionDuration:
                            const Duration(seconds: 0), // 애니메이션 시간을 0으로 설정
                      ),
                    );
                  }
                }
              },
              child: Column(children: [
                Image.asset('lib/images/shop.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!),
                CustomText('상점',
                    style: TextStyle(
                        fontSize: SizeConfig.defaultSize! * 1.2,
                        color: _currentIndex == 1 ? black : grey))
              ]),
            ),
            GestureDetector(
              onTap: () {
                if (_currentIndex != 2) {
                  Navigator.of(context).pop();
                }
              },
              child: Column(children: [
                Image.asset('lib/images/home.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!),
                CustomText('홈',
                    style: TextStyle(
                        fontSize: SizeConfig.defaultSize! * 1.2,
                        color: _currentIndex == 2 ? black : grey))
              ]),
            ),
            GestureDetector(
              onTap: () {
                if (_currentIndex != 3) {
                  if (_currentIndex == 2) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            Purchase(bgmPlayer: widget.bgmPlayer),
                        transitionDuration:
                            const Duration(seconds: 0), // 애니메이션 시간을 0으로 설정
                      ),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            Purchase(bgmPlayer: widget.bgmPlayer),
                        transitionDuration:
                            const Duration(seconds: 0), // 애니메이션 시간을 0으로 설정
                      ),
                    );
                  }
                }
              },
              child: Column(children: [
                Image.asset('lib/images/favorite.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!),
                CustomText('즐겨찾기',
                    style: TextStyle(
                        fontSize: SizeConfig.defaultSize! * 1.2,
                        color: _currentIndex == 3 ? black : grey))
              ]),
            ),
            GestureDetector(
              onTap: () {
                if (_currentIndex != 4) {
                  if (_currentIndex == 2) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            Purchase(bgmPlayer: widget.bgmPlayer),
                        transitionDuration:
                            const Duration(seconds: 0), // 애니메이션 시간을 0으로 설정
                      ),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            Purchase(bgmPlayer: widget.bgmPlayer),
                        transitionDuration:
                            const Duration(seconds: 0), // 애니메이션 시간을 0으로 설정
                      ),
                    );
                  }
                }
              },
              child: Column(children: [
                Image.asset('lib/images/search.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!),
                CustomText('검색',
                    style: TextStyle(
                        fontSize: SizeConfig.defaultSize! * 1.2,
                        color: _currentIndex == 4 ? black : grey))
              ]),
            ),
          ],
        ));
  }
}
