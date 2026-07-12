import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // YENİ
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/error_handler.dart';
import '../auth/services/profile_service.dart';
import '../auth/models/user_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import 'dart:io';
import '../../core/services/audio_recorder_service.dart';
import '../../core/services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _jobController;
  late TextEditingController _educationController;
  late TextEditingController _ageController;
  late TextEditingController _countryController;
  
  List<String> _photoUrls = [];
  String? _videoUrl;
  String? _profileVoiceUrl;
  List<String> _selectedInterests = [];
  bool _isSaving = false;
  bool _hasChanges = false;
  
  bool _isRecording = false;
  int _recordingDuration = 0;
  final AudioRecorderService _audioRecorder = AudioRecorderService();

  final List<String> _allInterests = [
    'Spor', 'Müzik', 'Sanat', 'Film', 'Okuma', 'Seyahat',
    'Yeme-İçme', 'Fotoğrafçılık', 'Dans', 'Yoga', 'Oyun',
    'Fitness', 'Moda', 'Doğa', 'Teknoloji', 'Girişimcilik',
  ];

  String? _selectedRelationshipGoal;
  final List<Map<String, String>> _relationshipGoals = [
    {'id': 'serious', 'label': 'Ciddi İlişki 💍', 'desc': 'Uzun vadeli partner'},
    {'id': 'casual', 'label': 'Eğlence 🥂', 'desc': 'Rahat takılmaca'},
    {'id': 'chat', 'label': 'Sohbet ☕', 'desc': 'Arkadaşlık ve sohbet'},
    {'id': 'unsure', 'label': 'Belirsiz 🤷‍♂️', 'desc': 'Henüz karar vermedim'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _jobController = TextEditingController(text: widget.profile.job ?? '');
    _educationController = TextEditingController(text: widget.profile.education ?? '');
    _ageController = TextEditingController(text: widget.profile.age.toString());
    _countryController = TextEditingController(text: widget.profile.country);
    _photoUrls = List.from(widget.profile.photoUrls ?? []);
    _videoUrl = widget.profile.videoUrl;
    _profileVoiceUrl = widget.profile.profileVoiceUrl;
    _selectedInterests = List.from(widget.profile.interests);
    _selectedRelationshipGoal = widget.profile.relationshipGoal;

    _audioRecorder.onDurationUpdate = (duration) {
      if (mounted) setState(() => _recordingDuration = duration);
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _jobController.dispose();
    _educationController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    
    if (image != null) {
      setState(() => _isSaving = true);
      try {
        final url = await ProfileService().uploadProfilePhoto(image, widget.profile.uid);
        setState(() {
          _photoUrls.add(url);
          _hasChanges = true;
        });
      } catch (e) {
        if (mounted) ErrorHandler.showError(context, "Fotoğraf yüklenemedi: $e");
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAndUploadVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 30));
    
    if (video != null) {
      setState(() => _isSaving = true);
      try {
        final url = await ProfileService().uploadProfileVideo(video);
        if (url != null) {
          setState(() {
            _videoUrl = url;
            _hasChanges = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Video başarıyla yüklendi!'), backgroundColor: Colors.green),
            );
          }
        }
      } catch (e) {
        if (mounted) ErrorHandler.showError(context, "Video yüklenemedi: $e");
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _startRecording() async {
    final started = await _audioRecorder.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });
    } else {
      if (mounted) ErrorHandler.showError(context, "Mikrofon erişimi gerekli");
    }
  }

  Future<void> _stopAndSaveRecording() async {
    if (!_isRecording) return;
    
    setState(() => _isSaving = true);
    try {
      final filePath = await _audioRecorder.stopRecording();
      setState(() {
        _isRecording = false;
      });
      if (filePath != null) {
        Uint8List bytes;
        if (kIsWeb) {
            // Web returns a blob URL, we need to fetch it to get bytes
            // Note: Requires http package, but we can try using cross_file or just dio/http if available.
            // A simpler way without extra packages is just returning the blob if Cloudinary handles it,
            // but our CloudinaryService expects bytes.
            // Using dart:html is discouraged for cross-platform, but we can use XFile if we wrap it.
            // For now, let's use a dynamic fetch if on web, or just skip if we don't have http.
            // Ideally record package on web returns an url we can read via standard ways.
            // Let's use a generic approach using XFile (from image_picker which we already imported)
            final xfile = XFile(filePath);
            bytes = await xfile.readAsBytes();
        } else {
            final file = File(filePath);
            bytes = await file.readAsBytes();
        }
        
        final url = await CloudinaryService.uploadAudioBytes(bytes);
        if (url != null) {
          setState(() {
            _profileVoiceUrl = url;
            _hasChanges = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Ses kaydı başarıyla yüklendi!'), backgroundColor: Colors.green),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, "Ses yüklenemedi: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _cancelRecording() async {
    await _audioRecorder.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUrls.removeAt(index);
      _hasChanges = true;
    });
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else if (_selectedInterests.length < 6) {
        _selectedInterests.add(interest);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En fazla 6 ilgi alanı seçebilirsiniz')),
        );
      }
      _hasChanges = true;
    });
  }

  Future<void> _saveProfile() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      ErrorHandler.showError(context, "İsim boş bırakılamaz");
      return;
    }
    
    if (_photoUrls.isEmpty) {
      ErrorHandler.showError(context, "En az 1 fotoğraf eklemelisiniz");
      return;
    }

    if (_selectedInterests.isEmpty) {
      ErrorHandler.showError(context, "En az 1 ilgi alanı seçmelisiniz");
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ProfileService().updateProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        job: _jobController.text.trim().isNotEmpty ? _jobController.text.trim() : null,
        education: _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : null,
        age: int.tryParse(_ageController.text.trim()) ?? widget.profile.age,
        country: _countryController.text.trim(),
        photoUrls: _photoUrls,
        videoUrl: _videoUrl,
        profileVoiceUrl: _profileVoiceUrl,
        interests: _selectedInterests,
        relationshipGoal: _selectedRelationshipGoal,
      );

      // Refresh provider
      await context.read<UserProvider>().loadCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profil güncellendi!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorHandler.showError(context, "Kaydetme hatası: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildCircleIcon(Icons.arrow_back_ios_new, onTap: () {
            if (_hasChanges) {
              _showDiscardDialog();
            } else {
              Navigator.pop(context);
            }
          }),
        ),
        centerTitle: true,
        title: Text(
          "PROFİLİ DÜZENLE",
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: _isSaving ? null : _saveProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: [AppColors.neoShadowSmall],
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(
                        'KAYDET',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.black, height: 1),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos Section
            _buildSectionHeader("FOTOĞRAFLAR"),
            const SizedBox(height: 12),
            _buildPhotosGrid(),
            
            const SizedBox(height: 24),
            
            // Video Section
            _buildSectionHeader("VİDEO PROFİL (OPSİYONEL)"),
            const SizedBox(height: 12),
            _buildVideoPicker(),
            
            const SizedBox(height: 24),
            
            // Voice Section
            _buildSectionHeader("SES PROFİLİ (OPSİYONEL - MAX 30SN)"),
            const SizedBox(height: 12),
            _buildVoicePicker(),
            
            const SizedBox(height: 32),
            
            // Basic Info
            _buildSectionHeader("TEMEL BİLGİLER"),
            const SizedBox(height: 16),
            _buildTextField("İsim", _nameController, Icons.person_outline),
            _buildTextField("Yaş", _ageController, Icons.cake_outlined, keyboardType: TextInputType.number),
            _buildTextField("Konum", _countryController, Icons.location_on_outlined),
            
            const SizedBox(height: 32),

            // Relationship Goal
            _buildSectionHeader("İLİŞKİ HEDEFİ"),
            const SizedBox(height: 16),
            _buildRelationshipGoalSelector(),
            
            const SizedBox(height: 32),
            
            // About
            _buildSectionHeader("HAKKINDA"),
            const SizedBox(height: 16),
            _buildTextField("Biyografi", _bioController, Icons.edit_note, maxLines: 4, hint: "Kendinden bahset..."),
            _buildTextField("Meslek", _jobController, Icons.work_outline, hint: "Örn: Yazılım Mühendisi"),
            _buildTextField("Eğitim", _educationController, Icons.school_outlined, hint: "Örn: İstanbul Üniversitesi"),
            
            const SizedBox(height: 32),
            
            // Interests
            _buildSectionHeader("İLGİ ALANLARI (${_selectedInterests.length}/6)"),
            const SizedBox(height: 16),
            _buildInterestsGrid(),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Icon(icon, color: Colors.black, size: 18),
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _photoUrls.length + 1,
        itemBuilder: (context, index) {
          if (index == _photoUrls.length) {
            // Add Photo Button
            return GestureDetector(
              onTap: _pickAndUploadPhoto,
              child: Container(
                width: 100,
                height: 140,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: [AppColors.neoShadowSmall],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: Colors.black, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'EKLE',
                      style: GoogleFonts.outfit(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Photo Item
          return Stack(
            children: [
              Container(
                width: 100,
                height: 140,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: [AppColors.neoShadowSmall],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: _photoUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.black12),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                      ),
                      child: Text(
                        'ANA',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              // Delete Button
              Positioned(
                top: 4,
                right: 20,
                child: GestureDetector(
                  onTap: () => _removePhoto(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                    ),
                    child: const Icon(Icons.close, color: Colors.black, size: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoPicker() {
    return GestureDetector(
      onTap: _pickAndUploadVideo,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: _videoUrl != null
            ? Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_library, color: AppColors.primary, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          "VİDEO YÜKLENDİ",
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _videoUrl = null;
                          _hasChanges = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                        ),
                        child: const Icon(Icons.close, color: Colors.black, size: 18),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_call_outlined, color: Colors.black26, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    "VİDEO PROFİL EKLE (MAX 30SN)",
                    style: GoogleFonts.outfit(
                      color: Colors.black38,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVoicePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: _profileVoiceUrl != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mic, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      "SES KAYDI YÜKLENDİ",
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _profileVoiceUrl = null;
                      _hasChanges = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                    ),
                    child: const Icon(Icons.close, color: Colors.black, size: 18),
                  ),
                ),
              ],
            )
          : _isRecording
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AudioRecorderService.formatDuration(_recordingDuration),
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _cancelRecording,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                            ),
                            child: const Icon(Icons.close, color: Colors.black, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _stopAndSaveRecording,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                              boxShadow: [AppColors.neoShadowSmall],
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: _startRecording,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic_none, color: Colors.black26, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        "SES KAYDET",
                        style: GoogleFonts.outfit(
                          color: Colors.black38,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
        onChanged: (_) => _hasChanges = true,
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          hintText: hint?.toUpperCase(),
          hintStyle: GoogleFonts.outfit(color: Colors.black.withValues(alpha: 0.2), fontSize: 12, fontWeight: FontWeight.w900),
          labelStyle: GoogleFonts.outfit(color: Colors.black.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w900),
          prefixIcon: Icon(icon, color: Colors.black, size: 20),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildInterestsGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _allInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return GestureDetector(
          onTap: () => _toggleInterest(interest),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
              boxShadow: isSelected ? null : [AppColors.neoShadowSmall],
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

  Widget _buildRelationshipGoalSelector() {
    return Column(
      children: _relationshipGoals.map((goal) {
        final isSelected = _selectedRelationshipGoal == goal['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRelationshipGoal = goal['id'];
              _hasChanges = true;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
              boxShadow: isSelected ? null : [AppColors.neoShadowSmall],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['label']!.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        goal['desc']!.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white70 : Colors.black.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
        ),
        title: Text(
          "DEĞİŞİKLİKLER KAYBOLACAK",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        content: Text(
          "YAPTIĞINIZ DEĞİŞİKLİKLER KAYDEDİLMEDİ. ÇIKMAK İSTEDİĞİNİZE EMİN MİSİNİZ?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.black54),
        ),
        actions: [
          TextButton(
            child: Text("İPTAL", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.black38)),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close edit screen
              },
              child: Text("ÇIK", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}
