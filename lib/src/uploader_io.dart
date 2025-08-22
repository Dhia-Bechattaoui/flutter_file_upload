// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'uploader.dart';

/// IO implementation of [PlatformUploader] for Android/iOS/desktop.
class IoPlatformUploader implements PlatformUploader {
  const IoPlatformUploader();

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
    final client = HttpClient();
    int bytesSent = 0;
    final effectiveHeaders = <String, String>{
      if (headers != null) ...headers,
    };

    // Buffer incoming bytes and send in chunks
    final buffer = BytesBuilder(copy: false);
    final controller = StreamController<List<int>>();

    final subscription = byteStream.listen((data) async {
      buffer.add(data);
      while (buffer.length >= chunkSizeBytes) {
        final chunk = buffer.takeBytes();
        int offset = 0;
        while (offset < chunk.length) {
          final end = (offset + chunkSizeBytes).clamp(0, chunk.length);
          final slice = chunk.sublist(offset, end);
          offset = end;
          await _sendChunk(
            client,
            url,
            slice,
            bytesSent,
            totalByteLength,
            effectiveHeaders,
            onProgress,
            shouldResumeFrom,
          );
          bytesSent += slice.length;
        }
      }
    });

    await subscription.asFuture<void>();

    // Flush remaining bytes
    final remaining = buffer.takeBytes();
    if (remaining.isNotEmpty) {
      await _sendChunk(
        client,
        url,
        remaining,
        bytesSent,
        totalByteLength,
        effectiveHeaders,
        onProgress,
        shouldResumeFrom,
      );
      bytesSent += remaining.length;
    }

    controller.close();

    // A simple finalization GET to retrieve server response if supported
    final request = await client.getUrl(url);
    final response = await request.close();
    final responseBytes = await consolidateHttpClientResponseBytes(response);
    final headersMap = <String, String>{};
    response.headers.forEach((name, values) {
      headersMap[name] = values.join(',');
    });
    return UploadResult(
      statusCode: response.statusCode,
      responseHeaders: headersMap,
      responseBodyBytes: responseBytes,
    );
  }

  Future<void> _sendChunk(
    HttpClient client,
    Uri url,
    List<int> bytes,
    int start,
    int? total,
    Map<String, String> headers,
    UploadProgressCallback? onProgress,
    FutureOr<bool> Function(int nextByteStart)? shouldResumeFrom,
  ) async {
    if (shouldResumeFrom != null) {
      final canProceed = await shouldResumeFrom(start);
      if (!canProceed) return;
    }

    final request = await client.postUrl(url);
    headers.forEach(request.headers.set);
    if (total != null) {
      request.headers.set(
          'Content-Range', 'bytes $start-${start + bytes.length - 1}/$total');
    }
    request.add(bytes);
    final response = await request.close();
    // Drain response to not leak sockets
    await response.drain<void>();
    onProgress?.call(start + bytes.length, total);
  }
}

// Helper to read all bytes from HttpClientResponse
Future<List<int>> consolidateHttpClientResponseBytes(
    HttpClientResponse response) async {
  final completer = Completer<List<int>>();
  final contents = <int>[];
  response.listen(
    contents.addAll,
    onDone: () => completer.complete(contents),
    onError: completer.completeError,
    cancelOnError: true,
  );
  return completer.future;
}

// Factory used by conditional imports to create the correct uploader on IO.
PlatformUploader createPlatformUploaderImpl() => const IoPlatformUploader();
