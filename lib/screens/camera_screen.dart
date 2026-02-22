import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/camera_service.dart';
import '../services/film_service.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import 'package:volume_controller/volume_controller.dart';
import '../widgets/viewfinder.dart';
import '../widgets/shutter_button.dart';
import '../widgets/winding_lever.dart';
import '../widgets/film_counter.dart';
import '../widgets/film_frame.dart';
import '../widgets/physical_gallery_button.dart';
import '../widgets/physical_filter_button.dart';
import '../widgets/gpu_camera_preview.dart';
import '../widgets/grain_overlay.dart';
import '../services/filter_service.dart';
import 'gallery_screen.dart';
import 'info_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final FilmService _filmService = FilmService();
  final StorageService _storageService = StorageService();

  final SoundService _soundService = SoundService();
  VolumeController _volumeController = VolumeController();

  bool _isCameraInitialized = false;
  bool _hasInitError = false;
  int _filmCount = 24;
  bool _isWound = false;
  bool _isDeveloping = false;
  DateTime? _developmentCompleteTime;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  Future<List<File>>? _pendingPhotosFuture;

  final FilterService _filterService = FilterService();
  VintageFilterType _currentFilterType = VintageFilterType.wetzlarMono;

  @override
  void initState() {
    super.initState();
    _initialize();
    _setupVolumeListener();
    _soundService.initialize();
  }

  void _setupVolumeListener() {
    // Listen to volume button press
    _volumeController.listener((volume) {
      if (_isCameraInitialized && _isWound && !_isDeveloping && _filmCount > 0) {
        _takePhoto();
      }
    });
  }

  Future<void> _initialize() async {
    await _cameraService.initialize();
    await _filterService.setFilter(_currentFilterType);
    final count = await _filmService.getFilmCount();
    
    // Check development status
    if (count <= 0) {
      final isComplete = await _filmService.isDevelopmentComplete();
      if (!isComplete) {
        final completeTime = await _filmService.getDevelopmentCompletionTime();
        if (completeTime != null) {
          setState(() {
            _isDeveloping = true;
            _developmentCompleteTime = completeTime;
            _pendingPhotosFuture = _storageService.getPendingPhotos();
            _startCountdown();
          });
        }
      } else {
         // Ready to view
         _isDeveloping = false;
      }
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
        _filmCount = count;
        if (!Platform.isMacOS) {
          if (_cameraService.controller == null || !_cameraService.controller!.value.isInitialized) {
            _hasInitError = true;
          }
        }
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_developmentCompleteTime == null) return;
      
      final now = DateTime.now();
      if (now.isAfter(_developmentCompleteTime!)) {
        timer.cancel();
        setState(() {
          _isDeveloping = false;
        });
      } else {
        setState(() {
          _timeRemaining = _developmentCompleteTime!.difference(now);
        });
      }
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _soundService.dispose();
    _volumeController.removeListener();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onWindComplete() {
    _soundService.playWindSound();
    setState(() {
      _isWound = true;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white24, width: 2),
          ),
          title: const Text(
            'SELECT FILM STOCK',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Courier',
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: VintageFilterType.values
                .where((type) => type != VintageFilterType.original)
                .map((type) {
                final isSelected = _currentFilterType == type;
                String title = 'ORIGINAL';
                String subtitle = 'No filter applied';

                switch (type) {
                  case VintageFilterType.wetzlarMono:
                    title = 'WETZLAR MONO (1954)';
                    subtitle = 'Timeless German high-contrast black and white.';
                    break;
                  case VintageFilterType.portraGlow:
                    title = 'PORTRA GLOW (1998)';
                    subtitle = 'Natural skin tones and iconic American warmth.';
                    break;
                  case VintageFilterType.kChrome64:
                    title = 'K-CHROME 64 (1980)';
                    subtitle = 'Classic vivid colors of vintage travel magazines.';
                    break;
                  case VintageFilterType.superiaTeal:
                    title = 'SUPERIA TEAL (1998)';
                    subtitle = 'Tokyo-inspired cool tones and urban grit.';
                    break;
                  case VintageFilterType.nightCine:
                    title = 'NIGHT CINE (2012)';
                    subtitle = 'Cinematic night look with cool teal shadows.';
                    break;
                  case VintageFilterType.magicSquare:
                    title = 'MAGIC SQUARE (1972)';
                    subtitle = 'Instant nostalgia in a classic square frame.';
                    break;
                  case VintageFilterType.original:
                  default:
                    title = 'ORIGINAL';
                    subtitle = 'Raw sensor data without emulation.';
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await _filterService.setFilter(type);
                      setState(() {
                        _currentFilterType = type;
                      });
                       if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange.withOpacity(0.8) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.orange : Colors.white24,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              color: isSelected ? Colors.black87 : Colors.white54,
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _takePhoto() async {
    if (!_isWound || _filmCount <= 0) return;

    await _soundService.playShutterSound(_currentFilterType);

    final file = await _cameraService.takePicture();
    if (file != null) {
      // Apply vintage film LUT if a filter is active
      final ioFile = File(file.path);
      await _filterService.applyFilterToFile(ioFile);

      await _storageService.saveImage(file);
      await _filmService.decrementFilmCount();
      
      
      HapticFeedback.mediumImpact();

      final newCount = await _filmService.getFilmCount();

      setState(() {
        _filmCount = newCount;
        _isWound = false;
      });

      if (newCount <= 0) {
        await _filmService.startDevelopmentTimer();
        final completeTime = await _filmService.getDevelopmentCompletionTime();
        setState(() {
          _isDeveloping = true;
          _developmentCompleteTime = completeTime;
          _pendingPhotosFuture = _storageService.getPendingPhotos();
          _startCountdown();
        });
      }
    }
  }

  Future<void> _openGallery() async {
    // Move photos to unlocked folder
    await _storageService.developPhotos();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GalleryScreen()),
      ).then((_) {
        if (_filmCount <= 0 && !_isDeveloping) {
          _showNewFilmDialog(); 
        }
      });
    }
  }

  void _showNewFilmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Film?'),
        content: const Text('Do you want to load a new roll of 24 exp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _filmService.resetFilm();
              setState(() {
                _filmCount = 24;
                _isWound = false;
                _isDeveloping = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_filmCount <= 0) {
      return _buildDevelopmentScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Metal Plate
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/textures/brushed_metal.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                           BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text(
                            'RETRO CAM 90',
                            style: TextStyle(
                              color: Colors.black87,
                              fontFamily: 'Courier', 
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              shadows: [Shadow(color: Colors.white, offset: Offset(0, 1), blurRadius: 0)],
                            ),
                          ),
                          Positioned(
                            left: 8,
                            child: IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.black54),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const InfoScreen()),
                                );
                              },
                              tooltip: 'How to shoot',
                            ),
                          ),
                          Positioned(
                            right: 16,
                            child: PhysicalFilterButton(onPressed: _showFilterDialog),
                          ),
                        ],
                      ),
                    ),
                    // Divider/Trim between Top Plate and Leather
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.5), offset: Offset(0, 2), blurRadius: 4),
                        ]
                      ),
                    ),
                    
                    // Main Body Area (Leather visible)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage('assets/textures/leather_texture.png'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // The filter dial was removed from here. Now entirely modal.
                            _hasInitError
                                ? const Text(
                                    'CAMERA ERROR\nCHECK PERMISSIONS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // The actual viewfinder hardware wrapper (Bezel, reflection)
                                      Viewfinder(
                                        controller: _cameraService.controller,
                                        onMacosCameraCreated: (controller) {
                                          _cameraService.setMacosController(controller);
                                          setState(() {
                                            _isCameraInitialized = true;
                                            _hasInitError = false;
                                          });
                                        },
                                      ),
                                      // The GPU Preview layer applied on top (or wrapping) the raw camera stream.
                                      // Because Viewfinder contains the complex bezel, we need to pass the filter config inside or overlay a ColorFilter here.
                                      // Actually, we can just overlay the live approximation directly here over the viewfinder bounds.
                                      if (_cameraService.controller != null && _cameraService.controller!.value.isInitialized && _filterService.currentFilter != null)
                                        IgnorePointer(
                                          child: Container(
                                            width: 176, // Match Viewfinder inner bounds approximately
                                            height: 126,
                                            color: _getFilterPreviewOverlayColor(_currentFilterType),
                                            child: GrainOverlay(
                                              opacity: _filterService.getGrainIntensity(),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),

                    // Divider/Trim between Leather and Bottom Plate
                    Container(
                      height: 2,
                       decoration: BoxDecoration(
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.5), offset: Offset(0, -2), blurRadius: 4),
                        ]
                      ),
                    ),
                    // Bottom Metal Plate
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/textures/brushed_metal.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [ // Removed extra top shadow as the divider handles depth
                          // BoxShadow(
                          //   color: Colors.black.withOpacity(0.5),
                          //   blurRadius: 10,
                          //   offset: const Offset(0, -4),
                          // ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 55, // Height to accommodate the tallest element
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left: Film Counter & Gallery Button
                                Row(
                                  children: [
                                    GestureDetector(
                                      onLongPress: () async {
                                        // Debug: Finish roll immediately
                                        await _filmService.debugSetFilmCount(0);
                                        await _filmService.startDevelopmentTimer();
                                        final completeTime = await _filmService.getDevelopmentCompletionTime();
                                        setState(() {
                                          _filmCount = 0;
                                          _isDeveloping = true;
                                          _developmentCompleteTime = completeTime;
                                          _pendingPhotosFuture = _storageService.getPendingPhotos();
                                          _startCountdown();
                                        });
                                      },
                                      child: FilmCounter(count: _filmCount),
                                    ),
                                    const SizedBox(width: 24),
                                    PhysicalGalleryButton(onPressed: _openGallery),
                                  ],
                                ),
                                
                                // Center: Shutter Button
                                ShutterButton(
                                  onPressed: _isWound && _filmCount > 0 ? _takePhoto : null,
                                  isEnabled: _isWound && _filmCount > 0,
                                ),

                                // Right: Winding Lever
                                WindingLever(
                                  onWindComplete: _onWindComplete,
                                  isWound: _isWound,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevelopmentScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isDeveloping) ...[
                  GestureDetector(
                    onLongPress: () async {
                      // Debug: Skip development timer
                      await _filmService.debugForceCompleteDevelopment();
                      setState(() {
                        _isDeveloping = false;
                      });
                      HapticFeedback.heavyImpact();
                    },
                    child: const Text('DEVELOPING PHOTOS', style: TextStyle(color: Colors.orange, fontSize: 20, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_timeRemaining.inHours}:${(_timeRemaining.inMinutes % 60).toString().padLeft(2, '0')}:${(_timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontFamily: 'Courier'),
                  ),
                  const SizedBox(height: 10),
                  const Text('Please wait...', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: FutureBuilder<List<File>>(
                      future: _pendingPhotosFuture,
                      builder: (context, pendingSnapshot) {
                        if (pendingSnapshot.connectionState == ConnectionState.waiting) {
                           return const Center(child: CircularProgressIndicator(color: Colors.orange));
                        }
                        if (!pendingSnapshot.hasData || pendingSnapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Processing...',
                              style: TextStyle(color: Colors.white54, fontFamily: 'Courier'),
                            )
                          );
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: pendingSnapshot.data!.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: FilmFrame(
                                file: pendingSnapshot.data![index],
                                dateString: '---- -- --',
                                isPending: true,
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ),
                ] else ...[
                  const Text('DEVELOPMENT COMPLETE', style: TextStyle(color: Colors.green, fontSize: 20, letterSpacing: 2)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _openGallery,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    child: const Text('OPEN GALLERY', style: TextStyle(color: Colors.black)),
                  ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getFilterPreviewOverlayColor(VintageFilterType type) {
    // This provides a live hue overlay approximation for the 60fps preview, 
    // while the real GPU LUT processes the actual image bytes upon capture.
    switch (type) {
      case VintageFilterType.original:
        return Colors.transparent;
      case VintageFilterType.wetzlarMono:
        return Colors.black.withOpacity(0.5); // Desaturated/darker look
      case VintageFilterType.portraGlow:
        return Colors.orange.withOpacity(0.15); // Warm wash
      case VintageFilterType.kChrome64:
        return Colors.red.withOpacity(0.10); // Subtle red/yellow vibe
      case VintageFilterType.superiaTeal:
        return Colors.teal.withOpacity(0.15); // Cool urban green/blue
      case VintageFilterType.nightCine:
        return Colors.blue[900]!.withOpacity(0.25); // Heavy cool shadows
      case VintageFilterType.magicSquare:
        return Colors.cyan.withOpacity(0.15); // Polaroid chemical fade
    }
  }
}
