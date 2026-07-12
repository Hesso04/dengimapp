'use client';

import React, { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { Card, StatCard } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { TierBadge } from '@/components/ui/Badge';
import { Avatar } from '@/components/ui/Avatar';
import { GrowthChart } from '@/components/dashboard/Charts';
import { AnalyticsService } from '@/services/analyticsService';
import { UserService } from '@/services/userService';
import { PremiumService, PremiumConfig } from '@/services/premiumService';
import { formatCurrency, formatRelativeTime, cn } from '@/lib/utils';
import { User, DashboardStats } from '@/types';

export default function PremiumPage() {
    const [activeTab, setActiveTab] = useState<'overview' | 'subscribers' | 'tiers' | 'credits'>('overview');
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [premiumStats, setPremiumStats] = useState<any>(null);
    const [subscribers, setSubscribers] = useState<User[]>([]);
    const [config, setConfig] = useState<PremiumConfig | null>(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    // User tier edit modal
    const [editUser, setEditUser] = useState<User | null>(null);
    const [editTier, setEditTier] = useState<'free' | 'gold' | 'platinum'>('free');
    const [editDays, setEditDays] = useState('30');
    const [editCredits, setEditCredits] = useState('');
    const [editCreditReason, setEditCreditReason] = useState('');

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        setLoading(true);
        try {
            const [statsData, subsData, premConfig, pStats] = await Promise.all([
                AnalyticsService.getDashboardStats(),
                UserService.getPremiumUsers(),
                PremiumService.getConfig(),
                PremiumService.getStats()
            ]);
            setStats(statsData);
            setSubscribers(subsData);
            setConfig(premConfig);
            setPremiumStats(pStats);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const handleSaveConfig = async () => {
        if (!config) return;
        setSaving(true);
        try {
            await PremiumService.updateConfig(config);
            alert('✅ Premium ayarları başarıyla kaydedildi!');
        } catch (error) {
            alert('❌ Kayıt sırasında hata oluştu.');
        } finally {
            setSaving(false);
        }
    };

    const handleUpdateUserTier = async () => {
        if (!editUser) return;
        try {
            await PremiumService.updateUserTier(editUser.id, editTier, parseInt(editDays));
            alert(`✅ ${editUser.name} kullanıcısının tier bilgisi güncellendi.`);
            setEditUser(null);
            loadData();
        } catch (error) {
            alert('❌ Güncelleme başarısız.');
        }
    };

    const handleAdjustCredits = async () => {
        if (!editUser || !editCredits) return;
        try {
            await PremiumService.adjustUserCredits(editUser.id, parseInt(editCredits), editCreditReason || 'Manuel düzeltme');
            alert(`✅ Kredi güncellendi.`);
            setEditCredits('');
            setEditCreditReason('');
        } catch (error) {
            alert('❌ Kredi güncelleme başarısız.');
        }
    };

    const revenueData = [
        { date: 'Eyl 25', value: 8200 },
        { date: 'Eki 25', value: 12500 },
        { date: 'Kas 25', value: 18400 },
        { date: 'Ara 25', value: 24600 },
        { date: 'Oca 26', value: 31200 },
        { date: 'Şub 26', value: 35800 },
    ];

    const updateConfig = (key: keyof PremiumConfig, value: any) => {
        if (!config) return;
        setConfig({ ...config, [key]: value });
    };

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col">
                <Header />
                <main className="flex-1 overflow-y-auto pb-24 md:pb-6 custom-scrollbar">
                    {/* Tabs */}
                    <div className="flex border-b border-white/10 px-4 gap-6 sticky top-0 bg-background-dark z-10">
                        {[
                            { key: 'overview', label: 'Gelir Özeti', icon: 'trending_up' },
                            { key: 'subscribers', label: 'Aboneler', icon: 'people' },
                            { key: 'tiers', label: 'Tier Ayarları', icon: 'tune' },
                            { key: 'credits', label: 'Kredi Sistemi', icon: 'monetization_on' },
                        ].map((tab) => (
                            <button
                                key={tab.key}
                                onClick={() => setActiveTab(tab.key as any)}
                                className={cn(
                                    'pb-3 pt-4 text-sm font-bold border-b-[3px] transition-colors flex items-center gap-2',
                                    activeTab === tab.key
                                        ? 'text-white border-primary'
                                        : 'text-white/50 border-transparent hover:text-white/70'
                                )}
                            >
                                <span className="material-symbols-outlined text-lg">{tab.icon}</span>
                                {tab.label}
                            </button>
                        ))}
                    </div>

                    <div className="p-4 md:p-6">
                        {loading ? (
                            <div className="flex justify-center py-20">
                                <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                            </div>
                        ) : (
                            <>
                                {/* OVERVIEW TAB */}
                                {activeTab === 'overview' && (
                                    <div className="space-y-8">
                                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                                            <StatCard
                                                title="Aylık Gelir (MRR)"
                                                value={formatCurrency(stats?.mrr || 0, 'TRY')}
                                                borderColor="border-l-primary"
                                            />
                                            <StatCard
                                                title="Gold Üyeler"
                                                value={premiumStats?.goldCount || 0}
                                                borderColor="border-l-amber-500"
                                            />
                                            <StatCard
                                                title="Platinum Üyeler"
                                                value={premiumStats?.platinumCount || 0}
                                                borderColor="border-l-blue-400"
                                            />
                                            <StatCard
                                                title="Dönüşüm Oranı"
                                                value={`${((premiumStats?.totalPremium || 0) / (stats?.totalUsers || 1) * 100).toFixed(1)}%`}
                                                borderColor="border-l-accent-emerald"
                                            />
                                        </div>

                                        {/* Kredi Dolaşım İstatistikleri */}
                                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                                            <Card glass className="p-6">
                                                <div className="flex items-center gap-3 mb-2">
                                                    <span className="material-symbols-outlined text-primary">monetization_on</span>
                                                    <h4 className="text-white/40 text-xs uppercase font-bold">Toplam Dolaşımdaki Kredi</h4>
                                                </div>
                                                <p className="text-3xl font-black text-white">{premiumStats?.totalCreditsInCirculation?.toLocaleString() || 0}</p>
                                            </Card>
                                            <Card glass className="p-6">
                                                <div className="flex items-center gap-3 mb-2">
                                                    <span className="material-symbols-outlined text-amber-500">person</span>
                                                    <h4 className="text-white/40 text-xs uppercase font-bold">Ortalama Kredi / Kullanıcı</h4>
                                                </div>
                                                <p className="text-3xl font-black text-white">{premiumStats?.avgCreditsPerUser || 0}</p>
                                            </Card>
                                            <Card glass className="p-6">
                                                <div className="flex items-center gap-3 mb-2">
                                                    <span className="material-symbols-outlined text-emerald-500">groups</span>
                                                    <h4 className="text-white/40 text-xs uppercase font-bold">Kredili Kullanıcılar</h4>
                                                </div>
                                                <p className="text-3xl font-black text-white">{premiumStats?.creditUsers || 0}</p>
                                            </Card>
                                        </div>

                                        <Card glass>
                                            <h3 className="text-lg font-bold text-white mb-6 px-6 pt-6">Gelir Trendi</h3>
                                            <div className="h-[250px] px-6 pb-6">
                                                <GrowthChart data={revenueData} color="#ecb613" />
                                            </div>
                                        </Card>
                                    </div>
                                )}

                                {/* SUBSCRIBERS TAB */}
                                {activeTab === 'subscribers' && (
                                    <div className="space-y-3">
                                        {subscribers.length > 0 ? subscribers.map((sub) => (
                                            <div key={sub.id} className="flex items-center gap-4 p-4 bg-surface-dark rounded-xl border border-white/10 hover:border-primary/30 transition-all">
                                                <Avatar name={sub.name} premium />
                                                <div className="flex-1">
                                                    <div className="flex items-center gap-2 mb-1">
                                                        <p className="font-semibold text-white">{sub.name}</p>
                                                        <TierBadge tier={sub.premiumTier as any || 'basic'} />
                                                    </div>
                                                    <p className="text-xs text-white/40">
                                                        {formatRelativeTime(sub.createdAt)} katıldı
                                                    </p>
                                                </div>
                                                <div className="flex gap-2">
                                                    <Button variant="ghost" size="sm" onClick={() => {
                                                        setEditUser(sub);
                                                        setEditTier(sub.premiumTier as any || 'free');
                                                    }}>
                                                        <span className="material-symbols-outlined text-sm mr-1">edit</span>
                                                        Düzenle
                                                    </Button>
                                                </div>
                                            </div>
                                        )) : (
                                            <div className="py-20 text-center text-white/20">Henüz premium abonelik bulunmuyor.</div>
                                        )}
                                    </div>
                                )}

                                {/* TIER SETTINGS TAB */}
                                {activeTab === 'tiers' && config && (
                                    <div className="space-y-8">
                                        {/* Pricing */}
                                        <Card glass className="p-6">
                                            <h3 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
                                                <span className="material-symbols-outlined text-primary">payments</span>
                                                Fiyatlandırma (₺)
                                            </h3>
                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                                <div>
                                                    <h4 className="text-sm font-bold text-amber-500 mb-4">⭐ GOLD</h4>
                                                    <div className="space-y-3">
                                                        <Input label="Aylık" type="number" value={config.goldMonthlyPrice.toString()} onChange={e => updateConfig('goldMonthlyPrice', parseFloat(e.target.value))} />
                                                        <Input label="3 Aylık" type="number" value={config.goldQuarterlyPrice.toString()} onChange={e => updateConfig('goldQuarterlyPrice', parseFloat(e.target.value))} />
                                                        <Input label="Yıllık" type="number" value={config.goldYearlyPrice.toString()} onChange={e => updateConfig('goldYearlyPrice', parseFloat(e.target.value))} />
                                                    </div>
                                                </div>
                                                <div>
                                                    <h4 className="text-sm font-bold text-blue-400 mb-4">💎 PLATINUM</h4>
                                                    <div className="space-y-3">
                                                        <Input label="Aylık" type="number" value={config.platinumMonthlyPrice.toString()} onChange={e => updateConfig('platinumMonthlyPrice', parseFloat(e.target.value))} />
                                                        <Input label="3 Aylık" type="number" value={config.platinumQuarterlyPrice.toString()} onChange={e => updateConfig('platinumQuarterlyPrice', parseFloat(e.target.value))} />
                                                        <Input label="Yıllık" type="number" value={config.platinumYearlyPrice.toString()} onChange={e => updateConfig('platinumYearlyPrice', parseFloat(e.target.value))} />
                                                    </div>
                                                </div>
                                            </div>
                                        </Card>

                                        {/* Feature Limits */}
                                        <Card glass className="p-6">
                                            <h3 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
                                                <span className="material-symbols-outlined text-primary">tune</span>
                                                Özellik Limitleri
                                            </h3>
                                            <div className="overflow-x-auto">
                                                <table className="w-full text-sm">
                                                    <thead>
                                                        <tr className="border-b border-white/10">
                                                            <th className="text-left text-white/50 py-3 px-2 font-bold">Özellik</th>
                                                            <th className="text-center text-white/50 py-3 px-2 font-bold">Free</th>
                                                            <th className="text-center text-amber-500 py-3 px-2 font-bold">Gold</th>
                                                            <th className="text-center text-blue-400 py-3 px-2 font-bold">Platinum</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody className="text-white/80">
                                                        {[
                                                            { label: 'Günlük Beğeni', free: 'freeDailyLikes', gold: 'goldDailyLikes', plat: 'platinumDailyLikes' },
                                                            { label: 'Günlük Super Like', free: 'freeDailySuperLikes', gold: 'goldDailySuperLikes', plat: 'platinumDailySuperLikes' },
                                                            { label: 'Maksimum Fotoğraf', free: 'freeMaxPhotos', gold: 'goldMaxPhotos', plat: 'platinumMaxPhotos' },
                                                            { label: 'Günlük Geri Alma', free: 'freeRewindsPerDay', gold: 'goldRewindsPerDay', plat: 'platinumRewindsPerDay' },
                                                        ].map(row => (
                                                            <tr key={row.label} className="border-b border-white/5">
                                                                <td className="py-3 px-2 font-medium">{row.label}</td>
                                                                <td className="py-3 px-2 text-center">
                                                                    <input type="number" className="w-20 bg-white/5 border border-white/10 rounded-lg px-2 py-1 text-center text-white outline-none focus:border-primary" value={(config as any)[row.free]} onChange={e => updateConfig(row.free as keyof PremiumConfig, parseInt(e.target.value))} />
                                                                </td>
                                                                <td className="py-3 px-2 text-center">
                                                                    <input type="number" className="w-20 bg-amber-500/5 border border-amber-500/20 rounded-lg px-2 py-1 text-center text-amber-400 outline-none focus:border-amber-500" value={(config as any)[row.gold]} onChange={e => updateConfig(row.gold as keyof PremiumConfig, parseInt(e.target.value))} />
                                                                </td>
                                                                <td className="py-3 px-2 text-center">
                                                                    <input type="number" className="w-20 bg-blue-500/5 border border-blue-500/20 rounded-lg px-2 py-1 text-center text-blue-400 outline-none focus:border-blue-500" value={(config as any)[row.plat]} onChange={e => updateConfig(row.plat as keyof PremiumConfig, parseInt(e.target.value))} />
                                                                </td>
                                                            </tr>
                                                        ))}
                                                    </tbody>
                                                </table>
                                            </div>

                                            {/* Toggle features */}
                                            <div className="mt-6 space-y-3">
                                                <h4 className="text-sm font-bold text-white/50 mb-2">Toggle Özellikleri</h4>
                                                {[
                                                    { label: 'Boost', gold: 'goldCanBoost', plat: 'platinumCanBoost' },
                                                    { label: 'Sesli Mesaj', gold: 'goldVoiceMessage', plat: 'platinumVoiceMessage' },
                                                    { label: 'Okundu Bilgisi', gold: 'goldReadReceipts', plat: 'platinumReadReceipts' },
                                                    { label: 'Gelişmiş Filtreler', gold: 'goldAdvancedFilters', plat: 'platinumAdvancedFilters' },
                                                    { label: 'Reklamsız', gold: 'goldNoAds', plat: 'platinumNoAds' },
                                                ].map(feat => (
                                                    <div key={feat.label} className="flex items-center justify-between p-3 bg-white/5 rounded-xl">
                                                        <span className="text-sm font-medium text-white">{feat.label}</span>
                                                        <div className="flex gap-4">
                                                            <label className="flex items-center gap-2 text-xs">
                                                                <span className="text-amber-500">Gold</span>
                                                                <button
                                                                    onClick={() => updateConfig(feat.gold as keyof PremiumConfig, !(config as any)[feat.gold])}
                                                                    className={cn("w-10 h-5 rounded-full relative transition-colors", (config as any)[feat.gold] ? "bg-amber-500" : "bg-white/10")}
                                                                >
                                                                    <div className={cn("absolute top-0.5 h-4 w-4 rounded-full bg-white transition-all", (config as any)[feat.gold] ? "right-0.5" : "left-0.5")} />
                                                                </button>
                                                            </label>
                                                            <label className="flex items-center gap-2 text-xs">
                                                                <span className="text-blue-400">Plat</span>
                                                                <button
                                                                    onClick={() => updateConfig(feat.plat as keyof PremiumConfig, !(config as any)[feat.plat])}
                                                                    className={cn("w-10 h-5 rounded-full relative transition-colors", (config as any)[feat.plat] ? "bg-blue-500" : "bg-white/10")}
                                                                >
                                                                    <div className={cn("absolute top-0.5 h-4 w-4 rounded-full bg-white transition-all", (config as any)[feat.plat] ? "right-0.5" : "left-0.5")} />
                                                                </button>
                                                            </label>
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        </Card>

                                        <div className="flex justify-end">
                                            <Button className="h-14 px-12 text-lg shadow-xl shadow-primary/20" onClick={handleSaveConfig} loading={saving}>
                                                Tier Ayarlarını Kaydet
                                            </Button>
                                        </div>
                                    </div>
                                )}

                                {/* CREDITS TAB */}
                                {activeTab === 'credits' && config && (
                                    <div className="space-y-8">
                                        {/* Credit toggle */}
                                        <Card glass className="p-6">
                                            <div className="flex items-center justify-between mb-6">
                                                <h3 className="text-lg font-bold text-white flex items-center gap-2">
                                                    <span className="material-symbols-outlined text-primary">monetization_on</span>
                                                    Kredi Sistemi
                                                </h3>
                                                <button
                                                    onClick={() => updateConfig('creditEnabled', !config.creditEnabled)}
                                                    className={cn("w-14 h-7 rounded-full relative transition-colors", config.creditEnabled ? "bg-primary" : "bg-white/10")}
                                                >
                                                    <div className={cn("absolute top-1 h-5 w-5 rounded-full bg-white transition-all", config.creditEnabled ? "right-1" : "left-1")} />
                                                </button>
                                            </div>

                                            {config.creditEnabled && (
                                                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                                    <div>
                                                        <h4 className="text-sm font-bold text-emerald-500 mb-4 flex items-center gap-2">
                                                            <span className="material-symbols-outlined text-sm">add_circle</span>
                                                            Kazanım Ayarları
                                                        </h4>
                                                        <div className="space-y-3">
                                                            <Input label="Reklam İzleme Ödülü" type="number" value={config.creditPerAdWatch.toString()} onChange={e => updateConfig('creditPerAdWatch', parseInt(e.target.value))} />
                                                            <Input label="Günlük Giriş Ödülü" type="number" value={config.creditDailyLogin.toString()} onChange={e => updateConfig('creditDailyLogin', parseInt(e.target.value))} />
                                                            <Input label="Ardışık Giriş Bonusu" type="number" value={config.creditStreakBonus.toString()} onChange={e => updateConfig('creditStreakBonus', parseInt(e.target.value))} />
                                                            <Input label="Günlük Max Reklam" type="number" value={config.creditMaxAdsPerDay.toString()} onChange={e => updateConfig('creditMaxAdsPerDay', parseInt(e.target.value))} />
                                                        </div>
                                                    </div>
                                                    <div>
                                                        <h4 className="text-sm font-bold text-rose-500 mb-4 flex items-center gap-2">
                                                            <span className="material-symbols-outlined text-sm">remove_circle</span>
                                                            Harcama Fiyatları
                                                        </h4>
                                                        <div className="space-y-3">
                                                            <Input label="Super Like Maliyeti" type="number" value={config.creditCostSuperLike.toString()} onChange={e => updateConfig('creditCostSuperLike', parseInt(e.target.value))} />
                                                            <Input label="Boost Maliyeti" type="number" value={config.creditCostBoost.toString()} onChange={e => updateConfig('creditCostBoost', parseInt(e.target.value))} />
                                                            <Input label="Kimin Beğendiğini Gör" type="number" value={config.creditCostSeeWhoLiked.toString()} onChange={e => updateConfig('creditCostSeeWhoLiked', parseInt(e.target.value))} />
                                                            <Input label="Geri Alma Maliyeti" type="number" value={config.creditCostUndoSwipe.toString()} onChange={e => updateConfig('creditCostUndoSwipe', parseInt(e.target.value))} />
                                                        </div>
                                                    </div>
                                                </div>
                                            )}
                                        </Card>

                                        <div className="flex justify-end">
                                            <Button className="h-14 px-12 text-lg shadow-xl shadow-primary/20" onClick={handleSaveConfig} loading={saving}>
                                                Kredi Ayarlarını Kaydet
                                            </Button>
                                        </div>
                                    </div>
                                )}
                            </>
                        )}
                    </div>
                </main>
                <BottomNav />
            </div>

            {/* User Edit Modal */}
            {editUser && (
                <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4" onClick={() => setEditUser(null)}>
                    <div className="bg-surface-dark rounded-2xl border border-white/10 w-full max-w-lg p-6" onClick={e => e.stopPropagation()}>
                        <div className="flex items-center justify-between mb-6">
                            <h3 className="text-xl font-bold text-white">Kullanıcı Düzenle</h3>
                            <button onClick={() => setEditUser(null)} className="text-white/40 hover:text-white">
                                <span className="material-symbols-outlined">close</span>
                            </button>
                        </div>

                        <div className="flex items-center gap-4 mb-6 p-4 bg-white/5 rounded-xl">
                            <Avatar name={editUser.name} premium={editUser.isPremium} />
                            <div>
                                <p className="font-bold text-white">{editUser.name}</p>
                                <p className="text-xs text-white/40">{editUser.email}</p>
                            </div>
                        </div>

                        {/* Tier Değiştirme */}
                        <div className="mb-6">
                            <h4 className="text-sm font-bold text-white mb-3">Abonelik Tier</h4>
                            <div className="flex gap-2 mb-3">
                                {['free', 'gold', 'platinum'].map(tier => (
                                    <button
                                        key={tier}
                                        onClick={() => setEditTier(tier as any)}
                                        className={cn(
                                            "flex-1 py-3 rounded-xl font-bold text-sm transition-all border",
                                            editTier === tier
                                                ? tier === 'gold' ? 'bg-amber-500/20 text-amber-500 border-amber-500/40'
                                                    : tier === 'platinum' ? 'bg-blue-500/20 text-blue-400 border-blue-500/40'
                                                        : 'bg-white/10 text-white border-white/20'
                                                : 'bg-white/5 text-white/40 border-white/5 hover:bg-white/10'
                                        )}
                                    >
                                        {tier.toUpperCase()}
                                    </button>
                                ))}
                            </div>
                            {editTier !== 'free' && (
                                <Input label="Süre (gün)" type="number" value={editDays} onChange={e => setEditDays(e.target.value)} />
                            )}
                            <Button className="w-full mt-3 h-12" onClick={handleUpdateUserTier}>
                                Tier Güncelle
                            </Button>
                        </div>

                        {/* Kredi Düzenleme */}
                        <div className="border-t border-white/10 pt-6">
                            <h4 className="text-sm font-bold text-white mb-3">Kredi Düzenleme</h4>
                            <div className="space-y-3">
                                <Input label="Miktar (+ ekle, - çıkar)" type="number" value={editCredits} onChange={e => setEditCredits(e.target.value)} />
                                <Input label="Sebep (opsiyonel)" value={editCreditReason} onChange={e => setEditCreditReason(e.target.value)} />
                                <Button variant="secondary" className="w-full h-12" onClick={handleAdjustCredits}>
                                    Kredi Güncelle
                                </Button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
