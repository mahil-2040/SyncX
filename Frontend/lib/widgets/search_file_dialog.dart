import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:p2p/services/socket_service.dart';
import 'package:provider/provider.dart';

class SearchFileDialog extends StatefulWidget {
  const SearchFileDialog({super.key, required this.serverIP});
  final String serverIP;

  @override
  State<SearchFileDialog> createState() => _SearchFileDialogState();
}

class _SearchFileDialogState extends State<SearchFileDialog> {
  final TextEditingController _searchController = TextEditingController();
  dynamic selectedFile;
  List<Map<String, dynamic>> allFiles = [];

  List<Map<String, dynamic>> filteredFiles = [];

  @override
  void initState() {
    super.initState();
    filteredFiles;
  }

  @override
  Widget build(BuildContext context) {
    final usersList = Provider.of<SocketService>(context, listen: false).users;

    return Dialog(
      backgroundColor: const Color.fromARGB(255, 54, 54, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 35,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 32, 32, 32),
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(5), topLeft: Radius.circular(5)),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Global Search",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 15,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search for files among your peers',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35,
                          child: TextFormField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(255, 45, 45, 45),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide:
                                    const BorderSide(color: Colors.black),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide:
                                    const BorderSide(color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      _button('Search', () {
                        searchFiles(_searchController.text);
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration:
                        BoxDecoration(border: Border.all(color: Colors.black)),
                    height: 400,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: IntrinsicWidth(
                          child: DataTable(
                            headingRowHeight: 30,
                            columnSpacing: 30,
                            dataRowMinHeight: 30,
                            dataRowMaxHeight: 30,
                            border: TableBorder.symmetric(
                              inside: const BorderSide(
                                  color: Colors.black, width: 1),
                              outside: const BorderSide(
                                  color: Colors.black, width: 1),
                            ),
                            columns: const [
                              DataColumn(
                                label: SizedBox(
                                  width: 250,
                                  child: Text('Item',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 60,
                                  child: Text('Type',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 70,
                                  child: Text('Owner',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 70,
                                  child: Text('Size',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                            rows: filteredFiles.map((file) {
                              bool isSelected = false;
                              if (selectedFile != null) {
                                isSelected = selectedFile['_id'] == file['_id'];
                              }
                              return DataRow(
                                selected: isSelected,
                                color: WidgetStateProperty.resolveWith<Color?>(
                                  (states) {
                                    if (isSelected) {
                                      return Colors.teal.withAlpha((0.6 * 255)
                                          .toInt()); // Selected color
                                    }
                                    return null; // Default color
                                  },
                                ),
                                onSelectChanged: (data) {
                                  setState(() {
                                    selectedFile = file;
                                  });
                                },
                                cells: [
                                  DataCell(
                                    Text(
                                      file['name'],
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DataCell(
                                    Text(file['fileType'],
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                  DataCell(
                                    Text(
                                      usersList.firstWhere(
                                        (user) => user["id"] == file['owner'],
                                        orElse: () => {
                                          "name": "Unknown"
                                        }, 
                                      )["name"],
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                        '${(double.parse((file['size'] / (1024*1024)).toStringAsFixed(2))).toString()} MB',
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _button('Download', () {
                        if (selectedFile != null) {
                          Provider.of<SocketService>(context, listen: false)
                              .downloadFile(
                            selectedFile['_id'],
                            context,
                            selectedFile['ip'],
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No file selected!')),
                          );
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  void searchFiles(String searchQuery) async {
    // change hardcoded value
    final String url = 
        'http://${widget.serverIP}:9000/api/users/searchFiles/$searchQuery';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          filteredFiles = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  Widget _button(String title, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 54, 54, 54),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color.fromARGB(255, 24, 24, 24)),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }
}
