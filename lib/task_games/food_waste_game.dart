import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class FoodWasteGame extends StatefulWidget {
  final VoidCallback? onComplete;
  const FoodWasteGame({this.onComplete});

  @override
  _FoodWasteGameState createState() => _FoodWasteGameState();
}

class _FoodWasteGameState extends State<FoodWasteGame>
    with TickerProviderStateMixin {
  late AnimationController _plateController;
  late AnimationController _compostController;
  List<FoodItem> foodItems = [];
  List<CompostBin> compostBins = [];
  int foodSaved = 0;
  int compostMade = 0;
  int wasteReduced = 0;
  bool gameCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateFoodItems();
    _generateCompostBins();
  }

  void _initializeAnimations() {
    _plateController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _compostController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  void _generateFoodItems() {
    final random = Random();
    final foodTypes = [
      FoodType.apple,
      FoodType.bread,
      FoodType.banana,
      FoodType.carrot,
      FoodType.lettuce,
      FoodType.tomato,
      FoodType.potato,
      FoodType.orange,
    ];

    for (int i = 0; i < 8; i++) {
      foodItems.add(FoodItem(
        id: i,
        x: 50.0 + (i % 4) * 80,
        y: 200.0 + (i ~/ 4) * 100,
        type: foodTypes[i],
        freshness: random.nextInt(100) + 1,
        isUsed: false,
      ));
    }
  }

  void _generateCompostBins() {
    compostBins.add(CompostBin(
      id: 0,
      x: 50,
      y: 450,
      capacity: 0,
      maxCapacity: 5,
    ));

    compostBins.add(CompostBin(
      id: 1,
      x: 250,
      y: 450,
      capacity: 0,
      maxCapacity: 5,
    ));
  }

  void _handleFoodAction(int foodId, FoodAction action) {
    setState(() {
      final food = foodItems.firstWhere((f) => f.id == foodId);
      if (!food.isUsed) {
        food.isUsed = true;

        switch (action) {
          case FoodAction.save:
            if (food.freshness > 50) {
              foodSaved++;
              wasteReduced += 2;
            }
            break;
          case FoodAction.compost:
            if (compostBins[0].capacity < compostBins[0].maxCapacity) {
              compostBins[0].capacity++;
              compostMade++;
              wasteReduced += 1;
            } else if (compostBins[1].capacity < compostBins[1].maxCapacity) {
              compostBins[1].capacity++;
              compostMade++;
              wasteReduced += 1;
            }
            break;
        }
      }
    });

    _plateController.forward().then((_) => _plateController.reset());

    if (foodItems.every((f) => f.isUsed) && wasteReduced >= 10) {
      _completeGame();
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
        title: Text("🍽️ Food Hero!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Amazing! You reduced food waste!",
                style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("Food Saved: $foodSaved items 🥗",
                style: TextStyle(color: Colors.black)),
            Text("Compost Made: $compostMade bins 🌱",
                style: TextStyle(color: Colors.black)),
            Text("Waste Reduced: $wasteReduced points ♻️",
                style: TextStyle(color: Colors.black)),
            Text("You're fighting hunger and helping Earth! 🌍",
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _plateController.dispose();
    _compostController.dispose();
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
              Color(0xFFFFF8DC),
              Color(0xFFFFE4B5),
              Color(0xFFDEB887),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Kitchen background
            _buildKitchenBackground(),

            // Food items
            ...foodItems.where((f) => !f.isUsed).map((food) => Positioned(
                  left: food.x,
                  top: food.y,
                  child: _buildFoodItem(food),
                )),

            // Compost bins
            ...compostBins.map((bin) => Positioned(
                  left: bin.x,
                  top: bin.y,
                  child: _buildCompostBin(bin),
                )),

            // UI
            _buildGameUI(),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildKitchenBackground() {
    return CustomPaint(
      painter: KitchenPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    return AnimatedBuilder(
      animation: _plateController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_plateController.value * 0.1),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _getFreshnessColor(food.freshness),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    _getFoodEmoji(food.type),
                    style: TextStyle(fontSize: 30),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _handleFoodAction(food.id, FoodAction.save),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.favorite,
                              color: Colors.white, size: 12),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _handleFoodAction(food.id, FoodAction.compost),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.brown,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.eco, color: Colors.white, size: 12),
                        ),
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

  Widget _buildCompostBin(CompostBin bin) {
    return AnimatedBuilder(
      animation: _compostController,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.brown[600],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              // Bin body
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.brown[800],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              // Compost level
              Positioned(
                bottom: 5,
                left: 5,
                right: 5,
                height: (bin.capacity / bin.maxCapacity) * 70,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              // Lid
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.brown[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "♻️",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              // Capacity indicator
              Positioned(
                top: 25,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "${bin.capacity}/${bin.maxCapacity}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
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
                  "🍽️ Food Saver",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                Text("Saved: $foodSaved | Composted: $compostMade"),
              ],
            ),
            Column(
              children: [
                Text(
                  "Waste Reduced: $wasteReduced",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
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
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "🎯 Green button: Save fresh food! 💚\n🎯 Brown button: Compost old food! 🤎\nReduce food waste to help the planet! 🌍",
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

  Color _getFreshnessColor(int freshness) {
    if (freshness > 70) return Colors.green;
    if (freshness > 40) return Colors.orange;
    return Colors.red;
  }

  String _getFoodEmoji(FoodType type) {
    switch (type) {
      case FoodType.apple:
        return "🍎";
      case FoodType.bread:
        return "🍞";
      case FoodType.banana:
        return "🍌";
      case FoodType.carrot:
        return "🥕";
      case FoodType.lettuce:
        return "🥬";
      case FoodType.tomato:
        return "🍅";
      case FoodType.potato:
        return "🥔";
      case FoodType.orange:
        return "🍊";
    }
  }
}

class KitchenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw kitchen counter
    paint.color = Colors.brown[300]!;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      paint,
    );

    // Draw cabinets
    paint.color = Colors.brown[600]!;
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
            i * (size.width / 4), size.height * 0.1, size.width / 4 - 10, 100),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FoodItem {
  final int id;
  final double x;
  final double y;
  final FoodType type;
  final int freshness;
  bool isUsed;

  FoodItem({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.freshness,
    required this.isUsed,
  });
}

class CompostBin {
  final int id;
  final double x;
  final double y;
  int capacity;
  final int maxCapacity;

  CompostBin({
    required this.id,
    required this.x,
    required this.y,
    required this.capacity,
    required this.maxCapacity,
  });
}

enum FoodType {
  apple,
  bread,
  banana,
  carrot,
  lettuce,
  tomato,
  potato,
  orange,
}

enum FoodAction { save, compost }
