import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_upload/flutter_file_upload.dart';
import 'package:file_picker/file_picker.dart';
import 'file_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_file_upload example')),
        body: const Center(child: UploadDemo()),
      ),
    );
  }
}

class UploadDemo extends StatefulWidget {
  const UploadDemo({super.key});

  @override
  State<UploadDemo> createState() => _UploadDemoState();
}

class _UploadDemoState extends State<UploadDemo> {
  double _progress = 0;
  String _status = 'Ready - Select a file to upload';
  bool _isUploading = false;
  int _maxBytesSent =
      0; // Track maximum bytes sent to prevent progress from going backwards
  String? _selectedFileName;

  Future<void> _pickAndUploadFile() async {
    try {
      // Pick a file
      // On web, always use withData to get bytes directly
      // On native, try path first (no caching), then fallback to bytes if needed
      FilePickerResult? result;
      if (kIsWeb) {
        // Web: Always use withData to get file bytes directly
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
      } else {
        // Native: Try without withData first to use path directly (avoids caching)
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
          );
        } catch (e) {
          // If that fails, try with withData as fallback
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
            withData: true,
          );
        }
      }

      if (result == null) {
        setState(() {
          _status = 'No file selected';
        });
        return;
      }

      final file = result.files.single;
      _selectedFileName = file.name;

      // On web, always use bytes (file.path doesn't work on web)
      // On native, prefer path (streams from disk, no memory issues)
      if (kIsWeb) {
        // Web: Must use bytes
        if (file.bytes != null) {
          final fileSize = file.size;
          setState(() {
            _status =
                'Selected: $_selectedFileName (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)\nStarting upload...';
          });
          await _startUploadFromBytes(file.bytes!, fileSize);
          return;
        } else {
          setState(() {
            _status =
                'Error: Could not read file bytes on web.\nFile may be too large.';
          });
          return;
        }
      } else {
        // Native: Prefer file path (no caching, works even with low storage)
        final filePath = file.path;
        if (filePath != null) {
          setState(() {
            _status = 'Selected: $_selectedFileName\nStarting upload...';
          });
          await _startUpload(filePath);
          return;
        }

        // Fallback to bytes if path not available
        if (file.bytes != null) {
          final fileSize = file.size;
          setState(() {
            _status =
                'Selected: $_selectedFileName (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)\nStarting upload...';
          });
          await _startUploadFromBytes(file.bytes!, fileSize);
          return;
        }

        setState(() {
          _status = 'Error: Could not get file path or data';
        });
      }
    } on PlatformException catch (e) {
      String errorMessage = 'File picker error: ${e.message ?? e.code}';

      // Handle specific error cases
      if (e.code == 'unknown_path' ||
          e.message?.contains('No space') == true ||
          e.message?.contains('ENOSPC') == true) {
        errorMessage =
            'Storage Error: Device is out of space.\n\n'
            'Solutions:\n'
            '• Free up storage space on your device\n'
            '• Try selecting a smaller file\n'
            '• Clear app cache/data\n\n'
            'The file picker needs temporary space to process files.';
      }

      setState(() {
        _status = errorMessage;
      });
    } catch (e) {
      setState(() {
        _status = 'Error picking file: $e';
      });
    }
  }

  Future<void> _startUploadFromBytes(List<int> bytes, int total) async {
    setState(() {
      _isUploading = true;
      _progress = 0;
      _maxBytesSent = 0;
      _status = 'Uploading $_selectedFileName...';
    });

    try {
      // Create a stream from bytes - chunk it to avoid memory issues
      // For large files, yield in chunks to simulate streaming
      Stream<List<int>> byteStream;
      if (bytes.length > 1024 * 1024) {
        // For files > 1 MB, chunk the bytes to simulate streaming
        const chunkSize = 256 * 1024; // 256 KB chunks
        byteStream = Stream.periodic(const Duration(milliseconds: 1), (index) {
          final start = index * chunkSize;
          if (start >= bytes.length) return null;
          final end = (start + chunkSize).clamp(0, bytes.length);
          return bytes.sublist(start, end);
        }).takeWhile((chunk) => chunk != null).cast<List<int>>();
      } else {
        // Small files: send all at once
        byteStream = Stream.value(bytes);
      }

      setState(() {
        _status = 'Uploading ${(total / 1024 / 1024).toStringAsFixed(1)} MB...';
      });

      await _performUpload(byteStream, total);
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _startUpload(String filePath) async {
    setState(() {
      _isUploading = true;
      _progress = 0;
      _maxBytesSent = 0; // Reset max bytes sent
      _status = 'Uploading $_selectedFileName...';
    });

    try {
      // getFileStream() handles platform differences automatically:
      // - On web: creates a demo 5 MB stream (filePath is ignored)
      // - On native: reads from the provided file path
      final fileInfo = await getFileStream(filePath);
      final byteStream = fileInfo.stream;
      final total = fileInfo.totalBytes;

      setState(() {
        _status = 'Uploading ${(total / 1024 / 1024).toStringAsFixed(1)} MB...';
      });

      await _performUpload(byteStream, total);
    } catch (e) {
      String errorMessage;
      final errorString = e.toString();

      // Provide helpful error messages for common cases
      if (errorString.contains('Failed to fetch') ||
          errorString.contains('ClientException') ||
          errorString.contains('NetworkError')) {
        errorMessage =
            'Network error: Could not connect to upload endpoint.\n\n'
            'This is expected - "example.com/upload" is a placeholder URL.\n'
            'Replace it with your actual upload endpoint to test real uploads.\n\n'
            'For testing, you can use:\n'
            '• httpbin.org/post (for testing)\n'
            '• Your own server endpoint';
      } else if (errorString.contains('File not found')) {
        errorMessage = errorString;
      } else {
        errorMessage = 'Error: $e';
      }

      setState(() {
        _status = errorMessage;
        _isUploading = false;
      });
    }
  }

  Future<void> _performUpload(Stream<List<int>> byteStream, int total) async {
    try {
      // createPlatformUploader() automatically selects WebPlatformUploader or IoPlatformUploader
      final uploader = FileUploader(createPlatformUploader());

      // Using httpbin.org/anything for testing - accepts any HTTP method (POST for chunks, GET for final verification)
      // Replace with your actual upload endpoint in production
      final result = await uploader.upload(
        Uri.parse('https://httpbin.org/anything'),
        byteStream: byteStream,
        totalByteLength: total,
        headers: {
          'Authorization': 'Bearer <token>',
          'Content-Type': 'application/octet-stream',
        },
        chunkSizeBytes: 256 * 1024, // Configurable chunk size
        onProgress: (sent, total) {
          // Progress callback with bytesSent and totalBytes
          // Ensure progress only increases (chunks may complete out of order in parallel uploads)
          if (sent > _maxBytesSent) {
            _maxBytesSent = sent;
            setState(() {
              _progress = total == null || total == 0 ? 0 : sent / total;
              _status =
                  'Uploading: ${(sent / 1024 / 1024).toStringAsFixed(2)} MB / ${total != null ? (total / 1024 / 1024).toStringAsFixed(2) : '?'} MB';
            });
          }
        },
        shouldResumeFrom: (nextStart) async {
          // Resume strategy hook - return true to continue, false to skip
          // You could check server state here to resume from a specific byte position
          return true;
        },
        skipFinalRequest: false, // Set to true to skip the final GET request
      );

      setState(() {
        if (result.statusCode >= 200 && result.statusCode < 300) {
          _status = 'Upload successful! Status: ${result.statusCode}';
        } else {
          _status = 'Upload complete! Status: ${result.statusCode}';
        }
        _isUploading = false;
      });
    } catch (e) {
      String errorMessage;
      final errorString = e.toString();

      // Handle network/CORS errors
      if (errorString.contains('Failed to fetch') ||
          errorString.contains('ClientException') ||
          errorString.contains('NetworkError') ||
          errorString.contains('CORS')) {
        errorMessage =
            'Network/CORS Error: Some requests failed.\n\n'
            'This is common with test servers like httpbin.org:\n'
            '• CORS restrictions may block some requests\n'
            '• Rate limiting may reject some chunks\n'
            '• Some chunks may succeed while others fail\n\n'
            'On a real server with proper CORS headers:\n'
            '• Set Access-Control-Allow-Origin: *\n'
            '• Set Access-Control-Allow-Methods: POST, GET\n'
            '• Set Access-Control-Allow-Headers: Content-Range, Content-Type\n\n'
            'The upload will work correctly on a properly configured server.';
      } else {
        errorMessage = 'Upload Error: $e';
      }

      setState(() {
        _status = errorMessage;
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _status,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: _progress == 0 ? null : _progress,
            minHeight: 8,
          ),
          if (_progress > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isUploading ? null : _pickAndUploadFile,
            child: Text(_isUploading ? 'Uploading...' : 'Pick File & Upload'),
          ),
          const SizedBox(height: 16),
          Text(
            'Features demonstrated:\n'
            '• Streaming bytes with configurable chunk size\n'
            '• Progress callback (bytesSent, totalBytes)\n'
            '• Resume strategy hook (shouldResumeFrom)\n'
            '• Headers support\n'
            '• Platform detection (Web/IO)',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
