import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../core/providers/navigation_provider.dart';
import '../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'izin/izin_screen.dart';
import 'profile/profile_screen.dart';
import 'riwayat/riwayat_screen.dart';

/// Main navigation shell hosting the 4 primary tabs and the floating CrystalNavigationBar.
class MainShell extends StatelessWidget {
  static const String routeName = '/main';

  const MainShell({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    IzinScreen(),
    RiwayatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: nav.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CrystalNavigationBar(
          currentIndex: nav.currentIndex,
          height: 60,
          borderRadius: 30,
          backgroundColor: Colors.white.withValues(alpha: 0.85),
          outlineBorderColor: AppColors.primaryBlue.withValues(alpha: 0.2),
          borderWidth: 1.0,
          unselectedItemColor: AppColors.textLight,
          selectedItemColor: AppColors.primaryBlue,
          indicatorColor: AppColors.primaryBlue,
          marginR: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          paddingR: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          onTap: (index) => nav.setIndex(index),
          items: [
            // Home
            CrystalNavigationBarItem(
              icon: Iconsax.home_15,
              unselectedIcon: Iconsax.home,
              selectedColor: AppColors.primaryBlue,
              unselectedColor: AppColors.textLight,
            ),
            // Izin
            CrystalNavigationBarItem(
              icon: Iconsax.document_text_15,
              unselectedIcon: Iconsax.document_text,
              selectedColor: AppColors.primaryBlue,
              unselectedColor: AppColors.textLight,
            ),
            // Riwayat
            CrystalNavigationBarItem(
              icon: Iconsax.clock5,
              unselectedIcon: Iconsax.clock,
              selectedColor: AppColors.primaryBlue,
              unselectedColor: AppColors.textLight,
            ),
            // Profil
            CrystalNavigationBarItem(
              icon: Icons.person_rounded,
              unselectedIcon: Iconsax.user,
              selectedColor: AppColors.primaryBlue,
              unselectedColor: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
