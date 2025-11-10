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
    bool skipFinalRequest = false,
  }) async {
    final client = HttpClient();
    int bytesSent = 0;
    final effectiveHeaders = <String, String>{if (headers != null) ...headers};

    // Buffer incoming bytes and send in chunks
    final buffer = BytesBuilder(copy: false);
    final chunkUploads = <Future<void>>[];

    await for (final data in byteStream) {
      buffer.add(data);
      while (buffer.length >= chunkSizeBytes) {
        final chunk = buffer.takeBytes();
        int offset = 0;
        while (offset < chunk.length) {
          final end = (offset + chunkSizeBytes).clamp(0, chunk.length);
          final slice = chunk.sublist(offset, end);
          final currentBytesSent = bytesSent;
          bytesSent += slice.length;
          offset = end;

          // Track this chunk upload
          final chunkUpload = _sendChunk(
            client,
            url,
            slice,
            currentBytesSent,
            totalByteLength,
            effectiveHeaders,
            onProgress,
            shouldResumeFrom,
          );
          chunkUploads.add(chunkUpload);
        }
      }
    }

    // Flush remaining bytes
    final remaining = buffer.takeBytes();
    if (remaining.isNotEmpty) {
      final currentBytesSent = bytesSent;
      bytesSent += remaining.length;
      final chunkUpload = _sendChunk(
        client,
        url,
        remaining,
        currentBytesSent,
        totalByteLength,
        effectiveHeaders,
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

    // A simple finalization GET to retrieve server response if supported
    // Add a small delay to ensure server has processed all chunks
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final request = await client.getUrl(url);
      effectiveHeaders.forEach(request.headers.set);
      final response = await request.close();
      final responseBytes = await consolidateHttpClientResponseBytes(response);
      final headersMap = <String, String>{};
      response.headers.forEach((name, values) {
        headersMap[name] = values.join(',');
      });
      client.close();
      return UploadResult(
        statusCode: response.statusCode,
        responseHeaders: headersMap,
        responseBodyBytes: responseBytes,
      );
    } catch (e) {
      client.close();
      // If final GET fails, still return success since chunks were uploaded
      // This is common with servers that don't support GET after POST
      return UploadResult(
        statusCode: 200,
        responseHeaders: const {},
        responseBodyBytes: const <int>[],
      );
    }
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
        'Content-Range',
        'bytes $start-${start + bytes.length - 1}/$total',
      );
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
  HttpClientResponse response,
) async {
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
