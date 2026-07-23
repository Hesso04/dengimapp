// User Types
export interface User {
    id: string;
    name: string;
    email: string;
    phone?: string;
    age: number;
    gender: 'male' | 'female' | 'other' | 'Erkek' | 'Kadın';
    location: {
        city: string;
        country: string;
        coordinates?: { lat: number; lng: number };
    };
    photos: string[];
    bio?: string;
    interests?: string[];
    status: 'active' | 'banned' | 'deleted' | 'pending' | 'verified' | 'suspended';
    isPremium: boolean;
    premiumTier?: 'basic' | 'gold' | 'platinum';
    premiumExpiry?: Date;
    isVerified: boolean;
    relationshipGoal?: 'serious' | 'casual' | 'chat' | 'unsure' | string;
    reportCount: number;
    matchCount: number;
    messageCount: number;
    followersCount: number;
    followingCount: number;
    followers?: string[];
    following?: string[];
    lastActive: Date;
    createdAt: Date;
    updatedAt: Date;
}

// Verification Types
export interface VerificationRequest {
    id: string;
    userId: string;
    email: string;
    selfieUrl: string;
    status: 'pending' | 'approved' | 'rejected';
    createdAt: Date;
    resolvedAt?: Date;
    rejectionReason?: string;
    userProfilePhoto?: string;
    userName?: string;
}

// Report Types
export type ReportReason =
    | 'spam'
    | 'fake_profile'
    | 'inappropriate_content'
    | 'harassment'
    | 'underage'
    | 'scam'
    | 'other';

export type ReportStatus = 'pending' | 'reviewed' | 'dismissed' | 'action_taken';

export interface Report {
    id: string;
    reporterId: string;
    reporterName: string;
    reporterEmail?: string;
    reportedUserId: string;
    reportedUserName: string;
    reportedUserEmail?: string;
    collection: string;
    type: string;
    reason: ReportReason;
    reasonDisplayName: string;
    description?: string;
    evidence?: string[];
    status: ReportStatus;
    priority: 'low' | 'medium' | 'high' | 'critical';
    assignedTo?: string;
    resolution?: string;
    createdAt: Date;
    updatedAt: Date;
    resolvedAt?: Date;
}

// Match Types
export interface Match {
    id: string;
    user1Id: string;
    user1Name: string;
    user2Id: string;
    user2Name: string;
    matchedAt: Date;
    hasConversation: boolean;
    messageCount: number;
    isActive: boolean;
}

// Subscription Types
export interface Subscription {
    id: string;
    userId: string;
    userName: string;
    plan: 'monthly' | 'quarterly' | 'yearly';
    tier: 'basic' | 'gold' | 'platinum';
    amount: number;
    currency: string;
    status: 'active' | 'cancelled' | 'expired' | 'paused';
    startDate: Date;
    endDate: Date;
    autoRenew: boolean;
    paymentMethod: string;
}

// Notification Types
export interface Notification {
    id: string;
    title: string;
    body: string;
    type: 'info' | 'warning' | 'error' | 'success';
    read: boolean;
    actionUrl?: string;
    createdAt: Date;
}

// Analytics Types
export interface DashboardStats {
    totalUsers: number;
    activeUsers: number;
    newUsersToday: number;
    newUsersThisWeek: number;
    newUsersThisMonth: number;
    premiumUsers: number;
    totalMatches: number;
    totalMessages: number;
    pendingReports: number;
    pendingVerifications: number;
    mrr: number;
    arr: number;
    churnRate: number;
    conversionRate: number;
}

export interface ChartDataPoint {
    date: string;
    value: number;
    label?: string;
}

export interface GenderDistribution {
    male: number;
    female: number;
    other: number;
}

export interface AgeDistribution {
    '18-24': number;
    '25-34': number;
    '35-44': number;
    '45-54': number;
    '55+': number;
}

// Admin Types
export interface Admin {
    id: string;
    name: string;
    email: string;
    avatar?: string;
    role: 'super_admin' | 'admin' | 'moderator' | 'support';
    permissions: string[];
    lastLogin: Date;
    createdAt: Date;
}

export interface AuditLog {
    id: string;
    adminId: string;
    adminName: string;
    action: string;
    targetType: 'user' | 'report' | 'subscription' | 'system';
    targetId?: string;
    details: string;
    ipAddress: string;
    location?: string;
    createdAt: Date;
}

// Ticket Types
export interface SupportTicket {
    id: string;
    userId: string;
    userName: string;
    userEmail: string;
    isPremium: boolean;
    subject: string;
    category: 'billing' | 'technical' | 'account' | 'report' | 'other';
    priority: 'low' | 'medium' | 'high' | 'urgent';
    status: 'open' | 'in_progress' | 'waiting' | 'resolved' | 'closed';
    messages: TicketMessage[];
    assignedTo?: string;
    createdAt: Date;
    updatedAt: Date;
    resolvedAt?: Date;
}

export interface TicketMessage {
    id: string;
    senderId: string;
    senderName: string;
    senderType: 'user' | 'admin';
    content: string;
    attachments?: string[];
    createdAt: Date;
}

// Promo Code Types
export interface PromoCode {
    id: string;
    code: string;
    discountType: 'percentage' | 'fixed';
    discountValue: number;
    maxUses: number;
    usedCount: number;
    minPurchase?: number;
    applicablePlans: string[];
    validFrom: Date;
    validUntil: Date;
    isActive: boolean;
    createdBy: string;
    createdAt: Date;
}

// API Response Types
export interface ApiResponse<T> {
    success: boolean;
    data?: T;
    error?: string;
    message?: string;
}

export interface PaginatedResponse<T> {
    items: T[];
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
}

// Filter Types
export interface UserFilters {
    search?: string;
    status?: User['status'];
    gender?: User['gender'];
    isPremium?: boolean;
    isVerified?: boolean;
    minAge?: number;
    maxAge?: number;
    city?: string;
    sortBy?: 'name' | 'createdAt' | 'lastActive' | 'reportCount';
    sortOrder?: 'asc' | 'desc';
}

export interface ReportFilters {
    status?: ReportStatus;
    reason?: ReportReason;
    priority?: Report['priority'];
    dateFrom?: Date;
    dateTo?: Date;
    assignedTo?: string;
}

// Media Browser & Storage Types
export interface MediaItem {
    id: string;
    url: string;
    fullPath: string;
    fileName: string;
    userId: string;
    userName?: string;
    userEmail?: string;
    userPhoto?: string;
    size: number;
    contentType: string;
    timeCreated: Date;
    type: 'image' | 'video' | 'audio' | 'other';
    flagged?: boolean;
}

export interface StorageStats {
    totalFiles: number;
    totalSizeBytes: number;
    formattedSize: string;
    imagesCount: number;
    videosCount: number;
    audioCount: number;
}

export interface OnlineUserStats {
    onlineNow: number;
    recentlyActive: User[];
}

