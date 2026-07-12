import Link from 'next/link';

export default function TermsPage() {
    return (
        <div className="min-h-screen bg-background-light font-display text-zinc-900">
            <header className="fixed top-0 left-0 right-0 z-50 bg-background-light border-b-4 border-black px-6 py-4 flex items-center justify-between">
                <Link href="/" className="text-3xl font-black tracking-tight text-primary uppercase" style={{ textShadow: '2px 2px 0px #000' }}>
                    DENGIM
                </Link>
                <Link href="/" className="font-bold hover:underline underline-offset-4">Geri Dön</Link>
            </header>

            <main className="pt-32 pb-20 px-6 max-w-4xl mx-auto">
                <div className="bg-white border-4 border-black shadow-[8px_8px_0px_0px_#B2FF33] p-8 md:p-12 rounded-2xl">
                    <h1 className="text-4xl font-black uppercase mb-8 border-b-4 border-black pb-4">Kullanım Koşulları</h1>
                    
                    <div className="prose prose-zinc max-w-none prose-headings:font-black prose-headings:uppercase">
                        <h2>1. Kabul Edilme</h2>
                        <p>Dengim uygulamasını kullanarak bu kullanım koşullarını kabul etmiş sayılırsınız.</p>
                        
                        <h2>2. Kullanıcı Yükümlülükleri</h2>
                        <p>Kullanıcılar, platform üzerinde sahte hesap oluşturmamayı, yanıltıcı bilgiler vermemeyi ve diğer kullanıcılara saygı çerçevesinde davranmayı taahhüt eder.</p>

                        <h2>3. İçerik ve Moderasyon</h2>
                        <p>Dengim, platforma yüklenen tüm ses, video ve metin içeriklerini yapay zeka ve moderatörler aracılığıyla denetleme hakkını saklı tutar. Kurallara uymayan içerikler ve hesaplar kalıcı olarak silinebilir.</p>

                        <h2>4. Sorumluluk Reddi</h2>
                        <p>Dengim, kullanıcılar arasındaki iletişimden veya gerçek hayattaki buluşmalardan doğabilecek herhangi bir maddi/manevi zarardan sorumlu tutulamaz.</p>
                        
                        <p className="text-sm text-zinc-500 mt-12 font-bold">Son Güncelleme: {new Date().toLocaleDateString('tr-TR')}</p>
                    </div>
                </div>
            </main>
        </div>
    );
}
