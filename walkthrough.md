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

### 6. 🛠️ Görsel Okunabilirlik, Renk Paleti & Kredi Altyapısı Düzeltmeleri
- **Profil Ekranı Renk Paleti Standartlaştırması**: Tüm modal, kart ve diyalog yüzeyleri Profil ekranı paletiyle (`isDark ? Color(0xFF14161B) : Colors.white`, Kenarlıklar: `Color(0xFF262934)`, Vurgu: `AppColors.primary`) birebir eşlendi.
- **Kredi İle Boost Aktifleştirme Bağlantısı (`discovery_service.dart` & `credit_provider.dart`)**: `DiscoveryService` servisine `activateBoost({int durationMinutes = 30})` metodu yazıldı ve `CreditProvider.spendBoost()` çağrısına bağlandı. Artık 20 kredi harcandığında kullanıcının Firestore `boostUntil` zaman damgası otomatik olarak 30 dakika ileriye güncellenir.
- **Dikey Karakter Kırılmaları & Taşmaların Önlenmesi**: `FeatureActionModal`, `WatchAndEarnScreen` ve `DiscoverScreen` üzerindeki metin blokları `Expanded(Column(children: [Text(..., maxLines: 1, overflow: TextOverflow.ellipsis)]))` mimarisi ile kırılmasız hale getirildi.
- **Ödüllü Reklam Dinamik Teması (`watch_and_earn_screen.dart`)**: Ödül popup'ı light/dark moda duyarlı hale getirildi.
- **`CreditProvider` Canlı Senkronizasyon (`credit_provider.dart`)**: Kullanıcı giriş durumundaki değişikliklerle bakiye ve streak verilerinin canlı akışı otomatik bağlanmıştır.
