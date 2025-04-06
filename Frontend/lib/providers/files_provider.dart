import 'package:flutter/foundation.dart';

class FileState with ChangeNotifier {
  dynamic _selectedItem;

  dynamic get selectedItem => _selectedItem;

  void updateSelectedItem(dynamic newItem) {
    _selectedItem = newItem;
    notifyListeners(); 
  }
}
   