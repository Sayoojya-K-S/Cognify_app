import 'package:flutter/material.dart';
import 'services/accessibility_service.dart';
import 'models/accessibility_profile.dart'; // Import for type safety if needed

class ConditionSelectionScreen extends StatelessWidget {
  const ConditionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using ValueListenableBuilder to listen to changes (e.g. High Contrast)
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService().profileNotifier,
      builder: (context, profile, child) {
        final bool isHighContrast = profile.highContrast;
        final Color backgroundColor = isHighContrast ? Colors.black : Colors.white;
        final Color textColor = isHighContrast ? Colors.white : Colors.black87;
        final Color cardColor = isHighContrast ? Colors.grey[900]! : Colors.deepPurple[50]!;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text("Cognify Dashboard", style: TextStyle(color: textColor)),
            backgroundColor: isHighContrast ? Colors.black : Colors.deepPurple,
            elevation: 0,
            actions: [
               IconButton(
                 icon: Icon(Icons.settings, color: textColor),
                 onPressed: () {
                    // Placeholder for Settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settings - Coming Soon")),
                    );
                 },
               )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDashboardCard(
                  context,
                  "Customize Features",
                  Icons.accessibility_new,
                  Colors.deepPurple,
                  () => Navigator.pushNamed(context, '/feature_selection'),
                  isHighContrast,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDashboardCard(
                        context,
                        "Learn",
                        Icons.school,
                        Colors.blue,
                        () => _showPlaceholder(context, "Learn Module"),
                        isHighContrast,
                      ),
                      _buildDashboardCard(
                        context,
                        "Quiz",
                        Icons.quiz,
                        Colors.orange,
                        () => _showPlaceholder(context, "Quiz Module"),
                        isHighContrast,
                      ),
                      _buildDashboardCard(
                        context,
                        "Help Center",
                        Icons.help,
                        Colors.green,
                        () => _showPlaceholder(context, "Help Center"),
                        isHighContrast,
                      ),
                      _buildDashboardCard(
                        context,
                        "Start",
                        Icons.play_arrow,
                        Colors.redAccent,
                        () => Navigator.pushNamed(context, '/access'),
                        isHighContrast,
                       ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title - Coming Soon")),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isHighContrast,
  ) {
    final cardColor = isHighContrast ? Colors.grey[900] : color.withOpacity(0.1);
    final iconColor = isHighContrast ? Colors.white : color;
    final textColor = isHighContrast ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
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
    );
  }
}
