import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './user_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

late String token;
bool purchase = false;
bool record = false;

class UserCubit extends Cubit<UserState> {
  UserCubit()
      : super(UserState(
            userId: 0,
            userName: 'Guest',
            image: 'human1',
            email: '',
            record: false,
            purchase: false,
            login: true,
            point: 0,
            isDataFetched: false)) {
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      var url = Uri.parse('${dotenv.get("API_SERVER")}user/myInfo');
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        // API 응답 데이터 파싱
        final data = json.decode(response.body)[0];
        print(data);
        final userName = data['name'];
        final image = data['image'];
        final email = data['email'];
        final point = data['point'];
        final purchase = data['purchase'] as bool;
        final userId = data['id'];
        final record = data['record'] as bool;
        const login = true;
        const isDataFetched = true;
        if (record) {
          final voiceId = data['voiceId'];
          final voiceName = data['voiceName'];
          final voiceIcon = data['voiceIcon'];
          final inferenceUrl = data['inferenceUrl'];
          emit(UserState(
              userId: userId,
              userName: userName,
              image: image,
              email: email,
              purchase: purchase,
              record: record,
              login: login,
              point: point,
              isDataFetched: isDataFetched,
              voiceId: voiceId,
              voiceName: voiceName,
              voiceIcon: voiceIcon,
              inferenceUrl: inferenceUrl));
        }
        // 상태 업데이트
        else {
          emit(
            UserState(
                userId: userId,
                userName: userName,
                image: image,
                email: email,
                purchase: purchase,
                record: record,
                login: true,
                point: point,
                isDataFetched: isDataFetched),
          );
        }
        // emit(state.copyWith(
        //   userName: userName,
        //   email: email,
        //   record: record,
        //   purchase: purchase,
        // ));
        // // 한번 불러온 거 저장되도록 한다
        // SharedPreferences prefs = await SharedPreferences.getInstance();
        // prefs.setString('userName', userName);
        // prefs.setString('email', email);
        // prefs.setBool('purchase', purchase);
        // prefs.setBool('record', record);

        // final globalCubit = GlobalCubit();
        //globalCubit.updateUser(userName, email, record, purchase, true);
      } else {
        // API 호출 실패 시 에러 처리
        print('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 처리
      print('Error while fetching user data: $e');
    }
  }

  Future<void> logout() {
    emit(
      UserState(
          userId: 0,
          userName: 'Guest',
          email: '',
          image: 'human1',
          record: false,
          purchase: false,
          login: false,
          point: 0,
          isDataFetched: false),
    );
    return Future.value();
  }

  Future<void> successSubscribe() {
    if (state.record) {
      emit(UserState(
          userId: state.userId,
          userName: state.userName,
          image: state.image,
          email: state.email,
          purchase: true,
          record: state.record,
          login: state.login,
          point: state.point,
          isDataFetched: state.isDataFetched,
          voiceId: state.voiceId,
          voiceName: state.voiceName,
          voiceIcon: state.voiceIcon,
          inferenceUrl: state.inferenceUrl));
    } else {
      emit(
        UserState(
          userId: state.userId,
          userName: state.userName,
          email: state.email,
          image: state.image,
          purchase: true,
          record: state.record,
          login: state.login,
          point: state.point,
          isDataFetched: state.isDataFetched,
        ),
      );
    }
    return Future.value();
  }
}


// class UserCubit extends Cubit<UserState> {
//   UserCubit()
//       : super(UserState(
//             userName: '',
//             email: '',
//             record: false,
//             purchase: false,
//             isDataFetched: false));

//   Future<void> fetchUser() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');

//       var url = Uri.parse('${dotenv.get("API_SERVER")}user/myInfo');
//       var response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//       if (response.statusCode == 200) {
//         // API 응답 데이터 파싱
//         final data = json.decode(response.body)[0];
//         final userName = data['name'];
//         final email = data['email'];
//         purchase = data['purhcase'];
//         record = data['record'];
//         const isDataFetched = true;

//         // 상태 업데이트
//         // emit(
//         //   UserState(
//         //       userName: userName,
//         //       email: email,
//         //       purchase: purchase,
//         //       record: record,
//         //       isDataFetched: isDataFetched),
//         // );
//         emit(state.copyWith(
//           userName: userName,
//           email: email,
//           record: record,
//           purchase: purchase,
//         ));
//         // 한번 불러온 거 저장되도록 한다
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         prefs.setString('userName', userName);
//         prefs.setString('email', email);
//         prefs.setBool('purchase', purchase);
//         prefs.setBool('record', record);

//         // final globalCubit = GlobalCubit();
//         //globalCubit.updateUser(userName, email, record, purchase, true);
//       } else {
//         // API 호출 실패 시 에러 처리
//         print('Failed to fetch user data: ${response.statusCode}');
//       }
//     } catch (e) {
//       // 예외 처리
//       print('Error while fetching user data: $e');
//     }
//   }
//}
