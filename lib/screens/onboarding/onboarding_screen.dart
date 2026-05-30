import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../../core/constants/app_colors.dart';

/// **Layar Onboarding (Selamat Datang)**
/// Ditampilkan hanya sekali saat pengguna pertama kali menginstal aplikasi.
/// Memberikan pengenalan singkat tentang fitur utama: Bounty, Guild, dan Kemudahan Pelaporan.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Temukan & Dapatkan Bounty',
      description: 'Laporkan barang hilang atau temukan barang orang lain layaknya sebuah misi. Selesaikan misi dan dapatkan Bounty (Poin)!',
      icon: Icons.monetization_on_rounded,
      colors: [AppColors.guildGold, AppColors.bounty],
    ),
    _OnboardingData(
      title: 'Bergabung dalam Guild',
      description: 'Jadilah bagian dari komunitas! Tingkatkan reputasi Guild-mu dengan terus membantu orang lain dan jadilah yang terbaik di Leaderboard.',
      icon: Icons.shield_rounded,
      colors: const [AppColors.primary, Color(0xFF4A90E2)],
    ),
    _OnboardingData(
      title: 'Aman & Terpercaya',
      description: 'Sistem Penitipan Poin memastikan setiap hadiah poin ditahan secara aman oleh sistem hingga proses pengembalian barang benar-benar selesai.',
      icon: Icons.verified_user_rounded,
      colors: const [AppColors.statusActive, Color(0xFF1B5E20)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient sesuai halaman
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pages[_currentPage].colors.map((c) => c.withValues(alpha: 0.1)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Tombol Skip
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Lewati', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),

                // Slider
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final data = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon Placeholder dengan efek Glassmorphism
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: data.colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: data.colors.first.withValues(alpha: 0.4),
                                    blurRadius: 32,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Icon(data.icon, size: 80, color: Colors.white),
                            ),
                            const SizedBox(height: 64),
                            Text(
                              data.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              data.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Indikator dan Tombol Bawah
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dots Indicator
                      Row(
                        children: List.generate(_pages.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppColors.primary : AppColors.divider,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      // Next / Finish Button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentPage == _pages.length - 1
                            ? ElevatedButton(
                                key: const ValueKey('finish'),
                                onPressed: _finishOnboarding,
                                child: const Text('Mulai Gunakan'),
                              )
                            : FloatingActionButton(
                                key: const ValueKey('next'),
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                child: const Icon(Icons.arrow_forward_rounded),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;

  _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });
}
