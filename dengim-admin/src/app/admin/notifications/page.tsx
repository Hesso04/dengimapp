'use client';

import { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { Card, StatCard } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { cn, formatRelativeTime } from '@/lib/utils';
import { NotificationService } from '@/services/notificationService';
import { Timestamp } from 'firebase/firestore';

export default function NotificationsPage() {
    const [activeTab, setActiveTab] = useState<'push' | 'announcements' | 'history'>('push');
    const [selectedSegment, setSelectedSegment] = useState('all');
    const [counts, setCounts] = useState({ all: 0, premium: 0, new: 0, inactive: 0 });
    const [loading, setLoading] = useState(false);
    const [sentStatus, setSentStatus] = useState<{ message: string; count: number } | null>(null);
    const [history, setHistory] = useState<any[]>([]);
    const [loadingHistory, setLoadingHistory] = useState(false);
    const [announcements, setAnnouncements] = useState<any[]>([]);
    const [loadingAnnouncements, setLoadingAnnouncements] = useState(false);

    // Form State
    const [title, setTitle] = useState('');
    const [body, setBody] = useState('');
    const [imageUrl, setImageUrl] = useState('');

    useEffect(() => {
        const fetchCounts = async () => {
            const data = await NotificationService.getSegmentCounts();
            setCounts(data);
        };
        fetchCounts();
    }, []);

    useEffect(() => {
        if (activeTab === 'history') {
            const fetchHistory = async () => {
                setLoadingHistory(true);
                const data = await NotificationService.getHistory();
                setHistory(data);
                setLoadingHistory(false);
            };
            fetchHistory();
        }
        if (activeTab === 'announcements') {
            const fetchAnnouncements = async () => {
                setLoadingAnnouncements(true);
                const data = await NotificationService.getActiveAnnouncements();
                setAnnouncements(data);
                setLoadingAnnouncements(false);
            };
            fetchAnnouncements();
        }
    }, [activeTab]);

    const handleSend = async () => {
        if (!title || !body) return alert("Başlık ve içeriği doldurun!");

        const confirmMsg = `"${title}" bildirimi ${selectedSegment === 'all' ? 'TÜM' : selectedSegment.toUpperCase()
            } kullanıcılara (${selectedSegment === 'all' ? counts.all :
                selectedSegment === 'premium' ? counts.premium :
                    selectedSegment === 'new' ? counts.new :
                        counts.inactive
            } kişi) gönderilecek. Emin misiniz?`;

        if (!confirm(confirmMsg)) return;

        setLoading(true);
        const result = await NotificationService.sendPushNotification({
            title,
            body,
            segment: selectedSegment,
            imageUrl: imageUrl || undefined
        });

        if (result.success) {
            setSentStatus({
                message: `Bildirim ${result.sentCount} kullanıcıya başarıyla gönderildi!`,
                count: result.sentCount
            });
            setTitle('');
            setBody('');
            setImageUrl('');
            setTimeout(() => setSentStatus(null), 5000);
        } else {
            alert("Bir hata oluştu. Konsolu kontrol edin.");
        }
        setLoading(false);
    };

    const handleDeactivateAnnouncement = async (id: string) => {
        if (!confirm("Bu duyuruyu devre dışı bırakmak istediğinize emin misiniz?")) return;
        const success = await NotificationService.deactivateAnnouncement(id);
        if (success) {
            setAnnouncements(prev => prev.filter(a => a.id !== id));
        }
    };

    const getSegmentLabel = (segment: string) => {
        switch (segment) {
            case 'all': return 'Tüm Kullanıcılar';
            case 'premium': return 'Premium Üyeler';
            case 'new': return 'Yeni Üyeler';
            case 'inactive': return 'İnaktif Üyeler';
            default: return segment;
        }
    };

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col">
                <Header />
                <main className="flex-1 overflow-y-auto pb-24 md:pb-6 custom-scrollbar text-white">
                    {/* Stats */}
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 p-4 md:p-6">
                        <StatCard title="Toplam Kullanıcı" value={counts.all.toLocaleString()} borderColor="border-l-primary" />
                        <StatCard title="Premium Üyeler" value={counts.premium.toLocaleString()} borderColor="border-l-accent-indigo" />
                        <StatCard title="Yeni Üyeler (7g)" value={counts.new.toLocaleString()} borderColor="border-l-accent-emerald" />
                        <StatCard title="İnaktif Üyeler" value={counts.inactive.toLocaleString()} borderColor="border-l-red-500" />
                    </div>

                    {/* Tabs */}
                    <div className="flex border-b border-white/10 px-4 gap-6 sticky top-0 bg-background-dark z-10">
                        {[
                            { key: 'push', label: 'Bildirim Gönder' },
                            { key: 'announcements', label: 'Aktif Duyurular' },
                            { key: 'history', label: 'Geçmiş' },
                        ].map(({ key, label }) => (
                            <button
                                key={key}
                                onClick={() => setActiveTab(key as any)}
                                className={cn(
                                    'pb-3 pt-4 text-sm font-bold border-b-[3px] transition-colors',
                                    activeTab === key ? 'text-white border-primary' : 'text-white/50 border-transparent hover:text-white/70'
                                )}
                            >
                                {label}
                            </button>
                        ))}
                    </div>

                    <div className="p-4 md:p-6">
                        {/* Push Bildirim Gönder */}
                        {activeTab === 'push' && (
                            <div className="max-w-3xl">
                                <Card glass className="mb-6">
                                    <h3 className="text-lg font-bold text-white mb-2">📢 Duyuru Bildirimi Gönder</h3>
                                    <p className="text-xs text-white/40 mb-6">
                                        Bu bildirim seçilen segmentteki tüm kayıtlı kullanıcılara gönderilir.
                                        Ayrıca <strong>yeni kayıt olacak kullanıcılar</strong> da bu duyuruyu bildirim panelinde görebilir.
                                    </p>

                                    {/* Segment Selection */}
                                    <div className="mb-6">
                                        <label className="text-xs font-bold text-white/40 mb-3 block uppercase tracking-wider">Hedef Kitle</label>
                                        <div className="flex flex-wrap gap-2">
                                            {[
                                                { id: 'all', label: 'Tüm Kullanıcılar', count: counts.all, icon: '🌍' },
                                                { id: 'premium', label: 'Premium Üyeler', count: counts.premium, icon: '👑' },
                                                { id: 'new', label: 'Yeni Üyeler (7g)', count: counts.new, icon: '🆕' },
                                                { id: 'inactive', label: 'İnaktif Üyeler', count: counts.inactive, icon: '😴' },
                                            ].map((segment) => (
                                                <button
                                                    key={segment.id}
                                                    onClick={() => setSelectedSegment(segment.id)}
                                                    className={cn(
                                                        'px-4 py-2.5 rounded-xl text-sm font-semibold transition-all border',
                                                        selectedSegment === segment.id
                                                            ? 'bg-primary text-black border-primary'
                                                            : 'bg-white/5 text-white/60 border-white/5 hover:border-white/20'
                                                    )}
                                                >
                                                    {segment.icon} {segment.label}
                                                    <span className="ml-2 opacity-60 text-xs font-bold">{segment.count}</span>
                                                </button>
                                            ))}
                                        </div>
                                    </div>

                                    <div className="space-y-4">
                                        <div>
                                            <label className="text-xs font-bold text-white/40 mb-2 block uppercase tracking-wider">Başlık *</label>
                                            <input
                                                value={title}
                                                onChange={(e) => setTitle(e.target.value)}
                                                placeholder="Örn: 🎉 Yeni Güncelleme Geldi!"
                                                maxLength={100}
                                                className="w-full h-12 bg-white/5 border border-white/10 rounded-xl px-4 text-white focus:border-primary outline-none transition-all"
                                            />
                                            <span className="text-[10px] text-white/20 mt-1 block">{title.length}/100</span>
                                        </div>

                                        <div>
                                            <label className="text-xs font-bold text-white/40 mb-2 block uppercase tracking-wider">İçerik *</label>
                                            <textarea
                                                value={body}
                                                onChange={(e) => setBody(e.target.value)}
                                                rows={3}
                                                maxLength={500}
                                                placeholder="Bildirim detaylarını buraya yazın..."
                                                className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-primary outline-none transition-all resize-none"
                                            />
                                            <span className="text-[10px] text-white/20 mt-1 block">{body.length}/500</span>
                                        </div>

                                        <div>
                                            <label className="text-xs font-bold text-white/40 mb-2 block uppercase tracking-wider">Görsel URL (Opsiyonel)</label>
                                            <input
                                                value={imageUrl}
                                                onChange={(e) => setImageUrl(e.target.value)}
                                                placeholder="https://..."
                                                className="w-full h-12 bg-white/5 border border-white/10 rounded-xl px-4 text-white focus:border-primary outline-none"
                                            />
                                        </div>

                                        {/* Preview */}
                                        {(title || body) && (
                                            <div className="p-4 bg-white/5 rounded-2xl border border-white/10">
                                                <p className="text-[10px] text-white/30 mb-2 uppercase tracking-wider font-bold">Önizleme</p>
                                                <div className="flex gap-3 items-start">
                                                    <div className="h-10 w-10 rounded-full bg-primary/20 flex items-center justify-center shrink-0">
                                                        <span className="material-symbols-outlined text-primary text-lg">campaign</span>
                                                    </div>
                                                    <div>
                                                        <p className="text-white font-bold text-sm">{title || 'Başlık...'}</p>
                                                        <p className="text-white/60 text-xs mt-0.5">{body || 'İçerik...'}</p>
                                                    </div>
                                                </div>
                                            </div>
                                        )}

                                        {sentStatus && (
                                            <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-xl flex items-center gap-3">
                                                <span className="material-symbols-outlined text-emerald-400">check_circle</span>
                                                <div>
                                                    <p className="text-emerald-400 font-bold text-sm">{sentStatus.message}</p>
                                                    <p className="text-emerald-400/60 text-xs">{sentStatus.count} kullanıcıya başarıyla iletildi</p>
                                                </div>
                                            </div>
                                        )}

                                        <Button
                                            onClick={handleSend}
                                            loading={loading}
                                            className="w-full h-14 text-base mt-2"
                                        >
                                            <span className="material-symbols-outlined mr-2">send_to_mobile</span>
                                            {loading ? 'Gönderiliyor...' : 'Bildirimi Hemen Gönder'}
                                        </Button>

                                        <p className="text-[10px] text-white/20 text-center">
                                            ⚠️ Bildirim gönderildiğinde geri alınamaz. Tüm hedef kullanıcılara anında iletilir.
                                        </p>
                                    </div>
                                </Card>
                            </div>
                        )}

                        {/* Aktif Duyurular */}
                        {activeTab === 'announcements' && (
                            <div className="space-y-4 max-w-3xl">
                                <div className="p-4 bg-blue-500/10 border border-blue-500/20 rounded-2xl mb-4">
                                    <p className="text-blue-400 text-sm">
                                        <strong>💡 Not:</strong> Aktif duyurular yeni kayıt olan kullanıcılara da otomatik olarak gösterilir.
                                        Devre dışı bırakılan duyurular artık yeni kullanıcılara gösterilmez.
                                    </p>
                                </div>

                                {loadingAnnouncements ? (
                                    <div className="flex justify-center py-20">
                                        <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                                    </div>
                                ) : announcements.length > 0 ? (
                                    announcements.map((item) => (
                                        <Card key={item.id} padding="sm">
                                            <div className="flex items-start gap-4">
                                                <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                                                    <span className="material-symbols-outlined text-primary">campaign</span>
                                                </div>
                                                <div className="flex-1">
                                                    <div className="flex justify-between items-start mb-1">
                                                        <h4 className="font-bold text-white">{item.title}</h4>
                                                        <button
                                                            onClick={() => handleDeactivateAnnouncement(item.id)}
                                                            className="text-xs text-red-400 hover:text-red-300 bg-red-500/10 px-2 py-1 rounded-lg transition-colors"
                                                        >
                                                            Devre Dışı Bırak
                                                        </button>
                                                    </div>
                                                    <p className="text-sm text-white/60 mb-2">{item.body}</p>
                                                    <div className="flex gap-3 items-center flex-wrap">
                                                        <span className="text-[10px] font-bold text-primary uppercase tracking-tighter bg-primary/10 px-2 py-0.5 rounded">
                                                            {getSegmentLabel(item.segment)}
                                                        </span>
                                                        <span className="text-[10px] text-white/30">
                                                            📤 {item.sentCount || 0} kişiye gönderildi
                                                        </span>
                                                        <span className="text-[10px] text-white/30">
                                                            {item.createdAt instanceof Timestamp
                                                                ? formatRelativeTime(item.createdAt.toDate())
                                                                : 'Az önce'}
                                                        </span>
                                                    </div>
                                                </div>
                                            </div>
                                        </Card>
                                    ))
                                ) : (
                                    <div className="text-center py-24 border border-dashed border-white/10 rounded-3xl opacity-30">
                                        <span className="material-symbols-outlined text-6xl mb-4">campaign</span>
                                        <p>Aktif duyuru bulunmuyor.</p>
                                    </div>
                                )}
                            </div>
                        )}

                        {/* Geçmiş */}
                        {activeTab === 'history' && (
                            <div className="space-y-4 max-w-3xl">
                                {loadingHistory ? (
                                    <div className="flex justify-center py-20">
                                        <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                                    </div>
                                ) : history.length > 0 ? (
                                    history.map((item) => (
                                        <Card key={item.id} padding="sm">
                                            <div className="flex items-start gap-4">
                                                <div className="h-10 w-10 rounded-full bg-white/5 flex items-center justify-center shrink-0">
                                                    <span className="material-symbols-outlined text-white/40">notifications</span>
                                                </div>
                                                <div className="flex-1">
                                                    <div className="flex justify-between items-start mb-1">
                                                        <h4 className="font-bold text-white">{item.title}</h4>
                                                        <span className="text-[10px] text-white/30">
                                                            {item.createdAt instanceof Timestamp
                                                                ? formatRelativeTime(item.createdAt.toDate())
                                                                : 'Az önce'}
                                                        </span>
                                                    </div>
                                                    <p className="text-sm text-white/60 mb-2">{item.body}</p>
                                                    <div className="flex gap-4 items-center flex-wrap">
                                                        <span className="text-[10px] font-bold text-primary uppercase tracking-tighter bg-primary/10 px-2 py-0.5 rounded">
                                                            {getSegmentLabel(item.segment)}
                                                        </span>
                                                        <span className="text-[10px] text-white/30">
                                                            📤 {item.sentCount || 0} / {item.totalTarget || '?'} kişi
                                                        </span>
                                                        <span className={cn(
                                                            "text-[10px] uppercase tracking-tighter font-bold px-2 py-0.5 rounded",
                                                            item.status === 'sent' ? 'text-emerald-400 bg-emerald-500/10' : 'text-yellow-400 bg-yellow-500/10'
                                                        )}>
                                                            {item.status === 'sent' ? '✅ Gönderildi' : '⏳ ' + item.status}
                                                        </span>
                                                    </div>
                                                </div>
                                            </div>
                                        </Card>
                                    ))
                                ) : (
                                    <div className="text-center py-24 border border-dashed border-white/10 rounded-3xl opacity-30">
                                        <span className="material-symbols-outlined text-6xl mb-4">history</span>
                                        <p>Bildirim geçmişi şu an boş.</p>
                                    </div>
                                )}
                            </div>
                        )}
                    </div>
                </main>
                <BottomNav />
            </div>
        </div>
    );
}
