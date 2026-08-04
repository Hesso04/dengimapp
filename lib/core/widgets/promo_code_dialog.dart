import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/credit_provider.dart';

class PromoCodeDialog extends StatefulWidget {
  const PromoCodeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PromoCodeDialog(),
    );
  }

  @override
  State<PromoCodeDialog> createState() => _PromoCodeDialogState();
}

class _PromoCodeDialogState extends State<PromoCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final creditProvider = context.read<CreditProvider>();
    final result = await creditProvider.redeemPromoCode(code);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Kredi yüklendi!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _errorMessage = result['message'] ?? 'Kod geçersiz.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.confirmation_number_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'PROMOSYON KODU',
            style: GoogleFonts.outfit(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kampanya veya admin kodunuzu girerek anında ücretsiz kredi kazanın.',
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            decoration: InputDecoration(
              hintText: 'Örn: DENGIM2026',
              hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.black38, letterSpacing: 0),
              filled: true,
              fillColor: isDark ? const Color(0xFF191C24) : const Color(0xFFF2F4F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: GoogleFonts.outfit(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İPTAL', style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _redeemCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('KULLAN', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
