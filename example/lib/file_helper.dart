import 'dart:async';
import 'file_stream_info.dart';
import 'file_helper_stub.dart'
    if (dart.library.io) 'file_helper_io.dart'
    if (dart.library.html) 'file_helper_web.dart'
    as impl;

export 'file_stream_info.dart';

/// Platform-agnostic file helper
Future<FileStreamInfo> getFileStream(String path) => impl.getFileStream(path);
