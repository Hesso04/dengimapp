import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
    title: "Dengim - Ses Odaklı Tanışma ve Eşleşme Uygulaması",
    description: "Klasik tanışma uygulamalarını unutun. Dengim ile ses tonlarıyla kendinizi ifade edin, Agora ses odalarında canlı sohbet edin ve yapay zeka desteğiyle ruh eşinizi bulun.",
    icons: {
        icon: "/favicon.ico",
        shortcut: "/favicon.ico",
        apple: "/logo.png",
    },
    verification: {
        google: "U59EEGyEqCWisGgtZmELsFMI3OiYiVx9eDyzy4U-yBk",
    },
};

import { AuthProvider } from "@/components/layout/AuthProvider";

// ...

export default function RootLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <html lang="tr" className="dark">
            <head>
                <link rel="icon" href="/favicon.ico" sizes="any" />
                <link rel="apple-touch-icon" href="/logo.png" />
                <link
                    href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap"
                    rel="stylesheet"
                />
                <link
                    href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap"
                    rel="stylesheet"
                />
            </head>
            <body className="font-display antialiased">
                <AuthProvider>
                    {children}
                </AuthProvider>
            </body>
        </html>
    );
}
