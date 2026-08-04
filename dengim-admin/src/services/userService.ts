import {
    collection,
    getDocs,
    getDoc,
    doc,
    updateDoc,
    deleteDoc,
    query,
    orderBy,
    limit,
    where,
    startAfter,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { User } from "@/types";

const USERS_COLLECTION = "users";

export const UserService = {
    // Tüm kullanıcıları getir (Pagination destekli)
    getUsers: async (lastDoc: any = null, pageSize: number = 20) => {
        try {
            let q = query(
                collection(db, USERS_COLLECTION),
                orderBy("createdAt", "desc"),
                limit(pageSize)
            );

            if (lastDoc) {
                q = query(q, startAfter(lastDoc));
            }

            const snapshot = await getDocs(q);
            const users: User[] = [];

            snapshot.forEach((docSnap) => {
                const data = docSnap.data();
                const photoList = data.photoUrls || data.photos || (data.profileImageUrl ? [data.profileImageUrl] : []) || [];
                
                // Kayıt türü tespiti
                let authProvider: 'google' | 'facebook' | 'phone' | 'email' = 'email';
                const providerStr = (data.providerId || data.authProvider || data.provider || "").toString().toLowerCase();
                const phoneStr = data.phoneNumber || data.phone;

                if (providerStr.includes("google") || data.googleId) {
                    authProvider = "google";
                } else if (providerStr.includes("facebook") || data.facebookId) {
                    authProvider = "facebook";
                } else if (phoneStr || providerStr.includes("phone")) {
                    authProvider = "phone";
                }

                users.push({
                    id: docSnap.id,
                    name: data.name || data.fullName || 'İsimsiz Kullanıcı',
                    email: data.email || '',
                    phone: phoneStr || undefined,
                    authProvider,
                    photos: photoList,
                    credits: data.credits || 0,
                    status: data.isBanned ? 'banned' : (data.status || (data.isVerified ? 'verified' : 'active')),
                    lastActive: data.lastActive?.toDate ? data.lastActive.toDate() : new Date(),
                    isPremium: data.isPremium || false,
                    premiumTier: data.premiumTier || undefined,
                    gender: data.gender || 'Erkek',
                    age: data.age || 18,
                    location: data.location || { city: 'Belirtilmedi', country: 'Türkiye' },
                    isVerified: data.isVerified || false,
                    reportCount: data.reportCount || 0,
                    matchCount: data.matchCount || 0,
                    messageCount: data.messageCount || 0,
                    followersCount: data.followersCount || 0,
                    followingCount: data.followingCount || 0,
                    bio: data.bio || '',
                    createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(),
                    updatedAt: data.updatedAt?.toDate ? data.updatedAt.toDate() : new Date(),
                    interests: data.interests || [],
                } as unknown as User);
            });

            return { users, lastDoc: snapshot.docs[snapshot.docs.length - 1] };
        } catch (error) {
            console.error("Fetch Users Error:", error);
            throw error;
        }
    },

    // Kullanıcı durumunu güncelle (Ban/Unban)
    updateUserStatus: async (userId: string, action: 'ban' | 'verify' | 'suspend' | 'activate') => {
        try {
            const userRef = doc(db, USERS_COLLECTION, userId);
            const updates: Record<string, unknown> = {
                updatedAt: new Date(),
            };

            if (action === 'ban') {
                updates.isBanned = true;
                updates.status = 'banned';
            } else if (action === 'verify') {
                updates.isVerified = true;
                updates.status = 'active';
            } else if (action === 'suspend') {
                updates.isBanned = true;
                updates.status = 'suspended';
            } else if (action === 'activate') {
                updates.isBanned = false;
                updates.status = 'active';
            }

            await updateDoc(userRef, updates);
            return true;
        } catch (error) {
            console.error("Update User Status Error:", error);
            return false;
        }
    },

    // Tekli Kullanıcı Silme (Direct Firestore Deletion)
    deleteUser: async (userId: string): Promise<boolean> => {
        try {
            const userRef = doc(db, USERS_COLLECTION, userId);
            await deleteDoc(userRef);
            return true;
        } catch (error) {
            console.error("Delete User Error:", error);
            return false;
        }
    },

    // Çoklu (Toplu) Kullanıcı Silme
    deleteUsersBatch: async (userIds: string[]): Promise<boolean> => {
        try {
            await Promise.all(userIds.map(id => deleteDoc(doc(db, USERS_COLLECTION, id))));
            return true;
        } catch (error) {
            console.error("Delete Users Batch Error:", error);
            return false;
        }
    },

    // Kullanıcıya Kredi Yükleme
    addCredits: async (userId: string, amount: number) => {
        try {
            const userRef = doc(db, USERS_COLLECTION, userId);
            const userDoc = await getDoc(userRef);
            const currentCredits = userDoc.exists() ? (userDoc.data()?.credits || 0) : 0;
            await updateDoc(userRef, {
                credits: currentCredits + amount,
                updatedAt: new Date(),
            });
            return true;
        } catch (error) {
            console.error("Add Credits error:", error);
            return false;
        }
    },

    // Kullanıcıya VIP (Gold/Platinum) Üyelik Ver
    grantPremium: async (userId: string, tier: 'gold' | 'platinum') => {
        try {
            const userRef = doc(db, USERS_COLLECTION, userId);
            await updateDoc(userRef, {
                isPremium: true,
                premiumTier: tier,
                premiumExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
                updatedAt: new Date(),
            });
            return true;
        } catch (error) {
            console.error("Grant Premium error:", error);
            return false;
        }
    },
};
