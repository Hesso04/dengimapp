'use client';

import { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { Avatar } from '@/components/ui/Avatar';
import { User } from '@/types';
import { UserService } from '@/services/userService';
import { formatRelativeTime } from '@/lib/utils';

export default function UsersPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('all');
    const [selectedUserIds, setSelectedUserIds] = useState<string[]>([]);
    const [editingUser, setEditingUser] = useState<User | null>(null);
    const [showUserModal, setShowUserModal] = useState(false);
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [creditModalUser, setCreditModalUser] = useState<User | null>(null);
    const [customCreditAmount, setCustomCreditAmount] = useState('50');

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        setLoading(true);
        try {
            const result = await UserService.getUsers(null, 200);
            setUsers(result.users);
        } catch (error) {
            console.error('Kullanıcılar yüklenemedi:', error);
        } finally {
            setLoading(false);
        }
    };

    // Filtreleme
    const filteredUsers = users.filter(user => {
        const matchesSearch = (user.name?.toLowerCase() || '').includes(searchQuery.toLowerCase()) ||
            (user.email?.toLowerCase() || '').includes(searchQuery.toLowerCase()) ||
            (user.phone?.toLowerCase() || '').includes(searchQuery.toLowerCase());

        const matchesStatus = statusFilter === 'all' ||
            (statusFilter === 'active' && user.status === 'active') ||
            (statusFilter === 'verified' && user.isVerified) ||
            (statusFilter === 'banned' && user.status === 'banned') ||
            (statusFilter === 'premium' && user.isPremium);

        return matchesSearch && matchesStatus;
    });

    // Checkbox Seçim Yönetimi
    const handleSelectAll = (checked: boolean) => {
        if (checked) {
            setSelectedUserIds(filteredUsers.map(u => u.id));
        } else {
            setSelectedUserIds([]);
        }
    };

    const handleSelectUser = (id: string, checked: boolean) => {
        if (checked) {
            setSelectedUserIds(prev => [...prev, id]);
        } else {
            setSelectedUserIds(prev => prev.filter(i => i !== id));
        }
    };

    // Tekli Kullanıcı Silme
    const handleDeleteSingleUser = async (user: User) => {
        if (!confirm(`${user.name} kullanıcısının hesabını kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz!`)) return;

        setProcessingId(user.id);
        const success = await UserService.deleteUser(user.id);
        setProcessingId(null);

        if (success) {
            setUsers(prev => prev.filter(u => u.id !== user.id));
            setSelectedUserIds(prev => prev.filter(i => i !== user.id));
        } else {
            alert('Hesap silinirken bir hata oluştu.');
        }
    };

    // Çoklu (Toplu) Kullanıcı Silme
    const handleBulkDelete = async () => {
        if (selectedUserIds.length === 0) return;
        if (!confirm(`Seçilen ${selectedUserIds.length} kullanıcının hesabını kalıcı olarak silmek istediğinize emin misiniz?`)) return;

        setProcessingId('bulk');
        const success = await UserService.deleteUsersBatch(selectedUserIds);
        setProcessingId(null);

        if (success) {
            setUsers(prev => prev.filter(u => !selectedUserIds.includes(u.id)));
            setSelectedUserIds([]);
            alert(`${selectedUserIds.length} kullanıcı hesabı silindi.`);
        } else {
            alert('Toplu silme sırasında bir hata oluştu.');
        }
    };

    // Kullanıcı Banlama / Engeli Kaldırma
    const handleToggleBan = async (user: User) => {
        const action = user.status === 'banned' ? 'activate' : 'ban';
        const msg = action === 'ban' ? `${user.name} engellensin mi?` : `${user.name} engel kaldırılsın mı?`;
        if (!confirm(msg)) return;

        setProcessingId(user.id);
        const success = await UserService.updateUserStatus(user.id, action);
        setProcessingId(null);

        if (success) {
            setUsers(prev => prev.map(u => u.id === user.id ? {
                ...u,
                status: action === 'ban' ? 'banned' : 'active',
            } : u));
        } else {
            alert('İşlem yapılması başarısız oldu.');
        }
    };

    // Kredi Yükleme
    const handleAddCreditsSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!creditModalUser) return;
        const amount = Number(customCreditAmount);
        if (isNaN(amount) || amount <= 0) return;

        setProcessingId(creditModalUser.id);
        const success = await UserService.addCredits(creditModalUser.id, amount);
        setProcessingId(null);

        if (success) {
            setUsers(prev => prev.map(u => u.id === creditModalUser.id ? { ...u, credits: (u.credits || 0) + amount } : u));
            setCreditModalUser(null);
            alert(`${amount} Kredi yüklendi.`);
        } else {
            alert('Kredi yükleme başarısız.');
        }
    };

    // VIP Tanımlama
    const handleGrantVIP = async (userId: string, tier: 'gold' | 'platinum') => {
        const success = await UserService.grantPremium(userId, tier);
        if (success) {
            setUsers(prev => prev.map(u => u.id === userId ? { ...u, isPremium: true, premiumTier: tier } : u));
            alert(`${tier.toUpperCase()} VIP tanımlandı.`);
        }
    };

    return (
        <div className="flex min-h-screen bg-[#090A0C] text-white">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">
                    
                    {/* Header */}
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                        <div>
                            <h1 className="text-2xl font-extrabold text-white tracking-tight">Kullanıcı Yönetimi</h1>
                            <p className="text-zinc-400 text-sm">Üyeleri listeleyin, hesap silme, banlama ve bakiye işlemlerini yönetin.</p>
                        </div>
                        <div className="flex items-center gap-3">
                            <span className="px-3.5 py-1.5 bg-zinc-900 border border-zinc-800 text-zinc-300 text-xs font-bold rounded-xl">
                                Toplam: <strong className="text-white">{users.length}</strong> Kullanıcı
                            </span>
                        </div>
                    </div>

                    {/* Toplu İşlem Çubuğu (Toplu Seçimde Görünür) */}
                    {selectedUserIds.length > 0 && (
                        <div className="mb-6 p-4 bg-rose-500/10 border border-rose-500/30 rounded-2xl flex items-center justify-between animate-fade-in shadow-xl">
                            <div className="flex items-center gap-2">
                                <span className="material-symbols-outlined text-rose-400">checklist</span>
                                <span className="text-sm font-bold text-rose-200">
                                    {selectedUserIds.length} kullanıcı seçildi
                                </span>
                            </div>
                            <div className="flex items-center gap-3">
                                <button
                                    onClick={() => setSelectedUserIds([])}
                                    className="text-xs font-semibold text-zinc-400 hover:text-white px-3 py-1.5 rounded-lg border border-zinc-800"
                                >
                                    Seçimi Temizle
                                </button>
                                <button
                                    onClick={handleBulkDelete}
                                    disabled={processingId === 'bulk'}
                                    className="text-xs font-bold bg-rose-600 hover:bg-rose-700 text-white px-4 py-2 rounded-xl transition-all shadow-md flex items-center gap-1.5"
                                >
                                    <span className="material-symbols-outlined text-sm">delete_forever</span>
                                    <span>Seçilenleri Sil ({selectedUserIds.length})</span>
                                </button>
                            </div>
                        </div>
                    )}

                    {/* Arama & Filtreleme Barı */}
                    <div className="bg-zinc-900/80 border border-zinc-800 rounded-2xl p-4 mb-6 flex flex-col md:flex-row items-center justify-between gap-4">
                        <div className="relative flex-1 w-full">
                            <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-zinc-500 text-xl">search</span>
                            <input
                                type="text"
                                placeholder="İsim, e-posta veya telefon ile arayın..."
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                className="w-full bg-zinc-950 border border-zinc-800 rounded-xl pl-11 pr-4 py-2.5 text-sm text-white placeholder:text-zinc-500 focus:outline-none focus:border-zinc-600"
                            />
                        </div>

                        <div className="flex items-center gap-2 w-full md:w-auto overflow-x-auto">
                            {['all', 'active', 'verified', 'banned', 'premium'].map((f) => (
                                <button
                                    key={f}
                                    onClick={() => setStatusFilter(f)}
                                    className={`px-3.5 py-2 rounded-xl text-xs font-bold capitalize transition-colors whitespace-nowrap ${
                                        statusFilter === f
                                            ? 'bg-white text-black font-extrabold'
                                            : 'bg-zinc-950 text-zinc-400 border border-zinc-800 hover:text-white'
                                    }`}
                                >
                                    {f === 'all' && 'Tümü'}
                                    {f === 'active' && 'Aktif'}
                                    {f === 'verified' && 'Mavi Tıklı'}
                                    {f === 'banned' && 'Engellenen'}
                                    {f === 'premium' && 'VIP Üyeler'}
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Kullanıcılar Tablosu */}
                    {loading ? (
                        <div className="flex justify-center py-20">
                            <div className="h-10 w-10 border-4 border-white border-t-transparent rounded-full animate-spin" />
                        </div>
                    ) : filteredUsers.length === 0 ? (
                        <div className="bg-zinc-900/60 border border-zinc-800 rounded-2xl p-12 text-center max-w-md mx-auto my-8">
                            <span className="material-symbols-outlined text-4xl text-zinc-600 mb-2">person_search</span>
                            <h3 className="text-base font-bold text-white mb-1">Kullanıcı Bulunamadı</h3>
                            <p className="text-xs text-zinc-400">Arama kriterlerinize uyan kullanıcı kaydı yok.</p>
                        </div>
                    ) : (
                        <div className="bg-zinc-900/90 border border-zinc-800 rounded-2xl overflow-hidden shadow-2xl">
                            <div className="overflow-x-auto">
                                <table className="w-full text-left text-xs text-zinc-300">
                                    <thead className="bg-zinc-950 text-zinc-400 uppercase text-[10px] tracking-wider border-b border-zinc-800">
                                        <tr>
                                            <th className="px-4 py-3.5 w-10">
                                                <input
                                                    type="checkbox"
                                                    checked={selectedUserIds.length === filteredUsers.length && filteredUsers.length > 0}
                                                    onChange={(e) => handleSelectAll(e.target.checked)}
                                                    className="rounded border-zinc-700 bg-zinc-900 text-white focus:ring-0 cursor-pointer"
                                                />
                                            </th>
                                            <th className="px-4 py-3.5 font-bold">Kullanıcı</th>
                                            <th className="px-4 py-3.5 font-bold">Kayıt Yöntemi / İletişim</th>
                                            <th className="px-4 py-3.5 font-bold">Üyelik / Kredi</th>
                                            <th className="px-4 py-3.5 font-bold">Durum</th>
                                            <th className="px-4 py-3.5 font-bold">Kayıt Tarihi</th>
                                            <th className="px-4 py-3.5 font-bold text-right">İşlemler</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-zinc-800/60">
                                        {filteredUsers.map((user) => {
                                            const isSelected = selectedUserIds.includes(user.id);

                                            return (
                                                <tr
                                                    key={user.id}
                                                    className={`hover:bg-zinc-800/40 transition-colors ${
                                                        isSelected ? 'bg-zinc-800/50' : ''
                                                    }`}
                                                >
                                                    {/* Checkbox */}
                                                    <td className="px-4 py-3.5">
                                                        <input
                                                            type="checkbox"
                                                            checked={isSelected}
                                                            onChange={(e) => handleSelectUser(user.id, e.target.checked)}
                                                            className="rounded border-zinc-700 bg-zinc-900 text-white focus:ring-0 cursor-pointer"
                                                        />
                                                    </td>

                                                    {/* Profil / İsim */}
                                                    <td className="px-4 py-3.5">
                                                        <div className="flex items-center gap-3">
                                                            <Avatar
                                                                src={user.photos?.[0]}
                                                                name={user.name}
                                                                size="md"
                                                                className="ring-1 ring-zinc-700"
                                                            />
                                                            <div>
                                                                <div className="font-bold text-white text-sm flex items-center gap-1.5">
                                                                    <span>{user.name}</span>
                                                                    {user.isVerified && (
                                                                        <span className="material-symbols-outlined text-blue-400 text-sm" title="Mavi Tıklı">verified</span>
                                                                    )}
                                                                </div>
                                                                <div className="text-[11px] text-zinc-500 font-mono">
                                                                    ID: {user.id.substring(0, 8)}...
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </td>

                                                    {/* Kayıt Yöntemi & İletişim Detayları */}
                                                    <td className="px-4 py-3.5">
                                                        <div className="space-y-1">
                                                            {/* Kayıt türü rozeti */}
                                                            <div>
                                                                {user.authProvider === 'google' && (
                                                                    <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/20">
                                                                        🌐 Google ile Giriş
                                                                    </span>
                                                                )}
                                                                {user.authProvider === 'facebook' && (
                                                                    <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                                                                        📘 Facebook ile Giriş
                                                                    </span>
                                                                )}
                                                                {user.authProvider === 'phone' && (
                                                                    <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                                                                        📱 Telefon İle Giriş
                                                                    </span>
                                                                )}
                                                                {user.authProvider === 'email' && (
                                                                    <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded bg-zinc-800 text-zinc-300 border border-zinc-700">
                                                                        ✉️ E-Posta ile Giriş
                                                                    </span>
                                                                )}
                                                            </div>

                                                            {/* Telefon & Email detay */}
                                                            <div className="text-zinc-300 text-[11px] font-mono">
                                                                {user.phone ? (
                                                                    <span className="text-emerald-400 font-bold">Tel: {user.phone}</span>
                                                                ) : user.email ? (
                                                                    <span>{user.email}</span>
                                                                ) : (
                                                                    <span className="text-zinc-600">-</span>
                                                                )}
                                                            </div>
                                                        </div>
                                                    </td>

                                                    {/* Üyelik / Kredi */}
                                                    <td className="px-4 py-3.5">
                                                        <div className="space-y-1">
                                                            {user.isPremium ? (
                                                                <span className="inline-flex items-center gap-1 text-[10px] font-extrabold px-2 py-0.5 rounded bg-amber-500/20 text-amber-400 border border-amber-500/40">
                                                                    👑 {user.premiumTier?.toUpperCase() || 'VIP'}
                                                                </span>
                                                            ) : (
                                                                <span className="text-[10px] text-zinc-500 font-semibold">Ücretsiz Üye</span>
                                                            )}
                                                            <div className="text-zinc-300 font-extrabold text-[11px]">
                                                                ⚡ {user.credits || 0} <span className="text-zinc-500 font-normal text-[10px]">Kredi</span>
                                                            </div>
                                                        </div>
                                                    </td>

                                                    {/* Durum */}
                                                    <td className="px-4 py-3.5">
                                                        {user.status === 'banned' ? (
                                                            <span className="px-2 py-0.5 bg-rose-500/20 text-rose-400 border border-rose-500/30 rounded text-[10px] font-extrabold">
                                                                YASAKLI (BAN)
                                                            </span>
                                                        ) : (
                                                            <span className="px-2 py-0.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded text-[10px] font-bold">
                                                                Aktif
                                                            </span>
                                                        )}
                                                    </td>

                                                    {/* Kayıt Tarihi */}
                                                    <td className="px-4 py-3.5 text-zinc-400 text-[11px]">
                                                        {formatRelativeTime(new Date(user.createdAt))}
                                                    </td>

                                                    {/* Aksiyon Butonları */}
                                                    <td className="px-4 py-3.5 text-right">
                                                        <div className="flex items-center justify-end gap-1.5">
                                                            {/* Kredi Ekle */}
                                                            <button
                                                                onClick={() => setCreditModalUser(user)}
                                                                className="px-2 py-1 bg-zinc-800 hover:bg-zinc-700 text-amber-400 rounded-lg text-[11px] font-bold transition-colors"
                                                                title="Kredi Yükle"
                                                            >
                                                                +Kredi
                                                            </button>

                                                            {/* VIP Ekle */}
                                                            <button
                                                                onClick={() => handleGrantVIP(user.id, 'platinum')}
                                                                className="px-2 py-1 bg-zinc-800 hover:bg-zinc-700 text-yellow-300 rounded-lg text-[11px] font-bold transition-colors"
                                                                title="Platinum VIP Ver"
                                                            >
                                                                VIP
                                                            </button>

                                                            {/* Ban/Unban */}
                                                            <button
                                                                onClick={() => handleToggleBan(user)}
                                                                disabled={processingId === user.id}
                                                                className={`px-2 py-1 rounded-lg text-[11px] font-bold transition-colors ${
                                                                    user.status === 'banned'
                                                                        ? 'bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-600/30'
                                                                        : 'bg-zinc-800 hover:bg-zinc-700 text-zinc-300'
                                                                }`}
                                                            >
                                                                {user.status === 'banned' ? 'Engeli Kaldır' : 'Banla'}
                                                            </button>

                                                            {/* Doğrudan Hesabı Sil */}
                                                            <button
                                                                onClick={() => handleDeleteSingleUser(user)}
                                                                disabled={processingId === user.id}
                                                                className="p-1 text-zinc-500 hover:text-rose-400 transition-colors rounded-lg hover:bg-rose-500/10"
                                                                title="Hesabı Kalıcı Sil"
                                                            >
                                                                <span className="material-symbols-outlined text-base">delete</span>
                                                            </button>
                                                        </div>
                                                    </td>
                                                </tr>
                                            );
                                        })}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    )}
                </main>
            </div>

            {/* Kredi Yükleme Modalı */}
            {creditModalUser && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                    <div className="bg-zinc-900 border border-zinc-800 w-full max-w-sm rounded-2xl p-6 shadow-2xl">
                        <h3 className="text-base font-bold text-white mb-1">Kredi Yükle</h3>
                        <p className="text-xs text-zinc-400 mb-4">
                            <strong className="text-white">{creditModalUser.name}</strong> kullanıcısının hesabına tanımlanacak kredi miktarı:
                        </p>

                        <form onSubmit={handleAddCreditsSubmit} className="space-y-4">
                            <input
                                type="number"
                                min="1"
                                value={customCreditAmount}
                                onChange={(e) => setCustomCreditAmount(e.target.value)}
                                className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-3 text-white text-lg font-bold focus:outline-none focus:border-amber-400 text-amber-400"
                            />

                            <div className="flex gap-2">
                                {[20, 50, 100, 500].map((amt) => (
                                    <button
                                        type="button"
                                        key={amt}
                                        onClick={() => setCustomCreditAmount(amt.toString())}
                                        className="flex-1 py-1.5 bg-zinc-950 border border-zinc-800 hover:border-zinc-600 rounded-lg text-xs font-bold text-zinc-300"
                                    >
                                        +{amt}
                                    </button>
                                ))}
                            </div>

                            <div className="pt-2 flex gap-3">
                                <button
                                    type="button"
                                    onClick={() => setCreditModalUser(null)}
                                    className="flex-1 bg-zinc-800 text-zinc-300 font-bold py-2.5 rounded-xl text-xs"
                                >
                                    İptal
                                </button>
                                <button
                                    type="submit"
                                    disabled={processingId === creditModalUser.id}
                                    className="flex-1 bg-amber-400 hover:bg-amber-500 text-black font-extrabold py-2.5 rounded-xl text-xs transition-colors"
                                >
                                    Kredi Yükle
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
