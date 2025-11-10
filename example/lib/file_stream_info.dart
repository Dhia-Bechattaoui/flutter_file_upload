import 'dart:async';

/// Information about a file stream
class FileStreamInfo {
  final Stream<List<int>> stream;
  final int totalBytes;

  FileStreamInfo({required this.stream, required this.totalBytes});
}
