import Link from 'next/link';

export default function LandingPage() {
    return (
        <div className="min-h-screen bg-black font-display text-white selection:bg-primary selection:text-black overflow-x-hidden">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-black/70 backdrop-blur-xl border-b border-white/5 px-6 py-4">
                <div className="max-w-7xl mx-auto flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
                            <span className="material-symbols-outlined text-black text-2xl font-bold" style={{ fontVariationSettings: "'FILL' 1" }}>local_fire_department</span>
                        </div>
                        <span className="text-2xl font-black tracking-tight text-white">DENGİM</span>
                    </div>
                    <nav className="hidden md:flex gap-8 font-semibold text-sm">
                        <a href="#features" className="text-zinc-400 hover:text-primary transition-colors">Özellikler</a>
                        <a href="#how-it-works" className="text-zinc-400 hover:text-primary transition-colors">Nasıl Çalışır</a>
                        <a href="#stats" className="text-zinc-400 hover:text-primary transition-colors">Rakamlar</a>
                        <a href="#faq" className="text-zinc-400 hover:text-primary transition-colors">SSS</a>
                    </nav>
                    <a href="#download" className="hidden md:inline-flex px-6 py-2.5 bg-primary text-black font-bold text-sm rounded-xl hover:bg-primary/90 transition-all hover:scale-105">
                        Hemen İndir
                    </a>
                </div>
            </header>

            {/* Hero Section */}
            <main className="relative pt-32 pb-24 px-6 max-w-7xl mx-auto">
                {/* Background glow */}
                <div className="absolute top-20 left-1/2 -translate-x-1/2 w-[800px] h-[600px] bg-primary/8 blur-[180px] rounded-full pointer-events-none" />

                <div className="flex flex-col lg:flex-row items-center gap-16 relative z-10">
                    <div className="flex-1 space-y-8 text-center lg:text-left">
                        <div className="inline-flex items-center gap-2 bg-white/5 border border-white/10 rounded-full px-5 py-2 text-sm font-semibold text-zinc-300">
                            <span className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse" />
                            Türkiye&apos;nin Yeni Nesil Eşleşme Uygulaması
                        </div>

                        <h1 className="text-5xl sm:text-6xl md:text-7xl lg:text-8xl font-black leading-[0.9] uppercase tracking-tight">
                            <span className="block text-white">Ruh Eşini</span>
                            <span className="block text-primary mt-2">Bul.</span>
                        </h1>

                        <p className="text-lg md:text-xl font-medium text-zinc-400 max-w-xl mx-auto lg:mx-0 leading-relaxed">
                            Klasik eşleşme uygulamalarını unut. <strong className="text-white">DENGİM</strong> ile ses ve video aracılığıyla kendini ifade et, yapay zeka destekli eşleşme ile ruh eşini bul.
                        </p>

                        <div id="download" className="flex flex-col sm:flex-row gap-4 pt-4 justify-center lg:justify-start">
                            <button className="flex items-center justify-center gap-3 bg-zinc-900 text-white px-7 py-4 rounded-2xl font-bold text-base border border-white/10 hover:border-primary/50 hover:bg-zinc-800 transition-all group">
                                <svg className="w-7 h-7 group-hover:text-primary transition-colors" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" /></svg>
                                <div className="text-left">
                                    <div className="text-[10px] text-zinc-500 font-medium uppercase tracking-wider">App Store&apos;dan</div>
                                    <div className="text-sm">İndir</div>
                                </div>
                            </button>
                            <button className="flex items-center justify-center gap-3 bg-primary text-black px-7 py-4 rounded-2xl font-bold text-base hover:bg-primary/90 hover:scale-[1.02] transition-all shadow-[0_0_60px_rgba(236,182,19,0.2)]">
                                <svg className="w-7 h-7" viewBox="0 0 24 24" fill="currentColor"><path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.61 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.5,12.92 20.16,13.19L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z" /></svg>
                                <div className="text-left">
                                    <div className="text-[10px] text-black/60 font-medium uppercase tracking-wider">Google Play&apos;den</div>
                                    <div className="text-sm">Edin</div>
                                </div>
                            </button>
                        </div>
                    </div>

                    {/* Phone Mockup */}
                    <div className="flex-1 relative w-full max-w-sm mx-auto">
                        <div className="absolute inset-0 bg-primary/15 blur-[100px] rounded-full scale-75" />
                        <div className="relative w-[280px] sm:w-[300px] h-[580px] sm:h-[620px] bg-zinc-900 rounded-[3rem] border-[6px] border-zinc-800 p-1.5 mx-auto shadow-2xl shadow-primary/10">
                            {/* Notch */}
                            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-28 h-7 bg-zinc-900 rounded-b-2xl z-20" />
                            <div className="w-full h-full bg-[#0a0a0a] rounded-[2.5rem] overflow-hidden relative border border-white/5">
                                {/* App UI Inside Phone */}
                                <div className="absolute inset-0 flex flex-col">
                                    <div className="h-16 flex items-center px-5 pt-8 z-10">
                                        <span className="text-primary font-black tracking-widest text-xs">DENGİM</span>
                                        <div className="flex-1" />
                                        <span className="material-symbols-outlined text-zinc-600 text-xl">notifications</span>
                                    </div>
                                    <div className="flex-1 m-3 rounded-3xl relative overflow-hidden">
                                        <div className="absolute inset-0 bg-gradient-to-br from-zinc-800 via-zinc-900 to-zinc-800 flex items-center justify-center">
                                            <div className="absolute inset-0 bg-gradient-to-tr from-primary/5 to-rose-500/5" />
                                            <span className="material-symbols-outlined text-7xl text-zinc-700" style={{ fontVariationSettings: "'FILL' 1" }}>person</span>
                                        </div>
                                        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black via-black/90 to-transparent p-5 pt-16">
                                            <div className="flex items-center gap-2 mb-1">
                                                <h3 className="font-black text-xl text-white">Elif, 24</h3>
                                                <span className="material-symbols-outlined text-sky-400 text-lg" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
                                            </div>
                                            <div className="flex items-center gap-1.5 text-primary text-xs font-bold">
                                                <span className="material-symbols-outlined text-xs" style={{ fontVariationSettings: "'FILL' 1" }}>location_on</span>
                                                İstanbul • 3 km uzakta
                                            </div>
                                            <div className="flex gap-2 mt-3">
                                                <span className="px-2.5 py-1 bg-white/10 rounded-full text-[10px] font-medium text-zinc-300">🎵 Müzik</span>
                                                <span className="px-2.5 py-1 bg-white/10 rounded-full text-[10px] font-medium text-zinc-300">📚 Kitap</span>
                                                <span className="px-2.5 py-1 bg-white/10 rounded-full text-[10px] font-medium text-zinc-300">✈️ Seyahat</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="h-24 pb-4 flex justify-center gap-5 items-center">
                                        <button className="w-12 h-12 rounded-full bg-zinc-900 border border-zinc-700/50 flex items-center justify-center text-rose-500 shadow-lg">
                                            <span className="material-symbols-outlined text-2xl">close</span>
                                        </button>
                                        <button className="w-16 h-16 rounded-full bg-primary flex items-center justify-center text-black shadow-[0_0_30px_rgba(236,182,19,0.4)]">
                                            <span className="material-symbols-outlined text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>favorite</span>
                                        </button>
                                        <button className="w-12 h-12 rounded-full bg-zinc-900 border border-zinc-700/50 flex items-center justify-center text-sky-400 shadow-lg">
                                            <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            {/* Stats Section */}
            <section id="stats" className="border-y border-white/5 bg-[#050505]">
                <div className="max-w-7xl mx-auto px-6 py-16">
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-4">
                        {[
                            { value: '50K+', label: 'Aktif Kullanıcı', icon: 'group' },
                            { value: '1M+', label: 'Eşleşme', icon: 'favorite' },
                            { value: '4.8', label: 'App Store Puanı', icon: 'star' },
                            { value: '%99', label: 'Memnuniyet', icon: 'sentiment_satisfied' },
                        ].map((stat, i) => (
                            <div key={i} className="text-center group">
                                <div className="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-primary/10 text-primary mb-4 group-hover:scale-110 transition-transform">
                                    <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>{stat.icon}</span>
                                </div>
                                <div className="text-3xl md:text-4xl font-black text-white mb-1">{stat.value}</div>
                                <div className="text-sm text-zinc-500 font-medium">{stat.label}</div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Features Section */}
            <section id="features" className="bg-black py-28 relative overflow-hidden">
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[1000px] h-[600px] bg-primary/5 blur-[200px] rounded-full pointer-events-none" />

                <div className="max-w-7xl mx-auto px-6 relative z-10">
                    <div className="text-center mb-20">
                        <span className="inline-block px-4 py-1.5 bg-primary/10 text-primary text-xs font-bold rounded-full uppercase tracking-wider mb-6">Özellikler</span>
                        <h2 className="text-4xl md:text-6xl font-black uppercase text-white mb-6">
                            Neden <span className="text-primary">Dengim?</span>
                        </h2>
                        <p className="text-lg text-zinc-400 font-medium max-w-2xl mx-auto">
                            Güvenli, yenilikçi ve tamamen size özel bir eşleşme deneyimi sunuyoruz.
                        </p>
                    </div>

                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {[
                            {
                                icon: 'videocam',
                                color: 'primary',
                                title: 'Sesli & Görüntülü Tanışma',
                                desc: 'Sahte profillere son! Kullanıcıları direkt video ve ses kayıtlarıyla tanıyın, kim olduklarını gerçekten görün.'
                            },
                            {
                                icon: 'travel_explore',
                                color: 'sky-400',
                                title: 'Işınlanma Modu',
                                desc: 'Sadece kendi şehrinizle sınırlı kalmayın. İstediğiniz ülkeye ışınlanın ve yeni insanlarla tanışın.'
                            },
                            {
                                icon: 'smart_toy',
                                color: 'violet-400',
                                title: 'Yapay Zeka Eşleşme',
                                desc: 'Gelişmiş AI algoritmamız ilgi alanlarınızı, karakterinizi ve tercihlerinizi analiz ederek size en uygun eşi bulur.'
                            },
                            {
                                icon: 'security',
                                color: 'emerald-400',
                                title: 'Güvenli Ortam',
                                desc: 'Kötü niyetli mesajlar ve uygunsuz içerikler gelişmiş moderasyonumuz sayesinde size ulaşmadan engellenir.'
                            },
                            {
                                icon: 'auto_stories',
                                color: 'rose-400',
                                title: 'Hikâyeler & Anlar',
                                desc: 'Günlük anlarınızı paylaşarak kendinizi doğal bir şekilde ifade edin ve gerçek bağlantılar kurun.'
                            },
                            {
                                icon: 'diamond',
                                color: 'amber-400',
                                title: 'Premium Deneyim',
                                desc: 'Sınırsız beğeni, profil öne çıkarma, süper beğeni ve çok daha fazlasına Premium ile erişin.'
                            },
                        ].map((feature, i) => (
                            <div key={i} className="bg-zinc-900/40 backdrop-blur-sm border border-white/5 p-8 rounded-3xl hover:bg-zinc-900/70 hover:border-white/10 transition-all duration-300 group">
                                <div className={`w-14 h-14 bg-${feature.color}/10 rounded-2xl flex items-center justify-center text-${feature.color} mb-6 group-hover:scale-110 transition-transform`}>
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
            <section id="how-it-works" className="bg-[#050505] border-t border-white/5 py-28">
                <div className="max-w-7xl mx-auto px-6">
                    <div className="text-center mb-20">
                        <span className="inline-block px-4 py-1.5 bg-primary/10 text-primary text-xs font-bold rounded-full uppercase tracking-wider mb-6">3 Adımda</span>
                        <h2 className="text-4xl md:text-6xl font-black uppercase text-white mb-6">Nasıl Çalışır?</h2>
                    </div>

                    <div className="grid md:grid-cols-3 gap-8">
                        {[
                            { step: '01', title: 'Profilini Oluştur', desc: 'Fotoğraf, ses ve video kayıtlarınla kendini en iyi şekilde ifade et.', icon: 'person_add' },
                            { step: '02', title: 'Dengini Keşfet', desc: 'Yapay zeka destekli eşleşme sistemiyle sana en uygun kişileri bul.', icon: 'explore' },
                            { step: '03', title: 'Bağlantı Kur', desc: 'Mesajlaş, sesli veya görüntülü ara ve gerçek bağlantılar oluştur.', icon: 'favorite' },
                        ].map((item, i) => (
                            <div key={i} className="relative text-center group">
                                <div className="text-[80px] font-black text-white/[0.03] absolute top-0 left-1/2 -translate-x-1/2 select-none">{item.step}</div>
                                <div className="relative pt-8">
                                    <div className="w-20 h-20 bg-primary/10 rounded-3xl flex items-center justify-center text-primary mx-auto mb-6 group-hover:bg-primary group-hover:text-black transition-all duration-300">
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
            <section className="bg-black border-t border-white/5 py-28">
                <div className="max-w-4xl mx-auto px-6 text-center">
                    <span className="inline-block px-4 py-1.5 bg-primary/10 text-primary text-xs font-bold rounded-full uppercase tracking-wider mb-10">Kullanıcı Yorumları</span>
                    <blockquote className="text-2xl md:text-3xl font-bold text-white leading-relaxed mb-8">
                        &ldquo;DENGİM sayesinde hayatımın aşkını buldum. Video profil özelliği sayesinde kişiyi tanımadan önce gerçekten görme fırsatı yakaladım. Artık sahte profil endişesi yok!&rdquo;
                    </blockquote>
                    <div className="flex items-center justify-center gap-3">
                        <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center text-primary font-bold">A</div>
                        <div className="text-left">
                            <div className="font-bold text-white text-sm">Ayşe K.</div>
                            <div className="text-zinc-500 text-xs">İstanbul, 26</div>
                        </div>
                    </div>
                </div>
            </section>

            {/* FAQ Section */}
            <section id="faq" className="bg-[#050505] border-t border-white/5 py-28">
                <div className="max-w-3xl mx-auto px-6">
                    <div className="text-center mb-16">
                        <span className="inline-block px-4 py-1.5 bg-primary/10 text-primary text-xs font-bold rounded-full uppercase tracking-wider mb-6">SSS</span>
                        <h2 className="text-4xl md:text-5xl font-black uppercase text-white">Sıkça Sorulan Sorular</h2>
                    </div>

                    <div className="space-y-4">
                        {[
                            { q: 'DENGİM ücretsiz mi?', a: 'Evet! DENGİM\'i ücretsiz olarak indirip kullanabilirsiniz. Ek özellikler için Premium üyelik mevcuttur.' },
                            { q: 'Verilerim güvende mi?', a: 'Kesinlikle. Tüm verileriniz şifrelenerek saklanır ve KVKK uyumlu altyapımızla korunur.' },
                            { q: 'Video profil zorunlu mu?', a: 'Hayır, zorunlu değil. Ancak video profili olan kullanıcılar %70 daha fazla eşleşme alıyor.' },
                            { q: 'Hangi cihazlarda kullanabilirim?', a: 'DENGİM, iOS ve Android cihazlarda kullanılabilir. Web sürümü de yakında geliyor.' },
                        ].map((faq, i) => (
                            <details key={i} className="group bg-zinc-900/40 border border-white/5 rounded-2xl overflow-hidden">
                                <summary className="flex items-center justify-between p-6 cursor-pointer font-bold text-white hover:text-primary transition-colors list-none">
                                    <span>{faq.q}</span>
                                    <span className="material-symbols-outlined text-zinc-500 group-open:rotate-180 transition-transform">expand_more</span>
                                </summary>
                                <div className="px-6 pb-6 text-zinc-400 text-sm leading-relaxed -mt-2">
                                    {faq.a}
                                </div>
                            </details>
                        ))}
                    </div>
                </div>
            </section>

            {/* Final CTA */}
            <section className="bg-black border-t border-white/5 py-28">
                <div className="max-w-4xl mx-auto px-6 text-center">
                    <h2 className="text-4xl md:text-6xl font-black uppercase text-white mb-6">
                        Hazır mısın?
                    </h2>
                    <p className="text-lg text-zinc-400 font-medium max-w-xl mx-auto mb-10">
                        Dengini bulmak için sadece bir adım kaldı. Hemen indir, profilini oluştur ve keşfetmeye başla.
                    </p>
                    <div className="flex flex-col sm:flex-row gap-4 justify-center">
                        <button className="flex items-center justify-center gap-3 bg-primary text-black px-10 py-4 rounded-2xl font-bold text-lg hover:bg-primary/90 hover:scale-[1.02] transition-all shadow-[0_0_80px_rgba(236,182,19,0.2)]">
                            <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>download</span>
                            Uygulamayı İndir
                        </button>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className="bg-[#050505] py-16 px-6 border-t border-white/5">
                <div className="max-w-7xl mx-auto">
                    <div className="grid md:grid-cols-4 gap-12 mb-12">
                        <div className="md:col-span-2">
                            <div className="flex items-center gap-2 mb-4">
                                <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
                                    <span className="material-symbols-outlined text-black text-lg" style={{ fontVariationSettings: "'FILL' 1" }}>local_fire_department</span>
                                </div>
                                <span className="text-xl font-black text-white">DENGİM</span>
                            </div>
                            <p className="text-zinc-500 text-sm leading-relaxed max-w-sm">
                                Türkiye&apos;nin en yenilikçi eşleşme uygulaması. Yapay zeka destekli algoritmalarla ruh eşinizi bulun.
                            </p>
                        </div>
                        <div>
                            <h4 className="font-bold text-white text-sm mb-4 uppercase tracking-wider">Yasal</h4>
                            <div className="space-y-3">
                                <Link href="/terms" className="block text-zinc-500 text-sm hover:text-primary transition-colors">Kullanım Koşulları</Link>
                                <Link href="/privacy" className="block text-zinc-500 text-sm hover:text-primary transition-colors">Gizlilik Politikası</Link>
                                <a href="mailto:destek@dengim.app" className="block text-zinc-500 text-sm hover:text-primary transition-colors">KVKK Başvurusu</a>
                            </div>
                        </div>
                        <div>
                            <h4 className="font-bold text-white text-sm mb-4 uppercase tracking-wider">İletişim</h4>
                            <div className="space-y-3">
                                <a href="mailto:destek@dengim.app" className="block text-zinc-500 text-sm hover:text-primary transition-colors">destek@dengim.app</a>
                                <a href="https://instagram.com/dengimapp" target="_blank" rel="noopener noreferrer" className="block text-zinc-500 text-sm hover:text-primary transition-colors">Instagram</a>
                                <a href="https://twitter.com/dengimapp" target="_blank" rel="noopener noreferrer" className="block text-zinc-500 text-sm hover:text-primary transition-colors">X (Twitter)</a>
                            </div>
                        </div>
                    </div>
                    <div className="border-t border-white/5 pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
                        <div className="text-zinc-600 text-xs font-medium">
                            © {new Date().getFullYear()} Dengim. Tüm Hakları Saklıdır.
                        </div>
                        <div className="text-zinc-700 text-xs">
                            Made with 🔥 in Türkiye
                        </div>
                    </div>
                </div>
            </footer>
        </div>
    );
}
