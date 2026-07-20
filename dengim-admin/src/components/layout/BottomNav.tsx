'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';

const navItems = [
    { label: 'Panel', icon: 'dashboard', href: '/admin' },
    { label: 'Üyeler', icon: 'group', href: '/admin/users' },
    { label: 'Moderasyon', icon: 'verified_user', href: '/admin/moderation' },
    { label: 'Raporlar', icon: 'report', href: '/admin/reports' },
    { label: 'Ayarlar', icon: 'settings', href: '/admin/settings' },
];

export function BottomNav() {
    const pathname = usePathname();

    return (
        <nav className="fixed bottom-0 left-0 right-0 z-50 md:hidden bg-background-dark/95 backdrop-blur-xl border-t border-white/5 px-6 py-3">
            <div className="flex justify-between items-center">
                {navItems.map((item) => {
                    const isActive = pathname === item.href ||
                        (item.href !== '/' && pathname.startsWith(item.href));

                    return (
                        <Link
                            key={item.href}
                            href={item.href}
                            className={cn(
                                'flex flex-col items-center gap-1 transition-colors',
                                isActive ? 'text-primary' : 'text-slate-500 hover:text-white'
                            )}
                        >
                            <span className="material-symbols-outlined text-xl">{item.icon}</span>
                            <span className="text-[10px] font-medium">{item.label}</span>
                        </Link>
                    );
                })}
            </div>
        </nav>
    );
}
