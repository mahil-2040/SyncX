import 'package:flutter/material.dart';

class FileDownload {
  String fileName;
  double progress;
  int downloadedBytes;
  int totalBytes;
  bool isCompleted;
  bool isPaused;

  FileDownload({
    required this.fileName,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    required this.totalBytes,
    this.isCompleted = false,
    this.isPaused = false,
  });
}

class DownloadProvider extends ChangeNotifier {
  final List<FileDownload> _downloads = [];

  List<FileDownload> get downloads => _downloads;

  void addDownload(String fileName, int totalBytes) {
    _downloads.add(FileDownload(fileName: fileName, totalBytes: totalBytes));
    notifyListeners();
  }

  void updateProgress(String fileName, int downloadedBytes) {
    final file = _downloads.firstWhere((f) => f.fileName == fileName);
    file.downloadedBytes = downloadedBytes;
    file.progress = downloadedBytes / file.totalBytes;
    if (downloadedBytes >= file.totalBytes) {
      file.isCompleted = true;
    }
    notifyListeners();
  }

  void togglePause(String fileName) {
    final file = _downloads.firstWhere((f) => f.fileName == fileName);
    file.isPaused = !file.isPaused;
    notifyListeners();
  }

  void removeCompletedFiles() {
    _downloads.removeWhere((file) => file.isCompleted);
    notifyListeners();
  }
}
