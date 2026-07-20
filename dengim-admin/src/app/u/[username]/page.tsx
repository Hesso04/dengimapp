import { UserPublicProfileClient } from './UserPublicProfileClient';

export async function generateStaticParams() {
    return [{ username: 'user' }, { username: 'demo' }];
}

interface Props {
    params: Promise<{ username: string }>;
}

export default async function UserPublicProfilePage({ params }: Props) {
    const resolvedParams = await params;
    const username = resolvedParams?.username || 'kullanici';

    return <UserPublicProfileClient username={username} />;
}
