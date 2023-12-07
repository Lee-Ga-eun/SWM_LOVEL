import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yoggo/component/notice/viewModel/notice_model.dart';
import 'package:yoggo/size_config.dart';
import '../../globalCubit/user/user_cubit.dart';
import 'package:amplitude_flutter/amplitude.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../rec.dart';

class Notice extends StatefulWidget {
  const Notice({
    super.key,
  });

  @override
  _NoticeState createState() => _NoticeState();
}

class _NoticeState extends State<Notice> {
  @override
  void initState() {
    super.initState();
    fetchAllNotices();
  }

  List<NoticeModel> notices = [];
  bool isLoaded = false;

  Future<void> fetchAllNotices() async {
    await dotenv.load(fileName: ".env");
    // API에서 모든 책 페이지 데이터를 불러와 pages 리스트에 저장
    final url = '${dotenv.get("API_SERVER")}notice';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print(notices.length);

      var noticeList = json.decode(response.body);
      for (var content in noticeList) {
        notices.add(NoticeModel.fromJson(content));
      }
      setState(() {
        isLoaded = true;
      });
    } else {
      // 에러 처리
    }
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
    SizeConfig().init(context);
    return Scaffold(
        body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFAE4),
            ),
            child: SafeArea(
              minimum: EdgeInsets.only(
                  // top: SizeConfig.defaultSize!,
                  right: 3 * SizeConfig.defaultSize!,
                  left: 3 * SizeConfig.defaultSize!),
              bottom: false,
              child: Column(children: [
                Expanded(
                  flex: SizeConfig.defaultSize!.toInt(),
                  child: Stack(alignment: Alignment.centerLeft, children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LOVEL',
                          style: TextStyle(
                            fontFamily: 'Modak',
                            fontSize: SizeConfig.defaultSize! * 5,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      //left: 20,
                      top: SizeConfig.defaultSize! * 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: Icon(
                          Icons.clear,
                          size: 3 * SizeConfig.defaultSize!,
                        ),
                      ),
                    ),
                  ]),
                ),
                Container(
                  padding: EdgeInsets.only(
                    top: SizeConfig.defaultSize!,
                  ),
                  height: sh * 0.85,
                  child: notices.isEmpty
                      ? Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              alignment: Alignment.topCenter,
                              height: sh * 0.78,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withOpacity(0.6),
                              ),
                              width: sw * 0.8,
                            ),
                            Center(
                                child: isLoaded
                                    ? Text("No Notice",
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.defaultSize! * 2))
                                    : const CircularProgressIndicator(
                                        color:
                                            Color.fromARGB(255, 111, 111, 111),
                                      )),
                          ],
                        )
                      : ListView.separated(
                          scrollDirection: Axis.vertical,
                          itemCount: notices.length, //.length,
                          //  itemCount: 4,
                          itemBuilder: (context, index) {
                            var notice = notices[index];
                            return noticeContent(sw, sh, notice);
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              SizedBox(width: 2 * SizeConfig.defaultSize!),
                        ),
                )
              ]),
            )));
  }

  Column noticeContent(double sw, double sh, NoticeModel noticeContent) {
    print(context.locale.toString());
    final title = context.locale.toString() == "ko_KR"
        ? noticeContent.titleKo
        : noticeContent.title;
    final content = context.locale.toString() == "ko_KR"
        ? noticeContent.contentKo
        : noticeContent.content;
    final time = noticeContent.createdAt.substring(0, 10);
    return Column(
      children: [
        // Hero(
        //tag: book.id,
        //child:
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withOpacity(0.6),
          ),
          width: sw * 0.8,
          height: null,
          // child: Expanded(
          child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(children: [
                Container(),
                Padding(
                    padding: EdgeInsets.only(
                        top: SizeConfig.defaultSize! * 1,
                        bottom: SizeConfig.defaultSize! * 1,
                        left: SizeConfig.defaultSize! * 2,
                        right: SizeConfig.defaultSize! * 2),
                    child: Column(children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(title,
                            style: TextStyle(
                                fontSize: SizeConfig.defaultSize! * 2)),
                      ),
                      Align(
                          alignment: Alignment.topRight,
                          child: Text(time,
                              style: TextStyle(
                                  fontSize: SizeConfig.defaultSize! * 1.4))),
                      Text('',
                          style: TextStyle(
                              fontSize: SizeConfig.defaultSize! * 0.7)),
                      Align(
                          alignment: Alignment.topLeft,
                          child: Text(content,
                              style: TextStyle(
                                  fontSize: SizeConfig.defaultSize! * 1.7)))
                    ]))
              ])),
        ),
        //),

        SizedBox(
          height: SizeConfig.defaultSize! * 1,
        ),
      ],
    );
  }
}
