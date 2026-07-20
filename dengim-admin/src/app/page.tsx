'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';

export default function LandingPage() {
    const [lang, setLang] = useState<'tr' | 'en'>('tr');
    const [showDownloadModal, setShowDownloadModal] = useState(false);
    const [email, setEmail] = useState('');
    const [submitted, setSubmitted] = useState(false);
    const [activeFaq, setActiveFaq] = useState<number | null>(null);
    const [showCookieBanner, setShowCookieBanner] = useState(false);
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

    useEffect(() => {
        // Check cookie consent
        const consent = localStorage.getItem('dengim_cookie_consent');
        if (!consent) {
            setShowCookieBanner(true);
        }
    }, []);

    const acceptCookies = () => {
        localStorage.setItem('dengim_cookie_consent', 'accepted');
        setShowCookieBanner(false);
    };

    const handleEmailSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (email.trim()) {
            setSubmitted(true);
            setTimeout(() => {
                setEmail('');
                setSubmitted(false);
                setShowDownloadModal(false);
            }, 3000);
        }
    };

    const toggleFaq = (index: number) => {
        setActiveFaq(activeFaq === index ? null : index);
    };

    const translations = {
        tr: {
            features: "Özellikler",
            howItWorks: "Nasıl Çalışır",
            stats: "Rakamlar",
            faq: "SSS",
            download: "Hemen İndir",
            heroBadge: "Türkiye'nin İlk Ses Odaklı Eşleşme Uygulaması",
            heroTitle1: "Ruh Eşini",
            heroTitle2: "Sesiyle Bul.",
            heroSub: "Klasik, yüzeysel eşleşme uygulamalarını unut. DENGİM ile gerçek ses tonlarıyla kendini ifade et, yapay zeka destekli eşleşme ve Agora ses odaları ile samimi bağlar kur.",
            appStoreBtn: "App Store'dan",
            playStoreBtn: "Google Play'den",
            downloadSub: "İndir",
            getItSub: "Edin",
            mockOnline: "Çevrimiçi",
            mockTitle: "Ses Odası Tanıtımı",
            mockUser: "Ceren, 23",
            mockLocation: "Ankara • 4 km uzakta",
            mockTag1: "🎵 Müzik",
            mockTag2: "✈️ Seyahat",
            featuresSectionBadge: "Fark Yaratan Özellikler",
            featuresSectionTitle: "Happn Tarzı Keşif, Ses Odaklı Bağlar",
            featuresSectionSub: "Sadece fotoğraflara bakarak değil, gerçek sesleri ve samimiyeti keşfederek eşleşin.",
            feature1Title: "Sesli Tanışma",
            feature1Desc: "Yazıların ve sahte fotoğrafların ötesine geçin. 10 saniyelik doğal ses profilinizle ruhunuzu yansıtın, Agora kalitesiyle doğrudan konuşmaya başlayın.",
            feature2Title: "Güvenli Eşleşme (Mavi Tik)",
            feature2Desc: "Gelişmiş AI yüz doğrulama ve moderasyon sistemimiz sayesinde tüm profiller biyometrik mavi tik ile onaylanır. Sahte ve bot hesaplara geçit yok.",
            feature3Title: "Işınlanma Modu",
            feature3Desc: "Sadece yakınınızdakilerle sınırlı kalmayın. İstediğiniz şehre veya ülkeye ışınlanarak global ses odalarına katılın ve yeni kültürler keşfedin.",
            howItWorksBadge: "3 Kolay Adımda",
            howItWorksTitle: "Nasıl Çalışır?",
            step1Title: "Ses Profilini Oluştur",
            step1Desc: "En güzel fotoğraflarının yanına 10 saniyelik doğal ses kaydını ekle, kendini tanımla.",
            step2Title: "Dengini Keşfet",
            step2Desc: "AI motorunun ilgi alanları ve ses tonu eşleşmelerine göre analiz ettiği profilleri keşfet.",
            step3Title: "Sesli Sohbet Et",
            step3Desc: "Hızlıca mesajlaş, beğen ve Agora ses kalitesiyle kesintisiz sesli arama gerçekleştir.",
            testimonialBadge: "Başarı Hikayeleri",
            testimonialText: "“Mesajlaşırken kaybolan o sıcaklığı DENGİM sayesinde ilk saniyede hissettim. Birebir ses kaydı dinleme ve ardından yaptığımız kaliteli sesli arama sayesinde, eşimle sanki yan yanaymış gibi bağ kurduk. Kesinlikle harika bir deneyim!”",
            testimonialAuthor: "Melis T.",
            testimonialInfo: "Ankara, 25",
            faqTitle: "Sıkça Sorulan Sorular",
            faqList: [
                { q: 'DENGİM uygulamasını kullanmak ücretsiz mi?', a: 'Evet! DENGİM\'i ücretsiz olarak indirip profil oluşturabilir ve keşfetmeye başlayabilirsiniz. Günlük arama sınırını kaldırmak ve ekstra AI eşleşmeleri için Gold ve Platinum paketlerimizi tercih edebilirsiniz.' },
                { q: 'Sesli profil tanıtımı zorunlu mu?', a: 'Zorunlu olmamakla birlikte, sesli tanıtım yükleyen profillerin eşleşme oranı %80 daha fazladır. İnsanlar sizin gerçek ses tonunuzu duyduğunda çok daha hızlı bağ kurmaktadır.' },
                { q: 'Kişisel verilerimin güvenliği nasıl sağlanıyor?', a: 'Verileriniz v1.0.4 sürümü doğrultusunda KVKK ve GDPR standartlarına uygun olarak şifreli veri tabanlarımızda korunmaktadır. Sesli ve yazılı görüşmeleriniz uçtan uca şifrelenir.' },
                { q: 'Hangi platformlarda kullanabilirim?', a: 'DENGİM şu an aktif olarak hem iOS (App Store) hem de Android (Google Play Store) cihazlarda çalışmaktadır.' }
            ],
            ctaTitle: "Dengini Keşfetmeye Hazır Mısın?",
            ctaSub: "İlk ses tonuyla başlayan samimi dostluklara ve aşklara adım at. Uygulamayı indir ve hemen eşleşmeye başla.",
            ctaBtn: "Uygulamayı İndir",
            cookieText: "Dengim, size daha iyi bir deneyim sunmak için çerezleri kullanır. Sitemizi kullanarak çerez politikamızı kabul etmiş sayılırsınız.",
            cookieAccept: "Kabul Et",
            footerDesc: "Türkiye'nin en yenilikçi ses odaklı eşleşme uygulaması. Ruh eşinizi ilk ses tonuyla bulun.",
            footerLegal: "Yasal",
            footerTerms: "Kullanım Koşulları",
            footerPrivacy: "Gizlilik Politikası",
            footerKvkk: "KVKK Başvurusu",
            footerContact: "İletişim",
            footerRights: "Tüm Hakları Saklıdır.",
            modalTitle: "DENGİM YAKINDA MAĞAZALARDA!",
            modalDesc: "Uygulamamız çok yakında Google Play Store ve App Store'da yayınlanacaktır. İlk test eden kapalı beta grubuna katılmak için e-postanızı bırakın.",
            modalBtn: "Beta Sürümüne Kaydol",
            modalSuccess: "Teşekkürler! Beta listesine başarıyla eklendiniz.",
            modalQr: "YA DA HEMEN ŞİMDİ TEST ETMEK İÇİN",
            modalQrSub: "Kameranızla tarayarak kapalı beta sürümünü indirin."
        },
        en: {
            features: "Features",
            howItWorks: "How It Works",
            stats: "Stats",
            faq: "FAQ",
            download: "Download Now",
            heroBadge: "Turkey's First Voice-Centric Dating App",
            heroTitle1: "Find Your",
            heroTitle2: "Match by Voice.",
            heroSub: "Forget classic, superficial dating apps. Express yourself with real voice tones on DENGİM, build genuine connections with AI-powered matching and Agora audio spaces.",
            appStoreBtn: "Download on",
            playStoreBtn: "Get it on",
            downloadSub: "App Store",
            getItSub: "Google Play",
            mockOnline: "Online",
            mockTitle: "Voice Intro",
            mockUser: "Ceren, 23",
            mockLocation: "Ankara • 4 km away",
            mockTag1: "🎵 Music",
            mockTag2: "✈️ Travel",
            featuresSectionBadge: "Distinguishing Features",
            featuresSectionTitle: "Happn Style Discovery, Voice-Centric Bonds",
            featuresSectionSub: "Match not just by looking at photos, but by discovering real voices and sincerity.",
            feature1Title: "Voice Dating",
            feature1Desc: "Go beyond text and fake photos. Reflect your soul with a 10-second natural voice profile, and start talking directly with high-quality Agora audio.",
            feature2Title: "Safe Match (Blue Tick)",
            feature2Desc: "All profiles are verified with biometric blue ticks using our advanced AI face verification and moderation systems. No fake accounts or bots allowed.",
            feature3Title: "Teleport Mode",
            feature3Desc: "Don't limit yourself to your surroundings. Teleport to any city or country, join global voice spaces, and discover new cultures.",
            howItWorksBadge: "In 3 Easy Steps",
            howItWorksTitle: "How It Works?",
            step1Title: "Create Voice Profile",
            step1Desc: "Add a 10-second natural voice recording next to your best photos, describe yourself.",
            step2Title: "Discover Matches",
            step2Desc: "Explore profiles curated by our AI algorithm based on your interests and voice tone.",
            step3Title: "Start Voice Chat",
            step3Desc: "Send messages, like profiles, and make high-quality Agora voice calls instantly.",
            testimonialBadge: "Success Stories",
            testimonialText: "“I felt the warmth that gets lost in messaging immediately with DENGİM. Listening to the voice intro and then having a high-quality voice call made us connect as if we were side by side. An absolutely amazing experience!”",
            testimonialAuthor: "Melis T.",
            testimonialInfo: "Ankara, 25",
            faqTitle: "Frequently Asked Questions",
            faqList: [
                { q: 'Is DENGİM app free to use?', a: 'Yes! You can download and use DENGİM for free to create a profile and start exploring. You can choose Gold or Platinum packages to remove daily call limits and get extra AI matching.' },
                { q: 'Is a voice introduction profile mandatory?', a: 'Although not mandatory, profiles with voice introductions get an 80% higher match rate. People connect much faster when they hear your real voice tone.' },
                { q: 'How is my personal data secured?', a: 'Your data is secured in our encrypted databases in compliance with KVKK and GDPR standards under the v1.0.4 update. All audio and text communications are end-to-end encrypted.' },
                { q: 'Which platforms can I use it on?', a: 'DENGİM is currently available and fully optimized for both iOS (App Store) and Android (Google Play Store) devices.' }
            ],
            ctaTitle: "Ready to Find Your Match?",
            ctaSub: "Step into sincere friendships and romances starting with the first voice tone. Download the app and start matching now.",
            ctaBtn: "Download App",
            cookieText: "Dengim uses cookies to provide you with a better experience. By using our website, you agree to our cookie policy.",
            cookieAccept: "Accept",
            footerDesc: "Turkey's most innovative voice-centric matchmaking app. Find your soulmate with the power of voice.",
            footerLegal: "Legal",
            footerTerms: "Terms of Service",
            footerPrivacy: "Privacy Policy",
            footerKvkk: "GDPR / KVKK Request",
            footerContact: "Contact",
            footerRights: "All Rights Reserved.",
            modalTitle: "DENGİM IN STORES SOON!",
            modalDesc: "Our application will be available on Google Play Store and App Store very soon. Leave your email to join our closed beta group.",
            modalBtn: "Register for Beta",
            modalSuccess: "Thank you! You have been successfully added to the beta list.",
            modalQr: "OR TEST IT RIGHT NOW",
            modalQrSub: "Scan with your camera to download the closed beta version."
        }
    };

    const t = translations[lang];

    return (
        <div className="min-h-screen bg-black font-display text-white selection:bg-[#FF4B55] selection:text-black overflow-x-hidden">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-black/90 backdrop-blur-xl border-b border-white/5 px-6 py-4">
                <div className="max-w-7xl mx-auto flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 relative rounded-xl overflow-hidden shadow-lg shadow-[#FF4B55]/20 border border-white/10 flex items-center justify-center bg-zinc-900">
                            <Image 
                                src="/logo.png" 
                                alt="Dengim Logo" 
                                width={40} 
                                height={40} 
                                className="object-cover"
                            />
                        </div>
                        <span className="text-2xl font-black tracking-tight bg-gradient-to-r from-white to-zinc-400 bg-clip-text text-transparent">DENGİM</span>
                    </div>

                    <nav className="hidden md:flex gap-8 font-semibold text-sm">
                        <a href="#features" className="text-zinc-400 hover:text-[#FF4B55] transition-colors">{t.features}</a>
                        <a href="#how-it-works" className="text-zinc-400 hover:text-[#FF4B55] transition-colors">{t.howItWorks}</a>
                        <a href="#stats" className="text-zinc-400 hover:text-[#FF4B55] transition-colors">{t.stats}</a>
                        <a href="#faq" className="text-zinc-400 hover:text-[#FF4B55] transition-colors">{t.faq}</a>
                    </nav>

                    <div className="hidden md:flex items-center gap-6">
                        {/* Language Selector */}
                        <div className="flex bg-zinc-900 rounded-lg p-0.5 border border-white/5 text-xs font-bold">
                            <button 
                                onClick={() => setLang('tr')} 
                                className={`px-2.5 py-1.5 rounded-md transition-colors ${lang === 'tr' ? 'bg-[#FF4B55] text-black' : 'text-zinc-400 hover:text-white'}`}
                            >
                                TR
                            </button>
                            <button 
                                onClick={() => setLang('en')} 
                                className={`px-2.5 py-1.5 rounded-md transition-colors ${lang === 'en' ? 'bg-[#FF4B55] text-black' : 'text-zinc-400 hover:text-white'}`}
                            >
                                EN
                            </button>
                        </div>

                        <button 
                            onClick={() => setShowDownloadModal(true)}
                            className="px-6 py-2.5 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black font-extrabold text-sm rounded-xl hover:opacity-95 transition-all transform hover:scale-105 active:scale-95 shadow-md shadow-[#FF4B55]/10"
                        >
                            {t.download}
                        </button>
                    </div>

                    {/* Mobile Menu Button */}
                    <div className="flex items-center gap-3 md:hidden">
                        <div className="flex bg-zinc-900 rounded-lg p-0.5 border border-white/5 text-[10px] font-bold">
                            <button onClick={() => setLang('tr')} className={`px-1.5 py-1 rounded-md ${lang === 'tr' ? 'bg-[#FF4B55] text-black' : 'text-zinc-400'}`}>TR</button>
                            <button onClick={() => setLang('en')} className={`px-1.5 py-1 rounded-md ${lang === 'en' ? 'bg-[#FF4B55] text-black' : 'text-zinc-400'}`}>EN</button>
                        </div>
                        <button 
                            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                            className="text-white hover:text-[#FF4B55] transition-colors"
                        >
                            <span className="material-symbols-outlined text-2xl">{mobileMenuOpen ? 'close' : 'menu'}</span>
                        </button>
                    </div>
                </div>

                {/* Mobile Menu Dropdown */}
                {mobileMenuOpen && (
                    <div className="md:hidden mt-4 pt-4 border-t border-white/5 flex flex-col gap-4 font-semibold text-sm animate-fade-in">
                        <a href="#features" onClick={() => setMobileMenuOpen(false)} className="text-zinc-400 hover:text-[#FF4B55] transition-colors">{t.features}</a>
                        <a href="#how-it-works" onClick={() => setMobileMenuOpen(false)} className="text-zinc-400 hover:text-[#FF4B55] transition-colors">{t.howItWorks}</a>
                        <a href="#stats" onClick={() => setMobileMenuOpen(false)} className="text-zinc-400 hover:text-[#FF4B55] transition-colors">{t.stats}</a>
                        <a href="#faq" onClick={() => setMobileMenuOpen(false)} className="text-zinc-400 hover:text-[#FF4B55] transition-colors">{t.faq}</a>
                        <button 
                            onClick={() => { setMobileMenuOpen(false); setShowDownloadModal(true); }}
                            className="w-full py-2.5 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black font-extrabold text-center rounded-xl"
                        >
                            {t.download}
                        </button>
                    </div>
                )}
            </header>

            {/* Hero Section */}
            <main className="relative pt-32 pb-24 px-6 max-w-7xl mx-auto flex flex-col lg:flex-row items-center gap-16 min-h-[90vh]">
                <div className="absolute top-20 left-1/4 w-[500px] h-[500px] bg-[#FF4B55]/5 blur-[150px] rounded-full pointer-events-none" />
                <div className="absolute bottom-20 right-1/4 w-[500px] h-[500px] bg-[#ECB613]/5 blur-[150px] rounded-full pointer-events-none" />

                <div className="flex-1 space-y-8 text-center lg:text-left relative z-10">
                    <div className="inline-flex items-center gap-2 bg-white/5 border border-white/10 rounded-full px-5 py-2 text-xs sm:text-sm font-semibold text-zinc-300">
                        <span className="w-2.5 h-2.5 bg-rose-500 rounded-full animate-pulse" />
                        {t.heroBadge}
                    </div>

                    <h1 className="text-5xl sm:text-6xl md:text-7xl lg:text-8xl font-black leading-[0.9] uppercase tracking-tight">
                        <span className="block text-white">{t.heroTitle1}</span>
                        <span className="block bg-gradient-to-r from-[#FF4B55] to-[#ECB613] bg-clip-text text-transparent mt-2">{t.heroTitle2}</span>
                    </h1>

                    <p className="text-base sm:text-lg md:text-xl font-medium text-zinc-400 max-w-xl mx-auto lg:mx-0 leading-relaxed">
                        {t.heroSub}
                    </p>

                    <div className="flex flex-col sm:flex-row gap-4 pt-4 justify-center lg:justify-start">
                        <button 
                            onClick={() => setShowDownloadModal(true)}
                            className="flex items-center justify-center gap-3 bg-zinc-900/80 backdrop-blur-md text-white px-7 py-4 rounded-2xl font-bold text-base border border-white/10 hover:border-[#FF4B55]/50 hover:bg-zinc-800 transition-all group"
                        >
                            <svg className="w-7 h-7 group-hover:text-[#FF4B55] transition-colors" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" /></svg>
                            <div className="text-left">
                                <div className="text-[10px] text-zinc-500 font-medium uppercase tracking-wider">{t.appStoreBtn}</div>
                                <div className="text-sm">{t.downloadSub}</div>
                            </div>
                        </button>
                        <button 
                            onClick={() => setShowDownloadModal(true)}
                            className="flex items-center justify-center gap-3 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black px-7 py-4 rounded-2xl font-bold text-base hover:opacity-95 hover:scale-[1.02] transition-all shadow-lg shadow-[#FF4B55]/10"
                        >
                            <svg className="w-7 h-7" viewBox="0 0 24 24" fill="currentColor"><path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.61 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.5,12.92 20.16,13.19L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z" /></svg>
                            <div className="text-left">
                                <div className="text-[10px] text-black/60 font-medium uppercase tracking-wider">{t.playStoreBtn}</div>
                                <div className="text-sm">{t.getItSub}</div>
                            </div>
                        </button>
                    </div>
                </div>

                {/* Happn-Style Phone Mockup */}
                <div className="flex-1 relative w-full max-w-sm mx-auto z-10">
                    <div className="absolute inset-0 bg-[#FF4B55]/10 blur-[120px] rounded-full scale-75 pointer-events-none" />
                    <div className="relative w-[285px] sm:w-[305px] h-[585px] sm:h-[625px] bg-[#141414] rounded-[3rem] border-[6px] border-[#222] p-1.5 mx-auto shadow-2xl shadow-[#FF4B55]/5">
                        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-28 h-7 bg-[#222] rounded-b-2xl z-20" />
                        <div className="w-full h-full bg-[#0E0E0E] rounded-[2.5rem] overflow-hidden relative border border-white/5 flex flex-col justify-between">
                            
                            {/* App Bar Mockup */}
                            <div className="h-16 flex items-center justify-between px-6 pt-8 z-10">
                                <span className="text-[#FF4B55] font-black tracking-widest text-xs">DENGİM</span>
                                <span className="material-symbols-outlined text-zinc-500 text-xl">notifications</span>
                            </div>

                            {/* UI Card */}
                            <div className="flex-1 mx-4 my-2 bg-gradient-to-b from-zinc-900 to-zinc-950 rounded-[2rem] border border-white/5 relative overflow-hidden flex flex-col justify-end p-5 shadow-2xl">
                                <div className="absolute inset-0">
                                    <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent z-10" />
                                    <img 
                                        src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80" 
                                        alt="Mock Profile"
                                        className="w-full h-full object-cover"
                                    />
                                </div>

                                <div className="absolute top-4 left-4 z-20 bg-black/60 backdrop-blur-md px-3 py-1 rounded-full border border-white/10 flex items-center gap-1.5">
                                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                                    <span className="text-[10px] font-extrabold text-white tracking-wider uppercase">{t.mockOnline}</span>
                                </div>

                                {/* Audio Wave Widget */}
                                <div className="relative z-20 bg-black/70 backdrop-blur-xl rounded-2xl p-3 border border-white/10 mb-4 flex items-center gap-3">
                                    <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] flex items-center justify-center text-black">
                                        <span className="material-symbols-outlined text-sm font-bold" style={{ fontVariationSettings: "'FILL' 1" }}>play_arrow</span>
                                    </div>
                                    <div className="flex-1">
                                        <div className="text-[10px] text-zinc-400 font-extrabold uppercase tracking-wider">{t.mockTitle}</div>
                                        <div className="flex items-center gap-0.5 h-4 mt-1">
                                            {[3, 6, 8, 4, 9, 5, 7, 3, 6, 8, 4, 9, 5, 7, 3].map((height, idx) => (
                                                <span 
                                                    key={idx} 
                                                    className="w-1 bg-gradient-to-t from-[#FF4B55] to-[#ECB613] rounded-full animate-pulse" 
                                                    style={{ 
                                                         height: `${height * 10}%`,
                                                         animationDelay: `${idx * 0.1}s`
                                                    }} 
                                                />
                                            ))}
                                        </div>
                                    </div>
                                    <span className="text-[9px] text-white font-extrabold bg-[#FF4B55] px-2 py-0.5 rounded-full">0:12</span>
                                </div>

                                {/* Profile info */}
                                <div className="relative z-20 space-y-2">
                                    <div className="flex items-center gap-2">
                                        <h3 className="font-extrabold text-xl text-white">{t.mockUser}</h3>
                                        <span className="material-symbols-outlined text-[#FF4B55] text-lg" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
                                    </div>
                                    <div className="flex items-center gap-1 text-zinc-300 text-xs font-semibold">
                                        <span className="material-symbols-outlined text-[12px] text-[#FF4B55]" style={{ fontVariationSettings: "'FILL' 1" }}>location_on</span>
                                        {t.mockLocation}
                                    </div>
                                    <div className="flex gap-1.5 pt-1">
                                        <span className="text-[9px] bg-white/10 px-2.5 py-1 rounded-full text-white font-semibold">{t.mockTag1}</span>
                                        <span className="text-[9px] bg-white/10 px-2.5 py-1 rounded-full text-white font-semibold">{t.mockTag2}</span>
                                    </div>
                                </div>
                            </div>

                            {/* Bottom Controls */}
                            <div className="h-20 pb-4 flex justify-center gap-4 items-center bg-black/40 backdrop-blur-md border-t border-white/5 relative z-20">
                                <button className="w-11 h-11 rounded-full bg-zinc-950 border border-white/10 flex items-center justify-center text-zinc-400 hover:text-[#FF4B55] transition-colors shadow-md">
                                    <span className="material-symbols-outlined text-lg">close</span>
                                </button>
                                <button className="w-14 h-14 rounded-full bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] flex items-center justify-center text-black shadow-lg shadow-[#FF4B55]/20 hover:scale-110 active:scale-95 transition-transform">
                                    <span className="material-symbols-outlined text-2xl font-bold" style={{ fontVariationSettings: "'FILL' 1" }}>favorite</span>
                                </button>
                                <button className="w-11 h-11 rounded-full bg-zinc-950 border border-white/10 flex items-center justify-center text-zinc-400 hover:text-[#ECB613] transition-colors shadow-md">
                                    <span className="material-symbols-outlined text-lg">mic</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            {/* Stats section */}
            <section id="stats" className="border-y border-white/5 bg-[#080808]">
                <div className="max-w-7xl mx-auto px-6 py-16">
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
                        {[
                            { value: '50K+', label: t.stats1, icon: 'diversity_1' },
                            { value: '1M+', label: t.stats2, icon: 'mic' },
                            { value: '4.8', label: t.stats3, icon: 'grade' },
                            { value: '%99', label: t.stats4, icon: 'shield_with_heart' },
                        ].map((stat, i) => (
                            <div key={i} className="text-center group">
                                <div className="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-[#FF4B55]/10 text-[#FF4B55] mb-4 group-hover:scale-115 transition-transform">
                                    <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>{stat.icon}</span>
                                </div>
                                <div className="text-3xl md:text-4xl font-black text-white mb-1">{stat.value}</div>
                                <div className="text-sm text-zinc-500 font-semibold">{stat.label}</div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Happn-Style Features Section */}
            <section id="features" className="bg-[#0A0A0A] py-28 relative overflow-hidden">
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[500px] bg-[#FF4B55]/3 blur-[200px] rounded-full pointer-events-none" />

                <div className="max-w-7xl mx-auto px-6 relative z-10">
                    <div className="text-center mb-20">
                        <span className="inline-block px-4 py-1.5 bg-[#FF4B55]/10 text-[#FF4B55] text-xs font-bold rounded-full uppercase tracking-wider mb-6">{t.featuresSectionBadge}</span>
                        <h2 className="text-4xl md:text-6xl font-black uppercase text-white mb-6">
                            {t.featuresSectionTitle}
                        </h2>
                        <p className="text-lg text-zinc-400 font-medium max-w-2xl mx-auto">
                            {t.featuresSectionSub}
                        </p>
                    </div>

                    <div className="grid md:grid-cols-3 gap-8">
                        {/* Feature 1 */}
                        <div className="bg-zinc-950/80 border border-white/5 p-8 rounded-[2.5rem] hover:border-[#FF4B55]/30 hover:bg-zinc-900/40 transition-all duration-500 group flex flex-col justify-between min-h-[380px]">
                            <div className="space-y-6">
                                <div className="w-14 h-14 bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] rounded-2xl flex items-center justify-center text-black font-bold">
                                    <span className="material-symbols-outlined text-3xl">mic</span>
                                </div>
                                <h3 className="text-2xl font-black text-white">{t.feature1Title}</h3>
                                <p className="text-zinc-500 leading-relaxed text-sm">{t.feature1Desc}</p>
                            </div>
                            <div className="pt-6 border-t border-white/5 flex items-center gap-2 text-xs font-bold text-[#FF4B55]">
                                <span>DENGİM Voice Engine</span>
                                <span className="w-1.5 h-1.5 rounded-full bg-[#FF4B55] animate-ping" />
                            </div>
                        </div>

                        {/* Feature 2 */}
                        <div className="bg-zinc-950/80 border border-white/5 p-8 rounded-[2.5rem] hover:border-[#FF4B55]/30 hover:bg-zinc-900/40 transition-all duration-500 group flex flex-col justify-between min-h-[380px]">
                            <div className="space-y-6">
                                <div className="w-14 h-14 bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] rounded-2xl flex items-center justify-center text-black font-bold">
                                    <span className="material-symbols-outlined text-3xl">verified</span>
                                </div>
                                <h3 className="text-2xl font-black text-white">{t.feature2Title}</h3>
                                <p className="text-zinc-500 leading-relaxed text-sm">{t.feature2Desc}</p>
                            </div>
                            <div className="pt-6 border-t border-white/5 flex items-center gap-2 text-xs font-bold text-[#ECB613]">
                                <span>Safe Match AI</span>
                                <span className="w-1.5 h-1.5 rounded-full bg-[#ECB613]" />
                            </div>
                        </div>

                        {/* Feature 3 */}
                        <div className="bg-zinc-950/80 border border-white/5 p-8 rounded-[2.5rem] hover:border-[#FF4B55]/30 hover:bg-zinc-900/40 transition-all duration-500 group flex flex-col justify-between min-h-[380px]">
                            <div className="space-y-6">
                                <div className="w-14 h-14 bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] rounded-2xl flex items-center justify-center text-black font-bold">
                                    <span className="material-symbols-outlined text-3xl">travel_explore</span>
                                </div>
                                <h3 className="text-2xl font-black text-white">{t.feature3Title}</h3>
                                <p className="text-zinc-500 leading-relaxed text-sm">{t.feature3Desc}</p>
                            </div>
                            <div className="pt-6 border-t border-white/5 flex items-center gap-2 text-xs font-bold text-[#FF4B55]">
                                <span>Teleport Mode Active</span>
                                <span className="w-1.5 h-1.5 rounded-full bg-[#FF4B55] animate-ping" />
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* How It Works */}
            <section id="how-it-works" className="bg-[#080808] border-t border-white/5 py-28">
                <div className="max-w-7xl mx-auto px-6">
                    <div className="text-center mb-20">
                        <span className="inline-block px-4 py-1.5 bg-[#FF4B55]/10 text-[#FF4B55] text-xs font-bold rounded-full uppercase tracking-wider mb-6">{t.howItWorksBadge}</span>
                        <h2 className="text-4xl md:text-6xl font-black uppercase text-white mb-6">{t.howItWorks}</h2>
                    </div>

                    <div className="grid md:grid-cols-3 gap-12">
                        {[
                            { step: '01', title: t.step1Title, desc: t.step1Desc, icon: 'record_voice_over' },
                            { step: '02', title: t.step2Title, desc: t.step2Desc, icon: 'explore' },
                            { step: '03', title: t.step3Title, desc: t.step3Desc, icon: 'phone_in_talk' },
                        ].map((item, i) => (
                            <div key={i} className="relative text-center group">
                                <div className="text-[90px] font-black text-white/[0.02] absolute -top-8 left-1/2 -translate-x-1/2 select-none">{item.step}</div>
                                <div className="relative pt-8">
                                    <div className="w-20 h-20 bg-white/5 rounded-3xl flex items-center justify-center text-[#FF4B55] mx-auto mb-6 group-hover:bg-[#FF4B55] group-hover:text-black transition-all duration-350">
                                        <span className="material-symbols-outlined text-4xl" style={{ fontVariationSettings: "'FILL' 1" }}>{item.icon}</span>
                                    </div>
                                    <h3 className="text-xl font-bold text-white mb-3">{item.title}</h3>
                                    <p className="text-zinc-500 text-sm leading-relaxed max-w-xs mx-auto">{item.desc}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Testimonials */}
            <section className="bg-[#0A0A0A] border-t border-white/5 py-28">
                <div className="max-w-4xl mx-auto px-6 text-center">
                    <span className="inline-block px-4 py-1.5 bg-[#FF4B55]/10 text-[#FF4B55] text-xs font-bold rounded-full uppercase tracking-wider mb-10">{t.testimonialBadge}</span>
                    <blockquote className="text-2xl md:text-3xl font-extrabold text-white leading-relaxed mb-8">
                        {t.testimonialText}
                    </blockquote>
                    <div className="flex items-center justify-center gap-3">
                        <div className="w-12 h-12 bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] rounded-full flex items-center justify-center text-black font-extrabold">M</div>
                        <div className="text-left">
                            <div className="font-bold text-white text-sm">{t.testimonialAuthor}</div>
                            <div className="text-zinc-500 text-xs">{t.testimonialInfo}</div>
                        </div>
                    </div>
                </div>
            </section>

            {/* FAQ Section */}
            <section id="faq" className="bg-[#080808] border-t border-white/5 py-28">
                <div className="max-w-3xl mx-auto px-6">
                    <div className="text-center mb-16">
                        <span className="inline-block px-4 py-1.5 bg-[#FF4B55]/10 text-[#FF4B55] text-xs font-bold rounded-full uppercase tracking-wider mb-6">{t.faq}</span>
                        <h2 className="text-4xl md:text-5xl font-black uppercase text-white">{t.faqTitle}</h2>
                    </div>

                    <div className="space-y-4">
                        {t.faqList.map((faq, i) => (
                            <div key={i} className="bg-zinc-900/30 border border-white/5 rounded-2xl overflow-hidden">
                                <button 
                                    onClick={() => toggleFaq(i)}
                                    className="w-full flex items-center justify-between p-6 text-left font-bold text-white hover:text-[#FF4B55] transition-colors"
                                >
                                    <span>{faq.q}</span>
                                    <span className={`material-symbols-outlined text-zinc-500 transition-transform duration-300 ${activeFaq === i ? 'rotate-180' : ''}`}>expand_more</span>
                                </button>
                                <div className={`transition-all duration-300 overflow-hidden ${activeFaq === i ? 'max-h-40 border-t border-white/5 p-6 text-zinc-400' : 'max-h-0'}`}>
                                    <p className="text-sm leading-relaxed">{faq.a}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Final CTA */}
            <section className="bg-[#0A0A0A] border-t border-white/5 py-28 relative">
                <div className="max-w-4xl mx-auto px-6 text-center relative z-10">
                    <h2 className="text-4xl md:text-6xl font-black uppercase text-white mb-6">
                        {t.ctaTitle}
                    </h2>
                    <p className="text-lg text-zinc-400 font-medium max-w-xl mx-auto mb-10">
                        {t.ctaSub}
                    </p>
                    <button 
                        onClick={() => setShowDownloadModal(true)}
                        className="inline-flex items-center justify-center gap-3 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black px-10 py-4.5 rounded-2xl font-extrabold text-lg hover:opacity-95 hover:scale-[1.02] active:scale-95 transition-all shadow-xl shadow-[#FF4B55]/10"
                    >
                        <span className="material-symbols-outlined text-2xl font-bold" style={{ fontVariationSettings: "'FILL' 1" }}>download</span>
                        {t.ctaBtn}
                    </button>
                </div>
            </section>

            {/* Footer */}
            <footer className="bg-[#050505] py-16 px-6 border-t border-white/5">
                <div className="max-w-7xl mx-auto">
                    <div className="grid md:grid-cols-4 gap-12 mb-12">
                        <div className="md:col-span-2">
                            <div className="flex items-center gap-3 mb-4">
                                <div className="w-8 h-8 relative rounded-lg overflow-hidden flex items-center justify-center bg-zinc-900">
                                    <Image 
                                        src="/logo.png" 
                                        alt="Dengim Logo" 
                                        width={32} 
                                        height={32} 
                                        className="object-cover"
                                    />
                                </div>
                                <span className="text-xl font-black text-white">DENGİM</span>
                            </div>
                            <p className="text-zinc-500 text-sm leading-relaxed max-w-sm">
                                {t.footerDesc}
                            </p>
                        </div>
                        <div>
                            <h4 className="font-bold text-white text-sm mb-4 uppercase tracking-wider">{t.footerLegal}</h4>
                            <div className="space-y-3 text-sm">
                                <Link href="/terms" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">{t.footerTerms}</Link>
                                <Link href="/privacy" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">{t.footerPrivacy}</Link>
                                <a href="mailto:support@dengim.app" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">{t.footerKvkk}</a>
                            </div>
                        </div>
                        <div>
                            <h4 className="font-bold text-white text-sm mb-4 uppercase tracking-wider">{t.footerContact}</h4>
                            <div className="space-y-3 text-sm">
                                <a href="mailto:support@dengim.app" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">support@dengim.app</a>
                                <a href="https://instagram.com/dengimapp" target="_blank" rel="noopener noreferrer" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">Instagram</a>
                                <a href="https://twitter.com/dengimapp" target="_blank" rel="noopener noreferrer" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">X (Twitter)</a>
                            </div>
                        </div>
                    </div>
                    <div className="border-t border-white/5 pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
                        <div className="text-zinc-600 text-xs font-semibold">
                            © {new Date().getFullYear()} Dengim. {t.footerRights}
                        </div>
                        <div className="text-zinc-700 text-xs">
                            Made with 🔥 in Türkiye
                        </div>
                    </div>
                </div>
            </footer>

            {/* Cookie Consent Banner */}
            {showCookieBanner && (
                <div className="fixed bottom-6 left-6 right-6 md:left-auto md:max-w-md z-50 bg-zinc-950/80 backdrop-blur-xl border border-white/10 p-5 rounded-3xl shadow-2xl flex flex-col sm:flex-row items-center gap-4 animate-slide-up">
                    <p className="text-xs text-zinc-400 leading-relaxed text-center sm:text-left">
                        {t.cookieText}
                    </p>
                    <button 
                        onClick={acceptCookies}
                        className="w-full sm:w-auto px-6 py-2.5 bg-white text-black font-extrabold text-xs rounded-xl hover:bg-zinc-200 transition-colors whitespace-nowrap"
                    >
                        {t.cookieAccept}
                    </button>
                </div>
            )}

            {/* Download Modal */}
            {showDownloadModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                    <div 
                        className="absolute inset-0 bg-black/85 backdrop-blur-md"
                        onClick={() => setShowDownloadModal(false)}
                    />
                    
                    <div className="relative bg-[#111] border border-white/10 w-full max-w-md rounded-[2.5rem] p-8 text-center shadow-2xl overflow-hidden">
                        <div className="absolute -top-10 -right-10 w-40 h-40 bg-[#FF4B55]/10 blur-2xl rounded-full" />
                        <div className="absolute -bottom-10 -left-10 w-40 h-40 bg-[#ECB613]/10 blur-2xl rounded-full" />

                        <div className="flex justify-end -mt-4 -mr-4 mb-2">
                            <button 
                                onClick={() => setShowDownloadModal(false)}
                                className="w-8 h-8 rounded-full bg-white/5 hover:bg-white/10 flex items-center justify-center text-zinc-400 hover:text-white transition-colors"
                            >
                                <span className="material-symbols-outlined text-lg">close</span>
                            </button>
                        </div>

                        <span className="material-symbols-outlined text-5xl text-[#FF4B55] mb-4" style={{ fontVariationSettings: "'FILL' 1" }}>apk_install</span>
                        
                        <h3 className="text-2xl font-black text-white mb-2 uppercase">{t.modalTitle}</h3>
                        <p className="text-zinc-400 text-sm mb-6 leading-relaxed">
                            {t.modalDesc}
                        </p>

                        {submitted ? (
                            <div className="bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 p-4 rounded-2xl text-sm font-bold animate-bounce flex items-center justify-center gap-2">
                                <span className="material-symbols-outlined">check_circle</span>
                                {t.modalSuccess}
                            </div>
                        ) : (
                            <form onSubmit={handleEmailSubmit} className="space-y-3">
                                <input 
                                    type="email" 
                                    required
                                    placeholder={lang === 'tr' ? 'E-posta adresiniz...' : 'Your email address...'}
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="w-full bg-white/5 border border-white/10 focus:border-[#FF4B55]/50 focus:outline-none rounded-xl px-4 py-3 text-sm text-white placeholder-zinc-500 transition-colors"
                                />
                                <button 
                                    type="submit"
                                    className="w-full py-3.5 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black font-extrabold text-sm rounded-xl hover:opacity-95 transition-all shadow-md shadow-[#FF4B55]/10"
                                >
                                    {t.modalBtn}
                                </button>
                            </form>
                        )}

                        <div className="mt-8 border-t border-white/5 pt-6">
                            <p className="text-zinc-500 text-xs font-semibold mb-3">{t.modalQr}</p>
                            <div className="inline-block bg-white p-3 rounded-2xl shadow-inner">
                                <div className="w-32 h-32 bg-zinc-950 flex flex-col items-center justify-center p-2 rounded-xl">
                                    <div className="grid grid-cols-4 gap-1.5 w-full h-full opacity-80">
                                        {Array.from({ length: 16 }).map((_, idx) => (
                                            <div 
                                                key={idx} 
                                                className={`rounded-sm ${(idx * 7 + 3) % 2 === 0 ? 'bg-[#FF4B55]' : 'bg-[#ECB613]'}`} 
                                                style={{ opacity: (idx * 11 % 5 + 4) / 10 }}
                                            />
                                        ))}
                                    </div>
                                </div>
                            </div>
                            <p className="text-zinc-400 text-xs mt-3 font-medium">{t.modalQrSub}</p>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
