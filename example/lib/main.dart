import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter_file_upload/flutter_file_upload.dart';

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

  Future<void> _startUpload() async {
    final file = File('path/to/big.file');
    if (!await file.exists()) return;

    final total = await file.length();
    final uploader = FileUploader(createPlatformUploader());

    await uploader.upload(
      Uri.parse('https://example.com/upload'),
      byteStream: file.openRead(),
      totalByteLength: total,
      chunkSizeBytes: 256 * 1024,
      onProgress: (sent, total) => setState(() {
        _progress = total == null || total == 0 ? 0 : sent / total;
      }),
      shouldResumeFrom: (start) async => true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LinearProgressIndicator(value: _progress == 0 ? null : _progress),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _startUpload,
          child: const Text('Start Upload'),
        ),
      ],
    );
  }
}
