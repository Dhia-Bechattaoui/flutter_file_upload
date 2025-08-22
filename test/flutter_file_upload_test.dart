import 'package:flutter_test/flutter_test.dart';

import 'dart:async';
import 'package:flutter_file_upload/flutter_file_upload.dart';

// Top-level fake uploader (Dart does not support local class declarations)
class FakeUploader implements PlatformUploader {
  @override
  Future<UploadResult> upload({
    required Uri url,
    required Stream<List<int>> byteStream,
    required int? totalByteLength,
    Map<String, String>? headers,
    int chunkSizeBytes = 1024 * 256,
    UploadProgressCallback? onProgress,
    FutureOr<bool> Function(int nextByteStart)? shouldResumeFrom,
  }) async {
    int sent = 0;
    await for (final chunk in byteStream) {
      if (shouldResumeFrom != null) {
        final ok = await shouldResumeFrom(sent);
        if (!ok) continue;
      }
      sent += chunk.length;
      onProgress?.call(sent, totalByteLength);
    }
    return const UploadResult(
        statusCode: 200, responseHeaders: {}, responseBodyBytes: <int>[]);
  }
}

void main() {
  test('progress callback receives updates (fake uploader, no network)',
      () async {
    final uploader = FileUploader(FakeUploader());

    final controller = StreamController<List<int>>();
    final progresses = <int>[];

    unawaited(() async {
      controller.add(List<int>.filled(4, 1));
      controller.add(List<int>.filled(4, 2));
      controller.add(List<int>.filled(4, 3));
      await controller.close();
    }());

    await uploader.upload(
      Uri.parse('http://localhost/unused'),
      byteStream: controller.stream,
      totalByteLength: 12,
      chunkSizeBytes: 4,
      onProgress: (sent, total) => progresses.add(sent),
      shouldResumeFrom: (start) async => true,
    );

    expect(progresses, containsAllInOrder([4, 8, 12]));
  });
}
