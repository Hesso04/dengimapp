'use client';

import React, { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { Card, StatCard } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { PriorityBadge, StatusBadge, Badge } from '@/components/ui/Badge';
import { Input } from '@/components/ui/Input';
import { formatRelativeTime, cn } from '@/lib/utils';
import { ReportService } from '@/services/reportService';
import { UserService } from '@/services/userService';
import { Report } from '@/types';

const REPORT_CATEGORIES = [
    { key: 'all', label: 'Tümü' },
    { key: 'pending', label: 'Bekleyenler' },
    { key: 'reviewed', label: 'İncelenen' },
    { key: 'action_taken', label: 'İşlem Yapılan' },
    { key: 'dismissed', label: 'Reddedilen' },
];

const BAN_DURATIONS = [
    { label: '1 Gün', days: 1 },
    { label: '3 Gün', days: 3 },
    { label: '7 Gün', days: 7 },
    { label: '30 Gün', days: 30 },
    { label: 'Kalıcı', days: -1 },
];

export default function ReportsPage() {
    const [activeTab, setActiveTab] = useState('pending');
    const [reports, setReports] = useState<Report[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedReport, setSelectedReport] = useState<Report | null>(null);
    const [actionNote, setActionNote] = useState('');
    const [showBanModal, setShowBanModal] = useState(false);
    const [banDuration, setBanDuration] = useState(7);
    const [banReason, setBanReason] = useState('');
    const [stats, setStats] = useState({ total: 0, pending: 0, resolved: 0, actionTaken: 0 });

    useEffect(() => {
        fetchReports();
    }, [activeTab]);

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchReports = async () => {
        setLoading(true);
        try {
            const data = await ReportService.getReports(activeTab);
            setReports(data as Report[]);
        } catch (error) {
            console.error('Reports fetch error:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchStats = async () => {
        try {
            const [all, pending, reviewed, actionTaken] = await Promise.all([
                ReportService.getReports('all'),
                ReportService.getReports('pending'),
                ReportService.getReports('reviewed'),
                ReportService.getReports('action_taken'),
            ]);
            setStats({
                total: (all as Report[]).length,
                pending: (pending as Report[]).length,
                resolved: (reviewed as Report[]).length,
                actionTaken: (actionTaken as Report[]).length,
            });
        } catch (e) {
            console.error(e);
        }
    };

    const handleAction = async (reportId: string, status: Report['status'], collectionName: string = 'reports') => {
        try {
            await ReportService.updateReportStatus(reportId, status, actionNote || undefined, collectionName);
            setReports(prev => prev.filter((r) => r.id !== reportId));
            setSelectedReport(null);
            setActionNote('');
            fetchStats();
        } catch (error) {
            alert('İşlem başarısız');
        }
    };

    const handleBanUser = async (report: Report) => {
        if (!confirm(`${report.reportedUserName} kullanıcısını ${banDuration === -1 ? 'KALICI' : banDuration + ' gün'} banlamak istediğinize emin misiniz?`)) return;

        try {
            await UserService.updateUserStatus(report.reportedUserId, 'ban');
            const resolution = `Kullanıcı ${banDuration === -1 ? 'kalıcı olarak' : banDuration + ' gün'} banlandı. Neden: ${banReason || report.reason}`;
            await ReportService.updateReportStatus(report.id, 'action_taken', resolution, report.collection);
            setReports(prev => prev.filter((r) => r.id !== report.id));
            setShowBanModal(false);
            setSelectedReport(null);
            setBanReason('');
            fetchStats();
            alert('✅ Kullanıcı başarıyla banlandı.');
        } catch (error) {
            alert('❌ Banlama işlemi başarısız oldu.');
        }
    };

    const handleWarnUser = async (report: Report) => {
        try {
            // Uyarı veren kullanıcıyı güncelle
            await UserService.updateUser(report.reportedUserId, {
                reportCount: (report as any).reportCount ? (report as any).reportCount + 1 : 1
            } as any);
            const resolution = `Kullanıcıya uyarı verildi. Not: ${actionNote || 'Topluluk kurallarına aykırı davranış'}`;
            await ReportService.updateReportStatus(report.id, 'action_taken', resolution, report.collection);
            setReports(prev => prev.filter(r => r.id !== report.id));
            setSelectedReport(null);
            setActionNote('');
            fetchStats();
            alert('✅ Kullanıcıya uyarı verildi.');
        } catch (error) {
            alert('❌ İşlem başarısız.');
        }
    };

    const getPriorityColor = (priority: string) => {
        switch (priority) {
            case 'critical': return 'text-red-500 bg-red-500/10';
            case 'high': return 'text-rose-500 bg-rose-500/10';
            case 'medium': return 'text-amber-500 bg-amber-500/10';
            default: return 'text-blue-400 bg-blue-500/10';
        }
    };

    const getReasonDisplayName = (reason: string) => {
        const map: Record<string, string> = {
            'spam': 'Spam / Reklam',
            'fake_profile': 'Sahte Profil',
            'inappropriate_content': 'Uygunsuz İçerik',
            'harassment': 'Taciz / Zorbalık',
            'underage': 'Reşit Olmayan Kullanıcı',
            'scam': 'Dolandırıcılık',
            'hate_speech': 'Nefret Söylemi',
            'violence': 'Şiddet İçerikli',
            'sexual_content': 'Cinsel İçerik',
            'impersonation': 'Kimlik Taklidi',
            'other': 'Diğer',
        };
        return map[reason] || reason;
    };

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col">
                <Header />
                <main className="flex-1 overflow-y-auto pb-24 md:pb-6 custom-scrollbar">
                    {/* Stats */}
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 p-4 md:p-6">
                        <StatCard
                            title="Toplam Şikayet"
                            value={stats.total}
                            icon={<span className="material-symbols-outlined text-xl">report</span>}
                            borderColor="border-l-white/40"
                        />
                        <StatCard
                            title="Bekleyenler"
                            value={stats.pending}
                            icon={<span className="material-symbols-outlined text-xl">pending</span>}
                            borderColor="border-l-amber-500"
                        />
                        <StatCard
                            title="İncelenen"
                            value={stats.resolved}
                            icon={<span className="material-symbols-outlined text-xl">visibility</span>}
                            borderColor="border-l-blue-500"
                        />
                        <StatCard
                            title="İşlem Yapılan"
                            value={stats.actionTaken}
                            icon={<span className="material-symbols-outlined text-xl">gavel</span>}
                            borderColor="border-l-rose-500"
                        />
                    </div>

                    {/* Tabs */}
                    <div className="flex border-b border-white/10 px-4 gap-6 sticky top-0 bg-background-dark z-10">
                        {REPORT_CATEGORIES.map((tab) => (
                            <button
                                key={tab.key}
                                onClick={() => setActiveTab(tab.key)}
                                className={cn(
                                    'pb-3 pt-4 text-sm font-bold border-b-[3px] transition-colors',
                                    activeTab === tab.key
                                        ? 'text-white border-primary'
                                        : 'text-white/50 border-transparent hover:text-white/70'
                                )}
                            >
                                {tab.label}
                                {tab.key === 'pending' && stats.pending > 0 && (
                                    <span className="ml-2 px-2 py-0.5 text-[10px] rounded-full bg-rose-500 text-white font-bold">{stats.pending}</span>
                                )}
                            </button>
                        ))}
                    </div>

                    <div className="p-4 md:p-6">
                        {loading ? (
                            <div className="flex justify-center py-20">
                                <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                            </div>
                        ) : (
                            <div className="space-y-4">
                                {reports.length > 0 ? (
                                    reports.map((report) => (
                                        <div key={report.id} className={cn(
                                            "bg-surface-dark rounded-2xl border overflow-hidden transition-all",
                                            selectedReport?.id === report.id ? "border-primary/40 ring-2 ring-primary/10" : "border-white/10 hover:border-white/20"
                                        )}>
                                            {/* Report Header */}
                                            <div
                                                className="p-5 cursor-pointer"
                                                onClick={() => setSelectedReport(selectedReport?.id === report.id ? null : report)}
                                            >
                                                <div className="flex items-start justify-between gap-4">
                                                    <div className="flex items-center gap-3 flex-1">
                                                        <div className={cn("h-12 w-12 rounded-xl flex items-center justify-center flex-shrink-0", getPriorityColor(report.priority))}>
                                                            <span className="material-symbols-outlined text-xl">
                                                                {report.priority === 'critical' ? 'error' : report.priority === 'high' ? 'warning' : 'report'}
                                                            </span>
                                                        </div>
                                                        <div className="min-w-0">
                                                            <div className="flex items-center gap-2 flex-wrap">
                                                                <h4 className="font-bold text-white text-base">
                                                                    {report.reportedUserName}
                                                                </h4>
                                                                <Badge variant={report.type === 'Message' ? 'info' : report.type === 'Story' ? 'warning' : 'default'}>
                                                                    {report.type}
                                                                </Badge>
                                                                <PriorityBadge priority={report.priority} />
                                                            </div>
                                                            <p className="text-xs text-white/40 mt-1">
                                                                <span className="text-white/60 font-medium">{report.reporterName}</span> tarafından raporlandı
                                                                <span className="mx-2">•</span>
                                                                {formatRelativeTime(report.createdAt)}
                                                            </p>
                                                        </div>
                                                    </div>
                                                    <div className="flex items-center gap-2">
                                                        <StatusBadge status={report.status} />
                                                        <span className="material-symbols-outlined text-white/20">
                                                            {selectedReport?.id === report.id ? 'expand_less' : 'expand_more'}
                                                        </span>
                                                    </div>
                                                </div>

                                                {/* Neden ve Açıklama - Özet */}
                                                <div className="mt-3 flex gap-3">
                                                    <div className="px-3 py-1.5 bg-rose-500/10 rounded-lg">
                                                        <span className="text-xs font-bold text-rose-400">
                                                            {getReasonDisplayName(report.reason)}
                                                        </span>
                                                    </div>
                                                    {report.description && (
                                                        <p className="text-sm text-white/50 italic truncate flex-1">
                                                            &ldquo;{report.description.substring(0, 100)}{report.description.length > 100 ? '...' : ''}&rdquo;
                                                        </p>
                                                    )}
                                                </div>
                                            </div>

                                            {/* Expanded Detail */}
                                            {selectedReport?.id === report.id && (
                                                <div className="border-t border-white/5 p-5 space-y-4 bg-white/[0.02]">
                                                    {/* Detaylı Bilgi */}
                                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                        <div className="p-4 bg-white/5 rounded-xl border border-white/5">
                                                            <p className="text-[10px] text-white/30 uppercase font-bold mb-2">🔵 Raporlayan</p>
                                                            <p className="font-bold text-sm text-white">{report.reporterName}</p>
                                                            <p className="text-xs text-white/50">{report.reporterEmail || '-'}</p>
                                                            <p className="text-[10px] text-white/20 mt-1 font-mono">ID: {report.reporterId}</p>
                                                        </div>
                                                        <div className="p-4 bg-rose-500/5 rounded-xl border border-rose-500/10">
                                                            <p className="text-[10px] text-rose-400/70 uppercase font-bold mb-2">🔴 Raporlanan</p>
                                                            <p className="font-bold text-sm text-white">{report.reportedUserName}</p>
                                                            <p className="text-xs text-white/50">{report.reportedUserEmail || '-'}</p>
                                                            <p className="text-[10px] text-white/20 mt-1 font-mono">UID: {report.reportedUserId}</p>
                                                        </div>
                                                    </div>

                                                    {/* Açıklama */}
                                                    {report.description && (
                                                        <div className="bg-white/5 p-4 rounded-xl border border-white/5">
                                                            <p className="text-[10px] text-white/30 uppercase font-bold mb-2">📋 Detaylar / Mesaj İçeriği</p>
                                                            <p className="text-sm text-white/80 italic leading-relaxed">&ldquo;{report.description}&rdquo;</p>
                                                        </div>
                                                    )}

                                                    {/* İşlem Notu */}
                                                    <div>
                                                        <label className="text-xs text-white/40 font-bold">İşlem Notu (opsiyonel)</label>
                                                        <textarea
                                                            className="w-full mt-2 bg-white/5 border border-white/10 rounded-xl p-3 text-sm text-white outline-none focus:border-primary resize-none"
                                                            rows={2}
                                                            placeholder="İşlem hakkında not ekle..."
                                                            value={actionNote}
                                                            onChange={e => setActionNote(e.target.value)}
                                                        />
                                                    </div>

                                                    {/* İşlem Butonları */}
                                                    <div className="flex flex-wrap gap-2 pt-2">
                                                        <Button
                                                            size="sm"
                                                            className="h-10 px-5 bg-rose-600 hover:bg-rose-500 border-none text-white font-bold"
                                                            onClick={() => {
                                                                setShowBanModal(true);
                                                            }}
                                                        >
                                                            <span className="material-symbols-outlined text-sm mr-2">block</span>
                                                            Banla
                                                        </Button>
                                                        <Button
                                                            size="sm"
                                                            className="h-10 px-5 bg-amber-600 hover:bg-amber-500 border-none text-white font-bold"
                                                            onClick={() => handleWarnUser(report)}
                                                        >
                                                            <span className="material-symbols-outlined text-sm mr-2">warning</span>
                                                            Uyar
                                                        </Button>
                                                        <Button
                                                            size="sm"
                                                            className="h-10 px-5 bg-emerald-600 hover:bg-emerald-500 border-none text-white"
                                                            onClick={() => handleAction(report.id, 'action_taken', report.collection)}
                                                        >
                                                            <span className="material-symbols-outlined text-sm mr-2">check_circle</span>
                                                            Çözüldü
                                                        </Button>
                                                        <Button
                                                            size="sm"
                                                            variant="ghost"
                                                            className="h-10 px-5 text-blue-400 hover:bg-blue-500/10"
                                                            onClick={() => handleAction(report.id, 'reviewed', report.collection)}
                                                        >
                                                            <span className="material-symbols-outlined text-sm mr-2">visibility</span>
                                                            İncelendi
                                                        </Button>
                                                        <Button
                                                            size="sm"
                                                            variant="ghost"
                                                            className="h-10 px-5 text-white/40 hover:bg-white/10"
                                                            onClick={() => handleAction(report.id, 'dismissed', report.collection)}
                                                        >
                                                            <span className="material-symbols-outlined text-sm mr-2">close</span>
                                                            Reddet
                                                        </Button>
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    ))
                                ) : (
                                    <div className="text-center py-32 bg-surface-dark/50 rounded-3xl border border-dashed border-white/10">
                                        <span className="material-symbols-outlined text-7xl mb-4 opacity-10">shield_person</span>
                                        <p className="text-white/40 font-medium">Şu an müdahale gerektiren rapor bulunmuyor.</p>
                                        <p className="text-white/20 text-sm mt-2">Her şey yolunda görünüyor!</p>
                                    </div>
                                )}
                            </div>
                        )}
                    </div>
                </main>
                <BottomNav />
            </div>

            {/* Ban Modal */}
            {showBanModal && selectedReport && (
                <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4" onClick={() => setShowBanModal(false)}>
                    <div className="bg-surface-dark rounded-2xl border border-rose-500/20 w-full max-w-md p-6" onClick={e => e.stopPropagation()}>
                        <div className="flex items-center gap-3 mb-6">
                            <div className="h-12 w-12 rounded-xl bg-rose-500/20 flex items-center justify-center">
                                <span className="material-symbols-outlined text-rose-500 text-2xl">gavel</span>
                            </div>
                            <div>
                                <h3 className="text-lg font-bold text-white">Kullanıcıyı Banla</h3>
                                <p className="text-xs text-white/40">{selectedReport.reportedUserName}</p>
                            </div>
                        </div>

                        {/* Süre seçimi */}
                        <p className="text-sm font-bold text-white/50 mb-3">Ban Süresi</p>
                        <div className="grid grid-cols-3 gap-2 mb-4">
                            {BAN_DURATIONS.map(d => (
                                <button
                                    key={d.days}
                                    onClick={() => setBanDuration(d.days)}
                                    className={cn(
                                        "py-3 rounded-xl text-sm font-bold border transition-all",
                                        banDuration === d.days
                                            ? "bg-rose-500/20 text-rose-400 border-rose-500/40"
                                            : "bg-white/5 text-white/40 border-white/5 hover:bg-white/10"
                                    )}
                                >
                                    {d.label}
                                </button>
                            ))}
                        </div>

                        <div className="mb-4">
                            <label className="text-xs font-bold text-white/40 block mb-2">Ban Nedeni</label>
                            <textarea
                                className="w-full bg-white/5 border border-white/10 rounded-xl p-3 text-sm text-white outline-none focus:border-rose-500 resize-none"
                                rows={3}
                                placeholder="Banlama sebebini yazın..."
                                value={banReason}
                                onChange={e => setBanReason(e.target.value)}
                            />
                        </div>

                        {/* Play Store Uyumlu Uyarı */}
                        <div className="mb-4 p-3 bg-amber-500/10 rounded-xl border border-amber-500/20">
                            <div className="flex items-center gap-2 text-amber-500 text-xs font-bold mb-1">
                                <span className="material-symbols-outlined text-sm">info</span>
                                Play Store Uyumluluk
                            </div>
                            <p className="text-[11px] text-amber-400/70">
                                Banlama kararı kullanıcıya bildirim olarak iletilecek ve itiraz hakkı sunulacaktır. Bu Google Play Store geliştirici politikalarına uygundur.
                            </p>
                        </div>

                        <div className="flex gap-3">
                            <Button variant="ghost" className="flex-1 h-12" onClick={() => setShowBanModal(false)}>İptal</Button>
                            <Button
                                className="flex-1 h-12 bg-rose-600 hover:bg-rose-500 border-none"
                                onClick={() => handleBanUser(selectedReport)}
                            >
                                <span className="material-symbols-outlined text-sm mr-2">block</span>
                                Banla
                            </Button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
