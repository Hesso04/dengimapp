'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';

export default function LandingPage() {
    const [showDownloadModal, setShowDownloadModal] = useState(false);
    const [email, setEmail] = useState('');
    const [submitted, setSubmitted] = useState(false);
    const [activeFaq, setActiveFaq] = useState<number | null>(null);

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

    return (
        <div className="min-h-screen bg-[#0A0A0A] font-display text-white selection:bg-[#FF4B55] selection:text-black overflow-x-hidden">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-[#0A0A0A]/85 backdrop-blur-xl border-b border-white/5 px-6 py-4">
                <div className="max-w-7xl mx-auto flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] rounded-xl flex items-center justify-center shadow-lg shadow-[#FF4B55]/20">
                            <span className="material-symbols-outlined text-black text-2xl font-bold" style={{ fontVariationSettings: "'FILL' 1" }}>local_fire_department</span>
                        </div>
                        <span className="text-2xl font-black tracking-tight bg-gradient-to-r from-white to-zinc-400 bg-clip-text text-transparent">DENGİM</span>
                    </div>
                    <nav className="hidden md:flex gap-8 font-semibold text-sm">
                        <a href="#features" className="text-zinc-400 hover:text-[#FF4B55] transition-colors">Özellikler</a>
                        <a href="#how-it-works" className="text-zinc-400 hover:text-[#FF4B55] transition-colors">Nasıl Çalışır</a>
                        <a href="#stats" className="text-zinc-400 hover:text-[#FF4B55] transition-colors">Rakamlar</a>
                        <a href="#faq" className="text-zinc-400 hover:text-[#FF4B55] transition-colors">SSS</a>
                    </nav>
                    <button 
                        onClick={() => setShowDownloadModal(true)}
                        className="px-6 py-2.5 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black font-extrabold text-sm rounded-xl hover:opacity-95 transition-all transform hover:scale-105 active:scale-95 shadow-md shadow-[#FF4B55]/10"
                    >
                        Hemen İndir
                    </button>
                </div>
            </header>

            {/* Hero Section */}
            <main className="relative pt-32 pb-24 px-6 max-w-7xl mx-auto">
                {/* Background glow effects */}
                <div className="absolute top-20 left-1/4 w-[500px] h-[500px] bg-[#FF4B55]/5 blur-[150px] rounded-full pointer-events-none" />
                <div className="absolute bottom-20 right-1/4 w-[500px] h-[500px] bg-[#ECB613]/5 blur-[150px] rounded-full pointer-events-none" />

                <div className="flex flex-col lg:flex-row items-center gap-16 relative z-10">
                    <div className="flex-1 space-y-8 text-center lg:text-left">
                        <div className="inline-flex items-center gap-2 bg-white/5 border border-white/10 rounded-full px-5 py-2 text-sm font-semibold text-zinc-300">
                            <span className="w-2.5 h-2.5 bg-rose-500 rounded-full animate-pulse" />
                            Türkiye&apos;nin İlk Ses Odaklı Eşleşme Uygulaması
                        </div>

                        <h1 className="text-5xl sm:text-6xl md:text-7xl lg:text-8xl font-black leading-[0.9] uppercase tracking-tight">
                            <span className="block text-white">Ruh Eşini</span>
                            <span className="block bg-gradient-to-r from-[#FF4B55] to-[#ECB613] bg-clip-text text-transparent mt-2">Sesiyle Bul.</span>
                        </h1>

                        <p className="text-lg md:text-xl font-medium text-zinc-400 max-w-xl mx-auto lg:mx-0 leading-relaxed">
                            Klasik, yüzeysel eşleşme uygulamalarını unut. <strong className="text-white">DENGİM</strong> ile gerçek ses tonlarıyla kendini ifade et, yapay zeka destekli eşleşme ve Agora ses odaları ile samimi bağlar kur.
                        </p>

                        <div className="flex flex-col sm:flex-row gap-4 pt-4 justify-center lg:justify-start">
                            <button 
                                onClick={() => setShowDownloadModal(true)}
                                className="flex items-center justify-center gap-3 bg-zinc-900/80 backdrop-blur-md text-white px-7 py-4 rounded-2xl font-bold text-base border border-white/10 hover:border-[#FF4B55]/50 hover:bg-zinc-800 transition-all group"
                            >
                                <svg className="w-7 h-7 group-hover:text-[#FF4B55] transition-colors" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" /></svg>
                                <div className="text-left">
                                    <div className="text-[10px] text-zinc-500 font-medium uppercase tracking-wider">App Store&apos;dan</div>
                                    <div className="text-sm">İndir</div>
                                </div>
                            </button>
                            <button 
                                onClick={() => setShowDownloadModal(true)}
                                className="flex items-center justify-center gap-3 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black px-7 py-4 rounded-2xl font-bold text-base hover:opacity-95 hover:scale-[1.02] transition-all shadow-lg shadow-[#FF4B55]/10"
                            >
                                <svg className="w-7 h-7" viewBox="0 0 24 24" fill="currentColor"><path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.61 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.5,12.92 20.16,13.19L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z" /></svg>
                                <div className="text-left">
                                    <div className="text-[10px] text-black/60 font-medium uppercase tracking-wider">Google Play&apos;den</div>
                                    <div className="text-sm">Edin</div>
                                </div>
                            </button>
                        </div>
                    </div>

                    {/* Phone Mockup with Voice UI */}
                    <div className="flex-1 relative w-full max-w-sm mx-auto">
                        <div className="absolute inset-0 bg-[#FF4B55]/10 blur-[120px] rounded-full scale-75 pointer-events-none" />
                        <div className="relative w-[285px] sm:w-[305px] h-[585px] sm:h-[625px] bg-[#141414] rounded-[3rem] border-[6px] border-[#222] p-1.5 mx-auto shadow-2xl shadow-[#FF4B55]/5">
                            {/* Notch */}
                            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-28 h-7 bg-[#222] rounded-b-2xl z-20" />
                            <div className="w-full h-full bg-[#0E0E0E] rounded-[2.5rem] overflow-hidden relative border border-white/5 flex flex-col justify-between">
                                {/* Status bar area */}
                                <div className="h-16 flex items-center justify-between px-6 pt-8 z-10">
                                    <span className="text-[#FF4B55] font-black tracking-widest text-xs">DENGİM</span>
                                    <span className="material-symbols-outlined text-zinc-500 text-xl">notifications</span>
                                           {/* App UI Center Card */}
                                <div className="flex-1 mx-4 my-2 bg-gradient-to-b from-zinc-900 to-zinc-950 rounded-[2rem] border border-white/5 relative overflow-hidden flex flex-col justify-end p-5 shadow-2xl">
                                    {/* Mock User Image with Premium Overlay */}
                                    <div className="absolute inset-0">
                                        <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent z-10" />
                                        <img 
                                            src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80" 
                                            alt="Mock Profile"
                                            className="w-full h-full object-cover"
                                        />
                                    </div>

                                    {/* Match Category Badge */}
                                    <div className="absolute top-4 left-4 z-20 bg-black/60 backdrop-blur-md px-3 py-1 rounded-full border border-white/10 flex items-center gap-1.5">
                                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                                        <span className="text-[10px] font-extrabold text-white tracking-wider uppercase">Çevrimiçi</span>
                                    </div>

                                    {/* Interactive Sound Wave Widget */}
                                    <div className="relative z-20 bg-black/70 backdrop-blur-xl rounded-2xl p-3 border border-white/10 mb-4 flex items-center gap-3 transform hover:scale-[1.02] transition-transform">
                                        <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] flex items-center justify-center text-black">
                                            <span className="material-symbols-outlined text-sm font-bold" style={{ fontVariationSettings: "'FILL' 1" }}>play_arrow</span>
                                        </div>
                                        <div className="flex-1">
                                            <div className="text-[10px] text-zinc-400 font-extrabold uppercase tracking-wider">Ses Odası Tanıtımı</div>
                                            {/* Simulated Audio Wave Animation */}
                                            <div className="flex items-center gap-0.5 h-4 mt-1">
                                                {[3, 6, 8, 4, 9, 5, 7, 3, 6, 8, 4, 9, 5, 7, 3].map((height, idx) => (
                                                    <span 
                                                        key={idx} 
                                                        className="w-1 bg-gradient-to-t from-[#FF4B55] to-[#ECB613] rounded-full" 
                                                        style={{ 
                                                             height: `${height * 10}%`,
                                                             opacity: 0.7 + (idx % 3) * 0.1
                                                        }} 
                                                    />
                                                ))}
                                            </div>
                                        </div>
                                        <span className="text-[9px] text-white font-extrabold bg-[#FF4B55] px-2 py-0.5 rounded-full">0:12</span>
                                    </div>

                                    {/* Profile Metadata */}
                                    <div className="relative z-20 space-y-2">
                                        <div className="flex items-center gap-2">
                                            <h3 className="font-extrabold text-xl text-white">Ceren, 23</h3>
                                            <span className="material-symbols-outlined text-[#FF4B55] text-lg" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
                                        </div>
                                        <div className="flex items-center gap-1 text-zinc-300 text-xs font-semibold">
                                            <span className="material-symbols-outlined text-[12px] text-[#FF4B55]" style={{ fontVariationSettings: "'FILL' 1" }}>location_on</span>
                                            Ankara • 4 km uzakta
                                        </div>
                                        
                                        {/* User tags inside mockup */}
                                        <div className="flex gap-1.5 pt-1">
                                            <span className="text-[9px] bg-white/10 px-2.5 py-1 rounded-full text-white font-semibold">🎵 Müzik</span>
                                            <span className="text-[9px] bg-white/10 px-2.5 py-1 rounded-full text-white font-semibold">✈️ Seyahat</span>
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
                        </div>>
                        </div>
                    </div>
                </div>
            </main>

            {/* Stats Section */}
            <section id="stats" className="border-y border-white/5 bg-[#080808]">
                <div className="max-w-7xl mx-auto px-6 py-16">
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-4">
                        {[
                            { value: '50K+', label: 'Aktif Eşleşen', icon: 'diversity_1' },
                            { value: '1M+', label: 'Sesli Bağlantı', icon: 'mic' },
                            { value: '4.8', label: 'Play Store Puanı', icon: 'grade' },
                            { value: '%99', label: 'Güvenli Moderasyon', icon: 'shield_with_heart' },
                        ].map((stat, i) => (
                            <div key={i} className="text-center group">
                                <div className="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-[#FF4B55]/10 text-[#FF4B55] mb-4 group-hover:scale-110 transition-transform">
                                    <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>{stat.icon}</span>
                                </div>
                                <div className="text-3xl md:text-4xl font-black text-white mb-1">{stat.value}</div>
                                <div className="text-sm text-zinc-500 font-semibold">{stat.label}</div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Features Section */}
            <section id="features" className="bg-[#0A0A0A] py-28 relative overflow-hidden">
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[500px] bg-[#FF4B55]/3 blur-[200px] rounded-full pointer-events-none" />

                <div className="max-w-7xl mx-auto px-6 relative z-10">
                    <div className="text-center mb-20">
                        <span className="inline-block px-4 py-1.5 bg-[#FF4B55]/10 text-[#FF4B55] text-xs font-bold rounded-full uppercase tracking-wider mb-6">Özellikler</span>
                        <h2 className="text-4xl md:text-6xl font-black uppercase text-white mb-6">
                            Neden <span className="bg-gradient-to-r from-[#FF4B55] to-[#ECB613] bg-clip-text text-transparent">Dengim?</span>
                        </h2>
                        <p className="text-lg text-zinc-400 font-medium max-w-2xl mx-auto">
                            Güvenli, ses odaklı ve tamamen yapay zeka destekli eşleşme algoritmasıyla sahte dünyaları geride bırakın.
                        </p>
                    </div>

                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {[
                            {
                                icon: 'mic',
                                color: '[#FF4B55]',
                                title: 'Birebir Sesli Arama',
                                desc: 'Agora.io yüksek kaliteli ses altyapısı ile donatılmış sesli arama sistemi. Sahte profiller ve eski mesajlaşmalar yerine ilk andan itibaren sesin gücüyle tanışın.'
                            },
                            {
                                icon: 'forum',
                                color: '[#ECB613]',
                                title: 'Sesli Sohbet Odaları',
                                desc: 'Grup halinde konuşabileceğiniz, ortak zevklere sahip insanların bir araya gelip ses odalarında muhabbet edebildiği interaktif odalar.'
                            },
                            {
                                icon: 'psychology',
                                color: '[#FF4B55]',
                                title: 'Yapay Zeka Algoritması',
                                desc: 'Gelişmiş AI motorumuz, ses analizlerinizi ve profil ilgi alanlarınızı inceleyerek en uygun ruh eşinizle nokta atışı eşleşme sağlar.'
                            },
                            {
                                icon: 'travel_explore',
                                color: '[#ECB613]',
                                title: 'Işınlanma Modu',
                                desc: 'Sadece yakınınızdakilerle sınırlı kalmayın. İstediğiniz şehre veya ülkeye ışınlanarak global ses odalarına katılın ve yeni insanlarla tanışın.'
                            },
                            {
                                icon: 'safety_check',
                                color: '[#FF4B55]',
                                title: 'Biyometrik Mavi Tik',
                                desc: 'Yapay zeka yüz doğrulama ve moderasyon kuyrukları ile tüm profiller doğrulanır. Sahte ve bot hesaplara asla izin verilmez.'
                            },
                            {
                                icon: 'diamond',
                                color: '[#ECB613]',
                                title: 'Premium Ayrıcalıklar',
                                desc: 'Sınırsız beğeni, profil öne çıkarma, doğrudan sesli arama başlatma ve özel Gold/Platinum abonelik tier avantajları.'
                            },
                        ].map((feature, i) => (
                            <div key={i} className="bg-zinc-900/30 backdrop-blur-sm border border-white/5 p-8 rounded-3xl hover:bg-zinc-900/60 hover:border-white/10 transition-all duration-300 group">
                                <div className="w-14 h-14 bg-white/5 rounded-2xl flex items-center justify-center text-[#FF4B55] mb-6 group-hover:scale-110 transition-transform">
                                    <span className="material-symbols-outlined text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>{feature.icon}</span>
                                </div>
                                <h3 className="text-xl font-bold mb-3 text-white">{feature.title}</h3>
                                <p className="text-zinc-500 leading-relaxed text-sm">{feature.desc}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* How It Works */}
            <section id="how-it-works" className="bg-[#080808] border-t border-white/5 py-28">
                <div className="max-w-7xl mx-auto px-6">
                    <div className="text-center mb-20">
                        <span className="inline-block px-4 py-1.5 bg-[#FF4B55]/10 text-[#FF4B55] text-xs font-bold rounded-full uppercase tracking-wider mb-6">3 Kolay Adımda</span>
                        <h2 className="text-4xl md:text-6xl font-black uppercase text-white mb-6">Nasıl Çalışır?</h2>
                    </div>

                    <div className="grid md:grid-cols-3 gap-12">
                        {[
                            { step: '01', title: 'Ses Profilini Oluştur', desc: 'Fotoğraflarının yanına 10 saniyelik doğal ses kaydını ekle, kendini en iyi şekilde tanımla.', icon: 'record_voice_over' },
                            { step: '02', title: 'Dengini Bul', desc: 'AI motorunun ilgi alanları ve ses tonu eşleşmelerine göre analiz ettiği profilleri keşfet.', icon: 'explore' },
                            { step: '03', title: 'Sesli Bağlantı Kur', desc: 'Hızlıca mesajlaş, beğen ve Agora ses kalitesiyle kesintisiz sesli arama gerçekleştir.', icon: 'phone_in_talk' },
                        ].map((item, i) => (
                            <div key={i} className="relative text-center group">
                                <div className="text-[90px] font-black text-white/[0.02] absolute -top-8 left-1/2 -translate-x-1/2 select-none">{item.step}</div>
                                <div className="relative pt-8">
                                    <div className="w-20 h-20 bg-white/5 rounded-3xl flex items-center justify-center text-[#FF4B55] mx-auto mb-6 group-hover:bg-[#FF4B55] group-hover:text-black transition-all duration-300">
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

            {/* Testimonial */}
            <section className="bg-[#0A0A0A] border-t border-white/5 py-28">
                <div className="max-w-4xl mx-auto px-6 text-center">
                    <span className="inline-block px-4 py-1.5 bg-[#FF4B55]/10 text-[#FF4B55] text-xs font-bold rounded-full uppercase tracking-wider mb-10">Başarı Hikayeleri</span>
                    <blockquote className="text-2xl md:text-3xl font-extrabold text-white leading-relaxed mb-8">
                        &ldquo;Mesajlaşırken kaybolan o sıcaklığı DENGİM sayesinde ilk saniyede hissettim. Birebir ses kaydı dinleme ve ardından yaptığımız kaliteli sesli arama sayesinde, eşimle sanki yan yanaymış gibi bağ kurduk. Kesinlikle harika bir deneyim!&rdquo;
                    </blockquote>
                    <div className="flex items-center justify-center gap-3">
                        <div className="w-12 h-12 bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] rounded-full flex items-center justify-center text-black font-extrabold">M</div>
                        <div className="text-left">
                            <div className="font-bold text-white text-sm">Melis T.</div>
                            <div className="text-zinc-500 text-xs">Ankara, 25</div>
                        </div>
                    </div>
                </div>
            </section>

            {/* FAQ Section */}
            <section id="faq" className="bg-[#080808] border-t border-white/5 py-28">
                <div className="max-w-3xl mx-auto px-6">
                    <div className="text-center mb-16">
                        <span className="inline-block px-4 py-1.5 bg-[#FF4B55]/10 text-[#FF4B55] text-xs font-bold rounded-full uppercase tracking-wider mb-6">SSS</span>
                        <h2 className="text-4xl md:text-5xl font-black uppercase text-white">Sıkça Sorulan Sorular</h2>
                    </div>

                    <div className="space-y-4">
                        {[
                            { q: 'DENGİM uygulamasını kullanmak ücretsiz mi?', a: 'Evet! DENGİM\'i ücretsiz olarak indirip profil oluşturabilir ve keşfetmeye başlayabilirsiniz. Günlük arama sınırını kaldırmak ve ekstra AI eşleşmeleri için Gold ve Platinum paketlerimizi tercih edebilirsiniz.' },
                            { q: 'Sesli profil tanıtımı zorunlu mu?', a: 'Zorunlu olmamakla birlikte, sesli tanıtım yükleyen profillerin eşleşme oranı %80 daha fazladır. İnsanlar sizin gerçek ses tonunuzu duyduğunda çok daha hızlı bağ kurmaktadır.' },
                            { q: 'Kişisel verilerimin güvenliği nasıl sağlanıyor?', a: 'Verileriniz KVKK standartlarına uygun olarak şifreli veri tabanlarımızda korunmaktadır. Sesli ve yazılı görüşmeleriniz uçtan uca şifrelenir ve asla üçüncü şahıslarla paylaşılmaz.' },
                            { q: 'Hangi platformlarda kullanabilirim?', a: 'DENGİM şu an aktif olarak hem iOS (App Store) hem de Android (Google Play Store) cihazlarda çalışmaktadır.' },
                        ].map((faq, i) => (
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
                        Dengini Keşfetmeye Hazır Mısın?
                    </h2>
                    <p className="text-lg text-zinc-400 font-medium max-w-xl mx-auto mb-10">
                        İlk ses tonuyla başlayan samimi dostluklara ve aşklara adım at. Uygulamayı indir ve hemen eşleşmeye başla.
                    </p>
                    <button 
                        onClick={() => setShowDownloadModal(true)}
                        className="inline-flex items-center justify-center gap-3 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black px-10 py-4.5 rounded-2xl font-extrabold text-lg hover:opacity-95 hover:scale-[1.02] active:scale-95 transition-all shadow-xl shadow-[#FF4B55]/10"
                    >
                        <span className="material-symbols-outlined text-2xl font-bold" style={{ fontVariationSettings: "'FILL' 1" }}>download</span>
                        Uygulamayı İndir
                    </button>
                </div>
            </section>

            {/* Footer */}
            <footer className="bg-[#050505] py-16 px-6 border-t border-white/5">
                <div className="max-w-7xl mx-auto">
                    <div className="grid md:grid-cols-4 gap-12 mb-12">
                        <div className="md:col-span-2">
                            <div className="flex items-center gap-3 mb-4">
                                <div className="w-8 h-8 bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] rounded-lg flex items-center justify-center">
                                    <span className="material-symbols-outlined text-black text-lg" style={{ fontVariationSettings: "'FILL' 1" }}>local_fire_department</span>
                                </div>
                                <span className="text-xl font-black text-white">DENGİM</span>
                            </div>
                            <p className="text-zinc-500 text-sm leading-relaxed max-w-sm">
                                Türkiye&apos;nin en yenilikçi ses odaklı eşleşme uygulaması. Ruh eşinizi ilk ses tonuyla bulun.
                            </p>
                        </div>
                        <div>
                            <h4 className="font-bold text-white text-sm mb-4 uppercase tracking-wider">Yasal</h4>
                            <div className="space-y-3 text-sm">
                                <Link href="/terms" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">Kullanım Koşulları</Link>
                                <Link href="/privacy" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">Gizlilik Politikası</Link>
                                <a href="mailto:destek@dengim.app" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">KVKK Başvurusu</a>
                            </div>
                        </div>
                        <div>
                            <h4 className="font-bold text-white text-sm mb-4 uppercase tracking-wider">İletişim</h4>
                            <div className="space-y-3 text-sm">
                                <a href="mailto:destek@dengim.app" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">destek@dengim.app</a>
                                <a href="https://instagram.com/dengimapp" target="_blank" rel="noopener noreferrer" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">Instagram</a>
                                <a href="https://twitter.com/dengimapp" target="_blank" rel="noopener noreferrer" className="block text-zinc-500 hover:text-[#FF4B55] transition-colors">X (Twitter)</a>
                            </div>
                        </div>
                    </div>
                    <div className="border-t border-white/5 pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
                        <div className="text-zinc-600 text-xs font-semibold">
                            © {new Date().getFullYear()} Dengim. Tüm Hakları Saklıdır.
                        </div>
                        <div className="text-zinc-700 text-xs">
                            Made with 🔥 in Türkiye
                        </div>
                    </div>
                </div>
            </footer>

            {/* Download Modal - Completely Working A-Z */}
            {showDownloadModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                    {/* Backdrop */}
                    <div 
                        className="absolute inset-0 bg-black/85 backdrop-blur-md"
                        onClick={() => setShowDownloadModal(false)}
                    />
                    
                    {/* Modal Content */}
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
                        
                        <h3 className="text-2xl font-black text-white mb-2 uppercase">DENGİM YAKINDA MAĞAZALARDA!</h3>
                        <p className="text-zinc-400 text-sm mb-6 leading-relaxed">
                            Uygulamamız çok yakında Google Play Store ve App Store&apos;da yayınlanacaktır. İlk test eden kapalı beta grubuna katılmak için e-postanızı bırakın.
                        </p>

                        {/* Interactive Form */}
                        {submitted ? (
                            <div className="bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 p-4 rounded-2xl text-sm font-bold animate-bounce flex items-center justify-center gap-2">
                                <span className="material-symbols-outlined">check_circle</span>
                                Teşekkürler! Beta listesine başarıyla eklendiniz.
                            </div>
                        ) : (
                            <form onSubmit={handleEmailSubmit} className="space-y-3">
                                <input 
                                    type="email" 
                                    required
                                    placeholder="E-posta adresiniz..."
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="w-full bg-white/5 border border-white/10 focus:border-[#FF4B55]/50 focus:outline-none rounded-xl px-4 py-3 text-sm text-white placeholder-zinc-500 transition-colors"
                                />
                                <button 
                                    type="submit"
                                    className="w-full py-3.5 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black font-extrabold text-sm rounded-xl hover:opacity-95 transition-all shadow-md shadow-[#FF4B55]/10"
                                >
                                    Beta Sürümüne Kaydol
                                </button>
                            </form>
                        )}

                        <div className="mt-8 border-t border-white/5 pt-6">
                            <p className="text-zinc-500 text-xs font-semibold mb-3">YA DA HEMEN ŞİMDİ TEST ETMEK İÇİN</p>
                            <div className="inline-block bg-white p-3 rounded-2xl shadow-inner">
                                {/* Simulated QR Code */}
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
                            <p className="text-zinc-400 text-xs mt-3 font-medium">Kameranızla tarayarak kapalı beta sürümünü indirin.</p>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
