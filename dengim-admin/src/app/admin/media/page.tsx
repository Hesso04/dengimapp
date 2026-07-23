'use client';

import React, { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { StatCard } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
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
        if (!confirm(`"${item.fileName}" medyasını kaldırmak istediğinize emin misiniz?`)) return;

        setDeletingId(item.id);
        try {
            const success = await MediaService.deleteMedia(item.fullPath, item.url);
            if (success) {
                setMediaItems(prev => prev.filter(m => m.id !== item.id));
                if (selectedItem?.id === item.id) setSelectedItem(null);
                alert("Medya başarıyla kaldırıldı.");
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
        if (!confirm(`${userName || 'Bu kullanıcıyı'} engellemek ve profiline erişimi dondurmak istiyor musunuz?`)) return;

        try {
            await UserService.updateUserStatus(userId, 'ban');
            alert("Kullanıcı başarıyla engellendi.");
        } catch (e) {
            alert("Kullanıcı banlanırken hata oluştu.");
        }
    };

    const handleVerifyUser = async (userId: string, userName?: string) => {
        try {
            await UserService.updateUserStatus(userId, 'verify');
            alert(`${userName || 'Kullanıcıya'} Mavi Tik rozeti başarıyla tanımlandı.`);
        } catch (e) {
            alert("Doğrulama hatası oluştu.");
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
        <div className="flex min-h-screen bg-background-dark text-white">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">

                    {/* Header Strip */}
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                        <div>
                            <h1 className="text-2xl font-bold text-white mb-1 flex items-center gap-2">
                                <span className="material-symbols-outlined text-primary text-2xl">perm_media</span>
                                Medya Tarayıcı & Sunucu Doluluk Kontrolü
                            </h1>
                            <p className="text-zinc-400 text-sm">
                                Uygulamadaki tüm profil görselleri, sohbet medyaları, ses kayıtları ve müstehcenlik denetim merkezi.
                            </p>
                        </div>
                        <Button onClick={loadMediaData} variant="outline" size="sm" className="border-zinc-700 bg-zinc-900 hover:bg-zinc-800 text-zinc-200">
                            <span className="material-symbols-outlined text-base mr-1">refresh</span>
                            Taramayı Yenile
                        </Button>
                    </div>

                    {/* Stats Grid */}
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                        <StatCard
                            title="Sunucu Doluluk"
                            value={stats.formattedSize}
                            subValue={`${stats.totalFiles} toplam medya kaydı`}
                            icon={<span className="material-symbols-outlined text-2xl text-primary">hard_drive</span>}
                            borderColor="border-l-primary"
                        />
                        <StatCard
                            title="Görsel Sayısı"
                            value={stats.imagesCount}
                            subValue="Profil & Sohbet fotoğrafları"
                            icon={<span className="material-symbols-outlined text-2xl text-emerald-400">image</span>}
                            borderColor="border-l-emerald-500"
                        />
                        <StatCard
                            title="Video Kayıtları"
                            value={stats.videosCount}
                            subValue="Yüklenen medya videoları"
                            icon={<span className="material-symbols-outlined text-2xl text-blue-400">videocam</span>}
                            borderColor="border-l-blue-500"
                        />
                        <StatCard
                            title="Ses Dosyaları"
                            value={stats.audioCount}
                            subValue="Sesli mesajlar & Odalar"
                            icon={<span className="material-symbols-outlined text-2xl text-amber-400">mic</span>}
                            borderColor="border-l-amber-500"
                        />
                    </div>

                    {/* High Contrast Filter & Search Bar */}
                    <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mb-6 bg-zinc-900/90 p-4 rounded-2xl border border-zinc-800 shadow-lg">
                        <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto">
                            {(['all', 'image', 'video', 'audio'] as const).map(type => (
                                <button
                                    key={type}
                                    onClick={() => setFilterType(type)}
                                    className={cn(
                                        "px-4 py-2.5 rounded-xl text-xs font-bold transition-all border whitespace-nowrap",
                                        filterType === type
                                            ? "bg-primary text-black border-primary font-extrabold shadow-lg"
                                            : "bg-zinc-950 text-zinc-300 border-zinc-800 hover:bg-zinc-800 hover:text-white"
                                    )}
                                >
                                    {type === 'all' ? 'Tüm Medyalar' : type === 'image' ? 'Fotoğraflar' : type === 'video' ? 'Videolar' : 'Ses Kayıtları'}
                                </button>
                            ))}
                        </div>

                        <div className="relative w-full sm:w-80">
                            <span className="material-symbols-outlined absolute left-3 top-2.5 text-zinc-400 text-sm">search</span>
                            <input
                                type="text"
                                placeholder="Kullanıcı adı veya e-posta ara..."
                                value={searchUser}
                                onChange={(e) => setSearchUser(e.target.value)}
                                className="w-full bg-zinc-950 border border-zinc-800 rounded-xl pl-9 pr-4 py-2.5 text-xs text-white placeholder:text-zinc-500 focus:outline-none focus:border-primary transition-all"
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
                                    className="group bg-zinc-900 rounded-2xl border border-zinc-800 overflow-hidden flex flex-col justify-between hover:border-primary/60 transition-all shadow-md"
                                >
                                    <div className="aspect-square relative bg-black/60 overflow-hidden flex items-center justify-center">
                                        {item.type === 'image' ? (
                                            <img
                                                src={item.url}
                                                alt={item.fileName}
                                                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                                                loading="lazy"
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
                                        <div className="absolute inset-0 bg-black/75 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2 p-2">
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
                                                className="h-10 w-10 rounded-xl bg-rose-600/80 hover:bg-rose-600 text-white flex items-center justify-center transition-colors"
                                                title="Medyayı Sil"
                                            >
                                                <span className="material-symbols-outlined text-lg">delete</span>
                                            </button>
                                        </div>
                                    </div>

                                    {/* Item Footer */}
                                    <div className="p-3 bg-zinc-950 border-t border-zinc-800">
                                        <div className="flex items-center gap-2.5">
                                            <Avatar src={item.userPhoto} name={item.userName} size="sm" />
                                            <div className="min-w-0 flex-1">
                                                <p className="text-xs font-bold text-zinc-100 truncate">{item.userName}</p>
                                                <p className="text-[10px] text-zinc-400 truncate">
                                                    {(item.size / 1024).toFixed(0)} KB • {formatRelativeTime(item.timeCreated)}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <div className="py-20 text-center bg-zinc-900/60 rounded-2xl border border-zinc-800">
                            <span className="material-symbols-outlined text-5xl mb-3 text-zinc-500">perm_media</span>
                            <p className="text-base font-bold text-zinc-200">Hiç medya dosyası bulunamadı.</p>
                            <p className="text-xs text-zinc-400 mt-1">Seçilen filtreler altında medya mevcut değil veya henüz yükleme yapılmadı.</p>
                        </div>
                    )}

                    {/* High Contrast Detail Modal */}
                    {selectedItem && (
                        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
                            <div className="bg-zinc-900 border border-zinc-700 rounded-3xl max-w-2xl w-full overflow-hidden shadow-2xl animate-scale-up">
                                <div className="p-4 border-b border-zinc-800 flex items-center justify-between bg-zinc-950">
                                    <h3 className="font-bold text-white text-base flex items-center gap-2">
                                        <span className="material-symbols-outlined text-primary">visibility</span>
                                        Medya & Profil İnceleme
                                    </h3>
                                    <button
                                        onClick={() => setSelectedItem(null)}
                                        className="h-8 w-8 rounded-full bg-zinc-800 hover:bg-zinc-700 text-zinc-300 hover:text-white flex items-center justify-center"
                                    >
                                        <span className="material-symbols-outlined text-lg">close</span>
                                    </button>
                                </div>

                                <div className="p-6 space-y-6">
                                    <div className="aspect-video bg-black rounded-2xl overflow-hidden flex items-center justify-center border border-zinc-800">
                                        {selectedItem.type === 'image' ? (
                                            <img src={selectedItem.url} alt="Büyük Görsel" className="max-h-full max-w-full object-contain" />
                                        ) : selectedItem.type === 'video' ? (
                                            <video src={selectedItem.url} controls className="max-h-full max-w-full" />
                                        ) : (
                                            <audio src={selectedItem.url} controls className="w-4/5" />
                                        )}
                                    </div>

                                    <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-zinc-950 p-4 rounded-2xl border border-zinc-800">
                                        <div className="flex items-center gap-3">
                                            <Avatar src={selectedItem.userPhoto} name={selectedItem.userName} size="md" />
                                            <div>
                                                <p className="font-bold text-white text-sm">{selectedItem.userName}</p>
                                                <p className="text-xs text-zinc-400">{selectedItem.userEmail || selectedItem.userId}</p>
                                            </div>
                                        </div>

                                        <div className="flex flex-wrap gap-2">
                                            <Button
                                                variant="outline"
                                                size="sm"
                                                onClick={() => handleVerifyUser(selectedItem.userId, selectedItem.userName)}
                                                className="border-amber-500/30 text-amber-400 hover:bg-amber-500/10"
                                            >
                                                <span className="material-symbols-outlined text-base mr-1">verified</span>
                                                Mavi Tik Ver
                                            </Button>
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
                                                className="bg-zinc-800 border-zinc-700 text-zinc-200 hover:bg-zinc-700"
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
