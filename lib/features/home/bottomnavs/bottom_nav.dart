import 'package:flutter/material.dart';
import 'package:econsultation/core/theme.dart';
import 'package:go_router/go_router.dart';

// import 'package:google_fonts/google_fonts.dart';
// import '../constants/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        border: const Border(
          top: BorderSide(color: Color(0xFFF4F4F4)),
          left: BorderSide(color: Color(0xFFF4F4F4)),
          right: BorderSide(color: Color(0xFFF4F4F4)),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient line for selected tab
          if (selectedIndex >= 0)
            Container(
              height: 4,
              margin: EdgeInsets.only(
                left: (selectedIndex * (MediaQuery.of(context).size.width / 4)),
                top: 8,
              ),
              width: MediaQuery.of(context).size.width / 4,
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, 'Home', context),
                _buildNavItem(1, Icons.description, 'Documents', context),
                _buildNavItem(2, Icons.chat, 'Feedbacks', context),
                _buildNavItem(3, Icons.settings, 'Settings', context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    BuildContext context,
  ) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onIndexChanged(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryDark : AppTheme.secondaryText,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            // style: AppTheme.textStyle11.copyWith(
            //   fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            //   color: isSelected
            //       ? AppTheme.primaryDark
            //       : AppTheme.secondaryText,
            // ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
