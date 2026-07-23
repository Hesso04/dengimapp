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
    const [counts, setCounts] = useState({ all: 0, premium: 0, new: 0, inactive: 0, male: 0, female: 0 });
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

    // Hazır Taslaklar / Şablonlar
    const notificationTemplates = [
        {
            name: '🎁 Haftasonu Kredi Bonusu',
            title: '🎉 Haftasonuna Özel 50 Ücretsiz Kredi!',
            body: 'Hesabına 50 ücretsiz kredi tanımlandı! Hemen giren ilk kişilerden ol ve yeni eşleşmeler yakala.',
            segment: 'all',
        },
        {
            name: '💖 Profilini Tamamla',
            title: '✨ Profilini Tamamla, 5 Kat Fazla Görün!',
            body: 'Fotoğraf ve ilgi alanlarını tamamlayarak vitrinde öne çıkabilir ve eşleşme şansını katlayabilirsin.',
            segment: 'new',
        },
        {
            name: '👑 Premium Fırsatı',
            title: '🔥 Premium Üyelikte %50 İndirim Fırsatı!',
            body: 'Sınırsız beğeni, süper uyum ve seni beğenenleri görme ayrıcalığı bugün yarı fiyatına!',
            segment: 'inactive',
        },
        {
            name: '🚀 Yeni Güncelleme',
            title: '⚡ DENGİM Yeni Sürümü Yayında!',
            body: 'Performans iyileştirmeleri ve yepyeni görünümle uygulamamızı güncelledik. Hemen keşfet!',
            segment: 'all',
        },
    ];

    const applyTemplate = (template: typeof notificationTemplates[0]) => {
        setTitle(template.title);
        setBody(template.body);
        setSelectedSegment(template.segment);
    };

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
        if (!title || !body) return alert("Lütfen başlık ve içeriği doldurun!");

        const targetCount =
            selectedSegment === 'all' ? counts.all :
            selectedSegment === 'premium' ? counts.premium :
            selectedSegment === 'male' ? counts.male :
            selectedSegment === 'female' ? counts.female :
            selectedSegment === 'new' ? counts.new : counts.inactive;

        const confirmMsg = `"${title}" bildirimi ${selectedSegment.toUpperCase()} segmentindeki ${targetCount} kullanıcıya gönderilecek. Onaylıyor musunuz?`;

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
            alert("Bir hata oluştu.");
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

    return (
        <div className="flex min-h-screen bg-background-dark text-white">
            <Sidebar />
            <div className="flex-1 flex flex-col">
                <Header />
                <main className="flex-1 overflow-y-auto pb-24 md:pb-6 custom-scrollbar">
                    {/* Stats */}
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 p-4 md:p-6">
                        <StatCard title="Toplam Kullanıcı" value={counts.all.toLocaleString()} borderColor="border-l-primary" />
                        <StatCard title="Premium Üyeler" value={counts.premium.toLocaleString()} borderColor="border-l-indigo-500" />
                        <StatCard title="Erkek Kullanıcılar" value={counts.male.toLocaleString()} borderColor="border-l-blue-500" />
                        <StatCard title="Kadın Kullanıcılar" value={counts.female.toLocaleString()} borderColor="border-l-pink-500" />
                    </div>

                    {/* High Contrast Tabs */}
                    <div className="flex border-b border-zinc-800 px-4 gap-6 sticky top-0 bg-background-dark/95 backdrop-blur-md z-10">
                        {[
                            { key: 'push', label: 'Bildirim Gönder & Taslaklar' },
                            { key: 'announcements', label: 'Aktif Duyurular' },
                            { key: 'history', label: 'Gönderim Geçmişi' },
                        ].map(({ key, label }) => (
                            <button
                                key={key}
                                onClick={() => setActiveTab(key as any)}
                                className={cn(
                                    'pb-3 pt-4 text-sm font-bold border-b-[3px] transition-colors',
                                    activeTab === key ? 'text-primary border-primary' : 'text-zinc-400 border-transparent hover:text-white'
                                )}
                            >
                                {label}
                            </button>
                        ))}
                    </div>

                    <div className="p-4 md:p-6">
                        {/* Push Bildirim & Taslaklar */}
                        {activeTab === 'push' && (
                            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                                <div className="lg:col-span-2 space-y-6">
                                    {/* Ready Templates Bar */}
                                    <div className="bg-zinc-900 p-4 rounded-2xl border border-zinc-800">
                                        <label className="text-xs font-bold text-zinc-400 mb-3 block uppercase tracking-wider flex items-center gap-1.5">
                                            <span className="material-symbols-outlined text-primary text-base">auto_awesome</span>
                                            Hızlı Taslaklar (1 Tıkla Doldur)
                                        </label>
                                        <div className="flex flex-wrap gap-2">
                                            {notificationTemplates.map((tpl, i) => (
                                                <button
                                                    key={i}
                                                    onClick={() => applyTemplate(tpl)}
                                                    className="px-3.5 py-2 rounded-xl text-xs font-bold bg-zinc-950 border border-zinc-800 text-zinc-200 hover:border-primary hover:text-white transition-all text-left"
                                                >
                                                    {tpl.name}
                                                </button>
                                            ))}
                                        </div>
                                    </div>

                                    {/* Main Form */}
                                    <div className="bg-zinc-900 p-6 rounded-2xl border border-zinc-800 shadow-xl space-y-6">
                                        <div>
                                            <h3 className="text-lg font-bold text-white mb-1">📢 Push Bildirim & Duyuru Oluştur</h3>
                                            <p className="text-xs text-zinc-400">
                                                Seçilen segmente anında mobil push bildirimi gönderilir ve bildirim merkezine kaydedilir.
                                            </p>
                                        </div>

                                        {sentStatus && (
                                            <div className="p-4 bg-emerald-500/20 border border-emerald-500/40 rounded-xl text-emerald-400 text-sm font-bold flex items-center gap-2">
                                                <span className="material-symbols-outlined">check_circle</span>
                                                {sentStatus.message}
                                            </div>
                                        )}

                                        {/* Segment Selection */}
                                        <div>
                                            <label className="text-xs font-bold text-zinc-400 mb-3 block uppercase tracking-wider">Hedef Kitle</label>
                                            <div className="flex flex-wrap gap-2">
                                                {[
                                                    { id: 'all', label: 'Tüm Kullanıcılar', count: counts.all, icon: '🌍' },
                                                    { id: 'premium', label: 'Premium Üyeler', count: counts.premium, icon: '👑' },
                                                    { id: 'male', label: 'Sadece Erkekler', count: counts.male, icon: '👨' },
                                                    { id: 'female', label: 'Sadece Kadınlar', count: counts.female, icon: '👩' },
                                                    { id: 'new', label: 'Yeni Üyeler (7g)', count: counts.new, icon: '🆕' },
                                                    { id: 'inactive', label: 'İnaktif Üyeler', count: counts.inactive, icon: '😴' },
                                                ].map((segment) => (
                                                    <button
                                                        key={segment.id}
                                                        onClick={() => setSelectedSegment(segment.id)}
                                                        className={cn(
                                                            'px-4 py-2.5 rounded-xl text-xs font-bold transition-all border',
                                                            selectedSegment === segment.id
                                                                ? 'bg-primary text-black border-primary font-extrabold shadow-lg'
                                                                : 'bg-zinc-950 text-zinc-300 border-zinc-800 hover:border-zinc-700'
                                                        )}
                                                    >
                                                        {segment.icon} {segment.label}
                                                        <span className="ml-2 opacity-70 text-[11px] font-extrabold">({segment.count})</span>
                                                    </button>
                                                ))}
                                            </div>
                                        </div>

                                        <div className="space-y-4">
                                            <div>
                                                <label className="text-xs font-bold text-zinc-400 mb-2 block uppercase tracking-wider">Bildirim Başlığı *</label>
                                                <input
                                                    value={title}
                                                    onChange={(e) => setTitle(e.target.value)}
                                                    placeholder="Örn: 🎉 Haftasonu Kredi Bonusu Hesabında!"
                                                    maxLength={100}
                                                    className="w-full h-12 bg-zinc-950 border border-zinc-800 rounded-xl px-4 text-white focus:border-primary outline-none transition-all text-sm"
                                                />
                                            </div>

                                            <div>
                                                <label className="text-xs font-bold text-zinc-400 mb-2 block uppercase tracking-wider">Bildirim İçeriği *</label>
                                                <textarea
                                                    value={body}
                                                    onChange={(e) => setBody(e.target.value)}
                                                    placeholder="Kullanıcıların kilit ekranında görünecek ilgi çekici mesaj..."
                                                    rows={4}
                                                    maxLength={300}
                                                    className="w-full bg-zinc-950 border border-zinc-800 rounded-xl p-4 text-white focus:border-primary outline-none transition-all text-sm"
                                                />
                                            </div>

                                            <div>
                                                <label className="text-xs font-bold text-zinc-400 mb-2 block uppercase tracking-wider">Görsel URL (Opsiyonel)</label>
                                                <input
                                                    value={imageUrl}
                                                    onChange={(e) => setImageUrl(e.target.value)}
                                                    placeholder="https://images.unsplash.com/..."
                                                    className="w-full h-12 bg-zinc-950 border border-zinc-800 rounded-xl px-4 text-white focus:border-primary outline-none transition-all text-sm"
                                                />
                                            </div>
                                        </div>

                                        <Button
                                            onClick={handleSend}
                                            disabled={loading || !title || !body}
                                            className="w-full h-12 text-base font-extrabold bg-primary text-black hover:bg-primary/90"
                                        >
                                            {loading ? 'Gönderiliyor...' : '🚀 Bildirimi Anında Gönder'}
                                        </Button>
                                    </div>
                                </div>

                                {/* Live Preview Card */}
                                <div>
                                    <h4 className="text-xs font-bold text-zinc-400 mb-3 uppercase tracking-wider">Canlı Mobil Önizleme</h4>
                                    <div className="bg-black/90 p-4 rounded-3xl border border-zinc-800 shadow-2xl space-y-3">
                                        <div className="flex items-center justify-between border-b border-zinc-800 pb-3">
                                            <div className="flex items-center gap-2">
                                                <div className="w-6 h-6 rounded-lg bg-primary flex items-center justify-center text-black font-extrabold text-[10px]">D</div>
                                                <span className="text-xs font-bold text-white">DENGİM</span>
                                            </div>
                                            <span className="text-[10px] text-zinc-500">Şimdi</span>
                                        </div>

                                        <div className="space-y-1">
                                            <p className="text-sm font-bold text-white leading-tight">
                                                {title || 'Bildirim Başlığı Buraya Gelecek'}
                                            </p>
                                            <p className="text-xs text-zinc-400 leading-normal">
                                                {body || 'Bildirimin içerik metni kilit ekranında bu şekilde görünecektir.'}
                                            </p>
                                        </div>

                                        {imageUrl && (
                                            <div className="aspect-video rounded-xl overflow-hidden bg-zinc-900 border border-zinc-800">
                                                <img src={imageUrl} alt="Önizleme" className="w-full h-full object-cover" />
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        )}

                        {/* Aktif Duyurular */}
                        {activeTab === 'announcements' && (
                            <div className="bg-zinc-900 rounded-2xl border border-zinc-800 p-6">
                                <h3 className="text-lg font-bold text-white mb-4">Aktif Duyuru Listesi</h3>
                                {loadingAnnouncements ? (
                                    <div className="py-10 text-center text-zinc-400">Yükleniyor...</div>
                                ) : announcements.length > 0 ? (
                                    <div className="space-y-4">
                                        {announcements.map((item) => (
                                            <div key={item.id} className="bg-zinc-950 p-4 rounded-xl border border-zinc-800 flex items-center justify-between">
                                                <div>
                                                    <p className="font-bold text-white text-sm">{item.title}</p>
                                                    <p className="text-xs text-zinc-400 mt-1">{item.body}</p>
                                                </div>
                                                <Button
                                                    variant="danger"
                                                    size="sm"
                                                    onClick={() => handleDeactivateAnnouncement(item.id)}
                                                >
                                                    Devre Dışı Bırak
                                                </Button>
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <div className="text-center py-10 text-zinc-500">Aktif duyuru yok.</div>
                                )}
                            </div>
                        )}

                        {/* Geçmiş */}
                        {activeTab === 'history' && (
                            <div className="bg-zinc-900 rounded-2xl border border-zinc-800 p-6">
                                <h3 className="text-lg font-bold text-white mb-4">Gönderim Geçmişi</h3>
                                {loadingHistory ? (
                                    <div className="py-10 text-center text-zinc-400">Yükleniyor...</div>
                                ) : history.length > 0 ? (
                                    <div className="space-y-3">
                                        {history.map((item) => (
                                            <div key={item.id} className="bg-zinc-950 p-4 rounded-xl border border-zinc-800 flex items-center justify-between">
                                                <div>
                                                    <p className="font-bold text-white text-sm">{item.title}</p>
                                                    <p className="text-xs text-zinc-400 mt-1">{item.body}</p>
                                                </div>
                                                <span className="text-xs text-primary font-bold bg-primary/10 px-3 py-1 rounded-full border border-primary/20">
                                                    {item.sentCount || 0} Kişiye Gönderildi
                                                </span>
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <div className="text-center py-10 text-zinc-500">Gönderim geçmişi yok.</div>
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
