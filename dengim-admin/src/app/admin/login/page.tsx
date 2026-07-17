'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
    signInWithEmailAndPassword,
    createUserWithEmailAndPassword,
    sendPasswordResetEmail,
    GoogleAuthProvider,
    signInWithPopup
} from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase';
import { useAdminStore } from '@/store/adminStore';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';

// Admin kontrolü için yardımcı fonksiyon
const checkAdminAccess = async (email: string): Promise<{ isAdmin: boolean; role: string; name: string }> => {
    try {
        // Firestore'da admin koleksiyonunu kontrol et
        const adminDoc = await getDoc(doc(db, 'admins', email));
        if (adminDoc.exists()) {
            const data = adminDoc.data();
            return { isAdmin: true, role: data.role || 'admin', name: data.name || email.split('@')[0] };
        }

        // İlk kurulum için: Eğer hiç admin yoksa, belirli email'i otomatik admin yap
        const masterEmails = ['omerbedirhano@gmail.com'];
        if (masterEmails.includes(email)) {
            // Master admin'i Firestore'a kaydet
            await setDoc(doc(db, 'admins', email), {
                email,
                name: 'Ömer Bedirhan',
                role: 'super_admin',
                createdAt: new Date(),
                lastLogin: new Date()
            });
            return { isAdmin: true, role: 'super_admin', name: 'Ömer Bedirhan' };
        }

        return { isAdmin: false, role: '', name: '' };
    } catch (error) {
        console.error('Admin check error:', error);
        return { isAdmin: false, role: '', name: '' };
    }
};

