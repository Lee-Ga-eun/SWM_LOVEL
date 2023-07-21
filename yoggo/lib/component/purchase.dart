import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/home/view/home_screen.dart';
import 'package:yoggo/component/record_info.dart';
import 'package:yoggo/size_config.dart';

// final bool _kAutoConsume = Platform.isIOS || true;

// const String _kConsumableId = 'consumable';
// const String _kUpgradeId = 'upgrade';
// const String _kSilverSubscriptionId = 'subscription_silver';
// const String _kGoldSubscriptionId = 'subscription_gold';
// const List<String> _kProductIds = <String>[
//   _kConsumableId,
//   _kUpgradeId,
//   _kSilverSubscriptionId,
//   _kGoldSubscriptionId,
// ];

class Purchase extends StatefulWidget {
  const Purchase({super.key});

  @override
  _PurchaseState createState() => _PurchaseState();
}

class _PurchaseState extends State<Purchase> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> view = [];
  late String token;

  Future fetch() async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (available) {
      // 제품 정보를 로드
      const Set<String> ids = <String>{'product1'};
      ProductDetailsResponse res =
          await InAppPurchase.instance.queryProductDetails(ids);
      view = res.productDetails;

      _inAppPurchase.purchaseStream.listen((List<PurchaseDetails> event) {
        PurchaseDetails e = event[0];
        print(
            "📌 EVENT $e ${e.status} ${e.productID} ${e.pendingCompletePurchase}");

        /// 구매 여부 pendingCompletePurchase - 승인 true / 취소 false
        if (e.pendingCompletePurchase) {
          if (!mounted) return;
          successPurchase();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RecordInfo()));
        }
      });
    }
    if (!mounted) return;
    setState(() {});
  }
  //   final bool isAvailable = await _inAppPurchase.isAvailable();
  //   if (!isAvailable) {
  //     setState(() {
  //       _isAvailable = isAvailable;
  //       _products = <ProductDetails>[];
  //       _purchases = <PurchaseDetails>[];
  //       _notFoundIds = <String>[];
  //       _consumables = <String>[];
  //       _purchasePending = false;
  //       _loading = false;
  //     });
  //     return;
  //   }
  //   if (Platform.isIOS) {
  //     // final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
  //     //     _inAppPurchase
  //     //         .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
  //     // await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
  //   }
  //   final ProductDetailsResponse productDetailResponse =
  //       await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
  //   if (productDetailResponse.error != null) {
  //     setState(() {
  //       _queryProductError = productDetailResponse.error!.message;
  //       _isAvailable = isAvailable;
  //       _products = productDetailResponse.productDetails;
  //       _purchases = <PurchaseDetails>[];
  //       _notFoundIds = productDetailResponse.notFoundIDs;
  //       _consumables = <String>[];
  //       _purchasePending = false;
  //       _loading = false;
  //     });
  //     return;
  //   }

  // if (productDetailResponse.productDetails.isEmpty) {
  //   setState(() {
  //     _queryProductError = null;
  //     _isAvailable = isAvailable;
  //     _products = productDetailResponse.productDetails;
  //     _purchases = <PurchaseDetails>[];
  //     _notFoundIds = productDetailResponse.notFoundIDs;
  //     _consumables = <String>[];
  //     _purchasePending = false;
  //     _loading = false;
  //   });
  //   return;
  // }
  //}
  @override
  void initState() {
    Future(fetch);
    super.initState();
    getToken();
    // TODO: Add initialization code
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token')!;
    });
  }

  Future<void> successPurchase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('purchase', true);
    var url = Uri.parse('https://yoggo-server.fly.dev/user/successPurchase');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      print('정보 등록 완료');
    } else {
      throw Exception('Failed to start inference');
    }
  }

  Future<void> startPurchase() async {
    const Set<String> products = {'product1'};
    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails(products);
    if (response.notFoundIDs.isNotEmpty) {
      print('제품이 없어요');
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    try {
      final bool success = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (error) {
      // 결제 실패
      print('결제 실패했어요');
    }
  }

  @override
  void dispose() {
    // TODO: Add cleanup code
    //_subscription.cancel();
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
                  Positioned(
                    left: 2 * SizeConfig.defaultSize!,
                    child: IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(),
                          ),
                        );
                      },
                      //color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
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
                            'lib/images/rocket.png',
                            width: SizeConfig.defaultSize! * 5,
                            alignment: Alignment.topCenter,
                          ),
                          Text(
                            'Stimulate your children\'s imaginations \n Provide a fantastic reading experience \n Improve your bond with your children ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Molengo',
                                fontSize: SizeConfig.defaultSize! * 2.3),
                          ),
                          Image.asset(
                            'lib/images/horse.png',
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
                                      text: '\$19.99/month\n',
                                      style: TextStyle(
                                          fontSize: SizeConfig.defaultSize! * 2,
                                          fontFamily: 'Molengo',
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough),
                                    ),
                                    TextSpan(
                                      text: '\$5.99/month\n',
                                      style: TextStyle(
                                          fontSize: SizeConfig.defaultSize! * 2,
                                          color: Colors.black,
                                          fontFamily: 'Molengo'),
                                    ),
                                    TextSpan(
                                      text: '70% ',
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.defaultSize! * 2.3,
                                          color: Colors.red,
                                          fontFamily: 'Molengo'),
                                    ),
                                    TextSpan(
                                      text: 'OFF + 1 ',
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.defaultSize! * 2.3,
                                          color: Colors.black,
                                          fontFamily: 'Molengo'),
                                    ),
                                    TextSpan(
                                      text: 'FREE ',
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.defaultSize! * 2.3,
                                          color: Colors.red,
                                          fontFamily: 'Molengo'),
                                    ),
                                    TextSpan(
                                      text: 'MONTH\n',
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.defaultSize! * 2.3,
                                          color: Colors.black,
                                          fontFamily: 'Molengo'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      Padding(
                          padding: const EdgeInsets.only(),
                          child: Container(
                            width: SizeConfig.defaultSize! * 52.6,
                            height: SizeConfig.defaultSize! * 4.5,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(152, 97, 1, 152),
                              borderRadius: BorderRadius.all(
                                  Radius.circular(SizeConfig.defaultSize!)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: SizeConfig.defaultSize! * 5,
                                right: SizeConfig.defaultSize! * 5,
                                // top: SizeConfig.defaultSize! * 0.2,
                                // bottom: SizeConfig.defaultSize! * 0.2,
                              ),
                              child: TextButton(
                                onPressed: () async {
                                  await startPurchase();
                                },
                                child: Text(
                                  'Go get unlimited access to all upcoming books',
                                  style: TextStyle(
                                    fontFamily: 'Molengo',
                                    fontSize: SizeConfig.defaultSize! * 2.1,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ))
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
