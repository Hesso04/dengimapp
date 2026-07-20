'use client';

import { useState, useEffect } from 'react';
import { useAdminStore } from '@/store/adminStore';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { AnalyticsService } from '@/services/analyticsService';

const pageTitles: Record<string, string> = {
    '/admin': 'Dashboard',
    '/admin/users': 'Kullanıcı Yönetimi',
    '/admin/moderation': 'Moderasyon',
    '/admin/reports': 'Raporlar & Şikayetler',
    '/admin/premium': 'Premium Yönetimi',
    '/admin/analytics': 'Analitik & Raporlama',
    '/admin/notifications': 'Bildirim Merkezi',
    '/admin/resources': 'İçerik & Kaynak Yönetimi',
    '/admin/support': 'Destek Sistemi',
    '/admin/settings': 'Ayarlar',
};

export function Header() {
    const pathname = usePathname();
    const { toggleSidebar, currentAdmin } = useAdminStore();
    const [showNotifications, setShowNotifications] = useState(false);
    const [systemCounts, setSystemCounts] = useState({ reports: 0, moderation: 0, support: 0 });

    useEffect(() => {
        const fetchSystemCounts = async () => {
            try {
                const counts = await AnalyticsService.getSystemCounts();
                setSystemCounts(counts);
            } catch (e) {
                console.error("Header system counts error:", e);
            }
        };

        fetchSystemCounts();
        const interval = setInterval(fetchSystemCounts, 30000); // 30 sn periyodik kontrol
        return () => clearInterval(interval);
    }, []);

    const pageTitle = Object.entries(pageTitles).find(
        ([path]) => pathname === path || (path !== '/admin' && pathname.startsWith(path))
    )?.[1] || 'Dashboard';

    const totalAlerts = systemCounts.reports + systemCounts.moderation + systemCounts.support;

    return (
        <header className="sticky top-0 z-30 h-16 bg-background-dark/95 backdrop-blur-md border-b border-primary/10 px-4 md:px-6 flex items-center justify-between">
            {/* Left Section */}
            <div className="flex items-center gap-4">
                <button
                    onClick={toggleSidebar}
                    className="p-2 text-primary hover:bg-white/5 rounded-lg transition-colors md:hidden"
                >
                    <span className="material-symbols-outlined">menu</span>
                </button>
                <div>
                    <h1 className="text-lg font-bold text-white">{pageTitle}</h1>
                    <div className="hidden md:flex items-center text-xs text-slate-400 gap-1">
                        <Link href="/admin" className="hover:text-primary">Dashboard</Link>
                        {pathname !== '/admin' && (
                            <>
                                <span>/</span>
                                <span className="text-primary">{pageTitle}</span>
                            </>
                        )}
                    </div>
                </div>
            </div>

            {/* Right Section */}
            <div className="flex items-center gap-3">
                {/* Search */}
                <div className="hidden md:flex items-center h-10 bg-white/5 rounded-xl border border-white/10 px-3 gap-2 w-64">
                    <span className="material-symbols-outlined text-white/40 text-lg">search</span>
                    <input
                        type="text"
                        placeholder="Ara..."
                        className="flex-1 bg-transparent border-none text-sm text-white placeholder:text-white/30 focus:outline-none"
                    />
                    <kbd className="hidden lg:inline-flex px-1.5 py-0.5 text-[10px] font-mono bg-white/10 rounded text-white/50">⌘K</kbd>
                </div>

                {/* Server Status */}
                <div className="hidden lg:flex items-center gap-2 px-3 py-2 bg-emerald-500/10 rounded-xl border border-emerald-500/20">
                    <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                    <span className="text-xs font-medium text-emerald-400">Canlı Sistem</span>
                </div>

                {/* Notifications Dropdown Container */}
                <div className="relative">
                    <button
                        onClick={() => setShowNotifications(!showNotifications)}
                        className="relative p-2.5 text-slate-400 hover:text-primary hover:bg-white/5 rounded-xl transition-colors"
                    >
                        <span className="material-symbols-outlined">notifications</span>
                        {totalAlerts > 0 && (
                            <span className="absolute top-1.5 right-1.5 flex h-4 w-4">
                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-500 opacity-75" />
                                <span className="relative inline-flex items-center justify-center h-4 w-4 rounded-full bg-rose-500 text-[9px] font-bold text-white">
                                    {totalAlerts > 9 ? '9+' : totalAlerts}
                                </span>
                            </span>
                        )}
                    </button>

                    {/* Quick Notifications Popover */}
                    {showNotifications && (
                        <>
                            <div className="fixed inset-0 z-40" onClick={() => setShowNotifications(false)} />
                            <div className="absolute right-0 mt-2 w-80 bg-zinc-950 border border-white/10 rounded-2xl shadow-2xl z-50 overflow-hidden animate-slide-up">
                                <div className="p-4 border-b border-white/5 flex items-center justify-between bg-surface-dark">
                                    <h3 className="text-sm font-bold text-white flex items-center gap-2">
                                        <span className="material-symbols-outlined text-primary text-base">notifications_active</span>
                                        İncelenecek Bildirimler
                                    </h3>
                                    <span className="text-xs px-2 py-0.5 rounded-full bg-primary/20 text-primary font-extrabold">
                                        {totalAlerts} Bekleyen
                                    </span>
                                </div>

                                <div className="p-2 space-y-1">
                                    {/* Reports Alert */}
                                    <Link
                                        href="/admin/reports"
                                        onClick={() => setShowNotifications(false)}
                                        className="flex items-center justify-between p-3 rounded-xl hover:bg-white/5 transition-colors group"
                                    >
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-lg bg-rose-500/10 text-rose-500 flex items-center justify-center">
                                                <span className="material-symbols-outlined text-base">report</span>
                                            </div>
                                            <div>
                                                <p className="text-xs font-bold text-white group-hover:text-primary transition-colors">Bekleyen Şikayetler</p>
                                                <p className="text-[10px] text-zinc-400">İnceleme gerektiren kullanıcı raporları</p>
                                            </div>
                                        </div>
                                        <span className="text-xs font-extrabold px-2 py-0.5 rounded-full bg-rose-500/20 text-rose-400">
                                            {systemCounts.reports}
                                        </span>
                                    </Link>

                                    {/* Moderation Alert */}
                                    <Link
                                        href="/admin/moderation"
                                        onClick={() => setShowNotifications(false)}
                                        className="flex items-center justify-between p-3 rounded-xl hover:bg-white/5 transition-colors group"
                                    >
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-lg bg-amber-500/10 text-amber-500 flex items-center justify-center">
                                                <span className="material-symbols-outlined text-base">verified_user</span>
                                            </div>
                                            <div>
                                                <p className="text-xs font-bold text-white group-hover:text-primary transition-colors">Mavi Tik / Moderasyon</p>
                                                <p className="text-[10px] text-zinc-400">Fotoğraf & biyometri doğrulama</p>
                                            </div>
                                        </div>
                                        <span className="text-xs font-extrabold px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-400">
                                            {systemCounts.moderation}
                                        </span>
                                    </Link>

                                    {/* Support Alert */}
                                    <Link
                                        href="/admin/support"
                                        onClick={() => setShowNotifications(false)}
                                        className="flex items-center justify-between p-3 rounded-xl hover:bg-white/5 transition-colors group"
                                    >
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-lg bg-blue-500/10 text-blue-500 flex items-center justify-center">
                                                <span className="material-symbols-outlined text-base">support_agent</span>
                                            </div>
                                            <div>
                                                <p className="text-xs font-bold text-white group-hover:text-primary transition-colors">Açık Destek Biletleri</p>
                                                <p className="text-[10px] text-zinc-400">Yanıt bekleyen kullanıcı talepleri</p>
                                            </div>
                                        </div>
                                        <span className="text-xs font-extrabold px-2 py-0.5 rounded-full bg-blue-500/20 text-blue-400">
                                            {systemCounts.support}
                                        </span>
                                    </Link>
                                </div>

                                <div className="p-3 bg-surface-dark border-t border-white/5 text-center">
                                    <Link
                                        href="/admin/notifications"
                                        onClick={() => setShowNotifications(false)}
                                        className="text-xs font-bold text-primary hover:underline flex items-center justify-center gap-1"
                                    >
                                        Toplu Push Bildirim Gönder
                                        <span className="material-symbols-outlined text-sm">arrow_forward</span>
                                    </Link>
                                </div>
                            </div>
                        </>
                    )}
                </div>

                {/* Profile */}
                <button className="flex items-center gap-2 p-1.5 hover:bg-white/5 rounded-xl transition-colors">
                    <div className="h-8 w-8 rounded-full bg-primary flex items-center justify-center text-black font-bold text-xs">
                        {currentAdmin?.name?.substring(0, 2).toUpperCase() || 'AD'}
                    </div>
                    <span className="material-symbols-outlined text-white/40 text-sm hidden md:block">expand_more</span>
                </button>
            </div>
        </header>
    );
}
