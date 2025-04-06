import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final TextEditingController _shareFolderPath = TextEditingController();

  final TextEditingController _receiveFolderPath = TextEditingController();

  final TextEditingController _serverIP = TextEditingController();

  final TextEditingController _userName = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 54, 54, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        width: 750,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 35,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 32, 32, 32),
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(5), topLeft: Radius.circular(5)),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: const Text(
                      "Settings",
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
                      weight: 9,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            buildTextField("Share Folder Path", true, _shareFolderPath),
            buildTextField("Downloads Folder Path", true, _receiveFolderPath),
            buildTextField("Username", false, _userName),
            buildTextField("Server IP", false, _serverIP),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 35,
                  width: 90,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 54, 54, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 35,
                  width: 90,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 54, 54, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text("Apply",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 25),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
      String label, bool isSelectFolder, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 35,
              child: TextFormField(
                controller: controller,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  // isDense: true,
                  filled: true,
                  fillColor: const Color.fromARGB(255, 45, 45, 45),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
          if (isSelectFolder) ...[
            const SizedBox(width: 10),
            SizedBox(
              height: 35,
              width: 90,
              child: ElevatedButton(
                onPressed: () {
                  TextEditingController controller =
                      label == "Share Folder Path"
                          ? _shareFolderPath
                          : _receiveFolderPath;
                  _selectFolder(controller);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 54, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text("Select",
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectFolder(TextEditingController controller) async {
    String? selectedFolder = await FilePicker.platform.getDirectoryPath();

    if (selectedFolder != null) {
      setState(() {
        controller.text = selectedFolder;
      });
    } 
  }
}
