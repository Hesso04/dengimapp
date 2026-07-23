import {
    collection,
    getDocs,
    doc,
    updateDoc,
    query,
    orderBy,
    limit,
    where,
    startAfter
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

            snapshot.forEach((doc) => {
                const data = doc.data();
                const photoList = data.photoUrls || data.photos || (data.profileImageUrl ? [data.profileImageUrl] : []) || [];

                users.push({
                    id: doc.id,
                    name: data.name || data.fullName || 'İsimsiz',
                    email: data.email || '',
                    photos: photoList,
                    status: data.isBanned ? 'banned' : (data.isVerified ? 'verified' : 'active'),
                    lastActive: data.lastActive?.toDate ? data.lastActive.toDate() : new Date(),
                    isPremium: data.isPremium || false,
                    premiumTier: data.premiumTier || undefined,
                    gender: data.gender || 'male',
                    age: data.age || 18,
                    location: data.location || { city: '', country: '' },
                    isVerified: data.isVerified || false,
                    reportCount: data.reportCount || 0,
                    matchCount: data.matchCount || 0,
                    messageCount: data.messageCount || 0,
                    followersCount: data.followersCount || data.followers?.length || 0,
                    followingCount: data.followingCount || data.following?.length || 0,
                    followers: data.followers || [],
                    following: data.following || [],
                    bio: data.bio || '',
                    relationshipGoal: data.relationshipGoal || undefined,
                    createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(),
                    updatedAt: data.updatedAt?.toDate ? data.updatedAt.toDate() : new Date(),
                    phone: data.phoneNumber || data.phone || undefined,
                    interests: data.interests || [],
                } as unknown as User);
            });

            return { users, lastDoc: snapshot.docs[snapshot.docs.length - 1] };
        } catch (error) {
            console.error("Fetch Users Error:", error);
            throw error;
        }
    },

    // Onay bekleyen kullanıcıları getir
    getPendingVerifications: async () => {
        try {
            const q = query(
                collection(db, USERS_COLLECTION),
                where("isVerified", "==", false),
                limit(200)
            );
            const snapshot = await getDocs(q);
            const users: User[] = [];
            snapshot.forEach((doc) => {
                const data = doc.data();
                const photoList = data.photoUrls || data.photos || [];
                users.push({
                    id: doc.id,
                    name: data.name || 'İsimsiz',
                    photos: photoList,
                    createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(),
                    isVerified: false,
                    status: 'pending'
                } as unknown as User);
            });
            return users.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime()).slice(0, 50);
        } catch (e) {
            console.error("Pending Verifications Error:", e);
            return [];
        }
    },

    // Premium kullanıcıları getir
    getPremiumUsers: async () => {
        try {
            const q = query(
                collection(db, USERS_COLLECTION),
                where("isPremium", "==", true),
                limit(50)
            );
            const snapshot = await getDocs(q);
            const users: User[] = [];
            snapshot.forEach((doc) => {
                const data = doc.data();
                users.push({
                    id: doc.id,
                    name: data.name || 'İsimsiz',
                    premiumTier: data.premiumTier || 'basic',
                    createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(),
                    isPremium: true
                } as unknown as User);
            });
            return users;
        } catch (e) {
            console.error("Premium Users Error:", e);
            return [];
        }
    },

    // Biyografisi olan ve kontrol edilmesi gereken kullanıcıları getir
    getFlaggedBios: async () => {
        try {
            const q = query(
                collection(db, USERS_COLLECTION),
                where("bioFlagged", "==", true),
                limit(50)
            );
            const snapshot = await getDocs(q);
            const users: User[] = [];
            snapshot.forEach((doc) => {
                const data = doc.data();
                users.push({
                    id: doc.id,
                    name: data.name || 'İsimsiz',
                    bio: data.bio,
                    createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(),
                    status: data.isBanned ? 'banned' : 'active'
                } as unknown as User);
            });
            return users;
        } catch (e) {
            console.error("Flagged Bios Error:", e);
            return [];
        }
    },

    // Kullanıcı durumunu güncelle
    updateUserStatus: async (userId: string, action: 'ban' | 'verify' | 'suspend' | 'activate') => {
        try {
            const updates: any = {};
            if (action === 'ban') {
                updates.isBanned = true;
                updates.status = 'banned';
            }
            else if (action === 'verify') {
                updates.isVerified = true;
                updates.status = 'active'; // or 'verified' if you prefer
            }
            else if (action === 'suspend') {
                updates.isBanned = true;
                updates.status = 'suspended';
            }
            else if (action === 'activate') {
                updates.isBanned = false;
                updates.status = 'active';
            }

            const userRef = doc(db, USERS_COLLECTION, userId);
            await updateDoc(userRef, {
                ...updates,
                updatedAt: new Date()
            });
            return true;
        } catch (error) {
            console.error("Update User Status Error:", error);
            throw error;
        }
    },

    // Kullanıcıya VIP (Gold/Platinum) Üyelik Ver
    grantPremium: async (userId: string, tier: 'gold' | 'platinum') => {
        try {
            const userRef = doc(db, USERS_COLLECTION, userId);
            await updateDoc(userRef, {
                isPremium: true,
                premiumTier: tier,
                premiumExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // +30 gün
            });
            return true;
        } catch (error) {
            console.error("Grant Premium error:", error);
            return false;
        }
    },

    // Kullanıcıya Kredi Yükle
    addCredits: async (userId: string, amount: number) => {
        try {
            const userRef = doc(db, USERS_COLLECTION, userId);
            const userDoc = await getDoc(userRef);
            const currentCredits = userDoc.exists() ? (userDoc.data().credits || 0) : 0;
            await updateDoc(userRef, {
                credits: currentCredits + amount
            });
            return true;
        } catch (error) {
            console.error("Add Credits error:", error);
            return false;
        }
    },

    // Kullanıcı verisini güncelle (Edit için)
    updateUser: async (userId: string, data: Partial<User>) => {
        try {
            const userRef = doc(db, USERS_COLLECTION, userId);
            await updateDoc(userRef, {
                ...data as any,
                updatedAt: new Date()
            });
            return true;
        } catch (e) {
            console.error("Update User Error:", e);
            throw e;
        }
    }
};
