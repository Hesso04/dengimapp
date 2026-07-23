import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'package:dengim/features/main/main_scaffold.dart'; 
import '../auth/services/profile_service.dart';
import '../../core/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final ProfileService _profileService = ProfileService();
  final PageController _pageController = PageController();
  
  int _currentPage = 0;
  final int _totalPages = 5;
  bool _isTransitioning = false;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'Türkiye 🇹🇷');
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  // FocusNodes for birth date auto-advance
  final FocusNode _dayFocusNode = FocusNode();
  final FocusNode _monthFocusNode = FocusNode();
  final FocusNode _yearFocusNode = FocusNode();

  String? _selectedGender;
  String? _selectedRelationshipGoal;
  final List<String> _selectedInterests = [];
  final List<XFile?> _profilePhotos = [null, null, null, null, null, null]; 
  final Map<int, Uint8List> _photoBytes = {}; 

  final List<Map<String, String>> _relationshipGoals = [
    {'id': 'serious', 'label': 'Ciddi İlişki 💍', 'desc': 'Uzun vadeli ve samimi bir partnerlik'},
    {'id': 'casual', 'label': 'Eğlence 🥂', 'desc': 'Rahat, keyifli ve sosyal anlar'},
    {'id': 'chat', 'label': 'Sohbet & Kahve ☕', 'desc': 'Yeni insanlarla tanışıp dertleşmek'},
    {'id': 'unsure', 'label': 'Aşışına Bıraktım 🌿', 'desc': 'Zamanın ne getireceğini görelim'},
  ];
  
  final List<Map<String, dynamic>> _interests = [
    {'name': 'Seyahat', 'icon': Icons.flight_takeoff_rounded},
    {'name': 'Müzik', 'icon': Icons.music_note_rounded},
    {'name': 'Tenis', 'icon': Icons.sports_tennis_rounded},
    {'name': 'Yemek', 'icon': Icons.restaurant_rounded},
    {'name': 'Sinema', 'icon': Icons.movie_creation_rounded},
    {'name': 'Spor', 'icon': Icons.fitness_center_rounded},
    {'name': 'Fotoğrafçılık', 'icon': Icons.camera_alt_rounded},
    {'name': 'Yoga', 'icon': Icons.self_improvement_rounded},
    {'name': 'Kahve', 'icon': Icons.coffee_rounded},
    {'name': 'Oyun', 'icon': Icons.sports_esports_rounded},
    {'name': 'Doğa', 'icon': Icons.park_rounded},
    {'name': 'Teknoloji', 'icon': Icons.laptop_mac_rounded},
    {'name': 'Dans', 'icon': Icons.nightlife_rounded},
    {'name': 'Hayvanlar', 'icon': Icons.pets_rounded},
    {'name': 'Sanat', 'icon': Icons.palette_rounded},
    {'name': 'Kitap', 'icon': Icons.menu_book_rounded},
    {'name': 'Yazılım', 'icon': Icons.code_rounded},
    {'name': 'Kripto', 'icon': Icons.currency_bitcoin_rounded},
    {'name': 'Futbol', 'icon': Icons.sports_soccer_rounded},
    {'name': 'Basketbol', 'icon': Icons.sports_basketball_rounded},
    {'name': 'Podcast', 'icon': Icons.podcasts_rounded},
    {'name': 'Girişimcilik', 'icon': Icons.rocket_launch_rounded},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    _jobController.dispose();
    _educationController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();

    _dayFocusNode.dispose();
    _monthFocusNode.dispose();
    _yearFocusNode.dispose();

    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSaveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      await _profileService.updateLocation(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Location update failed during registration: $e");
    }
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profilePhotos[index] = image;
          _photoBytes[index] = bytes;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilemedi: $e')),
        );
      }
    }
  }

  DateTime? _getBirthDateFromFields() {
    final day = int.tryParse(_dayController.text);
    final month = int.tryParse(_monthController.text);
    final year = int.tryParse(_yearController.text);
    if (day == null || month == null || year == null) return null;
    if (day < 1 || day > 31 || month < 1 || month > 12) return null;
    if (year < 1924 || year > (DateTime.now().year - 18)) return null;
    try { return DateTime(year, month, day); } catch (e) { return null; }
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_isTransitioning || _isLoading) return;

    if (_currentPage == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showSnackBar('Lütfen adınızı giriniz.');
        return;
      }
      if (_getBirthDateFromFields() == null) {
        _showSnackBar('Lütfen geçerli bir doğum tarihi giriniz (En az 18 yaş).');
        return;
      }
    }

    if (_currentPage < _totalPages - 1) {
      setState(() => _isTransitioning = true);
      HapticFeedback.selectionClick();
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut)
          .then((_) {
            if (mounted) setState(() => _isTransitioning = false);
          });
    } else {
      _submitProfile();
    }
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    if (_isTransitioning || _isLoading) return;
    if (_currentPage > 0) {
      setState(() => _isTransitioning = true);
      HapticFeedback.selectionClick();
      _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut)
          .then((_) {
            if (mounted) setState(() => _isTransitioning = false);
          });
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _submitProfile() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final userProvider = context.read<UserProvider>();
      List<String> photoUrls = [];
      final List<Future<String>> uploadFutures = [];
      final uid = Provider.of<UserProvider>(context, listen: false).currentUser?.uid ?? 'anon';
      
      for (int i = 0; i < _profilePhotos.length; i++) {
        if (_photoBytes.containsKey(i)) {
          uploadFutures.add(
            _profileService.uploadProfilePhotoBytes(_photoBytes[i]!, uid)
              .timeout(
                const Duration(seconds: 8),
                onTimeout: () {
                  return 'https://ui-avatars.com/api/?name=${_nameController.text.isNotEmpty ? _nameController.text[0] : "D"}&background=random&color=fff&size=128&font-size=0.4';
                },
              ),
          );
        }
      }
      if (uploadFutures.isNotEmpty) {
        photoUrls = await Future.wait(uploadFutures);
      }

      await _profileService.createProfile(
        name: _nameController.text.trim(),
        birthDate: _getBirthDateFromFields() ?? DateTime(2000, 1, 1),
        gender: _selectedGender ?? 'Belirtilmemiş',
        country: _countryController.text.trim(),
        interests: _selectedInterests,
        relationshipGoal: _selectedRelationshipGoal,
        photoUrls: photoUrls.isNotEmpty ? photoUrls : ['https://ui-avatars.com/api/?name=${_nameController.text.isNotEmpty ? _nameController.text[0] : "D"}&background=random&color=fff&size=128&font-size=0.4'],
        bio: _bioController.text.trim(),
        job: _jobController.text.trim(),
        education: _educationController.text.trim(),
      );

      await _fetchAndSaveLocation();
      await userProvider.loadCurrentUser();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScaffold()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Profil oluşturulamadı: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitProfileMinimal() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Kullanıcı';
      await _profileService.createProfile(
        name: name,
        birthDate: _getBirthDateFromFields() ?? DateTime(2000, 1, 1),
        gender: _selectedGender ?? 'Belirtilmemiş',
        country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : 'Türkiye 🇹🇷',
        interests: _selectedInterests,
        relationshipGoal: _selectedRelationshipGoal,
        photoUrls: ['https://ui-avatars.com/api/?name=${name[0]}&background=random&color=fff&size=128&font-size=0.4'],
        bio: _bioController.text.trim(),
        job: _jobController.text.trim(),
        education: '',
      );
      await _fetchAndSaveLocation();
      await userProvider.loadCurrentUser();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScaffold()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSkipDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Daha sonra tamamla?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text('Eksiksiz profiller 5 kat daha fazla görünürlük ve eşleşme alır. Yine de geçmek istiyor musun?', style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Devam Et', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _submitProfileMinimal(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hızlı Başlat', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.scaffoldDark : AppColors.scaffold;
    final cardBgColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 70,
        leading: _currentPage > 0 
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
              onPressed: _prevPage,
            )
          : TextButton(
              onPressed: _isLoading ? null : _showSkipDialog,
              child: Text(
                'SONRA',
                style: GoogleFonts.outfit(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        title: Column(
          children: [
            Text(
              'PROFILINI OLUŞTUR',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: textColor),
            ),
            const SizedBox(height: 8),
            _buildStepProgress(isDark),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      FocusScope.of(context).unfocus();
                      setState(() => _currentPage = page);
                    },
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildPage0(isDark, cardBgColor, textColor, subtitleColor, borderColor), // Kimlik
                      _buildPage1(isDark, cardBgColor, textColor, subtitleColor, borderColor), // Meslek/Bio
                      _buildPage2(isDark, cardBgColor, textColor, subtitleColor, borderColor), // Fotoğraflar
                      _buildPage3(isDark, cardBgColor, textColor, subtitleColor, borderColor), // Cinsiyet & Hedef
                      _buildPage4(isDark, cardBgColor, textColor, subtitleColor, borderColor), // İlgi Alanları
                    ],
                  ),
                ),
                _buildBottomNavigation(isDark, cardBgColor, textColor, borderColor),
              ],
            ),
    );
  }

  Widget _buildStepProgress(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalPages, (index) {
        final isActive = index <= _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 12,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : (isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildBottomNavigation(bool isDark, Color cardBgColor, Color textColor, Color borderColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevPage,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('GERİ', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColor)),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _currentPage == _totalPages - 1 ? 'TAMAMLA VE BAŞLA' : 'DEVAM ET',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SAMİMİ İPUCU KARTI (TIP BANNER) WIDGET ---
  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String message,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A1B3D), const Color(0xFF1E142B)]
              : [const Color(0xFFFFF0F5), const Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF6584)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2A1B3D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PAGE 0: KİMLİK & DOĞUM TARİHİ ---
  Widget _buildPage0(bool isDark, Color cardBgColor, Color textColor, Color subtitleColor, Color borderColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Seni Tanıyalım 👋', 'Topluluğumuza adını ve yaşını sunarak başlayalım.'),
          _buildTipCard(
            icon: Icons.face_rounded,
            title: 'Neden Doğum Tarihi?',
            message: 'Yaşın profilinde görünecektir. Sana en uygun yaş aralığındaki kişileri eşleştirmek için kullanırız.',
            isDark: isDark,
          ),
          _buildModernInput(
            controller: _nameController,
            label: 'AD VE SOYAD',
            placeholder: 'Örn: Caner Yılmaz',
            isDark: isDark,
            cardBgColor: cardBgColor,
            textColor: textColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('DOĞUM TARİHİ', textColor),
          _buildBirthDateInputs(isDark, cardBgColor, textColor, borderColor),
          const SizedBox(height: 20),
          _buildSectionHeader('BULUNDUĞUN ÜLKE', textColor),
          _buildCountryDropdown(isDark, cardBgColor, textColor, borderColor),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- PAGE 1: MESLEK, EĞİTİM & HAKKINDA ---
  Widget _buildPage1(bool isDark, Color cardBgColor, Color textColor, Color subtitleColor, Color borderColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Tarzını Yansıt ✍️', 'Kendinden kısaca bahsederek sohbet başlatmayı kolaylaştır.'),
          _buildTipCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Harika Bir İpucu',
            message: 'İlgi çekici ve samimi bir biyografi sohbet açılışlarını %80 oranında kolaylaştırır!',
            isDark: isDark,
          ),
          _buildModernInput(
            controller: _jobController,
            label: 'MESLEK VEYA UĞRAŞ',
            placeholder: 'Örn: Yazılım Geliştirici, Mimar, Öğrenci...',
            isDark: isDark,
            cardBgColor: cardBgColor,
            textColor: textColor,
            borderColor: borderColor,
          ),
          _buildModernInput(
            controller: _educationController,
            label: 'EĞİTİM',
            placeholder: 'Örn: Boğaziçi Üniversitesi',
            isDark: isDark,
            cardBgColor: cardBgColor,
            textColor: textColor,
            borderColor: borderColor,
          ),
          _buildModernInput(
            controller: _bioController,
            label: 'HAKKINDA BİRKAÇ CÜMLE',
            placeholder: 'Nelerden hoşlanırsın, boş zamanlarında ne yaparsın?...',
            maxLines: 4,
            isDark: isDark,
            cardBgColor: cardBgColor,
            textColor: textColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- PAGE 2: FOTOĞRAFLAR ---
  Widget _buildPage2(bool isDark, Color cardBgColor, Color textColor, Color subtitleColor, Color borderColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _buildStepHeader('En Güzel Karelerin 📸', 'Fotoğrafların senin en büyük vitrinindir.'),
          _buildTipCard(
            icon: Icons.photo_camera_back_rounded,
            title: 'Vitrinini Parlat',
            message: 'Gülümseyen ve yüzünün net göründüğü fotoğraflar 5 kat daha fazla etkileşim getirir!',
            isDark: isDark,
          ),
          _buildPhotoPickerGrid(isDark, cardBgColor, textColor, borderColor),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- PAGE 3: CİNSİYET & İLİŞKİ HEDEFİ ---
  Widget _buildPage3(bool isDark, Color cardBgColor, Color textColor, Color subtitleColor, Color borderColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Niyet ve Tercihler 🎯', 'Sana en doğru eşleşmeleri getirmemiz için hedefini seç.'),
          _buildTipCard(
            icon: Icons.favorite_border_rounded,
            title: 'Açık İletişim',
            message: 'Ne aradığını belirtmek beklentileri doğru yönetir ve doğru insanları karşına çıkarır.',
            isDark: isDark,
          ),
          _buildSectionHeader('CİNSİYETİN', textColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildGenderChip('Erkek', Icons.male_rounded, isDark, cardBgColor, textColor, borderColor),
                const SizedBox(width: 12),
                _buildGenderChip('Kadın', Icons.female_rounded, isDark, cardBgColor, textColor, borderColor),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('İLİŞKİ HEDEFİN', textColor),
          _buildRelationshipGoalSelector(isDark, cardBgColor, textColor, borderColor),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- PAGE 4: İLİŞKİ HEDEFİ & İLGİ ALANLARI ---
  Widget _buildPage4(bool isDark, Color cardBgColor, Color textColor, Color subtitleColor, Color borderColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('İlgi Alanların ✨', 'Ortak tutkular harika sohbetlerin başlangıcıdır.'),
          _buildTipCard(
            icon: Icons.stars_rounded,
            title: 'Ortak Noktalar',
            message: 'En az 3 ilgi alanı seç. Eşleştiğin kişilerle ortak ilgi alanların sohbetinde vurgulanacaktır!',
            isDark: isDark,
          ),
          _buildInterestsGrid(isDark, cardBgColor, textColor, borderColor),
          const SizedBox(height: 28),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '🎉 Harika! Tüm bilgiler tamamlandı. Aşağıdaki butona basarak Dengim dünyasına ilk adımını atabilirsin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: textColor),
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    int maxLines = 1,
    required bool isDark,
    required Color cardBgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
            ),
          ),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.black38, fontSize: 14),
              filled: true,
              fillColor: cardBgColor,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  // --- DOĞUM TARİHİ INPUTLARI & AUTO-FOCUS ---
  Widget _buildBirthDateInputs(bool isDark, Color cardBgColor, Color textColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildDatePartInput(_dayController, _dayFocusNode, _monthFocusNode, 'GÜN', '15', 2, isDark, cardBgColor, textColor, borderColor),
          const SizedBox(width: 12),
          _buildDatePartInput(_monthController, _monthFocusNode, _yearFocusNode, 'AY', '06', 2, isDark, cardBgColor, textColor, borderColor),
          const SizedBox(width: 12),
          _buildDatePartInput(_yearController, _yearFocusNode, null, 'YIL', '1998', 4, isDark, cardBgColor, textColor, borderColor, flex: 2),
        ],
      ),
    );
  }

  Widget _buildDatePartInput(
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
    String label,
    String hint,
    int length,
    bool isDark,
    Color cardBgColor,
    Color textColor,
    Color borderColor, {
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: TextFormField(
        controller: controller,
        focusNode: currentFocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(length)],
        style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w700, fontSize: 16),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: cardBgColor,
          labelStyle: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 11),
          hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white24 : Colors.black26),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
        onChanged: (val) {
          if (val.length == length && nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCountryDropdown(bool isDark, Color cardBgColor, Color textColor, Color borderColor) {
    final countries = [
      'Türkiye 🇹🇷', 'Almanya 🇩🇪', 'Fransa 🇫🇷', 'İngiltere 🇬🇧', 'ABD 🇺🇸',
      'Hollanda 🇳🇱', 'Avusturya 🇦🇹', 'Belçika 🇧🇪', 'İsviçre 🇨🇭', 'İsveç 🇸🇪',
      'İtalya 🇮🇹', 'İspanya 🇪🇸', 'Kanada 🇨🇦', 'Azerbaycan 🇦🇿', 'KKTC 🇹🇷', 'Diğer 🌍',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DropdownButtonFormField<String>(
        initialValue: countries.contains(_countryController.text) ? _countryController.text : 'Türkiye 🇹🇷',
        style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          filled: true,
          fillColor: cardBgColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
        ),
        dropdownColor: cardBgColor,
        isExpanded: true,
        menuMaxHeight: 350,
        items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() => _countryController.text = v);
          }
        },
      ),
    );
  }

  // --- FOTOĞRAF IZGARASI ---
  Widget _buildPhotoPickerGrid(bool isDark, Color cardBgColor, Color textColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Ana Fotoğraf (Büyük)
          GestureDetector(
            onTap: () => _pickImage(0),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _photoBytes.containsKey(0) ? AppColors.primary : borderColor, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: _photoBytes.containsKey(0)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.memory(_photoBytes[0]!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_a_photo_rounded, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ana Profil Fotoğrafı Ekle',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dokunarak galeriden seç',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Diğer 5 Küçük Fotoğraf Karesi
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              final realIndex = index + 1;
              final hasImage = _photoBytes.containsKey(realIndex);
              return GestureDetector(
                onTap: () => _pickImage(realIndex),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: hasImage ? AppColors.primary : borderColor, width: 1.5),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(_photoBytes[realIndex]!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- CİNSİYET SEÇİMİ CHIP ---
  Widget _buildGenderChip(String label, IconData icon, bool isDark, Color cardBgColor, Color textColor, Color borderColor) {
    final isSelected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedGender = label);
          HapticFeedback.lightImpact();
          // Cinsiyet seçildiği an otomatik sonraki adıma kaydırma!
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _currentPage == 3 && _selectedRelationshipGoal != null) {
              _nextPage();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : borderColor, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : textColor, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- İLİŞKİ HEDEFİ SEÇİCİ & AUTO-ADVANCE ---
  Widget _buildRelationshipGoalSelector(bool isDark, Color cardBgColor, Color textColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _relationshipGoals.map((goal) {
          final isSelected = _selectedRelationshipGoal == goal['id'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedRelationshipGoal = goal['id']);
              HapticFeedback.lightImpact();
              // Hedef seçildiğinde 350ms sonra otomatik sonraki adıma geç!
              Future.delayed(const Duration(milliseconds: 350), () {
                if (mounted && _currentPage == 3 && _selectedGender != null) {
                  _nextPage();
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : borderColor, width: 1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal['label']!,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isSelected ? Colors.white : textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal['desc']!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isSelected ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- İLGİ ALANLARI GRID ---
  Widget _buildInterestsGrid(bool isDark, Color cardBgColor, Color textColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _interests.map((interest) {
          final isSelected = _selectedInterests.contains(interest['name']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedInterests.remove(interest['name']);
                } else if (_selectedInterests.length < 8) {
                  _selectedInterests.add(interest['name']);
                } else {
                  _showSnackBar('En fazla 8 ilgi alanı seçebilirsin.');
                }
              });
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : borderColor, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    interest['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    interest['name'] as String,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
