import 'package:http/http.dart' as http;
import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/globalCubit/user/user_cubit.dart';
import 'package:yoggo/component/onboarding/onboarding_icon.dart';
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

class OnboardingName extends StatefulWidget {
  const OnboardingName({
    Key? key,
  }) : super(key: key);

  @override
  _OnboardingNameState createState() => _OnboardingNameState();
}

class _OnboardingNameState extends State<OnboardingName> {
  String userName = '';
  bool isKeyboardVisible = false;
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

  Future<void> sendName() async {
    await dotenv.load(fileName: ".env");
    // API에서 모든 책 페이지 데이터를 불러와 pages 리스트에 저장
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token')!;
    if (userName != '') {
      final url = Uri.parse('${dotenv.get("API_SERVER")}user/modifyName');
      final body = jsonEncode({'name': userName});
      var response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData);
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

    KeyboardVisibilityController().onChange.listen((bool visible) {
      setState(() {
        isKeyboardVisible = visible;
      });
    });

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
                          CustomText('LOVEL에서 사용할\n이름을 입력해 주세요!'.tr(),
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 2.7 * SizeConfig.defaultSize!)),
                          SizedBox(height: 3 * SizeConfig.defaultSize!),
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                userName = value;
                              });
                            },
                            style: TextStyle(
                                fontFamily: 'Suit',
                                fontWeight: FontWeight.w500,
                                fontSize: 2.2 * SizeConfig.defaultSize!),
                            cursorColor: orangeDark,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(3),
                              hintText: '이름 입력'.tr(),
                              hintStyle: TextStyle(
                                  fontFamily: 'Suit',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 2.2 * SizeConfig.defaultSize!),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  width: 3,
                                  color: black.withOpacity(0.5), // 외곽선의 두께 조절
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  width: 3,
                                  color: orangeDark, // 외곽선의 두께 조절
                                ),
                              ),
                              focusColor: orangeDark,
                              filled: false,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        child: GestureDetector(
                          onTap: () {
                            if (userName != '') {
                              sendName();
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => OnboardingIcon(
                                            name: userName,
                                          )));
                            } else {
                              print('userName 입력해 주세요!');
                              // 구현 필요
                            }
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
    ;
  }
}
