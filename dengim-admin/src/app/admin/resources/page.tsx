'use client';

import React, { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { cn } from '@/lib/utils';
import { ResourceService, type AppResources } from '@/services/resourceService';

export default function ResourcesPage() {
    const [resources, setResources] = useState<AppResources | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);
    const [activeTab, setActiveTab] = useState('legal');

    useEffect(() => {
        const fetchResources = async () => {
            try {
                const data = await ResourceService.getResources();
                setResources(data);
            } catch (error) {
                console.error('Error fetching resources:', error);
            } finally {
                setIsLoading(false);
            }
        };
        fetchResources();
    }, []);

    const handleSave = async () => {
        if (!resources) return;
        setIsSaving(true);
        try {
            await ResourceService.updateResources(resources);
            alert('Kaynaklar başarıyla güncellendi!');
        } catch (error) {
            console.error('Error saving resources:', error);
            alert('Hata oluştu!');
        } finally {
            setIsSaving(false);
        }
    };

    const updateField = (field: keyof AppResources, value: any) => {
        if (!resources) return;
        setResources({ ...resources, [field]: value });
    };

    if (isLoading) {
        return (
            <div className="flex min-h-screen bg-background-dark">
                <Sidebar />
                <div className="flex-1 flex flex-col items-center justify-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-primary"></div>
                </div>
            </div>
        );
    }

    const tabs = [
        { id: 'legal', label: 'Yasal / Dökümanlar', icon: 'description' },
        { id: 'support', label: 'Destek & İletişim', icon: 'contact_support' },
        { id: 'system', label: 'Sistem & Uygulama', icon: 'phonelink_setup' },
    ];

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">
                    <div className="max-w-4xl mx-auto">
                        <div className="mb-6">
                            <h2 className="text-2xl font-bold text-white">Kaynak Yönetimi</h2>
                            <p className="text-slate-400 text-sm">Uygulama içi dinamik metinler, URL'ler ve sistem kaynakları</p>
                        </div>

                        {/* Tabs */}
                        <div className="flex gap-2 mb-6 overflow-x-auto pb-2 scrollbar-hide">
                            {tabs.map((tab) => (
                                <button
                                    key={tab.id}
                                    onClick={() => setActiveTab(tab.id)}
                                    className={cn(
                                        'flex items-center gap-2 px-6 py-3 rounded-2xl text-sm font-medium transition-all shrink-0',
                                        activeTab === tab.id
                                            ? 'bg-primary text-black'
                                            : 'bg-white/5 text-white/60 hover:bg-white/10'
                                    )}
                                >
                                    <span className="material-symbols-outlined text-lg">{tab.icon}</span>
                                    {tab.label}
                                </button>
                            ))}
                        </div>

                        {resources && (
                            <div className="space-y-6">
                                {/* Legal Section */}
                                {activeTab === 'legal' && (
                                    <div className="animate-in fade-in slide-in-from-bottom-2 duration-300">
                                        <Card glass className="space-y-4">
                                            <h3 className="text-lg font-bold text-white mb-2 italic">Yasal Bağlantılar</h3>
                                            <div className="space-y-4">
                                                <Input
                                                    label="Gizlilik Sözleşmesi URL"
                                                    value={resources.privacyPolicyUrl}
                                                    onChange={(e) => updateField('privacyPolicyUrl', e.target.value)}
                                                    placeholder="https://..."
                                                />
                                                <Input
                                                    label="Kullanım Koşulları (EULA) URL"
                                                    value={resources.termsOfServiceUrl}
                                                    onChange={(e) => updateField('termsOfServiceUrl', e.target.value)}
                                                    placeholder="https://..."
                                                />
                                            </div>
                                        </Card>
                                    </div>
                                )}

                                {/* Support Section */}
                                {activeTab === 'support' && (
                                    <div className="animate-in fade-in slide-in-from-bottom-2 duration-300 space-y-6">
                                        <Card glass className="space-y-4">
                                            <h3 className="text-lg font-bold text-white mb-2 italic">İletişim Bilgileri</h3>
                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                <Input
                                                    label="Destek E-posta"
                                                    value={resources.supportEmail}
                                                    onChange={(e) => updateField('supportEmail', e.target.value)}
                                                    placeholder="admin@dengim.space"
                                                />
                                                <Input
                                                    label="WhatsApp Destek"
                                                    value={resources.whatsappNumber}
                                                    onChange={(e) => updateField('whatsappNumber', e.target.value)}
                                                    placeholder="+905..."
                                                />
                                            </div>
                                        </Card>

                                        <Card glass className="space-y-4">
                                            <h3 className="text-lg font-bold text-white mb-2 italic">Sosyal Medya</h3>
                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                <Input
                                                    label="Instagram URL"
                                                    value={resources.instagramUrl}
                                                    onChange={(e) => updateField('instagramUrl', e.target.value)}
                                                />
                                                <Input
                                                    label="Twitter/X URL"
                                                    value={resources.twitterUrl}
                                                    onChange={(e) => updateField('twitterUrl', e.target.value)}
                                                />
                                            </div>
                                        </Card>
                                    </div>
                                )}

                                {/* System Section */}
                                {activeTab === 'system' && (
                                    <div className="animate-in fade-in slide-in-from-bottom-2 duration-300 space-y-6">
                                        <Card glass className="space-y-4">
                                            <h3 className="text-lg font-bold text-white mb-2 italic">Versiyon & Hoş Geldiniz</h3>
                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                <Input
                                                    label="Yayındaki Versiyon"
                                                    value={resources.appVersion}
                                                    onChange={(e) => updateField('appVersion', e.target.value)}
                                                />
                                                <div className="flex flex-col gap-2">
                                                    <label className="text-sm font-medium text-white/70">Zorunlu Güncelleme</label>
                                                    <button
                                                        onClick={() => updateField('forceUpdate', !resources.forceUpdate)}
                                                        className={cn(
                                                            'h-10 px-4 rounded-xl text-sm font-bold transition-all border',
                                                            resources.forceUpdate
                                                                ? 'bg-rose-500/20 text-rose-500 border-rose-500/30'
                                                                : 'bg-white/5 text-white/50 border-white/10'
                                                        )}
                                                    >
                                                        {resources.forceUpdate ? 'AKTİF (Kullanıcı güncellemeye zorlanır)' : 'PASİF'}
                                                    </button>
                                                </div>
                                            </div>
                                            <Input
                                                label="Hoş Geldiniz Mesajı"
                                                value={resources.welcomeMessage}
                                                onChange={(e) => updateField('welcomeMessage', e.target.value)}
                                                multiline
                                            />
                                        </Card>

                                        <Card glass className="space-y-4 border-rose-500/20">
                                            <div className="flex items-center justify-between mb-2">
                                                <h3 className="text-lg font-bold text-white italic">Bakım Modu</h3>
                                                <button
                                                    onClick={() => updateField('maintenanceMode', !resources.maintenanceMode)}
                                                    className={cn(
                                                        'relative w-14 h-8 rounded-full transition-colors',
                                                        resources.maintenanceMode ? 'bg-rose-500' : 'bg-white/20'
                                                    )}
                                                >
                                                    <span className={cn(
                                                        'absolute top-1 w-6 h-6 rounded-full bg-white shadow-lg transition-transform',
                                                        resources.maintenanceMode ? 'left-7' : 'left-1'
                                                    )} />
                                                </button>
                                            </div>
                                            <p className="text-xs text-white/50 -mt-2 mb-4">Aktif edildiğinde tüm kullanıcılar uygulama girişinde bakım mesajını görür.</p>
                                            <Input
                                                label="Bakım Mesajı"
                                                value={resources.maintenanceMessage}
                                                onChange={(e) => updateField('maintenanceMessage', e.target.value)}
                                                multiline
                                                disabled={!resources.maintenanceMode}
                                            />
                                        </Card>
                                    </div>
                                )}

                                {/* Save Button */}
                                <div className="pt-4">
                                    <Button
                                        className="w-full h-14 bg-primary text-black font-bold text-lg rounded-2xl shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all"
                                        onClick={handleSave}
                                        disabled={isSaving}
                                    >
                                        <span className="material-symbols-outlined mr-2">
                                            {isSaving ? 'sync' : 'save'}
                                        </span>
                                        {isSaving ? 'Kaydediliyor...' : 'Tüm Değişiklikleri Yayınla'}
                                    </Button>
                                    <p className="text-center text-[10px] text-white/30 mt-3 italic">
                                        * Kaydedilen değişiklikler tüm kullanıcılarda anında güncellenir.
                                    </p>
                                </div>
                            </div>
                        )}
                    </div>
                </main>
                <BottomNav />
            </div>
        </div>
    );
}
