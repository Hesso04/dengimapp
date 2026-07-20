import { User, Report, DashboardStats, Subscription, SupportTicket, AuditLog } from '@/types';

// Live production fallbacks - Empty defaults
export const mockDashboardStats: DashboardStats = {
    totalUsers: 0,
    activeUsers: 0,
    newUsersToday: 0,
    newUsersThisWeek: 0,
    newUsersThisMonth: 0,
    premiumUsers: 0,
    totalMatches: 0,
    totalMessages: 0,
    pendingReports: 0,
    pendingVerifications: 0,
    mrr: 0,
    arr: 0,
    churnRate: 0,
    conversionRate: 0,
};

export const mockUsers: User[] = [];
export const mockReports: Report[] = [];
export const mockSubscriptions: Subscription[] = [];
export const mockAuditLogs: AuditLog[] = [];
export const mockTickets: SupportTicket[] = [];
export const mockUserGrowthData = [];
export const mockRevenueData = [];
export const mockGenderDistribution = { male: 0, female: 0 };
export const mockAgeDistribution = { '18-24': 0, '25-34': 0, '35-44': 0, '45+': 0 };
