import 'package:ease/localization/app_localizations.dart';
import 'package:ease/profile.dart';
import 'package:ease/task.dart';
import 'package:ease/wellness2.dart';
import 'package:ease/widgets/animated_background.dart';
import 'package:ease/sanitization_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wellness_page.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'widgets/app_top_bar.dart';
import 'ShowTime.dart';
import 'report.dart';

class HomePage extends StatelessWidget {
  final User user;
  HomePage({required this.user});

  // Method to show the language selection dialog.
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: _buildLanguageDialogContent(context),
        );
      },
    );
  }

  Widget _buildLanguageDialogContent(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black
            : Colors.white, // Black for dark theme, white for light theme
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l.selectLanguage,
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.greenAccent
                  : Colors.green[
                      800], // White text for dark theme, green for light theme
            ),
          ),
          const SizedBox(height: 16.0),
          Divider(
            thickness: 1,
            color: isDark
                ? Colors.grey[700]
                : Colors.grey[300], // Theme-aware divider
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(
              Icons.sort_by_alpha_sharp,
              color: isDark
                  ? Colors.greenAccent
                  : Colors
                      .green, // White icon for dark theme, green for light theme
            ),
            title: Text(
              l.english,
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : Colors
                        .black, // White text for dark theme, black for light theme
              ),
            ),
            onTap: () {
              _updateLanguage(context, "English");
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.language,
              color: isDark
                  ? Colors.greenAccent
                  : Colors
                      .green, // White icon for dark theme, green for light theme
            ),
            title: Text(
              l.tamil,
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : Colors
                        .black, // White text for dark theme, black for light theme
              ),
            ),
            onTap: () {
              _updateLanguage(context, "Tamil");
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.translate,
              color: isDark
                  ? Colors.greenAccent
                  : Colors
                      .green, // White icon for dark theme, green for light theme
            ),
            title: Text(
              l.hindi,
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : Colors
                        .black, // White text for dark theme, black for light theme
              ),
            ),
            onTap: () {
              _updateLanguage(context, "Hindi");
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Method to update the language in the 'users' collection.
  void _updateLanguage(BuildContext context, String language) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'language': language});
    // Update in-memory locale immediately for real-time switch
    try {
      // ignore: use_build_context_synchronously
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setLocaleByName(language);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppTopBar(
        leading: IconButton(
          icon: Icon(Icons.translate, color: Colors.white),
          onPressed: () => _showLanguageDialog(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text(localizations.home,
                  style: TextStyle(color: theme.textTheme.titleLarge?.color));
            }
            final userData =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};
            String language = userData['language'] ?? "English";
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, size: 28, color: Colors.white),
                const SizedBox(width: 8),
                Text(localizations.home,
                    style: TextStyle(color: theme.textTheme.titleLarge?.color)),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode, color: Colors.white),
            onPressed: () => appState.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      // Main body content.
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "No user data found!",
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
            );
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String language = userData['language'] ?? "English";
          return AnimatedBackground(
            colors: [
              isDark ? Colors.green.shade900 : Colors.green.shade100,
              isDark ? Colors.blueGrey.shade900 : Colors.blue.shade50,
              isDark ? Colors.yellow.shade900 : Colors.yellow.shade50,
              isDark ? Colors.black : Colors.white,
            ],
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: theme.scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 24),
                        child: Column(
                          children: [
                            PulsingWidget(
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: theme.scaffoldBackgroundColor,
                                backgroundImage:
                                    AssetImage('lib/assets/earth.jpg'),
                                onBackgroundImageError: (_, __) => Icon(
                                  Icons.image,
                                  size: 50,
                                  color: theme.iconTheme.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations.savingEarth,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color:
                                    isDark ? Colors.greenAccent : Colors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localizations.subtext,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isDark ? Colors.greenAccent : Colors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.scaffoldBackgroundColor,
                              Colors.transparent
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        padding:
                            const EdgeInsets.only(top: 24, left: 16, right: 16),
                        child: Column(
                          children: [
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.75,
                              children: [
                                SlideInAnimation(
                                  delay: Duration(milliseconds: 200),
                                  child: _buildCardWithBackground(
                                    context,
                                    _buildFeatureCard(
                                      context,
                                      Icons.eco,
                                      "recycle",
                                      localizations.recycleTitle,
                                      localizations.recycleSubtitle,
                                      isDark
                                          ? Colors.green[900]!
                                          : Colors.green[100]!,
                                      isDark
                                          ? Colors.greenAccent
                                          : Colors.green[800]!,
                                      language,
                                    ),
                                  ),
                                ),
                                SlideInAnimation(
                                  delay: Duration(milliseconds: 400),
                                  child: _buildCardWithBackground(
                                    context,
                                    _buildFeatureCard(
                                      context,
                                      Icons.track_changes,
                                      "daily",
                                      localizations.dailyChallengeTitle,
                                      localizations.dailyChallengeSubtitle,
                                      isDark
                                          ? Colors.blueGrey[900]!
                                          : Colors.blue[100]!,
                                      isDark
                                          ? Colors.blueAccent
                                          : Colors.blue[800]!,
                                      language,
                                    ),
                                  ),
                                ),
                                SlideInAnimation(
                                  delay: Duration(milliseconds: 600),
                                  child: _buildCardWithBackground(
                                    context,
                                    _buildFeatureCard(
                                      context,
                                      Icons.track_changes,
                                      "wellness",
                                      localizations.wellnessTitle,
                                      localizations.wellnessSubtitle,
                                      isDark
                                          ? Colors.green[900]!
                                          : Colors.green[100]!,
                                      isDark
                                          ? Colors.blueAccent
                                          : Colors.blue[800]!,
                                      language,
                                    ),
                                  ),
                                ),
                                SlideInAnimation(
                                  delay: Duration(milliseconds: 800),
                                  child: _buildCardWithBackground(
                                    context,
                                    _buildFeatureCard(
                                      context,
                                      Icons.cleaning_services,
                                      "sanitization",
                                      "Sanitization System",
                                      "Clean & Sanitize",
                                      isDark
                                          ? Colors.purple[900]!
                                          : Colors.purple[100]!,
                                      isDark
                                          ? Colors.purpleAccent
                                          : Colors.purple[800]!,
                                      language,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Bottom taskbar with three evenly spaced buttons.
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: theme.bottomAppBarTheme.color ??
              (isDark ? Colors.black : Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home,
                  color: isDark ? Colors.greenAccent : Colors.green[900]),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.request_page_outlined,
                  color: isDark ? Colors.greenAccent : Colors.green[900]),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.incomplete_circle,
                  color: isDark ? Colors.greenAccent : Colors.green[900]),
              onPressed: () async {
                // Get the current logged in user's id.
                final String currentUserId =
                    FirebaseAuth.instance.currentUser!.uid;

                // Query the reports collection with the filter conditions.
                final QuerySnapshot snapshot = await FirebaseFirestore.instance
                    .collection('reports')
                    .where('userId', isEqualTo: currentUserId)
                    .where('status', isEqualTo: 'Not Approved')
                    .get();

                if (snapshot.docs.isEmpty) {
                  // Display a friendly message if no pending reports are found.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.noPendingReports,
                          style: TextStyle(
                              color:
                                  theme.snackBarTheme.contentTextStyle?.color)),
                      backgroundColor: theme.snackBarTheme.backgroundColor,
                    ),
                  );
                } else {
                  // If there are pending reports, navigate to MyReportsScreen.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyReportsScreen(userId: currentUserId),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to wrap a card with its own background.
  Widget _buildCardWithBackground(BuildContext context, Widget card) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: card,
    );
  }

  // Updated feature card widget with an extra identifier parameter.
  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String cardIdentifier,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
    String language, // New parameter for language
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Choose accent icon based on identifier.
    IconData accentIcon;
    switch (cardIdentifier) {
      case "recycle":
        accentIcon = Icons.autorenew;
        break;
      case "wellness":
        accentIcon = Icons.spa;
        break;
      case "daily":
        accentIcon = Icons.fitness_center;
        break;
      case "sanitization":
        accentIcon = Icons.clean_hands;
        break;
      default:
        accentIcon = icon;
    }

    // Adjust font sizes for Tamil.
    double titleFontSize = language == "Tamil" ? 14 : 16;
    double subtitleFontSize = language == "Tamil" ? 11 : 13;

    return GestureDetector(
      onTap: () {
        if (cardIdentifier == "wellness") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WellnessPage()),
          );
        } else if (cardIdentifier == "recycle") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecyclingSearchPage()),
          );
        } else if (cardIdentifier == "daily") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskPage()),
          );
        } else if (cardIdentifier == "wellness2") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WellnessPage1()),
          );
        } else if (cardIdentifier == "sanitization") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SanitizationPage()),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Theme-aware card background
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          // Add border for dark theme
          border: isDark
              ? Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                )
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Curved accent in the top-right corner.
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    accentIcon,
                    color: iconColor.withOpacity(0.8),
                    size: 30,
                  ),
                ),
              ),
            ),
            // Card content with overflow protection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(height: 12),
                // Title with overflow protection
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                      // Theme-aware text color
                      color:
                          isDark ? theme.colorScheme.onSurface : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitle with overflow protection
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      // Theme-aware subtitle color
                      color: isDark
                          ? theme.colorScheme.onSurface.withOpacity(0.7)
                          : Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
