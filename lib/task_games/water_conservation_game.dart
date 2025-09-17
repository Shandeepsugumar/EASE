import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class WaterConservationGame extends StatefulWidget {
  final VoidCallback? onComplete;
  WaterConservationGame({this.onComplete});
  @override
  _WaterConservationGameState createState() => _WaterConservationGameState();
}

class _WaterConservationGameState extends State<WaterConservationGame>
    with TickerProviderStateMixin {
  late AnimationController _dropController;
  List<WaterLeak> waterLeaks = [];
  List<WaterDrop> waterDrops = [];
  int waterSaved = 0;
  int leaksFixed = 0;
  bool gameCompleted = false;
  Timer? leakTimer;
  Timer? dropTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateWaterLeaks();
    _startTimers();
  }

  void _initializeAnimations() {
    _dropController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  void _generateWaterLeaks() {
    final random = Random();
    for (int i = 0; i < 5; i++) {
      waterLeaks.add(WaterLeak(
        id: i,
        x: 50.0 + random.nextDouble() * 300,
        y: 150.0 + random.nextDouble() * 300,
        isFixed: false,
        severity: random.nextInt(3) + 1,
      ));
    }
  }

  void _startTimers() {
    // Generate water drops from leaks
    dropTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      for (var leak in waterLeaks) {
        if (!leak.isFixed) {
          setState(() {
            waterDrops.add(WaterDrop(
              id: DateTime.now().millisecondsSinceEpoch,
              x: leak.x,
              y: leak.y,
              speed: leak.severity.toDouble(),
            ));
          });
        }
      }
      
      // Remove drops that have fallen
      waterDrops.removeWhere((drop) => drop.y > 600);
    });

    // Move water drops
    leakTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        for (var drop in waterDrops) {
          drop.y += drop.speed;
        }
      });
    });
  }

  void _fixLeak(int leakId) {
    setState(() {
      final leak = waterLeaks.firstWhere((l) => l.id == leakId);
      if (!leak.isFixed) {
        leak.isFixed = true;
        leaksFixed++;
        waterSaved += leak.severity * 10;
        
        // Remove drops from this leak
        waterDrops.removeWhere((drop) => 
            (drop.x - leak.x).abs() < 20 && drop.y < leak.y + 50);
      }
    });

    if (leaksFixed >= 4) {
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
        title: Text("💧 Water Hero!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Excellent work fixing the leaks!", style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("Water Saved: ${waterSaved}L 💧", style: TextStyle(color: Colors.black)),
            Text("You're protecting our precious water! 🌍", style: TextStyle(color: Colors.black)),
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
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dropController.dispose();
    leakTimer?.cancel();
    dropTimer?.cancel();
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
              Color(0xFFE1F5FE),
              Color(0xFFB3E5FC),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Pipes background
            _buildPipesBackground(),
            
            // Water leaks
            ...waterLeaks.map((leak) => Positioned(
              left: leak.x,
              top: leak.y,
              child: GestureDetector(
                onTap: () => _fixLeak(leak.id),
                child: _buildWaterLeak(leak),
              ),
            )),
            
            // Water drops
            ...waterDrops.map((drop) => Positioned(
              left: drop.x,
              top: drop.y,
              child: _buildWaterDrop(),
            )),
            
            // UI
            _buildGameUI(),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPipesBackground() {
    return CustomPaint(
      painter: PipesPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildWaterLeak(WaterLeak leak) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: leak.isFixed 
            ? Colors.green.withOpacity(0.8)
            : Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: leak.isFixed ? Colors.green : Colors.red,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          leak.isFixed ? "🔧" : "💧",
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }

  Widget _buildWaterDrop() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text("💧", style: TextStyle(fontSize: 12)),
      ),
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
                  "💧 Water Wizard",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan[800],
                  ),
                ),
                Text("Saved: ${waterSaved}L"),
              ],
            ),
            Column(
              children: [
                Text(
                  "Fixed: $leaksFixed/4",
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
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "🎯 Tap on red leaks to fix them with your wrench!\nStop water waste and save our planet! 🌍",
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
}

class PipesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    // Draw horizontal pipes
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      paint,
    );
    
    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.6),
      paint,
    );

    // Draw vertical pipes
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      paint,
    );
    
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaterLeak {
  final int id;
  final double x;
  final double y;
  bool isFixed;
  final int severity;

  WaterLeak({
    required this.id,
    required this.x,
    required this.y,
    required this.isFixed,
    required this.severity,
  });
}

class WaterDrop {
  final int id;
  final double x;
  double y;
  final double speed;

  WaterDrop({
    required this.id,
    required this.x,
    required this.y,
    required this.speed,
  });
}