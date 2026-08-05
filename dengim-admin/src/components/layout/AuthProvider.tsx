'use client';

import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase';
import { useAdminStore } from '@/store/adminStore';

export function AuthProvider({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();
    const { setCurrentAdmin, currentAdmin } = useAdminStore();
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (user) => {
            // 🚨 Bypass Kontrolü: Eğer store'da master admin varsa, Firebase'in "yok" demesini yoksay
            // getState() kullanarak en güncel state'i alıyoruz (closure sorununu önlemek için)
            const currentState = useAdminStore.getState().currentAdmin;

            if (currentState?.id === 'master-admin') {
                setLoading(false);
                // Eğer admin/login sayfasındaysak yönlendir
                if (pathname === '/admin/login') {
                    router.push('/admin');
                }
                return;
            }

            if (user) {
                try {
                    // Firestore'da admin yetkisini doğrula
                    const adminDoc = await getDoc(doc(db, 'admins', user.email || ''));
                    if (adminDoc.exists()) {
                        const data = adminDoc.data();
                        const validRoles = ["super_admin", "admin", "moderator", "support"] as const;
                        type Role = typeof validRoles[number];
                        const role: Role = validRoles.includes(data.role as Role)
                            ? data.role as Role
                            : "admin";

                        setCurrentAdmin({
                            id: user.uid,
                            name: data.name || user.displayName || user.email?.split('@')[0] || 'Admin',
                            email: user.email || '',
                            role,
                        });

                        if (pathname === '/admin/login') {
                            router.push('/admin');
                        }
                    } else {
                        // Eğer master email ise otomatik ekle
                        const masterEmails = ['omerbedirhano@gmail.com'];
                        if (user.email && masterEmails.includes(user.email)) {
                            const newAdminData = {
                                email: user.email,
                                name: user.displayName || 'Ömer Bedirhan',
                                role: 'super_admin',
                                createdAt: new Date(),
                                lastLogin: new Date()
                            };
                            // Firestore'a kaydet (yeni rules izin verecektir)
                            await setDoc(doc(db, 'admins', user.email), newAdminData);
                            
                            setCurrentAdmin({
                                id: user.uid,
                                name: newAdminData.name,
                                email: user.email,
                                role: 'super_admin',
                            });

                            if (pathname === '/admin/login') {
                                router.push('/admin');
                            }
                        } else {
                            // Admin değil, oturumu kapat
                            await signOut(auth);
                            setCurrentAdmin(null);
                            if (pathname?.startsWith('/admin') && pathname !== '/admin/login') {
                                router.push('/admin/login');
                            }
                        }
                    }
                } catch (e) {
                    console.error("Auth provider check error:", e);
                    await signOut(auth);
                    setCurrentAdmin(null);
                    if (pathname?.startsWith('/admin') && pathname !== '/admin/login') {
                        router.push('/admin/login');
                    }
                }
            } else {
                // Kullanıcı çıkış yapmış veya giriş yok
                // Eğer zaten master-admin olarak içerideysek dokunma
                if (currentState?.id !== 'master-admin') {
                    setCurrentAdmin(null);
                    // Yalnızca /admin rotalarındayken logine yönlendir
                    if (pathname?.startsWith('/admin') && pathname !== '/admin/login') {
                        router.push('/admin/login');
                    }
                }
            }
            setLoading(false);
        });

        return () => unsubscribe();
    }, [router, pathname, currentAdmin, setCurrentAdmin]);

    // Sadece /admin rotalarını koru (Landing page vb. koruma dışı kalır)
    const isAdminRoute = pathname?.startsWith('/admin');

    if (isAdminRoute && loading) {
        return (
            <div className="flex min-h-screen items-center justify-center bg-background-dark">
                <div className="flex flex-col items-center gap-4">
                    <div className="h-12 w-12 rounded-full border-4 border-primary border-t-transparent animate-spin" />
                    <p className="text-white/50 text-sm">Yükleniyor...</p>
                </div>
            </div>
        );
    }

    // Admin rotası değilse direkt çocukları render et
    if (!isAdminRoute) {
        return <>{children}</>;
    }

    return <>{children}</>;
}
