import 'uploader.dart';
import 'uploader_web.dart' if (dart.library.io) 'uploader_io.dart' as impl;

PlatformUploader createPlatformUploader() => impl.createPlatformUploaderImpl();
