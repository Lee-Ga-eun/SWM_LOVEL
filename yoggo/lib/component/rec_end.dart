import 'package:amplitude_flutter/amplitude.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/Repositories/Repository.dart';
import 'package:yoggo/component/bookIntro/view/book_intro.dart';
import '../size_config.dart';
import 'bookIntro/viewModel/book_intro_cubit.dart';
import 'bookIntro/viewModel/book_voice_cubit.dart';
import 'globalCubit/user/user_cubit.dart';
import 'home/view/home.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:yoggo/component/voice.dart';

import 'home/viewModel/home_screen_book_model.dart';

class RecEnd extends StatefulWidget {
  final int contentId;
  final AudioPlayer bgmPlayer;

  const RecEnd({super.key, required this.contentId, required this.bgmPlayer});

  @override
  _RecEndState createState() => _RecEndState();
}

class _RecEndState extends State<RecEnd> {
  bool isLoading = true;
  late String token;
  String completeInferenced = '';
  late HomeScreenBookModel? book;
  late DataRepository dataRepository;

  @override
  void initState() {
    super.initState();
    dataRepository = RepositoryProvider.of<DataRepository>(context);

    if (widget.contentId != 0) {
      book = DataRepository.getBookModelByContentId(widget.contentId);
    } else {
      book = null;
    }

    getToken();
    _sendRecEndViewEvent();
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token')!;
    });

    //print('getToken');
    // loadData(token);
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Amplitude amplitude = Amplitude.getInstance();

  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    print(userState.record);
    SizeConfig().init(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFAE4),
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
                              '녹음-축하',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'font-basic'.tr(),
                                  fontSize: SizeConfig.defaultSize! * 2.5),
                            ).tr(),
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
                            Center(
                              child: Text(
                                '녹음-푸쉬알림',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: SizeConfig.defaultSize! * 2.5,
                                  fontFamily: 'font-basic'.tr(),
                                  color: Colors.black,
                                ),
                              ).tr(),
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
                                //   await userCubit.fetchUser();
                                //if (userState.record) {

                                // OneSignal.shared
                                //     .promptUserForPushNotificationPermission()
                                //     .then((accepted) {
                                //   print("Accepted permission: $accepted");
                                // });
                                if (OneSignal.Notifications.permission !=
                                    true) {
                                  OneSignal.Notifications.requestPermission(
                                          true)
                                      .then((accepted) {
                                    print("Accepted permission: $accepted");
                                  });
                                }

                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                                if (widget.contentId == 0) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VoiceProfile(
                                          bgmPlayer: widget.bgmPlayer,
                                        ),
                                      ));
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MultiBlocProvider(
                                              providers: [
                                                BlocProvider<BookVoiceCubit>(
                                                  create: (context) =>
                                                      BookVoiceCubit(
                                                          dataRepository)
                                                        ..loadBookVoiceData(
                                                            widget.contentId),
                                                ),
                                                BlocProvider<BookIntroCubit>(
                                                  create: (context) =>
                                                      // BookIntroCubit(),
                                                      // DataCubit()..loadHomeBookData()
                                                      BookIntroCubit(
                                                          dataRepository)
                                                        ..loadBookIntroData(
                                                            widget.contentId),
                                                )
                                              ],
                                              child: BookIntro(
                                                id: widget.contentId,
                                                title: book!.title,
                                                thumbUrl: book!.thumbUrl,
                                                bgmPlayer: widget.bgmPlayer,
                                              ),
                                            )),
                                  );
                                }

                                //    }
                              },
                              child: Container(
                                  width: SizeConfig.defaultSize! * 24,
                                  height: SizeConfig.defaultSize! * 4.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA91A),
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            SizeConfig.defaultSize! * 3)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'OK',
                                      style: TextStyle(
                                        fontFamily: 'font-basic'.tr(),
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

  Future<void> _sendRecEndViewEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_end_view',
        parameters: <String, dynamic>{},
      );
      amplitude.logEvent('rec_end_view', eventProperties: {});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }
}
