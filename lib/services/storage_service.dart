import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageService {
  Future<String> saveImage(XFile imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    // We might want a 'pending' folder for undeveloped photos
    final String pendingDir = '${directory.path}/pending_development';

    await Directory(pendingDir).create(recursive: true);

    // Create a masked filename
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String filename = 'temp_img_$timestamp.dat'; 
    final String filePath = path.join(pendingDir, filename);

    // Move the file
    await File(imageFile.path).copy(filePath);
    return filePath;
  }

  Future<void> developPhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final String pendingDir = '${directory.path}/pending_development';
    final String developedDir = '${directory.path}/developed_photos';

    await Directory(developedDir).create(recursive: true);
    final pendingDirObj = Directory(pendingDir);

    if (await pendingDirObj.exists()) {
      final List<FileSystemEntity> files = pendingDirObj.listSync();
      for (final file in files) {
        if (file is File) {
          final filename = path.basename(file.path);
          final newPath = path.join(developedDir, filename);
          await file.copy(newPath);
          await file.delete();
        }
      }
    }
  }

  Future<List<File>> getDevelopedPhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final String developedDir = '${directory.path}/developed_photos';
    final developedDirObj = Directory(developedDir);

    if (await developedDirObj.exists()) {
      final List<FileSystemEntity> entities = developedDirObj.listSync();
      return entities.whereType<File>().toList();
    }
    return [];
  }
}
