class TierLimits {
  TierLimits._();
  static const int freeDailyLikes = 25;
  static const int freeDailySuperLikes = 0;
  static const int freeMaxPhotos = 4;
  static const int freeRewindsPerDay = 0;
  static const bool freeCanSeeWhoLiked = false;
  static const bool freeCanVideoCall = false;
  static const bool freeCanVoiceCall = false;
  static const bool freeCanSendVoiceMessage = false;
  static const bool freeHasAdvancedFilters = false;
  static const bool freeCanBoost = false;
  static const bool freeShowsAds = true;
  static const bool freeCanUseIncognito = false;
  static const bool freeCanSeeReadReceipts = false;
  static const int freeMaxSwipesPerDay = 25;

  static const int goldDailyLikes = 1000;
  static const int goldDailySuperLikes = 5;
  static const int goldMaxPhotos = 8;
  static const int goldRewindsPerDay = 5;
  static const bool goldCanSeeWhoLiked = false;
  static const bool goldCanVideoCall = false;
  static const bool goldCanVoiceCall = true;
  static const bool goldCanSendVoiceMessage = true;
  static const bool goldHasAdvancedFilters = true;
  static const bool goldCanBoost = true;
  static const bool goldShowsAds = false;
  static const bool goldCanUseIncognito = false;
  static const bool goldCanSeeReadReceipts = true;
  static const int goldMaxSwipesPerDay = 1000;

  static const int platinumDailyLikes = 999999;
  static const int platinumDailySuperLikes = 10;
  static const int platinumMaxPhotos = 12;
  static const int platinumDailyRewindsPerDay = 999999;
  static const bool platinumCanSeeWhoLiked = true;
  static const bool platinumCanVideoCall = true;
  static const bool platinumCanVoiceCall = true;
  static const bool platinumCanSendVoiceMessage = true;
  static const bool platinumHasAdvancedFilters = true;
  static const bool platinumCanBoost = true;
  static const bool platinumShowsAds = false;
  static const bool platinumCanUseIncognito = true;
  static const bool platinumCanSeeReadReceipts = true;
  static const int platinumMaxSwipesPerDay = 999999;

  static bool canSuperLike(String tier) => tier != 'free';
  static bool canUndo(String tier) => tier != 'free';
  static bool canSeeWhoLiked(String tier) => tier == 'platinum';
  static bool canVideoCall(String tier) => tier == 'platinum';
  static bool canVoiceCall(String tier) => tier != 'free';
  static bool canSendVoiceMessage(String tier) => tier != 'free';
  static bool hasAdvancedFilters(String tier) => tier != 'free';
  static bool canBoost(String tier) => tier != 'free';
  static bool showsAds(String tier) => tier == 'free';
  static bool canUseIncognito(String tier) => tier == 'platinum';
  static bool canSeeReadReceipts(String tier) => tier != 'free';

  static int getDailyLikes(String tier) => tier == 'platinum' ? platinumDailyLikes : (tier == 'gold' ? goldDailyLikes : freeDailyLikes);
  static int getDailySuperLikes(String tier) => tier == 'platinum' ? platinumDailySuperLikes : (tier == 'gold' ? goldDailySuperLikes : freeDailySuperLikes);
  static int getMaxPhotos(String tier) => tier == 'platinum' ? platinumMaxPhotos : (tier == 'gold' ? goldMaxPhotos : freeMaxPhotos);
  static int getRewindsPerDay(String tier) => tier == 'platinum' ? platinumDailyRewindsPerDay : (tier == 'gold' ? goldRewindsPerDay : freeRewindsPerDay);
  static int getMaxSwipesPerDay(String tier) => tier == 'platinum' ? platinumMaxSwipesPerDay : (tier == 'gold' ? goldMaxSwipesPerDay : freeMaxSwipesPerDay);

  static String getTierDisplayName(String tier) {
    switch (tier) {
      case 'platinum': return 'Platinum';
      case 'gold': return 'Gold';
      default: return 'Ucretsiz';
    }
  }

  static List<String> getFeaturesFor(String tier) {
    switch (tier) {
      case 'gold':
        return [
          'Gunde 1000 begeni hakki',
          'Gunde 5 Super Like',
          '8 fotograf yukleme',
          'Gunde 5 geri alma',
          'Sesli mesaj gonderme',
          'GelismiS filtreler',
          'Reklamsiz deneyim',
          'Okundu bilgisi',
        ];
      case 'platinum':
        return [
          'Sinirsiz begeni hakki',
          'Gunde 10 Super Like',
          '12 fotograf yukleme',
          'Sinirsiz geri alma',
          'Seni begenenleri gorme',
          'Goruntulu ve sesli arama',
          'Gizli mod (Incognito)',
          'Haftada 3 Boost',
          'Aramalarda oncelik',
          'Reklamsiz deneyim',
        ];
      default:
        return [
          'Gunde 25 begeni hakki',
          '4 fotograf yukleme',
          'Temel arama',
          'Reklam izleyerek kredi kazan',
        ];
    }
  }
}
