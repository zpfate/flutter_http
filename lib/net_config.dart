
/// 网络配置
class NetConfig {
  /// 禁用实例化HttpConfig类
  NetConfig._();

  /// 是否启用代理 代理服务IP 代理服务端口
  static bool proxyEnable = false;

  /// 默认代理地址和端口号都为空
  static String proxyIp = '10.10.13.243';
  static String proxyPort = '8888';

  /// 超时时间 30s
  static const int connectTimeout = 10000;
  static const int sendTimeout = 10000;
  static const int receiveTimeout = 10000;

  /// 请求内容类型key
  static const String headerContentType = "content-type";

  /// 请求内容类型（FORM，JSON，TEXT）
  static const String contentTypeForm = 'application/x-www-form-urlencoded';
  static const String contentTypeJson = 'application/json; charset=utf-8';
  static const String contentTypeText = 'text/plain';

  /// 认证类型key
  static const String authorization = "token";

  /// 后端返回key值
  static const String dataKey = "data";
  static const String messageKey = "message";
  static const String codeKey = "code";
  static const String successCode = "0";
}
