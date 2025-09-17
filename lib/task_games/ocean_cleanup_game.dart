import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class OceanCleanupGame extends StatefulWidget {
  final VoidCallback? onComplete;
  OceanCleanupGame({this.onComplete});
  @override
  _OceanCleanupGameState createState() => _OceanCleanupGameState();
}

class _OceanCleanupGameState extends State<OceanCleanupGame>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fishController;
  List<TrashItem> trashItems = [];
  List<SeaCreature> seaCreatures = [];
  int score = 0;
  int trashesCleaned = 0;
  bool gameCompleted = false;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateTrashItems();
    _generateSeaCreatures();
    _startGameTimer();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fishController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  void _generateTrashItems() {
    final random = Random();
    for (int i = 0; i < 8; i++) {
      trashItems.add(TrashItem(
        id: i,
        x: random.nextDouble() * 300 + 50,
        y: random.nextDouble() * 400 + 200,
        type: TrashType.values[random.nextInt(TrashType.values.length)],
      ));
    }
  }

  void _generateSeaCreatures() {
    final random = Random();
    for (int i = 0; i < 5; i++) {
      seaCreatures.add(SeaCreature(
        id: i,
        x: random.nextDouble() * 300 + 50,
        y: random.nextDouble() * 300 + 150,
        type: CreatureType.values[random.nextInt(CreatureType.values.length)],
        isHappy: false,
      ));
    }
  }

  void _startGameTimer() {
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (trashesCleaned >= 6) {
        _completeGame();
        timer.cancel();
      }
    });
  }

  void _cleanTrash(int trashId) {
    setState(() {
      trashItems.removeWhere((item) => item.id == trashId);
      trashesCleaned++;
      score += 10;

      // Make sea creatures happier
      for (var creature in seaCreatures) {
        if (trashesCleaned >= 3) {
          creature.isHappy = true;
        }
      }
    });
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
        title: Text("🎉 Ocean Saved!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Amazing work! You cleaned $trashesCleaned pieces of trash!",
                style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("The sea creatures are happy and healthy now! 🐠🐢",
                style: TextStyle(color: Colors.black)),
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fishController.dispose();
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ocean Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF87CEEB),
                  Color(0xFF4682B4),
                  Color(0xFF191970),
                ],
              ),
            ),
          ),

          // Animated Waves
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: WavePainter(_waveController.value),
                size: Size.infinite,
              );
            },
          ),

          // Sea Creatures
          ...seaCreatures.map((creature) => AnimatedBuilder(
                animation: _fishController,
                builder: (context, child) {
                  return Positioned(
                    left: creature.x + sin(_fishController.value * 2 * pi) * 20,
                    top: creature.y + cos(_fishController.value * 2 * pi) * 10,
                    child: _buildSeaCreature(creature),
                  );
                },
              )),

          // Trash Items
          ...trashItems.map((trash) => Positioned(
                left: trash.x,
                top: trash.y,
                child: GestureDetector(
                  onTap: () => _cleanTrash(trash.id),
                  child: _buildTrashItem(trash),
                ),
              )),

          // UI Elements
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _buildGameUI(),
          ),

          // Instructions
          if (trashesCleaned == 0)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: _buildInstructions(),
            ),
        ],
      ),
    );
  }

  Widget _buildGameUI() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Score: $score",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Text(
                "Cleaned: $trashesCleaned/6",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "🌊 Ocean Cleanup",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "🎯 Tap on trash to clean the ocean!\nHelp the sea creatures by removing all the waste!",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTrashItem(TrashItem trash) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          _getTrashEmoji(trash.type),
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }

  Widget _buildSeaCreature(SeaCreature creature) {
    return Container(
      width: 50,
      height: 50,
      child: Center(
        child: Text(
          _getCreatureEmoji(creature.type, creature.isHappy),
          style: TextStyle(fontSize: 35),
        ),
      ),
    );
  }

  String _getTrashEmoji(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return "🥤";
      case TrashType.can:
        return "🥫";
      case TrashType.bag:
        return "🛍️";
      case TrashType.bottle:
        return "🍼";
    }
  }

  String _getCreatureEmoji(CreatureType type, bool isHappy) {
    switch (type) {
      case CreatureType.fish:
        return isHappy ? "🐠" : "😰";
      case CreatureType.turtle:
        return isHappy ? "🐢" : "😢";
      case CreatureType.whale:
        return isHappy ? "🐋" : "😔";
      case CreatureType.dolphin:
        return isHappy ? "🐬" : "😟";
    }
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.8);

    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.8 +
          sin((x / size.width * 4 * pi) + (animationValue * 2 * pi)) * 20;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TrashItem {
  final int id;
  final double x;
  final double y;
  final TrashType type;

  TrashItem({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
  });
}

class SeaCreature {
  final int id;
  final double x;
  final double y;
  final CreatureType type;
  bool isHappy;

  SeaCreature({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.isHappy,
  });
}

enum TrashType { plastic, can, bag, bottle }

enum CreatureType { fish, turtle, whale, dolphin }
