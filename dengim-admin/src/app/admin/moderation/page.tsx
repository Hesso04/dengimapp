'use client';

import React, { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { StatCard } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { cn, formatRelativeTime } from '@/lib/utils';
import { UserService } from '@/services/userService';
import { VerificationService } from '@/services/verificationService';
import { ReportService } from '@/services/reportService';
import { SettingsService, ModerationSettings } from '@/services/settingsService';
import { User, VerificationRequest, Report } from '@/types';

export default function ModerationPage() {
    const [activeTab, setActiveTab] = useState<'photos' | 'bios' | 'id_verify' | 'reports' | 'settings'>('photos');
    const [pendingUsers, setPendingUsers] = useState<User[]>([]);
    const [pendingBios, setPendingBios] = useState<User[]>([]);
    const [verificationRequests, setVerificationRequests] = useState<VerificationRequest[]>([]);
    const [reports, setReports] = useState<Report[]>([]);
    const [settings, setSettings] = useState<ModerationSettings>({
        profanityFilter: true,
        aiPhotoCheck: false,
        autoShadowBan: true,
        reportThreshold: 5
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (activeTab === 'photos') fetchPending();
        else if (activeTab === 'bios') fetchBios();
        else if (activeTab === 'id_verify') fetchVerifications();
        else if (activeTab === 'reports') fetchReports();
        else if (activeTab === 'settings') fetchSettings();
    }, [activeTab]);

    useEffect(() => {
        // İlk yüklemede tüm sayıları güncellemek için hepsini çek
        fetchPending();
        fetchBios();
        fetchVerifications();
        fetchReports();
        fetchSettings();
    }, []);

    const toggleSetting = async (key: keyof ModerationSettings) => {
        const newValue = !settings[key];
        setSettings(prev => ({ ...prev, [key]: newValue }));
        try {
            await SettingsService.updateModerationSettings({ [key]: newValue });
        } catch (error) {
            console.error(error);
            alert('Ayar güncellenirken hata oluştu');
            setSettings(prev => ({ ...prev, [key]: !newValue }));
        }
    };

    const fetchPending = async () => {
        setLoading(true);
        try {
            const data = await UserService.getPendingVerifications();
            setPendingUsers(data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const fetchBios = async () => {
        setLoading(true);
        try {
            const data = await UserService.getFlaggedBios();
            setPendingBios(data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const fetchVerifications = async () => {
        setLoading(true);
        try {
            const data = await VerificationService.getPendingRequests();
            setVerificationRequests(data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const fetchReports = async () => {
        setLoading(true);
        try {
            const data = await ReportService.getReports('pending');
            setReports(data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const fetchSettings = async () => {
        try {
            const data = await SettingsService.getModerationSettings();
            setSettings(data);
        } catch (error) {
            console.error(error);
        }
    };

    const handleVerifyUser = async (userId: string, status: 'verify' | 'ban') => {
        try {
            await UserService.updateUserStatus(userId, status);
            setPendingUsers((prev: User[]) => prev.filter((u: User) => u.id !== userId));
        } catch (error) {
            alert('Hata oluştu');
        }
    };

    const handleVerificationAction = async (requestId: string, userId: string, action: 'approve' | 'reject') => {
        try {
            if (action === 'approve') {
                await VerificationService.approveRequest(requestId, userId);
            } else {
                const reason = prompt('Reddetme nedeni:') || 'Düşük kaliteli selfie veya yetersiz bilgi';
                await VerificationService.rejectRequest(requestId, userId, reason);
            }
            setVerificationRequests((prev: VerificationRequest[]) => prev.filter((r: VerificationRequest) => r.id !== requestId));
        } catch (error) {
            alert('Hata oluştu');
        }
    };

    const handleReportAction = async (reportId: string, action: 'reviewed' | 'dismissed' | 'action_taken', collection: string) => {
        try {
            await ReportService.updateReportStatus(reportId, action, undefined, collection);
            setReports((prev: Report[]) => prev.filter((r: Report) => r.id !== reportId));
        } catch (error) {
            alert('Hata oluştu');
        }
    };

    const handleBanUserFromReport = async (report: Report) => {
        if (!confirm(`${report.reportedUserName} kullanıcısını banlamak istediğinize emin misiniz?`)) return;
        setLoading(true);
        try {
            await UserService.updateUserStatus(report.reportedUserId, 'ban');
            await ReportService.updateReportStatus(report.id, 'action_taken', 'Kullanıcı banlandı.', report.collection);
            setReports((prev: Report[]) => prev.filter((r: Report) => r.id !== report.id));
            alert('Kullanıcı başarıyla banlandı.');
        } catch (error) {
            console.error(error);
            alert('Banlama işlemi başarısız oldu.');
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateBio = async (userId: string, action: 'approve' | 'reject') => {
        try {
            if (action === 'reject') {
                await UserService.updateUser(userId, { bio: '' });
            }
            setPendingBios((prev: User[]) => prev.filter((u: User) => u.id !== userId));
        } catch (error) {
            alert('Hata oluştu');
        }
    };

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col">
                <Header />
                <main className="flex-1 overflow-y-auto pb-24 md:pb-6 custom-scrollbar text-white">
                    {/* Stats */}
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 p-4 md:p-6 text-white">
                        <StatCard
                            title="Fotoğraf Onayı"
                            value={pendingUsers.length}
                            icon={<span className="material-symbols-outlined text-xl">image</span>}
                            borderColor="border-l-primary"
                        />
                        <StatCard
                            title="Biyografi Kontrol"
                            value={pendingBios.length}
                            icon={<span className="material-symbols-outlined text-xl">description</span>}
                            borderColor="border-l-amber-500"
                        />
                        <StatCard
                            title="Mavi Tik İstekleri"
                            value={verificationRequests.length}
                            icon={<span className="material-symbols-outlined text-xl">verified</span>}
                            borderColor="border-l-blue-500"
                        />
                        <StatCard
                            title="Bekleyen Şikayetler"
                            value={reports.length}
                            icon={<span className="material-symbols-outlined text-xl">report</span>}
                            borderColor="border-l-rose-500"
                        />
                    </div>

                    {/* Tabs */}
                    <div className="flex border-b border-white/10 px-4 gap-6 sticky top-0 bg-background-dark z-10">
                        {[
                            { key: 'photos', label: 'Fotoğraf Onayı', count: pendingUsers.length },
                            { key: 'bios', label: 'İçerik Kontrol', count: pendingBios.length },
                            { key: 'reports', label: 'Şikayet Kontrol', count: reports.length },
                            { key: 'id_verify', label: 'Mavi Tik Onayı', count: verificationRequests.length },
                            { key: 'settings', label: 'Kurallar' },
                        ].map((tab: { key: string; label: string; count?: number }) => (
                            <button
                                key={tab.key}
                                onClick={() => setActiveTab(tab.key as any)}
                                className={cn(
                                    'pb-3 pt-4 text-sm font-bold border-b-[3px] transition-colors',
                                    activeTab === tab.key
                                        ? 'text-white border-primary'
                                        : 'text-white/50 border-transparent hover:text-white/70'
                                )}
                            >
                                {tab.label}
                                {tab.count !== undefined && (
                                    <span className={cn(
                                        'ml-2 px-1.5 py-0.5 text-[10px] rounded',
                                        activeTab === tab.key ? 'bg-primary text-black' : 'bg-white/10'
                                    )}>
                                        {tab.count}
                                    </span>
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
                            <>
                                {activeTab === 'photos' && (
                                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                                        {pendingUsers.length > 0 ? pendingUsers.map((user: User) => (
                                            <div key={user.id} className="bg-surface-dark rounded-2xl border border-white/10 overflow-hidden group">
                                                <div className="aspect-[3/4] relative bg-white/5">
                                                    {user.photos && user.photos.length > 0 ? (
                                                        <img src={user.photos[0]} alt={user.name} className="w-full h-full object-cover" />
                                                    ) : (
                                                        <div className="flex items-center justify-center h-full text-white/20">
                                                            <span className="material-symbols-outlined text-6xl">person</span>
                                                        </div>
                                                    )}
                                                    <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-4">
                                                        <button
                                                            onClick={() => handleVerifyUser(user.id, 'verify')}
                                                            className="h-14 w-14 rounded-full bg-emerald-500 flex items-center justify-center text-white hover:bg-emerald-400"
                                                        >
                                                            <span className="material-symbols-outlined">check</span>
                                                        </button>
                                                        <button
                                                            onClick={() => handleVerifyUser(user.id, 'ban')}
                                                            className="h-14 w-14 rounded-full bg-rose-500 flex items-center justify-center text-white hover:bg-rose-400"
                                                        >
                                                            <span className="material-symbols-outlined">close</span>
                                                        </button>
                                                    </div>
                                                </div>
                                                <div className="p-4">
                                                    <h4 className="font-bold text-white text-sm truncate">{user.name}</h4>
                                                    <p className="text-xs text-white/40">{formatRelativeTime(user.createdAt)} kayıt oldu</p>
                                                </div>
                                            </div>
                                        )) : (
                                            <div className="col-span-full py-20 text-center text-white/20">
                                                <span className="material-symbols-outlined text-6xl mb-4">verified</span>
                                                <p>Onay bekleyen içerik bulunmuyor.</p>
                                            </div>
                                        )}
                                    </div>
                                )}

                                {activeTab === 'id_verify' && (
                                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                                        {verificationRequests.length > 0 ? verificationRequests.map((req: VerificationRequest) => (
                                            <div key={req.id} className="bg-surface-dark rounded-2xl border border-white/10 overflow-hidden group">
                                                <div className="aspect-[3/4] relative bg-white/5">
                                                    <img src={req.selfieUrl} alt={req.email} className="w-full h-full object-cover" />
                                                    <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-4">
                                                        <button
                                                            onClick={() => handleVerificationAction(req.id, req.userId, 'approve')}
                                                            className="h-14 w-14 rounded-full bg-emerald-500 flex items-center justify-center text-white hover:bg-emerald-400"
                                                            title="Onayla"
                                                        >
                                                            <span className="material-symbols-outlined">check</span>
                                                        </button>
                                                        <button
                                                            onClick={() => handleVerificationAction(req.id, req.userId, 'reject')}
                                                            className="h-14 w-14 rounded-full bg-rose-500 flex items-center justify-center text-white hover:bg-rose-400"
                                                            title="Reddet"
                                                        >
                                                            <span className="material-symbols-outlined">close</span>
                                                        </button>
                                                    </div>
                                                </div>
                                                <div className="p-4">
                                                    <h4 className="font-bold text-white text-sm truncate">{req.email}</h4>
                                                    <p className="text-xs text-white/40">{formatRelativeTime(req.createdAt)}</p>
                                                    <Badge className="mt-2" variant="warning">Onay Bekliyor</Badge>
                                                </div>
                                            </div>
                                        )) : (
                                            <div className="col-span-full py-20 text-center text-white/20">
                                                <span className="material-symbols-outlined text-6xl mb-4">face</span>
                                                <p>Onay bekleyen kimlik doğrulaması bulunmuyor.</p>
                                            </div>
                                        )}
                                    </div>
                                )}

                                {activeTab === 'reports' && (
                                    <div className="space-y-4">
                                        {reports.length > 0 ? reports.map((report: Report) => (
                                            <div key={report.id} className="bg-surface-dark rounded-xl border border-white/10 p-4">
                                                <div className="flex justify-between items-start mb-3">
                                                    <div className="flex items-center gap-3">
                                                        <div className={cn(
                                                            "h-10 w-10 rounded-full flex items-center justify-center",
                                                            report.priority === 'high' || report.priority === 'critical' ? 'bg-rose-500/20 text-rose-500' : 'bg-amber-500/20 text-amber-500'
                                                        )}>
                                                            <span className="material-symbols-outlined">report</span>
                                                        </div>
                                                        <div>
                                                            <div className="flex items-center gap-2">
                                                                <h4 className="font-bold text-white text-sm">
                                                                    {report.reportedUserName} {report.reportedUserEmail ? `(${report.reportedUserEmail})` : ''}
                                                                </h4>
                                                                <Badge variant={report.priority === 'high' || report.priority === 'critical' ? 'danger' : 'warning'}>
                                                                    {report.priority === 'critical' ? 'Kritik' : report.priority === 'high' ? 'Yüksek' : 'Orta'}
                                                                </Badge>
                                                                <Badge variant="default">{report.type}</Badge>
                                                            </div>
                                                            <p className="text-xs text-white/40">
                                                                <span className="font-bold text-white/60">{report.reporterName}</span> tarafından raporlandı • {formatRelativeTime(report.createdAt)}
                                                            </p>
                                                        </div>
                                                    </div>
                                                    <div className="flex flex-wrap gap-2">
                                                        <Button
                                                            size="sm"
                                                            variant="secondary"
                                                            className="h-9 px-4 bg-rose-600 hover:bg-rose-500 border-none text-white font-bold"
                                                            onClick={() => handleBanUserFromReport(report)}
                                                        >
                                                            <span className="material-symbols-outlined text-sm mr-1">block</span>
                                                            Banla
                                                        </Button>
                                                        <Button
                                                            size="sm"
                                                            variant="secondary"
                                                            className="h-9 px-4 bg-emerald-500 hover:bg-emerald-400 border-none"
                                                            onClick={() => handleReportAction(report.id, 'action_taken', report.collection)}
                                                        >
                                                            Onayla
                                                        </Button>
                                                        <Button
                                                            size="sm"
                                                            variant="ghost"
                                                            className="h-9 px-4 text-blue-400 hover:bg-blue-500/10"
                                                            onClick={() => handleReportAction(report.id, 'reviewed', report.collection)}
                                                        >
                                                            İncelendi
                                                        </Button>
                                                        <Button
                                                            size="sm"
                                                            variant="ghost"
                                                            className="h-9 px-4 text-white/40 hover:bg-white/10"
                                                            onClick={() => handleReportAction(report.id, 'dismissed', report.collection)}
                                                        >
                                                            Reddet
                                                        </Button>
                                                    </div>
                                                </div>
                                                <div className="bg-white/5 p-4 rounded-xl text-white/80 text-sm leading-relaxed border border-white/5 space-y-2">
                                                    <div className="flex items-center gap-2 text-rose-400 text-xs font-bold uppercase">
                                                        <span className="material-symbols-outlined text-xs">info</span>
                                                        Neden: {report.reasonDisplayName || report.reason}
                                                    </div>
                                                    <p className="italic">"{report.description}"</p>
                                                </div>
                                            </div>
                                        )) : (
                                            <div className="py-20 text-center text-white/20">
                                                <span className="material-symbols-outlined text-6xl mb-4">gavel</span>
                                                <p>İncelenecek şikayet bulunmuyor.</p>
                                            </div>
                                        )}
                                    </div>
                                )}

                                {activeTab === 'bios' && (
                                    <div className="space-y-4">
                                        {pendingBios.length > 0 ? pendingBios.map((user: User) => (
                                            <div key={user.id} className="bg-surface-dark rounded-xl border border-white/10 p-4">
                                                <div className="flex justify-between items-start mb-3">
                                                    <div className="flex items-center gap-3">
                                                        <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                                                            <span className="material-symbols-outlined">person</span>
                                                        </div>
                                                        <div>
                                                            <h4 className="font-bold text-white text-sm">{user.name}</h4>
                                                            <p className="text-xs text-white/40">{formatRelativeTime(user.createdAt)}</p>
                                                        </div>
                                                    </div>
                                                    <div className="flex gap-2">
                                                        <Button
                                                            size="sm"
                                                            variant="secondary"
                                                            className="h-9 px-4 bg-emerald-500 hover:bg-emerald-400 border-none"
                                                            onClick={() => handleUpdateBio(user.id, 'approve')}
                                                        >
                                                            Onayla
                                                        </Button>
                                                        <Button
                                                            size="sm"
                                                            variant="ghost"
                                                            className="h-9 px-4 text-rose-500 hover:bg-rose-500/10"
                                                            onClick={() => handleUpdateBio(user.id, 'reject')}
                                                        >
                                                            Kaldır
                                                        </Button>
                                                    </div>
                                                </div>
                                                <div className="bg-white/5 p-4 rounded-xl text-white/80 text-sm leading-relaxed italic border border-white/5">
                                                    "{user.bio}"
                                                </div>
                                            </div>
                                        )) : (
                                            <div className="py-20 text-center text-white/20">
                                                <span className="material-symbols-outlined text-6xl mb-4">description</span>
                                                <p>İncelenecek biyografi bulunmuyor.</p>
                                            </div>
                                        )}
                                    </div>
                                )}

                                {activeTab === 'settings' && (
                                    <div className="max-w-3xl space-y-6">
                                        <div className="bg-surface-dark rounded-2xl border border-white/10 p-6">
                                            <h3 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
                                                <span className="material-symbols-outlined text-primary">gavel</span>
                                                Otomatik Moderasyon Kuralları
                                            </h3>

                                            <div className="space-y-6">
                                                <div className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/5">
                                                    <div>
                                                        <h4 className="font-bold text-sm text-white">Küfür/Hakaret Filtresi</h4>
                                                        <p className="text-xs text-white/40">Biyografilerdeki uygunsuz kelimeleri otomatik temizle</p>
                                                    </div>
                                                    <div
                                                        onClick={() => toggleSetting('profanityFilter')}
                                                        className={`h-6 w-11 rounded-full relative cursor-pointer transition-colors ${settings.profanityFilter ? 'bg-primary' : 'bg-white/10'}`}
                                                    >
                                                        <div className={`absolute top-1 h-4 w-4 bg-white rounded-full shadow-sm transition-all ${settings.profanityFilter ? 'right-1' : 'left-1'}`} />
                                                    </div>
                                                </div>

                                                <div className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/5">
                                                    <div>
                                                        <h4 className="font-bold text-sm text-white">AI Fotoğraf Denetimi</h4>
                                                        <p className="text-xs text-white/40">NSFW içerikleri otomatik olarak reddet</p>
                                                    </div>
                                                    <div
                                                        onClick={() => toggleSetting('aiPhotoCheck')}
                                                        className={`h-6 w-11 rounded-full relative cursor-pointer transition-colors ${settings.aiPhotoCheck ? 'bg-primary' : 'bg-white/10'}`}
                                                    >
                                                        <div className={`absolute top-1 h-4 w-4 bg-white rounded-full shadow-sm transition-all ${settings.aiPhotoCheck ? 'right-1' : 'left-1'}`} />
                                                    </div>
                                                </div>

                                                <div className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/5">
                                                    <div>
                                                        <h4 className="font-bold text-sm text-white">Otomatik Shadow Ban</h4>
                                                        <p className="text-xs text-white/40">Çok sayıda şikayet alanları otomatik gizle</p>
                                                    </div>
                                                    <div
                                                        onClick={() => toggleSetting('autoShadowBan')}
                                                        className={`h-6 w-11 rounded-full relative cursor-pointer transition-colors ${settings.autoShadowBan ? 'bg-primary' : 'bg-white/10'}`}
                                                    >
                                                        <div className={`absolute top-1 h-4 w-4 bg-white rounded-full shadow-sm transition-all ${settings.autoShadowBan ? 'right-1' : 'left-1'}`} />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div className="bg-surface-dark rounded-2xl border border-white/10 p-6">
                                            <h3 className="text-lg font-bold text-white mb-4">Yasaklı Kelime Listesi</h3>
                                            <textarea
                                                className="w-full bg-white/5 border border-white/10 rounded-xl p-4 text-sm text-white/60 focus:border-primary outline-none min-h-[120px]"
                                                placeholder="Virgül ile ayırarak kelimeleri girin... (örn: küfür1, küfür2, reklam)"
                                                defaultValue="bahis, kumar, eskort, +905"
                                            />
                                            <div className="mt-4 flex justify-end">
                                                <Button size="sm">Listeyi Güncelle</Button>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </>
                        )}
                    </div>
                </main>
                <BottomNav />
            </div>
        </div>
    );
}
