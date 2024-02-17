class WishLinkResult {
  late int code;
  late String msg;
  late List<ListUrl> urlListObj;

  WishLinkResult(this.code, this.msg, this.urlListObj);
}

class ListUrl {
  late String uid;
  late String url;
  late String nickname;
  late String regionName;
  late int level;

  ListUrl(
      {required this.uid,
      required this.url,
      required this.nickname,
      required this.regionName,
      required this.level});
}
