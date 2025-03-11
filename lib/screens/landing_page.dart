import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'auth/login_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with doodles
          CustomPaint(painter: DoodlePainter(), size: Size.infinite),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  // Logo and Title
                  Text(
                        'PROJET',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple[700],
                          letterSpacing: 2,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 800))
                      .slideY(begin: -0.2),

                  const Spacer(),

                  // Login Buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLoginButton(
                            context,
                            'Student Login',
                            isTeacher: false,
                          )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 400))
                          .slideX(begin: -0.2),

                      const SizedBox(height: 20),

                      _buildLoginButton(
                            context,
                            'Teacher Login',
                            isTeacher: true,
                          )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 600))
                          .slideX(begin: 0.2),
                    ],
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(
    BuildContext context,
    String text, {
    required bool isTeacher,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(isTeacher: isTeacher),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isTeacher ? Colors.white : Colors.deepPurple,
          foregroundColor: isTeacher ? Colors.deepPurple : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: Colors.deepPurple,
              width: isTeacher ? 2 : 0,
            ),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class DoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    // Draw soccer ball
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 20, paint);

    // Draw star
    _drawStar(canvas, Offset(size.width * 0.2, size.height * 0.3), 20, paint);

    // Draw light bulb
    _drawLightBulb(canvas, Offset(size.width * 0.7, size.height * 0.6), paint);

    // Draw music note
    _drawMusicNote(canvas, Offset(size.width * 0.15, size.height * 0.7), paint);

    // Draw ABC
    drawText(
      canvas,
      'ABC',
      Offset(size.width * 0.85, size.height * 0.4),
      paint,
    );

    // Draw rocket
    _drawRocket(canvas, Offset(size.width * 0.3, size.height * 0.5), paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = i * 4 * pi / 5;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawLightBulb(Canvas canvas, Offset position, Paint paint) {
    final bulbPath =
        Path()
          ..moveTo(position.dx, position.dy)
          ..addOval(Rect.fromCircle(center: position, radius: 15))
          ..moveTo(position.dx - 10, position.dy + 15)
          ..lineTo(position.dx + 10, position.dy + 15);
    canvas.drawPath(bulbPath, paint);
  }

  void _drawMusicNote(Canvas canvas, Offset position, Paint paint) {
    final notePath =
        Path()
          ..moveTo(position.dx, position.dy)
          ..lineTo(position.dx, position.dy - 20)
          ..addOval(
            Rect.fromCircle(
              center: Offset(position.dx - 5, position.dy),
              radius: 5,
            ),
          );
    canvas.drawPath(notePath, paint);
  }

  void _drawRocket(Canvas canvas, Offset position, Paint paint) {
    final rocketPath =
        Path()
          ..moveTo(position.dx, position.dy)
          ..lineTo(position.dx - 10, position.dy + 20)
          ..lineTo(position.dx + 10, position.dy + 20)
          ..close();
    canvas.drawPath(rocketPath, paint);
  }

  void drawText(Canvas canvas, String text, Offset position, Paint paint) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: paint.color, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
