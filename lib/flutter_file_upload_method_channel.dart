import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_file_upload_platform_interface.dart';

/// An implementation of [FlutterFileUploadPlatform] that uses method channels.
class MethodChannelFlutterFileUpload extends FlutterFileUploadPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_file_upload');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
