import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "DENGIM Admin Panel",
    description: "DENGIM Dating App - Admin & VIP Management Platform",
};

export default function AdminLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return <>{children}</>;
}
