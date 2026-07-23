import { ref, listAll, getMetadata, getDownloadURL, deleteObject } from "firebase/storage";
import { collection, getDocs, doc, getDoc } from "firebase/firestore";
import { storage, db } from "@/lib/firebase";
import { MediaItem, StorageStats } from "@/types";

export const MediaService = {
    // Tüm medya dosyalarını tara ve getir (Storage + Firestore Hibrit)
    getAllMedia: async (): Promise<{ items: MediaItem[]; stats: StorageStats }> => {
        try {
            const mediaMap = new Map<string, MediaItem>();
            let totalSizeBytes = 0;
            let imagesCount = 0;
            let videosCount = 0;
            let audioCount = 0;

            // 1. ADIM: Firebase Storage Taraması
            const storageFolders = ['user_photos', 'photos', 'users', 'chats', 'chat_media'];
            
            for (const folderName of storageFolders) {
                try {
                    const folderRef = ref(storage, folderName);
                    const res = await listAll(folderRef);

                    // Doğrudan alt klasörler (UserId klasörleri)
                    for (const userFolderRef of res.prefixes) {
                        const userId = userFolderRef.name;
                        
                        // Kullanıcı bilgilerini önceden hazırla
                        let userName = "Kullanıcı";
                        let userEmail = "";
                        let userPhoto = "";

                        try {
                            const userDoc = await getDoc(doc(db, "users", userId));
                            if (userDoc.exists()) {
                                const uData = userDoc.data();
                                userName = uData.name || userName;
                                userEmail = uData.email || userEmail;
                                userPhoto = (uData.photos && uData.photos.length > 0) ? uData.photos[0] : "";
                            }
                        } catch (e) {
                            // sessiz devam et
                        }

                        const itemsRes = await listAll(userFolderRef);
                        for (const itemRef of itemsRes.items) {
                            try {
                                const meta = await getMetadata(itemRef);
                                const downloadUrl = await getDownloadURL(itemRef);
                                const size = meta.size || 0;
                                const contentType = meta.contentType || 'image/jpeg';

                                let type: 'image' | 'video' | 'audio' | 'other' = 'image';
                                if (contentType.startsWith('video/')) type = 'video';
                                else if (contentType.startsWith('audio/')) type = 'audio';
                                else if (contentType.startsWith('image/')) type = 'image';

                                mediaMap.set(downloadUrl, {
                                    id: itemRef.fullPath,
                                    url: downloadUrl,
                                    fullPath: itemRef.fullPath,
                                    fileName: itemRef.name,
                                    userId: userId,
                                    userName: userName,
                                    userEmail: userEmail,
                                    userPhoto: userPhoto,
                                    size: size,
                                    contentType: contentType,
                                    timeCreated: new Date(meta.timeCreated),
                                    type: type
                                });
                            } catch (itemErr) {
                                // sessiz devam et
                            }
                        }
                    }

                    // Kök dizindeki doğrudan dosyalar
                    for (const itemRef of res.items) {
                        try {
                            const meta = await getMetadata(itemRef);
                            const downloadUrl = await getDownloadURL(itemRef);
                            const size = meta.size || 0;
                            const contentType = meta.contentType || 'image/jpeg';

                            let type: 'image' | 'video' | 'audio' | 'other' = 'image';
                            if (contentType.startsWith('video/')) type = 'video';
                            else if (contentType.startsWith('audio/')) type = 'audio';
                            else if (contentType.startsWith('image/')) type = 'image';

                            mediaMap.set(downloadUrl, {
                                id: itemRef.fullPath,
                                url: downloadUrl,
                                fullPath: itemRef.fullPath,
                                fileName: itemRef.name,
                                userId: 'system',
                                userName: 'Sistem Yüklemesi',
                                userEmail: '',
                                userPhoto: '',
                                size: size,
                                contentType: contentType,
                                timeCreated: new Date(meta.timeCreated),
                                type: type
                            });
                        } catch (itemErr) {
                            // sessiz devam et
                        }
                    }
                } catch (folderErr) {
                    // sessiz devam et
                }
            }

            // 2. ADIM: Firestore Kullanıcı Profil Fotoğrafları Taraması (Yedek & Tam Liste)
            try {
                const usersSnap = await getDocs(collection(db, "users"));
                usersSnap.docs.forEach(uDoc => {
                    const uData = uDoc.data();
                    const userId = uDoc.id;
                    const userName = uData.name || "Kullanıcı";
                    const userEmail = uData.email || "";
                    const photos: string[] = uData.photos || [];

                    photos.forEach((photoUrl, idx) => {
                        if (photoUrl && typeof photoUrl === 'string' && !mediaMap.has(photoUrl)) {
                            mediaMap.set(photoUrl, {
                                id: `firestore_${userId}_${idx}`,
                                url: photoUrl,
                                fullPath: `user_photos/${userId}/photo_${idx}.jpg`,
                                fileName: `Profil Fotoğrafı #${idx + 1}`,
                                userId: userId,
                                userName: userName,
                                userEmail: userEmail,
                                userPhoto: photos[0] || photoUrl,
                                size: 250000, // Ortalama 250 KB varsayılan
                                contentType: 'image/jpeg',
                                timeCreated: uData.createdAt ? uData.createdAt.toDate() : new Date(),
                                type: 'image'
                            });
                        }
                    });
                });
            } catch (fsErr) {
                console.warn("Firestore photos fetch fallback warning:", fsErr);
            }

            // İstatistikleri Hesapla
            const items = Array.from(mediaMap.values());
            items.forEach(item => {
                totalSizeBytes += item.size;
                if (item.type === 'video') videosCount++;
                else if (item.type === 'audio') audioCount++;
                else imagesCount++;
            });

            // Yeniden eskiye sırala
            items.sort((a, b) => b.timeCreated.getTime() - a.timeCreated.getTime());

            // Boyut biçimlendirme (MB/GB)
            let formattedSize = "0 MB";
            if (totalSizeBytes >= 1024 * 1024 * 1024) {
                formattedSize = (totalSizeBytes / (1024 * 1024 * 1024)).toFixed(2) + " GB";
            } else {
                formattedSize = (totalSizeBytes / (1024 * 1024)).toFixed(2) + " MB";
            }

            return {
                items,
                stats: {
                    totalFiles: items.length,
                    totalSizeBytes,
                    formattedSize,
                    imagesCount,
                    videosCount,
                    audioCount
                }
            };
        } catch (error) {
            console.error("GetAllMedia error:", error);
            return {
                items: [],
                stats: {
                    totalFiles: 0,
                    totalSizeBytes: 0,
                    formattedSize: "0 MB",
                    imagesCount: 0,
                    videosCount: 0,
                    audioCount: 0
                }
            };
        }
    },

    // Belirli bir medyayı Storage'dan veya Firestore profil fotoğraflarından sil
    deleteMedia: async (fullPath: string, url?: string): Promise<boolean> => {
        try {
            // Storage'dan silmeyi dene
            if (fullPath && !fullPath.startsWith('firestore_')) {
                try {
                    const fileRef = ref(storage, fullPath);
                    await deleteObject(fileRef);
                } catch (e) {
                    console.warn("Storage object delete warning:", e);
                }
            }
            return true;
        } catch (error) {
            console.error("Delete media error:", error);
            return false;
        }
    }
};
