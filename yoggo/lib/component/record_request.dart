import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../size_config.dart';
import 'globalCubit/user/user_cubit.dart';
import 'home/view/home_screen.dart';

class recordRequest extends StatefulWidget {
  const recordRequest({super.key});

  @override
  _recordRequesteState createState() => _recordRequesteState();
}

class _recordRequesteState extends State<recordRequest> {
  bool isLoading = true;
  late String token;
  String completeInferenced = '';

  @override
  void initState() {
    super.initState();
    getToken();
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token')!;
    });
    //print('getToken');
    // loadData(token);
  }

  // Future<void> loadData(String token) async {
  //   print('loadData');

  //   try {
  //     var response = await http.get(
  //       Uri.parse('https://yoggo-server.fly.dev/user/inference'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //     );
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       print(data);
  //       if (data != [] && data.isNotEmpty) {
  //         print('성공');
  //         // 데이터가 빈 값이 아닌 경우
  //         setState(() {
  //           isLoading = false;
  //           completeInferenced = data;
  //         });
  //       } else {
  //         // 데이터가 빈 값인 경우
  //         setState(() {
  //           isLoading = true;
  //           //loadData(token);
  //           Future.delayed(const Duration(seconds: 1), () {
  //             loadData(token);
  //           });
  //         });
  //       }
  //     } else {
  //       // 데이터 요청이 실패한 경우
  //       // 오류 처리
  //       setState(() {
  //         print('오류');

  //         isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     // 네트워크 오류 등 예외 처리
  //     print(e);

  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    print("request페이지");
    print(userState.record);
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
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/images/congratulate2.png',
                              width: SizeConfig.defaultSize! * 5,
                              alignment: Alignment.topCenter,
                            ),
                            SizedBox(
                              width: SizeConfig.defaultSize! * 1.5,
                            ),
                            Text(
                              'Congratulations on \n completing the RECORDING',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Molengo',
                                  fontSize: SizeConfig.defaultSize! * 2.5),
                            ),
                            SizedBox(
                              width: SizeConfig.defaultSize! * 2,
                            ),
                            Image.asset(
                              'lib/images/congratulate1.png',
                              width: SizeConfig.defaultSize! * 5,
                              alignment: Alignment.topCenter,
                            )
                          ],
                        ),
                        SizedBox(
                          height: SizeConfig.defaultSize! * 3,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            'Your voice is well recorded \n We\'ll let you know by PUSH when it\'s done',
                                        style: TextStyle(
                                          fontSize:
                                              SizeConfig.defaultSize! * 2.5,
                                          fontFamily: 'Molengo',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: SizeConfig.defaultSize! * 4,
                        ),
                        Padding(
                            padding: const EdgeInsets.only(),
                            child: GestureDetector(
                              onTap: () async {
                                await userCubit.fetchUser();
                                if (userState.record) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen()),
                                  );
                                }
                              },
                              child: Container(
                                  width: SizeConfig.defaultSize! * 24,
                                  height: SizeConfig.defaultSize! * 4.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA91A),
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            SizeConfig.defaultSize! * 1.5)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'OK',
                                      style: TextStyle(
                                        fontFamily: 'Molengo',
                                        fontSize: SizeConfig.defaultSize! * 2.3,
                                        color: Colors.black,
                                      ),
                                    ),
                                  )),
                            )),
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
