import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onIndexChanged;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        boxShadow: [
          BoxShadow(
            color: AppColor.blackColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () {
                  if (onIndexChanged != null && currentIndex != 0) {
                    onIndexChanged!(0);
                  }
                },
              ),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(
                context: context,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                isActive: currentIndex == 1,
                onTap: () {
                  if (onIndexChanged != null && currentIndex != 1) {
                    onIndexChanged!(1);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? AppColor.primaryColor : AppColor.grey,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColor.primaryColor : AppColor.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const ModernFAB({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.primaryColor, AppColor.lightPrimaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Icon(Icons.add, size: 28, color: AppColor.whiteColor),
          ),
        ),
      ),
    );
  }
}
