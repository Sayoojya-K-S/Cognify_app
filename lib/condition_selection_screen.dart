import 'dart:async';
import 'package:flutter/material.dart';
import 'services/accessibility_service.dart';
import 'models/accessibility_profile.dart'; // Import for type safety if needed
import 'common/voice_accessible_widget.dart';

class ConditionSelectionScreen extends StatefulWidget {
  const ConditionSelectionScreen({super.key});

  @override
  State<ConditionSelectionScreen> createState() => _ConditionSelectionScreenState();
}

class DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final VoidCallback? customAction;

  DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    this.route = '',
    this.customAction,
  });
}

class _ConditionSelectionScreenState extends State<ConditionSelectionScreen> {
  // Auto-scanning state
  Timer? _scanTimer;
  int _focusedIndex = -1; // -1 means no focus (or header/start)
  bool _isScanning = false;
  
  // List of items to scan
  late List<DashboardItem> _items;

  @override
  void initState() {
    super.initState();
    _initializeItems();
    
    // Check initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleVoiceModeChange();
    });
    
    // Listen for profile changes to start/stop scanning
    AccessibilityService().profileNotifier.addListener(_handleVoiceModeChange);
  }

  void _initializeItems() {
    _items = [
      DashboardItem(
        title: "Customize Features",
        icon: Icons.accessibility_new,
        color: Colors.deepPurple,
        route: '/feature_selection',
      ),
      DashboardItem(
        title: "Learning",
        icon: Icons.school,
        color: Colors.teal,
        route: '/learning',
      ),
      DashboardItem(
        title: "Camera",
        icon: Icons.camera_alt,
        color: Colors.blue,
        route: '/camera',
      ),
      DashboardItem(
        title: "Audio",
        icon: Icons.audiotrack,
        color: Colors.orange,
        route: '/audio',
      ),
      DashboardItem(
        title: "Help Center",
        icon: Icons.help,
        color: Colors.green,
        customAction: () => _showPlaceholder("Help Center"),
      ),
      DashboardItem(
        title: "File",
        icon: Icons.folder,
        color: Colors.brown,
        route: '/file',
      ),
    ];
  }

  void _handleVoiceModeChange() {
    final isVoiceEnabled = AccessibilityService().currentProfile.voiceGuidanceEnabled;
    if (isVoiceEnabled && !_isScanning) {
      _startScanning();
    } else if (!isVoiceEnabled && _isScanning) {
      _stopScanning();
    }
  }

  void _startScanning() {
    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _focusedIndex = 0;
    });
    _announceCurrentItem();
    
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _focusedIndex = (_focusedIndex + 1) % _items.length;
      });
      _announceCurrentItem();
    });
  }

  void _stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
    if (mounted) {
      setState(() {
        _isScanning = false;
        _focusedIndex = -1;
      });
    }
  }

  Future<void> _announceCurrentItem() async {
    if (_focusedIndex >= 0 && _focusedIndex < _items.length) {
      await AccessibilityService().announce(_items[_focusedIndex].title);
    }
  }

  void _activateCurrentItem() {
    if (_focusedIndex >= 0 && _focusedIndex < _items.length) {
      final item = _items[_focusedIndex];
      
      // Stop scanning and speaking before navigating
      _stopScanning();
      AccessibilityService().stopSpeaking();

      if (item.customAction != null) {
        item.customAction!();
         // If custom action is just a placeholder/dialog, we might want to resume scanning?
         // For now, let's assume it might not change route.
         // If it's a dialog, we might want to stay stopped.
         // If it's just a snackbar, we might want to resume.
         // Let's resume after a short delay if it's just a placeholder customAction
         if (item.route.isEmpty) {
             Future.delayed(const Duration(seconds: 1), () {
                 if (mounted && AccessibilityService().currentProfile.voiceGuidanceEnabled) {
                     _startScanning();
                 }
             });
         }
      } else if (item.route.isNotEmpty) {
        Navigator.pushNamed(context, item.route).then((_) {
             // Restart scanning when returning
             if (mounted && AccessibilityService().currentProfile.voiceGuidanceEnabled) {
                 _startScanning();
             }
        });
      }
    }
  }
  


  @override
  void dispose() {
    AccessibilityService().profileNotifier.removeListener(_handleVoiceModeChange);
    _stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService().profileNotifier,
      builder: (context, profile, child) {
        final bool isHighContrast = profile.highContrast;
        final bool isVoiceEnabled = profile.voiceGuidanceEnabled;
        
        final Color backgroundColor = isHighContrast ? Colors.black : Colors.white;
        final Color textColor = isHighContrast ? Colors.white : Colors.black87;

        Widget content = Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text("Cognify Dashboard", style: TextStyle(color: textColor)),
            backgroundColor: isHighContrast ? Colors.black : Colors.deepPurple,
            elevation: 0,
            actions: [
               // Voice Mode Toggle
               Row(
                 children: [
                   Text("Voice Mode", style: TextStyle(color: textColor, fontSize: 12)),
                   Switch(
                     value: profile.voiceGuidanceEnabled,
                     onChanged: (val) {
                       AccessibilityService().toggleVoiceGuidance();
                       // Listener will handle scanning toggle
                     },
                     activeColor: Colors.green,
                     inactiveThumbColor: Colors.grey,
                   ),
                 ],
               ),
               // Settings Button
               VoiceAccessibleWidget(
                 label: "Settings",
                 isButton: true,
                 onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settings - Coming Soon")),
                    );
                 },
                 child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.settings, color: textColor),
                 ),
               )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display first item (Features) separately as per original layout
                if (_items.isNotEmpty)
                  _buildDashboardCard(
                    context,
                    _items[0],
                    isHighContrast,
                    isVoiceEnabled,
                    isFocused: _focusedIndex == 0,
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: _items.sublist(1).map((item) {
                      final index = _items.indexOf(item);
                      return _buildDashboardCard(
                        context,
                        item,
                        isHighContrast,
                        isVoiceEnabled,
                        isFocused: _focusedIndex == index,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );

        // If Voice Mode is ON, capture double taps anywhere
        if (isVoiceEnabled) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () {
              if (_isScanning) {
                _activateCurrentItem();
              }
            },
            child: content,
          );
        } else {
          return content;
        }
      },
    );
  }

  void _showPlaceholder(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title - Coming Soon")),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    DashboardItem item,
    bool isHighContrast,
    bool isVoiceEnabled, {
    bool isFocused = false,
  }) {
    final baseColor = isHighContrast ? Colors.grey[900]! : item.color.withOpacity(0.1);
    final iconColor = isHighContrast ? Colors.white : item.color;
    final textColor = isHighContrast ? Colors.white : Colors.black87;

    // Highlight logic
    final Color displayColor = (isVoiceEnabled && isFocused) 
        ? Colors.yellow.withOpacity(0.5) // Highlight color
        : baseColor;

    final Border? border = (isVoiceEnabled && isFocused)
        ? Border.all(color: Colors.yellow, width: 4)
        : (isHighContrast ? Border.all(color: Colors.white, width: 2) : null);

    return Semantics(
      label: item.title,
      excludeSemantics: isVoiceEnabled, // If voice enabled, we handle announcements manually
      child: GestureDetector(
        onTap: isVoiceEnabled 
            ? null // Disable single tap in voice mode (handled by scanner)
            : () { 
                if (item.customAction != null) {
                  item.customAction!();
                } else if (item.route.isNotEmpty) {
                  Navigator.pushNamed(context, item.route);
                }
              },
        child: Container(
          decoration: BoxDecoration(
            color: displayColor,
            borderRadius: BorderRadius.circular(20),
            border: border,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 48, color: iconColor),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
