import { db } from '@/lib/firebase';
import { doc, getDoc, setDoc, Timestamp } from 'firebase/firestore';

export interface AppResources {
    privacyPolicyUrl: string;
    termsOfServiceUrl: string;
    supportEmail: string;
    whatsappNumber: string;
    instagramUrl: string;
    twitterUrl: string;
    appVersion: string;
    welcomeMessage: string;
    forceUpdate: boolean;
    maintenanceMode: boolean;
    maintenanceMessage: string;
    updatedAt?: string;
}

export const ResourceService = {
    async getResources(): Promise<AppResources> {
        const docRef = doc(db, 'system', 'resources');
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
            return docSnap.data() as AppResources;
        }

        // Default values if not exists
        return {
            privacyPolicyUrl: 'https://dengim.app/privacy',
            termsOfServiceUrl: 'https://dengim.app/terms',
            supportEmail: 'support@dengim.app',
            whatsappNumber: '+905410000000',
            instagramUrl: 'https://instagram.com/dengimapp',
            twitterUrl: 'https://twitter.com/dengimapp',
            appVersion: '1.0.0',
            welcomeMessage: 'Dengim\'e hoş geldiniz! Yeni nesil arkadaşlık deneyimi.',
            forceUpdate: false,
            maintenanceMode: false,
            maintenanceMessage: 'Şu anda bakım çalışması yapıyoruz. Lütfen daha sonra tekrar deneyin.',
        };
    },

    async updateResources(resources: AppResources) {
        const docRef = doc(db, 'system', 'resources');
        await setDoc(docRef, {
            ...resources,
            updatedAt: new Date().toISOString()
        }, { merge: true });
    }
};
