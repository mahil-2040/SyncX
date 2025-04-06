import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:p2p/providers/files_provider.dart';
import 'package:p2p/services/socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:p2p/widgets/downlad_widget.dart';
import 'package:p2p/widgets/file_list.dart';
import 'dart:convert';
import 'package:p2p/widgets/message_bubble.dart';
import 'package:p2p/widgets/search_file_dialog.dart';
import 'package:p2p/widgets/settings_widget.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key, required this.currentUser, required this.serverIP});
  final Map<String, dynamic> currentUser;
  final String serverIP;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late TabController _tabController;
  String selectedFolder = "";
  String selectedFile = "";
  dynamic selectedUser;
  List<Map<String, dynamic>> userFileList = [];
  dynamic selectedUserFile;
  dynamic downloadingFile;

  @override
  void initState() {
    super.initState();
    // _fetchMessages();
    _getUsers();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    Provider.of<SocketService>(context, listen: false).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 54, 54, 54),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'P2P / ${widget.currentUser['username']}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                _button(
                  "Global Search",
                  () {
                    showAnimatedSettingsDialog(
                      context,
                      SearchFileDialog(
                        serverIP: widget.serverIP,
                      ),
                    );
                  },
                ),
                SizedBox(width: 10),
                _button("Import Files", () {
                  _pickFile();
                }),
                SizedBox(width: 10),
                _button("Import Folders", () {
                  _selectFolder();
                }),
                SizedBox(width: 10),
                _button(
                  "Settings",
                  () {
                    showAnimatedSettingsDialog(context, SettingsDialog());
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Browse Files',
                                style: TextStyle(color: Colors.white)),
                            SizedBox(width: 9),
                            Container(
                              height: 25,
                              width: 25,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 54, 54, 54),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Color.fromARGB(255, 24, 24, 24)),
                              ),
                              child: Icon(Icons.refresh,
                                  size: 16, color: Colors.white),
                            )
                          ],
                        ),
                        SizedBox(height: 10),
                        _infoContainer(
                            selectedUser == null
                                ? 'No user selected'
                                : selectedUser['username'],
                            height: 26),
                        SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 45, 45, 45),
                              border: Border.all(
                                  color: Color.fromARGB(255, 24, 24, 24)),
                            ),
                            child: userFileList.isEmpty
                                ? Center(
                                    child: Text('no user selected'),
                                  )
                                : FileList(
                                    fileList: userFileList,
                                    socketService: socketService,
                                  ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                                    Provider.of<FileState>(context)
                                                .selectedItem !=
                                            null
                                        ? Provider.of<FileState>(context)
                                            .selectedItem['name']
                                        : 'No file or folder selected',
                                    style: TextStyle(color: Colors.white))),
                            _button("Info", () {}),
                            SizedBox(width: 10),
                            _button("Download", () async {
                              final selectedUserFile =
                                  Provider.of<FileState>(context, listen: false)
                                      .selectedItem;
                              if (selectedUserFile != null) {
                                print(selectedUserFile);
                                Provider.of<SocketService>(context,
                                        listen: false)
                                    .downloadFile(
                                  selectedUserFile['_id'],
                                  context,
                                  selectedUserFile['ip'],
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('No file selected!')),
                                );
                              }
                              setState(() {
                                downloadingFile = selectedUserFile;
                              });
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Users', style: TextStyle(color: Colors.white)),
                        SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 45, 45, 45),
                              border: Border.all(
                                  color: Color.fromARGB(255, 24, 24, 24)),
                            ),
                            child: socketService.users.isEmpty
                                ? Center(child: Container())
                                : ListView.builder(
                                    itemExtent: 40,
                                    itemCount: socketService.users.length,
                                    itemBuilder: (context, index) {
                                      var user = socketService.users[index];
                                      return GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            selectedUser = user;
                                            userFileList = [];
                                          });
                                          _getUserFiles(user['_id']);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: selectedUser == user
                                                ? Colors.teal.withAlpha(
                                                    (0.7 * 255).toInt())
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                user['status'] == 'online'
                                                    ? Icons.public
                                                    : Icons.public_off,
                                                color:
                                                    user['status'] == 'online'
                                                        ? Colors.green
                                                        : Colors.red,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                user['username'], 
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Column(
                          children: [
                            Container(
                              height:
                                  MediaQuery.of(context).size.height * 0.05,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 45, 45, 45),
                                border: Border.all(
                                    color: Color.fromARGB(255, 24, 24, 24)),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                labelColor: Colors.white,
                                unselectedLabelColor:
                                    Color.fromARGB(255, 159, 159, 159),
                                indicatorColor: Colors.teal,
                                tabs: [
                                  Tab(text: "Group Chat"),
                                  Tab(text: "Private Chat"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(),
                              height: size.height * 0.26,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  Container(
                                    height: size.height * 0.26,
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 45, 45, 45),
                                      border: Border.all(
                                        color:
                                            Color.fromARGB(255, 24, 24, 24),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ListView.builder(
                                            padding: EdgeInsets.all(8),
                                            itemCount: socketService
                                                .groupMessage.length,
                                            itemBuilder: (context, index) {
                                              final message = socketService
                                                  .groupMessage[index];
                                              bool isMe = message['sender'] ==
                                                  widget.currentUser[
                                                      'username'];
                                              return Align(
                                                alignment: isMe
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                                child: MessageBubble(
                                                  username: message['sender'],
                                                  message:
                                                      message['message']!,
                                                  isMe: isMe,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  directMessagesWidget(selectedUser, socketService),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 45, 45, 45),
                                  border: Border.all(
                                    color: Color.fromARGB(255, 24, 24, 24),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                alignment: Alignment.topRight,
                                child: TextField(
                                  style: const TextStyle(color: Colors.white),
                                  controller: _messageController,
                                  autocorrect: true,
                                  enableSuggestions: true,
                                  minLines: 1,
                                  maxLines: 3,
                                  textAlign: TextAlign.left,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: InputDecoration(
                                    hintText: 'Enter a message',
                                    hintStyle: TextStyle(
                                      color: Colors.white
                                          .withAlpha((0.7 * 255).toInt()),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Column(
                              children: [
                                _button(
                                  "Send Message",
                                  () {
                                    if (_messageController.text
                                            .trim()
                                            .isEmpty ||
                                        (_tabController.index == 1 &&
                                            selectedUser == null)) {
                                      return;
                                    }
                                    if (_tabController.index == 0) {
                                      Provider.of<SocketService>(context,
                                              listen: false)
                                          .sendGroupMessage(
                                        _messageController.text.trim(),
                                      );
                                      setState(() {
                                        Provider.of<SocketService>(context,
                                                listen: false)
                                            .groupMessage
                                            .add({
                                          'sender':
                                              widget.currentUser['username'],
                                          'message':
                                              _messageController.text.trim(),
                                          'isMe': true,
                                        });
                                      });
                                      _messageController.clear();
                                    } else {
                                      Provider.of<SocketService>(context,
                                              listen: false)
                                          .sendAndAddDirectMessage(
                                        _messageController.text.trim(),
                                        widget.currentUser['username'],
                                        selectedUser['username'],
                                      );
                                      _messageController.clear();
                                    }
                                  },
                                ),
                                SizedBox(height: 10),
                                _button("    Send File    ", () {},
                                    tabIndex: _tabController.index),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text('Downloading :', style: TextStyle(color: Colors.white)),
            SizedBox(height: 5),
            if (downloadingFile != null)
              Container(
                height: 115,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 45, 45, 45),
                  border: Border.all(color: Color.fromARGB(255, 24, 24, 24)),
                ),
                child: DownloadProgressList(),
              ),
            if (downloadingFile == null) _infoContainer('', height: 115)
          ],
        ),
      ),
    );
  }

  Future<void> _fetchMessages() async {
    final String url =
        'http://${widget.serverIP}:9000/api/users/groupMessages/';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          Provider.of<SocketService>(context, listen: false).groupMessage =
              data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  Future<void> _selectFolder() async {
    String? result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      setState(() {
        selectedFolder = result;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      selectedFile = result.files.single.path!;
    }
  }

  Widget _button(String title, VoidCallback? onTap, {int? tabIndex}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 54, 54, 54),
        overlayColor: title == "    Send File    " && tabIndex == 0
            ? Colors.transparent
            : Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color.fromARGB(255, 24, 24, 24)),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: title == "    Send File    " && tabIndex == 0
              ? Color.fromARGB(255, 159, 159, 159)
              : Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget directMessagesWidget(
      dynamic selectedUser, SocketService socketService) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.26,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 45, 45, 45),
        border: Border.all(
          color: Color.fromARGB(255, 24, 24, 24),
        ),
      ),
      child: Builder(
        builder: (context) {
          if (selectedUser == null) {
            return Center(
              child: Text(
                'No user selected',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final messages =
              socketService.directMessage[selectedUser['username']];

          if (messages == null || messages.isEmpty) {
            return Center(
              child: Text(
                'No messages yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              bool isMe = message['sender'] == selectedUser['username'];

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: MessageBubble(
                  username: message['sender'] ?? '',
                  message: message['message'] ?? '',
                  isMe: isMe,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoContainer(String text, {double? height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 45, 45, 45),
        border: Border.all(color: Color.fromARGB(255, 24, 24, 24)),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 10, vertical: height == null ? 10 : 0),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(color: Color.fromARGB(255, 159, 159, 159)),
      ),
    );
  }

  void _getUsers() async {
    final url = Uri.parse('http://${widget.serverIP}:9000/api/users/users');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          Provider.of<SocketService>(context, listen: false).users =
              jsonDecode(response.body);
        });
        print(
            'Data: ${Provider.of<SocketService>(context, listen: false).users}');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception is : $e');
    }
  }

  void _getUserFiles(String userId) async {
    final url =
        Uri.parse('http://${widget.serverIP}:9000/api/users/files/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          userFileList = data.map((e) => e as Map<String, dynamic>).toList();
          // print('Data: $userFileList');
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception is this : $e');
    }
  }

  void showAnimatedSettingsDialog(BuildContext context, Widget dialogWidget) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Settings",
      pageBuilder: (context, animation, secondaryAnimation) {
        return dialogWidget;
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
    );
  }
}
