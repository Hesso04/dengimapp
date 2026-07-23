'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState, useEffect } from 'react';
import { signOut } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { cn } from '@/lib/utils';
import { useAdminStore } from '@/store/adminStore';
import { AnalyticsService } from '@/services/analyticsService';

export function Sidebar() {
    const pathname = usePathname();
    const { sidebarOpen, currentAdmin } = useAdminStore();
    const [counts, setCounts] = useState({ reports: 0, moderation: 0, support: 0 });

    useEffect(() => {
        const fetchCounts = async () => {
            const data = await AnalyticsService.getSystemCounts();
            setCounts(data);
        };
        fetchCounts();

        // Periyodik güncelleme (her 1 dk)
        const interval = setInterval(fetchCounts, 60000);
        return () => clearInterval(interval);
    }, []);

    const menuItems = [
        {
            label: 'Dashboard',
            icon: 'dashboard',
            href: '/admin',
        },
        {
            label: 'Kullanıcılar',
            icon: 'group',
            href: '/admin/users',
        },
        {
            label: 'Moderasyon',
            icon: 'verified_user',
            href: '/admin/moderation',
            badge: counts.moderation > 0 ? counts.moderation : undefined,
        },
        {
            label: 'Medya Tarayıcı',
            icon: 'perm_media',
            href: '/admin/media',
        },
        {
            label: 'Raporlar',
            icon: 'report',
            href: '/admin/reports',
            badge: counts.reports > 0 ? counts.reports : undefined,
        },
        {
            label: 'Premium',
            icon: 'diamond',
            href: '/admin/premium',
        },
        {
            label: 'Analitik',
            icon: 'analytics',
            href: '/admin/analytics',
        },
        {
            label: 'Bildirimler',
            icon: 'notifications',
            href: '/admin/notifications',
        },
        {
            label: 'İçerik/Kaynak',
            icon: 'source_environment',
            href: '/admin/resources',
        },
        {
            label: 'Destek',
            icon: 'support_agent',
            href: '/admin/support',
            badge: counts.support > 0 ? counts.support : undefined,
        },
        {
            label: 'Sistem Ayarları',
            icon: 'settings',
            href: '/admin/settings',
        },
    ];

    const handleLogout = async () => {
        try {
            await signOut(auth);
        } catch (error) {
            console.error('Logout error:', error);
        }
    };

    return (
        <>
            {/* Mobile Overlay */}
            {sidebarOpen && (
                <div
                    className="fixed inset-0 z-40 bg-black/60 md:hidden"
                    onClick={() => useAdminStore.getState().setSidebarOpen(false)}
                />
            )}

            {/* Sidebar */}
            <aside className={cn(
                'fixed md:sticky top-0 left-0 z-50 h-screen w-64 bg-surface-dark border-r border-white/5 flex flex-col transition-transform duration-300',
                'md:translate-x-0',
                sidebarOpen ? 'translate-x-0' : '-translate-x-full'
            )}>
                {/* Logo */}
                <div className="h-16 flex items-center px-6 border-b border-white/5">
                    <Link href="/admin" className="flex items-center gap-3">
                        <img 
                            src="/logo.png" 
                            alt="Dengim Logo" 
                            className="w-8 h-8 rounded-lg object-cover"
                        />
                        <div className="flex flex-col">
                            <span className="text-lg font-black tracking-tight text-white leading-tight">DENGİM</span>
                            <span className="text-[10px] font-bold text-primary uppercase tracking-wider leading-none">Dating</span>
                        </div>
                    </Link>
                </div>

                {/* Navigation */}
                <nav className="flex-1 overflow-y-auto custom-scrollbar py-4 px-3">
                    <ul className="space-y-1">
                        {menuItems.map((item) => {
                            const isActive = pathname === item.href ||
                                (item.href !== '/' && pathname.startsWith(item.href));

                            return (
                                <li key={item.href}>
                                    <Link
                                        href={item.href}
                                        className={cn(
                                            'flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200',
                                            isActive
                                                ? 'bg-primary/20 text-primary border border-primary/40 font-bold shadow-md'
                                                : 'text-zinc-300 font-medium hover:bg-zinc-800 hover:text-white'
                                        )}
                                        onClick={() => {
                                            if (window.innerWidth < 768) {
                                                useAdminStore.getState().setSidebarOpen(false);
                                            }
                                        }}
                                    >
                                        <span className="material-symbols-outlined text-xl">{item.icon}</span>
                                        <span className={cn('font-medium', isActive && 'font-semibold')}>{item.label}</span>
                                        {item.badge && (
                                            <span className={cn(
                                                'ml-auto px-2 py-0.5 text-[10px] font-bold rounded-full',
                                                isActive
                                                    ? 'bg-primary text-black'
                                                    : 'bg-rose-500/20 text-rose-500'
                                            )}>
                                                {item.badge}
                                            </span>
                                        )}
                                    </Link>
                                </li>
                            );
                        })}
                    </ul>
                </nav>

                {/* Footer */}
                <div className="p-4 border-t border-white/5">
                    <div className="glass rounded-xl p-3">
                        <div className="flex items-center gap-3">
                            <div className="h-10 w-10 rounded-full bg-primary flex items-center justify-center text-black font-bold">
                                {currentAdmin?.name?.substring(0, 2).toUpperCase() || 'AD'}
                            </div>
                            <div className="flex-1 min-w-0">
                                <p className="text-sm font-semibold text-white truncate">{currentAdmin?.name || 'Admin'}</p>
                                <p className="text-[10px] text-primary uppercase tracking-wider">
                                    {currentAdmin?.role === 'super_admin' ? 'Super Admin' : currentAdmin?.role}
                                </p>
                            </div>
                            <button
                                onClick={handleLogout}
                                className="p-2 text-white/40 hover:text-white transition-colors"
                            >
                                <span className="material-symbols-outlined text-lg">logout</span>
                            </button>
                        </div>
                    </div>
                </div>
            </aside>
        </>
    );
}
