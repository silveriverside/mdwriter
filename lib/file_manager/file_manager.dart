import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'recent_files_provider.dart';

class FileResult {
  final String path;
  final String content;
  FileResult(this.path, this.content);
}

class FileManager {
  static Future<FileResult?> openFile(context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      Provider.of<RecentFilesProvider>(context, listen: false).addRecentFile(file.path);
      return FileResult(file.path, content);
    } else {
      // User canceled the picker
      return null;
    }
  }

  static Future<File> createFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.create();
    return file;
  }

  static Future<void> saveFile(String filePath, String content) async {
    final file = File(filePath);
    await file.writeAsString(content);
  }

  static Future<String> getAppDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}