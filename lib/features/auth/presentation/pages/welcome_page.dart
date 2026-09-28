import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

/// Redesigned Welcome Page for Pennora.
///
/// Matches the reference design aesthetic (Screen 1):
/// - Deep twilight/sunset sky gradient background
/// - Stylized Pennora lotus/petal brand mark
/// - Tagline: "Your Goals + Your Money + Our Priority"
/// - Serene sunset skyline illustration with glowing sun/moon
/// - "Smarter Money. Brighter You. ♡" script heading
/// - Pill gradient CTA button: "Get Started →"
/// - Secondary "I already have an account" login link
/// - Preserves 100% of existing authentication navigation
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          // Background Gradient (Deep Navy -> Violet -> Sunset Dusk)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF071126),
                    Color(0xFF0F1E4A),
                    Color(0xFF2E1B5B),
                    Color(0xFF6B2D77),
                    Color(0xFFB8487A),
                    Color(0xFFF99D6B),
                  ],
                  stops: [0.0, 0.22, 0.44, 0.65, 0.82, 1.0],
                ),
              ),
            ),
          ),

          // Custom Vector Sunset Landscape Artwork
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SunsetLandscapePainter(
                    glowFactor: _glowAnimation.value,
                  ),
                );
              },
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 560 : double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Brand Emblem & Title
                      _buildLotusBrandHeader(),

                      const Spacer(flex: 3),

                      // Cursive Tagline: "Smarter Money. Brighter You. ♡"
                      _buildScriptCallout(),

                      const Spacer(flex: 2),

                      // Action CTAs
                      _buildActionButtons(context),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stylized Petal/Lotus Icon & Brand Header
  Widget _buildLotusBrandHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3-Petal Lotus Mark
        SizedBox(
          width: 52,
          height: 40,
          child: CustomPaint(
            painter: _LotusPetalPainter(),
          ),
        ),
        const SizedBox(height: 10),

        // "Pennora"
        const Text(
          'Pennora',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),

        // Tagline
        Text(
          'Your Goals  +  Your Money  +  Our Priority',
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Emotional Script callout: "Smarter Money, Brighter You ♡"
  Widget _buildScriptCallout() {
    return Column(
      children: [
        Text(
          'Smarter\nMoney\nBrighter\nYou',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withAlpha(240),
            fontSize: 26,
            fontWeight: FontWeight.w600,
            height: 1.15,
            letterSpacing: 0.5,
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(
                color: Colors.purple.withAlpha(140),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '♡',
          style: TextStyle(
            color: const Color(0xFFFFB6D9).withAlpha(220),
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  /// Action Buttons: "Get Started →" and "I already have an account"
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary Gradient Pill CTA: "Get Started →"
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5A58EE),
                Color(0xFF835CF6),
                Color(0xFFA855F7),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withAlpha(120),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SignUpPage(),
                  ),
                );
              },
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Secondary Text Button: "I already have an account"
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withAlpha(220),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
              children: const [
                TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom Lotus / Petal Brand Mark Painter
class _LotusPetalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Center Petal (Soft Lilac Pink)
    final centerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE9D5FF), Color(0xFFC084FC)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final centerPath = Path()
      ..moveTo(cx, cy - 16)
      ..cubicTo(cx + 8, cy - 6, cx + 8, cy + 10, cx, cy + 14)
      ..cubicTo(cx - 8, cy + 10, cx - 8, cy - 6, cx, cy - 16);
    canvas.drawPath(centerPath, centerPaint);

    // Left Petal (Soft Violet)
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFDDD6FE), Color(0xFFA855F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final leftPath = Path()
      ..moveTo(cx - 4, cy + 12)
      ..cubicTo(cx - 16, cy + 8, cx - 18, cy - 4, cx - 12, cy - 10)
      ..cubicTo(cx - 8, cy - 4, cx - 6, cy + 6, cx - 4, cy + 12);
    canvas.drawPath(leftPath, leftPaint);

    // Right Petal (Soft Violet)
    final rightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFDDD6FE), Color(0xFFA855F7)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final rightPath = Path()
      ..moveTo(cx + 4, cy + 12)
      ..cubicTo(cx + 16, cy + 8, cx + 18, cy - 4, cx + 12, cy - 10)
      ..cubicTo(cx + 8, cy - 4, cx + 6, cy + 6, cx + 4, cy + 12);
    canvas.drawPath(rightPath, rightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Vector Sunset Landscape & Skyline Painter
class _SunsetLandscapePainter extends CustomPainter {
  final double glowFactor;
  _SunsetLandscapePainter({required this.glowFactor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glowing Evening Sun / Moon on Horizon
    final sunCenter = Offset(w * 0.72, h * 0.62);
    final sunPaint = Paint()
      ..color = const Color(0xFFFFF7ED).withAlpha((210 * glowFactor).clamp(0, 255).toInt())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * glowFactor);
    canvas.drawCircle(sunCenter, 22 * glowFactor, sunPaint);

    final sunCorePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(sunCenter, 14, sunCorePaint);

    // City Skyline Silhouette on Horizon
    final cityPaint = Paint()..color = const Color(0xFF26123D).withAlpha(160);
    final cityPath = Path();
    final baseH = h * 0.68;
    cityPath.moveTo(w * 0.55, baseH);
    cityPath.lineTo(w * 0.58, baseH - 12);
    cityPath.lineTo(w * 0.60, baseH - 12);
    cityPath.lineTo(w * 0.61, baseH - 24);
    cityPath.lineTo(w * 0.64, baseH - 24);
    cityPath.lineTo(w * 0.65, baseH - 8);
    cityPath.lineTo(w * 0.69, baseH - 18);
    cityPath.lineTo(w * 0.73, baseH - 18);
    cityPath.lineTo(w * 0.75, baseH - 32);
    cityPath.lineTo(w * 0.77, baseH - 32);
    cityPath.lineTo(w * 0.80, baseH - 14);
    cityPath.lineTo(w * 0.85, baseH - 22);
    cityPath.lineTo(w * 0.90, baseH - 22);
    cityPath.lineTo(w * 0.95, baseH - 10);
    cityPath.lineTo(w, baseH - 8);
    cityPath.lineTo(w, baseH + 30);
    cityPath.lineTo(w * 0.55, baseH + 30);
    cityPath.close();
    canvas.drawPath(cityPath, cityPaint);

    // Calming Water / Shoreline Wave Gradient
    final waterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF4C1D95).withAlpha(180),
          const Color(0xFF0F172A).withAlpha(240),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, baseH - 4, w, h - baseH + 4));

    final waterPath = Path()
      ..moveTo(0, baseH + 12)
      ..cubicTo(w * 0.3, baseH - 8, w * 0.7, baseH + 20, w, baseH + 6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // Silhouetted Person Sitting by the Edge (Reference Scene)
    final personPaint = Paint()..color = const Color(0xFF0A0F24);
    final pierPaint = Paint()..color = const Color(0xFF050816);

    // Pier ledge
    final pierPath = Path()
      ..moveTo(0, baseH + 28)
      ..cubicTo(w * 0.25, baseH + 10, w * 0.42, baseH + 20, w * 0.50, baseH + 45)
      ..lineTo(w * 0.50, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(pierPath, pierPaint);

    // Person silhouette
    final px = w * 0.28;
    final py = baseH + 18;

    // Body
    final bodyPath = Path()
      ..moveTo(px - 14, py + 26)
      ..cubicTo(px - 16, py + 6, px - 6, py - 6, px + 6, py - 4)
      ..cubicTo(px + 16, py - 2, px + 18, py + 12, px + 22, py + 28)
      ..close();
    canvas.drawPath(bodyPath, personPaint);

    // Head with hair
    canvas.drawCircle(Offset(px + 2, py - 14), 10, personPaint);
    // Ponytail / hair curve
    final hairPath = Path()
      ..moveTo(px - 4, py - 12)
      ..cubicTo(px - 14, py - 8, px - 18, py - 2, px - 16, py + 6)
      ..lineTo(px - 10, py + 2)
      ..close();
    canvas.drawPath(hairPath, personPaint);
  }

  @override
  bool shouldRepaint(covariant _SunsetLandscapePainter oldDelegate) =>
      oldDelegate.glowFactor != glowFactor;
}
