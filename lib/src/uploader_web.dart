import 'dart:async';
import 'dart:typed_data';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

import 'uploader.dart';

/// Web implementation of [PlatformUploader] using XMLHttpRequest.
class WebPlatformUploader implements PlatformUploader {
  const WebPlatformUploader();

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
    int bytesSent = 0;

    final collected = <int>[];
    final completer = Completer<UploadResult>();

    final client = BrowserClient();

    byteStream.listen((chunk) async {
      collected.addAll(chunk);
      while (collected.length >= chunkSizeBytes) {
        final slice = collected.sublist(0, chunkSizeBytes);
        collected.removeRange(0, chunkSizeBytes);
        await _sendChunk(
          client,
          url,
          slice,
          bytesSent,
          totalByteLength,
          headers,
          onProgress,
          shouldResumeFrom,
        );
        bytesSent += slice.length;
      }
    }, onDone: () async {
      if (collected.isNotEmpty) {
        await _sendChunk(
          client,
          url,
          collected,
          bytesSent,
          totalByteLength,
          headers,
          onProgress,
          shouldResumeFrom,
        );
        bytesSent += collected.length;
      }

      final response = await client.head(url, headers: headers);
      completer.complete(UploadResult(
        statusCode: response.statusCode,
        responseHeaders: response.headers,
        responseBodyBytes: const <int>[],
      ));
      client.close();
    }, onError: completer.completeError);

    return completer.future;
  }

  Future<void> _sendChunk(
    http.Client client,
    Uri url,
    List<int> bytes,
    int start,
    int? total,
    Map<String, String>? headers,
    UploadProgressCallback? onProgress,
    FutureOr<bool> Function(int nextByteStart)? shouldResumeFrom,
  ) async {
    if (shouldResumeFrom != null) {
      final canProceed = await shouldResumeFrom(start);
      if (!canProceed) return;
    }
    final requestHeaders = <String, String>{};
    if (headers != null) requestHeaders.addAll(headers);
    if (total != null) {
      requestHeaders['Content-Range'] =
          'bytes $start-${start + bytes.length - 1}/$total';
    }
    final body = Uint8List.fromList(bytes);
    await client.post(
      url,
      headers: requestHeaders,
      body: body,
    );
    onProgress?.call(start + bytes.length, total);
  }
}

// Factory used by conditional imports to create the correct uploader on Web.
PlatformUploader createPlatformUploaderImpl() => const WebPlatformUploader();
