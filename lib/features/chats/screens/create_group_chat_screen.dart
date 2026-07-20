import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/log_service.dart';
import '../services/chat_service.dart';

class CreateGroupChatScreen extends StatefulWidget {
  const CreateGroupChatScreen({super.key});

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  final _groupNameController = TextEditingController();
  final List<String> _selectedUserIds = [];
  List<Map<String, dynamic>> _matchedUsers = [];
  bool _loadingUsers = true;
  bool _creatingGroup = false;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatches() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .limit(50)
          .get();

      final List<Map<String, dynamic>> users = [];
      for (var doc in usersSnap.docs) {
        if (doc.id != currentUserId) {
          final data = doc.data();
          users.add({
            'id': doc.id,
            'name': data['name'] ?? data['fullName'] ?? 'Dengim Kullanıcısı',
            'avatar': (data['photoUrls'] as List?)?.firstOrNull ?? data['imageUrl'] ?? '',
          });
        }
      }

      setState(() {
        _matchedUsers = users;
        _loadingUsers = false;
      });
    } catch (e) {
      LogService.e("Failed to fetch matches for group chat: $e");
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _handleCreateGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir grup adı girin.')),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 1 üye seçmelisiniz.')),
      );
      return;
    }

    setState(() => _creatingGroup = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final allMemberIds = [currentUserId, ..._selectedUserIds];
      await ChatService().createGroupConversation(
        groupName: groupName,
        memberIds: allMemberIds,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$groupName" grup sohbeti başarıyla oluşturuldu!')),
        );
      }
    } catch (e) {
      LogService.e("Group creation failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grup sohbeti oluşturulamadı.')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingGroup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121418),
        title: Text(
          'Grup Sohbeti Oluştur',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingUsers
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Group Name Input Card
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF121418),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GRUP BİLGİLERİ',
                        style: GoogleFonts.manrope(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _groupNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Grup Adı (Örn: Sohbet ve Müzik Odası)',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          prefixIcon: const Icon(Icons.groups, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Selected Members Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ÜYE SEÇİMİ (${_selectedUserIds.length} Seçildi)',
                        style: GoogleFonts.manrope(
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Members List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _matchedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _matchedUsers[index];
                      final isSelected = _selectedUserIds.contains(user['id']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : const Color(0xFF121418),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[800],
                            backgroundImage: user['avatar'].isNotEmpty ? NetworkImage(user['avatar']) : null,
                            child: user['avatar'].isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                          ),
                          title: Text(
                            user['name'],
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            activeColor: AppColors.primary,
                            checkColor: Colors.black,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedUserIds.add(user['id']);
                                } else {
                                  _selectedUserIds.remove(user['id']);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedUserIds.remove(user['id']);
                              } else {
                                _selectedUserIds.add(user['id']);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Create Button
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF121418),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _creatingGroup ? null : _handleCreateGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _creatingGroup
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : Text(
                              'GRUP SOHBETİ BAŞLAT',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
