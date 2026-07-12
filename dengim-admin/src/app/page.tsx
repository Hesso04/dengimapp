import Link from 'next/link';

export default function LandingPage() {
    return (
        <div className="min-h-screen bg-background-light font-display text-zinc-900 selection:bg-primary selection:text-black">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-background-light border-b-4 border-black px-6 py-4 flex items-center justify-between">
                <div className="text-3xl font-black tracking-tight text-primary uppercase" style={{ textShadow: '2px 2px 0px #000' }}>
                    DENGIM
                </div>
                <div className="hidden md:flex gap-8 font-bold">
                    <a href="#features" className="hover:text-primary hover:underline underline-offset-4 decoration-4 transition-all">Özellikler</a>
                    <a href="#download" className="hover:text-primary hover:underline underline-offset-4 decoration-4 transition-all">İndir</a>
                </div>
            </header>

            {/* Hero Section */}
            <main className="pt-32 pb-20 px-6 max-w-7xl mx-auto flex flex-col md:flex-row items-center gap-12">
                <div className="flex-1 space-y-8">
                    <h1 className="text-6xl md:text-8xl font-black leading-none uppercase">
                        Kuralları <span className="text-primary" style={{ textShadow: '4px 4px 0px #000' }}>Sen</span> Belirle
                    </h1>
                    <p className="text-xl md:text-2xl font-bold text-zinc-600 border-l-8 border-primary pl-6">
                        Klasik eşleşme uygulamalarını unut. DENGIM ile doğrudan ses ve video ile kendini ifade et, dünyanın her yerindeki dengini bul.
                    </p>
                    
                    <div className="flex flex-col sm:flex-row gap-4 pt-4">
                        <button className="flex items-center justify-center gap-3 bg-black text-white px-8 py-4 rounded-xl font-bold text-lg border-4 border-black hover:-translate-y-1 hover:shadow-[4px_4px_0px_0px_#B2FF33] transition-all">
                            <span className="material-symbols-outlined text-2xl">apple</span>
                            App Store'dan İndir
                        </button>
                        <button className="flex items-center justify-center gap-3 bg-primary text-black px-8 py-4 rounded-xl font-bold text-lg border-4 border-black hover:-translate-y-1 hover:shadow-[4px_4px_0px_0px_#000] transition-all">
                            <span className="material-symbols-outlined text-2xl">android</span>
                            Google Play'den Edin
                        </button>
                    </div>
                </div>

                <div className="flex-1 relative w-full max-w-md mx-auto perspective-1000">
                    <div className="relative w-[300px] h-[600px] bg-zinc-900 rounded-[3rem] border-8 border-black p-2 mx-auto rotate-y-[-10deg] rotate-x-[10deg] shadow-[20px_20px_0px_0px_#B2FF33] transform-gpu hover:rotate-y-0 hover:rotate-x-0 transition-transform duration-500">
                        <div className="w-full h-full bg-black rounded-[2.5rem] overflow-hidden relative">
                            {/* Ekran İçi Temsili UI */}
                            <div className="absolute inset-0 bg-zinc-800 flex flex-col">
                                <div className="h-20 bg-gradient-to-b from-black/50 to-transparent z-10" />
                                <div className="flex-1 bg-zinc-700 m-4 rounded-3xl border-4 border-black relative overflow-hidden">
                                    <div className="absolute inset-0 bg-primary/20 flex items-center justify-center">
                                        <span className="material-symbols-outlined text-6xl text-primary animate-bounce">favorite</span>
                                    </div>
                                    <div className="absolute bottom-4 left-4 right-4 bg-black/80 backdrop-blur text-white p-4 rounded-xl border-2 border-primary">
                                        <h3 className="font-bold text-lg">Ömer, 22</h3>
                                        <p className="text-sm opacity-80">İstanbul • 5 km</p>
                                    </div>
                                </div>
                                <div className="h-24 bg-black/90 flex justify-center gap-6 items-center border-t-2 border-white/10">
                                    <div className="w-12 h-12 rounded-full border-2 border-rose-500 flex items-center justify-center text-rose-500"><span className="material-symbols-outlined">close</span></div>
                                    <div className="w-16 h-16 rounded-full border-4 border-primary flex items-center justify-center text-primary bg-primary/10"><span className="material-symbols-outlined text-3xl">favorite</span></div>
                                    <div className="w-12 h-12 rounded-full border-2 border-sky-500 flex items-center justify-center text-sky-500"><span className="material-symbols-outlined">star</span></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            {/* Features Section */}
            <section id="features" className="bg-black text-white py-24 border-y-4 border-white">
                <div className="max-w-7xl mx-auto px-6">
                    <h2 className="text-5xl font-black uppercase text-center mb-16 text-primary" style={{ textShadow: '4px 4px 0px #fff' }}>Neden Dengim?</h2>
                    <div className="grid md:grid-cols-3 gap-8">
                        {/* Feature 1 */}
                        <div className="bg-zinc-900 border-4 border-primary p-8 rounded-2xl hover:-translate-y-2 transition-transform shadow-[8px_8px_0px_0px_#B2FF33]">
                            <div className="w-16 h-16 bg-primary rounded-xl flex items-center justify-center text-black mb-6 border-2 border-black">
                                <span className="material-symbols-outlined text-3xl">videocam</span>
                            </div>
                            <h3 className="text-2xl font-bold mb-4 uppercase">Video ve Ses</h3>
                            <p className="text-zinc-400 font-medium">Sahte profillere son! Kullanıcıları direkt video ve ses kayıtlarıyla tanıyın, kim olduklarını gerçekten görün.</p>
                        </div>
                        {/* Feature 2 */}
                        <div className="bg-zinc-900 border-4 border-sky-400 p-8 rounded-2xl hover:-translate-y-2 transition-transform shadow-[8px_8px_0px_0px_#38BDF8]">
                            <div className="w-16 h-16 bg-sky-400 rounded-xl flex items-center justify-center text-black mb-6 border-2 border-black">
                                <span className="material-symbols-outlined text-3xl">travel_explore</span>
                            </div>
                            <h3 className="text-2xl font-bold mb-4 uppercase">Işınlanma Modu</h3>
                            <p className="text-zinc-400 font-medium">Sadece kendi şehrinizle sınırlı kalmayın. İstediğiniz ülkeye ışınlanın ve yeni kültürlerden insanlarla tanışın.</p>
                        </div>
                        {/* Feature 3 */}
                        <div className="bg-zinc-900 border-4 border-rose-400 p-8 rounded-2xl hover:-translate-y-2 transition-transform shadow-[8px_8px_0px_0px_#FB7185]">
                            <div className="w-16 h-16 bg-rose-400 rounded-xl flex items-center justify-center text-black mb-6 border-2 border-black">
                                <span className="material-symbols-outlined text-3xl">security</span>
                            </div>
                            <h3 className="text-2xl font-bold mb-4 uppercase">Yapay Zeka Destekli</h3>
                            <p className="text-zinc-400 font-medium">Kötü niyetli mesajlar ve uygunsuz içerikler AI moderasyonumuz sayesinde size ulaşmadan engellenir.</p>
                        </div>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className="bg-background-light py-12 px-6 border-t-4 border-black">
                <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
                    <div className="text-2xl font-black uppercase">
                        DENGIM
                    </div>
                    <div className="flex gap-6 font-bold text-sm md:text-base">
                        <Link href="/terms" className="hover:text-primary transition-colors hover:underline">Kullanım Koşulları</Link>
                        <Link href="/privacy" className="hover:text-primary transition-colors hover:underline">Gizlilik Politikası</Link>
                        <Link href="/admin" className="text-zinc-400 hover:text-black transition-colors">Admin Paneli</Link>
                    </div>
                    <div className="text-zinc-500 font-medium">
                        © {new Date().getFullYear()} Dengim. Tüm Hakları Saklıdır.
                    </div>
                </div>
            </footer>
        </div>
    );
}
