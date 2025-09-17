import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ease/task.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class TrashCollectGame extends StatefulWidget {
  @override
  _TrashCollectGameState createState() => _TrashCollectGameState();
}

class _TrashCollectGameState extends State<TrashCollectGame>
    with TickerProviderStateMixin {
  // Initial player position.
  double playerX = 100.0;
  double playerY = 400.0;
  bool _dataStored = false;
  // Use 4 waste items.
  final int totalGarbage = 4;
  List<GarbageItem> garbageItems = [];

  // List to store collected waste images (bag).
  List<String> collectedWaste = [];

  // Controller for the player's bounce animation.
  late AnimationController _playerController;
  late Animation<double> _playerScaleAnimation;

  // Timer to manage movement state.
  Timer? _movementTimer;

  // Boolean to track if the player is moving.
  bool _isMoving = false;

  // Variable to track last horizontal movement value.
  double _lastDx = 0.0;

  // List of waste image paths.
  final List<String> wasteImages = [
    "lib/assets/banana.png",
    "lib/assets/glass.png",
    "lib/assets/paper.png",
    "lib/assets/plasticbottle.png",
  ];

  @override
  void initState() {
    super.initState();
    _generateGarbageItems();
    _playerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _playerScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _playerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _playerController.dispose();
    _movementTimer?.cancel();
    for (var item in garbageItems) {
      item.controller.dispose();
    }
    super.dispose();
  }

  // Generate waste items and place them evenly along the ground.
  void _generateGarbageItems() {
    final double gameWidth = 400;
    final double groundY = 460; // Fixed y-coordinate for ground-level waste.
    double spacing = (gameWidth - 100) / (totalGarbage - 1);
    garbageItems = List.generate(totalGarbage, (index) {
      double x = 50 + index * spacing;
      double y = groundY;
      AnimationController controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      );
      // Assign one of the waste images.
      String imagePath = wasteImages[index % wasteImages.length];
      return GarbageItem(
        position: Offset(x, y),
        controller: controller,
        wasteImage: imagePath,
      );
    });
  }

  // Check for collision between player and waste.
  // When collected, add the waste image to the bag and trigger fade-out.
  void _checkGarbageCollection() {
    setState(() {
      garbageItems.removeWhere((garbage) {
        double distance = sqrt(pow(garbage.position.dx - playerX, 2) +
            pow(garbage.position.dy - playerY, 2));
        if (distance < 50) {
          collectedWaste.add(garbage.wasteImage);
          garbage.controller.forward();
          return true;
        }
        return false;
      });
    });
  }

  // Helper function for directional movement.
  void _movePlayer(double dx, double dy) {
    setState(() {
      playerX += dx;
      playerY += dy;
      if (dx != 0) {
        _lastDx = dx;
      }
      _isMoving = true;
    });

    // Cancel any existing timer and restart it.
    _movementTimer?.cancel();
    _movementTimer = Timer(Duration(milliseconds: 300), () {
      setState(() {
        _isMoving = false;
      });
    });

    _checkGarbageCollection();
    // Play bounce animation.
    _playerController.forward().then((value) => _playerController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trash Collect Game',
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, color: Colors.white, size: 30),
              SizedBox(width: 8),
              Text(
                "Green Oasis Cleanup",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
        ),
          body: Stack(
          children: [
            // Enhanced landscape background.
            Positioned.fill(
              child: CustomPaint(
                painter: EnhancedLandscapePainter(),
              ),
            ),
            // Waste items as images with fade-out animation.
            ...garbageItems.map((garbage) {
              return AnimatedBuilder(
                animation: garbage.controller,
                builder: (context, child) {
                  return Positioned(
                    left: garbage.position.dx,
                    top: garbage.position.dy,
                    child: Opacity(
                      opacity: 1.0 - garbage.controller.value,
                      child: Image.asset(
                        garbage.wasteImage,
                        width: 70, // Increased size for waste images
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            // Player widget with animated scale and position.
            AnimatedPositioned(
              duration: Duration(milliseconds: 100),
              left: playerX,
              top: playerY,
              child: ScaleTransition(
                scale: _playerScaleAnimation,
                child: Container(
                  color: Colors.transparent,
                  child: _isMoving
                      ? (_lastDx > 0
                      ? Image.asset(
                    "lib/assets/runningboy.png",
                    width: 80, // Increased size for boy image
                    height: 80,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  )
                      : Image.asset(
                    "lib/assets/runboy.png",
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ))
                      : Image.asset(
                    "lib/assets/standboy.png",
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
            // On-screen control pad for directional movement.
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Stack(
                  children: [
                    // Up button.
                    Positioned(
                      top: 0,
                      left: 40,
                      child: IconButton(
                        icon: Icon(Icons.arrow_upward, color: Colors.white),
                        onPressed: () => _movePlayer(0, -20),
                      ),
                    ),
                    // Down button.
                    Positioned(
                      bottom: 0,
                      left: 40,
                      child: IconButton(
                        icon: Icon(Icons.arrow_downward, color: Colors.white),
                        onPressed: () => _movePlayer(0, 20),
                      ),
                    ),
                    // Left button.
                    Positioned(
                      top: 40,
                      left: 0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => _movePlayer(-20, 0),
                      ),
                    ),
                    // Right button.
                    Positioned(
                      top: 40,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward, color: Colors.white),
                        onPressed: () => _movePlayer(20, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bag widget at bottom center that displays collected waste images.
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_bag, color: Colors.white),
                      SizedBox(width: 8),
                      ...collectedWaste.map((img) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Image.asset(
                          img,
                          width: 40, // Increased size for bag images
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            // When all waste is collected, display an AlertDialog showing the bag with the collected waste.
            if (collectedWaste.length == totalGarbage)
              Center(
                child: Builder(builder: (context) {
                  // Check and store data if not already done.
                  if (!_dataStored) {
                    _dataStored = true;
                    Map<String, dynamic> verifyData = {
                      'userId': FirebaseAuth.instance.currentUser!.uid,
                      'status': 'Confirmed',
                      'level': 1,
                      'points': 40,
                      'completedAt': DateTime.now(),
                    };
                    FirebaseFirestore.instance.collection('verify').add(verifyData);

                    // After 6 seconds, dismiss the dialog and navigate back.
                    Future.delayed(Duration(seconds: 6), () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => TaskPage()),
                      );
                    });
                  }
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 10,
                    titlePadding: EdgeInsets.zero,
                    title: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal, Colors.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag, size: 40, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Collected Waste",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    contentPadding: EdgeInsets.fromLTRB(16, 20, 16, 24),
                    content: Container(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: collectedWaste.map((img) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                img,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

// Enhanced custom painter for a more natural environment.
class EnhancedLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw the sky with a soft gradient.
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.lightBlue.shade300, Colors.lightBlue.shade100],
    );
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final skyPaint = Paint()..shader = skyGradient.createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Draw the sun with a radial gradient.
    final sunCenter = Offset(size.width * 0.8, size.height * 0.2);
    final sunRadius = 40.0;
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.yellow, Colors.orange],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    // Draw clouds using soft, overlapping circles.
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.2), 20, cloudPaint);
    canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.18), 25, cloudPaint);
    canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.22), 20, cloudPaint);

    canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.15), 15, cloudPaint);
    canvas.drawCircle(
        Offset(size.width * 0.63, size.height * 0.13), 20, cloudPaint);
    canvas.drawCircle(
        Offset(size.width * 0.67, size.height * 0.16), 15, cloudPaint);

    // Draw rolling mountains using a curved path with a gradient.
    final mountainGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.grey.shade400, Colors.grey.shade800],
    );
    final mountainRect = Rect.fromLTWH(
        0, size.height * 0.35, size.width, size.height * 0.45);
    final mountainPaint = Paint()..shader = mountainGradient.createShader(mountainRect);

    final mountainPath = Path();
    mountainPath.moveTo(0, size.height * 0.55);
    mountainPath.quadraticBezierTo(
        size.width * 0.2, size.height * 0.4, size.width * 0.4, size.height * 0.55);
    mountainPath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.5, size.width * 0.6, size.height * 0.55);
    mountainPath.quadraticBezierTo(
        size.width * 0.8, size.height * 0.7, size.width, size.height * 0.55);
    mountainPath.lineTo(size.width, size.height);
    mountainPath.lineTo(0, size.height);
    mountainPath.close();
    canvas.drawPath(mountainPath, mountainPaint);

    // Draw the sea with a deep gradient.
    double seaHeight = size.height * 0.25;
    final seaRect = Rect.fromLTWH(0, size.height - seaHeight, size.width, seaHeight);
    final seaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.blue.shade300, Colors.blue.shade700],
    );
    final seaPaint = Paint()..shader = seaGradient.createShader(seaRect);
    canvas.drawRect(seaRect, seaPaint);

    // Draw a textured sandy beach with a gradient.
    double sandHeight = size.height * 0.1;
    final sandRect = Rect.fromLTWH(
        0, size.height - seaHeight - sandHeight, size.width, sandHeight);
    final sandGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.yellow.shade200, Colors.yellow.shade600],
    );
    final sandPaint = Paint()..shader = sandGradient.createShader(sandRect);
    canvas.drawRect(sandRect, sandPaint);

    // Draw more detailed trees on both sides.
    _drawTree(canvas, Offset(50, size.height - seaHeight - sandHeight - 80));
    _drawTree(canvas, Offset(size.width - 100, size.height - seaHeight - sandHeight - 80));
    _drawTree(canvas, Offset(size.width - 200, size.height - seaHeight - sandHeight - 80));
  }

  void _drawTree(Canvas canvas, Offset position) {
    // Adjust the position by adding an offset to place the tree lower.
    final Offset adjustedPosition = Offset(position.dx, position.dy + 40);

    // Draw a rounded trunk with gradient.
    final trunkRect = Rect.fromLTWH(adjustedPosition.dx, adjustedPosition.dy, 20, 60);
    final trunkRRect = RRect.fromRectAndRadius(trunkRect, Radius.circular(5));
    final trunkGradient = LinearGradient(
      colors: [Colors.brown.shade800, Colors.brown.shade600],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    final trunkPaint = Paint()..shader = trunkGradient.createShader(trunkRect);
    canvas.drawRRect(trunkRRect, trunkPaint);

    // Draw the main canopy with a radial gradient.
    final canopyCenter = Offset(adjustedPosition.dx + 10, adjustedPosition.dy - 10);
    final canopyRect = Rect.fromCenter(center: canopyCenter, width: 60, height: 40);
    final canopyGradient = RadialGradient(
      colors: [Colors.green.shade700, Colors.green.shade400],
    );
    final canopyPaint = Paint()..shader = canopyGradient.createShader(canopyRect);
    canvas.drawOval(canopyRect, canopyPaint);

    // Add overlapping ovals for extra canopy depth.
    final leftCanopyRect = Rect.fromCenter(
        center: Offset(adjustedPosition.dx, adjustedPosition.dy), width: 50, height: 30);
    final leftCanopyPaint = Paint()..color = Colors.green.shade600.withOpacity(0.9);
    canvas.drawOval(leftCanopyRect, leftCanopyPaint);

    final rightCanopyRect = Rect.fromCenter(
        center: Offset(adjustedPosition.dx + 20, adjustedPosition.dy), width: 50, height: 30);
    final rightCanopyPaint = Paint()..color = Colors.green.shade600.withOpacity(0.9);
    canvas.drawOval(rightCanopyRect, rightCanopyPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Model class to hold waste (garbage) information.
class GarbageItem {
  final Offset position;
  final AnimationController controller;
  final String wasteImage;
  GarbageItem({
    required this.position,
    required this.controller,
    required this.wasteImage,
  });
}
