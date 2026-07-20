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

  /// Convert to Map for passing to services
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

  @override
  void initState() {
    super.initState();
    _settings = FilterSettings(
      ageRange: widget.initialSettings.ageRange,
      gender: widget.initialSettings.gender,
      distance: widget.initialSettings.distance,
      location: widget.initialSettings.location,
      interests: widget.initialSettings.interests,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF090A0C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white10, width: 1.0)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
                ),
                child: Row(
                  children: [
                    _buildNeoCircleButton(
                      icon: Icons.close,
                      onTap: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'FİLTRELER',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _buildSectionHeader('KİMİ GÖRMEK İSTERSİN?'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildGenderChip('ERKEK', 'male'),
                          const SizedBox(width: 12),
                          _buildGenderChip('KADIN', 'female'),
                          const SizedBox(width: 12),
                          _buildGenderChip('HEPSİ', 'all'),
                        ],
                      ),

                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('YAŞ ARALIĞI'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                              boxShadow: [AppColors.neoShadowSmall],
                            ),
                            child: Text(
                              '${_settings.ageRange.start.toInt()} - ${_settings.ageRange.end.toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildRangeSlider(),

                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('MESAFE'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                              boxShadow: [AppColors.neoShadowSmall],
                            ),
                            child: Text(
                              '${_settings.distance.toInt()} KM',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDistanceSlider(),

                      const SizedBox(height: 40),
                      _buildSectionHeader('KONUM'),
                      const SizedBox(height: 16),
                      _buildLocationPicker(),

                      const SizedBox(height: 40),
                      _buildSectionHeader('İLGİ ALANLARI'),
                      const SizedBox(height: 16),
                      _buildInterestsSection(),

                      const SizedBox(height: 120), // Extra space for button
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Footer Apply Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                widget.onApply(_settings);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: [AppColors.neoShadowSmall],
                ),
                child: Center(
                  child: Text(
                    'FİLTRELERİ UYGULA',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Colors.black.withValues(alpha: 0.4),
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildNeoCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Icon(icon, color: Colors.black, size: 22),
      ),
    );
  }

  Widget _buildGenderChip(String label, String value) {
    final isSelected = _settings.gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _settings.gender = value),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            boxShadow: [
              if (isSelected) AppColors.neoShadowSmall,
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSlider() {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: Colors.black,
        inactiveTrackColor: Colors.black12,
        thumbColor: Colors.white,
        overlayColor: Colors.black12,
        trackHeight: 12,
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 16,
          elevation: 0,
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

  Widget _buildDistanceSlider() {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: Colors.black,
        inactiveTrackColor: Colors.black12,
        thumbColor: Colors.white,
        overlayColor: Colors.black12,
        trackHeight: 12,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 16,
          elevation: 0,
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

  Widget _buildLocationPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
              boxShadow: [AppColors.neoShadowSmall],
            ),
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _settings.location.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'YAKINIMDAKİLERİ ARA',
                  style: GoogleFonts.outfit(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black),
        ],
      ),
    );
  }

  final List<String> _interestOptions = const [
    'Müzik', 'Spor', 'Sanat', 'Gezi', 'Teknoloji', 
    'Yemek', 'Dans', 'Oyun', 'Sinema', 'Kitap', 
    'Moda', 'Fotoğraf', 'Doğa', 'Hayvanlar'
  ];

  Widget _buildInterestsSection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
              boxShadow: [
                if (isSelected) AppColors.neoShadowSmall,
              ],
            ),
            child: Text(
              interest.toUpperCase(),
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
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
