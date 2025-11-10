import 'dart:async';
import 'file_stream_info.dart';

/// Creates a demo byte stream for web platform
Stream<List<int>> _createDemoStream(int sizeBytes) async* {
  const chunkSize = 64 * 1024; // 64 KB chunks
  final random = DateTime.now().millisecondsSinceEpoch;

  for (int offset = 0; offset < sizeBytes; offset += chunkSize) {
    final remaining = sizeBytes - offset;
    final currentChunkSize = remaining < chunkSize ? remaining : chunkSize;
    final chunk = List<int>.generate(
      currentChunkSize,
      (index) => (random + offset + index) % 256,
    );
    yield chunk;
    // Small delay to simulate real file reading
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

Future<FileStreamInfo> getFileStream(String path) async {
  // On web, create a demo stream (5 MB)
  const total = 5 * 1024 * 1024; // 5 MB
  return FileStreamInfo(stream: _createDemoStream(total), totalBytes: total);
}
