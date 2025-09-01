import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  String _statusMessage = 'Select a file to start compression';
  File? _selectedFile;
  bool _isCompressing = false;
  String? _compressedFilePath;

  Future<void> _selectFile(FileType type) async {
    final result = await FilePicker.platform.pickFiles(type: type);

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _statusMessage = 'Selected: ${_selectedFile!.path.split('/').last}';
        _compressedFilePath = null;
      });
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File selection cancelled.')),
      );
    }
  }

  Future<void> _compress() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first!')),
      );
      return;
    }

    setState(() {
      _isCompressing = true;
      _statusMessage = 'Compressing, please wait...';
    });

    final inputPath = _selectedFile!.path;
    final extension = inputPath.split('.').last;
    final documentsDir = await getApplicationDocumentsDirectory();
    final outputPath =
        '${documentsDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.$extension';

    // More robust compression command with progress
    final command = '-i "$inputPath" -y -vcodec mpeg4 -b:v 1024k -acodec aac -b:a 128k "$outputPath"';

    await FFmpegKit.executeAsync(
      command,
      (session) async {
        final returnCode = await session.getReturnCode();
        setState(() {
          _isCompressing = false;
          if (ReturnCode.isSuccess(returnCode)) {
            _statusMessage = 'Compression successful!';
            _compressedFilePath = outputPath;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved to: $outputPath')),
            );
          } else if (ReturnCode.isCancel(returnCode)) {
            _statusMessage = 'Compression cancelled.';
          } else {
            _statusMessage = 'Error: Compression failed. Please try another file.';
          }
        });
      },
      (log) => print(log.getMessage()),
      (statistics) {
        // You can use statistics to update a progress bar
      },
    );
  }

  void _shareFile() {
    if (_compressedFilePath != null) {
      Share.shareXFiles([XFile(_compressedFilePath!)], text: 'Check out my compressed file!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No compressed file to share!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compress Media'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset('images/download (3).png', height: 150),
                const SizedBox(height: 30),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_selectedFile != null) ...[
                  const SizedBox(height: 15),
                  Chip(
                    label: Text(_selectedFile!.path.split('/').last),
                    onDeleted: () {
                      setState(() {
                        _selectedFile = null;
                        _compressedFilePath = null;
                        _statusMessage = 'Select a file to start compression';
                      });
                    },
                  ),
                ],
                const SizedBox(height: 30),
                if (_isCompressing)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('This may take a moment...'),
                    ],
                  )
                else ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.video_library),
                    onPressed: () => _selectFile(FileType.video),
                    label: const Text('Select Video'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.audiotrack),
                    onPressed: () => _selectFile(FileType.audio),
                    label: const Text('Select Audio'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.compress),
                    onPressed: _selectedFile != null ? _compress : null,
                    label: const Text('Start Compression'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (_compressedFilePath != null && !_isCompressing) ...[
                  const SizedBox(height: 30),
                  const Text('Compressed File:'),
                  Chip(label: Text(_compressedFilePath!.split('/').last)),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    onPressed: _shareFile,
                    label: const Text('Share File'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
