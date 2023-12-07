import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:yoggo/component/home/view/home.dart';
import 'package:yoggo/component/shop.dart';
import 'package:yoggo/size_config.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final AudioPlayer bgmPlayer;

  const CustomBottomNavigationBar({
    super.key,
    required this.bgmPlayer,
  });
  @override
  _CustomBottomNavigationBarState createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _currentIndex = 2;

  void _onTabTapped(int index) {
    print(index);
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Purchase(
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39 * SizeConfig.defaultSize!,
      height: 6.7 * SizeConfig.defaultSize!,
      padding: EdgeInsets.only(
          left: 2.5 * SizeConfig.defaultSize!,
          right: 2.5 * SizeConfig.defaultSize!),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
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
      child: BottomNavigationBar(
        backgroundColor: Color(0x00ffffff),
        elevation: 0.0,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
              icon: Column(children: [
                Image.asset('lib/images/calendar.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!)
              ]),
              label: '출석체크'),
          BottomNavigationBarItem(
              icon: Column(children: [
                Image.asset('lib/images/shop.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!)
              ]),
              label: '상점'),
          BottomNavigationBarItem(
              icon: Column(children: [
                Image.asset('lib/images/home.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!)
              ]),
              label: '홈'),
          BottomNavigationBarItem(
              icon: Column(children: [
                Image.asset('lib/images/favorite.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!)
              ]),
              label: '즐겨찾기'),
          BottomNavigationBarItem(
              icon: Column(children: [
                Image.asset('lib/images/search.png',
                    width: 2.8 * SizeConfig.defaultSize!),
                SizedBox(height: 0.6 * SizeConfig.defaultSize!)
              ]),
              label: '검색'),
        ],
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.black,
        showUnselectedLabels: true,
        selectedFontSize: SizeConfig.defaultSize! * 1.2,
        unselectedFontSize: SizeConfig.defaultSize! * 1.2,
        selectedLabelStyle: TextStyle(fontFamily: 'Suit'),
        // enableFeedback: false,
      ),
    );
  }
}
