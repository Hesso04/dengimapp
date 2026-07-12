'use client';

import { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { Card, StatCard } from '@/components/ui/Card';
import { GrowthChart, DonutChart, HorizontalBarChart } from '@/components/dashboard/Charts';
import { AnalyticsService } from '@/services/analyticsService';
import { DashboardStats, GenderDistribution, ChartDataPoint } from '@/types';
import { formatNumber, formatCurrency } from '@/lib/utils';

export default function AnalyticsPage() {
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [gender, setGender] = useState<GenderDistribution | null>(null);
    const [growth, setGrowth] = useState<ChartDataPoint[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const load = async () => {
            setLoading(true);
            try {
                const [s, g, gr] = await Promise.all([
                    AnalyticsService.getDashboardStats(),
                    AnalyticsService.getGenderDistribution(),
                    AnalyticsService.getUserGrowth()
                ]);
                setStats(s);
                setGender(g);
                setGrowth(gr);
            } catch (e) {
                console.error(e);
            } finally {
                setLoading(false);
            }
        };
        load();
    }, []);

    const genderData = gender ? [
        { name: 'Erkek', value: gender.male, color: '#3B82F6' },
        { name: 'Kadın', value: gender.female, color: '#EC4899' },
    ] : [];

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">
                    {loading ? (
                        <div className="flex justify-center py-20">
                            <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                        </div>
                    ) : (
                        <>
                            <div className="flex items-center justify-between mb-6">
                                <div>
                                    <h2 className="text-2xl font-bold text-white">Analitik & Raporlama</h2>
                                    <p className="text-zinc-400 text-sm">Gerçek zamanlı platform performansı</p>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                                <StatCard
                                    title="Toplam Kullanıcı"
                                    value={formatNumber(stats?.totalUsers || 0)}
                                    borderColor="border-l-primary"
                                />
                                <StatCard
                                    title="Premium Üyeler"
                                    value={formatNumber(stats?.premiumUsers || 0)}
                                    borderColor="border-l-accent-indigo"
                                />
                                <StatCard
                                    title="Toplam Eşleşme"
                                    value={formatNumber(stats?.totalMatches || 0)}
                                    borderColor="border-l-accent-emerald"
                                />
                                <StatCard
                                    title="Gelir (Tahmini)"
                                    value={formatCurrency(stats?.mrr || 0, 'TRY')}
                                    borderColor="border-l-primary"
                                />
                            </div>

                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                                <Card glass>
                                    <h3 className="text-lg font-bold text-white mb-4">Kullanıcı Büyümesi</h3>
                                    <GrowthChart data={growth} height={280} />
                                </Card>
                                <Card glass>
                                    <h3 className="text-lg font-bold text-white mb-4">Cinsiyet Dağılımı</h3>
                                    <div className="h-[280px]">
                                        <DonutChart data={genderData} />
                                    </div>
                                </Card>
                            </div>

                            <Card glass className="p-8 text-center text-white/20 italic">
                                Daha detaylı analitik verileri (Retention, Funnel vb.) kullanıcı sayısı arttıkça otomatik olarak hesaplanacaktır.
                            </Card>
                        </>
                    )}
                </main>
                <BottomNav />
            </div>
        </div>
    );
}

