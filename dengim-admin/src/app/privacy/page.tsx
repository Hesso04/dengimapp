'use client';

import { useState } from 'react';
import Link from 'next/link';

export default function PrivacyPage() {
    const [lang, setLang] = useState<'tr' | 'en'>('tr');

    const texts = {
        tr: {
            title: "Gizlilik Politikası",
            subtitle: "Dengim v1.0.4 ve Sonrası İçin Geçerlidir",
            back: "Ana Sayfaya Dön",
            lastUpdated: "Son Güncelleme",
            sections: [
                {
                    title: "1. Toplanan Kişisel Veriler",
                    content: "Dengim, hizmeti sunabilmek adına kullanıcıların şu bilgilerini işler: Ad/Soyad, profil fotoğrafları, 10 saniyelik ses tanıtım kayıtları, anlık veya arka plan konum verisi (en yakın kullanıcıları eşleştirebilmek amacıyla), yaş, cinsiyet ve uygulama içi etkileşim verileri."
                },
                {
                    title: "2. Ses ve Konum Verilerinin İşlenmesi",
                    content: "Ses kayıtlarınız, profilinizin doğrulanması ve diğer kullanıcılara tanıtılması amacıyla Firestore ve Cloudinary şifreli sunucularında saklanır. Konum verileriniz ise sadece 'yakındaki dengini bulma' ve 'Işınlanma Modu' özelliklerinin doğru çalışabilmesi için işlenir; üçüncü taraflara asla satılmaz."
                },
                {
                    title: "3. Veri Güvenliği ve Altyapı",
                    content: "Birebir sesli görüşmeleriniz Agora.io yüksek kaliteli altyapısı ile sağlanır ve uçtan uca şifrelenir. Profil fotoğraflarınız ve biyometrik verileriniz yapay zeka moderasyon sisteminden (Safe Match) geçirilerek sahte hesapların önüne geçilir."
                },
                {
                    title: "4. Kullanıcı Hakları ve Veri Silme (GDPR / KVKK)",
                    content: "Dilediğiniz zaman uygulama içi ayarlardan veya support@dengim.app adresine yazarak hesabınızı ve tüm ilişkili verilerinizi (fotoğraflar, ses kayıtları, sohbetler) kalıcı olarak sildirebilirsiniz."
                }
            ]
        },
        en: {
            title: "Privacy Policy",
            subtitle: "Effective for Dengim v1.0.4 and above",
            back: "Back to Home",
            lastUpdated: "Last Updated",
            sections: [
                {
                    title: "1. Collected Personal Data",
                    content: "Dengim processes the following user data to provide services: Name, profile photos, 10-second voice introduction recordings, location data (to match nearest users), age, gender, and in-app interaction logs."
                },
                {
                    title: "2. Processing Voice and Location Data",
                    content: "Your voice recordings are stored securely on Firestore and Cloudinary encrypted servers to verify your profile. Location data is processed solely for 'finding nearest match' and 'Teleport Mode'; it is never shared or sold to third parties."
                },
                {
                    title: "3. Data Security and Infrastructure",
                    content: "One-to-one voice calls are powered by Agora.io high-quality infrastructure and are end-to-end encrypted. Profile photos and biometric data are processed via AI moderation (Safe Match) to prevent fake accounts."
                },
                {
                    title: "4. User Rights and Data Erasure (GDPR / KVKK)",
                    content: "You can delete your account and all associated data (photos, voice records, chats) permanently at any time via in-app settings or by contacting us at support@dengim.app."
                }
            ]
        }
    };

    const currentText = texts[lang];

    return (
        <div className="min-h-screen bg-black font-display text-zinc-100">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-black/90 backdrop-blur-xl border-b border-white/5 px-6 py-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <span className="text-2xl font-black bg-gradient-to-r from-[#FF4B55] to-[#ECB613] bg-clip-text text-transparent">DENGİM</span>
                </div>
                
                <div className="flex items-center gap-6">
                    {/* Language Switcher */}
                    <div className="flex bg-zinc-900 rounded-lg p-0.5 border border-white/5 text-xs font-bold">
                        <button 
                            onClick={() => setLang('tr')} 
                            className={`px-3 py-1.5 rounded-md transition-colors ${lang === 'tr' ? 'bg-[#FF4B55] text-black' : 'text-zinc-400 hover:text-white'}`}
                        >
                            TR
                        </button>
                        <button 
                            onClick={() => setLang('en')} 
                            className={`px-3 py-1.5 rounded-md transition-colors ${lang === 'en' ? 'bg-[#FF4B55] text-black' : 'text-zinc-400 hover:text-white'}`}
                        >
                            EN
                        </button>
                    </div>

                    <Link href="/" className="font-bold text-sm text-zinc-400 hover:text-[#FF4B55] transition-colors">{currentText.back}</Link>
                </div>
            </header>

            <main className="pt-32 pb-20 px-6 max-w-4xl mx-auto">
                <div className="bg-zinc-950 border border-white/10 p-8 md:p-12 rounded-[2rem] shadow-2xl relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-80 h-80 bg-[#FF4B55]/5 blur-3xl rounded-full" />
                    
                    <h1 className="text-4xl font-black uppercase text-white mb-2 relative z-10">{currentText.title}</h1>
                    <p className="text-zinc-500 text-sm font-semibold mb-8 relative z-10">{currentText.subtitle}</p>
                    
                    <div className="space-y-8 relative z-10">
                        {currentText.sections.map((section, index) => (
                            <div key={index} className="space-y-3">
                                <h2 className="text-xl font-bold text-white border-l-2 border-[#FF4B55] pl-3">{section.title}</h2>
                                <p className="text-zinc-400 leading-relaxed text-sm">{section.content}</p>
                            </div>
                        ))}
                    </div>

                    <div className="border-t border-white/5 mt-12 pt-6 text-xs text-zinc-500 font-semibold relative z-10">
                        {currentText.lastUpdated}: {new Date().toLocaleDateString(lang === 'tr' ? 'tr-TR' : 'en-US')}
                    </div>
                </div>
            </main>
        </div>
    );
}
