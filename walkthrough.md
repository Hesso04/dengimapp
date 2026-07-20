# 🔐 DENGİM v1.0.5 — Arka Plan Bildirimleri, Sesli Arama, Grup Sohbeti & Dark Mode Raporu

Dengim projesi için planlanan **v1.0.5 Sürümü** kapsamındaki tüm arka plan push bildirim dinamikleri, Agora sesli arama bağlanıyor çözümü, Grup Sohbeti yeni özelliği, Admin-Kullanıcı geri bildirim sistemi, Dark Mode ekran revizyonları ve profil yönlendirme geliştirmeleri tamamlanmıştır.

---

## 🚀 v1.0.5 Sürümünde Tamamlanan Devasa Özellikler

### 1. 🔔 Arka Plan & Kapalı Uygulama Push Bildirimleri (WhatsApp / Tinder Stili)
- **Gönderen + İçerik Dinamiği:** Mesaj geldiğinde bildirimin başlığında jenerik "Yeni Mesaj" yerine **"Gönderen Kullanıcının Adı"**, içeriğinde ise **"Mesaj Metni"** gösterilmesi sağlandı.
- **Yüksek Öncelikli Kanal:** `functions/index.js` payload yapısı `dengim_messages_channel` yüksek öncelikli Android kanalı ve `contentAvailable: true` iOS APNS ayarlarıyla güncellendi.
- **Isolate Background Handler:** `notification_service.dart` üzerinden `AndroidNotificationChannel` tanımlanarak uygulama kapalıyken bile sesli Heads-Up bildirim basılması sağlandı.

---

### 2. 📞 Sesli Arama "Bağlanıyor" Takılma Hatasının Kökten Çözümü
- **Agora Token Wildcard UID:** `functions/index.js` içindeki `generateAgoraToken` Cloud Function'ında 0 wildcard UID kullanılarak her iki taraf için geçerli genel medya kanal jetonları üretildi.
- **Bağlantı Zaman Aşımı Koruyucusu:** `call_screen.dart` ve `agora_service.dart` üzerinde 10 saniyelik otomatik takılma önleyici (Timeout Guard) enjekte edildi.

---

### 3. 💬 Grup Sohbeti Oluşturma (Yeni Özellik)
- **Grup Sohbet Ekranı (`create_group_chat_screen.dart`):** Kullanıcının eşleştiği kişiler arasından üye seçebileceği, grup adı ve resmi belirleyebileceği neobrutalist/dark mode arayüz eklendi.
- **Mesajlar Başlık Butonu:** Mesajlar (`chats_screen.dart`) sayfasının sağ üstüne **Grup Ekle (+)** ikonu yerleştirildi.
- **Firestore Entegrasyonu:** `chat_service.dart` servisine `createGroupConversation` metodu eklenerek grup mesajlaşmaları desteklendi.

---

### 4. 🛡️ Admin Moderasyon Kararlarının Kullanıcıya Otomatik Bildirimi
- Admin panelinde (`reportService.ts`) bir şikayet veya destek biletinin durumu güncellendiğinde (`resolved`), şikayeti ileten kullanıcının Firestore `users/{userId}/notifications` koleksiyonuna otomatik teşekkür ve bilgilendirme bildirimi düşürüldü.

---

### 5. 🎨 Mobil Uygulama Dark Mode Revizyonları
- **Filtreler Ekranı (`filter_bottom_sheet.dart`):** Beyaz zemin kaldırılıp `#090A0C` derin siyah ve `#121418` kartlara uyarlandı.
- **Profili Düzenle (`edit_profile_screen.dart`):** Ekran ve AppBar beyaz renklerden arındırılıp tam Dark Mode yapıldı.
- **İzle & Kazan (`watch_and_earn_screen.dart`):** Dialog ve Scaffold karanlık moda geçirildi.
- **Engellenen Kullanıcılar (`blocked_users_screen.dart`):** Tüm liste ve silme modalları karanlık temaya uyarlandı.

---

### 6. 🔍 Keşfet Sol Üst Profil İkonu Yönlendirmesi
- Keşfet (`discover_header.dart`) ekranının sol üstündeki kullanıcı avatarına tıklandığında doğrudan kullanıcının kendi profil sayfasına (`ProfileScreen`) geçiş yapması sağlandı.
