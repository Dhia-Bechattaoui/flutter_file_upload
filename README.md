## flutter_file_upload

Advanced file upload for Flutter with progress tracking, chunked uploads, and resume capability. Works on iOS, Android, Web, Windows, macOS, and Linux. WASM compatible.

### Features
- Upload streaming bytes with configurable chunk size
- Progress callback `(bytesSent, totalBytes)`
- Resume strategy hook via `shouldResumeFrom`
- Conditional imports for Web and IO
- Pure Dart API, Flutter-friendly

### Getting started
Add the dependency:

```yaml
dependencies:
  flutter_file_upload: ^0.0.1
```

### Usage
```dart
import 'dart:io';
import 'package:flutter_file_upload/flutter_file_upload.dart';

Future<void> example() async {
  final file = File('path/to/big.file');
  final stream = file.openRead();
  final total = await file.length();

  final uploader = FileUploader(IoPlatformUploader());

  final result = await uploader.upload(
    Uri.parse('https://example.com/upload'),
    byteStream: stream,
    totalByteLength: total,
    headers: {'Authorization': 'Bearer <token>'},
    chunkSizeBytes: 256 * 1024,
    onProgress: (sent, total) => print('Progress: $sent/$total'),
    shouldResumeFrom: (nextStart) async => true,
  );

  print('Upload done: status ${result.statusCode}');
}
```

For Web, use `WebPlatformUploader()` instead.

### License
See `LICENSE`.
