import { db } from "@/lib/firebase";
import { DeletionRequest } from "@/types";
import {
    collection,
    doc,
    getDocs,
    updateDoc,
    deleteDoc,
    query,
    orderBy,
} from "firebase/firestore";

export class DeletionService {
    private static COLLECTION = "deletion_requests";

    static async getRequests(): Promise<DeletionRequest[]> {
        try {
            const q = query(
                collection(db, this.COLLECTION),
                orderBy("requestedAt", "desc")
            );
            const snapshot = await getDocs(q);

            return snapshot.docs.map((docSnap) => {
                const data = docSnap.data();
                return {
                    id: docSnap.id,
                    userId: data.userId || docSnap.id,
                    userName: data.userName || data.name || "Kullanıcı",
                    userEmail: data.userEmail || data.email || "-",
                    requestedAt: data.requestedAt?.toDate ? data.requestedAt.toDate() : new Date(),
                    status: data.status || "pending",
                    reason: data.reason || "Kullanıcı isteği",
                } as DeletionRequest;
            });
        } catch (error) {
            console.error("Silme talepleri çekilirken hata:", error);
            return [];
        }
    }

    static async approveDeletion(requestId: string, userId: string): Promise<boolean> {
        try {
            // 1. Mark user as deleted in Firestore `users` collection
            if (userId) {
                const userRef = doc(db, "users", userId);
                await updateDoc(userRef, {
                    status: "deleted",
                    isDeleted: true,
                    deletedAt: new Date(),
                });
            }

            // 2. Update request status to approved
            const reqRef = doc(db, this.COLLECTION, requestId);
            await updateDoc(reqRef, {
                status: "approved",
                processedAt: new Date(),
            });

            return true;
        } catch (error) {
            console.error("Hesap silme onaylanırken hata:", error);
            return false;
        }
    }

    static async rejectDeletion(requestId: string): Promise<boolean> {
        try {
            const reqRef = doc(db, this.COLLECTION, requestId);
            await updateDoc(reqRef, {
                status: "rejected",
                processedAt: new Date(),
            });
            return true;
        } catch (error) {
            console.error("Hesap silme talebi reddedilirken hata:", error);
            return false;
        }
    }
}
