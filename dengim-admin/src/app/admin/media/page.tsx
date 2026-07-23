'use client';

import React, { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { StatCard } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Avatar } from '@/components/ui/Avatar';
import { cn, formatRelativeTime } from '@/lib/utils';
import { MediaService } from '@/services/mediaService';
import { UserService } from '@/services/userService';
import { MediaItem, StorageStats } from '@/types';

export default function MediaBrowserPage() {
    const [mediaItems, setMediaItems] = useState<MediaItem[]>([]);
    const [stats, setStats] = useState<StorageStats>({
        totalFiles: 0,
        totalSizeBytes: 0,
        formattedSize: '0 MB',
        imagesCount: 0,
        videosCount: 0,
        audioCount: 0
    });
    const [loading, setLoading] = useState(true);
    const [filterType, setFilterType] = useState<'all' | 'image' | 'video' | 'audio'>('all');
    const [searchUser, setSearchUser] = useState('');
    const [selectedItem, setSelectedItem] = useState<MediaItem | null>(null);
    const [deletingId, setDeletingId] = useState<string | null>(null);

    const loadMediaData = async () => {
        setLoading(true);
        try {
            const data = await MediaService.getAllMedia();
            setMediaItems(data.items);
            setStats(data.stats);
        } catch (error) {
            console.error("Medya verileri yüklenirken hata:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadMediaData();
    }, []);

    const handleDeleteMedia = async (item: MediaItem) => {
        if (!confirm(`"${item.fileName}" medyasını kalıcı olarak silmek istediğinize emin misiniz?`)) return;

        setDeletingId(item.id);
        try {
            const success = await MediaService.deleteMedia(item.fullPath);
            if (success) {
                setMediaItems(prev => prev.filter(m => m.id !== item.id));
                if (selectedItem?.id === item.id) setSelectedItem(null);
                alert("Medya başarıyla silindi.");
            } else {
                alert("Medya silinirken bir hata oluştu.");
            }
        } catch (e) {
            alert("Hata oluştu.");
        } finally {
            setDeletingId(null);
        }
    };

    const handleBanUser = async (userId: string, userName?: string) => {
        if (!confirm(`${userName || 'Bu kullanıcıyı'} yasaklamak ve profiline erişimi engellemek istiyor musunuz?`)) return;

        try {
            await UserService.updateUserStatus(userId, 'ban');
            alert("Kullanıcı başarıyla banlandı.");
        } catch (e) {
            alert("Kullanıcı banlanırken hata oluştu.");
        }
    };

    // Filtreleme
    const filteredItems = mediaItems.filter(item => {
        const matchesType = filterType === 'all' || item.type === filterType;
        const matchesUser = searchUser === '' ||
            (item.userName && item.userName.toLowerCase().includes(searchUser.toLowerCase())) ||
            (item.userEmail && item.userEmail.toLowerCase().includes(searchUser.toLowerCase())) ||
            item.userId.includes(searchUser);
        return matchesType && matchesUser;
    });

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar text-white">

                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                        <div>
                            <h1 className="text-2xl font-bold text-white mb-1">Medya & Sunucu Doluluk Kontrolü</h1>
                            <p className="text-zinc-400 text-sm">Uygulamadaki tüm görsel, video, ses kayıtları ve müstehcenlik denetimi.</p>
                        </div>
                        <Button onClick={loadMediaData} variant="outline" size="sm">
                            <span className="material-symbols-outlined text-base mr-1">refresh</span>
                            Yenile
                        </Button>
                    </div>

                    {/* Stats Grid */}
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                        <StatCard
                            title="Sunucu Doluluk"
                            value={stats.formattedSize}
                            subValue={`${stats.totalFiles} toplam medya dosyası`}
                            icon={<span className="material-symbols-outlined text-2xl">hard_drive</span>}
                            borderColor="border-l-primary"
                        />
                        <StatCard
                            title="Görsel Sayısı"
                            value={stats.imagesCount}
                            subValue="Profil & Chat fotoğrafları"
                            icon={<span className="material-symbols-outlined text-2xl">image</span>}
                            borderColor="border-l-emerald-500"
                        />
                        <StatCard
                            title="Video Kayıtları"
                            value={stats.videosCount}
                            subValue="Yüklenen kısa videolar"
                            icon={<span className="material-symbols-outlined text-2xl">videocam</span>}
                            borderColor="border-l-blue-500"
                        />
                        <StatCard
                            title="Ses Dosyaları"
                            value={stats.audioCount}
                            subValue="Sesli mesajlar & Odalar"
                            icon={<span className="material-symbols-outlined text-2xl">mic</span>}
                            borderColor="border-l-amber-500"
                        />
                    </div>

                    {/* Filter & Search Bar */}
                    <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mb-6 bg-surface-dark p-4 rounded-2xl border border-white/10">
                        <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto">
                            {(['all', 'image', 'video', 'audio'] as const).map(type => (
                                <button
                                    key={type}
                                    onClick={() => setFilterType(type)}
                                    className={cn(
                                        "px-4 py-2 rounded-xl text-xs font-bold transition-all capitalize whitespace-nowrap",
                                        filterType === type
                                            ? "bg-primary text-black"
                                            : "bg-white/5 text-white/60 hover:bg-white/10 hover:text-white"
                                    )}
                                >
                                    {type === 'all' ? 'Tüm Medyalar' : type === 'image' ? 'Fotoğraflar' : type === 'video' ? 'Videolar' : 'Ses Kayıtları'}
                                </button>
                            ))}
                        </div>

                        <div className="relative w-full sm:w-72">
                            <span className="material-symbols-outlined absolute left-3 top-2.5 text-white/40 text-sm">search</span>
                            <input
                                type="text"
                                placeholder="Kullanıcı adı veya e-posta ara..."
                                value={searchUser}
                                onChange={(e) => setSearchUser(e.target.value)}
                                className="w-full bg-white/5 border border-white/10 rounded-xl pl-9 pr-4 py-2 text-xs text-white placeholder:text-white/30 focus:outline-none focus:border-primary"
                            />
                        </div>
                    </div>

                    {/* Media Grid */}
                    {loading ? (
                        <div className="flex justify-center py-20">
                            <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                        </div>
                    ) : filteredItems.length > 0 ? (
                        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4">
                            {filteredItems.map(item => (
                                <div
                                    key={item.id}
                                    className="group bg-surface-dark rounded-2xl border border-white/10 overflow-hidden flex flex-col justify-between hover:border-primary/50 transition-all"
                                >
                                    <div className="aspect-square relative bg-black/40 overflow-hidden">
                                        {item.type === 'image' ? (
                                            <img
                                                src={item.url}
                                                alt={item.fileName}
                                                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                                            />
                                        ) : item.type === 'video' ? (
                                            <video src={item.url} className="w-full h-full object-cover" controls />
                                        ) : (
                                            <div className="flex flex-col items-center justify-center h-full p-4 text-amber-400">
                                                <span className="material-symbols-outlined text-4xl mb-1">graphic_eq</span>
                                                <audio src={item.url} controls className="w-full h-8 scale-90" />
                                            </div>
                                        )}

                                        {/* Action Overlay */}
                                        <div className="absolute inset-0 bg-black/70 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2 p-2">
                                            <button
                                                onClick={() => setSelectedItem(item)}
                                                className="h-10 w-10 rounded-xl bg-white/20 hover:bg-white/40 text-white flex items-center justify-center transition-colors"
                                                title="Detaylı İncele"
                                            >
                                                <span className="material-symbols-outlined text-lg">visibility</span>
                                            </button>
                                            <button
                                                onClick={() => handleDeleteMedia(item)}
                                                disabled={deletingId === item.id}
                                                className="h-10 w-10 rounded-xl bg-rose-500/80 hover:bg-rose-500 text-white flex items-center justify-center transition-colors"
                                                title="Medyayı Sil"
                                            >
                                                <span className="material-symbols-outlined text-lg">delete</span>
                                            </button>
                                        </div>
                                    </div>

                                    {/* Item Footer */}
                                    <div className="p-3 bg-white/[0.02] border-t border-white/5">
                                        <div className="flex items-center gap-2">
                                            <Avatar src={item.userPhoto} name={item.userName} size="sm" />
                                            <div className="min-w-0 flex-1">
                                                <p className="text-xs font-bold text-white truncate">{item.userName}</p>
                                                <p className="text-[10px] text-white/40 truncate">
                                                    {(item.size / 1024).toFixed(0)} KB • {formatRelativeTime(item.timeCreated)}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <div className="py-20 text-center text-white/30 bg-surface-dark rounded-2xl border border-white/5">
                            <span className="material-symbols-outlined text-6xl mb-4">perm_media</span>
                            <p className="text-base font-semibold text-white">Hiç medya dosyası bulunamadı.</p>
                            <p className="text-xs text-white/40 mt-1">Seçilen filtreler altında dosya mevcut değil veya henüz yükleme yapılmadı.</p>
                        </div>
                    )}

                    {/* Detail Modal */}
                    {selectedItem && (
                        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
                            <div className="bg-surface-dark border border-white/10 rounded-3xl max-w-2xl w-full overflow-hidden shadow-2xl animate-scale-up">
                                <div className="p-4 border-b border-white/10 flex items-center justify-between">
                                    <h3 className="font-bold text-white text-base flex items-center gap-2">
                                        <span className="material-symbols-outlined text-primary">visibility</span>
                                        Medya & Profil Detayı
                                    </h3>
                                    <button
                                        onClick={() => setSelectedItem(null)}
                                        className="h-8 w-8 rounded-full hover:bg-white/10 text-white/60 hover:text-white flex items-center justify-center"
                                    >
                                        <span className="material-symbols-outlined text-lg">close</span>
                                    </button>
                                </div>

                                <div className="p-6 space-y-6">
                                    <div className="aspect-video bg-black/60 rounded-2xl overflow-hidden flex items-center justify-center border border-white/5">
                                        {selectedItem.type === 'image' ? (
                                            <img src={selectedItem.url} alt="Büyük Görsel" className="max-h-full max-w-full object-contain" />
                                        ) : selectedItem.type === 'video' ? (
                                            <video src={selectedItem.url} controls className="max-h-full max-w-full" />
                                        ) : (
                                            <audio src={selectedItem.url} controls className="w-4/5" />
                                        )}
                                    </div>

                                    <div className="flex items-center justify-between bg-white/5 p-4 rounded-2xl border border-white/5">
                                        <div className="flex items-center gap-3">
                                            <Avatar src={selectedItem.userPhoto} name={selectedItem.userName} size="md" />
                                            <div>
                                                <p className="font-bold text-white text-sm">{selectedItem.userName}</p>
                                                <p className="text-xs text-white/40">{selectedItem.userEmail || selectedItem.userId}</p>
                                            </div>
                                        </div>

                                        <div className="flex gap-2">
                                            <Button
                                                variant="danger"
                                                size="sm"
                                                onClick={() => handleBanUser(selectedItem.userId, selectedItem.userName)}
                                            >
                                                <span className="material-symbols-outlined text-base mr-1">block</span>
                                                Kullanıcıyı Banla
                                            </Button>
                                            <Button
                                                variant="secondary"
                                                size="sm"
                                                onClick={() => handleDeleteMedia(selectedItem)}
                                            >
                                                <span className="material-symbols-outlined text-base mr-1">delete</span>
                                                Medyayı Sil
                                            </Button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}

                </main>
                <BottomNav />
            </div>
        </div>
    );
}
