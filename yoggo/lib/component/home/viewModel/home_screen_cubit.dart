import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 모델 클래스 정의
class BookModel {
  final int id;
  final String title;
  final String thumbUrl;
  final String summary;
  final String createdAt;
  final int last;
  final int age;
  final bool visible;

  BookModel({
    required this.id,
    required this.title,
    required this.thumbUrl,
    required this.summary,
    required this.createdAt,
    required this.last,
    required this.age,
    required this.visible,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'],
      title: json['title'],
      thumbUrl: json['thumbUrl'],
      summary: json['summary'],
      createdAt: json['createdAt'],
      last: json['last'],
      age: json['age'],
      visible: json['visible'],
    );
  }
}

// 큐빗 정의
// class DataCubit extends Cubit<List<BookModel>> {
//   DataCubit() : super([]);

//   void loadData() async {
//     if (state.isEmpty) {
//       final response =
//           await http.get(Uri.parse('https://yoggo-server.fly.dev/content/all'));
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body) as List<dynamic>;
//         final data = jsonData.map((item) => BookModel.fromJson(item)).toList();
//         emit(data);
//       } else {
//         emit([]); // 에러 발생 시 빈 리스트로 상태 업데이트
//       }
//     }
//   }
// }
class DataCubit extends Cubit<List<BookModel>> {
  static bool _isLoaded = false; // 데이터를 로드했는지 여부를 저장하는 변수
  static List<BookModel> _loadedData = []; // 이전에 로드한 데이터를 저장하는 변수

  DataCubit() : super([]);

  void loadData() async {
    if (!_isLoaded) {
      // 데이터를 로드하지 않았을 경우에만 로드
      final response =
          await http.get(Uri.parse('https://yoggo-server.fly.dev/content/all'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;
        final data = jsonData.map((item) => BookModel.fromJson(item)).toList();
        _loadedData = data; // 로드한 데이터를 저장
        emit(data);
        _isLoaded = true; // 데이터를 로드했으므로 플래그를 true로 설정
      } else {
        emit(_loadedData); // 에러 발생 시 이전에 로드한 데이터를 상태로 유지
      }
    } else {
      emit(_loadedData);
    }
  }
}
// class DataCubit extends Cubit<List<BookModel>> {
//   DataCubit() : super([]) {
//     loadData(); // 생성자에서 loadData 호출
//   }

//   bool _isLoaded = false; // 데이터를 로드했는지 여부를 저장하는 변수
//   List<BookModel> _loadedData = []; // 이전에 로드한 데이터를 저장하는 변수

//   Future<void> loadData() async {
//     if (!_isLoaded) {
//       // 데이터를 로드하지 않았을 경우에만 로드
//       final response =
//           await http.get(Uri.parse('https://yoggo-server.fly.dev/content/all'));
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body) as List<dynamic>;
//         final data = jsonData.map((item) => BookModel.fromJson(item)).toList();
//         _loadedData = data; // 로드한 데이터를 저장
//         emit(data);
//         _isLoaded = true; // 데이터를 로드했으므로 플래그를 true로 설정
//       } else {
//         emit(_loadedData); // 에러 발생 시 이전에 로드한 데이터를 상태로 유지
//       }
//     } else {
//       emit(_loadedData);
//     }
//   }
// }
