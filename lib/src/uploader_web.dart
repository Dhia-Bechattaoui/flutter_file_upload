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
    bool skipFinalRequest = false,
  }) async {
    int bytesSent = 0;

    final collected = <int>[];
    final chunkUploads = <Future<void>>[];

    final client = BrowserClient();

    await for (final chunk in byteStream) {
      collected.addAll(chunk);
      while (collected.length >= chunkSizeBytes) {
        final slice = collected.sublist(0, chunkSizeBytes);
        collected.removeRange(0, chunkSizeBytes);
        final currentBytesSent = bytesSent;
        bytesSent += slice.length;

        // Track this chunk upload
        final chunkUpload = _sendChunk(
          client,
          url,
          slice,
          currentBytesSent,
          totalByteLength,
          headers,
          onProgress,
          shouldResumeFrom,
        );
        chunkUploads.add(chunkUpload);
      }
    }

    // Send remaining bytes
    if (collected.isNotEmpty) {
      final currentBytesSent = bytesSent;
      bytesSent += collected.length;
      final chunkUpload = _sendChunk(
        client,
        url,
        collected,
        currentBytesSent,
        totalByteLength,
        headers,
        onProgress,
        shouldResumeFrom,
      );
      chunkUploads.add(chunkUpload);
    }

    // Wait for all chunks to complete before making final request
    try {
      await Future.wait(chunkUploads);
    } catch (e) {
      client.close();
      rethrow;
    }

    if (skipFinalRequest) {
      client.close();
      return UploadResult(
        statusCode: 200,
        responseHeaders: const {},
        responseBodyBytes: const <int>[],
      );
    }

    // Use GET for consistency with IO implementation
    final response = await client.get(url, headers: headers);
    client.close();
    return UploadResult(
      statusCode: response.statusCode,
      responseHeaders: response.headers,
      responseBodyBytes: response.bodyBytes,
    );
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
    await client.post(url, headers: requestHeaders, body: body);
    onProgress?.call(start + bytes.length, total);
  }
}

// Factory used by conditional imports to create the correct uploader on Web.
PlatformUploader createPlatformUploaderImpl() => const WebPlatformUploader();
