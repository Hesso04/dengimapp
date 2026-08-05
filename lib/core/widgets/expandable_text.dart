import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxChars;
  final TextStyle? style;
  final TextAlign textAlign;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxChars = 50,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = widget.style ?? GoogleFonts.outfit(
      fontSize: 14,
      color: isDark ? Colors.white70 : Colors.black87,
      height: 1.4,
    );

    if (text.length <= widget.maxChars) {
      return Text(text, style: defaultStyle, textAlign: widget.textAlign);
    }

    final displayText = _isExpanded
        ? text
        : '${text.substring(0, widget.maxChars)}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayText,
          style: defaultStyle,
          textAlign: widget.textAlign,
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            _isExpanded ? 'Daha Az Göster' : 'Devamını Gör...',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
