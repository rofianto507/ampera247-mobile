import 'package:flutter/material.dart';

// Palette selaras login & dashboard
const _kBlue0 = Color(0xFF010D1E);
const _kBlue1 = Color(0xFF082244);
const _kBlue2 = Color(0xFF0B3C82);
const _kSky  = Color(0xFFE8A800);

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBlue0, _kBlue1, _kBlue2],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Gold accent line top
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(height: 3, color: _kSky),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo circle
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: _kSky, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 32,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.shield_rounded,
                          size: 56,
                          color: Color(0xFF1A56A0),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Brand name
                  const Text(
                    'AMPERA247',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Gold divider
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 1,
                          color: _kSky.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: _kSky, size: 10),
                      const SizedBox(width: 8),
                      Container(width: 40, height: 1,
                          color: _kSky.withValues(alpha: 0.5)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'AMPERA247',
                    style: TextStyle(
                      color: Color(0xFFA2CFFE),
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Loading indicator
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _kSky.withValues(alpha: 0.8)),
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
