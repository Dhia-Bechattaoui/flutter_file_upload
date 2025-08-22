import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_file_upload_method_channel.dart';

abstract class FlutterFileUploadPlatform extends PlatformInterface {
  /// Constructs a FlutterFileUploadPlatform.
  FlutterFileUploadPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterFileUploadPlatform _instance = MethodChannelFlutterFileUpload();

  /// The default instance of [FlutterFileUploadPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterFileUpload].
  static FlutterFileUploadPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterFileUploadPlatform] when
  /// they register themselves.
  static set instance(FlutterFileUploadPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
