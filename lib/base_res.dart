
import 'dart:convert';

import 'net_config.dart';

class BaseBean {

  BaseBean.fromJson(json);
}


class BaseRes<T extends BaseBean> {

  bool? success;
  String? code;
  T? data;
  List<T>? list;
  String? errorMsg;

  BaseRes({this.success, this.code, this.data, this.list, this.errorMsg});

  factory BaseRes.fromResponse(response) {
    try {
      if (response.data is Map) {
        String? code = response.data[NetConfig.codeKey];
        String? message = response.data[NetConfig.messageKey];
        dynamic data = response.data[NetConfig.dataKey];

        if (data is List) {

        } else {


        }

        return BaseRes(
          success: code == NetConfig.successCode,
          data: data,
          code: code,
          errorMsg: message,
        );
      } else if (response.data is String) {
        Map tempResponse = json.decode(response.data);
        String? code = tempResponse[NetConfig.codeKey];
        String? message = tempResponse[NetConfig.messageKey];
        dynamic data = response.data[NetConfig.dataKey];
        return BaseRes(
          success: true,
          data: data,
          code: code,
          errorMsg: message,
        );
      } else {
        /// 失败逻辑
        String? code;
        String? message;
        if (response.data is String) {
          message = response.data;
        } else if (response.data is Map) {
          code = response.data['code'];
          message = response.data['message'];

          message ??= response.data["errors"]?.toString() ?? 'Request failed';
        }
        return BaseRes(
            success: false,
            data: response.data?["data"] ?? message ?? "",
            code: code,
            errorMsg: message);
      }
    } catch (e) {
      return BaseRes(success: false, code: "-1", errorMsg: "");
    }
  }

}


class BeanFactory {

  static T? generateJson<T extends BaseBean>(json) {
    try {
      switch (T.toString()) {
        case "int":
          return json;
        case "bool":
          return json;
        case "String":
          return json;
        default:
          return T.fromJson(json);
      }
    } catch (e) {
      return null;
    }
  }
}