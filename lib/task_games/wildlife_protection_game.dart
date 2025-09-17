import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class WildlifeProtectionGame extends StatefulWidget {
  final VoidCallback? onComplete;
  const WildlifeProtectionGame({this.onComplete});

  @override
  _WildlifeProtectionGameState createState() => _WildlifeProtectionGameState();
}

class _WildlifeProtectionGameState extends State<WildlifeProtectionGame>
    with TickerProviderStateMixin {
  late AnimationController _animalController;
  late AnimationController _dangerController;
  List<Animal> animals = [];
  List<Danger> dangers = [];
  int animalsSaved = 0;
  int dangersRemoved = 0;
  bool gameCompleted = false;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateAnimals();
    _generateDangers();
    _startGameTimer();
  }

  void _initializeAnimations() {
    _animalController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _dangerController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _generateAnimals() {
    final random = math.Random();
    final animalTypes = [
      AnimalType.elephant,
      AnimalType.tiger,
      AnimalType.panda,
      AnimalType.turtle,
      AnimalType.bird,
      AnimalType.butterfly,
    ];

    for (int i = 0; i < 6; i++) {
      animals.add(Animal(
        id: i,
        x: random.nextDouble() * 300 + 50,
        y: random.nextDouble() * 300 + 150,
        type: animalTypes[i],
        isSafe: false,
        happiness: 50,
      ));
    }
  }

  void _generateDangers() {
    final random = math.Random();
    for (int i = 0; i < 5; i++) {
      dangers.add(Danger(
        id: i,
        x: random.nextDouble() * 300 + 50,
        y: random.nextDouble() * 300 + 150,
        type: DangerType.values[random.nextInt(DangerType.values.length)],
        isRemoved: false,
      ));
    }
  }

  void _startGameTimer() {
    gameTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        // Update animal happiness based on nearby dangers
        for (var animal in animals) {
          bool nearDanger = dangers.any((danger) =>
              !danger.isRemoved &&
              _getDistance(animal.x, animal.y, danger.x, danger.y) < 80);

          if (nearDanger) {
            animal.happiness = math.max(0, animal.happiness - 10);
          } else {
            animal.happiness = math.min(100, animal.happiness + 5);
          }

          animal.isSafe = animal.happiness > 70;
        }
      });

      if (dangersRemoved >= 4 && animals.every((a) => a.isSafe)) {
        _completeGame();
        timer.cancel();
      }
    });
  }

  double _getDistance(double x1, double y1, double x2, double y2) {
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }

  void _removeDanger(int dangerId) {
    setState(() {
      final danger = dangers.firstWhere((d) => d.id == dangerId);
      if (!danger.isRemoved) {
        danger.isRemoved = true;
        dangersRemoved++;

        // Increase happiness of nearby animals
        for (var animal in animals) {
          if (_getDistance(animal.x, animal.y, danger.x, danger.y) < 100) {
            animal.happiness = math.min(100, animal.happiness + 20);
          }
        }
      }
    });

    _dangerController.forward().then((_) => _dangerController.reset());
  }

  void _feedAnimal(int animalId) {
    setState(() {
      final animal = animals.firstWhere((a) => a.id == animalId);
      animal.happiness = math.min(100, animal.happiness + 15);
      if (animal.happiness > 70 && !animal.isSafe) {
        animal.isSafe = true;
        animalsSaved++;
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
        title: Text("🦁 Wildlife Hero!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Fantastic! You protected all the animals!",
                style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("Animals Saved: ${animals.length} 🐾",
                style: TextStyle(color: Colors.black)),
            Text("Dangers Removed: $dangersRemoved 🛡️",
                style: TextStyle(color: Colors.black)),
            Text("You're a true guardian of nature! 🌿",
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
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animalController.dispose();
    _dangerController.dispose();
    gameTimer?.cancel();
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
            colors: [
              Color(0xFF87CEEB),
              Color(0xFF98FB98),
              Color(0xFF228B22),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Forest background
            _buildForestBackground(),

            // Animals
            ...animals.map((animal) => AnimatedBuilder(
                  animation: _animalController,
                  builder: (context, child) {
                    return Positioned(
                      left: animal.x +
                          math.sin(_animalController.value * 2 * math.pi +
                                  animal.id) *
                              15,
                      top: animal.y +
                          math.cos(_animalController.value * 2 * math.pi +
                                  animal.id) *
                              8,
                      child: GestureDetector(
                        onTap: () => _feedAnimal(animal.id),
                        child: _buildAnimal(animal),
                      ),
                    );
                  },
                )),

            // Dangers
            ...dangers.where((d) => !d.isRemoved).map((danger) => Positioned(
                  left: danger.x,
                  top: danger.y,
                  child: GestureDetector(
                    onTap: () => _removeDanger(danger.id),
                    child: _buildDanger(danger),
                  ),
                )),

            // UI
            _buildGameUI(),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildForestBackground() {
    return CustomPaint(
      painter: ForestPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildAnimal(Animal animal) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: animal.isSafe
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              _getAnimalEmoji(animal.type),
              style: TextStyle(fontSize: 35),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: _getHappinessColor(animal.happiness),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDanger(Danger danger) {
    return AnimatedBuilder(
      animation: _dangerController,
      builder: (context, child) {
        return Transform.scale(
          scale: danger.id == dangersRemoved - 1
              ? 1.0 - _dangerController.value
              : 1.0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Center(
              child: Text(
                _getDangerEmoji(danger.type),
                style: TextStyle(fontSize: 25),
              ),
            ),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🦁 Wildlife Guardian",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
                Text(
                    "Safe Animals: ${animals.where((a) => a.isSafe).length}/${animals.length}"),
              ],
            ),
            Column(
              children: [
                Text(
                  "Dangers: $dangersRemoved/4",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
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
          color: Colors.brown.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "🎯 Tap red dangers to remove them!\n🍃 Tap animals to feed and make them happy!\nProtect all wildlife to win! 🐾",
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

  Color _getHappinessColor(int happiness) {
    if (happiness > 70) return Colors.green;
    if (happiness > 40) return Colors.orange;
    return Colors.red;
  }

  String _getAnimalEmoji(AnimalType type) {
    switch (type) {
      case AnimalType.elephant:
        return "🐘";
      case AnimalType.tiger:
        return "🐅";
      case AnimalType.panda:
        return "🐼";
      case AnimalType.turtle:
        return "🐢";
      case AnimalType.bird:
        return "🦅";
      case AnimalType.butterfly:
        return "🦋";
    }
  }

  String _getDangerEmoji(DangerType type) {
    switch (type) {
      case DangerType.trap:
        return "🪤";
      case DangerType.pollution:
        return "☠️";
      case DangerType.fire:
        return "🔥";
      case DangerType.hunter:
        return "🎯";
    }
  }
}

class ForestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw trees in background
    for (int i = 0; i < 12; i++) {
      paint.color = Colors.green[400 + (i % 3) * 100]!;
      final treeX = (i * size.width / 12) + (i % 2) * 20;
      final treeY = size.height * 0.7 + (i % 3) * 30;

      // Tree trunk
      paint.color = Colors.brown[600]!;
      canvas.drawRect(
        Rect.fromLTWH(treeX, treeY, 15, 40),
        paint,
      );

      // Tree crown
      paint.color = Colors.green[600]!;
      canvas.drawCircle(
        Offset(treeX + 7.5, treeY - 10),
        25,
        paint,
      );
    }

    // Draw grass
    paint.color = Colors.green[300]!;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Animal {
  final int id;
  final double x;
  final double y;
  final AnimalType type;
  bool isSafe;
  int happiness;

  Animal({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.isSafe,
    required this.happiness,
  });
}

class Danger {
  final int id;
  final double x;
  final double y;
  final DangerType type;
  bool isRemoved;

  Danger({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.isRemoved,
  });
}

enum AnimalType { elephant, tiger, panda, turtle, bird, butterfly }

enum DangerType { trap, pollution, fire, hunter }