export default function LoginPage() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [resetSent, setResetSent] = useState(false);
    const [error, setError] = useState('');
    const router = useRouter();
    const { setCurrentAdmin } = useAdminStore();

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const userCredential = await signInWithEmailAndPassword(auth, email, password);

            // Admin yetkisi kontrolü
            const adminCheck = await checkAdminAccess(userCredential.user.email || '');
            if (!adminCheck.isAdmin) {
                setError('Bu hesap admin yetkisine sahip değil.');
                setLoading(false);
                return;
            }

            // Son giriş zamanını güncelle
            await setDoc(doc(db, 'admins', userCredential.user.email || ''), {
                lastLogin: new Date()
            }, { merge: true });

            const validRoles = ["super_admin", "admin", "moderator", "support"] as const;
            type Role = typeof validRoles[number];
            const role: Role = validRoles.includes(adminCheck.role as Role)
                ? adminCheck.role as Role
                : "admin";

            setCurrentAdmin({
                id: userCredential.user.uid,
                name: adminCheck.name,
                email: userCredential.user.email || '',
                role,
            });
            router.push('/admin');
        } catch (err: any) {
            console.error("Login Error:", err.code);
            if (err.code === 'auth/user-not-found') {
                await tryCreateAccount();
            }
            else if (err.code === 'auth/wrong-password') {
                setError('Şifre hatalı. Lütfen kontrol edin.');
            }
            else if (err.code === 'auth/invalid-credential' || err.code === 'auth/invalid-login-credentials') {
                await tryCreateAccount();
            } else {
                setError('Giriş yapılırken bir hata oluştu: ' + err.message);
            }
        } finally {
            setLoading(false);
        }
    };

    const handleGoogleLogin = async () => {
        setLoading(true);
        setError('');
        const provider = new GoogleAuthProvider();
        try {
            const result = await signInWithPopup(auth, provider);

            // Firestore'dan admin yetkisi kontrolü
            const adminCheck = await checkAdminAccess(result.user.email || '');
            if (!adminCheck.isAdmin) {
                setError('Bu Google hesabı admin yetkisine sahip değil.');
                setLoading(false);
                return;
            }

            // Son giriş zamanını güncelle
            await setDoc(doc(db, 'admins', result.user.email || ''), {
                lastLogin: new Date()
            }, { merge: true });

            const validRoles = ["super_admin", "admin", "moderator", "support"] as const;
            type Role = typeof validRoles[number];
            const role: Role = validRoles.includes(adminCheck.role as Role)
                ? adminCheck.role as Role
                : "admin";

            setCurrentAdmin({
                id: result.user.uid,
                name: adminCheck.name || result.user.displayName || 'Admin',
                email: result.user.email || '',
                role,
            });
            router.push('/admin');
        } catch (err: any) {
            console.error("Google Login Error:", err);
            if (err.code === 'auth/popup-closed-by-user') {
                setError('Giriş penceresi kapatıldı.');
            } else if (err.code === 'auth/operation-not-allowed') {
                setError('Google ile giriş Firebase konsolunda aktif değil.');
            } else {
                setError('Google ile giriş hatası: ' + err.message);
            }
        } finally {
            setLoading(false);
        }
    };

    const tryCreateAccount = async () => {
        // Admin yetkisi kontrolü
        const adminCheck = await checkAdminAccess(email);
        if (!adminCheck.isAdmin) {
            setError('E-posta veya şifre hatalı.');
            return;
        }

        try {
            const newUser = await createUserWithEmailAndPassword(auth, email, password);
            const validRoles = ["super_admin", "admin", "moderator", "support"] as const;
            type Role = typeof validRoles[number];
            const role: Role = validRoles.includes(adminCheck.role as Role)
                ? adminCheck.role as Role
                : "admin";

            setCurrentAdmin({
                id: newUser.user.uid,
                name: adminCheck.name,
                email: newUser.user.email || '',
                role,
            });
            router.push('/admin');
        } catch (createErr: any) {
            if (createErr.code === 'auth/email-already-in-use') {
                setError('Bu e-posta adresi zaten kayıtlı fakat girilen şifre yanlış.');
            } else {
                setError('Hesap oluşturulamadı: ' + createErr.message);
            }
        }
    };

    const handleForgotPassword = async () => {
        if (!email) {
            setError('Lütfen e-posta adresinizi girin.');
            return;
        }
        try {
            await sendPasswordResetEmail(auth, email);
            setResetSent(true);
            setError('');
        } catch (err: any) {
            setError('Sıfırlama e-postası gönderilemedi: ' + err.message);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-background-dark p-4">
            <div className="w-full max-w-md space-y-8 glass p-8 rounded-2xl border border-primary/20">
                <div className="text-center flex flex-col items-center">
                    <img 
                        src="/logo.png" 
                        alt="Dengim Logo" 
                        className="w-16 h-16 rounded-2xl object-cover mb-4 shadow-lg shadow-primary/20 border border-primary/20"
                    />
                    <h1 className="text-3xl font-black uppercase tracking-tight text-white">DENGİM</h1>
                    <p className="text-primary text-xs font-bold uppercase tracking-widest mt-1">Dating Admin Portal</p>
                </div>

                <div className="space-y-4">
                    <form onSubmit={handleLogin} className="space-y-6">
                        <Input
                            label="E-posta"
                            type="email"
                            placeholder="admin@dengim.com"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                            className="bg-background-dark border-white/10"
                        />

                        <div>
                            <Input
                                label="Şifre"
                                type="password"
                                placeholder="••••••••"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                                className="bg-background-dark border-white/10"
                            />
                            <div className="flex justify-end mt-1">
                                <button
                                    type="button"
                                    onClick={handleForgotPassword}
                                    className="text-xs text-primary hover:text-primary/80 transition-colors"
                                >
                                    Şifremi Unuttum
                                </button>
                            </div>
                        </div>

                        <Button type="submit" className="w-full h-12 text-base" loading={loading}>
                            Giriş Yap
                        </Button>
                    </form>

                    <div className="relative">
                        <div className="absolute inset-0 flex items-center">
                            <div className="w-full border-t border-white/10"></div>
                        </div>
                        <div className="relative flex justify-center text-xs uppercase">
                            <span className="bg-background-dark px-2 text-white/30 italic">ya da</span>
                        </div>
                    </div>

                    <button
                        onClick={handleGoogleLogin}
                        disabled={loading}
                        className="w-full h-12 flex items-center justify-center gap-3 bg-white text-black font-semibold rounded-xl hover:bg-white/90 transition-all disabled:opacity-50"
                    >
                        <img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" alt="Google" className="w-5 h-5" />
                        Google ile Devam Et
                    </button>
                </div>

                {error && (
                    <div className="p-3 rounded-lg bg-rose-500/10 border border-rose-500/20 text-rose-500 text-sm font-medium text-center">
                        {error}
                    </div>
                )}

                {resetSent && (
                    <div className="p-3 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-500 text-sm font-medium text-center">
                        Şifre sıfırlama bağlantısı e-posta adresinize gönderildi!
                    </div>
                )}

                <p className="text-center text-[10px] text-white/20 mt-6">
                    Bu alan sadece yetkili personel içindir. IP Adresiniz kaydedilmektedir.
                </p>
            </div>
        </div>
    );
}
