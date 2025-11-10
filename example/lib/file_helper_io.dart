import 'dart:async';
import 'dart:io' show File, FileSystemException;
import 'file_stream_info.dart';

Future<FileStreamInfo> getFileStream(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    // Provide helpful error message with common locations
    final errorMessage =
        'File not found: $path\n\n'
        'Common file locations:\n'
        '• Android Downloads: /storage/emulated/0/Download/file.zip\n'
        '• Android: /sdcard/Download/file.zip\n'
        '• iOS Documents: Place file.zip in app Documents directory\n'
        '  (Access via Files app or Xcode Device window)\n'
        '• Desktop: Use absolute path like /Users/username/Downloads/file.zip\n\n'
        'Make sure the file exists and the app has permission to read it.';
    throw FileSystemException(errorMessage, path);
  }
  final total = await file.length();
  return FileStreamInfo(stream: file.openRead(), totalBytes: total);
}
