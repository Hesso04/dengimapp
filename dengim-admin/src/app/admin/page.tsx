'use client';

import { useEffect, useState } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { StatCard, AlertCard } from '@/components/ui/Card';
import { GrowthChart, DonutChart, HorizontalBarChart } from '@/components/dashboard/Charts';
import { AnalyticsService } from '@/services/analyticsService';
import { DashboardStats, ChartDataPoint, GenderDistribution } from '@/types';
import { UserService } from '@/services/userService';
import { User } from '@/types';
import { formatRelativeTime } from '@/lib/utils';
import { Avatar } from '@/components/ui/Avatar';

export default function Dashboard() {
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [genderData, setGenderData] = useState<GenderDistribution | null>(null);
    const [growthData, setGrowthData] = useState<ChartDataPoint[]>([]);
    const [recentUsers, setRecentUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const loadDashboardData = async () => {
            setLoading(true);
            try {
                // Paralel veri çekme
                const [statsData, genderStats, growthStats, usersData] = await Promise.all([
                    AnalyticsService.getDashboardStats(),
                    AnalyticsService.getGenderDistribution(),
                    AnalyticsService.getUserGrowth(),
                    UserService.getUsers(null, 5) // Son 5 kullanıcı
                ]);

                setStats(statsData);
                setGenderData(genderStats);
                setGrowthData(growthStats);
                setRecentUsers(usersData.users);
            } catch (error) {
                console.error("Dashboard yüklenirken hata:", error);
            } finally {
                setLoading(false);
            }
        };

        loadDashboardData();
    }, []);

    // Grafik verilerini hazırla
    const genderChartData = genderData ? [
        { name: 'Erkek', value: genderData.male, color: '#3B82F6' },
        { name: 'Kadın', value: genderData.female, color: '#EC4899' },
    ] : [];

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">

                    <div className="mb-8">
                        <h1 className="text-2xl font-bold text-white mb-2">Genel Bakış</h1>
                        <p className="text-zinc-400">Platform istatistikleri ve anlık veriler.</p>
                    </div>

                    {loading ? (
                        <div className="flex justify-center py-20">
                            <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                        </div>
                    ) : (
                        <>
                            {/* Stats Grid */}
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                                <StatCard
                                    title="Toplam Kullanıcı"
                                    value={stats?.totalUsers.toString() || '0'}
                                    subValue={`${stats?.newUsersToday || 0} bugün`}
                                    icon={<span className="material-symbols-outlined text-2xl">group</span>}
                                    borderColor="border-l-primary"
                                />
                                <StatCard
                                    title="Bu Hafta Yeni"
                                    value={stats?.newUsersThisWeek.toString() || '0'}
                                    subValue={`${stats?.newUsersThisMonth || 0} bu ay`}
                                    icon={<span className="material-symbols-outlined text-2xl">person_add</span>}
                                    borderColor="border-l-emerald-500"
                                />
                                <StatCard
                                    title="Premium Üyeler"
                                    value={stats?.premiumUsers.toString() || '0'}
                                    subValue={`${((stats?.premiumUsers || 0) / (stats?.totalUsers || 1) * 100).toFixed(1)}% dönüşüm`}
                                    icon={<span className="material-symbols-outlined text-2xl">diamond</span>}
                                    borderColor="border-l-amber-500"
                                />
                                <StatCard
                                    title="Eşleşmeler"
                                    value={stats?.totalMatches.toString() || '0'}
                                    subValue="Tüm zamanlar"
                                    icon={<span className="material-symbols-outlined text-2xl">favorite</span>}
                                    borderColor="border-l-rose-500"
                                />
                            </div>

                            {/* Main Charts Area */}
                            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
                                <div className="lg:col-span-2 bg-surface-dark rounded-2xl p-6 border border-white/5">
                                    <div className="flex items-center justify-between mb-6">
                                        <h3 className="text-lg font-bold text-white">Kullanıcı Büyümesi</h3>
                                        <select className="bg-white/5 border border-white/10 rounded-lg px-3 py-1 text-sm text-white focus:outline-none">
                                            <option>Son 7 Gün</option>
                                            <option>Son 30 Gün</option>
                                        </select>
                                    </div>
                                    <div className="h-[300px]">
                                        <GrowthChart data={growthData} />
                                    </div>
                                </div>

                                <div className="bg-surface-dark rounded-2xl p-6 border border-white/5">
                                    <h3 className="text-lg font-bold text-white mb-6">Cinsiyet Dağılımı</h3>
                                    <div className="h-[300px]">
                                        <DonutChart data={genderChartData} />
                                    </div>
                                </div>
                            </div>

                            {/* Recent Activity & Alerts */}
                            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                                <div className="lg:col-span-2">
                                    <div className="bg-surface-dark rounded-2xl border border-white/5 overflow-hidden">
                                        <div className="p-6 border-b border-white/5 flex items-center justify-between">
                                            <h3 className="text-lg font-bold text-white">Son Kayıt Olanlar</h3>
                                            <button className="text-sm text-primary hover:text-primary/80">Tümünü Gör</button>
                                        </div>
                                        <div className="divide-y divide-white/5">
                                            {recentUsers.length > 0 ? recentUsers.map((user) => (
                                                <div key={user.id} className="p-4 flex items-center justify-between hover:bg-white/5 transition-colors">
                                                    <div className="flex items-center gap-3">
                                                        <Avatar src={user.photos[0]} name={user.name} />
                                                        <div>
                                                            <p className="font-bold text-white text-sm">{user.name}</p>
                                                            <p className="text-slate-400 text-xs">
                                                                {user.email || 'E-posta yok'}
                                                            </p>
                                                        </div>
                                                    </div>
                                                    <span className="text-xs text-slate-500">
                                                        {formatRelativeTime(user.createdAt)}
                                                    </span>
                                                </div>
                                            )) : (
                                                <div className="p-6 text-center text-slate-500">Henüz kullanıcı yok.</div>
                                            )}
                                        </div>
                                    </div>
                                </div>

                                <div className="space-y-4">
                                    <h3 className="text-lg font-bold text-white">Sistem Uyarıları</h3>
                                    {stats?.pendingReports && stats.pendingReports > 0 ? (
                                        <AlertCard
                                            title="Bekleyen Şikayetler"
                                            description={`${stats.pendingReports} yeni şikayet incelenmeyi bekliyor.`}
                                            time="Simdi"
                                            type="error"
                                        />
                                    ) : (
                                        <AlertCard
                                            title="Her şey yolunda"
                                            description="İncelenmesi gereken acil bir durum yok."
                                            time="Simdi"
                                            type="info"
                                        />
                                    )}
                                </div>
                            </div>
                        </>
                    )}
                </main>
                <BottomNav />
            </div>
        </div>
    );
}
