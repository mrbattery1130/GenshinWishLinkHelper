import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:genshin_wish_link_helper/wish_link_result.dart';
import 'package:genshin_wish_link_helper/http_util.dart';

import 'history_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '原神祈愿链接助手'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _onClickFab() async {
    CookieManager cookieManager = CookieManager.instance();
    final url = Uri.parse("https://user.mihoyo.com");
    List<Cookie> cookies = await cookieManager.getCookies(url: url);
    int time = DateTime
        .now()
        .microsecondsSinceEpoch ~/ 1000;
    WishLinkResult obj = await HttpUtil.getAuthKey(
        cookies
            .map(
                (e) => {"name": e.name.toString(), "value": e.value.toString()})
            .toList(),
        time);
    setState(() {
      if (obj.code == 200) {
        //请求成功
        if (obj.urlListObj.length > 1) {
          //多账号
          //var array = obj.urlListObj.map((e) => e.uid).toList();
          showDialog(
              context: context,
              builder: (ctx) =>
                  AlertDialog(
                    title: const Text("选择账号"),
                    content: SingleChildScrollView(
                        child: Column(
                            children: obj.urlListObj
                                .map(
                                  (e) =>
                                  ListTile(
                                    title: Text(e.nickname),
                                    subtitle: Text("UID ${e.uid}"),
                                    // leading: const Icon(Icons.person),
                                    trailing:
                                    Text("${e.regionName} ${e.level}级"),
                                    onTap: () {
                                      onSelectAccount(e.url);
                                    },
                                  ),
                            )
                                .toList())),
                  ));
        } else {
          //单账号
          onSelectAccount(obj.urlListObj[0].url);
        }
      } else {
        //请求失败
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("请先登录米游社")));
      }
    });
  }

  void onSelectAccount(String url) {
    //复制到剪贴板
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("已复制到剪贴板")));
    //关闭弹窗
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => HistoryPage()));
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: InAppWebView(
          initialUrlRequest:
          URLRequest(url: Uri.parse("https://user.mihoyo.com"))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onClickFab,
        tooltip: 'Increment',
        label: const Text("获取祈愿链接"),
        icon: const Icon(Icons.copy),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}