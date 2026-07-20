'use client';

import { useState } from 'react';
import Link from 'next/link';

export default function TermsPage() {
    const [lang, setLang] = useState<'tr' | 'en'>('tr');

    const texts = {
        tr: {
            title: "Kullanım Koşulları",
            subtitle: "Dengim v1.0.4 ve Sonrası İçin Geçerlidir",
            back: "Ana Sayfaya Dön",
            lastUpdated: "Son Güncelleme",
            sections: [
                {
                    title: "1. Şartların Kabulü",
                    content: "Dengim uygulamasını indirerek, üye olarak veya kullanarak bu kullanım koşullarını, topluluk kurallarını ve sözleşmeleri kabul etmiş sayılırsınız. 18 yaşından küçüklerin uygulamayı kullanması kesinlikle yasaktır."
                },
                {
                    title: "2. Kullanıcı Yükümlülükleri ve Hesap Güvenliği",
                    content: "Kullanıcılar sahte profil oluşturmamayı, sesli ve yazılı görüşmelerde diğer kullanıcılara taciz, küfür veya hakaret içeren söylemlerde bulunmamayı taahhüt eder. Güvenli eşleşme amacıyla yapay zeka yüz doğrulama sistemini (Safe Match/Mavi Tik) manipüle etmeye çalışmak hesap kapatma sebebidir."
                },
                {
                    title: "3. Ses Odaları ve Agora İletişim Kuralları",
                    content: "Uygulama içerisindeki Agora sesli sohbet odalarında telif hakkı içeren müzikler çalmak, yasa dışı propaganda yapmak veya topluluk huzurunu bozan yayınlar gerçekleştirmek kesinlikle yasaktır. Moderatörler ve yapay zeka denetim mekanizması bu kurallara uymayan yayınları durdurma yetkisine sahiptir."
                },
                {
                    title: "4. Sorumluluk Sınırlandırması",
                    content: "Dengim, kullanıcılar arasındaki görüşmelerin içeriğinden, gerçek hayattaki buluşmalardan veya kullanıcıların bireysel beyanlarından doğabilecek hiçbir maddi ya da manevi zarardan hukuki olarak sorumlu tutulamaz."
                }
            ]
        },
        en: {
            title: "Terms of Service",
            subtitle: "Effective for Dengim v1.0.4 and above",
            back: "Back to Home",
            lastUpdated: "Last Updated",
            sections: [
                {
                    title: "1. Acceptance of Terms",
                    content: "By downloading, registering, or using Dengim, you agree to these terms of service and community guidelines. It is strictly forbidden for anyone under the age of 18 to use the application."
                },
                {
                    title: "2. User Obligations and Account Security",
                    content: "Users agree not to create fake profiles, nor to engage in harassment, profanity, or offensive language in voice or text interactions. Attempting to manipulate the AI face verification system (Safe Match/Blue Tick) is grounds for permanent ban."
                },
                {
                    title: "3. Voice Spaces and Agora Call Guidelines",
                    content: "It is strictly forbidden to play copyrighted music, stream illegal content, or disturb community peace in Agora voice spaces. Moderators and automated AI tools reserve the right to close violating spaces immediately."
                },
                {
                    title: "4. Limitation of Liability",
                    content: "Dengim cannot be held legally responsible for any direct or indirect damages, personal disputes, or offline encounters arising from user interactions on the platform."
                }
            ]
        }
    };

    const currentText = texts[lang];

    return (
        <div className="min-h-screen bg-black font-display text-zinc-100">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-black/90 backdrop-blur-xl border-b border-white/5 px-6 py-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <span className="text-2xl font-black bg-gradient-to-r from-[#FF4B55] to-[#ECB613] bg-clip-text text-transparent">DENGİM</span>
                </div>
                
                <div className="flex items-center gap-6">
                    {/* Language Switcher */}
                    <div className="flex bg-zinc-900 rounded-lg p-0.5 border border-white/5 text-xs font-bold">
                        <button 
                            onClick={() => setLang('tr')} 
                            className={`px-3 py-1.5 rounded-md transition-colors ${lang === 'tr' ? 'bg-[#FF4B55] text-black' : 'text-zinc-400 hover:text-white'}`}
                        >
                            TR
                        </button>
                        <button 
                            onClick={() => setLang('en')} 
                            className={`px-3 py-1.5 rounded-md transition-colors ${lang === 'en' ? 'bg-[#FF4B55] text-black' : 'text-zinc-400 hover:text-white'}`}
                        >
                            EN
                        </button>
                    </div>

                    <Link href="/" className="font-bold text-sm text-zinc-400 hover:text-[#FF4B55] transition-colors">{currentText.back}</Link>
                </div>
            </header>

            <main className="pt-32 pb-20 px-6 max-w-4xl mx-auto">
                <div className="bg-zinc-950 border border-white/10 p-8 md:p-12 rounded-[2rem] shadow-2xl relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-80 h-80 bg-[#ECB613]/5 blur-3xl rounded-full" />
                    
                    <h1 className="text-4xl font-black uppercase text-white mb-2 relative z-10">{currentText.title}</h1>
                    <p className="text-zinc-500 text-sm font-semibold mb-8 relative z-10">{currentText.subtitle}</p>
                    
                    <div className="space-y-8 relative z-10">
                        {currentText.sections.map((section, index) => (
                            <div key={index} className="space-y-3">
                                <h2 className="text-xl font-bold text-white border-l-2 border-[#ECB613] pl-3">{section.title}</h2>
                                <p className="text-zinc-400 leading-relaxed text-sm">{section.content}</p>
                            </div>
                        ))}
                    </div>

                    <div className="border-t border-white/5 mt-12 pt-6 text-xs text-zinc-500 font-semibold relative z-10">
                        {currentText.lastUpdated}: {new Date().toLocaleDateString(lang === 'tr' ? 'tr-TR' : 'en-US')}
                    </div>
                </div>
            </main>
        </div>
    );
}
