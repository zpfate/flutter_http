///
/// @author: Twisted Fate
/// @date: 2021/5/21 15:24
/// description:
///

enum HttpMethod {
  /// Get
  get,

  /// Post
  post,

  /// Put
  put,

  /// Delete
  delete,

  /// Patch
  patch,
}

extension HttpMethodLogic on HttpMethod {
  String get methodName => toString().split(".").last.toUpperCase();
}
