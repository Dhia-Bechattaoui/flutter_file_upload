import 'dart:async';

/// Progress callback providing the number of bytes sent and optional total.
typedef UploadProgressCallback = void Function(int bytesSent, int? totalBytes);

/// Represents a chunk of bytes to upload.
class UploadChunk {
  final List<int> bytes;
  final int index;
  final int startOffset;
  final int endOffset;

  UploadChunk({
    required this.bytes,
    required this.index,
    required this.startOffset,
    required this.endOffset,
  });
}

/// Interface for platform-specific uploaders.
abstract class PlatformUploader {
  Future<UploadResult> upload({
    required Uri url,
    required Stream<List<int>> byteStream,
    required int? totalByteLength,
    Map<String, String>? headers,
    int chunkSizeBytes,
    UploadProgressCallback? onProgress,
    FutureOr<bool> Function(int nextByteStart)? shouldResumeFrom,
  });
}

/// Result of an upload operation.
class UploadResult {
  final int statusCode;
  final Map<String, String> responseHeaders;
  final List<int> responseBodyBytes;

  const UploadResult({
    required this.statusCode,
    required this.responseHeaders,
    required this.responseBodyBytes,
  });
}

/// High-level uploader API.
class FileUploader {
  final PlatformUploader _platform;

  FileUploader(this._platform);

  Future<UploadResult> upload(
    Uri url, {
    required Stream<List<int>> byteStream,
    int? totalByteLength,
    Map<String, String>? headers,
    int chunkSizeBytes = 1024 * 256,
    UploadProgressCallback? onProgress,
    FutureOr<bool> Function(int nextByteStart)? shouldResumeFrom,
  }) async {
    return _platform.upload(
      url: url,
      byteStream: byteStream,
      totalByteLength: totalByteLength,
      headers: headers,
      chunkSizeBytes: chunkSizeBytes,
      onProgress: onProgress,
      shouldResumeFrom: shouldResumeFrom,
    );
  }
}
