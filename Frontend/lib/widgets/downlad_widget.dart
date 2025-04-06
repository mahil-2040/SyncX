import 'package:flutter/material.dart';
import 'package:p2p/providers/download_pregress_provider.dart';
import 'package:provider/provider.dart';

class DownloadProgressList extends StatelessWidget {
  const DownloadProgressList({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = Provider.of<DownloadProvider>(context);

    return ListView.builder(
      shrinkWrap: true,
      itemCount: downloadProvider.downloads.length,
      itemBuilder: (context, index) {
        final file = downloadProvider.downloads[index];

        // Display the progress bar only if the file is not yet fully downloaded
        if (file.isCompleted) return SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    LinearProgressIndicator(
                      value: file.progress,
                      color: Colors.teal,
                      backgroundColor: Colors.grey.shade700,
                    ),
                    Text(
                      '${(file.downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(file.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  file.progress == 1.0 ? Icons.check : Icons.pause,
                  color: Colors.white,
                ),
                onPressed: () {
                  downloadProvider.togglePause(file.fileName);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
