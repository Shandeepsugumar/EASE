import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class AirPollutionGame extends StatefulWidget {
  final VoidCallback? onComplete;
  const AirPollutionGame({this.onComplete});

  @override
  _AirPollutionGameState createState() => _AirPollutionGameState();
}

class _AirPollutionGameState extends State<AirPollutionGame>
    with TickerProviderStateMixin {
  late AnimationController _smokeController;
  late AnimationController _treeController;
  List<PollutionSource> pollutionSources = [];
  List<Tree> trees = [];
  int airQuality = 50; // 0-100 scale
  int treesPlanted = 0;
  int pollutionCleaned = 0;
  bool gameCompleted = false;
  Timer? pollutionTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generatePollutionSources();
    _startPollutionTimer();
  }

  void _initializeAnimations() {
    _smokeController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _treeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _generatePollutionSources() {
    final random = math.Random();
    for (int i = 0; i < 6; i++) {
      pollutionSources.add(PollutionSource(
        id: i,
        x: random.nextDouble() * 300 + 50,
        y: random.nextDouble() * 200 + 200,
        type: PollutionType.values[random.nextInt(PollutionType.values.length)],
        isActive: true,
      ));
    }
  }

  void _startPollutionTimer() {
    pollutionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        // Decrease air quality from active pollution sources
        int activeSources = pollutionSources.where((s) => s.isActive).length;
        airQuality = math.max(0, airQuality - activeSources);
        
        // Increase air quality from trees
        airQuality = math.min(100, airQuality + treesPlanted);
      });

      if (airQuality >= 80 && pollutionCleaned >= 4) {
        _completeGame();
        timer.cancel();
      }
    });
  }

  void _cleanPollution(int sourceId) {
    setState(() {
      final source = pollutionSources.firstWhere((s) => s.id == sourceId);
      if (source.isActive) {
        source.isActive = false;
        pollutionCleaned++;
        airQuality += 15;
      }
    });
  }

  void _plantTree(double x, double y) {
    if (trees.length < 8) {
      setState(() {
        trees.add(Tree(
          id: trees.length,
          x: x,
          y: y,
          size: 1,
        ));
        treesPlanted++;
        airQuality += 10;
      });
      
      _treeController.forward().then((_) => _treeController.reset());
    }
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
    });
    if (widget.onComplete != null) widget.onComplete!();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("🌬️ Air Guardian!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Amazing! You cleaned the air!", style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("Air Quality: $airQuality% 🌿", style: TextStyle(color: Colors.black)),
            Text("Trees Planted: $treesPlanted 🌳", style: TextStyle(color: Colors.black)),
            Text("You're helping everyone breathe cleaner air! 💨", style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Continue Adventure"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _smokeController.dispose();
    _treeController.dispose();
    pollutionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getBackgroundColors(),
          ),
        ),
        child: Stack(
          children: [
            // City background
            _buildCityBackground(),
            
            // Pollution sources with smoke
            ...pollutionSources.map((source) => Positioned(
              left: source.x,
              top: source.y,
              child: GestureDetector(
                onTap: () => _cleanPollution(source.id),
                child: _buildPollutionSource(source),
              ),
            )),
            
            // Trees
            ...trees.map((tree) => Positioned(
              left: tree.x,
              top: tree.y,
              child: _buildTree(tree),
            )),
            
            // Plantable areas
            GestureDetector(
              onTapDown: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                if (localPosition.dy > 400) {
                  _plantTree(localPosition.dx - 25, localPosition.dy - 25);
                }
              },
              child: Container(
                height: double.infinity,
                width: double.infinity,
                color: Colors.transparent,
              ),
            ),
            
            // UI
            _buildGameUI(),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  List<Color> _getBackgroundColors() {
    if (airQuality > 70) {
      return [Color(0xFF87CEEB), Color(0xFF98FB98)];
    } else if (airQuality > 40) {
      return [Color(0xFFFFE4B5), Color(0xFFFFA07A)];
    } else {
      return [Color(0xFF696969), Color(0xFFA0A0A0)];
    }
  }

  Widget _buildCityBackground() {
    return CustomPaint(
      painter: CityPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildPollutionSource(PollutionSource source) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: source.isActive ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _getPollutionEmoji(source.type),
              style: TextStyle(fontSize: 30),
            ),
          ),
        ),
        if (source.isActive)
          AnimatedBuilder(
            animation: _smokeController,
            builder: (context, child) {
              return Positioned(
                top: -20,
                left: 15,
                child: Opacity(
                  opacity: 0.7 * (1 - _smokeController.value),
                  child: Transform.translate(
                    offset: Offset(
                      math.sin(_smokeController.value * 2 * math.pi) * 10,
                      -_smokeController.value * 40,
                    ),
                    child: Text("💨", style: TextStyle(fontSize: 20)),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTree(Tree tree) {
    return AnimatedBuilder(
      animation: _treeController,
      builder: (context, child) {
        return Transform.scale(
          scale: tree.id == trees.length - 1 
              ? 0.5 + (_treeController.value * 0.5)
              : 1.0,
          child: Text(
            "🌳",
            style: TextStyle(fontSize: 40),
          ),
        );
      },
    );
  }

  Widget _buildGameUI() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "🌬️ Air Quality",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Text(
                  "$airQuality%",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getAirQualityColor(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: airQuality / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(_getAirQualityColor()),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Trees: $treesPlanted"),
                Text("Cleaned: $pollutionCleaned"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "🎯 Tap red pollution sources to clean them!\n🌳 Tap the ground to plant trees!\nImprove air quality to 80% to win!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _getAirQualityColor() {
    if (airQuality > 70) return Colors.green;
    if (airQuality > 40) return Colors.orange;
    return Colors.red;
  }

  String _getPollutionEmoji(PollutionType type) {
    switch (type) {
      case PollutionType.factory:
        return "🏭";
      case PollutionType.car:
        return "🚗";
      case PollutionType.fire:
        return "🔥";
      case PollutionType.trash:
        return "🗑️";
    }
  }
}

class CityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw buildings
    for (int i = 0; i < 8; i++) {
      paint.color = Colors.grey[600 + (i % 3) * 100]!;
      final buildingHeight = (100 + (i % 4) * 50).toDouble();
      canvas.drawRect(
        Rect.fromLTWH(
          i * (size.width / 8),
          size.height - buildingHeight - 100,
          size.width / 8,
          buildingHeight,
        ),
        paint,
      );
    }

    // Draw ground
    paint.color = Colors.brown[300]!;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 100, size.width, 100),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PollutionSource {
  final int id;
  final double x;
  final double y;
  final PollutionType type;
  bool isActive;

  PollutionSource({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.isActive,
  });
}

class Tree {
  final int id;
  final double x;
  final double y;
  final int size;

  Tree({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
  });
}

enum PollutionType { factory, car, fire, trash }