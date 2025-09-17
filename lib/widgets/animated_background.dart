import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final bool showFloatingElements;

  const AnimatedBackground({
    Key? key,
    required this.child,
    this.colors = const [
      Color(0xFF4CAF50),
      Color(0xFF81C784),
      Color(0xFFA5D6A7),
      Color(0xFFC8E6C9),
    ],
    this.showFloatingElements = true,
  }) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _floatingController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _gradientAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.colors[0].withOpacity(0.8),
                    widget.colors[1].withOpacity(0.6),
                    widget.colors[2].withOpacity(0.4),
                    widget.colors[3].withOpacity(0.2),
                  ],
                  stops: [
                    0.0,
                    0.3 + (_gradientAnimation.value * 0.2),
                    0.6 + (_gradientAnimation.value * 0.2),
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),
        
        // Floating elements
        if (widget.showFloatingElements)
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: FloatingElementsPainter(_floatingAnimation.value),
                size: Size.infinite,
              );
            },
          ),
        
        // Main content
        widget.child,
      ],
    );
  }
}

class FloatingElementsPainter extends CustomPainter {
  final double animationValue;

  FloatingElementsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw floating circles
    for (int i = 0; i < 15; i++) {
      final x = (size.width * (i / 15) + animationValue * 100) % size.width;
      final y = (size.height * ((i * 0.7) % 1) + 
                 math.sin(animationValue * 2 * math.pi + i) * 50) % size.height;
      
      paint.color = [
        Colors.green.withOpacity(0.1),
        Colors.blue.withOpacity(0.1),
        Colors.yellow.withOpacity(0.1),
        Colors.orange.withOpacity(0.1),
      ][i % 4];
      
      canvas.drawCircle(
        Offset(x, y),
        5 + (i % 3) * 3,
        paint,
      );
    }

    // Draw floating leaves
    for (int i = 0; i < 8; i++) {
      final x = (size.width * (i / 8) + animationValue * 80) % size.width;
      final y = (size.height * ((i * 0.5) % 1) + 
                 math.cos(animationValue * 2 * math.pi + i) * 30) % size.height;
      
      paint.color = Colors.green.withOpacity(0.15);
      
      // Draw leaf shape
      final path = Path();
      path.moveTo(x, y);
      path.quadraticBezierTo(x + 10, y - 5, x + 15, y);
      path.quadraticBezierTo(x + 10, y + 5, x, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PulsingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulsingWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  }) : super(key: key);

  @override
  _PulsingWidgetState createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset begin;
  final Offset end;

  const SlideInAnimation({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    this.begin = const Offset(0, 1),
    this.end = Offset.zero,
  }) : super(key: key);

  @override
  _SlideInAnimationState createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}