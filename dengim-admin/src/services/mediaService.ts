import { ref, listAll, getMetadata, getDownloadURL, deleteObject } from "firebase/storage";
import { doc, getDoc } from "firebase/firestore";
import { storage, db } from "@/lib/firebase";
import { MediaItem, StorageStats } from "@/types";

export const MediaService = {
    // Tüm medya dosyalarını tara ve getir
    getAllMedia: async (): Promise<{ items: MediaItem[]; stats: StorageStats }> => {
        try {
            const listRef = ref(storage, 'user_photos');
            const res = await listAll(listRef);

            let totalSizeBytes = 0;
            let imagesCount = 0;
            let videosCount = 0;
            let audioCount = 0;
            const items: MediaItem[] = [];

            // Klasörler (userId'ye göre)
            for (const folderRef of res.prefixes) {
                const userId = folderRef.name;
                
                // Kullanıcı bilgilerini Firestore'dan çek (Önbellek/Eşleşme)
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
                    console.warn(`User info fetch error for ${userId}:`, e);
                }

                // Klasör içindeki dosyalar
                const folderRes = await listAll(folderRef);
                for (const itemRef of folderRes.items) {
                    try {
                        const meta = await getMetadata(itemRef);
                        const downloadUrl = await getDownloadURL(itemRef);
                        const size = meta.size || 0;
                        const contentType = meta.contentType || 'image/jpeg';

                        let type: 'image' | 'video' | 'audio' | 'other' = 'image';
                        if (contentType.startsWith('video/')) {
                            type = 'video';
                            videosCount++;
                        } else if (contentType.startsWith('audio/')) {
                            type = 'audio';
                            audioCount++;
                        } else if (contentType.startsWith('image/')) {
                            type = 'image';
                            imagesCount++;
                        }

                        totalSizeBytes += size;

                        items.push({
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
                        console.error(`Item metadata error for ${itemRef.fullPath}:`, itemErr);
                    }
                }
            }

            // Yeniden eskiye sırala
            items.sort((a, b) => b.timeCreated.getTime() - a.timeCreated.getTime());

            // Boyut biçimlendirme
            const formattedSize = (totalSizeBytes / (1024 * 1024)).toFixed(2) + " MB";

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

    // Belirli bir medyayı Storage'dan sil
    deleteMedia: async (fullPath: string): Promise<boolean> => {
        try {
            const fileRef = ref(storage, fullPath);
            await deleteObject(fileRef);
            return true;
        } catch (error) {
            console.error("Delete media error:", error);
            return false;
        }
    }
};
