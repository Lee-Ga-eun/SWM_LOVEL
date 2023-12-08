import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:amplitude_flutter/amplitude.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:yoggo/component/bookPage/view/book_page.dart';
import 'package:yoggo/size_config.dart';
import 'package:yoggo/widgets/custom_text.dart';
import 'package:yoggo/widgets/navigation_bar.dart';
import 'globalCubit/user/user_cubit.dart';

class Calendar extends StatefulWidget {
  final AudioPlayer bgmPlayer;

  const Calendar({
    super.key,
    required this.bgmPlayer,
  });

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  // 받을 수 있는 포인트 day : availableGetPoint // 1일차, 2일차 ...
  // 마지막으로 받은 날짜: lastPointYMD // 2023년9월22일
  // 마지막으로 받은 포인트의 일수: lastPointDay --> 1일차, 2일차, 3일차... --> 마지막 기록이 1일차이면 2일차 포인트를 받게 해야한다
  bool openCalendar = true;
  late int availableGetPoint;
  late List<String> claim;
  bool wantClaim = false;
  String lastPointYMD = '';
  int lastPointDay = -1;
  String formattedTime = '';
  final scores = [100, 100, 300, 100, 100, 300, 500];
  bool _userEarnedReward = false;
  bool neverRequestedPermission = false;

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  @override
  void initState() {
    super.initState();
    print('hi');
    Future.delayed(Duration.zero, () async {
      await saveRewardStatus();
    });
    _openCalendarFunc();
  }

  @override
  void dispose() {
    // TODO: Add cleanup code
    super.dispose();
  }

  void _openCalendarFunc() async {
    // setState(() {
    //   showSecondOverlay = false;
    // });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime currentTime = DateTime.now();
    formattedTime = DateFormat('yyyy-MM-dd').format(currentTime);
    lastPointYMD = prefs.getString('lastPointYMD')!;
    availableGetPoint = prefs.getInt('availableGetPoint')!;
    claim = prefs.getStringList('claim')!;

    // print(lastPointYMD);
    // print(formattedTime);
    if (lastPointDay == 7 && prefs.getString('lastPointYMD') != formattedTime) {
      //저장된 lastPointDay가 7이고 다음 날 들어왔으면 --> 즉 포인트 다시 리셋되어야 하면
      setState(() {
        lastPointDay = 0;
        claim = ['0', '0', '0', '0', '0', '0', '0'];
        prefs.setStringList("claim", claim);
        prefs.setInt('lastPointDay', 0);
        prefs.setInt('availableGetPoint', 1);
        lastPointDay = prefs.getInt('lastPointDay')!;
        availableGetPoint = prefs.getInt('availableGetPoint')!;
      });
    }

    setState(() {
      openCalendar = true;
    });
  }

  void _closeCalendarFunc() {
    setState(() {
      openCalendar = false;
    });
  }

