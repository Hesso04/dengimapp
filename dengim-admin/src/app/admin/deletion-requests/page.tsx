'use client';

import { useEffect, useState } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { DeletionService } from '@/services/deletionService';
import { DeletionRequest } from '@/types';
import { formatRelativeTime } from '@/lib/utils';

export default function DeletionRequestsPage() {
    const [requests, setRequests] = useState<DeletionRequest[]>([]);
    const [loading, setLoading] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);

    const loadRequests = async () => {
        setLoading(true);
        const data = await DeletionService.getRequests();
        setRequests(data);
        setLoading(false);
    };

    useEffect(() => {
        loadRequests();
    }, []);

    const handleApprove = async (req: DeletionRequest) => {
        if (!confirm(`${req.userName} kullanıcısının hesabını silmeyi onaylıyor musunuz?`)) return;

        setProcessingId(req.id);
        const success = await DeletionService.approveDeletion(req.id, req.userId);
        setProcessingId(null);

        if (success) {
            setRequests(prev =>
                prev.map(r => (r.id === req.id ? { ...r, status: 'approved' } : r))
            );
        } else {
            alert('İşlem sırasında bir hata oluştu.');
        }
    };

    const handleReject = async (req: DeletionRequest) => {
        if (!confirm('Silme talebini reddetmek istediğinize emin misiniz?')) return;

        setProcessingId(req.id);
        const success = await DeletionService.rejectDeletion(req.id);
        setProcessingId(null);

        if (success) {
            setRequests(prev =>
                prev.map(r => (r.id === req.id ? { ...r, status: 'rejected' } : r))
            );
        }
    };

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">
                    
                    <div className="mb-6">
                        <h1 className="text-2xl font-bold text-white mb-1">Hesap Silme Talepleri</h1>
                        <p className="text-zinc-400 text-sm">Uygulamadan gelen hesap silme isteklerini inceleyin ve onaylayın.</p>
                    </div>

                    {loading ? (
                        <div className="flex justify-center py-20">
                            <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                        </div>
                    ) : requests.length === 0 ? (
                        <div className="bg-zinc-900/60 border border-zinc-800 rounded-2xl p-12 text-center max-w-lg mx-auto my-12">
                            <span className="material-symbols-outlined text-5xl text-zinc-600 mb-3">person_remove</span>
                            <h3 className="text-lg font-bold text-white mb-1">Silme Talebi Bulunmuyor</h3>
                            <p className="text-zinc-400 text-sm">Kullanıcılar tarafından iletilen herhangi bir hesap silme talebi yok.</p>
                        </div>
                    ) : (
                        <div className="bg-zinc-900/80 border border-zinc-800 rounded-2xl overflow-hidden shadow-xl">
                            <div className="overflow-x-auto">
                                <table className="w-full text-left text-sm text-zinc-300">
                                    <thead className="bg-zinc-950/80 text-zinc-400 uppercase text-[11px] tracking-wider border-b border-zinc-800">
                                        <tr>
                                            <th className="px-6 py-4 font-bold">Kullanıcı</th>
                                            <th className="px-6 py-4 font-bold">E-Posta / ID</th>
                                            <th className="px-6 py-4 font-bold">Talep Tarihi</th>
                                            <th className="px-6 py-4 font-bold">Sebep</th>
                                            <th className="px-6 py-4 font-bold">Durum</th>
                                            <th className="px-6 py-4 font-bold text-right">İşlem</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-zinc-800/60">
                                        {requests.map((req) => (
                                            <tr key={req.id} className="hover:bg-zinc-800/30 transition-colors">
                                                <td className="px-6 py-4 font-semibold text-white">
                                                    {req.userName}
                                                </td>
                                                <td className="px-6 py-4 text-zinc-400 font-mono text-xs">
                                                    {req.userEmail}
                                                    <div className="text-[10px] text-zinc-600">{req.userId}</div>
                                                </td>
                                                <td className="px-6 py-4 text-zinc-400 text-xs">
                                                    {formatRelativeTime(new Date(req.requestedAt))}
                                                </td>
                                                <td className="px-6 py-4 text-zinc-300">
                                                    {req.reason || 'Sebep belirtilmedi'}
                                                </td>
                                                <td className="px-6 py-4">
                                                    {req.status === 'pending' && (
                                                        <span className="px-2.5 py-1 bg-amber-500/10 border border-amber-500/30 text-amber-400 rounded-md text-xs font-bold">
                                                            Beklemede
                                                        </span>
                                                    )}
                                                    {req.status === 'approved' && (
                                                        <span className="px-2.5 py-1 bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 rounded-md text-xs font-bold">
                                                            Onaylandı
                                                        </span>
                                                    )}
                                                    {req.status === 'rejected' && (
                                                        <span className="px-2.5 py-1 bg-zinc-800 border border-zinc-700 text-zinc-400 rounded-md text-xs font-bold">
                                                            Reddedildi
                                                        </span>
                                                    )}
                                                </td>
                                                <td className="px-6 py-4 text-right">
                                                    {req.status === 'pending' ? (
                                                        <div className="flex items-center justify-end gap-2">
                                                            <button
                                                                onClick={() => handleReject(req)}
                                                                disabled={processingId === req.id}
                                                                className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded-lg text-xs font-bold transition-colors disabled:opacity-50"
                                                            >
                                                                Reddet
                                                            </button>
                                                            <button
                                                                onClick={() => handleApprove(req)}
                                                                disabled={processingId === req.id}
                                                                className="px-3 py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-xs font-bold transition-colors shadow-sm disabled:opacity-50"
                                                            >
                                                                {processingId === req.id ? 'İşleniyor...' : 'Onayla & Sil'}
                                                            </button>
                                                        </div>
                                                    ) : (
                                                        <span className="text-xs text-zinc-600 font-mono">Tamamlandı</span>
                                                    )}
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    )}
                </main>
            </div>
        </div>
    );
}
