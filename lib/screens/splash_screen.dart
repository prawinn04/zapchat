import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const SplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await _animationController.forward();
    
    // Wait a bit more to show the splash
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Complete initialization
    widget.onInitializationComplete();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive sizing based on screen dimensions
    final logoSize = screenWidth * 0.3; // 30% of screen width
    final maxLogoSize = screenHeight * 0.25; // Max 25% of screen height
    final finalLogoSize = logoSize > maxLogoSize ? maxLogoSize : logoSize;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo Image
                    Container(
                      width: finalLogoSize,
                      height: finalLogoSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/favbgss.png',
                          width: finalLogoSize * 0.8, // 80% of container size
                          height: finalLogoSize * 0.8,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to icon if image not found
                            return Icon(
                              Icons.chat_bubble_outline,
                              size: finalLogoSize * 0.5,
                              color: theme.colorScheme.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.04), // 4% of screen height
                    
                    // App Name
                    Text(
                      'ZapChat',
                      style: GoogleFonts.inter(
                        fontSize: screenWidth * 0.08, // 8% of screen width
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.01), // 1% of screen height
                    
                    // Tagline
                    Text(
                      'AI-Powered Conversations',
                      style: GoogleFonts.inter(
                        fontSize: screenWidth * 0.04, // 4% of screen width
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.06), // 6% of screen height
                    
                    // Loading Indicator
                    SizedBox(
                      width: screenWidth * 0.1, // 10% of screen width
                      height: screenWidth * 0.1,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}