import { db } from "@/lib/firebase";
import { PromoCode } from "@/types";
import {
    collection,
    doc,
    getDocs,
    setDoc,
    updateDoc,
    deleteDoc,
    query,
    orderBy,
    Timestamp,
    serverTimestamp,
} from "firebase/firestore";

export class PromoService {
    private static COLLECTION = "promo_codes";

    static async getPromoCodes(): Promise<PromoCode[]> {
        try {
            const q = query(
                collection(db, this.COLLECTION),
                orderBy("createdAt", "desc")
            );
            const snapshot = await getDocs(q);

            return snapshot.docs.map((docSnap) => {
                const data = docSnap.data();
                return {
                    id: docSnap.id,
                    code: data.code || docSnap.id,
                    creditAmount: data.creditAmount || data.discountValue || 0,
                    maxUses: data.maxUses || 100,
                    usedCount: data.usedCount || (data.usedBy ? data.usedBy.length : 0),
                    usedBy: data.usedBy || [],
                    isActive: data.isActive !== false,
                    createdBy: data.createdBy || "Admin",
                    createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(),
                    expiresAt: data.expiresAt?.toDate ? data.expiresAt.toDate() : null,
                } as PromoCode;
            });
        } catch (error) {
            console.error("Promo kodları çekilirken hata:", error);
            return [];
        }
    }

    static async createPromoCode(data: {
        code: string;
        creditAmount: number;
        maxUses: number;
        expiresAt?: string;
    }): Promise<boolean> {
        try {
            const codeId = data.code.trim().toUpperCase();
            const promoRef = doc(db, this.COLLECTION, codeId);

            const payload: Record<string, unknown> = {
                code: codeId,
                creditAmount: Number(data.creditAmount),
                maxUses: Number(data.maxUses),
                usedCount: 0,
                usedBy: [],
                isActive: true,
                createdAt: serverTimestamp(),
            };

            if (data.expiresAt) {
                payload.expiresAt = Timestamp.fromDate(new Date(data.expiresAt));
            }

            await setDoc(promoRef, payload);
            return true;
        } catch (error) {
            console.error("Promo kodu oluşturulurken hata:", error);
            return false;
        }
    }

    static async toggleStatus(id: string, currentIsActive: boolean): Promise<boolean> {
        try {
            const promoRef = doc(db, this.COLLECTION, id);
            await updateDoc(promoRef, {
                isActive: !currentIsActive,
            });
            return true;
        } catch (error) {
            console.error("Promo kodu durumu değiştirilirken hata:", error);
            return false;
        }
    }

    static async deletePromoCode(id: string): Promise<boolean> {
        try {
            const promoRef = doc(db, this.COLLECTION, id);
            await deleteDoc(promoRef);
            return true;
        } catch (error) {
            console.error("Promo kodu silinirken hata:", error);
            return false;
        }
    }
}
