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
            if (userId) {
                // 1. Kullanıcının ana dokümanını ve ilişkili sohbet/beğenilerini sil
                const userRef = doc(db, "users", userId);
                try {
                    await deleteDoc(userRef);
                } catch (e) {
                    await updateDoc(userRef, {
                        status: "deleted",
                        isDeleted: true,
                        deletedAt: new Date(),
                    });
                }
            }

            // 2. Silme talebini onaylandı durumuna getir
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
