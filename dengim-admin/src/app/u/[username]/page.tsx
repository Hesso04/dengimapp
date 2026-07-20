'use client';

import { useParams } from 'next/navigation';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';

export default function UserPublicProfilePage() {
    const params = useParams();
    const username = params?.username as string || 'kullanici';
    const [isMobile, setIsMobile] = useState(false);

    useEffect(() => {
        // Detect mobile user agent
        const checkMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
        setIsMobile(checkMobile);
    }, []);

    const handleOpenApp = () => {
        // Attempt deep link scheme, fallback to store modal or landing page
        window.location.href = `dengim://user/${username}`;
        setTimeout(() => {
            window.location.href = 'https://dengim.app';
        }, 1500);
    };

    return (
        <div className="min-h-screen bg-black font-display text-white selection:bg-[#FF4B55] selection:text-black flex flex-col justify-between p-6">
            {/* Header */}
            <header className="max-w-md mx-auto w-full flex items-center justify-between py-4 border-b border-white/5">
                <Link href="/" className="flex items-center gap-2">
                    <div className="w-8 h-8 relative rounded-lg overflow-hidden flex items-center justify-center bg-zinc-900">
                        <Image src="/logo.png" alt="Dengim Logo" width={32} height={32} className="object-cover" />
                    </div>
                    <span className="text-xl font-black bg-gradient-to-r from-white to-zinc-400 bg-clip-text text-transparent">DENGİM</span>
                </Link>
                <span className="text-xs bg-[#FF4B55]/10 text-[#FF4B55] font-extrabold px-3 py-1 rounded-full uppercase tracking-wider">Profil Daveti</span>
            </header>

            {/* User Profile Card */}
            <main className="max-w-md mx-auto w-full my-auto py-8">
                <div className="bg-zinc-950 border border-white/10 rounded-[2.5rem] p-6 shadow-2xl relative overflow-hidden text-center">
                    <div className="absolute top-0 right-0 w-64 h-64 bg-[#FF4B55]/10 blur-3xl rounded-full" />
                    
                    {/* User Avatar */}
                    <div className="relative w-36 h-36 mx-auto mb-6 rounded-full p-1 bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] shadow-xl">
                        <div className="w-full h-full rounded-full overflow-hidden relative bg-zinc-900">
                            <img 
                                src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80" 
                                alt={username}
                                className="w-full h-full object-cover"
                            />
                        </div>
                        <div className="absolute bottom-1 right-1 bg-black/80 backdrop-blur-md p-1.5 rounded-full border border-white/20 text-[#FF4B55]">
                            <span className="material-symbols-outlined text-lg block" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
                        </div>
                    </div>

                    <h1 className="text-3xl font-black text-white mb-1">@{username}</h1>
                    <p className="text-sm font-semibold text-zinc-400 mb-4">Seni DENGİM&apos;de ses odasına davet ediyor!</p>

                    {/* Simulated Voice Preview */}
                    <div className="bg-black/60 border border-white/10 rounded-2xl p-4 mb-8 flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-[#FF4B55] to-[#ECB613] flex items-center justify-center text-black font-bold">
                            <span className="material-symbols-outlined font-bold">play_arrow</span>
                        </div>
                        <div className="flex-1 text-left">
                            <div className="text-[10px] font-extrabold text-zinc-500 uppercase tracking-wider">Ses Profil Kaydı</div>
                            <div className="flex items-center gap-0.5 h-4 mt-1">
                                {[4, 7, 3, 8, 5, 9, 4, 6, 8, 5, 7, 3, 9, 6].map((h, i) => (
                                    <span key={i} className="w-1 bg-[#FF4B55] rounded-full" style={{ height: `${h * 10}%` }} />
                                ))}
                            </div>
                        </div>
                        <span className="text-xs font-bold text-white bg-[#FF4B55] px-2 py-0.5 rounded-full">0:10</span>
                    </div>

                    {/* Action Button */}
                    <button 
                        onClick={handleOpenApp}
                        className="w-full py-4 bg-gradient-to-r from-[#FF4B55] to-[#ECB613] text-black font-extrabold text-base rounded-2xl shadow-xl shadow-[#FF4B55]/20 hover:scale-[1.02] active:scale-95 transition-all mb-4"
                    >
                        {isMobile ? 'Uygulamada Profili Aç' : 'Uygulamayı İndir ve Bağlan'}
                    </button>

                    <p className="text-xs text-zinc-500 font-medium">
                        Dengim uygulamasını indirerek bu profil ile sesli sohbet etmeye başlayın.
                    </p>
                </div>
            </main>

            {/* Footer */}
            <footer className="max-w-md mx-auto w-full text-center py-4 border-t border-white/5 text-xs text-zinc-600 font-semibold">
                © {new Date().getFullYear()} Dengim. Tüm Hakları Saklıdır.
            </footer>
        </div>
    );
}
