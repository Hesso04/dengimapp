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
            const result = await UserService.getUsers(null, 50); // İlk 50 kullanıcıyı çek
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
            alert('Kullanıcı başarıyla güncellendi.');
        } catch (error) {
            alert('Güncelleme hatası!');
        }
    };

    // Filtreleme (Client-side şimdilik)
    const filteredUsers = users.filter(user => {
        const matchesSearch = (user.name?.toLowerCase() || '').includes(searchQuery.toLowerCase()) ||
            (user.email?.toLowerCase() || '').includes(searchQuery.toLowerCase());
        const matchesStatus = statusFilter === 'all' || user.status === statusFilter;
        return matchesSearch && matchesStatus;
    });

    const toggleUserSelection = (userId: string) => {
        setSelectedUsers(prev =>
            prev.includes(userId)
                ? prev.filter(id => id !== userId)
                : [...prev, userId]
        );
    };

    const handleAction = async (userId: string, action: 'ban' | 'verify' | 'suspend') => {
        if (!confirm('Bu işlemi yapmak istediğinize emin misiniz?')) return;
        try {
            await UserService.updateUserStatus(userId, action);
            // Listeyi güncelle
            setUsers(prev => prev.map(u => {
                if (u.id === userId) {
                    return {
                        ...u,
                        status: action === 'ban' ? 'banned' : (action === 'verify' ? 'verified' : 'banned'),
                        isVerified: action === 'verify',
                    } as User;
                }
                return u;
            }));
        } catch (error) {
            alert('İşlem başarısız oldu.');
        }
    };

    // Pending verifications (gerçek veriden türetiliyor)
    const pendingVerifications = users.filter(u => !u.isVerified && u.photos && u.photos.length > 0).slice(0, 5);

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">
                    {/* Page Header */}
                    <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">
                        <div className="flex items-center gap-3">
                            <div className="h-12 w-12 rounded-xl bg-primary/20 flex items-center justify-center">
                                <span className="material-symbols-outlined text-primary text-2xl">admin_panel_settings</span>
                            </div>
                            <div>
                                <h2 className="text-xl font-bold text-white">Kullanıcı Yönetimi</h2>
                                <p className="text-sm text-slate-400">
                                    {loading ? 'Yükleniyor...' : `${users.length} kullanıcı gösteriliyor`}
                                </p>
                            </div>
                        </div>
                        <div className="flex gap-2">
                            <Button variant="outline" size="sm" onClick={fetchUsers}>
                                <span className="material-symbols-outlined text-sm">refresh</span>
                                Yenile
                            </Button>
                        </div>
                    </div>

                    {/* Search and Filters */}
                    <div className="mb-6">
                        <div className="flex flex-col md:flex-row gap-4 mb-4">
                            <div className="flex-1">
                                <div className="flex items-center h-14 bg-white/5 rounded-xl border border-white/10 px-4 gap-3">
                                    <span className="material-symbols-outlined text-primary">search</span>
                                    <input
                                        type="text"
                                        placeholder="Kullanıcı adı veya e-posta ile ara..."
                                        className="flex-1 bg-transparent border-none text-white placeholder:text-white/30 focus:outline-none"
                                        value={searchQuery}
                                        onChange={(e) => setSearchQuery(e.target.value)}
                                    />
                                </div>
                            </div>
                        </div>

                        <div className="flex gap-2 overflow-x-auto scrollbar-hide py-2">
                            {['all', 'active', 'verified', 'banned'].map((status) => (
                                <button
                                    key={status}
                                    onClick={() => setStatusFilter(status)}
                                    className={cn(
                                        'flex h-10 shrink-0 items-center justify-center rounded-full px-6 font-semibold text-sm transition-all',
                                        statusFilter === status
                                            ? 'bg-primary text-black'
                                            : 'bg-white/5 border border-white/10 text-white hover:bg-white/10'
                                    )}
                                >
                                    {status === 'all' ? 'Tümü' : status === 'active' ? 'Aktif' : status === 'verified' ? 'Doğrulanmış' : 'Yasaklı'}
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Content */}
                    {loading ? (
                        <div className="flex justify-center py-20">
                            <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                        </div>
                    ) : (
                        <>
                            {/* Pending Verifications Strip */}
                            {pendingVerifications.length > 0 && (
                                <div className="mb-8">
                                    <h3 className="text-lg font-bold text-white mb-4">Hızlı Onay (Son Kayıtlar)</h3>
                                    <div className="flex overflow-x-auto gap-4 scrollbar-hide pb-2">
                                        {pendingVerifications.map((user) => (
                                            <div
                                                key={user.id}
                                                className="flex flex-col gap-3 min-w-[160px] bg-surface-dark p-3 rounded-xl border border-white/10 shadow-lg"
                                            >
                                                <div
                                                    className="w-full aspect-[3/4] bg-cover bg-center rounded-lg relative bg-white/5"
                                                    style={{ backgroundImage: user.photos[0] ? `url(${user.photos[0]})` : undefined }}
                                                >
                                                    {!user.photos[0] && (
                                                        <div className="absolute inset-0 flex items-center justify-center text-white/20">
                                                            <span className="material-symbols-outlined text-4xl">person</span>
                                                        </div>
                                                    )}
                                                </div>
                                                <div className="px-1">
                                                    <p className="font-bold text-sm text-white truncate">{user.name}</p>
                                                    <p className="text-xs text-white/50">{formatRelativeTime(user.createdAt)}</p>
                                                </div>
                                                <Button size="sm" className="w-full" onClick={() => handleAction(user.id, 'verify')}>
                                                    Doğrula
                                                </Button>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}

                            {/* User List */}
                            <h3 className="text-lg font-bold text-white mb-4">Kullanıcı Listesi</h3>
                            <div className="space-y-3">
                                {filteredUsers.map((user) => (
                                    <UserCard
                                        key={user.id}
                                        user={user}
                                        selected={selectedUsers.includes(user.id)}
                                        onSelect={() => toggleUserSelection(user.id)}
                                        onAction={handleAction}
                                        onEdit={() => handleEdit(user)}
                                        onView={() => handleEdit(user)}
                                    />
                                ))}

                                {filteredUsers.length === 0 && (
                                    <div className="text-center py-12">
                                        <span className="material-symbols-outlined text-6xl text-white/20 mb-4">search_off</span>
                                        <p className="text-white/50">Kullanıcı bulunamadı</p>
                                    </div>
                                )}
                            </div>
                        </>
                    )}
                </main>
                <BottomNav />

                {/* Edit Modal */}
                {showUserModal && editingUser && (
                    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                        <div className="bg-surface-dark w-full max-w-lg rounded-3xl border border-white/10 overflow-hidden shadow-2xl flex flex-col">
                            <div className="p-6 border-b border-white/5 flex items-center justify-between">
                                <h3 className="text-xl font-bold text-white">Kullanıcı Düzenle</h3>
                                <button onClick={() => setShowUserModal(false)} className="text-white/50 hover:text-white">
                                    <span className="material-symbols-outlined">close</span>
                                </button>
                            </div>

                            <div className="p-6 space-y-6 max-h-[70vh] overflow-y-auto custom-scrollbar">
                                {/* Photos Gallery */}
                                {editingUser.photos && editingUser.photos.length > 0 && (
                                    <div>
                                        <label className="text-xs font-bold text-white/40 mb-3 block uppercase tracking-wider">Fotoğraflar</label>
                                        <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
                                            {editingUser.photos.map((photo, i) => (
                                                <div key={i} className="relative group shrink-0">
                                                    <img
                                                        src={photo}
                                                        className="h-40 w-32 object-cover rounded-2xl border border-white/10 shadow-lg"
                                                        alt={`User photo ${i + 1}`}
                                                    />
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                )}

                                {/* Stats Grid */}
                                <div className="grid grid-cols-5 gap-3">
                                    <div className="bg-white/5 rounded-2xl p-3 border border-white/5 text-center flex flex-col justify-center">
                                        <p className="text-[9px] font-bold text-white/30 uppercase tracking-wider mb-1 line-clamp-1">Eşleşme</p>
                                        <p className="text-lg font-bold text-white leading-none">{editingUser.matchCount || 0}</p>
                                    </div>
                                    <div className="bg-white/5 rounded-2xl p-3 border border-white/5 text-center flex flex-col justify-center">
                                        <p className="text-[9px] font-bold text-white/30 uppercase tracking-wider mb-1 line-clamp-1">Mesaj</p>
                                        <p className="text-lg font-bold text-white leading-none">{editingUser.messageCount || 0}</p>
                                    </div>
                                    <div className="bg-white/5 rounded-2xl p-3 border border-primary/20 bg-primary/5 text-center flex flex-col justify-center">
                                        <p className="text-[9px] font-bold text-primary/60 uppercase tracking-wider mb-1 line-clamp-1">Takipçi</p>
                                        <p className="text-lg font-bold text-white leading-none">{editingUser.followersCount || 0}</p>
                                    </div>
                                    <div className="bg-white/5 rounded-2xl p-3 border border-white/5 text-center flex flex-col justify-center">
                                        <p className="text-[9px] font-bold text-white/30 uppercase tracking-wider mb-1 line-clamp-1">Takip</p>
                                        <p className="text-lg font-bold text-white leading-none">{editingUser.followingCount || 0}</p>
                                    </div>
                                    <div className="bg-white/5 rounded-2xl p-3 border border-rose-500/20 bg-rose-500/5 text-center flex flex-col justify-center">
                                        <p className="text-[9px] font-bold text-rose-500/60 uppercase tracking-wider mb-1 line-clamp-1">Rapor</p>
                                        <p className="text-lg font-bold text-rose-500 leading-none">{editingUser.reportCount || 0}</p>
                                    </div>
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="text-xs font-bold text-white/40 mb-2 block uppercase tracking-wider">Ad Soyad</label>
                                        <input
                                            type="text"
                                            value={editingUser.name}
                                            onChange={(e) => setEditingUser({ ...editingUser, name: e.target.value })}
                                            className="w-full h-12 bg-white/5 border border-white/10 rounded-xl px-4 text-white outline-none focus:border-primary transition-colors"
                                        />
                                    </div>
                                    <div>
                                        <label className="text-xs font-bold text-white/40 mb-2 block uppercase tracking-wider">İlişki Hedefi</label>
                                        <select
                                            value={editingUser.relationshipGoal || ''}
                                            onChange={(e) => setEditingUser({ ...editingUser, relationshipGoal: e.target.value })}
                                            className="w-full h-12 bg-white/5 border border-white/10 rounded-xl px-4 text-white outline-none focus:border-primary appearance-none [&>option]:bg-surface-dark transition-colors"
                                        >
                                            <option value="">Belirtilmemiş</option>
                                            <option value="serious">Ciddi Bir İlişki</option>
                                            <option value="casual">Kısa Süreli Eğlence</option>
                                            <option value="chat">Sadece Sohbet</option>
                                            <option value="unsure">Henüz Kararsızım</option>
                                        </select>
                                    </div>
                                </div>

                                <div>
                                    <label className="text-xs font-bold text-white/40 mb-2 block uppercase tracking-wider">Biyografi</label>
                                    <textarea
                                        value={editingUser.bio}
                                        onChange={(e) => setEditingUser({ ...editingUser, bio: e.target.value })}
                                        rows={4}
                                        className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-primary resize-none transition-colors"
                                    />
                                </div>

                                <div>
                                    <label className="text-xs font-bold text-white/40 mb-2 block uppercase tracking-wider">Hesap Durumu</label>
                                    <select
                                        value={editingUser.status}
                                        onChange={(e) => setEditingUser({ ...editingUser, status: e.target.value as any })}
                                        className="w-full h-12 bg-white/5 border border-white/10 rounded-xl px-4 text-white outline-none focus:border-primary appearance-none [&>option]:bg-surface-dark transition-colors"
                                    >
                                        <option value="active">Aktif</option>
                                        <option value="verified">Doğrulanmış</option>
                                        <option value="pending">Beklemede</option>
                                        <option value="banned">Yasaklı</option>
                                    </select>
                                </div>

                                <div className="flex gap-3 pt-4 border-t border-white/5 mt-auto">
                                    <Button variant="outline" className="flex-1 h-12 rounded-xl" onClick={() => setShowUserModal(false)}>İptal</Button>
                                    <Button className="flex-1 h-12 rounded-xl" onClick={handleUpdateUser}>Kaydet</Button>
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}

function UserCard({ user, selected, onSelect, onAction, onEdit, onView }: {
    user: User;
    selected: boolean;
    onSelect: () => void;
    onAction: (id: string, action: 'ban' | 'verify' | 'suspend') => void;
    onEdit: () => void;
    onView: () => void;
}) {
    return (
        <div className={cn(
            'bg-surface-dark rounded-2xl p-4 border transition-all duration-300',
            selected ? 'border-primary bg-primary/5 shadow-lg shadow-primary/10' : 'border-white/5 hover:border-white/20'
        )}>
            <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-4">
                    <div className="relative" onClick={onSelect}>
                        <div className={cn(
                            "absolute -top-1 -left-1 w-5 h-5 rounded-md border-2 border-surface-dark flex items-center justify-center transition-colors z-10",
                            selected ? "bg-primary border-primary" : "bg-white/10"
                        )}>
                            {selected && <span className="material-symbols-outlined text-[14px] text-black font-bold">check</span>}
                        </div>
                        <Avatar
                            src={user.photos[0]}
                            name={user.name}
                            size="lg"
                            verified={user.isVerified}
                            premium={user.isPremium}
                        />
                    </div>
                    <div className="cursor-pointer group" onClick={onView}>
                        <h4 className="font-bold text-white flex items-center gap-2 group-hover:text-primary transition-colors">
                            {user.name}
                            {user.isVerified && (
                                <span className="material-symbols-outlined text-blue-400 text-[18px]">verified</span>
                            )}
                        </h4>
                        <div className="flex flex-col gap-0.5 mt-0.5">
                            <p className="text-white/40 text-[11px] font-medium">
                                ID: {user.id.substring(0, 8)}... | {user.location?.city || 'Bilinmiyor'}
                            </p>
                            <p className="text-white/30 text-[10px] flex items-center gap-1">
                                <span className="material-symbols-outlined text-[12px]">calendar_today</span>
                                Kayıt: {formatRelativeTime(user.createdAt)}
                            </p>
                        </div>
                    </div>
                </div>
                <div className="flex flex-col items-end gap-2">
                    {user.isPremium && <TierBadge tier={user.premiumTier || 'basic'} />}
                    <StatusBadge status={user.status} />
                </div>
            </div>

            {/* Actions */}
            <div className="grid grid-cols-4 gap-2 border-t border-white/5 pt-4">
                <button
                    onClick={onView}
                    className="flex flex-col items-center gap-1.5 py-2 text-white/40 hover:text-white transition-all hover:bg-white/5 rounded-xl"
                >
                    <span className="material-symbols-outlined text-xl">visibility</span>
                    <span className="text-[10px] font-bold uppercase tracking-tight">Gör</span>
                </button>
                <button
                    onClick={onEdit}
                    className="flex flex-col items-center gap-1.5 py-2 text-white/40 hover:text-white transition-all hover:bg-white/5 rounded-xl"
                >
                    <span className="material-symbols-outlined text-xl">edit</span>
                    <span className="text-[10px] font-bold uppercase tracking-tight">Düzenle</span>
                </button>
                <button
                    onClick={() => onAction(user.id, 'verify')}
                    className="flex flex-col items-center gap-1.5 py-2 text-primary/60 hover:text-primary transition-all hover:bg-primary/5 rounded-xl"
                >
                    <span className="material-symbols-outlined text-xl">verified_user</span>
                    <span className="text-[10px] font-bold uppercase tracking-tight">Doğrula</span>
                </button>
                <button
                    onClick={() => onAction(user.id, 'ban')}
                    className="flex flex-col items-center gap-1.5 py-2 text-rose-500/60 hover:text-rose-500 transition-all hover:bg-rose-500/5 rounded-xl"
                >
                    <span className="material-symbols-outlined text-xl">block</span>
                    <span className="text-[10px] font-bold uppercase tracking-tight">Yasakla</span>
                </button>
            </div>
        </div>
    );
}
