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
    final String filename = 'temp_img_$timestamp.jpg'; 
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
  Future<List<File>> getPendingPhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<File> photos = [];
    final String pendingDir = '${directory.path}/pending_development';
    final pendingDirObj = Directory(pendingDir);

    if (!await pendingDirObj.exists()) {
      return [];
    }

    await for (var entity in pendingDirObj.list()) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        if (entity.path.split('/').last.startsWith('temp_img_')) {
          photos.add(entity);
        }
      }
    }

    // Sort chronologically (oldest first as they were taken)
    photos.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    return photos;
  }

  Future<List<File>> getDevelopedPhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<File> photos = [];

    final String developedDir = '${directory.path}/developed_photos';
    final developedDirObj = Directory(developedDir);

    if (!await developedDirObj.exists()) {
      return [];
    }

    // Auto-migrate any old .dat files from previous app versions
    await for (var entity in developedDirObj.list()) {
      if (entity is File && entity.path.endsWith('.dat')) {
        if (entity.path.split('/').last.startsWith('temp_img_')) {
          final newPath = entity.path.replaceAll('.dat', '.jpg');
          final renamed = await entity.rename(newPath);
          photos.add(renamed);
        }
      } else if (entity is File && entity.path.endsWith('.jpg')) {
        // Look for all developed '.jpg' files
        if (entity.path.split('/').last.startsWith('temp_img_')) {
          photos.add(entity);
        }
      }
    }

    // Sort newest first
    photos.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return photos;
  }
}
