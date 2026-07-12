'use client';

import { useAdminStore } from '@/store/adminStore';
import { usePathname } from 'next/navigation';
import Link from 'next/link';

const pageTitles: Record<string, string> = {
    '/admin': 'Dashboard',
    '/admin/users': 'Kullanıcı Yönetimi',
    '/admin/moderation': 'Moderasyon',
    '/admin/reports': 'Raporlar & Şikayetler',
    '/admin/premium': 'Premium Yönetimi',
    '/admin/analytics': 'Analitik & Raporlama',
    '/admin/notifications': 'Bildirim Merkezi',
    '/admin/support': 'Destek Sistemi',
    '/admin/settings': 'Ayarlar',
};

export function Header() {
    const pathname = usePathname();
    const { toggleSidebar, currentAdmin, unreadNotificationCount } = useAdminStore();

    const pageTitle = Object.entries(pageTitles).find(
        ([path]) => pathname === path || (path !== '/admin' && pathname.startsWith(path))
    )?.[1] || 'Dashboard';

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
                    <span className="text-xs font-medium text-emerald-400">Aktif</span>
                </div>

                {/* Notifications */}
                <Link
                    href="/admin/notifications"
                    className="relative p-2.5 text-slate-400 hover:text-primary hover:bg-white/5 rounded-xl transition-colors"
                >
                    <span className="material-symbols-outlined">notifications</span>
                    {unreadNotificationCount > 0 && (
                        <span className="absolute top-1.5 right-1.5 flex h-4 w-4">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75" />
                            <span className="relative inline-flex items-center justify-center h-4 w-4 rounded-full bg-primary text-[9px] font-bold text-black">
                                {unreadNotificationCount > 9 ? '9+' : unreadNotificationCount}
                            </span>
                        </span>
                    )}
                </Link>

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
