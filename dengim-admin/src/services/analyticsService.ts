import {
    collection,
    getCountFromServer,
    query,
    where,
    getDocs,
    limit,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { DashboardStats, ChartDataPoint, GenderDistribution } from "@/types";

export const AnalyticsService = {
    // Toplu Sayaçları Getir (Sidebar ve Dashboard için)
    getSystemCounts: async () => {
        try {
            const usersColl = collection(db, "users");
            const supportColl = collection(db, "support_tickets");
            const verificationsColl = collection(db, "verification_requests");
            const reportsColl = collection(db, "reports");

            const [
                reportsSnap,
                verificationsSnap,
                ticketsSnap,
            ] = await Promise.allSettled([
                getCountFromServer(query(reportsColl, where("status", "==", "pending"))),
                getCountFromServer(query(verificationsColl, where("status", "==", "pending"))),
                getCountFromServer(query(supportColl, where("status", "==", "open"))),
            ]);

            const reportsCount = reportsSnap.status === "fulfilled" ? reportsSnap.value.data().count : 0;
            const verificationsCount = verificationsSnap.status === "fulfilled" ? verificationsSnap.value.data().count : 0;
            const supportCount = ticketsSnap.status === "fulfilled" ? ticketsSnap.value.data().count : 0;

            return {
                reports: reportsCount,
                moderation: verificationsCount,
                support: supportCount,
            };
        } catch (error) {
            console.error("System counts error:", error);
            return { reports: 0, moderation: 0, support: 0 };
        }
    },

    // Dashboard Ana İstatistikleri (Fallback korumalı)
    getDashboardStats: async (): Promise<DashboardStats> => {
        try {
            const usersColl = collection(db, "users");
            const matchesColl = collection(db, "matches");

            // Total users
            let totalUsers = 0;
            let premiumUsers = 0;
            let totalMatches = 0;
            let pendingReports = 0;
            let goldCount = 0;
            let platinumCount = 0;

            try {
                const totalSnap = await getCountFromServer(usersColl);
                totalUsers = totalSnap.data().count;
            } catch (e) {
                const usersSnap = await getDocs(usersColl);
                totalUsers = usersSnap.size;
            }

            try {
                const premSnap = await getCountFromServer(query(usersColl, where("isPremium", "==", true)));
                premiumUsers = premSnap.data().count;
            } catch (e) {
                // Ignore
            }

            try {
                const matchSnap = await getCountFromServer(matchesColl);
                totalMatches = matchSnap.data().count;
            } catch (e) {
                // Ignore
            }

            try {
                const repSnap = await getCountFromServer(query(collection(db, "reports"), where("status", "==", "pending")));
                pendingReports = repSnap.data().count;
            } catch (e) {
                // Ignore
            }

            const mrrValue = (goldCount * 249) + (platinumCount * 449);

            return {
                totalUsers,
                activeUsers: totalUsers,
                premiumUsers,
                totalMatches,
                totalMessages: 0,
                pendingReports,
                pendingVerifications: 0,
                newUsersToday: 0,
                newUsersThisWeek: 0,
                newUsersThisMonth: 0,
                mrr: mrrValue,
                arr: mrrValue * 12,
                churnRate: 0,
                conversionRate: totalUsers > 0 ? (premiumUsers / totalUsers) * 100 : 0,
            };
        } catch (error) {
            console.error("Dashboard Stats Error:", error);
            return {
                totalUsers: 0,
                activeUsers: 0,
                premiumUsers: 0,
                totalMatches: 0,
                totalMessages: 0,
                pendingReports: 0,
                pendingVerifications: 0,
                newUsersToday: 0,
                newUsersThisWeek: 0,
                newUsersThisMonth: 0,
                mrr: 0,
                arr: 0,
                churnRate: 0,
                conversionRate: 0,
            };
        }
    },

    // Kullanıcı Artış Grafiği (Son 7 gün)
    getUserGrowth: async (): Promise<ChartDataPoint[]> => {
        try {
            const days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
            const result: ChartDataPoint[] = [];

            // Tüm kullanıcıları alıp tarihe göre gruba böl (Query crash önleme)
            const usersSnap = await getDocs(query(collection(db, "users"), limit(500)));
            const users = usersSnap.docs.map(d => d.data());

            for (let i = 6; i >= 0; i--) {
                const date = new Date();
                date.setDate(date.getDate() - i);
                date.setHours(0, 0, 0, 0);

                const nextDate = new Date(date);
                nextDate.setDate(date.getDate() + 1);

                const count = users.filter(u => {
                    if (!u.createdAt) return false;
                    const uDate = u.createdAt.toDate ? u.createdAt.toDate() : new Date(u.createdAt);
                    return uDate >= date && uDate < nextDate;
                }).length;

                result.push({
                    date: days[date.getDay()],
                    value: count,
                });
            }
            return result;
        } catch (e) {
            console.error("getUserGrowth error:", e);
            return [
                { date: 'Pzt', value: 0 },
                { date: 'Sal', value: 0 },
                { date: 'Çar', value: 0 },
                { date: 'Per', value: 0 },
                { date: 'Cum', value: 0 },
                { date: 'Cmt', value: 0 },
                { date: 'Paz', value: 0 },
            ];
        }
    },

    // Cinsiyet Dağılımı
    getGenderDistribution: async (): Promise<GenderDistribution> => {
        try {
            const usersSnap = await getDocs(query(collection(db, "users"), limit(500)));
            let male = 0;
            let female = 0;

            usersSnap.docs.forEach(docSnap => {
                const g = (docSnap.data().gender || "").toString().toLowerCase();
                if (g === 'male' || g === 'erkek') male++;
                else if (g === 'female' || g === 'kadın') female++;
            });

            return { male, female, other: 0 };
        } catch (e) {
            return { male: 0, female: 0, other: 0 };
        }
    },

    // Anlık Çevrimiçi Kullanıcı İstatistikleri
    getOnlineUserStats: async () => {
        try {
            const usersSnap = await getDocs(query(collection(db, "users"), limit(100)));
            const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);

            const onlineUsers = usersSnap.docs.filter(docSnap => {
                const data = docSnap.data();
                if (data.isOnline === true) return true;
                if (data.lastActive) {
                    const lDate = data.lastActive.toDate ? data.lastActive.toDate() : new Date(data.lastActive);
                    return lDate >= fiveMinutesAgo;
                }
                return false;
            });

            const recentlyActive = usersSnap.docs.slice(0, 6).map(docSnap => {
                const data = docSnap.data();
                return {
                    id: docSnap.id,
                    name: data.name || data.fullName || "Kullanıcı",
                    email: data.email || "",
                    photos: data.photoUrls || data.photos || [],
                    lastActive: data.lastActive?.toDate ? data.lastActive.toDate() : new Date(),
                    createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(),
                    status: data.isBanned ? 'banned' : 'active',
                    isPremium: !!data.isPremium,
                } as any;
            });

            return {
                onlineNow: onlineUsers.length,
                recentlyActive,
            };
        } catch (e) {
            console.error("GetOnlineUserStats error:", e);
            return {
                onlineNow: 0,
                recentlyActive: [],
            };
        }
    },
};
