import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CategoryFilter extends StatelessWidget {
  final String? selected;
  final void Function(String?) onChanged;

  const CategoryFilter({super.key, this.selected, required this.onChanged});

  static const List<Map<String, dynamic>> _categories = [
    {'key': null, 'label': 'Semua', 'icon': Icons.grid_view_rounded},
    {'key': 'elektronik', 'label': 'Elektronik', 'icon': Icons.devices_rounded},
    {'key': 'dompet', 'label': 'Dompet', 'icon': Icons.account_balance_wallet_rounded},
    {'key': 'kunci', 'label': 'Kunci', 'icon': Icons.key_rounded},
    {'key': 'pakaian', 'label': 'Pakaian', 'icon': Icons.checkroom_rounded},
    {'key': 'dokumen', 'label': 'Dokumen', 'icon': Icons.description_rounded},
    {'key': 'tas', 'label': 'Tas', 'icon': Icons.backpack_rounded},
    {'key': 'lainnya', 'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final catKey = cat['key'] as String?;

          // Fix: "Semua" aktif jika selected == null
          // Kategori lain aktif jika selected == key-nya
          final isSelected = catKey == null
              ? selected == null
              : selected == catKey;

          return GestureDetector(
            onTap: () => onChanged(catKey),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}