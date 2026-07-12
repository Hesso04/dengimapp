import Link from 'next/link';

export default function PrivacyPage() {
    return (
        <div className="min-h-screen bg-background-light font-display text-zinc-900">
            <header className="fixed top-0 left-0 right-0 z-50 bg-background-light border-b-4 border-black px-6 py-4 flex items-center justify-between">
                <Link href="/" className="text-3xl font-black tracking-tight text-primary uppercase" style={{ textShadow: '2px 2px 0px #000' }}>
                    DENGIM
                </Link>
                <Link href="/" className="font-bold hover:underline underline-offset-4">Geri Dön</Link>
            </header>

            <main className="pt-32 pb-20 px-6 max-w-4xl mx-auto">
                <div className="bg-white border-4 border-black shadow-[8px_8px_0px_0px_#38BDF8] p-8 md:p-12 rounded-2xl">
                    <h1 className="text-4xl font-black uppercase mb-8 border-b-4 border-black pb-4">Gizlilik Politikası</h1>
                    
                    <div className="prose prose-zinc max-w-none prose-headings:font-black prose-headings:uppercase">
                        <h2>1. Toplanan Veriler</h2>
                        <p>Dengim, hizmet verebilmek amacıyla adınız, e-posta adresiniz, konumunuz, profil fotoğraflarınız, ses/video kayıtlarınız ve eşleşme tercihlerinizi saklar.</p>
                        
                        <h2>2. Verilerin Kullanımı</h2>
                        <p>Toplanan kişisel verileriniz yalnızca size en uygun eşleşmeleri sunmak, uygulamanın güvenliğini sağlamak ve hizmet kalitesini artırmak amacıyla kullanılır.</p>

                        <h2>3. Veri Paylaşımı</h2>
                        <p>Kişisel verileriniz yasal zorunluluklar haricinde hiçbir şekilde üçüncü taraf reklam şirketleriyle veya kurumlarla paylaşılmaz, satılmaz.</p>

                        <h2>4. Veri Silme Hakkı</h2>
                        <p>Dilediğiniz zaman uygulama içerisindeki "Hesabı Sil" seçeneğini kullanarak tüm verilerinizin kalıcı olarak sistemlerimizden silinmesini talep edebilirsiniz.</p>
                        
                        <p className="text-sm text-zinc-500 mt-12 font-bold">Son Güncelleme: {new Date().toLocaleDateString('tr-TR')}</p>
                    </div>
                </div>
            </main>
        </div>
    );
}
