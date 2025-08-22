export 'src/uploader.dart';
export 'src/platform_uploader.dart';
import 'flutter_file_upload_platform_interface.dart';

class FlutterFileUpload {
  Future<String?> getPlatformVersion() {
    return FlutterFileUploadPlatform.instance.getPlatformVersion();
  }
}
