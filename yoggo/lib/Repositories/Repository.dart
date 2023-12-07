import 'package:http/http.dart' as http;
import 'package:yoggo/component/bookIntro/viewModel/book_intro_model.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yoggo/component/home/viewModel/home_screen_book_model.dart';

import 'package:yoggo/component/bookPage/viewModel/book_page_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../component/bookIntro/viewModel/book_voice_model.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// Uint8List 사용을 위한 import
import 'dart:io'; // File 클래스를 사용하기 위한 import

class DataRepository {
  static bool _isLoaded = false;
  static bool _isChanged = false;

  static const bool _bookIntroLoaded = false;

  static List<HomeScreenBookModel> _loadedHomeScreenData = [];

  static HomeScreenBookModel? getBookModelByContentId(int contentId) {
    final bookModel = _loadedHomeScreenData.firstWhere(
      (model) => model.id == contentId,
      //orElse: () => null,
    );
    return bookModel;
  }

  Future<List<HomeScreenBookModel>> loadHomeBookRepository() async {
    // home screen에서 책 목록들
    if (!_isLoaded || _isChanged) {
      await dotenv.load(fileName: ".env");
      // final response =
      //     // // release 버전
      //     await http.get(Uri.parse(dotenv.get("API_SERVER") + 'content/all'));

      // release 버전
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      var url = Uri.parse('${dotenv.get("API_SERVER")}content/v2');
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      _isChanged = false;

      //

      // // dev 버전
      // await http.get(Uri.parse('${dotenv.get("API_SERVER")}content/dev'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;

        final bookThumb = await fetchBookThumb(jsonData);
        //print(bookThumb);
        bookThumb.sort((a, b) {
          if (a.lock == b.lock) {
            return 0;
          } else if (a.lock) {
            return 1;
          } else {
            return -1;
          }
        });

        _loadedHomeScreenData = bookThumb;
        _isLoaded = true;
      }
    }

