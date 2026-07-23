import {
    collection,
    getCountFromServer,
    query,
    where,
    Timestamp,
    addDoc,
    orderBy,
    limit,
    getDocs,
    doc,
    updateDoc,
    writeBatch,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

export const NotificationService = {
    // Bildirim Segment Sayılarını Hesapla
    getSegmentCounts: async () => {
        try {
            const usersColl = collection(db, "users");
            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
            const sevenDaysAgoTimestamp = Timestamp.fromDate(sevenDaysAgo);

            const [all, premium, newUsers, inactive, male, female] = await Promise.all([
                getCountFromServer(usersColl),
                getCountFromServer(query(usersColl, where("isPremium", "==", true))),
                getCountFromServer(query(usersColl, where("createdAt", ">=", sevenDaysAgoTimestamp))),
                getCountFromServer(query(usersColl, where("lastActive", "<", sevenDaysAgoTimestamp))),
                getCountFromServer(query(usersColl, where("gender", "in", ["male", "Erkek"]))),
                getCountFromServer(query(usersColl, where("gender", "in", ["female", "Kadın"])))
            ]);

            return {
                all: all.data().count,
                premium: premium.data().count,
                new: newUsers.data().count,
                inactive: inactive.data().count,
                male: male.data().count,
                female: female.data().count,
            };
        } catch (error) {
            console.error("Segment counts error:", error);
            return { all: 0, premium: 0, new: 0, inactive: 0, male: 0, female: 0 };
        }
    },

    // Yeni Bildirim Gönder — Hem kuyruğa ekle, hem tüm kullanıcılara yaz
    sendPushNotification: async (data: {
        title: string;
        body: string;
        segment: string;
        imageUrl?: string;
    }) => {
        try {
            // 1. Hedef segment'e göre kullanıcıları bul
            const usersColl = collection(db, "users");
            let usersQuery;

            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
            const sevenDaysAgoTimestamp = Timestamp.fromDate(sevenDaysAgo);

            switch (data.segment) {
                case 'premium':
                    usersQuery = query(usersColl, where("isPremium", "==", true));
                    break;
                case 'new':
                    usersQuery = query(usersColl, where("createdAt", ">=", sevenDaysAgoTimestamp));
                    break;
                case 'inactive':
                    usersQuery = query(usersColl, where("lastActive", "<", sevenDaysAgoTimestamp));
                    break;
                case 'male':
                    usersQuery = query(usersColl, where("gender", "in", ["male", "Erkek"]));
                    break;
                case 'female':
                    usersQuery = query(usersColl, where("gender", "in", ["female", "Kadın"]));
                    break;
                case 'all':
                default:
                    usersQuery = query(usersColl);
                    break;
            }

            const usersSnapshot = await getDocs(usersQuery);
            const totalUsers = usersSnapshot.docs.length;

            // 2. Duyuruyu global announcements koleksiyonuna kaydet
            // Bu sayede yeni kayıt olan kullanıcılar da görebilir
            const announcementRef = await addDoc(collection(db, "announcements"), {
                title: data.title,
                body: data.body,
                segment: data.segment,
                imageUrl: data.imageUrl || null,
                createdAt: Timestamp.now(),
                isActive: true,
                sentCount: totalUsers,
            });

            // 3. Mevcut kullanıcıların notifications alt koleksiyonuna yaz (batch ile)
            // Firestore batch limiti 500, chunk'lara bölerek yaz
            const BATCH_SIZE = 400;
            let sentCount = 0;

            for (let i = 0; i < usersSnapshot.docs.length; i += BATCH_SIZE) {
                const batch = writeBatch(db);
                const chunk = usersSnapshot.docs.slice(i, i + BATCH_SIZE);

                for (const userDoc of chunk) {
                    const notifRef = doc(collection(db, "users", userDoc.id, "notifications"));
                    batch.set(notifRef, {
                        type: 'announcement',
                        title: data.title,
                        body: data.body,
                        imageUrl: data.imageUrl || null,
                        announcementId: announcementRef.id,
                        senderId: 'admin',
                        isRead: false,
                        createdAt: Timestamp.now(),
                        data: {
                            segment: data.segment,
                        },
                    });
                }

                await batch.commit();
                sentCount += chunk.length;
            }

            // 4. Kuyruğa da ekle (geçmiş kaydı için)
            await addDoc(collection(db, "notification_queue"), {
                ...data,
                announcementId: announcementRef.id,
                status: 'sent',
                createdAt: Timestamp.now(),
                sentCount: sentCount,
                totalTarget: totalUsers,
            });

            return { success: true, sentCount };
        } catch (error) {
            console.error("Send notification error:", error);
            return { success: false, sentCount: 0 };
        }
    },

    // Bildirim Geçmişini Getir
    getHistory: async () => {
        try {
            const q = query(
                collection(db, "notification_queue"),
                orderBy("createdAt", "desc"),
                limit(30)
            );
            const snapshot = await getDocs(q);
            return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        } catch (error) {
            console.error("Get history error:", error);
            return [];
        }
    },

    // Aktif duyuruları getir (yeni kullanıcılar için)
    getActiveAnnouncements: async () => {
        try {
            const q = query(
                collection(db, "announcements"),
                where("isActive", "==", true),
                orderBy("createdAt", "desc"),
                limit(10)
            );
            const snapshot = await getDocs(q);
            return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        } catch (error) {
            console.error("Get announcements error:", error);
            return [];
        }
    },

    // Duyuruyu devre dışı bırak
    deactivateAnnouncement: async (announcementId: string) => {
        try {
            await updateDoc(doc(db, "announcements", announcementId), {
                isActive: false,
            });
            return true;
        } catch (error) {
            console.error("Deactivate announcement error:", error);
            return false;
        }
    },
};
