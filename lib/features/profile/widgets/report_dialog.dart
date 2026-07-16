import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dengim/core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../auth/services/report_service.dart';
import '../../auth/services/block_service.dart';

/// Kullanıcı raporlama ve engelleme dialog'u
class ReportDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final bool showBlockOption;

  const ReportDialog({
    super.key,
    required this.userId,
    required this.userName,
    this.showBlockOption = true,
  });

  /// Dialog'u göster
  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    required String userName,
    bool showBlockOption = true,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ReportDialog(
        userId: userId,
        userName: userName,
        showBlockOption: showBlockOption,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _selectedReason;
  final TextEditingController _additionalInfoController = TextEditingController();
  bool _isLoading = false;
  bool _alsoBlock = false;

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ErrorHandler.showError(context, 'Lütfen bir neden seçin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Rapor gönder
      final success = await ReportService().reportUser(
        reportedUserId: widget.userId,
        reason: _selectedReason!,
        additionalInfo: _additionalInfoController.text.isEmpty 
            ? null 
            : _additionalInfoController.text,
      );

      // Engelleme seçildiyse engelle
      if (_alsoBlock) {
        await BlockService().blockUser(widget.userId);
      }

      if (mounted) {
        if (success) {
          ErrorHandler.showSuccess(context, 'Rapor başarıyla gönderildi');
          Navigator.pop(context, true);
        } else {
          ErrorHandler.showError(context, 'Bu kullanıcıyı zaten raporladınız');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Bir hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.scaffoldDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.flag_rounded,
                  size: 48,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.userName} Bildir',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu kullanıcıyı neden bildirmek istiyorsunuz?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Reason Options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ...ReportReason.values.map((reason) => _buildReasonOption(reason)),
                  
                  // Additional Info
                  const SizedBox(height: 16),
                  TextField(
                    controller: _additionalInfoController,
                    maxLines: 3,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Ek bilgi ekleyin (opsiyonel)',
                      hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),

                  // Also Block Option
                  if (widget.showBlockOption) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => setState(() => _alsoBlock = !_alsoBlock),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _alsoBlock 
                              ? Colors.red.withValues(alpha: 0.1) 
                              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _alsoBlock 
                                ? Colors.red.withValues(alpha: 0.3) 
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _alsoBlock ? Icons.check_box : Icons.check_box_outline_blank,
                              color: _alsoBlock ? Colors.red : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ayrıca Engelle',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Bu kullanıcı sizi göremeyecek',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: Colors.red.withValues(alpha: 0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Bildir',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Cancel Button
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'İptal',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonOption(ReportReason reason) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.1) 
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
            ),
            const SizedBox(width: 12),
            Text(
              reason.displayName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sadece engelleme için basit dialog
class BlockConfirmDialog extends StatelessWidget {
  final String userId;
  final String userName;

  const BlockConfirmDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    required String userName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BlockConfirmDialog(userId: userId, userName: userName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.scaffoldDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
      ),
      title: Text(
        '$userName Engelle?',
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Bu kullanıcıyı engellediğinizde:\n\n• Karşılıklı olarak birbirinizi göremezsiniz\n• Mesajlaşamazsınız\n• Keşfette çıkmaz\n\nDaha sonra ayarlardan engeli kaldırabilirsiniz.',
        style: GoogleFonts.plusJakartaSans(
          color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('İptal', style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5))),
        ),
        ElevatedButton(
          onPressed: () async {
            await BlockService().blockUser(userId);
            if (context.mounted) {
              ErrorHandler.showSuccess(context, '$userName engellendi');
              Navigator.pop(context, true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Engelle'),
        ),
      ],
    );
  }
}
