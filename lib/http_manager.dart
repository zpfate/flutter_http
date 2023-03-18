

import 'dart:convert';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:global_x_flutter_module/network/base_result.dart';
import 'package:global_x_flutter_module/network/http.dart';
import 'package:global_x_flutter_module/network/http_method.dart';
import 'net_config.dart';

class HttpManager {
  /// 私有化构造函数
  HttpManager._internal();

  /// 静态私有成员变量
  static final HttpManager _httpManager = HttpManager._internal();

  /// 工厂构造方法
  factory HttpManager() => _httpManager;

  static HttpManager get instance => _httpManager;

  /// 私有dio请求
  final Dio _dio = Dio();
  final CancelToken _cancelToken = CancelToken();

  void init({
    required String baseUrl,
    bool isProduct = true,
    List<Interceptor>? interceptors,
    Parameters? headers,
  }) {
    /// BaseOptions、Options、RequestOptions 都可以配置参数，优先级别依次递增，且可以根据优先级别覆盖参数
    _dio.options = BaseOptions(
      baseUrl: baseUrl,

      /// 连接超时
      connectTimeout: NetConfig.connectTimeout,

      /// 发送超时
      sendTimeout: NetConfig.sendTimeout,

      /// 响应流上前后两次接受到数据的间隔，单位为毫秒。
      receiveTimeout: NetConfig.receiveTimeout,
      headers: headers,
    );

    /// 添加拦截器
    if (interceptors != null && interceptors.isNotEmpty) {
      _dio.interceptors.addAll(interceptors);
    }
  }

  /// Request 操作
  Future<BaseResult> request(
      String path, {
        String? baseUrl,
        required HttpMethod method,
        data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    _dio.options.method = method.methodName;

    /// 移除null
    if (data is Map) {
      data = data..removeWhere((key, value) => value == null);
    }
    try {
      /// 处理请求设置
      Response response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      /// 处理网络请求返回结果
      return _handleResponse(response);
    } on DioError catch (err) {
      /// 处理网络请求错误
      return _handleError(err);
    }
  }

  /// 网络请求结果
  BaseResult _handleResponse(Response response) {
    BaseResult baseResult;
    int statusCode = response.statusCode ?? 0;
    if (statusCode >= 200 && statusCode < 300) {
      if (response.data is Map) {
        String? code = response.data[NetConfig.codeKey];
        String? message = response.data[NetConfig.messageKey];
        dynamic data = response.data[NetConfig.dataKey];
        baseResult = BaseResult(
            success: code == NetConfig.successCode ? true : false,
            data: data,
            code: code,
            message: message,
            statusCode: statusCode);
      } else if (response.data is String) {
        Map tempResponse = json.decode(response.data);
        String? code = tempResponse[NetConfig.codeKey];
        String? message = tempResponse[NetConfig.messageKey];
        dynamic data = response.data[NetConfig.dataKey];
        baseResult = BaseResult(
            success: true,
            data: data,
            code: code,
            message: message,
            statusCode: statusCode);
      } else {
        baseResult = BaseResult(
            success: false, data: null, code: "-1", message: "Request failed");
      }
    } else {
      /// 失败逻辑
      String? code;
      String? message;
      if (response.data is String) {
        message = response.data;
      } else if (response.data is Map) {
        code = response.data['code'];
        statusCode = response.data['status'] ?? -1;
        message = response.data['message'];

        message ??= response.data["errors"]?.toString() ?? 'Request failed';
      }
      baseResult = BaseResult(
          success: false,
          data: response.data?["data"] ?? message ?? "",
          code: code,
          message: message);
    }
    return baseResult;
  }

  /// 处理网络请求失败的结果
  BaseResult _handleError(dynamic err) {
    int? statusCode;
    String? errorCode;
    String? errorMessage;
    if (err.response?.data is Map) {
      statusCode = err.response?.data['status'];
      errorCode = err.response?.data['code']?.toString();
      errorMessage = err.response?.data['message']?.toString() ??
          err.response?.data['errors']?.toString();
    } else {
      statusCode = err.response?.statusCode ?? -1;
      errorCode = "-1";
      switch (err.type) {
        case DioErrorType.connectTimeout:
          errorMessage = "Connection timeout";
          // errorMessage = "连接超时-S2004";
          break;
        case DioErrorType.sendTimeout:
          errorMessage = "Request timeout";
          // errorMessage = "请求超时-S2003";
          break;
        case DioErrorType.receiveTimeout:
          errorMessage = "Response timeout";
          // errorMessage = "响应超时-S2002";
          break;
        case DioErrorType.response:
          errorMessage = "Server error";
          // errorMessage = "服务异常 请检查网络${e.response?.statusCode?.toString() ?? ''}${e.response?.statusMessage?.toString() ?? ''}";
          break;
        case DioErrorType.cancel:
          errorMessage = "Request cancellation";
          // errorMessage = "请求取消";
          break;
        case DioErrorType.other:
          errorMessage = "Unknown error";
          // errorMessage = "未知错误 请咨询客服";
          String tempErrorMessage = err.message;
          if (tempErrorMessage.isNotEmpty &&
              tempErrorMessage.contains("Failed host lookup")) {
            errorMessage = "DNS resolution error";
            // errorMessage = "网络地域名解析失败 请咨询客服";
          } else if (tempErrorMessage.isNotEmpty &&
              tempErrorMessage.contains("Network is unreachable")) {
            // errorMessage = "无法连接到网络";
            errorMessage = "Unable to connect to the network";
          }
          break;
        default:
          break;
      }
    }
    return BaseResult(
        success: false,
        code: errorCode,
        statusCode: statusCode,
        message: errorMessage);
  }

  /// 设置header
  void setHeaders(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
  }

  /// 删除header中对应的
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// 取消请求
  void cancelRequest(CancelToken? cancelToken) {
    cancelToken ?? _cancelToken.cancel();
  }

  /// 设置代理
  void setProxy({String? proxyIp, String? proxyPort}) {
    proxyIp = proxyIp ?? NetConfig.proxyIp;
    proxyPort = proxyPort ?? NetConfig.proxyPort;

    /// 在调试模式下需要抓包调试，所以我们使用代理，并禁用HTTPS证书校验
    if (NetConfig.proxyEnable) {
      (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (client) {
        if (proxyIp!.isNotEmpty && proxyPort!.isNotEmpty) {
          client.findProxy = (uri) {
            return "PROXY $proxyIp:$proxyPort";
          };

          /// 代理工具会提供一个抓包的自签名证书，会通不过证书校验，所以我们禁用证书校验
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
        }
      };
    }
  }
}