    return _loadedHomeScreenData;
  }

  Future<List<HomeScreenBookModel>> changeHomeBookRepository() async {
    // home screen에서 책 목록들
    // final response =
    //     // // release 버전
    //     await http.get(Uri.parse(dotenv.get("API_SERVER") + 'content/all'));

    // release 버전
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    var url = Uri.parse('${dotenv.get("API_SERVER")}content/v2');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _isChanged = false;
    //

    // // dev 버전
    // await http.get(Uri.parse('${dotenv.get("API_SERVER")}content/dev'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List<dynamic>;

      final bookThumb = await fetchBookThumb(jsonData);
      //print(bookThumb);
      bookThumb.sort((a, b) {
        if (a.lock == b.lock) {
          return 0;
        } else if (a.lock) {
          return 1;
        } else {
          return -1;
        }
      });

      _loadedHomeScreenData = bookThumb;
      _isLoaded = true;
    }

    return _loadedHomeScreenData;
  }

  // static Future<List<BookIntroModel>> bookIntroRepository(
  //     // 홈 > 책 하나 클릭한 상태
  //     int contentId) async {
  //   // home screen에서 책 목록들
  //   if (!_bookIntroLoaded) {
  //     final response = await http
  //         .get(Uri.parse('${dotenv.get("API_SERVER")}content/$contentId'));

  //     if (response.statusCode == 200) {
  //       final jsonData = json.decode(response.body) as List<dynamic>;
  //       final data =
  //           jsonData.map((item) => BookIntroModel.fromJson(item)).toList();
  //       _loadedBookIntroData = data;
  //       _bookIntroLoaded = true;
  //     }
  //   }
  //   return _loadedBookIntroData;
  // }

  // ...

  // static final List<BookIntroModel> _loadedBookIntroData = [];
  static final List<BookIntroModel> _loadedBookIntroData = [];
  static final List<int> _loadedBookNumber = [];

  Future<List<BookIntroModel>> bookIntroRepository(int contentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (_loadedBookNumber.contains(contentId)) {
      // 이미 로드한 데이터가 있다면 해당 contentId에 맞는 데이터를 추출하여 리턴
      final loadedData = _loadedBookIntroData
          .where((data) => data.contentId == contentId)
          .toList();
      return loadedData;
    }
    _loadedBookNumber.add(contentId);
    final response = await http.get(
      Uri.parse('${dotenv.get("API_SERVER")}content/v2/$contentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List<dynamic>;
      jsonData[0]["thumbUrl"] = await getCachedOrFetch(jsonData[0]["thumbUrl"]);

      final data =
          jsonData.map((item) => BookIntroModel.fromJson(item)).toList();
      _loadedBookIntroData.addAll(data); // 로드한 데이터를 저장

      return data;
    } else {
      return []; // 에러 발생 시 빈 리스트 리턴
    }
  }

  Future<List<BookIntroModel>> bookIntroRepository2(int contentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (_loadedBookNumber.contains(contentId)) {
      // 이미 로드한 데이터가 있다면 해당 contentId에 맞는 데이터를 추출하여 리턴
      _loadedBookIntroData.removeWhere((data) => data.contentId == contentId);
    }
    final response = await http.get(
      Uri.parse('${dotenv.get("API_SERVER")}content/v2/$contentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List<dynamic>;
      jsonData[0]["thumbUrl"] = await getCachedOrFetch(jsonData[0]["thumbUrl"]);
      final data =
          jsonData.map((item) => BookIntroModel.fromJson(item)).toList();
      _loadedBookIntroData.addAll(data);
      _isChanged = true;
      // 로드한 데이터를 저장
      return data;
    } else {
      return []; // 에러 발생 시 빈 리스트 리턴
    }
  }

  Map<int, List<BookVoiceModel>> _loadedBookVoiceData = {};

  Future<void> bookVoiceResetRepository() async {
    _loadedBookVoiceData = {};
    print('reset');
  }

  Future<List<BookVoiceModel>> bookVoiceRepository(int contentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print(token);
    if (_loadedBookVoiceData.containsKey(contentId)) {
      print(_loadedBookIntroData);
      print('why');
      return _loadedBookVoiceData[contentId] as List<BookVoiceModel>;
    } else {
      print('Why');
      final response = await http.get(
        Uri.parse('${dotenv.get("API_SERVER")}content/voice/$contentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;
        final data = jsonData
            .map((item) => BookVoiceModel.fromJson(
                {...item, 'clicked': item['voiceId'] == 1 ? true : false}))
            .toList();
        _loadedBookVoiceData[contentId] = data;
        return data;
      } else {
        return []; // 에러 발생 시 빈 리스트 리턴
      }
    }
  }

  Future<List<BookVoiceModel>> clickBookVoiceRepository(
      int contentId, int clickedId) async {
    if (_loadedBookVoiceData.containsKey(contentId) &&
        _loadedBookVoiceData[contentId] != null) {
      final data = _loadedBookVoiceData[contentId];
      for (var item in data!) {
        if (item.voiceId == clickedId) {
          item.clicked = true;
        } else {
          item.clicked = false;
        }
      }
      _loadedBookVoiceData[contentId] = data;
      return data;
    } else {
      return bookVoiceRepository(contentId); // 에러 발생 시 빈 리스트 리턴
    }
  }

  Future<List<BookVoiceModel>> changeBookVoiceRepository(int contentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    List<BookVoiceModel>? exData = _loadedBookVoiceData[contentId];
    if (exData != null) {
      final response = await http.get(
        Uri.parse('${dotenv.get("API_SERVER")}content/voice/$contentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;

        final data = jsonData.map((item) {
          bool clicked = false;
          for (var exItem in exData) {
            if (exItem.voiceId == item['voiceId']) {
              clicked = exItem.clicked;
              break;
            }
          }
          return BookVoiceModel.fromJson({...item, 'clicked': clicked});
        }).toList();
        _loadedBookVoiceData[contentId] = data;
        return data;
      } else {
        return [];
      }
    } else {
      return bookVoiceRepository(contentId); // 에러 발생 시 빈 리스트 리턴
    }
  }

  Future<String> getCachedOrFetch(String url) async {
    String parsedUrl = Uri.parse(url).path;
    final cacheLocate =
        await cacheManager.getFileFromCache(parsedUrl); // 이미지 캐시 매니저
    String filePath = '';
    if (cacheLocate == null) {
      File file = await cacheManager.getSingleFile(url, key: parsedUrl);
      filePath = file.path;
    } else {
      filePath = '${cacheLocate.file}';
      filePath = filePath.replaceFirst("LocalFile: ", "");
    }
    return filePath;
  }

  Future<List<HomeScreenBookModel>> fetchBookThumb(dynamic jsonData) async {
    final futures = <Future<String>>[];
    final data = <HomeScreenBookModel>[];

    for (var element in jsonData) {
      futures.add(getCachedOrFetch(element["thumbUrl"]));
    }

    final result = await Future.wait(futures);
    for (var i = 0; i < jsonData.length; i++) {
      var element = jsonData[i];

      var homeScreenBookModel = HomeScreenBookModel(
        id: element["id"],
        title: element["title"],
        thumbUrl: result[i],
        summary: element["summary"],
        createdAt: element["createdAt"],
        last: element["last"],
        age: element["age"],
        visible: element["visible"],
        isNew: element["new"],
        badge: element["badge"],
        sequence: element["sequence"],
        author: element["author"],
        lock: element["lock"],
      );
      data.add(homeScreenBookModel);
    }
    return data;
  }

  Future<BookPageModel> fetchBookPage(dynamic element) async {
    String imageUrl = element["imageUrl"];
    String audioUrl = element["audioUrl"];

    final result = await Future.wait(
        [getCachedOrFetch(imageUrl), getCachedOrFetch(audioUrl)]);

    var bookPageModel = BookPageModel(
      contentVoiceId: element["contentVoiceId"],
      imageLocalPath: result[0],
      audioLocalPath: result[1],
      pageNum: element["pageNum"],
      text: element['text'],
      textKr: element['textKr'],
      imageUrl: element['imageUrl'],
      position: element['position'],
      audioUrl: element['audioUrl'],
    );
    return bookPageModel;
  }

// book page
  static final Map<int, List<BookPageModel>> _loadedBookPageDataMap = {};
  static final List<int> _loadedBookPageNumber = [];
  static final cacheManager = DefaultCacheManager();
  Future<List<BookPageModel>> bookPageRepository(int contentVoiceId) async {
    // if (_loadedBookPageNumber.contains(contentVoiceId)) {
    //   // 이미 로드한 데이터가 있다면 해당 contentVoiceId에 맞는 데이터를 추출하여 리턴
    //   return _loadedBookPageDataMap[contentVoiceId] ?? [];
    // }

    _loadedBookPageNumber.add(contentVoiceId);
    final response = await http.get(Uri.parse(
        //    'https://yoggo-server.fly.dev/content/page?contentVoiceId=$contentVoiceId'));
        '${dotenv.get("API_SERVER")}content/page?contentVoiceId=$contentVoiceId'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List<dynamic>;
      //final bookPageData = <BookPageModel>[];
      final futures = <Future<BookPageModel>>[];

      for (var element in jsonData) {
        futures.add(fetchBookPage(element));
      }
      final bookPageData = await Future.wait(futures);

      bookPageData.sort((a, b) => a.pageNum.compareTo(b.pageNum));

      _loadedBookPageDataMap[contentVoiceId] = bookPageData;
      return bookPageData;
    } else {
      return []; // 에러 발생 시 빈 리스트 리턴
    }
  }
}
