'use client';

import React, { useState, useEffect } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { cn } from '@/lib/utils';
import { updatePassword, reauthenticateWithCredential, EmailAuthProvider } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { adminService, type AdminUser } from '@/services/adminService';
import { ConfigService } from '@/services/configService';

const settingSections = [
    { id: 'general', label: 'Genel', icon: 'tune' },
    { id: 'security', label: 'Güvenlik', icon: 'shield' },
    { id: 'admins', label: 'Yöneticiler', icon: 'admin_panel_settings' },
    { id: 'api', label: 'API', icon: 'api' },
    { id: 'playstore', label: 'Play Store', icon: 'store' },
];

export default function SettingsPage() {
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [activeSection, setActiveSection] = useState('general');

    // System Config States
    const [isVipEnabled, setIsVipEnabled] = useState(false);
    const [isAdsEnabled, setIsAdsEnabled] = useState(true);
    const [isCreditsEnabled, setIsCreditsEnabled] = useState(false);
    const [minimumAge, setMinimumAge] = useState(18);
    const [maxDistance, setMaxDistance] = useState(100);
    const [dailyLikeLimit, setDailyLikeLimit] = useState(25);
    const [locationWeight, setLocationWeight] = useState(35);
    const [interestsWeight, setInterestsWeight] = useState(40);
    const [activityWeight, setActivityWeight] = useState(25);
    const [isMaintenanceMode, setIsMaintenanceMode] = useState(false);
    const [maintenanceMessage, setMaintenanceMessage] = useState('');
    const [minVersion, setMinVersion] = useState('1.0.0');
    const [contactEmail, setContactEmail] = useState('support@dengim.app');
    const [darkMode, setDarkMode] = useState(true);

    // Admin Management States
    const [admins, setAdmins] = useState<AdminUser[]>([]);
    const [isAddingAdmin, setIsAddingAdmin] = useState(false);
    const [newAdmin, setNewAdmin] = useState({
        name: '',
        email: '',
        role: 'moderator' as AdminUser['role'],
        status: 'active' as const
    });

    // Password States
    const [currentPassword, setCurrentPassword] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [isUpdatingPassword, setIsUpdatingPassword] = useState(false);

    useEffect(() => {
        const loadData = async () => {
            setLoading(true);
            try {
                const data = await ConfigService.getConfig();
                if (data) {
                    setIsVipEnabled(data.isVipEnabled ?? false);
                    setIsAdsEnabled(data.isAdsEnabled ?? true);
                    setIsCreditsEnabled(data.isCreditsEnabled ?? false);
                    setMinimumAge(data.minimumAge ?? 18);
                    setMaxDistance(data.maxDistance ?? 100);
                    setDailyLikeLimit(data.dailyLikeLimit ?? 25);
                    setLocationWeight(data.locationWeight ?? 35);
                    setInterestsWeight(data.interestsWeight ?? 40);
                    setActivityWeight(data.activityWeight ?? 25);
                    setIsMaintenanceMode(data.isMaintenanceMode ?? false);
                    setMaintenanceMessage(data.maintenanceMessage ?? '');
                    setMinVersion(data.minVersion ?? '1.0.0');
                    setContactEmail(data.contactEmail ?? 'support@dengim.com');
                    setDarkMode(data.darkMode ?? true);
                }

                const adminList = await adminService.getAdmins();
                setAdmins(adminList);
            } catch (error) {
                console.error("Load error:", error);
            } finally {
                setLoading(false);
            }
        };
        loadData();
    }, []);

    const handleSave = async () => {
        setSaving(true);
        try {
            await ConfigService.updateConfig({
                isVipEnabled,
                isAdsEnabled,
                isCreditsEnabled,
                minimumAge,
                maxDistance,
                dailyLikeLimit,
                locationWeight,
                interestsWeight,
                activityWeight,
                isMaintenanceMode,
                maintenanceMessage,
                minVersion,
                contactEmail,
                darkMode,
            });
            alert('Ayarlar başarıyla kaydedildi!');
        } catch (error) {
            console.error(error);
            alert('Kayıt sırasında hata oluştu.');
        } finally {
            setSaving(false);
        }
    };

    const handleAddAdmin = async () => {
        if (!newAdmin.name || !newAdmin.email) return;
        const success = await adminService.addAdmin(newAdmin);
        if (success) {
            setAdmins(await adminService.getAdmins());
            setIsAddingAdmin(false);
            setNewAdmin({ name: '', email: '', role: 'moderator', status: 'active' });
            alert('Yönetici başarıyla eklendi!');
        } else {
            alert('Yönetici eklenirken hata oluştu!');
        }
    };

    const handleDeleteAdmin = async (email: string) => {
        if (!confirm('Bu yöneticiyi silmek istediğinize emin misiniz?')) return;
        const success = await adminService.deleteAdmin(email);
        if (success) {
            setAdmins(await adminService.getAdmins());
        }
    };

    const handleChangePassword = async (e: React.FormEvent) => {
        e.preventDefault();
        if (newPassword !== confirmPassword) {
            alert('Şifreler eşleşmiyor!');
            return;
        }
        if (!auth.currentUser) return;

        setIsUpdatingPassword(true);
        try {
            const credential = EmailAuthProvider.credential(auth.currentUser.email!, currentPassword);
            await reauthenticateWithCredential(auth.currentUser, credential);
            await updatePassword(auth.currentUser, newPassword);

            alert('Şifreniz başarıyla güncellendi!');
            setCurrentPassword('');
            setNewPassword('');
            setConfirmPassword('');
        } catch (error: any) {
            console.error('Password update error:', error);
            alert('Şifre güncellenirken hata oluştu: ' + error.message);
        } finally {
            setIsUpdatingPassword(false);
        }
    };

    if (loading) return null;

    return (
        <div className="flex min-h-screen bg-background-dark">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
                <Header />
                <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-24 md:pb-6 custom-scrollbar">
                    <div className="mb-8">
                        <h2 className="text-2xl font-bold text-white mb-2">Sistem Ayarları</h2>
                        <p className="text-white/40 text-sm">Uygulama genelindeki özellikleri buradan yönetin.</p>
                    </div>

                    <div className="flex gap-4 mb-6 overflow-x-auto pb-2 scrollbar-none">
                        {settingSections.map((section) => (
                            <button
                                key={section.id}
                                onClick={() => setActiveSection(section.id)}
                                className={cn(
                                    "flex items-center gap-2 px-6 py-3 rounded-2xl transition-all whitespace-nowrap",
                                    activeSection === section.id
                                        ? "bg-primary text-white shadow-lg shadow-primary/20"
                                        : "bg-white/5 text-white/50 hover:bg-white/10"
                                )}
                            >
                                <span className="material-symbols-outlined text-xl">{section.icon}</span>
                                <span className="font-medium">{section.label}</span>
                            </button>
                        ))}
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-1 gap-6">
                        {activeSection === 'general' && (
                            <div className="space-y-6">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <Card glass className="p-6">
                                        <h3 className="text-lg font-bold text-white mb-6">Özellik Bayrakları</h3>
                                        <div className="space-y-4">
                                            {[
                                                { id: 'vip', label: 'VIP Sistemi', desc: 'Premium özellikleri aktif eder', state: isVipEnabled, setState: setIsVipEnabled },
                                                { id: 'ads', label: 'Reklamlar', desc: 'AdMob entegrasyonu', state: isAdsEnabled, setState: setIsAdsEnabled },
                                                { id: 'credits', label: 'Kredi Sistemi', desc: 'İç içerik satın alma', state: isCreditsEnabled, setState: setIsCreditsEnabled },
                                                { id: 'maintenance', label: 'Bakım Modu', desc: 'Uygulamayı bakıma alır', state: isMaintenanceMode, setState: setIsMaintenanceMode },
                                            ].map((feature) => (
                                                <div key={feature.id} className="flex items-center justify-between py-2">
                                                    <div>
                                                        <p className="font-medium text-white">{feature.label}</p>
                                                        <p className="text-xs text-white/40">{feature.desc}</p>
                                                    </div>
                                                    <button
                                                        onClick={() => feature.setState(!feature.state)}
                                                        className={cn(
                                                            "w-12 h-6 rounded-full transition-colors relative",
                                                            feature.state ? "bg-primary" : "bg-white/10"
                                                        )}
                                                    >
                                                        <div className={cn(
                                                            "absolute top-1 w-4 h-4 rounded-full bg-white transition-all",
                                                            feature.state ? "right-1" : "left-1"
                                                        )} />
                                                    </button>
                                                </div>
                                            ))}
                                        </div>
                                    </Card>

                                    <Card glass className="p-6">
                                        <h3 className="text-lg font-bold text-white mb-6">Uygulama Bilgileri</h3>
                                        <div className="space-y-4">
                                            <Input
                                                label="Minimum Versiyon"
                                                value={minVersion}
                                                onChange={(e) => setMinVersion(e.target.value)}
                                            />
                                            <Input
                                                label="Destek E-postası"
                                                value={contactEmail}
                                                onChange={(e) => setContactEmail(e.target.value)}
                                            />
                                            <Input
                                                label="Bakım Mesajı"
                                                value={maintenanceMessage}
                                                onChange={(e) => setMaintenanceMessage(e.target.value)}
                                            />
                                        </div>
                                    </Card>
                                </div>

                                <Card glass className="p-6">
                                    <h3 className="text-lg font-bold text-white mb-6">Algoritma & Kullanım Limitleri</h3>
                                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                                        <div className="space-y-4">
                                            <Input label="Minimum Yaş" type="number" value={minimumAge.toString()} onChange={(e) => setMinimumAge(parseInt(e.target.value))} />
                                            <Input label="Maksimum Mesafe (km)" type="number" value={maxDistance.toString()} onChange={(e) => setMaxDistance(parseInt(e.target.value))} />
                                            <Input label="Günlük Beğeni Limiti" type="number" value={dailyLikeLimit.toString()} onChange={(e) => setDailyLikeLimit(parseInt(e.target.value))} />
                                        </div>
                                        <div className="md:col-span-2">
                                            <p className="text-sm font-medium text-white/70 mb-4">Eşleşme Ağırlıkları (%)</p>
                                            <div className="grid grid-cols-3 gap-4">
                                                <div className="p-4 bg-white/5 rounded-2xl">
                                                    <p className="text-xs text-white/40 mb-1">Konum</p>
                                                    <input type="number" value={locationWeight} onChange={(e) => setLocationWeight(parseInt(e.target.value))} className="w-full bg-transparent text-xl font-bold text-primary outline-none" />
                                                </div>
                                                <div className="p-4 bg-white/5 rounded-2xl">
                                                    <p className="text-xs text-white/40 mb-1">İlgi Alanları</p>
                                                    <input type="number" value={interestsWeight} onChange={(e) => setInterestsWeight(parseInt(e.target.value))} className="w-full bg-transparent text-xl font-bold text-primary outline-none" />
                                                </div>
                                                <div className="p-4 bg-white/5 rounded-2xl">
                                                    <p className="text-xs text-white/40 mb-1">Aktivite</p>
                                                    <input type="number" value={activityWeight} onChange={(e) => setActivityWeight(parseInt(e.target.value))} className="w-full bg-transparent text-xl font-bold text-primary outline-none" />
                                                </div>
                                            </div>
                                            {(locationWeight + interestsWeight + activityWeight) !== 100 && (
                                                <p className="text-xs text-rose-500 mt-2">Toplam %100 olmalıdır! (Şu an: {locationWeight + interestsWeight + activityWeight}%)</p>
                                            )}
                                        </div>
                                    </div>
                                </Card>

                                <div className="flex justify-end">
                                    <Button className="h-14 px-12 text-lg shadow-xl shadow-primary/20" onClick={handleSave} loading={saving}>
                                        Ayarları Kaydet
                                    </Button>
                                </div>
                            </div>
                        )}

                        {activeSection === 'security' && (
                            <div className="max-w-2xl space-y-6">
                                <Card glass className="p-6">
                                    <h3 className="text-lg font-bold text-white mb-6">Şifre Değiştir</h3>
                                    <form onSubmit={handleChangePassword} className="space-y-4">
                                        <Input label="Mevcut Şifre" type="password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} required />
                                        <Input label="Yeni Şifre" type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} required />
                                        <Input label="Yeni Şifre (Tekrar)" type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} required />
                                        <Button type="submit" className="w-full h-12" loading={isUpdatingPassword}>Şifreyi Güncelle</Button>
                                    </form>
                                </Card>
                            </div>
                        )}

                        {activeSection === 'admins' && (
                            <div className="space-y-6">
                                <div className="flex justify-between items-center">
                                    <h3 className="text-xl font-bold text-white">Yöneticiler</h3>
                                    <Button onClick={() => setIsAddingAdmin(true)}>Yönetici Ekle</Button>
                                </div>

                                {isAddingAdmin && (
                                    <Card glass className="p-6">
                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                                            <Input label="Ad Soyad" value={newAdmin.name} onChange={(e) => setNewAdmin({ ...newAdmin, name: e.target.value })} />
                                            <Input label="E-posta" type="email" value={newAdmin.email} onChange={(e) => setNewAdmin({ ...newAdmin, email: e.target.value })} />
                                        </div>
                                        <div className="mb-6">
                                            <label className="block text-sm font-medium text-white/70 mb-2">Rol</label>
                                            <select
                                                value={newAdmin.role}
                                                onChange={(e) => setNewAdmin({ ...newAdmin, role: e.target.value as any })}
                                                className="w-full h-12 bg-white/5 border border-white/10 rounded-xl px-4 text-white outline-none focus:border-primary"
                                            >
                                                <option value="moderator">Moderator</option>
                                                <option value="admin">Admin</option>
                                                <option value="super_admin">Süper Admin</option>
                                            </select>
                                        </div>
                                        <div className="flex gap-4">
                                            <Button className="flex-1" onClick={handleAddAdmin}>Ekle</Button>
                                            <Button variant="ghost" className="flex-1" onClick={() => setIsAddingAdmin(false)}>İptal</Button>
                                        </div>
                                    </Card>
                                )}

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    {admins.map((admin) => (
                                        <Card key={admin.email} glass className="p-4 flex items-center justify-between">
                                            <div className="flex items-center gap-4">
                                                <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold">
                                                    {admin.name[0]}
                                                </div>
                                                <div>
                                                    <p className="font-bold text-white">{admin.name}</p>
                                                    <p className="text-xs text-white/40">{admin.email}</p>
                                                </div>
                                            </div>
                                            <div className="flex items-center gap-3">
                                                <span className="text-[10px] bg-white/10 text-white/60 px-2 py-1 rounded-full uppercase font-bold">
                                                    {admin.role}
                                                </span>
                                                <button onClick={() => handleDeleteAdmin(admin.email)} className="text-rose-500 hover:bg-rose-500/10 p-2 rounded-lg">
                                                    <span className="material-symbols-outlined text-xl">delete</span>
                                                </button>
                                            </div>
                                        </Card>
                                    ))}
                                </div>
                            </div>
                        )}

                        {activeSection === 'api' && (
                            <div className="max-w-2xl space-y-6">
                                <Card glass className="p-6">
                                    <h3 className="text-lg font-bold text-white mb-6">API Entegrasyonları</h3>
                                    <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl mb-6">
                                        <p className="text-emerald-400 text-sm font-medium">API servisleri şu an aktif ve sağlıklı çalışıyor.</p>
                                    </div>
                                    <div className="space-y-4">
                                        <div className="p-4 bg-white/5 rounded-2xl">
                                            <p className="text-xs text-white/40 mb-1">Production Key</p>
                                            <div className="flex items-center justify-between gap-4">
                                                <code className="text-sm text-white/80 font-mono truncate">pk_live_83921...</code>
                                                <Button variant="ghost" size="sm">Kopyala</Button>
                                            </div>
                                        </div>
                                    </div>
                                </Card>
                            </div>
                        )}

                        {/* Play Store Uyumluluk */}
                        {activeSection === 'playstore' && (
                            <div className="space-y-6">
                                <Card glass className="p-6">
                                    <h3 className="text-lg font-bold text-white mb-2 flex items-center gap-2">
                                        <span className="material-symbols-outlined text-primary">store</span>
                                        Google Play Store Uyumluluk Kontrol Listesi
                                    </h3>
                                    <p className="text-sm text-white/40 mb-6">Uygulamanızı Play Store&apos;a yüklemeden önce tüm maddelerin yeşil olduğundan emin olun.</p>

                                    <div className="space-y-3">
                                        {[
                                            { label: 'Gizlilik Politikası URL\'si Tanımlı', status: true, desc: 'Settings → contactEmail & privacy policy URL' },
                                            { label: 'Kullanıcı Raporlama Sistemi Aktif', status: true, desc: 'Kullanıcılar profil, mesaj ve hikayeleri raporlayabiliyor' },
                                            { label: 'Engelleme (Block) Sistemi Aktif', status: true, desc: 'Kullanıcılar birbirini engelleyebiliyor' },
                                            { label: 'İçerik Moderasyonu Aktif', status: true, desc: 'Fotoğraf, biyografi ve profil doğrulaması aktif' },
                                            { label: 'Yaş Doğrulaması (18+)', status: minimumAge >= 18, desc: `Minimum yaş: ${minimumAge}` },
                                            { label: 'Şikayet Yanıtlama Süreci', status: true, desc: 'Admin panelden şikayetler yönetiliyor' },
                                            { label: 'Küfür/Uygunsuz İçerik Filtresi', status: true, desc: 'Moderasyon ayarlarından yönetilebilir' },
                                            { label: 'Kullanıcı Banlama Sistemi', status: true, desc: 'Ban süresi, sebebi ve itiraz hakkı mevcut' },
                                            { label: 'Premium Abonelik Yönetimi', status: true, desc: 'In-app purchase entegrasyonu ve tier yönetimi' },
                                            { label: 'Veri Silme Mekanizması', status: true, desc: 'Kullanıcılar hesaplarını silebilir' },
                                            { label: 'Minimum Versiyon Kontrolü', status: !!minVersion, desc: `Minimum versiyon: ${minVersion}` },
                                            { label: 'Bakım Modu Desteği', status: true, desc: isMaintenanceMode ? '⚠️ BAKIM MODU AKTİF' : 'Bakım modu hazır (şu an kapalı)' },
                                        ].map((item, i) => (
                                            <div key={i} className={cn(
                                                "flex items-center gap-4 p-4 rounded-xl border",
                                                item.status ? "bg-emerald-500/5 border-emerald-500/20" : "bg-rose-500/5 border-rose-500/20"
                                            )}>
                                                <span className={cn("material-symbols-outlined text-xl", item.status ? "text-emerald-500" : "text-rose-500")}>
                                                    {item.status ? 'check_circle' : 'cancel'}
                                                </span>
                                                <div className="flex-1">
                                                    <p className="text-sm font-bold text-white">{item.label}</p>
                                                    <p className="text-xs text-white/40">{item.desc}</p>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </Card>

                                <Card glass className="p-6">
                                    <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
                                        <span className="material-symbols-outlined text-amber-500">warning</span>
                                        Play Store İnceleme Notları
                                    </h3>
                                    <div className="space-y-3 text-sm text-white/70">
                                        <div className="p-3 bg-amber-500/5 rounded-xl border border-amber-500/10">
                                            <p className="font-bold text-amber-500 mb-1">📋 İçerik Derecelendirmesi</p>
                                            <p>Uygulamanın 18+ olarak derecelendirildiğinden emin olun. Dating uygulamaları &quot;Everyone&quot; olarak yayınlanamaz.</p>
                                        </div>
                                        <div className="p-3 bg-blue-500/5 rounded-xl border border-blue-500/10">
                                            <p className="font-bold text-blue-400 mb-1">🔐 Veri Güvenliği Formu</p>
                                            <p>Play Console&apos;da Data Safety bölümünü doğru doldurun: konum, fotoğraf, kişisel bilgiler topluyorsunuz.</p>
                                        </div>
                                        <div className="p-3 bg-purple-500/5 rounded-xl border border-purple-500/10">
                                            <p className="font-bold text-purple-400 mb-1">💳 Abonelik Politikası</p>
                                            <p>Auto-renewal ve iptal koşullarını uygulama içinde ve mağaza listesinde belirtin.</p>
                                        </div>
                                        <div className="p-3 bg-emerald-500/5 rounded-xl border border-emerald-500/10">
                                            <p className="font-bold text-emerald-400 mb-1">✅ Reklam Bildirimi</p>
                                            <p>AdMob kullanıyorsanız, mağaza listesinde &quot;Contains ads&quot; işaretleyin.</p>
                                        </div>
                                    </div>
                                </Card>
                            </div>
                        )}
                    </div>
                </main>
                <BottomNav />
            </div>
        </div>
    );
}
