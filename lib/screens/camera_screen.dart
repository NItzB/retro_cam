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

  Future<void> _takePhoto() async {
    if (!_isWound || _filmCount <= 0) return;

    await _soundService.playShutterSound();

    final file = await _cameraService.takePicture();
    if (file != null) {
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
                      decoration: BoxDecoration(
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
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage('assets/textures/leather_texture.png'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
                          ),
                        ),
                        child: Center(
                          child: _hasInitError
                              ? const Text(
                                  'CAMERA ERROR\nCHECK PERMISSIONS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                                )
                              : Viewfinder(
                                  controller: _cameraService.controller,
                                  // showWindIndicator removed per user request
                                  onMacosCameraCreated: (controller) {
                                    _cameraService.setMacosController(controller);
                                    setState(() {
                                      // On macOS, we consider camera initialized when the view gives us the controller
                                      _isCameraInitialized = true;
                                      _hasInitError = false;
                                    });
                                  },
                                ),
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
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white24, width: 1),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.photo_library, color: Colors.orange, size: 22),
                                        onPressed: _openGallery,
                                        tooltip: 'Photo Library',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
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
}
