import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class ClimateChangeGame extends StatefulWidget {
  final VoidCallback? onComplete;
  const ClimateChangeGame({this.onComplete});

  @override
  _ClimateChangeGameState createState() => _ClimateChangeGameState();
}

class _ClimateChangeGameState extends State<ClimateChangeGame>
    with TickerProviderStateMixin {
  late AnimationController _earthController;
  late AnimationController _temperatureController;
  double globalTemperature = 25.0; // Celsius
  int carbonReduced = 0;
  int renewableEnergy = 0;
  int icebergsSaved = 0;
  List<ClimateAction> actions = [];
  bool gameCompleted = false;
  Timer? climateTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateClimateActions();
    _startClimateTimer();
  }

  void _initializeAnimations() {
    _earthController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _temperatureController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _generateClimateActions() {
    final random = math.Random();
    final actionTypes = [
      ActionType.solarPanel,
      ActionType.windTurbine,
      ActionType.electricCar,
      ActionType.recycling,
      ActionType.treePlanting,
      ActionType.ledBulb,
    ];

    for (int i = 0; i < 8; i++) {
      actions.add(ClimateAction(
        id: i,
        x: 50.0 + (i % 4) * 80,
        y: 300.0 + (i ~/ 4) * 100,
        type: actionTypes[random.nextInt(actionTypes.length)],
        isCompleted: false,
        impact: random.nextInt(3) + 1,
      ));
    }
  }

  void _startClimateTimer() {
    climateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        // Increase temperature if no actions taken
        if (carbonReduced < 5) {
          globalTemperature += 0.1;
        } else {
          globalTemperature = math.max(20.0, globalTemperature - 0.2);
        }
      });

      if (carbonReduced >= 6 && globalTemperature <= 22.0) {
        _completeGame();
        timer.cancel();
      }
    });
  }

  void _performAction(int actionId) {
    setState(() {
      final action = actions.firstWhere((a) => a.id == actionId);
      if (!action.isCompleted) {
        action.isCompleted = true;
        carbonReduced += action.impact;

        switch (action.type) {
          case ActionType.solarPanel:
          case ActionType.windTurbine:
            renewableEnergy += action.impact;
            break;
          case ActionType.treePlanting:
            icebergsSaved += action.impact;
            break;
          default:
            break;
        }

        globalTemperature =
            math.max(20.0, globalTemperature - (action.impact * 0.5));
      }
    });

    _temperatureController
        .forward()
        .then((_) => _temperatureController.reset());
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
        title: Text("🌍 Climate Hero!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Outstanding! You helped fight climate change!",
                style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("Temperature: ${globalTemperature.toStringAsFixed(1)}°C 🌡️",
                style: TextStyle(color: Colors.black)),
            Text("Carbon Reduced: $carbonReduced tons 🌿",
                style: TextStyle(color: Colors.black)),
            Text("You're saving our planet's future! 🌍",
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
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _earthController.dispose();
    _temperatureController.dispose();
    climateTimer?.cancel();
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
            // Earth in center
            Center(
              child: AnimatedBuilder(
                animation: _earthController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _earthController.value * 2 * math.pi,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.blue[400]!,
                            Colors.green[400]!,
                            Colors.blue[600]!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text("🌍", style: TextStyle(fontSize: 60)),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Climate actions
            ...actions.map((action) => Positioned(
                  left: action.x,
                  top: action.y,
                  child: GestureDetector(
                    onTap: () => _performAction(action.id),
                    child: _buildClimateAction(action),
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

  List<Color> _getBackgroundColors() {
    if (globalTemperature <= 22) {
      return [Color(0xFF87CEEB), Color(0xFF98FB98)];
    } else if (globalTemperature <= 25) {
      return [Color(0xFFFFE4B5), Color(0xFFFFA07A)];
    } else {
      return [Color(0xFFFF6B6B), Color(0xFFFF8E53)];
    }
  }

  Widget _buildClimateAction(ClimateAction action) {
    return AnimatedBuilder(
      animation: _temperatureController,
      builder: (context, child) {
        return Transform.scale(
          scale: action.isCompleted
              ? 1.0 + (_temperatureController.value * 0.2)
              : 1.0,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: action.isCompleted
                  ? Colors.green.withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: action.isCompleted ? Colors.green : Colors.grey,
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
            child: Center(
              child: Text(
                _getActionEmoji(action.type),
                style: TextStyle(fontSize: 30),
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "🌡️ Global Temperature",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                ),
                Text(
                  "${globalTemperature.toStringAsFixed(1)}°C",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getTemperatureColor(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Carbon Reduced: $carbonReduced tons"),
                Text(
                    "Actions: ${actions.where((a) => a.isCompleted).length}/${actions.length}"),
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
          color: Colors.indigo.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "🎯 Tap climate actions to reduce global warming!\n🌱 Lower temperature to 22°C to save the planet!\nEvery action counts! 🌍",
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

  Color _getTemperatureColor() {
    if (globalTemperature <= 22) return Colors.green;
    if (globalTemperature <= 25) return Colors.orange;
    return Colors.red;
  }

  String _getActionEmoji(ActionType type) {
    switch (type) {
      case ActionType.solarPanel:
        return "☀️";
      case ActionType.windTurbine:
        return "💨";
      case ActionType.electricCar:
        return "🚗";
      case ActionType.recycling:
        return "♻️";
      case ActionType.treePlanting:
        return "🌳";
      case ActionType.ledBulb:
        return "💡";
    }
  }
}

class ClimateAction {
  final int id;
  final double x;
  final double y;
  final ActionType type;
  bool isCompleted;
  final int impact;

  ClimateAction({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.isCompleted,
    required this.impact,
  });
}

enum ActionType {
  solarPanel,
  windTurbine,
  electricCar,
  recycling,
  treePlanting,
  ledBulb,
}
