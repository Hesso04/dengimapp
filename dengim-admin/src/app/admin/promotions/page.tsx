'use client';

import { useEffect, useState } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { PromoService } from '@/services/promoService';
import { PromoCode } from '@/types';
import { formatRelativeTime } from '@/lib/utils';

export default function PromotionsPage() {
    const [promoCodes, setPromoCodes] = useState<PromoCode[]>([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    // Form state
    const [code, setCode] = useState('');
    const [creditAmount, setCreditAmount] = useState('20');
    const [maxUses, setMaxUses] = useState('100');
    const [expiresAt, setExpiresAt] = useState('');

    const loadPromoCodes = async () => {
        setLoading(true);
        const data = await PromoService.getPromoCodes();
        setPromoCodes(data);
        setLoading(false);
    };

    useEffect(() => {
        loadPromoCodes();
    }, []);

    const handleCreatePromoCode = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!code.trim()) return;

        setSubmitting(true);
        const success = await PromoService.createPromoCode({
            code: code.trim().toUpperCase(),
            creditAmount: Number(creditAmount),
            maxUses: Number(maxUses),
            expiresAt: expiresAt || undefined,
        });

        setSubmitting(false);

        if (success) {
            setIsModalOpen(false);
            setCode('');
            setCreditAmount('20');
            setMaxUses('100');
            setExpiresAt('');
            loadPromoCodes();
        } else {
            alert('Promo kodu oluşturulurken bir hata oluştu.');
        }
    };

    const handleToggleStatus = async (promo: PromoCode) => {
        const success = await PromoService.toggleStatus(promo.id, promo.isActive);
        if (success) {
            setPromoCodes(prev =>
                prev.map(p => (p.id === promo.id ? { ...p, isActive: !p.isActive } : p))
            );
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('Bu promosyon kodunu silmek istediğinize emin misiniz?')) return;
        const success = await PromoService.deletePromoCode(id);
        if (success) {
            setPromoCodes(prev => prev.filter(p => p.id !== id));
        }
    };

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">
                    
                    {/* Header bar */}
                    <div className="mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
                        <div>
                            <h1 className="text-2xl font-bold text-white mb-1">Promosyon Kodları & Kampanyalar</h1>
                            <p className="text-zinc-400 text-sm">Uygulama içi özel hediye kredi kodlarını tanımlayın ve yönetin.</p>
                        </div>
                        <button
                            onClick={() => setIsModalOpen(true)}
                            className="inline-flex items-center gap-2 bg-primary hover:bg-primary-dark text-black font-bold px-4 py-2.5 rounded-xl transition-all shadow-lg shadow-primary/20"
                        >
                            <span className="material-symbols-outlined text-xl">add_circle</span>
                            <span>Yeni Promosyon Kodu</span>
                        </button>
                    </div>

                    {/* Promosyon Kodları Listesi */}
                    {loading ? (
                        <div className="flex justify-center py-20">
                            <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                        </div>
                    ) : promoCodes.length === 0 ? (
                        <div className="bg-zinc-900/60 border border-zinc-800 rounded-2xl p-12 text-center max-w-lg mx-auto my-12">
                            <span className="material-symbols-outlined text-5xl text-zinc-600 mb-3">card_giftcard</span>
                            <h3 className="text-lg font-bold text-white mb-1">Henüz Promosyon Kodu Yok</h3>
                            <p className="text-zinc-400 text-sm mb-6">Kullanıcıların kampanya veya hediyelerle kredi kazanması için yeni bir kod oluşturun.</p>
                            <button
                                onClick={() => setIsModalOpen(true)}
                                className="bg-primary text-black font-bold px-5 py-2.5 rounded-xl inline-flex items-center gap-2"
                            >
                                <span className="material-symbols-outlined">add</span>
                                <span>İlk Kodu Oluştur</span>
                            </button>
                        </div>
                    ) : (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                            {promoCodes.map((promo) => {
                                const isExpired = promo.expiresAt ? new Date(promo.expiresAt) < new Date() : false;
                                const isLimitReached = promo.usedCount >= promo.maxUses;

                                return (
                                    <div
                                        key={promo.id}
                                        className={`relative bg-zinc-900/80 border rounded-2xl p-5 flex flex-col justify-between transition-all ${
                                            !promo.isActive
                                                ? 'border-zinc-800 opacity-60'
                                                : isExpired || isLimitReached
                                                ? 'border-amber-500/30'
                                                : 'border-zinc-700/80 hover:border-primary/50'
                                        }`}
                                    >
                                        <div>
                                            <div className="flex items-center justify-between mb-3">
                                                <span className="px-3 py-1 bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs font-mono font-bold rounded-lg tracking-wider">
                                                    {promo.code}
                                                </span>
                                                <div className="flex items-center gap-2">
                                                    <button
                                                        onClick={() => handleToggleStatus(promo)}
                                                        className={`text-xs px-2.5 py-1 rounded-md font-semibold transition-colors ${
                                                            promo.isActive
                                                                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                                                                : 'bg-zinc-800 text-zinc-400'
                                                        }`}
                                                    >
                                                        {promo.isActive ? 'Aktif' : 'Pasif'}
                                                    </button>
                                                    <button
                                                        onClick={() => handleDelete(promo.id)}
                                                        className="text-zinc-500 hover:text-rose-400 transition-colors p-1"
                                                        title="Sil"
                                                    >
                                                        <span className="material-symbols-outlined text-lg">delete</span>
                                                    </button>
                                                </div>
                                            </div>

                                            <div className="mb-4">
                                                <div className="text-2xl font-extrabold text-white flex items-center gap-1.5">
                                                    <span className="text-amber-400">+{promo.creditAmount}</span>
                                                    <span className="text-xs text-zinc-400 font-medium">Kredi</span>
                                                </div>
                                            </div>

                                            <div className="space-y-2 text-xs text-zinc-400">
                                                <div className="flex justify-between items-center bg-zinc-950/50 p-2 rounded-lg">
                                                    <span>Kullanım İlerlemesi:</span>
                                                    <span className="font-bold text-zinc-200">
                                                        {promo.usedCount} / {promo.maxUses}
                                                    </span>
                                                </div>
                                                
                                                {/* Progress bar */}
                                                <div className="w-full bg-zinc-800 h-1.5 rounded-full overflow-hidden">
                                                    <div
                                                        className="bg-primary h-full transition-all"
                                                        style={{
                                                            width: `${Math.min(
                                                                100,
                                                                (promo.usedCount / promo.maxUses) * 100
                                                            )}%`,
                                                        }}
                                                    />
                                                </div>

                                                {promo.expiresAt && (
                                                    <div className="flex items-center justify-between text-zinc-400 pt-1">
                                                        <span>Son Kullanma:</span>
                                                        <span className={isExpired ? 'text-rose-400 font-bold' : 'text-zinc-300'}>
                                                            {new Date(promo.expiresAt).toLocaleDateString('tr-TR')}
                                                        </span>
                                                    </div>
                                                )}
                                            </div>
                                        </div>

                                        <div className="mt-4 pt-3 border-t border-zinc-800/80 flex items-center justify-between text-[11px] text-zinc-500">
                                            <span>Oluşturulma: {formatRelativeTime(new Date(promo.createdAt))}</span>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    )}

                </main>
            </div>

            {/* Yeni Promosyon Kodu Modalı */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
                    <div className="bg-zinc-900 border border-zinc-800 w-full max-w-md rounded-2xl p-6 shadow-2xl">
                        <div className="flex items-center justify-between mb-4 pb-3 border-b border-zinc-800">
                            <h3 className="text-lg font-bold text-white flex items-center gap-2">
                                <span className="material-symbols-outlined text-primary">confirmation_number</span>
                                Yeni Promosyon Kodu
                            </h3>
                            <button
                                onClick={() => setIsModalOpen(false)}
                                className="text-zinc-400 hover:text-white"
                            >
                                <span className="material-symbols-outlined">close</span>
                            </button>
                        </div>

                        <form onSubmit={handleCreatePromoCode} className="space-y-4">
                            <div>
                                <label className="block text-xs font-semibold text-zinc-300 mb-1">
                                    Promosyon Kodu *
                                </label>
                                <input
                                    type="text"
                                    required
                                    placeholder="Örn: DENGIM2026 veya KAMPANYA50"
                                    value={code}
                                    onChange={(e) => setCode(e.target.value.toUpperCase())}
                                    className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-white placeholder:text-zinc-600 focus:outline-none focus:border-primary font-mono uppercase tracking-wider"
                                />
                            </div>

                            <div className="grid grid-cols-2 gap-3">
                                <div>
                                    <label className="block text-xs font-semibold text-zinc-300 mb-1">
                                        Tanımlanacak Kredi *
                                    </label>
                                    <input
                                        type="number"
                                        min="1"
                                        required
                                        value={creditAmount}
                                        onChange={(e) => setCreditAmount(e.target.value)}
                                        className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-white focus:outline-none focus:border-primary font-bold text-amber-400"
                                    />
                                </div>
                                <div>
                                    <label className="block text-xs font-semibold text-zinc-300 mb-1">
                                        Maks. Kişi Sayısı *
                                    </label>
                                    <input
                                        type="number"
                                        min="1"
                                        required
                                        value={maxUses}
                                        onChange={(e) => setMaxUses(e.target.value)}
                                        className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-white focus:outline-none focus:border-primary"
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="block text-xs font-semibold text-zinc-300 mb-1">
                                    Son Kullanma Tarihi (Opsiyonel)
                                </label>
                                <input
                                    type="date"
                                    value={expiresAt}
                                    onChange={(e) => setExpiresAt(e.target.value)}
                                    className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-white focus:outline-none focus:border-primary"
                                />
                            </div>

                            <div className="pt-3 flex gap-3">
                                <button
                                    type="button"
                                    onClick={() => setIsModalOpen(false)}
                                    className="flex-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 font-bold py-2.5 rounded-xl transition-colors text-sm"
                                >
                                    İptal
                                </button>
                                <button
                                    type="submit"
                                    disabled={submitting}
                                    className="flex-1 bg-primary hover:bg-primary-dark text-black font-bold py-2.5 rounded-xl transition-colors text-sm disabled:opacity-50"
                                >
                                    {submitting ? 'Oluşturuluyor...' : 'Kodu Oluştur'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
