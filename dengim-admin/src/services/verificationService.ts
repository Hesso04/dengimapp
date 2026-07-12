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
    Timestamp
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { VerificationRequest } from "@/types";

const COLLECTION = "verification_requests";
const USERS_COLLECTION = "users";

export const VerificationService = {
    // Bekleyen doğrulama isteklerini getir
    getPendingRequests: async (limitCount: number = 50) => {
        try {
            const q = query(
                collection(db, COLLECTION),
                where("status", "==", "pending"),
                limit(200)
            );

            const snapshot = await getDocs(q);

            const requests: VerificationRequest[] = await Promise.all(
                snapshot.docs.map(async (d) => {
                    const data = d.data();
                    let userProfilePhoto = "";
                    let userName = "Bilinmeyen Kullanıcı";
                    try {
                        const userDoc = await getDoc(doc(db, USERS_COLLECTION, data.userId));
                        if (userDoc.exists()) {
                            const userData = userDoc.data();
                            userProfilePhoto = userData.photos?.[0] || userData.imageUrl || "";
                            userName = userData.name || "Bilinmeyen Kullanıcı";
                        }
                    } catch (err) {
                        console.error("Error fetching user profile for verification request:", err);
                    }
                    return {
                        id: d.id,
                        ...data,
                        userProfilePhoto,
                        userName,
                        createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(),
                        resolvedAt: data.resolvedAt?.toDate ? data.resolvedAt.toDate() : undefined,
                    } as unknown as VerificationRequest;
                })
            );

            return requests.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime()).slice(0, limitCount);
        } catch (error) {
            console.error("Error fetching verification requests:", error);
            return [];
        }
    },

    // İsteği onayla
    approveRequest: async (requestId: string, userId: string) => {
        try {
            // 1. İstek durumunu güncelle
            const requestRef = doc(db, COLLECTION, requestId);
            await updateDoc(requestRef, {
                status: 'approved',
                resolvedAt: Timestamp.now(),
            });

            // 2. Kullanıcıyı doğrulanmış olarak işaretle
            const userRef = doc(db, USERS_COLLECTION, userId);
            await updateDoc(userRef, {
                isVerified: true,
                updatedAt: Timestamp.now(),
            });

            return true;
        } catch (error) {
            console.error("Error approving verification:", error);
            throw error;
        }
    },

    // İsteği reddet
    rejectRequest: async (requestId: string, userId: string, reason: string) => {
        try {
            const requestRef = doc(db, COLLECTION, requestId);
            await updateDoc(requestRef, {
                status: 'rejected',
                rejectionReason: reason,
                resolvedAt: Timestamp.now(),
            });

            // Note: We don't necessarily update the user if rejected, 
            // but we could mark a 'verificationStatus' if we had one.
            return true;
        } catch (error) {
            console.error("Error rejecting verification:", error);
            throw error;
        }
    }
};