  Future<String> plusPoint(int plusPoint) async {
    final url = '${dotenv.get("API_SERVER")}point/plus';
    final response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'point': plusPoint + 0}));
    if (response.statusCode == 200) {
      // UserCubit().fetchUser();

      Amplitude.getInstance()
          .setUserProperties({'point': json.decode(response.body)[0]['point']});
      context.read<UserCubit>().fetchUser();
      return response.statusCode.toString();
    } else if (response.statusCode == 400) {
      return json.decode(response.body)[0].toString();
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  Future<void> claimSuccess(int multiple) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
    int tmp = prefs.getInt('availableGetPoint')!;

    // 포인트 증가 & 큐빗 반영

    print('다음 받을 수 있는 일차 $tmp'); // 다음날 받을 수 있는
    // print(
    //     '다음 날 받게 될 포인트 점수 ${scores[availableGetPoint - 1]}');
    print('마지막으로 받은 일차 $lastPointDay ');
    print('현재 날짜 $formattedDate');
    print('마지막으로 받은 시간 ${prefs.getString('lastPointYMD')}');

    if (formattedDate != prefs.getString('lastPointYMD') &&
        tmp != lastPointDay) {
      // 지금 접속한 날짜와 마지막으로 포인트 받은 날짜가 동일하면 아무것도 일어나지 않는다
      // 다를 경우에만 변화가 생긴다
      // 포인트를 이미 받지 않은 상태여야 한다
      prefs.setInt('availableGetPoint', tmp + 1);
      prefs.setString('lastPointYMD', formattedDate); // 시간 현재 시간으로 업데이트
      prefs.setInt('lastPointDay', lastPointDay + 1);
      prefs.setStringList('claim', claim);
      var userState = context.read<UserCubit>().state;
      multiple == 1
          ? _sendCalClaimSuccessEvent(
              userState.point, lastPointDay, scores[lastPointDay] * multiple)
          : _sendCalClaimAdSuccessEvent(
              userState.point, lastPointDay, scores[lastPointDay] * multiple);
      claim[lastPointDay] = multiple.toString();
      prefs.setStringList('claim', claim);
      plusPoint(scores[lastPointDay] * multiple);
      setState(() {
        lastPointDay += 1;
        lastPointYMD = formattedDate;
        availableGetPoint = tmp + 1;
      });
      if (multiple == 1 && lastPointDay >= 3) {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          inAppReview.requestReview();
        }
      }
    }
  }

  Future<void> saveRewardStatus() async {
    DateTime currentTime = DateTime.now();

    formattedTime = DateFormat('yyyy-MM-dd').format(currentTime);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('availableGetPoint') == null) {
      // 첫사용자인 경우
      prefs.setInt('availableGetPoint', 1); // 1일차 포인트를 받을 수 있음
      availableGetPoint = 1;
      prefs.setStringList('claim', ['0', '0', '0', '0', '0', '0', '0']);
    } else {
      availableGetPoint = prefs.getInt('availableGetPoint')!;
    }
    if (prefs.getStringList('claim') == null) {
      // 첫사용자인 경우
      prefs.setStringList('claim', ['0', '0', '0', '0', '0', '0', '0']);
      claim = ['0', '0', '0', '0', '0', '0', '0'];
    } else {
      claim = prefs.getStringList('claim')!;
    }

    if (prefs.getString('lastPointYMD') == null) {
      // 내가 마지막으로 받은 날짜
      prefs.setString('lastPointYMD', ''); //
      lastPointYMD = '';
    } else {
      lastPointYMD = prefs.getString('lastPointYMD')!;
    }
    if (prefs.getInt('lastPointDay') == null) {
      // 내가 마지막으로 받은 일차
      prefs.setInt('lastPointDay', 0); // 일차
      lastPointDay = 0;
    } else {
      lastPointDay = prefs.getInt('lastPointDay')!;
    }
    openCalendar = lastPointYMD != formattedTime;
  }

  bool _isAdLoading = false; // 광고 로딩 중 여부를 나타내는 변수

  void _loadRewardedAd() {
    setState(() {
      _isAdLoading = true; // 광고 로딩 중임을 나타내도록 상태를 업데이트
    });
    RewardedAd.load(
      adUnitId: Platform.isIOS
          ? dotenv.get("ADMOB_ios")
          : dotenv.get("ADMOB_android"),
      // "ca-app-pub-3940256099942544/5224354917", // test
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          setState(() {
            _isAdLoading = false;
          });
          print('Ad was loaded.');
          _rewardedAd = ad;
          _userEarnedReward = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (RewardedAd ad) =>
                print('Ad showed fullscreen content.'),
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              if (_userEarnedReward) {
                if (OneSignal.Notifications.permission != true &&
                    neverRequestedPermission) {
                  OneSignal.Notifications.requestPermission(true);
                  neverRequestedPermission = false;
                }
              }
              print('Ad dismissed fullscreen content.');
              setState(() {
                _isAdLoaded = false;
              });
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              print('Ad failed to show fullscreen content.');
              _rewardedAd = null;
            },
            onAdImpression: (RewardedAd ad) =>
                print('Ad recorded an impression.'),
          );

          setState(() {
            _isAdLoaded = true;
          });

          _showRewardedAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      print('The rewarded ad wasn\'t ready yet.');

      return;
    }
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print(reward.amount);
      print('User earned the reward.');

      claimSuccess(2);
      // OneSignal.shared
      //     .promptUserForPushNotificationPermission()
      //     .then((accepted) {
      //   print("Accepted permission: $accepted");
      // });
      _userEarnedReward = true;

      // 여기에서 reward를 처리할 수 있습니다.
    });
  }

  Container eachDayPoint({
    coinImage,
    compare,
    point,
    lastPointYMD,
  }) {
    return Container(
      width: SizeConfig.defaultSize! * 7,
      height: SizeConfig.defaultSize! * 8.8,
      decoration: const BoxDecoration(
          color: Color.fromARGB(255, 222, 220, 220),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Stack(alignment: Alignment.topCenter, children: [
        lastPointYMD != formattedTime && compare == availableGetPoint
            ? Container(
                width: SizeConfig.defaultSize! * 7,
                height: SizeConfig.defaultSize! * 8.8,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 5, color: Color(0xFF9866FF)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ))
            : Container(),
        Positioned(
          top: coinImage == 'lib/images/oneCoin.png'
              ? 1.9 * SizeConfig.defaultSize!
              : 0.9 * SizeConfig.defaultSize!,
          child: Image.asset(coinImage, width: 4.332 * SizeConfig.defaultSize!),
        ),
        lastPointDay >= compare
            ? Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  'lib/images/completed.png',
                  width: SizeConfig.defaultSize! * 4.6,
                ))
            : Container(),
        claim[compare - 1] == '2'
            ? Positioned(
                right: 0,
                child: Image.asset(
                  'lib/images/double.png',
                  width: SizeConfig.defaultSize! * 4.6,
                ),
              )
            : Container(),
        Positioned(
          bottom: 0.6 * SizeConfig.defaultSize!,
          child: CustomText(
            point,
            style: TextStyle(
                fontFamily: 'Suit',
                fontWeight: FontWeight.w700,
                fontSize: SizeConfig.defaultSize! * 1.6),
          ),
        ),
      ]),
    );
  }

  Container eachDayPointDouble({
    coinImage,
    compare,
    point,
    lastPointYMD,
  }) {
    return Container(
      width: SizeConfig.defaultSize! * 15,
      height: SizeConfig.defaultSize! * 8.8,
      decoration: const BoxDecoration(
          color: Color.fromARGB(255, 222, 220, 220),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Stack(alignment: Alignment.topCenter, children: [
        lastPointYMD != formattedTime && compare == availableGetPoint
            ? Container(
                width: SizeConfig.defaultSize! * 7,
                height: SizeConfig.defaultSize! * 8.8,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 5, color: Color(0xFF9866FF)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ))
            : Container(),
        Positioned(
          top: 1.8 * SizeConfig.defaultSize!,
          left: 1.5 * SizeConfig.defaultSize!,
          child: Image.asset(coinImage, width: 7.632 * SizeConfig.defaultSize!),
        ),
        lastPointDay >= compare
            ? Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  'lib/images/completed.png',
                  width: SizeConfig.defaultSize! * 4.6,
                ))
            : Container(),
        claim[compare - 1] == '2'
            ? Positioned(
                right: 0,
                child: Image.asset(
                  'lib/images/double.png',
                  width: SizeConfig.defaultSize! * 4.6,
                ),
              )
            : Container(),
        Positioned(
          // alignment: compare != 7 ? Alignment.bottomCenter : Alignment.center,
          bottom: 3.4 * SizeConfig.defaultSize!,
          right: 1.6 * SizeConfig.defaultSize!,
          child: CustomText(
            point,
            style: TextStyle(
                fontFamily: 'Suit',
                fontWeight: FontWeight.w700,
                fontSize: SizeConfig.defaultSize! * 1.6),
          ),
        ),
      ]),
    );
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Amplitude amplitude = Amplitude.getInstance();

  @override
  Widget build(BuildContext context) {
    final sw = (MediaQuery.of(context).size.width -
        MediaQuery.of(context).padding.left -
        MediaQuery.of(context).padding.right);
    final sh = (MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom);
    SizeConfig().init(context);
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: Color(0xFFFFFAE4),
      bottomNavigationBar: CustomBottomNavigationBar(
        index: 0,
        bgmPlayer: widget.bgmPlayer,
      ),
      body: SafeArea(
        child: Center(
            child: Container(
          width: 35 * SizeConfig.defaultSize!,
          height: 47.5 * SizeConfig.defaultSize!,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.all(Radius.circular(SizeConfig.defaultSize!)),
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(1),
          ),
          child: Stack(
            children: [
              Column(children: [
                SizedBox(
                  height: SizeConfig.defaultSize! * 9,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 35 * SizeConfig.defaultSize!,
                      child: CustomText(
                        "달력-안내".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          //fontFamily: 'font-basic'.tr(),
                          fontSize: 2.2 *
                              SizeConfig.defaultSize! *
                              double.parse('font-ratio'.tr()),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: SizeConfig.defaultSize! * 2,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    eachDayPoint(
                        coinImage: 'lib/images/oneCoin.png',
                        compare: 1,
                        point: '100',
                        lastPointYMD: lastPointYMD),
                    SizedBox(
                      width: SizeConfig.defaultSize!,
                    ),
                    //2일차
                    eachDayPoint(
                        coinImage: 'lib/images/oneCoin.png',
                        compare: 2,
                        point: '100',
                        lastPointYMD: lastPointYMD),
                    SizedBox(
                      width: SizeConfig.defaultSize!,
                    ),

                    //3일차
                    eachDayPoint(
                        coinImage: 'lib/images/threeCoins.png',
                        compare: 3,
                        point: '300',
                        lastPointYMD: lastPointYMD),
                    SizedBox(
                      width: SizeConfig.defaultSize!,
                    ),

                    eachDayPoint(
                        // 4일차
                        coinImage: 'lib/images/oneCoin.png',
                        compare: 4,
                        point: '100',
                        lastPointYMD: lastPointYMD),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.defaultSize! * 2,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    eachDayPoint(
                        // 5일차
                        coinImage: 'lib/images/oneCoin.png',
                        compare: 5,
                        point: '100',
                        lastPointYMD: lastPointYMD),
                    SizedBox(
                      width: SizeConfig.defaultSize!,
                    ),

                    eachDayPoint(
                        // 6일차
                        coinImage: 'lib/images/threeCoins.png',
                        compare: 6,
                        point: '300',
                        lastPointYMD: lastPointYMD),
                    SizedBox(
                      width: SizeConfig.defaultSize!,
                    ),

                    // 7일차
                    eachDayPointDouble(
                        // 6일차
                        coinImage: 'lib/images/fiveCoins.png',
                        compare: 7,
                        point: '500',
                        lastPointYMD: lastPointYMD),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.defaultSize! * 2,
                ),
                GestureDetector(
                  onTap: () async {
                    _sendCalClaimNowClickEvent(userState.point);
                    lastPointYMD != formattedTime
                        ? setState(() {
                            wantClaim = true;
                          })
                        : null;
                  },
                  child: Container(
                      width: SizeConfig.defaultSize! * 31,
                      height: SizeConfig.defaultSize! * 5.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            1.4 * SizeConfig.defaultSize!),
                        color: lastPointYMD != formattedTime
                            ? const Color(0xFFFF8700)
                            : Colors.grey,
                      ), // 배경색 설정

                      child: Center(
                        child: CustomText(
                          textAlign: TextAlign.center,
                          '출첵'.tr(),
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.defaultSize! * 2),
                        ),
                      )),
                ),
              ]),
              Visibility(
                  visible: _isAdLoading,
                  child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: sw * 0.08,
                        height: sw * 0.08,
                        child: const CircularProgressIndicator(
                          color: Color(0xFFF39E09),
                        ),
                      ))),
              Visibility(
                  visible: wantClaim,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        wantClaim = false;
                      });
                      _sendCalClaimClickEvent(userState.point, true);

                      lastPointYMD != formattedTime
                          ? {
                              claimSuccess(1),
                              if (OneSignal.Notifications.permission != true &&
                                  neverRequestedPermission)
                                {
                                  OneSignal.Notifications.requestPermission(
                                      true),
                                  neverRequestedPermission = false,
                                }
                            }
                          : null;
                    },
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(SizeConfig.defaultSize!),
                            ),
                            color: Color(0x60000000))),
                  )),
              Visibility(
                  visible: wantClaim,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15)),
                        color: Colors.white,
                      ),
                      height: 29 * SizeConfig.defaultSize!,
                      width: 32 * SizeConfig.defaultSize!,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: SizeConfig.defaultSize! * 1),
                            SizedBox(
                              height: 12.5 * SizeConfig.defaultSize!,
                              child: Image.asset('lib/images/pointBox.png',
                                  width: 12.5 * SizeConfig.defaultSize!),
                            ),
                            SizedBox(height: SizeConfig.defaultSize! * 2),
                            GestureDetector(
                              onTap: () async {
                                _sendCalClaimAdClickEvent(userState.point);

                                setState(() {
                                  wantClaim = false;
                                });
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                DateTime currentDate = DateTime.now();
                                String formattedDate = DateFormat('yyyy-MM-dd')
                                    .format(currentDate);
                                int tmp = prefs.getInt('availableGetPoint')!;
                                lastPointYMD != formattedTime
                                    ? {
                                        if (formattedDate !=
                                                prefs.getString(
                                                    'lastPointYMD') &&
                                            tmp != lastPointDay)
                                          {
                                            _isAdLoaded
                                                ? null
                                                : _loadRewardedAd(),
                                          }
                                      }
                                    : null;
                              },
                              child: Container(
                                  width: 24 * SizeConfig.defaultSize!,
                                  height: 5 * SizeConfig.defaultSize!,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        1.4 * SizeConfig.defaultSize!),
                                    color: lastPointYMD != formattedTime
                                        ? const Color(0xFFFF8700)
                                        : Colors.grey,
                                  ), // 배경색 설정

                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'lib/images/slate1.png',
                                          width: 2 * SizeConfig.defaultSize!,
                                        ),
                                        Text(
                                          '출첵-광고',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize:
                                                SizeConfig.defaultSize! * 2.2,
                                            fontFamily: 'font-point'.tr(),
                                          ),
                                        ).tr(),
                                      ],
                                    ),
                                  )),
                            ),
                            SizedBox(height: SizeConfig.defaultSize!),
                            Container(
                              width: 23 * SizeConfig.defaultSize!,
                              child: Center(
                                child: GestureDetector(
                                  onTap: () async {
                                    _sendCalClaimClickEvent(
                                        userState.point, false);
                                    setState(() {
                                      wantClaim = false;
                                    });
                                    lastPointYMD != formattedTime
                                        ? {
                                            claimSuccess(1),
                                            if (OneSignal.Notifications
                                                        .permission !=
                                                    true &&
                                                neverRequestedPermission)
                                              {
                                                OneSignal.Notifications
                                                    .requestPermission(true),
                                                neverRequestedPermission =
                                                    false,
                                              }
                                          }
                                        : null;
                                  },
                                  child: Text(
                                    '출첵-일반',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: SizeConfig.defaultSize! * 1.5,
                                      fontFamily: 'font-claim'.tr(),
                                    ),
                                  ).tr(),
                                ),
                              ),
                            ),
                          ]),
                    ),
                  ))
            ],
          ),
        )),
      ),
    );
  }

  Future<void> _sendCalXClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'cal_x_click',
        parameters: <String, dynamic>{'point_now': pointNow},
      );
      await amplitude.logEvent(
        'cal_x_click',
        eventProperties: {'point_now': pointNow},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendCalClickEvent(pointNow, dayNow, alreadyClaimed) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'cal_click',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'day_now': dayNow,
          'already_claimed': alreadyClaimed
        },
      );
      await amplitude.logEvent(
        'cal_click',
        eventProperties: {
          'point_now': pointNow,
          'day_now': dayNow,
          'already_claimed': alreadyClaimed
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendCalClaimClickEvent(pointNow, background) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'cal_claim_click',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'background': background
        },
      );
      await amplitude.logEvent(
        'cal_claim_click',
        eventProperties: {
          'point_now': pointNow,
          'background': background ? 'true' : 'false'
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendCalClaimAdClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'cal_claim_ad_click',
        parameters: <String, dynamic>{'point_now': pointNow},
      );
      await amplitude.logEvent(
        'cal_claim_ad_click',
        eventProperties: {'point_now': pointNow},
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendCalClaimSuccessEvent(pointNow, dayNow, pointGet) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
          name: 'cal_claim_success',
          parameters: <String, dynamic>{
            'point_now': pointNow,
            'day_now': dayNow,
            'point_get': pointGet
          });
      await amplitude.logEvent(
        'cal_claim_success',
        eventProperties: {
          'point_now': pointNow,
          'day_now': dayNow,
          'point_get': pointGet
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendCalClaimAdSuccessEvent(pointNow, dayNow, pointGet) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
          name: 'cal_claim_ad_success',
          parameters: <String, dynamic>{
            'point_now': pointNow,
            'day_now': dayNow,
            'point_get': pointGet
          });
      await amplitude.logEvent(
        'cal_claim_ad_success',
        eventProperties: {
          'point_now': pointNow,
          'day_now': dayNow,
          'point_get': pointGet
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendCalClaimNowClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'cal_claim_now_click',
        parameters: <String, dynamic>{
          'point_now': pointNow,
        },
      );
      await amplitude.logEvent(
        'cal_claim_now_click',
        eventProperties: {
          'point_now': pointNow,
        },
      );
    } catch (e) {
      print('Failed to log event: $e');
    }
  }
}
