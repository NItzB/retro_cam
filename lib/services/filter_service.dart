import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';

enum VintageFilterType {
  original,
  wetzlarMono,
  portraGlow,
  kChrome64,
  superiaTeal,
  nightCine,
  magicSquare,
}

class FilterService {
  GPUFilterConfiguration? _currentFilter;
  VintageFilterType _currentType = VintageFilterType.wetzlarMono;
  
  // Cache the generated dummy cube files on device so the C++ filter can read them via path
  final Map<VintageFilterType, String> _cubePaths = {};

  Future<void> initialize() async {
    // Copy the asset LUTs to the local file system so the native filter can read the raw file
    final dir = await getApplicationDocumentsDirectory();
    final lutsDir = Directory('${dir.path}/luts');
    if (!await lutsDir.exists()) {
      await lutsDir.create(recursive: true);
    }

    final Map<VintageFilterType, String> assetMap = {
      VintageFilterType.original: 'assets/luts/original.png',
      VintageFilterType.wetzlarMono: 'assets/luts/wetzlar_mono.png',
      VintageFilterType.portraGlow: 'assets/luts/portra_glow.png',
      VintageFilterType.kChrome64: 'assets/luts/k_chrome_64.png',
      VintageFilterType.superiaTeal: 'assets/luts/superia_teal.png',
      VintageFilterType.nightCine: 'assets/luts/night_cine.png',
      VintageFilterType.magicSquare: 'assets/luts/magic_square.png',
    };

    for (var entry in assetMap.entries) {
      final fileName = entry.value.split('/').last;
      final localFile = File('${lutsDir.path}/$fileName');
      
      // Always overwrite the local file to ensure we have the latest LUTs from assets
      try {
         final byteData = await rootBundle.load(entry.value);
         final buffer = byteData.buffer;
         await localFile.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes), flush: true);
      } catch (e) {
         print('Error copying LUT: $e');
      }
      
      _cubePaths[entry.key] = localFile.path;
    }
  }

  Future<void> setFilter(VintageFilterType type) async {
    _currentType = type;
    
    // Original means no filter
    if (type == VintageFilterType.original) {
      _currentFilter = null;
      return;
    }

    final path = _cubePaths[type];
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        final filter = GPUSquareLookupTableConfiguration();
        filter.lutImageFile = file;
        _currentFilter = filter;
      }
    }
  }

  /// Helper to get the asset path for a type
  String? _getAssetPath(VintageFilterType type) {
    switch (type) {
      case VintageFilterType.wetzlarMono: return 'assets/luts/wetzlar_mono.png';
      case VintageFilterType.portraGlow: return 'assets/luts/portra_glow.png';
      case VintageFilterType.kChrome64: return 'assets/luts/k_chrome_64.png';
      case VintageFilterType.superiaTeal: return 'assets/luts/superia_teal.png';
      case VintageFilterType.nightCine: return 'assets/luts/night_cine.png';
      case VintageFilterType.magicSquare: return 'assets/luts/magic_square.png';
      default: return null;
    }
  }

  /// Returns a specific grain intensity level based on the current filter
  double getGrainIntensity() {
    switch (_currentType) {
      case VintageFilterType.wetzlarMono:
        return 0.15; // Heavy black and white grain
      case VintageFilterType.portraGlow:
        return 0.05; // Very fine grain
      case VintageFilterType.kChrome64:
        return 0.08; // Classic fine grain
      case VintageFilterType.superiaTeal:
        return 0.12; // Modest 400iso grain
      case VintageFilterType.nightCine:
        return 0.20; // Very heavy high ISO tungsten grain
      case VintageFilterType.magicSquare:
        return 0.10; // Medium Polaroid-style grain
      default:
        return 0.05; // Default light grain
    }
  }

  /// Applies the currently selected LUT to a static image file and overwrites it.
  Future<void> applyFilterToFile(File imageFile) async {
    if (_currentType == VintageFilterType.original) return;

    final assetPath = _getAssetPath(_currentType);
    if (assetPath == null) return;

    try {
      final source = await TextureSource.fromFile(imageFile);
      final filter = SquareLookupTableShaderConfiguration();
      await filter.setLutAsset(assetPath);

      final image = await filter.export(source, source.size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        await imageFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      }
    } catch (e) {
      debugPrint('Error applying GPU filter to image: $e');
    }
  }

  GPUFilterConfiguration? get currentFilter => _currentFilter;
  VintageFilterType get currentType => _currentType;
}
