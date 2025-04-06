import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:p2p/providers/download_pregress_provider.dart';

class FileReceiver {
  final String senderIP;
  final int senderPort;
  IOWebSocketChannel? _channel;
  File? _file;
  IOSink? _fileSink;
  String receiveFolderPath;
  late Directory _publicFolder;
  int _totalBytesReceived = 0;
  int _expectedTotalBytes = 0;
  bool _isPaused = false; 
  final List<int> _bufferedChunks = []; 

  FileReceiver({
    required this.senderIP,
    required this.senderPort,
    required this.receiveFolderPath,
  }) {
    _publicFolder = Directory(receiveFolderPath);
  }

  void start(BuildContext context) {
    final uri = Uri.parse('ws://$senderIP:$senderPort');
    _channel = IOWebSocketChannel.connect(uri);

    if (!_publicFolder.existsSync()) {
      _publicFolder.createSync();
    }

    _channel!.stream.listen(
      (message) => _handleMessage(message, context),
      onDone: _handleDisconnect,
      onError: _handleError,
    );
  }

  void _handleMessage(dynamic message, BuildContext context) {
    try {
      if (message is String) {
        final data = jsonDecode(message);

        if (data['type'] == 'startFile') {
          final fileName = data['fileName'] ?? 'downloaded_file';
          _expectedTotalBytes = data['size'] ?? 0;
          _file = File('${_publicFolder.path}/$fileName');
          _fileSink = _file!.openWrite(mode: FileMode.append); // ✅ Allow resuming
          _totalBytesReceived = _file!.existsSync() ? _file!.lengthSync() : 0; // ✅ Start from last saved bytes

          Provider.of<DownloadProvider>(context, listen: false)
              .addDownload(fileName, _expectedTotalBytes);

          print('Receiving file: $fileName from byte $_totalBytesReceived');
          
          // ✅ Inform sender to start from where it stopped
          _channel!.sink.add(jsonEncode({"type": "resume", "receivedBytes": _totalBytesReceived}));
        } 
        else if (data['type'] == 'fileChunk') {
          final chunk = base64Decode(data['chunk']);

          if (_isPaused) {
            _bufferedChunks.addAll(chunk); // ✅ Store data while paused
            return;
          }

          _fileSink?.add(chunk);
          _totalBytesReceived += chunk.length;
          
          Provider.of<DownloadProvider>(context, listen: false)
              .updateProgress(_file!.path.split('/').last, _totalBytesReceived);

          if (_totalBytesReceived >= _expectedTotalBytes) {
            print('Download completed.');
          }
        } 
        else if (data['type'] == 'endOfFile') {
          _fileSink?.close();
          print('File received at: ${_file?.path}');
          _channel?.sink.close();
        }
      } 
      else {
        print('Unexpected message type: ${message.runtimeType}');
      }
    } catch (e) {
      print('Error processing message: $e');
    }
  }

  void pauseDownload() {
    _isPaused = true;
    print("Download paused at $_totalBytesReceived bytes.");
  }

  void resumeDownload() {
    _isPaused = false;
    print("Resuming download from $_totalBytesReceived bytes.");

    if (_bufferedChunks.isNotEmpty) {
      _fileSink?.add(_bufferedChunks);
      _totalBytesReceived += _bufferedChunks.length;
      _bufferedChunks.clear();
    }

    _channel!.sink.add(jsonEncode({"type": "resume", "receivedBytes": _totalBytesReceived}));
  }

  void _handleDisconnect() {
    print('Disconnected from sender.');
    _fileSink?.close();
  }

  void _handleError(error) {
    print('WebSocket error: $error');
  }
}
