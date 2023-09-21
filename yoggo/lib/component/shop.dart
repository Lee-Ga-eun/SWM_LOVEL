import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:crypto/crypto.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
import 'package:yoggo/component/sign.dart';
import 'package:yoggo/component/rec_info.dart';
import 'package:yoggo/component/sign_and.dart';
import 'package:yoggo/size_config.dart';
import 'package:flutter/material.dart';

import 'dart:io' show Platform;

import 'globalCubit/user/user_cubit.dart';
import 'package:amplitude_flutter/amplitude.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Purchase extends StatefulWidget {
  const Purchase({super.key});

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
                    builder: (context) => const HomeScreen(),
                  ),
                );
              } else {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecInfo(),
                  ),
                );
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
      print('정보 등록 완료 1');
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
      // _sendSubSuccessEvent();
      print('정보 등록 완료 2');
      context.read<UserCubit>().fetchUser();
    } else {
      _sendSubFailEvent(response.statusCode);
      throw Exception('Failed to start inference');
    }
  }

  Future<void> payCashToPoint(points) async {
    try {
      Set<String> _kIds = <String>{"points_$points"};
      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails(_kIds);

      if (response.notFoundIDs.isNotEmpty) print('제품 없다');
      final ProductDetails productDetails = response.productDetails.first;
      // Saved earlier from queryProductDetails().
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);
      InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
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
            Positioned(
              top: 2 * SizeConfig.defaultSize!,
              right: 11.5 * SizeConfig.defaultSize!,
              child: GestureDetector(
                  onTap: () async {
                    print('tap');
                    _sendAlreadysubClickEvent(userState.point);
                    try {
                      CustomerInfo customerInfo =
                          await Purchases.restorePurchases();
                      EntitlementInfo? entitlement =
                          customerInfo.entitlements.all['pro'];
                      if (entitlement != null) {
                        if (entitlement.isActive) {
                          print('restore success');
                          subSuccess();
                          if (userState.record) {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          } else {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RecInfo(),
                              ),
                            );
                          }
                        } else {
                          print('fail');

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                // title: Text('Sorry'),
                                content: Text(
                                    'No subscription information registered.'),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Close'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      }
                    } on PlatformException {
                      print('andriod');
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            // title: Text('Sorry'),
                            content:
                                Text('No subscription information registered.'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Close'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );

                      // Error restoring purchases
                    }
                  },
                  child: Container(
                    width: 17 * SizeConfig.defaultSize!,
                    height: 3.5 * SizeConfig.defaultSize!,
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(128, 255, 255, 255),
                        borderRadius: BorderRadius.all(
                            Radius.circular(SizeConfig.defaultSize! * 1))),
                    child: Center(
                        child: Text(
                      'Already Subscribed?',
                      style: TextStyle(
                          fontFamily: 'Molengo',
                          fontSize: SizeConfig.defaultSize! * 1.6),
                    )),
                  )),
            ),
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
                                      'LOVEL SUBSCRIPTION',
                                      style: TextStyle(
                                          fontFamily: 'GenBkBasR',
                                          fontSize:
                                              SizeConfig.defaultSize! * 2.3),
                                    ),
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
                                              Text(
                                                  '✅ Read with your voice\n✅ Unlock all books\n✅ 7-days FREE trial',
                                                  style: TextStyle(
                                                      fontFamily: 'Molengo',
                                                      fontSize: 1.5 *
                                                          SizeConfig
                                                              .defaultSize!)),
                                              SizedBox(
                                                  width: 3 *
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
                                                            '\$5.99',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 2.8 *
                                                                  SizeConfig
                                                                      .defaultSize!,
                                                              fontFamily:
                                                                  'Molengo',
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding: EdgeInsets.only(
                                                                top: SizeConfig
                                                                        .defaultSize! *
                                                                    1.8),
                                                            child: Text(
                                                              '/mo',
                                                              //  textAlign: TextAlign.start,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 2 *
                                                                    SizeConfig
                                                                        .defaultSize!,
                                                                fontFamily:
                                                                    'Molengo',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        '\$19.99',
                                                        style: TextStyle(
                                                            color: const Color
                                                                    .fromARGB(
                                                                136,
                                                                0,
                                                                0,
                                                                0),
                                                            fontFamily:
                                                                'Molengo',
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            fontSize: 1.5 *
                                                                SizeConfig
                                                                    .defaultSize!),
                                                      )
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
                                                width: 32 *
                                                    SizeConfig.defaultSize!,
                                                height:
                                                    3 * SizeConfig.defaultSize!,
                                                child: SingleChildScrollView(
                                                  child: Platform.isAndroid
                                                      ? Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                              Text(
                                                                "After free trial, LOVEL monthly subscription is \$5.99.",
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'Molengo',
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
                                                              ),
                                                            ])
                                                      : Column(
                                                          children: [
                                                            RichText(
                                                              text: TextSpan(
                                                                children: [
                                                                  TextSpan(
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize: 1 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      fontFamily:
                                                                          'Molengo',
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                    text:
                                                                        "Subscription Terms: After free trial, LOVEL monthly subscription is \$5.99, automatically renews unless turned off in Account Settings at least 24h before current period ends. Payment is charged to your iTunes account. By tapping Continue, you agree to our ",
                                                                  ),
                                                                  TextSpan(
                                                                    text:
                                                                        "Terms",
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize: 1.2 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      fontFamily:
                                                                          'Molengo',
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
                                                                    text:
                                                                        " and ",
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize: 1.2 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      fontFamily:
                                                                          'Molengo',
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                  TextSpan(
                                                                    text:
                                                                        "Privacy Policy.",
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize: 1.2 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      fontFamily:
                                                                          'Molengo',
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
            // 포인트 시작
            Positioned(
                top: 7 * SizeConfig.defaultSize!,
                right: 1 * SizeConfig.defaultSize!,
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
                                          price: '\$ 2.99',
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
                                          price: '\$ 4.99',
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
                                          price: '\$ 8.99',
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
                                          price: '\$ 9.99',
                                          pointNow: userState.point,
                                          flag: 'specialPromotion'),
                                    ],
                                  ),
                                )
                              ]),
                        )),
                  ),
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
                top: 4 * SizeConfig.defaultSize!,
                left: 0.75 * SizeConfig.defaultSize!,
                child: SizedBox(
                    width: 11.5 * SizeConfig.defaultSize!, //
                    child: Image.asset('lib/images/bestProduct.png'))),

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
                        decoration: BoxDecoration(
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
                          ))
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
                        fontFamily: 'Molengo',
                        fontSize: 2.5 / 100 * sw,
                      ),
                    )
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

  Future<void> _sendAlreadysubClickEvent(pointNow) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'shop_alreadysub_click',
        parameters: <String, dynamic>{'point_now': pointNow},
      );
      await amplitude.logEvent('shop_alreadysub_click',
          eventProperties: {'point_now': pointNow});
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
