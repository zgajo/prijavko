import 'dart:typed_data';

import 'package:dio/dio.dart';

// Story 1.3 skeleton: returns a 200 with empty body for any request.
// This is enough to verify that dioProvider wires correctly in fake env.
//
// TODO(story-1.7): wire login endpoint
class EvisitorFakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('', 200, headers: {});
  }

  @override
  void close({bool force = false}) {}
}
