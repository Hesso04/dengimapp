# 🔐 DENGİM v1.0.5 — Arka Plan Bildirimleri, Sesli Arama, Grup Sohbeti & Dark Mode Raporu

Dengim projesi için planlanan **v1.0.5 Sürümü** kapsamındaki tüm arka plan push bildirim dinamikleri, Agora sesli arama bağlanıyor çözümü, Grup Sohbeti yeni özelliği, Admin-Kullanıcı geri bildirim sistemi, Dark Mode ekran revizyonları ve profil yönlendirme geliştirmeleri tamamlanmıştır.

---

## 📊 Derleme & Yayın Bilgileri (Güncel)

- **Uygulama Sürüm Kodu**: `33`
- **Uygulama Sürüm Adı**: `1.3.3`
- **Derleme Tipi**: Android App Bundle (Release AAB)
- **Derleme Durumu**: `BUILD SUCCESSFUL` (Zaman: 4 dakika 5 saniye)
- **Oluşturulan Dosya Yolları**:
  - `C:\src\dengim\app-release.aab` (Boyut: 46.8 MB)
  - `C:\src\dengim\android\app\build\outputs\bundle\release\app-release.aab`

---

## 🎯 Tamamlanan Tüm Çalışmaların Özeti

### 1. Google Play Politika & Manifest Güncellemeleri
- `READ_EXTERNAL_STORAGE` izni Android 13+ (API 33+) için daraltıldı ve scoped storage uyumlu hale getirildi.
- Gerek duyulmayan `USE_FULL_SCREEN_INTENT` izni kaldırıldı.
- Konum erişimi öncesi belirgin açıklama sunan `LocationDisclosureDialog` sistemi entegre edildi.
- Android 11+ paket görünürlüğü için `<queries>` yapılandırması tanımlandı.

### 2. UI/UX & Temalandırma (Dark & Light Mode)
- `unified_discover_screen.dart`, `discover_screen.dart`, `watch_and_earn_screen.dart`, `profile_screen.dart` ve `settings_screen.dart` üzerindeki tüm metin, ikon, kart ve buton kontrastları açık ve koyu temalarda okunabilir hale getirildi.
- Keşfet ekranındaki Boost, Rewind (Geri Al) ve Super Like butonları için tek bir modal (`FeatureActionModal`) altında 3 farklı kullanım seçeneği (Kredi ile / Reklam izleyerek / Premium Paket ile) sunuldu.
- Keşfet ekranı premium tanıtım banner'ı Platinum altındaki tüm paketler için dinamik hale getirildi.
- İzle Kazan ekranındaki günlük ödül butonunun devredışı metin rengi yüksek kontrastlı hale getirildi.

### 3. Güvenlik & 4-Haneli PIN Kilidi
- Sorun çıkarabilen Biyometrik Kilit altyapısı kaldırıldı; yerine kullanıcıların kendi 4 haneli PIN kodlarını belirleyip değiştirebilecekleri, uygulama yeniden açıldığında otomatik devreye giren şık ve güvenli `PinLockService` & `PinLockScreen` kuruldu.

### 4. Referans ve Promosyon Kodu Sistemi
- Kullanıcının sadece **1 kez** referans kodu kullanabilmesi için Firestore `hasUsedReferralCode` alanıyla kısıtlama sağlandı.
- Welcome Bonus tetiklendiğinde referans kredilerinin ezilmesi engellendi (`credits: current + 1000`).

### 5. Admin Paneli & Canlı Yayın
- Firestore kurallarına master admin e-postası (`omerbedirhano@gmail.com`) eklendi.
- Admin panelinin `AuthProvider` ve ilk kayıt (`tryCreateAccount`) akışlarındaki permission-denied döngüsü çözüldü.
- Admin paneli ve landing page GitHub Actions üzerinden canlıya (`https://dengim.app` ve `https://dengim.app/admin`) alındı.

---

### 6. 🛠️ Görsel Okunabilirlik, Düzen & Kredi Canlı Senkronizasyon Düzeltmeleri
- **`CreditProvider` Otomatik Senkronizasyon (`credit_provider.dart`)**: `FirebaseAuth.instance.authStateChanges()` dinleyicisi eklenerek kullanıcının giriş yapması veya oturum değiştirmesi durumunda kredilerin ve istatistiklerin anında Firestore'dan çekilmesi sağlandı.
- **`FeatureActionModal` Düzeni (`feature_action_modal.dart`)**: Modal açıldığında metinlerin dikeyde tek harflik sütunlara sıkışma sorunu `ListTile` yerine özel `Expanded` esnek `Row` mimarisi kurularak tamamen çözüldü.
- **Keşfet Mor Bannerı (`discover_screen.dart`)**: Mor banner içerisindeki başlık ("Gold & Platinum Üyelik"), alt yazı ve butonun taşma yapmadan ve okunabilirlik kaybı yaşanmadan basılması sağlandı.
- **İzle & Kazan Kartları (`watch_and_earn_screen.dart`)**: "KREDİLERİNİ KULLAN" ve "PROMOSYON KODU GİR" kartlarındaki eksik/boş kalan başlık, açıklama ve buton içerikleri yüksek kontrastlı metin renkleri ve `mainAxisSize: MainAxisSize.min` sınırlamaları ile düzeltildi.
- **Gold/Platinum Reklam Ödülü Fix (`ad_service_mobile.dart`)**: Premium kullanıcılara özel reklam muafiyeti mantığında `onReward(3)` çağrısı eklenerek kilitlenmeler engellendi.
- **Profil Kartları Metin Ölçekleme (`profile_screen.dart`)**: Profil ekranındaki kredi ve üyelik butonlarında (`_buildMiniBtn`) `FittedBox` küçültme sorunu giderilerek metinlerin tüm ekran genişliklerinde okunabilir boyutta kalması sağlandı.
