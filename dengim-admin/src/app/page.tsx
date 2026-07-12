import Link from 'next/link';
import Image from 'next/image';

export default function LandingPage() {
    return (
        <div className="min-h-screen bg-black font-display text-white selection:bg-primary selection:text-black">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-md border-b border-white/10 px-6 py-4 flex items-center justify-between">
                <div className="text-3xl font-black tracking-tight text-primary uppercase">
                    DENGIM
                </div>
                <div className="hidden md:flex gap-8 font-bold">
                    <a href="#features" className="text-zinc-300 hover:text-primary transition-colors">Özellikler</a>
                    <a href="#download" className="text-zinc-300 hover:text-primary transition-colors">İndir</a>
                </div>
            </header>

            {/* Hero Section */}
            <main className="pt-32 pb-20 px-6 max-w-7xl mx-auto flex flex-col md:flex-row items-center gap-16">
                <div className="flex-1 space-y-8 z-10">
                    <h1 className="text-6xl md:text-8xl font-black leading-tight uppercase tracking-tight">
                        <span className="block text-white">Kuralları</span>
                        <span className="block text-primary">Sen Belirle</span>
                    </h1>
                    <p className="text-xl md:text-2xl font-medium text-zinc-400 max-w-xl">
                        Klasik eşleşme uygulamalarını unut. DENGIM ile doğrudan ses ve video ile kendini ifade et, dünyanın her yerindeki dengini bul.
                    </p>
                    
                    <div id="download" className="flex flex-col sm:flex-row gap-6 pt-8">
                        <button className="flex items-center justify-center gap-3 bg-zinc-900 text-white px-8 py-4 rounded-2xl font-bold text-lg border border-white/10 hover:border-primary hover:bg-zinc-800 transition-all group">
                            <span className="material-symbols-outlined text-3xl group-hover:text-primary transition-colors">apple</span>
                            <div className="text-left">
                                <div className="text-xs text-zinc-400 font-medium">App Store'dan</div>
                                <div>İndir</div>
                            </div>
                        </button>
                        <button className="flex items-center justify-center gap-3 bg-primary text-black px-8 py-4 rounded-2xl font-bold text-lg hover:bg-primary/90 hover:scale-105 transition-all shadow-[0_0_40px_rgba(236,182,19,0.3)]">
                            <span className="material-symbols-outlined text-3xl">android</span>
                            <div className="text-left">
                                <div className="text-xs text-black/70 font-medium">Google Play'den</div>
                                <div>Edin</div>
                            </div>
                        </button>
                    </div>
                </div>

                <div className="flex-1 relative w-full max-w-md mx-auto perspective-1000 z-0">
                    <div className="absolute inset-0 bg-primary/20 blur-[100px] rounded-full" />
                    <div className="relative w-[320px] h-[650px] bg-zinc-900 rounded-[3rem] border-8 border-zinc-800 p-2 mx-auto rotate-y-[-12deg] rotate-x-[8deg] shadow-2xl transform-gpu hover:rotate-y-0 hover:rotate-x-0 transition-transform duration-700">
                        <div className="w-full h-full bg-black rounded-[2.5rem] overflow-hidden relative border border-white/10">
                            {/* Ekran İçi Temsili UI */}
                            <div className="absolute inset-0 bg-[#0a0a0a] flex flex-col">
                                <div className="h-20 bg-gradient-to-b from-black/80 to-transparent z-10 flex items-center px-6">
                                    <div className="text-primary font-black tracking-widest text-sm">DENGIM</div>
                                </div>
                                <div className="flex-1 m-4 rounded-3xl relative overflow-hidden group">
                                    {/* Placeholder Profile Image with subtle pulse */}
                                    <div className="absolute inset-0 bg-zinc-800 flex items-center justify-center overflow-hidden">
                                        <div className="absolute inset-0 bg-gradient-to-tr from-primary/10 to-transparent mix-blend-overlay" />
                                        <span className="material-symbols-outlined text-8xl text-zinc-700 group-hover:scale-110 transition-transform duration-700">person</span>
                                    </div>
                                    <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black via-black/80 to-transparent p-6 pt-20">
                                        <h3 className="font-black text-2xl text-white mb-1">Ömer, 22</h3>
                                        <div className="flex items-center gap-2 text-primary text-sm font-bold">
                                            <span className="material-symbols-outlined text-sm">location_on</span>
                                            İstanbul • 5 km
                                        </div>
                                    </div>
                                </div>
                                <div className="h-28 pb-6 flex justify-center gap-6 items-center">
                                    <button className="w-14 h-14 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center text-rose-500 hover:bg-rose-500/10 hover:border-rose-500/50 hover:scale-110 transition-all shadow-lg">
                                        <span className="material-symbols-outlined text-3xl">close</span>
                                    </button>
                                    <button className="w-20 h-20 rounded-full bg-primary flex items-center justify-center text-black hover:bg-white hover:scale-110 transition-all shadow-[0_0_30px_rgba(236,182,19,0.4)]">
                                        <span className="material-symbols-outlined text-4xl">favorite</span>
                                    </button>
                                    <button className="w-14 h-14 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center text-sky-400 hover:bg-sky-400/10 hover:border-sky-400/50 hover:scale-110 transition-all shadow-lg">
                                        <span className="material-symbols-outlined text-3xl">star</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            {/* Features Section */}
            <section id="features" className="bg-[#0a0a0a] border-t border-white/5 py-32 relative overflow-hidden">
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-3xl h-[400px] bg-primary/5 blur-[120px] rounded-full pointer-events-none" />
                
                <div className="max-w-7xl mx-auto px-6 relative z-10">
                    <div className="text-center mb-20">
                        <h2 className="text-5xl md:text-7xl font-black uppercase text-white mb-6">Neden <span className="text-primary">Dengim?</span></h2>
                        <p className="text-xl text-zinc-400 font-medium max-w-2xl mx-auto">Güvenli, yenilikçi ve tamamen size özel bir eşleşme deneyimi sunuyoruz.</p>
                    </div>
                    
                    <div className="grid md:grid-cols-3 gap-6">
                        {/* Feature 1 */}
                        <div className="bg-zinc-900/50 backdrop-blur-sm border border-white/10 p-10 rounded-[2rem] hover:bg-zinc-900 transition-colors group">
                            <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center text-primary mb-8 group-hover:scale-110 transition-transform">
                                <span className="material-symbols-outlined text-4xl">videocam</span>
                            </div>
                            <h3 className="text-2xl font-bold mb-4 text-white">Video ve Ses</h3>
                            <p className="text-zinc-400 leading-relaxed">Sahte profillere son! Kullanıcıları direkt video ve ses kayıtlarıyla tanıyın, kim olduklarını gerçekten görün.</p>
                        </div>
                        {/* Feature 2 */}
                        <div className="bg-zinc-900/50 backdrop-blur-sm border border-white/10 p-10 rounded-[2rem] hover:bg-zinc-900 transition-colors group">
                            <div className="w-16 h-16 bg-sky-400/10 rounded-2xl flex items-center justify-center text-sky-400 mb-8 group-hover:scale-110 transition-transform">
                                <span className="material-symbols-outlined text-4xl">travel_explore</span>
                            </div>
                            <h3 className="text-2xl font-bold mb-4 text-white">Işınlanma Modu</h3>
                            <p className="text-zinc-400 leading-relaxed">Sadece kendi şehrinizle sınırlı kalmayın. İstediğiniz ülkeye ışınlanın ve yeni kültürlerden insanlarla tanışın.</p>
                        </div>
                        {/* Feature 3 */}
                        <div className="bg-zinc-900/50 backdrop-blur-sm border border-white/10 p-10 rounded-[2rem] hover:bg-zinc-900 transition-colors group">
                            <div className="w-16 h-16 bg-rose-400/10 rounded-2xl flex items-center justify-center text-rose-400 mb-8 group-hover:scale-110 transition-transform">
                                <span className="material-symbols-outlined text-4xl">security</span>
                            </div>
                            <h3 className="text-2xl font-bold mb-4 text-white">Yapay Zeka Destekli</h3>
                            <p className="text-zinc-400 leading-relaxed">Kötü niyetli mesajlar ve uygunsuz içerikler gelişmiş AI moderasyonumuz sayesinde size ulaşmadan engellenir.</p>
                        </div>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className="bg-black py-12 px-6 border-t border-white/10">
                <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
                    <div className="text-2xl font-black uppercase text-white tracking-widest">
                        DENGIM
                    </div>
                    <div className="flex gap-8 font-medium text-sm text-zinc-400">
                        <Link href="/terms" className="hover:text-primary transition-colors">Kullanım Koşulları</Link>
                        <Link href="/privacy" className="hover:text-primary transition-colors">Gizlilik Politikası</Link>
                    </div>
                    <div className="text-zinc-600 text-sm font-medium">
                        © {new Date().getFullYear()} Dengim. Tüm Hakları Saklıdır.
                    </div>
                </div>
            </footer>
        </div>
    );
}
