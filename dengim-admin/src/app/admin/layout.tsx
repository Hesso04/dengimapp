import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "DENGİM - Yönetim Paneli",
    description: "Dengim Dating App - Admin & VIP Yönetim Platformu",
};

export default function AdminLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return <>{children}</>;
}
