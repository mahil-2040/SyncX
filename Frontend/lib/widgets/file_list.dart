import 'package:flutter/material.dart';
import 'package:p2p/providers/files_provider.dart';
import 'package:p2p/services/socket_service.dart';
import 'package:provider/provider.dart';

class FileList extends StatefulWidget {
  const FileList(
      {super.key, required this.fileList, required this.socketService});
  final List<Map<String, dynamic>> fileList;
  final SocketService? socketService;

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> with TickerProviderStateMixin {
  late List<Map<String, dynamic>> fileStructure;
  late FileState fileProvider;

  @override
  void initState() {
    super.initState();
    fileProvider = Provider.of<FileState>(context, listen: false);
    fileStructure = convertToNestedStructure(widget.fileList);
  }

  List<Map<String, dynamic>> convertToNestedStructure(
      List<Map<String, dynamic>> fileList) {
    void addToNestedStructure(Map<String, dynamic> currentFolder,
        List<String> pathParts, String name, String type, String id, String ip, int size) {
      if (pathParts.isEmpty) return;

      String currentPart = pathParts.removeAt(0);

      bool isFile = currentPart.contains('.');

      if (pathParts.isEmpty && isFile) {
        (currentFolder['children'] ??= []).add({
          "name": currentPart,
          "fileType": "file",
          "_id": id,
          "ip" : ip,
          "size" : size ?? 0, // change
        });
        return;
      }

      Map<String, dynamic> folder = currentFolder['children']?.firstWhere(
        (child) =>
            child['name'] == currentPart && child['fileType'] == "folder",
        orElse: () {
          Map<String, dynamic> newFolder = {
            "name": currentPart,
            "fileType": "folder",
            "isExpanded": false,
            "_id": id,
            "size" : size ?? 0, // change
            "children": [],
          };
          (currentFolder['children'] ??= []).add(newFolder);
          return newFolder;
        },
      );

      addToNestedStructure(folder, pathParts, name, type, id,ip, size);
    }

    List<Map<String, dynamic>> result = [];

    for (var file in fileList) {
      List<String> pathParts = file['path'].split('\\');
      String name = file['name'];
      String type = file['fileType'];
      String id = file['_id'];
      String ip = file['ip'];
      int size = file['size']; // change
      if (pathParts.length == 1) {
        // Top-level file or folder
        if (type == "file" || name.contains('.')) {
          result.add({"name": name, "fileType": "file", "_id": id});
        } else {
          result.add({
            "name": name,
            "fileType": "folder",
            "_id": id,
            "isExpanded": false,
            "size" : size ?? 0, // change
            "children": []
          });
        }
      } else {
        // Nested files or folders
        String rootFolder = pathParts.removeAt(0);
        Map<String, dynamic> folder = result.firstWhere(
          (item) => item['name'] == rootFolder && item['fileType'] == "folder",
          orElse: () {
            Map<String, dynamic> newFolder = {
              "name": rootFolder,
              "fileType": "folder",
              "_id": id,
              "ip" : ip,
              "size" : size ?? 0, // change
              "isExpanded": false,
              "children": [],
            };
            result.add(newFolder);
            return newFolder;
          },
        );
        addToNestedStructure(folder, pathParts, name, type, id, ip, size);
      }
    }
    return result;
  }

  // dynamic selectedItem;
  void handleSelection(Map<String, dynamic> selectedItem) {
    // Update the selected item in FileState
    fileProvider.updateSelectedItem(selectedItem);
  }

  void toggleFolder(Map<String, dynamic> folder) {
    setState(() {
      folder["isExpanded"] = !(folder["isExpanded"] ?? false);
    });
  }

  Widget buildFileTree(List<Map<String, dynamic>> items, {int level = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        bool isSelected = Provider.of<FileState>(context).selectedItem?['name'] == item['name'];
        bool isFolder = item["fileType"] == "folder";
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                handleSelection(item);
                if (isFolder) {
                  toggleFolder(item);
                }
              },
              child: Container(
                // constraints: BoxConstraints(minWidth: ),
                margin: EdgeInsets.only(left: level * 25),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.teal.withAlpha((0.6 * 255).toInt())
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    if (isFolder)
                      Icon(
                        item["isExpanded"]
                            ? Icons.arrow_drop_down
                            : Icons.arrow_right,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    Icon(
                      isFolder
                          ? (item['isExpanded']
                              ? Icons.folder_open
                              : Icons.folder)
                          : Icons.insert_drive_file,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item["name"] + (isFolder ? "/" : ""),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade300,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isFolder)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: item["isExpanded"]
                    ? buildFileTree(
                        List<Map<String, dynamic>>.from(item["children"] ?? []),
                        level: level + 1,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: buildFileTree(fileStructure),
        ),
      ),
    );
  }
}
