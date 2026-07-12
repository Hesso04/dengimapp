import {
    collection,
    getCountFromServer,
    query,
    where,
    getDocs,
    orderBy,
    limit,
    Timestamp as FirestoreTimestamp
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

            const [
                reportsCount,
                messageReportsCount,
                storyReportsCount,
                pendingPhotosCount,
                pendingBiosCount,
                pendingVerificationsCount,
                openTickets
            ] = await Promise.all([
                getCountFromServer(query(collection(db, "reports"), where("status", "==", "pending"))),
                getCountFromServer(query(collection(db, "message_reports"), where("status", "==", "pending"))),
                getCountFromServer(query(collection(db, "story_reports"), where("status", "==", "pending"))),
                getCountFromServer(query(usersColl, where("isVerified", "==", false), where("imageUrl", "!=", ""))),
                getCountFromServer(query(usersColl, where("bioFlagged", "==", true))),
                getCountFromServer(query(verificationsColl, where("status", "==", "pending"))),
                getCountFromServer(query(supportColl, where("status", "==", "open")))
            ]);

            const totalPendingReports = reportsCount.data().count + messageReportsCount.data().count + storyReportsCount.data().count;
            const totalModerationTasks = pendingPhotosCount.data().count + pendingBiosCount.data().count + pendingVerificationsCount.data().count;

            return {
                reports: totalPendingReports,
                moderation: totalModerationTasks,
                support: openTickets.data().count
            };
        } catch (error) {
            console.error("System counts error:", error);
            return { reports: 0, moderation: 0, support: 0 };
        }
    },

    // Dashboard Ana İstatistikleri
    getDashboardStats: async (): Promise<DashboardStats> => {
        try {
            const usersColl = collection(db, "users");
            const matchesColl = collection(db, "matches");

            const now = new Date();
            const todayStart = new Date(now.setHours(0, 0, 0, 0));
            const weekStart = new Date(new Date().setDate(now.getDate() - 7));
            const monthStart = new Date(new Date().setMonth(now.getMonth() - 1));

            const [
                totalUsersSnap,
                premiumUsersSnap,
                reportsCount,
                messageReportsCount,
                storyReportsCount,
                verificationRequestsSnap,
                matchesSnap,
                todayUsersSnap,
                weekUsersSnap,
                monthUsersSnap,
                goldUsersSnap,
                platinumUsersSnap
            ] = await Promise.all([
                getCountFromServer(usersColl),
                getCountFromServer(query(usersColl, where("isPremium", "==", true))),
                getCountFromServer(query(collection(db, "reports"), where("status", "==", "pending"))),
                getCountFromServer(query(collection(db, "message_reports"), where("status", "==", "pending"))),
                getCountFromServer(query(collection(db, "story_reports"), where("status", "==", "pending"))),
                getCountFromServer(query(collection(db, "verification_requests"), where("status", "==", "pending"))),
                getCountFromServer(collection(db, "matches")),
                getCountFromServer(query(usersColl, where("createdAt", ">=", FirestoreTimestamp.fromDate(todayStart)))),
                getCountFromServer(query(usersColl, where("createdAt", ">=", FirestoreTimestamp.fromDate(weekStart)))),
                getCountFromServer(query(usersColl, where("createdAt", ">=", FirestoreTimestamp.fromDate(monthStart)))),
                getCountFromServer(query(usersColl, where("subscriptionTier", "==", "gold"))),
                getCountFromServer(query(usersColl, where("subscriptionTier", "==", "platinum")))
            ]);

            const goldCount = goldUsersSnap?.data().count || 0;
            const platinumCount = platinumUsersSnap?.data().count || 0;
            const mrrValue = (goldCount * 249) + (platinumCount * 449);

            const totalPendingReports = reportsCount.data().count + messageReportsCount.data().count + storyReportsCount.data().count;

            return {
                totalUsers: totalUsersSnap.data().count,
                activeUsers: totalUsersSnap.data().count, // TODO: Define active criteria
                premiumUsers: premiumUsersSnap.data().count,
                totalMatches: matchesSnap.data().count,
                totalMessages: 0, // Requires messages subcollection or count
                pendingReports: totalPendingReports,
                pendingVerifications: verificationRequestsSnap.data().count,
                newUsersToday: todayUsersSnap.data().count,
                newUsersThisWeek: weekUsersSnap.data().count,
                newUsersThisMonth: monthUsersSnap.data().count,
                mrr: mrrValue,
                arr: mrrValue * 12,
                churnRate: 0,
                conversionRate: totalUsersSnap.data().count > 0
                    ? (premiumUsersSnap.data().count / totalUsersSnap.data().count) * 100
                    : 0
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
                conversionRate: 0
            };
        }
    },

    // Kullanıcı Artış Grafiği (Son 7 gün)
    getUserGrowth: async (): Promise<ChartDataPoint[]> => {
        try {
            const days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
            const result: ChartDataPoint[] = [];

            for (let i = 6; i >= 0; i--) {
                const date = new Date();
                date.setDate(date.getDate() - i);
                date.setHours(0, 0, 0, 0);
                const nextDate = new Date(date);
                nextDate.setDate(date.getDate() + 1);

                const q = query(
                    collection(db, "users"),
                    where("createdAt", ">=", FirestoreTimestamp.fromDate(date)),
                    where("createdAt", "<", FirestoreTimestamp.fromDate(nextDate))
                );
                const snap = await getCountFromServer(q);
                result.push({
                    date: days[date.getDay()],
                    value: snap.data().count
                });
            }
            return result;
        } catch (e) {
            return [];
        }
    },

    // Cinsiyet Dağılımı
    getGenderDistribution: async (): Promise<GenderDistribution> => {
        try {
            const usersColl = collection(db, "users");
            const [male, female] = await Promise.all([
                getCountFromServer(query(usersColl, where("gender", "in", ["male", "Erkek"]))),
                getCountFromServer(query(usersColl, where("gender", "in", ["female", "Kadın"]))),
            ]);

            return {
                male: male.data().count,
                female: female.data().count,
                other: 0
            };
        } catch (e) {
            return { male: 0, female: 0, other: 0 };
        }
    }
};
