'use client';

import React, { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { Card, StatCard } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { SupportService, type SupportTicket } from '@/services/supportService';
import { cn, formatRelativeTime } from '@/lib/utils';
import { Timestamp } from 'firebase/firestore';

export default function SupportPage() {
    const [tickets, setTickets] = useState<SupportTicket[]>([]);
    const [pendingCount, setPendingCount] = useState(0);
    const [loading, setLoading] = useState(true);
    const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null);
    const [reply, setReply] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);

    const fetchData = async () => {
        setLoading(true);
        const [data, count] = await Promise.all([
            SupportService.getTickets(),
            SupportService.getPendingCount()
        ]);
        setTickets(data as any);
        setPendingCount(count);
        setLoading(false);
    };

    useEffect(() => {
        fetchData();
    }, []);

    const handleTicketClick = async (ticket: SupportTicket) => {
        setSelectedTicket(ticket);
    };

    const handleSendReply = async () => {
        if (!selectedTicket || !reply.trim()) return;

        setIsSubmitting(true);
        const success = await SupportService.addMessage(selectedTicket.id, {
            senderId: 'admin',
            senderName: 'Destek Ekibi',
            senderType: 'admin',
            content: reply
        });

        if (success) {
            setReply('');
            // Refresh ticket details
            const updated = await SupportService.getTicketById(selectedTicket.id);
            setSelectedTicket(updated);
            fetchData(); // Refresh list
        } else {
            alert('Yanıt gönderilemedi.');
        }
        setIsSubmitting(false);
    };

    const handleUpdateStatus = async (status: SupportTicket['status']) => {
        if (!selectedTicket) return;
        const success = await SupportService.updateStatus(selectedTicket.id, status);
        if (success) {
            const updated = await SupportService.getTicketById(selectedTicket.id);
            setSelectedTicket(updated);
            fetchData();
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
                        <StatCard
                            title="Açık Talepler"
                            value={pendingCount}
                            icon={<span className="material-symbols-outlined">confirmation_number</span>}
                            borderColor="border-l-primary"
                        />
                        <StatCard title="Yanıt Bekleyen" value="0" borderColor="border-l-accent-indigo" />
                        <StatCard title="Ort. Yanıt Süresi" value="-" borderColor="border-l-accent-emerald" />
                        <StatCard title="Müşteri Memnuniyeti" value="%100" borderColor="border-l-primary" />
                    </div>

                    <div className="p-4 md:p-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
                        {/* Ticket List */}
                        <div className="lg:col-span-1 space-y-4">
                            <h2 className="text-xl font-bold mb-4">Destek Talepleri</h2>
                            {loading ? (
                                <div className="flex justify-center py-20">
                                    <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                                </div>
                            ) : tickets.length > 0 ? (
                                tickets.map((ticket) => (
                                    <Card
                                        key={ticket.id}
                                        padding="sm"
                                        hover
                                        className={cn(
                                            selectedTicket?.id === ticket.id ? 'border-primary bg-primary/5' : 'border-white/5'
                                        )}
                                        onClick={() => handleTicketClick(ticket)}
                                    >
                                        <div className="flex justify-between items-start mb-2">
                                            <span className="text-[10px] font-bold text-primary uppercase tracking-tighter">{ticket.category}</span>
                                            <span className={cn(
                                                'text-[10px] px-1.5 py-0.5 rounded uppercase font-bold',
                                                ticket.status === 'open' ? 'bg-amber-500/20 text-amber-500' :
                                                    ticket.status === 'in_progress' ? 'bg-blue-500/20 text-blue-500' :
                                                        'bg-emerald-500/20 text-emerald-500'
                                            )}>
                                                {ticket.status}
                                            </span>
                                        </div>
                                        <h4 className="font-bold text-sm truncate">{ticket.subject}</h4>
                                        <p className="text-xs text-white/40 truncate">{ticket.userName}</p>
                                    </Card>
                                ))
                            ) : (
                                <div className="text-center py-12 border border-dashed border-white/10 rounded-2xl opacity-30 italic text-sm">
                                    Talep bulunamadı.
                                </div>
                            )}
                        </div>

                        {/* Ticket Details */}
                        <div className="lg:col-span-2">
                            {selectedTicket ? (
                                <Card padding="md" className="flex flex-col h-[600px]">
                                    {/* Detail Header */}
                                    <div className="flex justify-between items-start border-b border-white/5 pb-4 mb-4">
                                        <div>
                                            <h3 className="text-lg font-bold">{selectedTicket.subject}</h3>
                                            <p className="text-sm text-white/40">{selectedTicket.userName} ({selectedTicket.userEmail})</p>
                                        </div>
                                        <div className="flex gap-2">
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                onClick={() => handleUpdateStatus('closed' as any)}
                                            >
                                                Kapat
                                            </Button>
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                onClick={() => handleUpdateStatus('resolved' as any)}
                                            >
                                                Çözüldü
                                            </Button>
                                        </div>
                                    </div>

                                    {/* Messages */}
                                    <div className="flex-1 overflow-y-auto space-y-4 mb-4 pr-2 custom-scrollbar">
                                        {selectedTicket.messages?.map((msg, i) => (
                                            <div
                                                key={i}
                                                className={cn(
                                                    'max-w-[80%] p-3 rounded-2xl text-sm',
                                                    msg.senderType === 'admin'
                                                        ? 'ml-auto bg-primary text-black rounded-tr-none'
                                                        : 'bg-white/5 border border-white/10 rounded-tl-none'
                                                )}
                                            >
                                                <p>{msg.content}</p>
                                                <p className={cn(
                                                    'text-[10px] mt-1 text-right',
                                                    msg.senderType === 'admin' ? 'text-black/50' : 'text-white/30'
                                                )}>
                                                    {msg.createdAt instanceof Timestamp
                                                        ? formatRelativeTime(msg.createdAt.toDate())
                                                        : 'Az önce'}
                                                </p>
                                            </div>
                                        ))}
                                    </div>

                                    {/* Reply Box */}
                                    <div className="flex gap-2 bg-white/5 p-2 rounded-xl">
                                        <input
                                            value={reply}
                                            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setReply(e.target.value)}
                                            placeholder="Bir yanıt yazın..."
                                            className="flex-1 bg-transparent border-none outline-none px-2 text-sm"
                                            onKeyDown={(e: React.KeyboardEvent<HTMLInputElement>) => e.key === 'Enter' && handleSendReply()}
                                        />
                                        <Button
                                            size="icon"
                                            onClick={handleSendReply}
                                            loading={isSubmitting}
                                            disabled={!reply.trim()}
                                        >
                                            <span className="material-symbols-outlined">send</span>
                                        </Button>
                                    </div>
                                </Card>
                            ) : (
                                <div className="h-full flex flex-col items-center justify-center opacity-20 py-24 border border-dashed border-white/10 rounded-3xl">
                                    <span className="material-symbols-outlined text-6xl mb-4">forum</span>
                                    <p className="font-bold">Görüntülemek için bir talep seçin</p>
                                </div>
                            )}
                        </div>
                    </div>
                </main>
                <BottomNav />
            </div>
        </div>
    );
}
