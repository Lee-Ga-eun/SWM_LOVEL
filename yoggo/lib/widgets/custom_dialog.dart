import 'package:flutter/material.dart';
import 'package:yoggo/constants.dart';

Stack CustomDialog(String title, String? content, String leftText,
    String rightText, Function() leftAction, Function() rightAction) {
  return Stack(children: [
    Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(sizec),
            ),
            color: Color(0x60000000))),
    // width: 100 * sizec,
    AlertDialog(
      shadowColor: Colors.white.withOpacity(0),
      titlePadding: EdgeInsets.only(
        top: sizec * 2,
        // bottom: sizec * 1,
      ),
      actionsPadding: EdgeInsets.only(
        left: sizec * 2,
        right: sizec * 2,
        bottom: sizec * 2,
        top: content != null ? 0 : sizec * 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sizec * 2.5),
      ),
      backgroundColor: Colors.white,
      title: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: sizec * 2.4,
            fontFamily: 'Suit',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      content: content != null
          ? Text(
              content!,
              style: TextStyle(
                fontSize: sizec * 2,
                fontFamily: 'Suit',
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap:
                  // Left Action
                  leftAction,
              child: Container(
                width: sizec * 13.5,
                height: sizec * 5,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(sizec * 1.5),
                    color: greyLight),
                child: Center(
                  child: Text(
                    leftText,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Suit',
                      fontWeight: FontWeight.w600,
                      fontSize: 2 * sizec,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: sizec * 1), // 간격 조정
            GestureDetector(
              onTap:
                  // Right Action
                  rightAction,
              child: Container(
                width: sizec * 13.5,
                height: sizec * 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(sizec * 1.5),
                  color: orangeDark,
                ),
                child: Center(
                  child: Text(
                    rightText,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Suit',
                      fontWeight: FontWeight.w600,
                      fontSize: 2 * sizec,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ]);
}
