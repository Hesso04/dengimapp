'use client';

import {
    LineChart,
    Line,
    AreaChart,
    Area,
    BarChart,
    Bar,
    PieChart,
    Pie,
    Cell,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    Legend,
} from 'recharts';
import { cn } from '@/lib/utils';

// Custom Tooltip
const CustomTooltip = ({ active, payload, label }: { active?: boolean; payload?: unknown[]; label?: string }) => {
    if (active && payload && payload.length) {
        return (
            <div className="glass p-3 rounded-lg border border-primary/20 shadow-lg">
                <p className="text-xs text-white/60 mb-1">{label}</p>
                <p className="text-sm font-bold text-primary">
                    {(payload[0] as { value?: number })?.value?.toLocaleString()}
                </p>
            </div>
        );
    }
    return null;
};

interface AreaChartProps {
    data: { date: string; value: number }[];
    color?: string;
    height?: number;
}

export function GrowthChart({ data, color = '#ecb613', height = 256 }: AreaChartProps) {
    return (
        <ResponsiveContainer width="100%" height={height}>
            <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                <defs>
                    <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor={color} stopOpacity={0.3} />
                        <stop offset="95%" stopColor={color} stopOpacity={0} />
                    </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis
                    dataKey="date"
                    stroke="rgba(255,255,255,0.4)"
                    fontSize={11}
                    tickFormatter={(value) => {
                        if (!value) return '';
                        const dateObj = new Date(value);
                        return isNaN(dateObj.getTime())
                            ? value
                            : dateObj.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' });
                    }}
                />
                <YAxis
                    stroke="rgba(255,255,255,0.3)"
                    fontSize={10}
                    tickFormatter={(value) => value >= 1000 ? `${(value / 1000).toFixed(0)}K` : value}
                />
                <Tooltip content={<CustomTooltip />} />
                <Area
                    type="monotone"
                    dataKey="value"
                    stroke={color}
                    strokeWidth={2}
                    fillOpacity={1}
                    fill="url(#colorValue)"
                />
            </AreaChart>
        </ResponsiveContainer>
    );
}

interface DonutChartProps {
    data: { name: string; value: number; color: string }[];
    centerValue?: string;
    centerLabel?: string;
    height?: number;
}

export function DonutChart({ data, centerValue, centerLabel, height = 200 }: DonutChartProps) {
    return (
        <div className="relative">
            <ResponsiveContainer width="100%" height={height}>
                <PieChart>
                    <Pie
                        data={data}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={80}
                        paddingAngle={2}
                        dataKey="value"
                    >
                        {data.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                    </Pie>
                    <Tooltip content={<CustomTooltip />} />
                </PieChart>
            </ResponsiveContainer>
            {/* Center Text */}
            {centerValue && (
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                    {centerLabel && <p className="text-[10px] text-slate-400 uppercase tracking-widest">{centerLabel}</p>}
                    <p className="text-2xl font-bold text-white">{centerValue}</p>
                </div>
            )}
        </div>
    );
}

interface BarChartProps {
    data: { name: string; value: number }[];
    color?: string;
    height?: number;
}

export function HorizontalBarChart({ data, color = '#ecb613', height = 200 }: BarChartProps) {
    return (
        <ResponsiveContainer width="100%" height={height}>
            <BarChart data={data} layout="vertical" margin={{ top: 0, right: 20, left: 0, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" horizontal={false} />
                <XAxis
                    type="number"
                    stroke="rgba(255,255,255,0.3)"
                    fontSize={10}
                    tickFormatter={(value) => `${value}%`}
                />
                <YAxis
                    type="category"
                    dataKey="name"
                    stroke="rgba(255,255,255,0.3)"
                    fontSize={10}
                    width={60}
                />
                <Tooltip content={<CustomTooltip />} />
                <Bar dataKey="value" fill={color} radius={[0, 4, 4, 0]} />
            </BarChart>
        </ResponsiveContainer>
    );
}

interface MultiLineChartProps {
    data: { date: string; users: number; revenue: number }[];
    height?: number;
}

export function MultiLineChart({ data, height = 256 }: MultiLineChartProps) {
    return (
        <ResponsiveContainer width="100%" height={height}>
            <LineChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis
                    dataKey="date"
                    stroke="rgba(255,255,255,0.3)"
                    fontSize={10}
                    tickFormatter={(value) => new Date(value).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' })}
                />
                <YAxis stroke="rgba(255,255,255,0.3)" fontSize={10} />
                <Tooltip content={<CustomTooltip />} />
                <Legend
                    wrapperStyle={{ paddingTop: 20 }}
                    formatter={(value) => <span className="text-xs text-white/70">{value}</span>}
                />
                <Line
                    type="monotone"
                    dataKey="users"
                    name="Kullanıcılar"
                    stroke="#ecb613"
                    strokeWidth={2}
                    dot={{ r: 3, fill: '#ecb613' }}
                    activeDot={{ r: 5 }}
                />
                <Line
                    type="monotone"
                    dataKey="revenue"
                    name="Gelir"
                    stroke="#6366f1"
                    strokeWidth={2}
                    dot={{ r: 3, fill: '#6366f1' }}
                    activeDot={{ r: 5 }}
                />
            </LineChart>
        </ResponsiveContainer>
    );
}

// Chart Legend
interface ChartLegendProps {
    items: { label: string; color: string; value?: string }[];
}

export function ChartLegend({ items }: ChartLegendProps) {
    return (
        <div className="flex flex-wrap gap-4 mt-4">
            {items.map((item, i) => (
                <div key={i} className="flex items-center gap-2">
                    <span
                        className="w-3 h-3 rounded-full"
                        style={{ backgroundColor: item.color }}
                    />
                    <span className="text-xs text-white/70">{item.label}</span>
                    {item.value && <span className="text-xs font-bold text-white">{item.value}</span>}
                </div>
            ))}
        </div>
    );
}
