import 'dart:convert';
import 'dart:io';

class FileSender {
  final String filePath;
  final String senderIP;
  final int availablePort;
  final int size;
  int _resumeOffset = 0; // ✅ Keep track of resume position
  bool _isPaused = false; // ✅ Track if paused

  FileSender({required this.filePath, required this.senderIP, required this.availablePort , required this.size});

  Future<void> startSendingFile() async {
    final file = File(filePath);

    if (!file.existsSync()) {
      print("File does not exist: $filePath");
      return;
    }

    final fileName = file.uri.pathSegments.last;
    final server = await HttpServer.bind(senderIP, availablePort);
    print("WebSocket server started at ws://$senderIP:$availablePort");

    server.transform(WebSocketTransformer()).listen((WebSocket ws) async {
      print("Receiver connected.");
      
      ws.add(jsonEncode({"type": "startFile", "fileName": fileName , "size": size}));

      await for (final message in ws) {
        final data = jsonDecode(message);

        if (data['type'] == 'resume') {
          _resumeOffset = data['receivedBytes']; // ✅ Resume from where it left off
          print("Resuming file transfer from byte $_resumeOffset");
          _sendChunks(ws, file);
        }
      }
      
    }, onError: (error) {
      print("WebSocket server error: $error");
      server.close();
    });
  }

  Future<void> _sendChunks(WebSocket ws, File file) async {
    final stream = file.openRead(_resumeOffset);
    await for (final chunk in stream) {
      if (_isPaused) break; 

      final base64Chunk = base64Encode(chunk);
      ws.add(jsonEncode({"type": "fileChunk", "chunk": base64Chunk}));
    }

    if (!_isPaused) {
      ws.add(jsonEncode({"type": "endOfFile"}));
      print("File transfer complete.");
    }
  }

  void pauseSending() {
    _isPaused = true;
    print("File sending paused at $_resumeOffset.");
  }

  void resumeSending(WebSocket ws, File file) {
    _isPaused = false;
    print("Resuming file transfer from byte $_resumeOffset.");
    _sendChunks(ws, file);
  }
}
