import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';

import 'wish_link_result.dart';

class HttpUtil {
  static Future<WishLinkResult> getAuthKey(
      List<Map<String, String>> cookie, int time) async {
    // print(cookie);
    // print(time);
    var dio = Dio();
    // 写入Cookie
    var cookieJar = CookieJar();
    var cookies = cookie
        .map((e) => Cookie(e['name'].toString(), e['value'].toString()))
        .toList();
    cookieJar.saveFromResponse(
        Uri.parse("https://webapi.account.mihoyo.com"), cookies);
    dio.interceptors.add(CookieManager(cookieJar));
    try {
      //登录
      var response = await dio
          .get("https://webapi.account.mihoyo.com/Api/login_by_cookie?t=$time");
      // Print cookies
      // print(await cookieJar
      //     .loadForRequest(Uri.parse("https://webapi.account.mihoyo.com")));
      // Print response
      // print(response.data);
      var uid = response.data["data"]["account_info"]["account_id"];
      //print("uid: $uid");
      var token = response.data["data"]["account_info"]["weblogin_token"];
      //print("token: $token");
      cookies.add(Cookie("stuid", uid.toString()));

      //获取tid
      var multiResponse =
          await dio.get("https://api-takumi.mihoyo.com/auth/api/"
              "getMultiTokenByLoginTicket?"
              "login_ticket=$token&token_types=3&uid=$uid");
      for (var dataObj in multiResponse.data["data"]["list"]) {
        if (dataObj["name"] != null && dataObj["token"] != null) {
          cookies.add(Cookie(dataObj["name"], dataObj["token"]));
        }
      }
      print("cookies: $cookies");

      cookieJar.saveFromResponse(
          Uri.parse("https://api-takumi.mihoyo.com"), cookies);
      dio.interceptors.add(CookieManager(cookieJar));
      // Print cookies
      //print(await cookieJar
      //    .loadForRequest(Uri.parse("https://api-takumi.mihoyo.com")));

      //获取uid
      var uidResponse =
          await dio.get("https://api-takumi.mihoyo.com/binding/api/"
              "getUserGameRolesByCookie?game_biz=hk4e_cn");
      List<ListUrl> listUrl = [];
      //print(uidResponse.data["data"]["list"]);
      for (var userService in uidResponse.data["data"]["list"]) {
        print(userService);
        var gameUid = userService["game_uid"];
        var gameBiz = userService["game_biz"];
        var region = userService["region"];

        var authKeyPostData = {
          "auth_appid": "webview_gacha",
          "game_biz": gameBiz,
          "game_uid": gameUid,
          "region": region,
        };
        var authKeyResponse = await dio.request(
            "https://api-takumi.mihoyo.com/binding/api/genAuthKey",
            data: authKeyPostData,
            options: Options(
              method: "POST",
              headers: {
                "Content-Type": "application/json;charset=utf-8",
                "Host": "api-takumi.mihoyo.com",
                "Accept": "application/json, text/plain, */*",
                "x-rpc-app_version": "2.28.1",
                "x-rpc-client_type": "5",
                "x-rpc-device_id": "CBEC8312-AA77-489E-AE8A-8D498DE24E90",
                "DS": getDs(),
                "Cookie": cookies,
              },
            ));

        print("authKeyResponse: $authKeyResponse");
        var authKey =
            Uri.encodeComponent(authKeyResponse.data["data"]["authkey"]);
        var url = "https://hk4e-api.mihoyo.com/event/gacha_info/api/"
            "getGachaLog?win_mode=fullscreen&authkey_ver=1"
            "&sign_type=2&auth_appid=webview_gacha&init_type=301"
            "&gacha_id=b4ac24d133739b7b1d55173f30ccf980e0b73fc1"
            "&lang=zh-cn&device_type=mobile"
            "&game_version=CNRELiOS3.0.0_R10283122_S10446836_D10316937"
            "&plat_type=ios&game_biz=$gameBiz"
            "&size=20&authkey=$authKey&region=$region"
            "&timestamp=1664481732&gacha_type=200&page=1&end_id=0";
        listUrl.add(ListUrl(
            uid: gameUid,
            url: url,
            nickname: userService["nickname"],
            regionName: userService["region_name"],
            level: userService["level"]));
      }
      print("listUrl: $listUrl");
      if (listUrl.isNotEmpty) {
        return WishLinkResult(200, "请求成功", listUrl);
      } else {
        return WishLinkResult(404, "获取失败", []);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return WishLinkResult(404, "获取失败", []);
    }
  }

  static String getDs() {
    var salt = "ulInCDohgEs557j0VsPDYnQaaz6KJcv5";
    var time = DateTime.now().microsecondsSinceEpoch ~/ 1000000;
    var str = getStr();
    var key = "salt=$salt&t=$time&r=$str";
    var md5 = getMD5(key);
    return "$time,$str,$md5";
  }

  static String getStr() {
    var chars = "ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678";
    var maxPos = chars.length;
    var code = "";
    for (var i = 0; i <= 5; i++) {
      code += chars[Random().nextInt(maxPos)];
    }
    return code;
  }

  static String getMD5(String s) {
    var content = const Utf8Encoder().convert(s);
    var digest = md5.convert(content);
    return digest.toString();
  }
}
