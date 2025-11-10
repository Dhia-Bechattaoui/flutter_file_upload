# flutter_file_upload

Advanced file upload for Flutter with progress tracking, chunked uploads, and resume capability. Works on iOS, Android, Web, Windows, macOS, and Linux. WASM compatible.

<img src="example/example.gif" width="300" alt="Example demonstration">

## Features

- ✅ **Streaming uploads** with configurable chunk size
- ✅ **Progress tracking** via callback `(bytesSent, totalBytes)`
- ✅ **Resume capability** with `shouldResumeFrom` hook
- ✅ **Platform detection** - automatically selects Web or IO implementation
- ✅ **Skip final request** - optional parameter to skip verification request
- ✅ **Pure Dart API** - Flutter-friendly, no platform channels needed
- ✅ **Cross-platform** - iOS, Android, Web, Windows, macOS, Linux

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_file_upload: ^0.1.0
```

## Usage

### Basic Example

```dart
import 'dart:io';
import 'package:flutter_file_upload/flutter_file_upload.dart';

Future<void> uploadFile() async {
  final file = File('path/to/big.file');
  final stream = file.openRead();
  final total = await file.length();

  // Automatically selects WebPlatformUploader or IoPlatformUploader
  final uploader = FileUploader(createPlatformUploader());

  final result = await uploader.upload(
    Uri.parse('https://example.com/upload'),
    byteStream: stream,
    totalByteLength: total,
    headers: {'Authorization': 'Bearer <token>'},
    chunkSizeBytes: 256 * 1024, // 256 KB chunks
    onProgress: (sent, total) {
      print('Progress: ${sent}/${total} bytes (${(sent / total * 100).toStringAsFixed(1)}%)');
    },
    shouldResumeFrom: (nextStart) async {
      // Return true to continue, false to skip/resume from different position
      return true;
    },
    skipFinalRequest: false, // Set to true to skip final GET verification
  );

  print('Upload complete! Status: ${result.statusCode}');
}
```

### Platform-Specific Usage

For explicit platform selection:

```dart
// For native platforms (iOS, Android, Windows, macOS, Linux)
final uploader = FileUploader(IoPlatformUploader());

// For Web
final uploader = FileUploader(WebPlatformUploader());
```

### Skip Final Request

Some servers don't support the final GET verification request. Use `skipFinalRequest`:

```dart
final result = await uploader.upload(
  Uri.parse('https://api.example.com/upload'),
  byteStream: stream,
  totalByteLength: total,
  skipFinalRequest: true, // Skip final GET request
);
```

### Resume Strategy

Implement custom resume logic:

```dart
shouldResumeFrom: (nextStart) async {
  // Check with server if upload already exists
  final serverStatus = await checkServerStatus(nextStart);
  if (serverStatus.alreadyUploaded) {
    return false; // Skip this chunk
  }
  return true; // Continue uploading
},
```

## API Reference

### `FileUploader.upload()`

Uploads a stream of bytes in chunks.

**Parameters:**
- `url` (required): The upload endpoint URI
- `byteStream` (required): Stream of bytes to upload
- `totalByteLength`: Total size in bytes (optional, for progress calculation)
- `headers`: HTTP headers to include with each request
- `chunkSizeBytes`: Size of each chunk in bytes (default: 256 KB)
- `onProgress`: Callback `(bytesSent, totalBytes)` called after each chunk
- `shouldResumeFrom`: Hook `(nextByteStart)` to control resume behavior
- `skipFinalRequest`: Skip final GET verification request (default: false)

**Returns:** `UploadResult` with status code, headers, and response body

## Platform Support

| Platform | Status |
|----------|--------|
| iOS | ✅ Supported |
| Android | ✅ Supported |
| Web | ✅ Supported |
| Windows | ✅ Supported |
| macOS | ✅ Supported |
| Linux | ✅ Supported |
| WASM | ✅ Compatible |

## License

See `LICENSE` file for details.
