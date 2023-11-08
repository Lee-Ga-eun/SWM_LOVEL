import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yoggo/component/home/view/home.dart';
import 'package:yoggo/component/rec_info_1.dart';
import 'package:yoggo/size_config.dart';

import 'dart:io' show Platform;

import 'globalCubit/user/user_cubit.dart';
import 'package:amplitude_flutter/amplitude.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

class Purchase extends StatefulWidget {
  final FirebaseRemoteConfig abTest;
  const Purchase({super.key, required this.abTest});

  @override
  _PurchaseState createState() => _PurchaseState();
}

class AppData {
  static final AppData _appData = AppData._internal();

  bool entitlementIsActive = false;
  String appUserID = '';

  factory AppData() {
    return _appData;
  }
  AppData._internal();
}

class _PurchaseState extends State<Purchase> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> view = [];
  bool _isLoading = false;
  late String token;
  bool paySuccessed = false;
  Future fetch() async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (available) {
      // 제품 정보를 로드
      // const Set<String> ids = <String>{'product1'};
      // ProductDetailsResponse res =
      //     await InAppPurchase.instance.queryProductDetails(ids);
      // view = res.productDetails;

      _inAppPurchase.purchaseStream.listen((List<PurchaseDetails> event) {
        PurchaseDetails e = event[0];
        print(
            "📌 EVENT $e - ${e.status} - ${e.productID} - ${e.pendingCompletePurchase}");

        /// 구매 여부 pendingCompletePurchase - 승인 true / 취소 false
        if (e.pendingCompletePurchase) {
          if (!mounted) return;
          _inAppPurchase.completePurchase(e);
          setState(() {
            _isLoading = false;
          });

          if (e.status == PurchaseStatus.error) {
            print(e.error);
            return;
          }
          if (e.status == PurchaseStatus.canceled) {
            print(e.error);
            return;
          }
          if (e.status == PurchaseStatus.purchased ||
              e.status == PurchaseStatus.restored) {
            if (e.productID == 'monthly_ios' ||
                e.productID == 'product1:product1' ||
                e.productID == 'product1') {
              //subSuccess();
              _sendSubSuccessEvent();
              context.read<UserCubit>().successSubscribe();
              amplitude.setUserProperties({'subscribe': true});
              final userState = context.read<UserCubit>().state;

              if (userState.record) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      abTest: widget.abTest,
                    ),
                  ),
                );
              } else {
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => RecInfo(
                //       abTest: widget.abTest,
                //     ),
                //   ),
                // );
              }
            } else {
              paySuccess(e.productID.substring(7));
              context.read<UserCubit>().fetchUser();
              setState(() {
                paySuccessed = true;
              });
            }
          }
        }
      });
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getToken();
    _sendShopViewEvent();
    Future(fetch);
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token')!;
    });
  }

  Future<void> subSuccess() async {
    await getToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('purchase', true);
    var url = Uri.parse('${dotenv.get("API_SERVER")}user/successPurchase');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      // _sendSubSuccessEvent();
      print('구독 성공 완료');
      context.read<UserCubit>().fetchUser();
    } else {
      _sendSubFailEvent(response.statusCode);
      throw Exception('Failed to start inference');
    }
  }

  Future<void> subStart() async {
    try {
      Offerings? offerings = await Purchases.getOfferings();
      if (offerings.getOffering("default")!.availablePackages.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        var product = offerings.getOffering("default")!.availablePackages;
        CustomerInfo customerInfo = await Purchases.purchasePackage(product[0]);
        EntitlementInfo? entitlement = customerInfo.entitlements.all['pro'];
        // final appData = AppData();
        // appData.entitlementIsActive = entitlement?.isActive ?? false;
        // if (entitlement!.isActive) {
        //   subSuccess();
        // }
        // Display packages for sale
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('subStart 안에서 오류남');
      // optional error handling
    }

    // const Set<String> products = {'product1'};
    // final ProductDetailsResponse response =
    //     await InAppPurchase.instance.queryProductDetails(products);
    // if (response.notFoundIDs.isNotEmpty) {
    //   print('제품이 없어요');
    //   return;
    // }

    // final ProductDetails productDetails = response.productDetails.first;

    // final PurchaseParam purchaseParam = PurchaseParam(
    //   productDetails: productDetails,
    // );
    // try {
    //   final bool success = await InAppPurchase.instance.buyNonConsumable(
    //     purchaseParam: purchaseParam,
    //   );
    // } catch (error) {
    //   // 결제 실패
    //   print('결제 실패했어요');
    // }
  }

  Future<void> paySuccess(points) async {
    await getToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('purchase', true);
    var url = Uri.parse('${dotenv.get("API_SERVER")}point/plus');
    var response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'point': toInt(points)}));
    if (response.statusCode == 200) {
      var userState = context.read<UserCubit>().state;
      _sendBuyPointSuccessEvent(userState.point, points);
      Amplitude.getInstance()
          .setUserProperties({'point': json.decode(response.body)[0]['point']});
      print('포인트 구매 완료');
      context.read<UserCubit>().fetchUser();
      //       Amplitude.getInstance().setUserProperties(
      // {'point': point, 'subscribe': purchase, 'record': record});
    } else {
      //_sendSubFailEvent(response.statusCode);
      throw Exception('Failed to buy point');
    }
  }

  Future<void> payCashToPoint(points) async {
    try {
      Set<String> kIds = <String>{"points_$points"};
      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails(kIds);

      if (response.notFoundIDs.isNotEmpty) print('제품 없다');
      setState(() {
        _isLoading = true;
      });
      final ProductDetails productDetails = response.productDetails.first;
      // Saved earlier from queryProductDetails().
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);
      InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print(e);
      // optional error handling
    }

    // const Set<String> products = {'product1'};
    // final ProductDetailsResponse response =
    //     await InAppPurchase.instance.queryProductDetails(products);
    // if (response.notFoundIDs.isNotEmpty) {
    //   print('제품이 없어요');
    //   return;
    // }

    // final ProductDetails productDetails = response.productDetails.first;

    // final PurchaseParam purchaseParam = PurchaseParam(
    //   productDetails: productDetails,
    // );
    // try {
    //   final bool success = await InAppPurchase.instance.buyNonConsumable(
    //     purchaseParam: purchaseParam,
    //   );
    // } catch (error) {
    //   // 결제 실패
    //   print('결제 실패했어요');
    // }
  }

  @override
  void dispose() {
    // TODO: Add cleanup code
    //_subscription.cancel();
    super.dispose();
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Amplitude amplitude = Amplitude.getInstance();

  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    final sw = (MediaQuery.of(context).size.width -
        MediaQuery.of(context).padding.left -
        MediaQuery.of(context).padding.right);
    final sh = (MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom);

    paySuccessed
        ? {
            userCubit.fetchUser(),
            setState(() {
              paySuccessed = false;
            })
          }
        : ();
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
        child: Stack(
          fit: StackFit.expand, // Stack이 화면 전체를 덮도록 확장
          children: [
            // ios 앱 심사를 위한 restore 버튼 시작
            // Positioned(
            //   top: 2 * SizeConfig.defaultSize!,
            //   right: 11.5 * SizeConfig.defaultSize!,
            //   child: GestureDetector(
            //       onTap: () async {
            //         try {
            //           CustomerInfo customerInfo =
            //               await Purchases.restorePurchases();
            //           EntitlementInfo? entitlement =
            //               customerInfo.entitlements.all['pro'];
            //           if (entitlement != null) {
            //             if (entitlement.isActive) {
            //               _sendAlreadysubClickEvent(userState.point, 'true');

            //               print('restore success');
            //               subSuccess();
            //               if (userState.record) {
            //                 Navigator.pop(context);

            //                 Navigator.pushReplacement(
            //                   context,
            //                   MaterialPageRoute(
            //                     builder: (context) => HomeScreen(
            //                       abTest: widget.abTest,
            //                     ),
            //                   ),
            //                 );
            //               } else {
            //                 Navigator.pushReplacement(
            //                   context,
            //                   MaterialPageRoute(
            //                     builder: (context) => RecInfo(
            //                       abTest: widget.abTest,
            //                     ),
            //                   ),
            //                 );
            //               }
            //             } else {
            //               _sendAlreadysubClickEvent(userState.point, 'false');
            //               print('zclcickclciclkc');
            //               await subStart();
            //               // print('fail');
            //               // showDialog(
            //               //   context: context,
            //               //   builder: (BuildContext context) {

            //               //     // return AlertDialog(
            //               //     //   // title: Text('Sorry'),
            //               //     //   content: const Text('답변-부정 subscription found.'),
            //               //     //   actions: <Widget>[
            //               //     //     TextButton(
            //               //     //       child: const Text('Close'),
            //               //     //       onPressed: () {
            //               //     //         Navigator.of(context).pop();
            //               //     //       },
            //               //     //     ),
            //               //     //   ],
            //               //     // );
            //               //   },
            //               // );
            //             }
            //           } else {
            //             _sendAlreadysubClickEvent(userState.point, 'false');

            //             await subStart();

            //             // print("entitlement: $entitlement");
            //             // showDialog(
            //             //   context: context,
            //             //   builder: (BuildContext context) {
            //             //     return AlertDialog(
            //             //       // title: Text('Sorry'),
            //             //       content: const Text('답변-부정 subscription found.'),
            //             //       actions: <Widget>[
            //             //         TextButton(
            //             //           child: const Text('Close'),
            //             //           onPressed: () {
            //             //             Navigator.of(context).pop();
            //             //           },
            //             //         ),
            //             //       ],
            //             //     );
            //             //   },
            //             // );
            //           }
            //         } on PlatformException {
            //           _sendAlreadysubClickEvent(userState.point, 'false');
            //           await subStart();

            //           // showDialog(
            //           //   context: context,
            //           //   builder: (BuildContext context) {
            //           //     return AlertDialog(
            //           //       // title: Text('Sorry'),
            //           //       content: const Text('답변-부정 subscription found.'),
            //           //       actions: <Widget>[
            //           //         TextButton(
            //           //           child: const Text('Close'),
            //           //           onPressed: () {
            //           //             Navigator.of(context).pop();
            //           //           },
            //           //         ),
            //           //       ],
            //           //     );
            //           //   },
            //           // );

            //           // Error restoring purchases
            //         }
            //       },
            //       child: Container(
            //         width: 17 * SizeConfig.defaultSize!,
            //         height: 3.5 * SizeConfig.defaultSize!,
            //         decoration: BoxDecoration(
            //             color: const Color.fromARGB(128, 255, 255, 255),
            //             borderRadius: BorderRadius.all(
            //                 Radius.circular(SizeConfig.defaultSize! * 1))),
            //         child: Center(
            //           child: Text(
            //             '구독여부확인',
            //             style: TextStyle(
            //                 fontFamily: 'font-basic'.tr(),
            //                 fontSize: SizeConfig.defaultSize! * 1.6),
            //           ).tr(),
            //         ),
            //       )),
            // ),
            // ios 앱 심사를 위한 restore 버튼 끝
            Positioned(
              top: 2 * SizeConfig.defaultSize!,
              right: 1 * SizeConfig.defaultSize!,
              child: Stack(children: [
                Container(
                    width: 10 * SizeConfig.defaultSize!,
                    height: 3.5 * SizeConfig.defaultSize!,
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(128, 255, 255, 255),
                        borderRadius: BorderRadius.all(
                            Radius.circular(SizeConfig.defaultSize! * 1))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 0.5 * SizeConfig.defaultSize!,
                          ),
                          SizedBox(
                              width: 2 * SizeConfig.defaultSize!,
                              child: Image.asset('lib/images/oneCoin.png')),
                          // SizedBox(
                          //   width: 0.5 * SizeConfig.defaultSize!,
                          // ),
                          Container(
                            width: 7 * SizeConfig.defaultSize!,
                            alignment: Alignment.center,
                            // decoration: BoxDecoration(color: Colors.blue),
                            child: Text(
                              '${userState.point + 0}',
                              style: TextStyle(
                                  fontFamily: 'lilita',
                                  fontSize: SizeConfig.defaultSize! * 2),
                              textAlign: TextAlign.center,
                            ),
                          )
                        ])),
              ]),
            ),
            // HEADER 끝
            // BODY 시작
            // 구독 시작
            Positioned(
              top: 7 * SizeConfig.defaultSize!,
              left: 3 * SizeConfig.defaultSize!,
              child: Column(
                children: [
                  Stack(children: [
                    Align(
                        alignment: Alignment.bottomCenter,
                        //  right: SizeConfig.defaultSize! * 12,
                        //   top: SizeConfig.defaultSize! * 1.4,
                        child: GestureDetector(
                          onTap: () async {
                            // 버튼 클릭 시 동작
                            _sendSubClickEvent(userState.point, 'basic');
                            await subStart();
                          },
                          child: SizedBox(
                            width: 0.46 * sw,
                            height: 0.78 * sh,
                            child: Column(
                              children: [
                                Container(
                                  height: 0.1 * sh,
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 255, 167, 26),
                                    // borderRadius: BorderRadius.circular(
                                    // SizeConfig.defaultSize! * 1.15),
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      '구독-이름',
                                      style: TextStyle(
                                          fontFamily: 'font-book'.tr(),
                                          fontSize:
                                              SizeConfig.defaultSize! * 2.3),
                                    ).tr(),
                                  ),
                                ),
                                Container(
                                  height: 0.68 * sh,
                                  color: Colors.white,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                              height:
                                                  1 * SizeConfig.defaultSize!),
                                          SizedBox(
                                              height: 0.4 * 0.8 * sh,
                                              child: Image.asset(
                                                  'lib/images/books.png')),
                                          SizedBox(
                                              height:
                                                  1 * SizeConfig.defaultSize!),
                                          // 이미지 끝
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text("구독-설명",
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'font-basic'.tr(),
                                                          fontSize: 1.5 *
                                                              SizeConfig
                                                                  .defaultSize!))
                                                  .tr(),
                                              SizedBox(
                                                  width: 0.8 *
                                                      SizeConfig.defaultSize!),
                                              Container(
                                                height: 6.8 *
                                                    SizeConfig.defaultSize!,
                                                width: 12 *
                                                    SizeConfig.defaultSize!,
                                                decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 255, 167, 26),
                                                  // borderRadius: BorderRadius.circular(
                                                  // SizeConfig.defaultSize! * 1.15),
                                                ),
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            '구독-가격',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 2.8 *
                                                                  SizeConfig
                                                                      .defaultSize! *
                                                                  double.parse(
                                                                      'font-ratio'
                                                                          .tr()),
                                                              fontFamily:
                                                                  'font-basic'
                                                                      .tr(),
                                                            ),
                                                          ).tr(),
                                                          Padding(
                                                            padding: EdgeInsets.only(
                                                                top: SizeConfig
                                                                        .defaultSize! *
                                                                    1.8),
                                                            child: Text(
                                                              '가격-단위',
                                                              //  textAlign: TextAlign.start,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 2 *
                                                                    SizeConfig
                                                                        .defaultSize! *
                                                                    double.parse(
                                                                        'font-ratio'
                                                                            .tr()),
                                                                fontFamily:
                                                                    'font-basic'
                                                                        .tr(),
                                                              ),
                                                            ).tr(),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        '구독-가격-할인전',
                                                        style: TextStyle(
                                                            color: const Color
                                                                    .fromARGB(
                                                                136,
                                                                0,
                                                                0,
                                                                0),
                                                            fontFamily:
                                                                'font-basic'
                                                                    .tr(),
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            fontSize: 1.5 *
                                                                SizeConfig
                                                                    .defaultSize!),
                                                      ).tr()
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: 0.8 *
                                                  SizeConfig.defaultSize!),
                                          Container(
                                            decoration: const BoxDecoration(
                                                // color: Colors.blue, // 배경색 설정
                                                ),
                                            child: SizedBox(
                                                width: 0.4 * sw, //35 *
                                                //SizeConfig.defaultSize!,
                                                height: 3.3 *
                                                    SizeConfig.defaultSize!,
                                                child: SingleChildScrollView(
                                                  child: Platform.isAndroid
                                                      ? Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                              Text(
                                                                "구독-약관설명-안드로이드",
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'font-basic'
                                                                          .tr(),
                                                                  fontSize:
                                                                      SizeConfig
                                                                              .defaultSize! *
                                                                          1.4,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ).tr(),
                                                            ])
                                                      : Column(
                                                          children: [
                                                            RichText(
                                                              text: TextSpan(
                                                                children: [
                                                                  TextSpan(
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            1 * SizeConfig.defaultSize!,
                                                                        fontFamily:
                                                                            'font-basic'.tr(),
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                      text: "구독-약관설명-iOS"
                                                                          .tr()),
                                                                  TextSpan(
                                                                    text: "구독-약관"
                                                                        .tr(),
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize: 1 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      fontFamily:
                                                                          'font-basic'
                                                                              .tr(),
                                                                      color: Colors
                                                                          .black,
                                                                      decoration:
                                                                          TextDecoration
                                                                              .underline,
                                                                    ),
                                                                    recognizer:
                                                                        TapGestureRecognizer()
                                                                          ..onTap =
                                                                              () {
                                                                            launch('http://www.apple.com/legal/itunes/appstore/dev/stdeula');
                                                                          },
                                                                  ),
                                                                  TextSpan(
                                                                    text: "구독-그리고"
                                                                        .tr(),
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize: 1 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      fontFamily:
                                                                          'font-basic'
                                                                              .tr(),
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                  TextSpan(
                                                                    text: "구독-개인정보처리방침"
                                                                        .tr(),
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize: 1 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      fontFamily:
                                                                          'font-basic'
                                                                              .tr(),
                                                                      color: Colors
                                                                          .black,
                                                                      decoration:
                                                                          TextDecoration
                                                                              .underline,
                                                                    ),
                                                                    recognizer:
                                                                        TapGestureRecognizer()
                                                                          ..onTap =
                                                                              () {
                                                                            launch('https://doc-hosting.flycricket.io/lovel-privacy-policy/f8c6f57c-dd5f-4b67-8859-bc4afe251396/privacy');
                                                                          },
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                )),
                                          )
                                        ]),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ))
                  ]),
                ],
              ),
            ),

            // 구독 끝
            // 구독 일시중지
            Positioned(
                top: 7 * SizeConfig.defaultSize!,
                left: 3 * SizeConfig.defaultSize!,
                child: SizedBox(
                    width: 0.46 * sw,
                    height: 0.78 * sh,
                    child: Container(
                        decoration: BoxDecoration(
                            gradient: RadialGradient(
                                radius: 0.7,
                                // begin: Alignment.topCenter,
                                // end: Alignment.bottomCenter,
                                colors: [
                          const Color.fromARGB(150, 0, 0, 0), // 흐린 배경의 시작 색상
                          Color.fromARGB(100, 0, 0, 0), // 투명한 중간 색상
                        ]))

                        // 다른 속성들은 필요에 따라 추가할 수 있습니다.
                        // borderRadius: BorderRadius.circular(SizeConfig.defaultSize! * 1.5),
                        // border: Border.all(
                        //   width: SizeConfig.defaultSize! * 0.25,
                        //   color: const Color.fromARGB(255, 255, 167, 26),
                        // ),

                        ))),
            Positioned(
                top: 0.39 * sh,
                left: 3 * SizeConfig.defaultSize!,
                child: SizedBox(
                  width: 0.46 * sw,
                  child: Center(
                    child: Text('얼리버드'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'font-book'.tr(),
                            color: Colors.white,
                            fontSize: 2.8 *
                                SizeConfig.defaultSize! *
                                double.parse('font-ratio'.tr()),
                            fontWeight: FontWeight.w600)),
                  ),
                )),
            // Positioned(
            //     top: 0.2 * sh,
            //     left: 0.135 * sw,
            //     child: SizedBox(
            //         width: 0.26 * sw, //
            //         child: Image.asset('lib/images/event.png'))),
            // Positioned(
            //     top: 0.66 * sh,
            //     left: 0.1 * sw,
            //     child: SizedBox(
            //         width: 0.35 * sw, //
            //         child: Image.asset('lib/images/100%.png'))),
            // 포인트 시작
            Positioned(
                top: 7 * SizeConfig.defaultSize!,
                right: 0.01 * sw,
                child: Stack(children: [
                  SizedBox(
                    width: 0.46 * sw,
                    height: 0.78 * sh,
                    child: Container(
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255)
                                .withOpacity(0.4),
                            // borderRadius: BorderRadius.circular(
                            //     SizeConfig.defaultSize! * 1.5),
                            border: Border.all(
                              width: SizeConfig.defaultSize! * 0.25,
                              color: const Color.fromARGB(255, 255, 167, 26),
                            )),
                        child: Align(
                          // color: Color.black,
                          alignment: Alignment.topCenter,
                          child: Column(
                              // mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // SizedBox(
                                //   height: 1.2 * SizeConfig.defaultSize!,
                                // ),
                                Container(
                                  // color: Colors.blue,
                                  // margin: EdgeInsets.only(
                                  //     right: 3 * SizeConfig.defaultSize!),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    // 오른쪽에 마진 설정
                                    children: [
                                      pointGood(
                                          // top: 7.5,
                                          // right: 21.5,
                                          sw: sw,
                                          sh: sh,
                                          coinImage: 'oneCoin',
                                          coinWid: 6.5,
                                          coinNum: 3000,
                                          price: '포인트-가격-3000',
                                          pointNow: userState.point,
                                          flag: ''),
                                      pointGood(
                                          // top: 7.5,
                                          // right: 3.5,
                                          sw: sw,
                                          sh: sh,
                                          coinImage: 'twoCoins',
                                          coinWid: 8.5,
                                          coinNum: 6000,
                                          price: '포인트-가격-6000',
                                          pointNow: userState.point,
                                          flag: 'mostPopular'),
                                    ],
                                  ),
                                ),
                                Container(
                                  // margin: EdgeInsets.only(
                                  //     right: 3 * SizeConfig.defaultSize!),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      pointGood(
                                          // top: 23,
                                          // right: 21.5,
                                          sw: sw,
                                          sh: sh,
                                          coinImage: 'threeCoins',
                                          coinWid: 10,
                                          coinNum: 10000,
                                          price: '포인트-가격-10000',
                                          pointNow: userState.point,
                                          flag: ''),
                                      pointGood(
                                          // top: 23,
                                          // right: 3.5,
                                          sw: sw,
                                          sh: sh,
                                          coinImage: 'fiveCoins',
                                          coinWid: 14.5,
                                          coinNum: 15000,
                                          price: '포인트-가격-15000',
                                          pointNow: userState.point,
                                          flag: 'specialPromotion'),
                                    ],
                                  ),
                                ),
                              ]),
                        )),
                  ),
                  Center(
                      child: Visibility(
                          visible: _isLoading,
                          child: SizedBox(
                            width: sw * 0.08,
                            height: sw * 0.08,
                            child: const CircularProgressIndicator(
                              color: Color(0xFFF39E09),
                            ),
                          ))),
                  // Positioned(
                  //     top: 5 * SizeConfig.defaultSize!,
                  //     right: 10.5 * SizeConfig.defaultSize!,
                  //     child: SizedBox(
                  //         width: 11 * SizeConfig.defaultSize!, //
                  //         child: Image.asset('lib/images/mostPopular.png'))),
                  // Positioned(
                  //     top: 20.4 * SizeConfig.defaultSize!,
                  //     right: 10.7 * SizeConfig.defaultSize!,
                  //     child: SizedBox(
                  //         width: 10.4 * SizeConfig.defaultSize!, //
                  //         child:
                  //             Image.asset('lib/images/specialPromotion.png'))),
                ])),

            Positioned(
              top: 0.5 * SizeConfig.defaultSize!,
              left: 1 * SizeConfig.defaultSize!,
              child: IconButton(
                icon: Icon(Icons.clear, size: 3 * SizeConfig.defaultSize!),
                onPressed: () {
                  _sendShopXClickEvent(userState.point);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }

  GestureDetector pointGood(
      {
      //required double top,
      // required double right,
      required double sw,
      required double sh,
      required String coinImage,
      required double coinWid,
      required int coinNum,
      required price,
      required int pointNow,
      required String flag}) {
    return GestureDetector(
        // top: top * SizeConfig.defaultSize!,
        // right: right * SizeConfig.defaultSize!,
        onTap: () async {
          _sendBuyPointClickEvent(pointNow, coinNum, price);
          payCashToPoint(coinNum);
        },
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: 0.012 * sh,
                // left: 0.5 / 100 * sw,
                // right: 0.8 / 100 * sw,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight, // 자식 위젯을 중앙 정렬
                    children: [
                      Container(
                        width: 0.208 * sw,
                        height: (25.5) / 100 * sh,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(0, 255, 0, 255),
                        ),
                      ),
                      Stack(
                          alignment: Alignment.center, // 자식 위젯을 중앙 정렬

                          children: [
                            Container(
                              width: 17 / 100 * sw,
                              height: (20) / 100 * sh,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 167, 26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey
                                        .withOpacity(0.6), // 그림자 색상 및 투명도
                                    spreadRadius: 0, // 그림자 확산 반경
                                    blurRadius: 3, // 그림자의 흐림 정도
                                    offset:
                                        const Offset(5, 5), // 그림자의 위치 (가로, 세로)
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                                width: (coinWid - 1) / 100 * sw, //
                                child:
                                    Image.asset('lib/images/$coinImage.png')),
                          ]),
                      Positioned(
                        right: 0.5 * SizeConfig.defaultSize!,
                        bottom: 0.5 * SizeConfig.defaultSize!,
                        child: Text(
                          '$coinNum',
                          style: TextStyle(
                            fontFamily: 'Lilita',
                            fontSize: 2.8 / 100 * sw,
                          ),
                        ),
                      )
                    ],
                  ),
                  Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 17 / 100 * sw,
                      height: 7.5 / 100 * sh,
                      decoration:
                          BoxDecoration(color: Colors.white, boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.6), // 그림자 색상 및 투명도
                          spreadRadius: 0, // 그림자 확산 반경
                          blurRadius: 3, // 그림자의 흐림 정도
                          offset: const Offset(5, 5), // 그림자의 위치 (가로, 세로)
                        ),
                      ]),
                    ),
                    Text(
                      '$price',
                      style: TextStyle(
                        fontFamily: 'font-basic'.tr(),
                        fontSize:
                            2.5 / 100 * sw * double.parse('font-ratio'.tr()),
                      ),
                    ).tr()
                  ]),
                ],
              ),
            ),
            flag == 'mostPopular'
                ? Positioned(
                    top: 2.8 / 100 * sh,
                    left: 1.25 / 100 * sw,
                    child: SizedBox(
                        width: 11 / 100 * sw,
                        child: Image.asset('lib/images/mostPopular.png')))
                : flag == 'specialPromotion'
                    ? Positioned(
                        top: 2.8 / 100 * sh,
                        left: 1.65 / 100 * sw,
                        child: SizedBox(
                            width: 10.4 / 100 * sw,
                            child:
                                Image.asset('lib/images/specialPromotion.png')))
                    : Container(),
          ],
        ));
  }

  Future<void> _sendShopViewEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'shop_view',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent('shop_view', eventProperties: {});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendSubClickEvent(pointNow, plan) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'shop_sub_click',
        parameters: <String, dynamic>{'point_now': pointNow},
      );
      await amplitude.logEvent(
        'shop_sub_click',
        eventProperties: {'point_now': pointNow},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBuyPointSuccessEvent(pointNow, pointWant) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'shop_buy_point_success',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'point_want': pointWant,
        },
      );
      await amplitude.logEvent('shop_buy_point_success', eventProperties: {
        'point_now': pointNow,
        'point_want': pointWant,
      });
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendSubSuccessEvent() async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'sub_success',
        parameters: <String, dynamic>{},
      );
      await amplitude.logEvent('sub_success', eventProperties: {});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendSubFailEvent(response) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'sub_fail',
        parameters: <String, dynamic>{'response': response},
      );
      await amplitude
          .logEvent('sub_fail', eventProperties: {'response': response});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendAlreadysubClickEvent(pointNow, subscribed) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'shop_alreadysub_click',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'subscribed': subscribed
        },
      );
      await amplitude.logEvent('shop_alreadysub_click',
          eventProperties: {'point_now': pointNow, 'subscribed': subscribed});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBuyPointClickEvent(pointNow, pointWant, price) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'shop_buy_point_click',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'point_want': pointWant,
          'price': price
        },
      );
      await amplitude.logEvent('shop_buy_point_click', eventProperties: {
        'point_now': pointNow,
        'point_want': pointWant,
        'price': price
      });
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendShopXClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'shop_x_click',
        parameters: <String, dynamic>{'point_now': pointNow},
      );
      await amplitude
          .logEvent('shop_x_click', eventProperties: {'point_now': pointNow});
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  // Future<void> _sendAlreadysubClickEvent(pointNow) async {
  //   try {
  //     // 이벤트 로깅
  //     await analytics.logEvent(
  //       name: 'shop_alreadysub_click',
  //       parameters: <String, dynamic>{'point_now': pointNow},
  //     );
  //     await amplitude.logEvent('shop_alreadysub_click',
  //         eventProperties: {'point_now': pointNow});
  //   } catch (e) {
  //     // 이벤트 로깅 실패 시 에러 출력
  //     print('Failed to log event: $e');
  //   }
  // }

  // Future<void> _sendAlreadysubClickEvent(pointNow) async {
  //   try {
  //     // 이벤트 로깅
  //     await analytics.logEvent(
  //       name: 'shop_alreadysub_click',
  //       parameters: <String, dynamic>{'point_now': pointNow},
  //     );
  //     await amplitude.logEvent('shop_alreadysub_click',
  //         eventProperties: {'point_now': pointNow});
  //   } catch (e) {
  //     // 이벤트 로깅 실패 시 에러 출력
  //     print('Failed to log event: $e');
  //   }
  // }
}
