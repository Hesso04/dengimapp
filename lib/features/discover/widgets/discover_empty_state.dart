import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/discovery_provider.dart';

class DiscoverEmptyState extends StatelessWidget {
  final VoidCallback onShowFilters;

  const DiscoverEmptyState({
    super.key,
    required this.onShowFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.textSecondary;
    final iconBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Küçük, yumuşak ikon — %40 küçültüldü (120 → 72)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                boxShadow: [AppColors.neoShadow],
              ),
              child: Icon(
                Icons.explore_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Şu an için bu kadar 🎉',
              style: GoogleFonts.outfit(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Yakınındakileri bulmak için\nfiltrelerini genişlet veya daha sonra tekrar dene.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: subTextColor,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 36),
            // Butonlar — çerçevesiz, soft
            Row(
              children: [
                Expanded(
                  child: _ModernButton(
                    label: 'Filtreler',
                    isPrimary: true,
                    onTap: onShowFilters,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModernButton(
                    label: 'Yenile',
                    isPrimary: false,
                    onTap: () =>
                        context.read<DiscoveryProvider>().loadDiscoveryUsers(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ModernButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<_ModernButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: widget.isPrimary
              ? AppColors.primary.withValues(alpha: _pressed ? 0.85 : 1.0)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(AppColors.neoRadius),
          boxShadow: widget.isPrimary ? [AppColors.primaryShadow] : [AppColors.neoShadowSmall],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: widget.isPrimary
                  ? Colors.white
                  : (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
