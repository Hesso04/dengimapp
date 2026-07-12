import {
    collection,
    getDocs,
    getDoc,
    doc,
    updateDoc,
    query,
    orderBy,
    limit,
    where,
    Timestamp as FirestoreTimestamp
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Report } from "@/types";

const REPORTS_COLLECTIONS = ["reports", "message_reports", "story_reports"];

export const ReportService = {
    // Raporları getir
    getReports: async (status: string = 'all', limitCount: number = 50) => {
        try {
            const allReports: any[] = [];
            const userCache: { [key: string]: { name: string; email: string } } = {};

            const getUserInfo = async (userId: string) => {
                if (!userId) return { name: "Sistem", email: "-" };
                if (userCache[userId]) return userCache[userId];
                try {
                    const userDoc = await getDoc(doc(db, "users", userId));
                    if (userDoc.exists()) {
                        const data = userDoc.data();
                        userCache[userId] = {
                            name: data.name || data.fullName || "Bilinmiyor",
                            email: data.email || "E-posta yok"
                        };
                        return userCache[userId];
                    }
                } catch (e) {
                    console.error("User fetch error:", e);
                }
                return { name: "Bilinmeyen Kullanıcı", email: "-" };
            };

            for (const collName of REPORTS_COLLECTIONS) {
                try {
                    let q = query(
                        collection(db, collName),
                        limit(200)
                    );

                    if (status !== 'all') {
                        q = query(q, where("status", "==", status));
                    }

                    const snapshot = await getDocs(q);

                    for (const document of snapshot.docs) {
                        const data = document.data();
                        const reporter = await getUserInfo(data.reporterId);
                        const reported = await getUserInfo(data.reportedUserId);

                        const createdAt = data.createdAt?.toDate ? data.createdAt.toDate() :
                            (data.createdAt instanceof FirestoreTimestamp ? data.createdAt.toDate() :
                                (data.createdAt && typeof data.createdAt.seconds === 'number' ? new Date(data.createdAt.seconds * 1000) :
                                    new Date()));

                        allReports.push({
                            id: document.id,
                            collection: collName,
                            type: collName === 'reports' ? 'User' : collName === 'message_reports' ? 'Message' : 'Story',
                            ...data,
                            reporterName: reporter.name,
                            reporterEmail: reporter.email,
                            reportedUserName: reported.name,
                            reportedUserEmail: reported.email,
                            description: data.additionalInfo || data.description || data.messageContent || (data.storyId ? `Story ID: ${data.storyId}` : ""),
                            priority: data.priority || (data.reason === 'harassment' || data.reason === 'scam' ? 'high' : 'medium'),
                            createdAt,
                            updatedAt: data.updatedAt?.toDate ? data.updatedAt.toDate() : new Date(),
                        });
                    }
                } catch (e) {
                    console.error(`Error fetching from ${collName}:`, e);
                }
            }

            // Tüm raporları tarihe göre salla
            return allReports.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime()).slice(0, limitCount);
        } catch (error) {
            console.error("Error fetching reports:", error);
            return [];
        }
    },

    // Rapor durumunu güncelle
    updateReportStatus: async (reportId: string, status: Report['status'], resolution?: string, collectionName: string = "reports") => {
        try {
            const reportRef = doc(db, collectionName, reportId);
            await updateDoc(reportRef, {
                status,
                resolution,
                resolvedAt: new Date(),
                updatedAt: new Date()
            });
            return true;
        } catch (error) {
            console.error("Error updating report:", error);
            throw error;
        }
    }
};
