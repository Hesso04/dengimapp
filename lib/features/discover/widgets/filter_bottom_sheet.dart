import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Filtre ayarları için model
class FilterSettings {
  RangeValues ageRange;
  String gender; // 'male', 'female', 'all'
  double distance; // in km
  String location;
  List<String> interests;
  bool verifiedOnly;
  bool hasPhotoOnly;
  bool onlineOnly;
  String? relationshipGoal;

  FilterSettings({
    this.ageRange = const RangeValues(18, 99),
    this.gender = 'all',
    this.distance = 100,
    this.location = 'Türkiye',
    this.interests = const [],
    this.verifiedOnly = false,
    this.hasPhotoOnly = true,
    this.onlineOnly = false,
    this.relationshipGoal,
  });

  FilterSettings copyWith({
    RangeValues? ageRange,
    String? gender,
    double? distance,
    String? location,
    List<String>? interests,
    bool? verifiedOnly,
    bool? hasPhotoOnly,
    bool? onlineOnly,
    String? relationshipGoal,
  }) {
    return FilterSettings(
      ageRange: ageRange ?? this.ageRange,
      gender: gender ?? this.gender,
      distance: distance ?? this.distance,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      hasPhotoOnly: hasPhotoOnly ?? this.hasPhotoOnly,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minAge': ageRange.start.toInt(),
      'maxAge': ageRange.end.toInt(),
      'gender': gender,
      'maxDistance': distance.toInt(),
      'location': location,
      'interests': interests,
      'verifiedOnly': verifiedOnly,
      'hasPhotoOnly': hasPhotoOnly,
      'onlineOnly': onlineOnly,
      'relationshipGoal': relationshipGoal,
    };
  }
}

class FilterBottomSheet extends StatefulWidget {
  final FilterSettings initialSettings;
  final Function(FilterSettings) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialSettings,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterSettings _settings;

  final List<Map<String, String>> _relationshipGoals = const [
    {'id': 'serious', 'label': 'Ciddi İlişki 💍'},
    {'id': 'casual', 'label': 'Eğlence 🥂'},
    {'id': 'chat', 'label': 'Sohbet ☕'},
    {'id': 'unsure', 'label': 'Belirsiz 🤷‍♂️'},
  ];

  @override
  void initState() {
    super.initState();
    _settings = FilterSettings(
      ageRange: widget.initialSettings.ageRange,
      gender: widget.initialSettings.gender,
      distance: widget.initialSettings.distance,
      location: widget.initialSettings.location,
      interests: List.from(widget.initialSettings.interests),
      verifiedOnly: widget.initialSettings.verifiedOnly,
      hasPhotoOnly: widget.initialSettings.hasPhotoOnly,
      onlineOnly: widget.initialSettings.onlineOnly,
      relationshipGoal: widget.initialSettings.relationshipGoal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF14161B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final cardBg = isDark ? const Color(0xFF1F1F23) : const Color(0xFFF7F8FA);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'FİLTRELER',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _settings = FilterSettings();
                        });
                      },
                      child: Text(
                        'SIFIRLA',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('KİMİ GÖRMEK İSTERSİN?', textColor),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildGenderChip('ERKEK', 'male', isDark, cardBg, borderColor, textColor),
                          const SizedBox(width: 8),
                          _buildGenderChip('KADIN', 'female', isDark, cardBg, borderColor, textColor),
                          const SizedBox(width: 8),
                          _buildGenderChip('HEPSİ', 'all', isDark, cardBg, borderColor, textColor),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('YAŞ ARALIĞI', textColor),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_settings.ageRange.start.toInt()} - ${_settings.ageRange.end.toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRangeSlider(isDark),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('MAKSİMUM MESAFE', textColor),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF262629) : Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_settings.distance.toInt()} KM',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDistanceSlider(isDark),

                      const SizedBox(height: 32),
                      _buildSectionHeader('NE ARIYORSUN? (İLİŞKİ HEDEFİ)', textColor),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _relationshipGoals.map((goal) {
                          final isSelected = _settings.relationshipGoal == goal['id'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _settings.relationshipGoal = isSelected ? null : goal['id'];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : borderColor,
                                ),
                              ),
                              child: Text(
                                goal['label']!,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader('İLGİ ALANLARI', textColor),
                      const SizedBox(height: 12),
                      _buildInterestsSection(isDark, cardBg, borderColor, textColor),

                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Footer Apply Button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_settings);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Text(
                'FİLTRELERİ UYGULA',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: textColor.withValues(alpha: 0.7),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildGenderChip(String label, String value, bool isDark, Color cardBg, Color borderColor, Color textColor) {
    final isSelected = _settings.gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _settings.gender = value),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : borderColor),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSlider(bool isDark) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
        thumbColor: Colors.white,
        overlayColor: AppColors.primary.withValues(alpha: 0.2),
        trackHeight: 6,
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 12,
          elevation: 2,
        ),
      ),
      child: RangeSlider(
        values: _settings.ageRange,
        min: 18,
        max: 99,
        onChanged: (val) => setState(() => _settings.ageRange = val),
      ),
    );
  }

  Widget _buildDistanceSlider(bool isDark) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: isDark ? Colors.white : Colors.black,
        inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
        thumbColor: Colors.white,
        overlayColor: isDark ? Colors.white10 : Colors.black12,
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12,
          elevation: 2,
        ),
      ),
      child: Slider(
        value: _settings.distance,
        min: 1,
        max: 100,
        onChanged: (val) => setState(() => _settings.distance = val),
      ),
    );
  }

  final List<String> _interestOptions = const [
    'Müzik', 'Spor', 'Sanat', 'Gezi', 'Teknoloji', 
    'Yemek', 'Dans', 'Oyun', 'Sinema', 'Kitap', 
    'Moda', 'Fotoğraf', 'Doğa', 'Hayvanlar'
  ];

  Widget _buildInterestsSection(bool isDark, Color cardBg, Color borderColor, Color textColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interestOptions.map((interest) {
        final isSelected = _settings.interests.contains(interest);
        return GestureDetector(
          onTap: () {
            setState(() {
              List<String> newInterests = List.from(_settings.interests);
              if (isSelected) {
                newInterests.remove(interest);
              } else {
                newInterests.add(interest);
              }
              _settings.interests = newInterests;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : borderColor),
            ),
            child: Text(
              interest.toUpperCase(),
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : textColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

void showFilterBottomSheet(
  BuildContext context, {
  required FilterSettings currentSettings,
  required Function(FilterSettings) onApply,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => FilterBottomSheet(
      initialSettings: currentSettings,
      onApply: onApply,
    ),
  );
}
