import { doc, getDoc, updateDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";

export const ConfigService = {
    getConfig: async () => {
        try {
            const docRef = doc(db, "system", "config");
            const snapshot = await getDoc(docRef);
            if (snapshot.exists()) {
                return snapshot.data();
            }
            return {
                isVipEnabled: false,
                isAdsEnabled: true,
                isCreditsEnabled: false,
                isMapEnabled: false,
                minVersion: "1.0.0",
                contactEmail: "support@dengim.app"
            };
        } catch (error) {
            console.error("Get config error:", error);
            throw error;
        }
    },

    updateConfig: async (data: any) => {
        try {
            const docRef = doc(db, "system", "config");
            await updateDoc(docRef, {
                ...data,
                updatedAt: new Date()
            });
            return true;
        } catch (error) {
            console.error("Update config error:", error);
            throw error;
        }
    }
};
