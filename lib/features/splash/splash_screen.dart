import 'package:flutter/material.dart';

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
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(height: 3, color: _kSky),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Logo + nama + subtitle — tengah layar
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo penuh, tanpa lingkaran / background (PNG transparan)
                          Image.asset(
                            'assets/images/logo.png',
                            height: 210,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.shield_rounded,
                              size: 110,
                              color: Color(0xFFA2CFFE),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Nama instansi di bawah logo
                          const Text(
                            'POLRESTABES PALEMBANG',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFA2CFFE),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                          // Pemisah antara nama instansi dan nama aplikasi
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
                          const Text(
                            'AMPERA PBM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                          // Keterangan aplikasi, rapat ke nama aplikasi
                          const SizedBox(height: 4),
                          const Text(
                            'Polisi Bersama Masyarakat',
                            style: TextStyle(
                              color: Color(0xFFA2CFFE),
                              fontSize: 12,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Loading + sponsorship — bawah layar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _kSky.withValues(alpha: 0.8)),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Didukung oleh :',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Image.asset(
                          'assets/images/banksumselbabel.png',
                          height: 40,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ],
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
