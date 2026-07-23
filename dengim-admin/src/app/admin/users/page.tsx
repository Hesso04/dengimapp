'use client';

import { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { Button } from '@/components/ui/Button';
import { Avatar } from '@/components/ui/Avatar';
import { StatusBadge, TierBadge, Badge } from '@/components/ui/Badge';
import { cn, formatRelativeTime } from '@/lib/utils';
import { User } from '@/types';
import { UserService } from '@/services/userService';

export default function UsersPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('all');
    const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
    const [lastDoc, setLastDoc] = useState<any>(null);
    const [editingUser, setEditingUser] = useState<User | null>(null);
    const [showUserModal, setShowUserModal] = useState(false);

    // Verileri Çek
    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        setLoading(true);
        try {
            const result = await UserService.getUsers(null, 100); // 100 kullanıcı
            setUsers(result.users);
            setLastDoc(result.lastDoc);
        } catch (error) {
            console.error('Kullanıcılar yüklenemedi:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleEdit = (user: User) => {
        setEditingUser({ ...user });
        setShowUserModal(true);
    };

    const handleUpdateUser = async () => {
        if (!editingUser) return;
        try {
            await UserService.updateUser(editingUser.id, editingUser);
            setUsers(prev => prev.map(u => u.id === editingUser.id ? editingUser : u));
            setShowUserModal(false);
            setEditingUser(null);
            alert('Kullanıcı bilgileri başarıyla güncellendi.');
        } catch (error) {
            alert('Güncelleme hatası!');
        }
    };

    const handleGrantVIP = async (userId: string, tier: 'gold' | 'platinum') => {
        try {
            await UserService.grantPremium(userId, tier);
            setUsers(prev => prev.map(u => u.id === userId ? { ...u, isPremium: true, premiumTier: tier } as User : u));
            alert(`Kullanıcıya ${tier.toUpperCase()} VIP üyeliği tanımlandı.`);
        } catch (e) {
            alert("VIP tanımlama hatası.");
        }
    };

    const handleAddCredits = async (userId: string, amount: number) => {
        try {
            await UserService.addCredits(userId, amount);
            alert(`Kullanıcı hesabına +${amount} Kredi yüklendi.`);
        } catch (e) {
            alert("Kredi yükleme hatası.");
        }
    };

    // Filtreleme
    const filteredUsers = users.filter(user => {
        const matchesSearch = (user.name?.toLowerCase() || '').includes(searchQuery.toLowerCase()) ||
            (user.email?.toLowerCase() || '').includes(searchQuery.toLowerCase());
        const matchesStatus = statusFilter === 'all' ||
            (statusFilter === 'active' && user.status === 'active') ||
            (statusFilter === 'verified' && user.isVerified) ||
            (statusFilter === 'banned' && user.status === 'banned');
        return matchesSearch && matchesStatus;
    });

    const handleAction = async (userId: string, action: 'ban' | 'verify' | 'suspend') => {
        if (!confirm('Bu işlemi onaylıyor musunuz?')) return;
        try {
            await UserService.updateUserStatus(userId, action);
            setUsers(prev => prev.map(u => {
                if (u.id === userId) {
                    return {
                        ...u,
                        status: action === 'ban' ? 'banned' : (action === 'verify' ? 'verified' : 'active'),
                        isVerified: action === 'verify' ? true : u.isVerified,
                    } as User;
                }
                return u;
            }));
        } catch (error) {
            alert('İşlem başarısız oldu.');
        }
    };

    const pendingVerifications = users.filter(u => !u.isVerified && u.photos && u.photos.length > 0).slice(0, 6);

    return (
        <div className="flex min-h-screen bg-background-dark text-white">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">

                    {/* Page Header */}
                    <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">
                        <div className="flex items-center gap-3">
                            <div className="h-12 w-12 rounded-xl bg-primary/20 flex items-center justify-center border border-primary/30">
                                <span className="material-symbols-outlined text-primary text-2xl">admin_panel_settings</span>
                            </div>
                            <div>
                                <h2 className="text-xl font-bold text-white">Kullanıcı Yönetim Merkezi</h2>
                                <p className="text-sm text-zinc-400">
                                    {loading ? 'Yükleniyor...' : `${filteredUsers.length} kullanıcı listeleniyor`}
                                </p>
                            </div>
                        </div>
                        <div className="flex gap-2">
                            <Button variant="outline" size="sm" onClick={fetchUsers} className="border-zinc-800 bg-zinc-900 text-zinc-200">
                                <span className="material-symbols-outlined text-sm mr-1">refresh</span>
                                Yenile
                            </Button>
                        </div>
                    </div>

                    {/* Search & High Contrast Filter Bar */}
                    <div className="mb-6 space-y-4">
                        <div className="flex items-center h-12 bg-zinc-900 rounded-xl border border-zinc-800 px-4 gap-3">
                            <span className="material-symbols-outlined text-primary">search</span>
                            <input
                                type="text"
                                placeholder="Kullanıcı adı veya e-posta ile ara..."
                                className="flex-1 bg-transparent border-none text-white placeholder:text-zinc-500 focus:outline-none text-sm"
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                            />
                        </div>

                        <div className="flex gap-2 overflow-x-auto py-1">
                            {[
                                { id: 'all', label: 'Tüm Kullanıcılar' },
                                { id: 'active', label: 'Aktif Üyeler' },
                                { id: 'verified', label: 'Doğrulanmış (Mavi Tik)' },
                                { id: 'banned', label: 'Engellenmiş (Yasaklı)' },
                            ].map((tab) => (
                                <button
                                    key={tab.id}
                                    onClick={() => setStatusFilter(tab.id)}
                                    className={cn(
                                        'px-4 py-2 rounded-xl text-xs font-bold transition-all border whitespace-nowrap',
                                        statusFilter === tab.id
                                            ? 'bg-primary text-black border-primary font-extrabold shadow-md'
                                            : 'bg-zinc-900 text-zinc-300 border-zinc-800 hover:bg-zinc-800'
                                    )}
                                >
                                    {tab.label}
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Pending Verifications Strip */}
                    {pendingVerifications.length > 0 && (
                        <div className="mb-8">
                            <h3 className="text-sm font-bold text-white mb-3 flex items-center gap-2">
                                <span className="material-symbols-outlined text-amber-400 text-base">verified</span>
                                Mavi Tik Bekleyenler
                            </h3>
                            <div className="flex overflow-x-auto gap-4 pb-2 scrollbar-hide">
                                {pendingVerifications.map((user) => (
                                    <div
                                        key={user.id}
                                        className="flex flex-col justify-between min-w-[150px] bg-zinc-900 p-3 rounded-2xl border border-zinc-800 shadow-lg"
                                    >
                                        <div
                                            className="w-full aspect-[3/4] bg-cover bg-center rounded-xl relative bg-zinc-950 border border-zinc-800"
                                            style={{ backgroundImage: user.photos && user.photos.length > 0 ? `url(${user.photos[0]})` : undefined }}
                                        >
                                            {!user.photos || user.photos.length === 0 && (
                                                <div className="flex items-center justify-center h-full text-zinc-600">
                                                    <span className="material-symbols-outlined text-3xl">person</span>
                                                </div>
                                            )}
                                        </div>
                                        <div className="mt-2">
                                            <p className="font-bold text-xs text-white truncate">{user.name}</p>
                                            <p className="text-[10px] text-zinc-400 truncate">{user.email || 'E-posta yok'}</p>
                                            <button
                                                onClick={() => handleAction(user.id, 'verify')}
                                                className="mt-2 w-full py-1.5 rounded-lg bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-[10px] font-bold hover:bg-emerald-500/30 transition-all flex items-center justify-center gap-1"
                                            >
                                                <span className="material-symbols-outlined text-xs">check_circle</span>
                                                Onayla
                                            </button>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Users List Grid / Table */}
                    {loading ? (
                        <div className="flex justify-center py-20">
                            <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                        </div>
                    ) : filteredUsers.length > 0 ? (
                        <div className="bg-zinc-900 rounded-2xl border border-zinc-800 overflow-hidden shadow-xl">
                            <div className="divide-y divide-zinc-800">
                                {filteredUsers.map((user) => (
                                    <div key={user.id} className="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-zinc-800/50 transition-colors">
                                        <div className="flex items-center gap-3">
                                            <Avatar src={user.photos && user.photos.length > 0 ? user.photos[0] : ''} name={user.name} size="md" />
                                            <div>
                                                <div className="flex items-center gap-2">
                                                    <p className="font-bold text-white text-sm">{user.name}</p>
                                                    {user.isVerified && (
                                                        <span className="material-symbols-outlined text-sky-400 text-sm" title="Mavi Tik">verified</span>
                                                    )}
                                                    {user.isPremium && (
                                                        <TierBadge tier={user.premiumTier || 'gold'} />
                                                    )}
                                                </div>
                                                <p className="text-xs text-zinc-400">{user.email || 'E-posta tanımlanmamış'}</p>
                                                <p className="text-[11px] text-zinc-500 mt-0.5">
                                                    Kayıt: {formatRelativeTime(user.createdAt)} • Son Aktif: {formatRelativeTime(user.lastActive)}
                                                </p>
                                            </div>
                                        </div>

                                        {/* Action Bar */}
                                        <div className="flex items-center gap-2 flex-wrap sm:flex-nowrap">
                                            <button
                                                onClick={() => handleGrantVIP(user.id, 'gold')}
                                                className="px-2.5 py-1.5 rounded-lg bg-amber-500/10 border border-amber-500/30 text-amber-400 hover:bg-amber-500/20 text-xs font-bold transition-all"
                                                title="Gold VIP Üyelik Ver"
                                            >
                                                👑 VIP Ver
                                            </button>
                                            <button
                                                onClick={() => handleAddCredits(user.id, 100)}
                                                className="px-2.5 py-1.5 rounded-lg bg-blue-500/10 border border-blue-500/30 text-blue-400 hover:bg-blue-500/20 text-xs font-bold transition-all"
                                                title="+100 Kredi Yükle"
                                            >
                                                💎 +100 Kredi
                                            </button>
                                            <button
                                                onClick={() => handleEdit(user)}
                                                className="p-1.5 rounded-lg bg-zinc-800 hover:bg-zinc-700 text-zinc-200"
                                                title="Düzenle"
                                            >
                                                <span className="material-symbols-outlined text-base">edit</span>
                                            </button>
                                            <button
                                                onClick={() => handleAction(user.id, user.status === 'banned' ? 'suspend' : 'ban')}
                                                className={cn(
                                                    "p-1.5 rounded-lg border transition-all",
                                                    user.status === 'banned'
                                                        ? "bg-emerald-500/20 border-emerald-500/30 text-emerald-400"
                                                        : "bg-rose-500/20 border-rose-500/30 text-rose-400"
                                                )}
                                                title={user.status === 'banned' ? "Yasağı Kaldır" : "Engelle (Ban)"}
                                            >
                                                <span className="material-symbols-outlined text-base">
                                                    {user.status === 'banned' ? 'lock_open' : 'block'}
                                                </span>
                                            </button>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    ) : (
                        <div className="py-20 text-center bg-zinc-900 rounded-2xl border border-zinc-800 text-zinc-500">
                            Aranan kriterlere uygun kullanıcı bulunamadı.
                        </div>
                    )}

                    {/* Edit User Modal */}
                    {showUserModal && editingUser && (
                        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
                            <div className="bg-zinc-900 border border-zinc-800 rounded-3xl max-w-lg w-full p-6 space-y-4 shadow-2xl">
                                <div className="flex justify-between items-center border-b border-zinc-800 pb-3">
                                    <h3 className="text-base font-bold text-white">Kullanıcı Profilini Düzenle</h3>
                                    <button onClick={() => setShowUserModal(false)} className="text-zinc-400 hover:text-white">
                                        <span className="material-symbols-outlined">close</span>
                                    </button>
                                </div>

                                <div className="space-y-3">
                                    <div>
                                        <label className="text-xs text-zinc-400 block mb-1">Ad Soyad</label>
                                        <input
                                            value={editingUser.name || ''}
                                            onChange={(e) => setEditingUser({ ...editingUser, name: e.target.value })}
                                            className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3 py-2 text-sm text-white focus:border-primary outline-none"
                                        />
                                    </div>
                                    <div>
                                        <label className="text-xs text-zinc-400 block mb-1">Biyografi</label>
                                        <textarea
                                            value={editingUser.bio || ''}
                                            onChange={(e) => setEditingUser({ ...editingUser, bio: e.target.value })}
                                            className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3 py-2 text-sm text-white focus:border-primary outline-none"
                                            rows={3}
                                        />
                                    </div>
                                </div>

                                <div className="flex justify-end gap-2 pt-3">
                                    <Button variant="secondary" onClick={() => setShowUserModal(false)} className="bg-zinc-800 text-zinc-300">İptal</Button>
                                    <Button onClick={handleUpdateUser} className="bg-primary text-black font-bold">Kaydet</Button>
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
