import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> loadApiUrl() async {
  try {
    var currentDir = Directory.current;
    final file = File('${currentDir.path}/api_url.txt');

    if (await file.exists()) {
      final _apiUrl = await file.readAsString();
      API_URL = _apiUrl;
      return _apiUrl.trim();
    } else {
      const defaultUrl = 'http://192.168.51.17:5000';
      await file.writeAsString(defaultUrl);
      API_URL = defaultUrl;
      return defaultUrl;
    }
  } catch (e) {
    return 'http://default.api.url';
  }
}

String? API_URL;


const AUTH_API_URL = 'http://178.124.209.20/thyroid-auth';
const USE_FAKE_THYROID_API = false;
const USE_FAKE_AUTH_API = false;
var width1 = 150.0;
var width2 = 150.0;
var width3 = 150.0;
var width4 = 150.0;
var width5 = 150.0;
var width6 = 150.0;
var width7 = 150.0;
var width8 = 150.0;
var width9 = 150.0;
var width10 = 150.0;
var width11 = 150.0;
var width12 = 150.0;
var width13 = 150.0;
var width14 = 150.0;
var width15 = 150.0;
var WidthColumns = [width1,width2,width3,width4,width5,width6,width7,width8,width9,width10,width11,width12,width13,width14,width15];
var RowsNumber = 10;