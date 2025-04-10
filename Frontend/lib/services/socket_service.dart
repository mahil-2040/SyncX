import 'dart:async';
import 'dart:io';
import 'package:p2p/services/recieve_service.dart';
import 'package:p2p/services/sender_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

class SocketService with ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? socket;
  List<Map<String, dynamic>> groupMessage = [];
  Map<String, List<Map<String, dynamic>>> directMessage = {};
  List<dynamic> users = [];
  String? serverIP;
  dynamic availablePort;
  String? localIPAdress;
  String? username;
  String? receiveFolderPath;
  SocketService._internal();

  void initialize(String ip, String localIPAdress, String receiveFolderPath,
      String username) {
    serverIP = ip;
    this.localIPAdress = localIPAdress;
    this.receiveFolderPath = receiveFolderPath;
    this.username = username;
    connect();
  }

  void connect() {
    if (socket != null && socket!.connected) {
      print('Socket already connected: ${socket!.id}');
      return;
    }
    print("Server IP is $serverIP ");
    socket ??= IO.io(
      'http://$serverIP:9000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    socket!.onConnect((_) {
      print('Connected: ${socket!.id}');
    });

    // socket!.off('message');
    socket!.on('gmessage', (data) {
      print('Received gmessage: $data');
      groupMessage.add(data);
      notifyListeners();
    });

    socket!.on('dmessage', (data) {
      print('Received dmessage: $data');
      if (directMessage.containsKey(data['user'])) {
        directMessage[data['user']]!.add(data['msg']);
      } else {
        directMessage[data['user']] = [data['msg']];
      }
      notifyListeners();
    });

    socket!.on('user_joined', (data) {
      print('User joined: $data');
      users.add(data['newUser']);
      notifyListeners();
    });

    socket!.on('free-port', (data) {
      availablePort = data['availablePort'];
    });

    socket!.on('userDisconnect', (data) {
      print('called');
      users.removeWhere((user) => user['_id'] == data['user']);
      notifyListeners();
    });

    socket!.on("fileRequest", (data) async {
      final freePort = await getFreePort();
      final fileSender = FileSender(
        availablePort: freePort,
        filePath: data['file'],
        senderIP: localIPAdress!,
        size: data['size']
      );
      socket!.emit("portInfo",
          {"availablePort": freePort, "userSocketId": data['userSocketId']});
      fileSender.startSendingFile();
    });
    socket!.onDisconnect((_) => print('Disconnected from server'));
  }

  bool isConnected() => socket != null && socket!.connected;

  void registerUser(String username, String shareFolderPath, String serverIP) {
    socket!.emit('register', {
      'username': username,
      'fileList': getFolderContents(shareFolderPath),
      'ip': serverIP,
    });
  }

  void sendGroupMessage(String msg) {
    if (socket != null && socket!.connected) {
      socket!.emit('groupMessage', {'msg': msg, 'user': username});
    }
  }

  void sendAndAddDirectMessage(String msg, String sender, String reciever) {
    if (socket != null && socket!.connected) {
      socket!.emit('directMessage', {'msg': msg, 'user': sender});
    }
    directMessage[reciever] ??= [];  
    directMessage[reciever]!.add({
      'sender': sender,
      'message': msg,
      'isMe': true,
    });
    notifyListeners();
  }

  Future<int> getFreePort() async {
    final socket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  void downloadFile(
      String fileId, BuildContext context, String senderIP) async {
    print(receiveFolderPath);
    if (socket != null && socket!.connected) {
      socket!.emit('requestFile', {'fileId': fileId});

      if (availablePort == null) {
        print("Waiting for available port...");

        Timer.periodic(Duration(milliseconds: 100), (timer) async {
          if (availablePort != null) {
            final fileReceiver = FileReceiver(
                senderIP: senderIP,
                senderPort: availablePort,
                receiveFolderPath: receiveFolderPath!);
            print("Port found: $availablePort. Starting file download.");
            timer.cancel();
            fileReceiver.start(context);
            availablePort = null;
          } else {
            print("Port not found yet. Retrying...");
          }
        });
      } else {
        final fileReceiver = FileReceiver(
            senderIP: senderIP,
            senderPort: availablePort,
            receiveFolderPath: receiveFolderPath!);
        fileReceiver.start(context);
        availablePort = null;
      }
    }
  }

  void disconnect() {
    socket?.disconnect();
  }

  List<Map<String, dynamic>> getFolderContents(String folderPath) {
    List<Map<String, dynamic>> results = [];

    try {
      Directory folder = Directory(folderPath);
      List<FileSystemEntity> entities = folder.listSync();

      for (var entity in entities) {
        FileStat stats = entity.statSync();
        String type =
            stats.type == FileSystemEntityType.directory ? "folder" : "file";

        int size = 0;
        if (type == "file") {
          size = stats.size;
        } else if (type == "folder") {
          size = _calculateFolderSize(entity.path);
        }

        results.add({
          "name": entity.uri.pathSegments.last == ''?'folder':entity.uri.pathSegments.last,
          "path": entity.path,
          "type": type,
          "size": size,
        });

        if (type == "folder") {
          results.addAll(getFolderContents(entity.path));
        }
      }
    } catch (e) {
      print("Error reading folder: $e");
    }

    return results;
  }

  int _calculateFolderSize(String folderPath) {
    int totalSize = 0;
    try {
      Directory folder = Directory(folderPath);
      List<FileSystemEntity> entities = folder.listSync();

      for (var entity in entities) {
        FileStat stats = entity.statSync();
        if (stats.type == FileSystemEntityType.file) {
          totalSize += stats.size;
        } else if (stats.type == FileSystemEntityType.directory) {
          totalSize += _calculateFolderSize(entity.path);
        }
      }
    } catch (e) {
      print("Error calculating folder size: $e");
    }

    return totalSize;
  }

  factory SocketService() {
    return _instance;
  }
}
