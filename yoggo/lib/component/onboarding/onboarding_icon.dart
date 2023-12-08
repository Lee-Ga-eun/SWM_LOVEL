import 'package:http/http.dart' as http;
import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/globalCubit/user/user_cubit.dart';
import 'package:yoggo/component/home/view/home.dart';
import 'package:yoggo/constants.dart';
import 'package:yoggo/size_config.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:yoggo/widgets/custom_text.dart';

class OnboardingIcon extends StatefulWidget {
  final String name;

  const OnboardingIcon({
    super.key,
    required this.name,
  });

  @override
  _OnboardingIconState createState() => _OnboardingIconState();
}

class _OnboardingIconState extends State<OnboardingIcon> {
  String userIcon = 'human1';
  String? token;
  @override
  void initState() {
    super.initState();
    getToken();
    // _loadAd();
  }

  @override
  void dispose() {
    super.dispose();
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
            child: Text(
              '앱종료-질문',
              style: TextStyle(
                fontSize: SizeConfig.defaultSize! * 2.5,
                fontFamily: 'font-basic'.tr(),
              ),
            ).tr(),
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
                      child: Text(
                        '답변-부정',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'font-basic'.tr(),
                          fontSize: 2.2 * SizeConfig.defaultSize!,
                        ),
                      ).tr(),
                    ),
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
                      child: Text(
                        '답변-긍정',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'font-basic'.tr(),
                          fontSize: 2.2 * SizeConfig.defaultSize!,
                        ),
                      ).tr(),
                    ),
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

  Future<void> sendIcon(userIcon) async {
    await dotenv.load(fileName: ".env");
    // API에서 모든 책 페이지 데이터를 불러와 pages 리스트에 저장
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token')!;
    if (userIcon != '') {
      final url = Uri.parse('${dotenv.get("API_SERVER")}user/modifyIcon');
      final body = jsonEncode({'icon': userIcon});
      var response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        context.read<UserCubit>().fetchUser();
      } else {
        // 에러 처리
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final userCubit = context.watch<UserCubit>();
    final sw = (MediaQuery.of(context).size.width -
        MediaQuery.of(context).padding.left -
        MediaQuery.of(context).padding.right);
    final sh = (MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom);
    SizeConfig().init(context);

    final userState = userCubit.state;

    SizeConfig().init(context);

    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit; // Return true to exit the app, false to stay in the app
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: bkground,
              ),
              child: SafeArea(
                minimum: EdgeInsets.only(
                    left: SizeConfig.defaultSize! * 4,
                    right: SizeConfig.defaultSize! * 4,
                    top: SizeConfig.defaultSize! * 12,
                    bottom: SizeConfig.defaultSize! * 10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText('${widget.name}님이 사용할\n아이콘을 선택해 주세요!'.tr(),
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 2.7 * SizeConfig.defaultSize!)),
                          SizedBox(height: 5 * SizeConfig.defaultSize!),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  selectIcon('human1'),
                                  selectIcon('human2'),
                                  selectIcon('human3'),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  selectIcon('human4'),
                                  selectIcon('human5'),
                                  selectIcon('human6'),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  selectIcon('human7'),
                                  selectIcon('human8'),
                                  selectIcon('human9'),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  selectIcon('human10'),
                                  selectIcon('human11'),
                                  selectIcon('human12'),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                      Container(
                        child: GestureDetector(
                          onTap: () {
                            sendIcon(userIcon);
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomeScreen()));
                          },
                          child: Container(
                            height: SizeConfig.defaultSize! * 5.8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  SizeConfig.defaultSize! * 3),
                              color: orangeDark,
                            ),
                            child: Center(
                              child: CustomText(
                                '다음'.tr(),
                                style: TextStyle(
                                    color: white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 2 * SizeConfig.defaultSize!),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
              ),

              //),
            )
          ],
        ),
      ),
    );
  }

  GestureDetector selectIcon(String icon) {
    return GestureDetector(
        onTap: () {
          setState(() {
            userIcon = icon;
          });
        },
        child: Stack(children: [
          userIcon == icon
              ? Positioned(
                  left: 0.3 * SizeConfig.defaultSize!,
                  top: 0.0 * SizeConfig.defaultSize!,
                  child: Container(
                    height: 9.2 * SizeConfig.defaultSize!,
                    width: 9.4 * SizeConfig.defaultSize!,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: orangeDark),
                  ),
                )
              : Container(),
          Image.asset('lib/images/icon/$icon.png',
              width: 10 * SizeConfig.defaultSize!),
        ]));
  }
}
