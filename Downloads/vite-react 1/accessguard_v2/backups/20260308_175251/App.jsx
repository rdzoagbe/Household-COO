import React, { useEffect, useMemo, useState, createContext, useContext } from "react";
import {
  BrowserRouter,
  Navigate,
  Route,
  Routes,
  Link,
  useLocation,
  useNavigate,
} from "react-router-dom";
import { signInWithGoogle, signOutUser, onAuthChange, sendMagicLink, completeMagicLinkSignIn, getUserProfile, completeOnboarding } from './firebase-config';
import {
  QueryClient,
  QueryClientProvider,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { useTranslation } from './translations';
import toast, { Toaster } from 'react-hot-toast';
import { differenceInDays, format, parseISO, subDays } from "date-fns";
import { AnimatePresence, motion } from "framer-motion"; // eslint-disable-line no-unused-vars
// ExecutiveDashboard and AIInsights inlined below
import {
  Shield,
  LayoutDashboard,
  Boxes,
  Users,
  GitMerge,
  Plug,
  Upload,
  UserMinus,
  Download,
  CreditCard,
  Search,
  Filter,
  Plus,
  Pencil,
  Trash2,
  AlertTriangle,
  BadgeCheck,
  BadgeX,
  RefreshCw,
  ExternalLink,
  Lock,
  Building2,
  Briefcase,
  Wrench,
  Activity,
  CalendarClock,
  Sparkles,
  Check,
  X,
  Info,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ChevronDown,
  Crown,
  Play,
  FileText,
  Star,
  Zap,
  BarChart3,
  TrendingUp,
  CheckCircle,
  Award,
  Menu,
  MessageCircle,
  GitCompare,
  FileDiff,
  ArrowLeftRight,
  TrendingDown,
  BarChart2,
  Settings,
  Target,
  PieChart,
  Bell,
  ArrowUp,
  ArrowDown,
  DollarSign,
} from "lucide-react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, LineChart, Line, CartesianGrid, PieChart as RPieChart, Pie, Cell } from 'recharts';

// ============================================================================
// GLOBAL LANGUAGE CONTEXT — single source of truth for all pages
// ============================================================================
const LanguageContext = React.createContext({ language: 'en', setLanguage: () => {} });

function LanguageProvider({ children }) {
  const [language, setLanguage] = React.useState(
    () => localStorage.getItem('language') || 'en'
  );
  const setAndPersist = React.useCallback((lang) => {
    localStorage.setItem('language', lang);
    setLanguage(lang);
  }, []);
  return (
    <LanguageContext.Provider value={{ language, setLanguage: setAndPersist }}>
      {children}
    </LanguageContext.Provider>
  );
}

function useLang() {
  return React.useContext(LanguageContext);
}
// ============================================================================


const cx = (...xs) => xs.filter(Boolean).join(" ");

// ============================================================================
// R'D LOGO - Custom Animated Logo for Roland D.
// ============================================================================
function RDLogo({ size = "md", onClick }) {
  const s = { sm: "h-9 w-9", md: "h-12 w-12", lg: "h-16 w-16" }[size] || "h-12 w-12";
  return (
    <button onClick={onClick} className={cx("relative group cursor-pointer transition-all duration-300 hover:scale-105 flex-shrink-0", s)}>
      <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-emerald-500 via-teal-600 to-blue-700 opacity-60 blur-md group-hover:opacity-90 transition-opacity duration-300" />
      <div className="relative flex items-center justify-center rounded-xl bg-gradient-to-br from-emerald-500 via-teal-600 to-blue-700 shadow-xl overflow-hidden h-full w-full border border-white/20">
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/15 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
        <svg viewBox="0 0 28 28" fill="none" style={{width:"62%",height:"62%"}} className="relative z-10">
          <path d="M14 2L4 6.5V13c0 5.5 4.3 10.6 10 12 5.7-1.4 10-6.5 10-12V6.5L14 2z" fill="white" fillOpacity="0.15" stroke="white" strokeWidth="1.5" strokeLinejoin="round"/>
          <path d="M10 14l3 3 5-6" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
    </button>
  );
}

// ============================================================================
// SCROLL TO TOP BUTTON
// ============================================================================
function ScrollToTop() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setShow(window.scrollY > 500);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  if (!show) return null;

  return (
    <button
      onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
      className="fixed bottom-8 right-8 p-4 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 rounded-full shadow-2xl transition-all z-50 hover:scale-110"
      aria-label="Scroll to top"
    >
      <ChevronUp className="w-6 h-6 text-white" />
    </button>
  );
}

function Card({ className, children }) {
  return (
    <div
      className={cx(
        "rounded-2xl border border-slate-800 bg-slate-900/60 shadow-sm",
        className
      )}
    >
      {children}
    </div>
  );
}

function CardHeader({ className, title, subtitle, right }) {
  return (
    <div className={cx("flex items-start justify-between gap-4 p-5", className)}>
      <div>
        <div className="text-lg font-semibold text-slate-100">{title}</div>
        {subtitle ? <div className="mt-1 text-sm text-slate-400">{subtitle}</div> : null}
      </div>
      {right ? <div className="shrink-0">{right}</div> : null}
    </div>
  );
}

function CardBody({ className, children }) {
  return <div className={cx("p-5 pt-0", className)}>{children}</div>;
}

function Divider() {
  return <div className="my-4 h-px bg-slate-800" />;
}

function Button({
  className,
  variant = "primary",
  size = "md",
  disabled,
  onClick,
  type = "button",
  children,
}) {
  const base =
    "inline-flex items-center justify-center gap-2 rounded-xl font-medium transition focus:outline-none focus:ring-2 focus:ring-blue-500/50 disabled:cursor-not-allowed disabled:opacity-60";
  const sizes = {
    sm: "h-9 px-3 text-sm",
    md: "h-10 px-4 text-sm",
    lg: "h-11 px-5 text-sm",
  };
  const variants = {
    primary: "bg-blue-600 text-white hover:bg-blue-500",
    secondary:
      "bg-slate-800 text-slate-100 hover:bg-slate-700 border border-slate-700",
    ghost: "bg-transparent text-slate-200 hover:bg-slate-800",
    danger: "bg-rose-600 text-white hover:bg-rose-500",
  };
  return (
    <button
      type={type}
      disabled={disabled}
      onClick={onClick}
      className={cx(base, sizes[size], variants[variant], className)}
    >
      {children}
    </button>
  );
}

function Input({ className, ...props }) {
  return (
    <input
      className={cx(
        "h-10 w-full rounded-xl border border-slate-800 bg-slate-950 px-3 text-sm text-slate-100 placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500/40",
        className
      )}
      {...props}
    />
  );
}

function Select({ className, children, ...props }) {
  return (
    <select
      className={cx(
        "h-10 w-full rounded-xl border border-slate-800 bg-slate-950 px-3 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500/40",
        className
      )}
      {...props}
    >
      {children}
    </select>
  );
}

function Textarea({ className, ...props }) {
  return (
    <textarea
      className={cx(
        "w-full rounded-xl border border-slate-800 bg-slate-950 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500/40",
        className
      )}
      {...props}
    />
  );
}

function Pill({ tone = "slate", icon: Icon, children }) {
  const tones = {
    slate: "bg-slate-800/70 text-slate-200 border-slate-700",
    blue: "bg-blue-600/15 text-blue-200 border-blue-600/30",
    green: "bg-emerald-600/15 text-emerald-200 border-emerald-600/30",
    amber: "bg-amber-500/15 text-amber-200 border-amber-500/30",
    rose: "bg-rose-600/15 text-rose-200 border-rose-600/30",
    purple: "bg-violet-600/15 text-violet-200 border-violet-600/30",
  };
  return (
    <span
      className={cx(
        "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs",
        tones[tone]
      )}
    >
      {Icon ? <Icon className="h-3.5 w-3.5" /> : null}
      {children}
    </span>
  );
}

function Modal({ open, title, subtitle, onClose, children, footer }) {
  return (
    <AnimatePresence>
      {open ? (
        <motion.div
          className="fixed inset-0 z-50 flex items-center justify-center"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <div
            className="absolute inset-0 bg-slate-950/70 backdrop-blur"
            onClick={onClose}
          />
          <motion.div
            className="relative z-10 w-[92vw] max-w-2xl"
            initial={{ y: 16, opacity: 0, scale: 0.98 }}
            animate={{ y: 0, opacity: 1, scale: 1 }}
            exit={{ y: 16, opacity: 0, scale: 0.98 }}
          >
            <Card className="overflow-hidden">
              <div className="flex items-start justify-between gap-4 border-b border-slate-800 p-5">
                <div>
                  <div className="text-lg font-semibold text-slate-100">{title}</div>
                  {subtitle ? (
                    <div className="mt-1 text-sm text-slate-400">{subtitle}</div>
                  ) : null}
                </div>
                <Button variant="ghost" size="sm" onClick={onClose}>
                  <X className="h-4 w-4" />
                  Close
                </Button>
              </div>
              <div className="p-5">{children}</div>
              {footer ? (
                <div className="border-t border-slate-800 bg-slate-950/30 p-4">
                  {footer}
                </div>
              ) : null}
            </Card>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}

function SkeletonRow({ cols = 6 }) {
  return (
    <div className="grid grid-cols-12 gap-3 py-2">
      {Array.from({ length: cols }).map((_, i) => (
        <div
          key={i}
          className={cx(
            "col-span-2 h-6 animate-pulse rounded-lg bg-slate-800/70",
            i === 0 ? "col-span-3" : ""
          )}
        />
      ))}
    </div>
  );
}

function EmptyState({ icon: Icon, title, body, action }) {
  const { language } = useLang();
  const t = useTranslation(language);
  return (
    <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-slate-800 bg-slate-950/30 p-10 text-center">
      {Icon ? (
        <div className="mb-4 rounded-2xl border border-slate-800 bg-slate-900/50 p-3">
          <Icon className="h-6 w-6 text-slate-200" />
        </div>
      ) : null}
      <div className="text-base font-semibold text-slate-100">{title}</div>
      <div className="mt-1 max-w-md text-sm text-slate-400">{body}</div>
      {action ? <div className="mt-5">{action}</div> : null}
    </div>
  );
}

const LS_KEY = "accessguard_v1";

const CATEGORIES = [
  "engineering",
  "design",
  "marketing",
  "sales",
  "finance",
  "hr",
  "operations",
  "security",
  "communication",
  "other",
];

const EMP_DEPARTMENTS = [...CATEGORIES, "executive"];

const TOOL_STATUS = ["active", "orphaned", "unused", "decommissioned"];
const CRITICALITY = ["low", "medium", "high"];
const RISK_SCORE = ["low", "medium", "high"];

const ACCESS_LEVEL = ["admin", "editor", "viewer", "billing"];
const ACCESS_STATUS = ["active", "revoked", "pending_revocation"];
const RISK_FLAG = [
  "none",
  "orphaned",
  "unused",
  "former_employee",
  "excessive_admin",
  "needs_review",
];

function uid(prefix = "id") {
  return `${prefix}_${Math.random().toString(16).slice(2)}_${Date.now()}`;
}

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

function safeParseISO(s) {
  try {
    if (!s) return null;
    return parseISO(s);
  } catch {
    return null;
  }
}

function loadDb() {
  const raw = localStorage.getItem(LS_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function saveDb(db) {
  localStorage.setItem(LS_KEY, JSON.stringify(db));
}

function seedDbIfEmpty() {
  const existing = loadDb();
  if (existing) return existing;

  const now = new Date();
  const d = (daysAgo) => format(subDays(now, daysAgo), "yyyy-MM-dd");

  const employees = [
    {
      id: uid("emp"),
      full_name: "Amina Dupont",
      email: "amina.dupont@acme.com",
      department: "security",
      role: "Security Lead",
      status: "active",
      start_date: d(420),
      end_date: "",
    },
    {
      id: uid("emp"),
      full_name: "Lucas Martin",
      email: "lucas.martin@acme.com",
      department: "engineering",
      role: "Platform Engineer",
      status: "active",
      start_date: d(210),
      end_date: "",
    },
    {
      id: uid("emp"),
      full_name: "Chloé Bernard",
      email: "chloe.bernard@acme.com",
      department: "finance",
      role: "Controller",
      status: "offboarding",
      start_date: d(680),
      end_date: d(3),
    },
    {
      id: uid("emp"),
      full_name: "Noah Petit",
      email: "noah.petit@acme.com",
      department: "marketing",
      role: "Growth Manager",
      status: "offboarded",
      start_date: d(980),
      end_date: d(35),
    },
  ];

  const tools = [
    {
      id: uid("tool"),
      name: "Slack",
      category: "communication",
      owner_email: "amina.dupont@acme.com",
      owner_name: "Amina Dupont",
      criticality: "high",
      url: "https://slack.com",
      description: "Company messaging + alerts",
      status: "active",
      last_used_date: d(1),
      cost_per_month: 240,
      risk_score: "low",
      notes: "SSO enabled",
    },
    {
      id: uid("tool"),
      name: "GitHub",
      category: "engineering",
      owner_email: "lucas.martin@acme.com",
      owner_name: "Lucas Martin",
      criticality: "high",
      url: "https://github.com",
      description: "Source control",
      status: "active",
      last_used_date: d(0),
      cost_per_month: 320,
      risk_score: "medium",
      notes: "{t('review_admin_access')} quarterly",
    },
    {
      id: uid("tool"),
      name: "Figma",
      category: "design",
      owner_email: "",
      owner_name: "",
      criticality: "medium",
      url: "https://figma.com",
      description: "Design collaboration",
      status: "orphaned",
      last_used_date: d(16),
      cost_per_month: 180,
      risk_score: "high",
      notes: "Owner missing",
    },
    {
      id: uid("tool"),
      name: "HubSpot",
      category: "sales",
      owner_email: "noah.petit@acme.com",
      owner_name: "Noah Petit",
      criticality: "medium",
      url: "https://hubspot.com",
      description: "CRM",
      status: "unused",
      last_used_date: d(120),
      cost_per_month: 600,
      risk_score: "high",
      notes: "Unused > 90 days",
    },
  ];

  const access = [
    {
      id: uid("acc"),
      tool_id: tools[0].id,
      tool_name: tools[0].name,
      employee_id: employees[0].id,
      employee_name: employees[0].full_name,
      employee_email: employees[0].email,
      access_level: "admin",
      granted_date: d(300),
      last_accessed_date: d(1),
      last_reviewed_date: d(200),
      status: "active",
      risk_flag: "needs_review",
    },
    {
      id: uid("acc"),
      tool_id: tools[1].id,
      tool_name: tools[1].name,
      employee_id: employees[1].id,
      employee_name: employees[1].full_name,
      employee_email: employees[1].email,
      access_level: "admin",
      granted_date: d(190),
      last_accessed_date: d(0),
      last_reviewed_date: d(210),
      status: "active",
      risk_flag: "excessive_admin",
    },
    {
      id: uid("acc"),
      tool_id: tools[2].id,
      tool_name: tools[2].name,
      employee_id: employees[1].id,
      employee_name: employees[1].full_name,
      employee_email: employees[1].email,
      access_level: "viewer",
      granted_date: d(60),
      last_accessed_date: d(20),
      last_reviewed_date: d(60),
      status: "active",
      risk_flag: "orphaned",
    },
    {
      id: uid("acc"),
      tool_id: tools[3].id,
      tool_name: tools[3].name,
      employee_id: employees[3].id,
      employee_name: employees[3].full_name,
      employee_email: employees[3].email,
      access_level: "admin",
      granted_date: d(400),
      last_accessed_date: d(200),
      last_reviewed_date: d(300),
      status: "active",
      risk_flag: "former_employee",
    },
    {
      id: uid("acc"),
      tool_id: tools[3].id,
      tool_name: tools[3].name,
      employee_id: employees[2].id,
      employee_name: employees[2].full_name,
      employee_email: employees[2].email,
      access_level: "billing",
      granted_date: d(120),
      last_accessed_date: d(80),
      last_reviewed_date: d(20),
      status: "active",
      risk_flag: "needs_review",
    },
  ];

  const user = {
    id: uid("usr"),
    email: "demo@accessguard.app",
    subscription_plan: "pro",
    is_authenticated: false,
    is_demo: false,
  };

  const db = { tools, employees, access, user };
  saveDb(db);
  return db;
}

function computeToolDerivedStatus(tool) {
  const ownerMissing = !tool.owner_email;
  if (tool.status === "decommissioned") return "decommissioned";
  if (ownerMissing) return "orphaned";
  const lastUsed = safeParseISO(tool.last_used_date);
  if (lastUsed) {
    const days = differenceInDays(new Date(), lastUsed);
    if (days >= 90) return "unused";
  }
  return "active";
}

function computeToolDerivedRisk(tool) {
  const status = computeToolDerivedStatus(tool);
  if (status === "orphaned") return "high";
  if (status === "unused") return "high";
  if (tool.criticality === "high" && status === "active") return "medium";
  return tool.risk_score || "low";
}

function computeAccessDerivedRiskFlag(accessRow, employeesById, toolsById) {
  const emp = employeesById[accessRow.employee_id];
  const tool = toolsById[accessRow.tool_id];

  const toolStatus = tool ? computeToolDerivedStatus(tool) : "active";
  const ownerMissing = tool ? !tool.owner_email : false;

  if (accessRow.status !== "active") return "none";
  if (emp && emp.status === "offboarded") return "former_employee";
  if (emp && emp.status === "offboarding") return "needs_review";
  if (ownerMissing) return "orphaned";
  if (toolStatus === "unused") return "unused";

  const lastReviewed = safeParseISO(accessRow.last_reviewed_date);
  if (accessRow.access_level === "admin") {
    if (!lastReviewed) return "needs_review";
    const days = differenceInDays(new Date(), lastReviewed);
    if (days >= 180) return "needs_review";
    return "excessive_admin";
  }

  if (lastReviewed) {
    const days = differenceInDays(new Date(), lastReviewed);
    if (days >= 365) return "needs_review";
  }

  return "none";
}

function buildRiskAlerts(db) {
  const employeesById = Object.fromEntries(db.employees.map((e) => [e.id, e]));

  const orphanedTools = db.tools.filter((t) => !t.owner_email);
  const formerEmployeeAccess = db.access.filter((a) => {
    const e = employeesById[a.employee_id];
    return a.status === "active" && e && e.status === "offboarded";
  });

  const adminOverdueReview = db.access.filter((a) => {
    if (a.status !== "active") return false;
    if (a.access_level !== "admin") return false;
    const lastReviewed = safeParseISO(a.last_reviewed_date);
    if (!lastReviewed) return true;
    return differenceInDays(new Date(), lastReviewed) >= 180;
  });

  const toolsUnused90 = db.tools.filter((t) => {
    const d0 = safeParseISO(t.last_used_date);
    if (!d0) return false;
    return differenceInDays(new Date(), d0) >= 90;
  });

  const alerts = [];

  if (orphanedTools.length) {
    alerts.push({
      id: "orphaned_tools",
      severity: "critical",
      title: "Orphaned tools detected",
      body: `${orphanedTools.length} tool(s) have no owner assigned.`,
      action: { label: "Review Tools", to: "/tools", icon: Boxes },
    });
  }

  if (formerEmployeeAccess.length) {
    alerts.push({
      id: "former_employee_access",
      severity: "critical",
      title: "Former employees still have access",
      body: `${formerEmployeeAccess.length} active access record(s) belong to offboarded employees.`,
      action: { label: "Offboarding", to: "/offboarding", icon: UserMinus },
    });
  }

  if (adminOverdueReview.length) {
    alerts.push({
      id: "admin_overdue_review",
      severity: "high",
      title: "Admin access overdue for review",
      body: `${adminOverdueReview.length} admin access record(s) have not been reviewed in 6+ months.`,
      action: { label: "Access Map", to: "/access", icon: GitMerge },
    });
  }

  if (toolsUnused90.length) {
    alerts.push({
      id: "tools_unused_90",
      severity: "high",
      title: "Tools unused for 90+ days",
      body: `${toolsUnused90.length} tool(s) have not been used in 90+ days.`,
      action: { label: "Audit Export", to: "/audit", icon: Download },
    });
  }

  const needsReview = db.access.filter((a) => {
    if (a.status !== "active") return false;
    const lastReviewed = safeParseISO(a.last_reviewed_date);
    if (!lastReviewed) return true;
    return differenceInDays(new Date(), lastReviewed) >= 365;
  });
  if (needsReview.length) {
    alerts.push({
      id: "needs_review",
      severity: "medium",
      title: "Access records need review",
      body: `${needsReview.length} access record(s) are due for annual review.`,
      action: { label: "Review Access", to: "/access", icon: GitMerge },
    });
  }

  const spend = db.tools.reduce((sum, t) => sum + Number(t.cost_per_month || 0), 0);
  if (spend > 1000) {
    alerts.push({
      id: "spend_watch",
      severity: "medium",
      title: "Monthly spend exceeds threshold",
      body: `Current tool spend is €${Math.round(spend)} / month.`,
      action: { label: "Tools", to: "/tools", icon: Boxes },
    });
  }

  return alerts.slice(0, 7);
}

function riskSeverityCounts(alerts) {
  const counts = { critical: 0, high: 0, medium: 0 };
  for (const a of alerts) counts[a.severity] = (counts[a.severity] || 0) + 1;
  return counts;
}


// Validation helpers
function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function validateRequired(value, fieldName) {
  if (!value || !value.trim()) {
    toast.error(`${fieldName} is required`);
    return false;
  }
  return true;
}

function useDbQuery() {
  return useQuery({
    queryKey: ["db"],
    queryFn: async () => seedDbIfEmpty(),
  });
}

function useDbMutations() {
  const qc = useQueryClient();

  const clone = (obj) => {
    if (typeof structuredClone === "function") return structuredClone(obj);
    return JSON.parse(JSON.stringify(obj));
  };

  const setDb = (updater) => {
    const cur = seedDbIfEmpty();
    const next = typeof updater === "function" ? updater(clone(cur)) : updater;
    saveDb(next);
    return next;
  };

  const invalidate = () => qc.invalidateQueries({ queryKey: ["db"] });

  const createTool = useMutation({
    mutationFn: async (tool) => {
      setDb((db) => {
        db.tools.unshift({ ...tool, id: uid("tool") });
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const updateTool = useMutation({
    mutationFn: async ({ id, patch }) => {
      setDb((db) => {
        db.tools = db.tools.map((t) => (t.id === id ? { ...t, ...patch } : t));
        const tool = db.tools.find((t) => t.id === id);
        db.access = db.access.map((a) =>
          a.tool_id === id ? { ...a, tool_name: tool?.name || a.tool_name } : a
        );
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const deleteTool = useMutation({
    mutationFn: async (id) => {
      setDb((db) => {
        db.tools = db.tools.filter((t) => t.id !== id);
        db.access = db.access.filter((a) => a.tool_id !== id);
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const createEmployee = useMutation({
    mutationFn: async (emp) => {
      setDb((db) => {
        db.employees.unshift({ ...emp, id: uid("emp") });
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const updateEmployee = useMutation({
    mutationFn: async ({ id, patch }) => {
      setDb((db) => {
        const before = db.employees.find((e) => e.id === id);
        const oldEmail = (before?.email || "").toLowerCase();

        db.employees = db.employees.map((e) => (e.id === id ? { ...e, ...patch } : e));
        const after = db.employees.find((e) => e.id === id);
        const newEmail = (after?.email || "").toLowerCase();

        db.access = db.access.map((a) => {
          if (a.employee_id !== id) return a;
          return {
            ...a,
            employee_name: after?.full_name || a.employee_name,
            employee_email: after?.email || a.employee_email,
          };
        });

        if (oldEmail && newEmail && oldEmail !== newEmail) {
          db.tools = db.tools.map((t) =>
            (t.owner_email || "").toLowerCase() === oldEmail
              ? { ...t, owner_email: after.email, owner_name: after.full_name || t.owner_name }
              : t
          );
        } else if (newEmail) {
          db.tools = db.tools.map((t) =>
            (t.owner_email || "").toLowerCase() === newEmail
              ? { ...t, owner_name: after?.full_name || t.owner_name }
              : t
          );
        }

        return db;
      });
    },
    onSuccess: invalidate,
  });

  const deleteEmployee = useMutation({
    mutationFn: async (id) => {
      setDb((db) => {
        const emp = db.employees.find((e) => e.id === id);
        const email = (emp?.email || "").toLowerCase();
        db.employees = db.employees.filter((e) => e.id !== id);
        db.access = db.access.filter((a) => a.employee_id !== id);
        if (email) {
          db.tools = db.tools.map((t) =>
            (t.owner_email || "").toLowerCase() === email
              ? { ...t, owner_email: "", owner_name: "", status: "orphaned" }
              : t
          );
        }
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const createAccess = useMutation({
    mutationFn: async (row) => {
      setDb((db) => {
        db.access.unshift({ ...row, id: uid("acc") });
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const updateAccess = useMutation({
    mutationFn: async ({ id, patch }) => {
      setDb((db) => {
        db.access = db.access.map((a) => (a.id === id ? { ...a, ...patch } : a));
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const deleteAccess = useMutation({
    mutationFn: async (id) => {
      setDb((db) => {
        db.access = db.access.filter((a) => a.id !== id);
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const setPlan = useMutation({
    mutationFn: async (subscription_plan) => {
      setDb((db) => {
        db.user.subscription_plan = subscription_plan;
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const setAuth = useMutation({
    mutationFn: async (patch) => {
      setDb((db) => {
        db.user = { ...db.user, ...patch };
        return db;
      });
    },
    onSuccess: invalidate,
  });

  const bulkImport = useMutation({
    mutationFn: async ({ kind, records }) => {
      setDb((db) => {
        if (kind === "tools") {
          db.tools = [
            ...records.map((r) => ({
              id: uid("tool"),
              name: r.name || "",
              category: r.category || "other",
              owner_email: r.owner_email || "",
              owner_name: r.owner_name || "",
              criticality: r.criticality || "medium",
              url: r.url || "",
              description: r.description || "",
              status: r.status || "active",
              last_used_date: r.last_used_date || "",
              cost_per_month: Number(r.cost_per_month || 0),
              risk_score: r.risk_score || "low",
              notes: r.notes || "",
            })),
            ...db.tools,
          ];
        }

        if (kind === "employees") {
          db.employees = [
            ...records.map((r) => ({
              id: uid("emp"),
              full_name: r.full_name || "",
              email: r.email || "",
              department: r.department || "other",
              role: r.role || "",
              status: r.status || "active",
              start_date: r.start_date || "",
              end_date: r.end_date || "",
            })),
            ...db.employees,
          ];
        }

        if (kind === "access") {
          const toolsByName = Object.fromEntries(db.tools.map((t) => [t.name.toLowerCase(), t]));
          const empByEmail = Object.fromEntries(db.employees.map((e) => [e.email.toLowerCase(), e]));
          db.access = [
            ...records
              .map((r) => {
                const tool = toolsByName[(r.tool_name || "").toLowerCase()];
                const emp = empByEmail[(r.employee_email || "").toLowerCase()];
                if (!tool || !emp) return null;
                return {
                  id: uid("acc"),
                  tool_id: tool.id,
                  tool_name: tool.name,
                  employee_id: emp.id,
                  employee_name: emp.full_name,
                  employee_email: emp.email,
                  access_level: r.access_level || "viewer",
                  granted_date: r.granted_date || "",
                  last_accessed_date: r.last_accessed_date || "",
                  last_reviewed_date: r.last_reviewed_date || "",
                  status: r.status || "active",
                  risk_flag: r.risk_flag || "none",
                };
              })
              .filter(Boolean),
            ...db.access,
          ];
        }

        return db;
      });
    },
    onSuccess: invalidate,
  });

  return {
    createTool,
    updateTool,
    deleteTool,
    createEmployee,
    updateEmployee,
    deleteEmployee,
    createAccess,
    updateAccess,
    deleteAccess,
    setPlan,
    setAuth,
    bulkImport,
  };
}

function useAuth() {
  const qc = useQueryClient();
  const { data: db } = useDbQuery();
  const [firebaseUser, setFirebaseUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Listen to Firebase auth state
  useEffect(() => {
    const unsubscribe = onAuthChange((fbUser) => {
      setFirebaseUser(fbUser);
      setLoading(false);
      
      // Sync Firebase user to local DB
      if (fbUser) {
        const cur = seedDbIfEmpty();
        cur.user = {
          is_authenticated: true,
          is_demo: false,
          email: fbUser.email,
          displayName: fbUser.displayName,
          photoURL: fbUser.photoURL,
          uid: fbUser.uid
        };
        saveDb(cur);
        qc.invalidateQueries({ queryKey: ["db"] });
      }
    });
    return unsubscribe;
  }, [qc]);

  const user = db?.user || null;
  const isAuthed = Boolean(user?.is_authenticated);
  const isDemo = Boolean(user?.is_demo);

  const setUser = (patch) => {
    const cur = seedDbIfEmpty();
    cur.user = { ...cur.user, ...patch };
    saveDb(cur);
    qc.invalidateQueries({ queryKey: ["db"] });
  };

  const login = async () => {
    const { user: fbUser, error } = await signInWithGoogle();
    if (error) {
      alert('Sign in failed: ' + error);
      return null;
    }
    // Firebase auth will trigger the useEffect above
    return fbUser;
  };

  const logout = async () => {
    await signOutUser();
    setUser({ is_authenticated: false, is_demo: false });
  };

  const startDemo = () => setUser({ is_demo: true, is_authenticated: false });
  const endDemo = () => setUser({ is_demo: false });

  return { user, isAuthed, isDemo, login, logout, startDemo, endDemo, firebaseUser, loading };
}

function RequireAuth({ children }) {
  const { language } = useLang();
  const t = useTranslation(language);
  const { isAuthed, isDemo, loading } = useAuth();
  const location = useLocation();
  
  // Wait for auth to load before redirecting
  if (loading) return <div className="flex items-center justify-center h-screen"><div className="text-white">{t('loading')}</div></div>;
  
  if (!isAuthed && !isDemo) return <Navigate to="/" replace state={{ from: location }} />;
  return children;
}

function CategoryIcon({ category }) {
  const map = {
    engineering: Wrench,
    design: Sparkles,
    marketing: Activity,
    sales: Briefcase,
    finance: CreditCard,
    hr: Users,
    operations: Building2,
    security: Lock,
    communication: ExternalLink,
    other: Boxes,
  };
  const Icon = map[category] || Boxes;
  return (
    <div className="flex h-9 w-9 items-center justify-center rounded-2xl border border-slate-800 bg-slate-950/40">
      <Icon className="h-4 w-4 text-slate-200" />
    </div>
  );
}

function StatusBadge({ status }) {
  const m = {
    active: { tone: "green", icon: BadgeCheck, label: "Active" },
    orphaned: { tone: "rose", icon: AlertTriangle, label: "Orphaned" },
    unused: { tone: "amber", icon: CalendarClock, label: "Unused" },
    decommissioned: { tone: "slate", icon: BadgeX, label: "Decommissioned" },
    revoked: { tone: "slate", icon: BadgeX, label: "Revoked" },
    pending_revocation: { tone: "amber", icon: RefreshCw, label: "Pending" },
    offboarding: { tone: "amber", icon: RefreshCw, label: "Offboarding" },
    offboarded: { tone: "slate", icon: BadgeX, label: "Offboarded" },
  };
  const v = m[status] || { tone: "slate", icon: Info, label: String(status || "-") };
  return (
    <Pill tone={v.tone} icon={v.icon}>
      {v.label}
    </Pill>
  );
}

function RiskBadge({ risk }) {
  const m = {
    low: { tone: "green", icon: BadgeCheck, label: "Low" },
    medium: { tone: "amber", icon: AlertTriangle, label: "Medium" },
    high: { tone: "rose", icon: AlertTriangle, label: "High" },
    critical: { tone: "rose", icon: AlertTriangle, label: "Critical" },
  };
  const v = m[risk] || { tone: "slate", icon: Info, label: String(risk || "-") };
  return (
    <Pill tone={v.tone} icon={v.icon}>
      {v.label}
    </Pill>
  );
}

function AccessLevelBadge({ level }) {
  const m = {
    admin: { tone: "rose", icon: Lock, label: "Admin" },
    editor: { tone: "blue", icon: Pencil, label: "Editor" },
    viewer: { tone: "slate", icon: BadgeCheck, label: "Viewer" },
    billing: { tone: "purple", icon: CreditCard, label: "Billing" },
  };
  const v = m[level] || { tone: "slate", icon: Info, label: String(level || "-") };
  return (
    <Pill tone={v.tone} icon={v.icon}>
      {v.label}
    </Pill>
  );
}

function RiskFlagBadge({ flag }) {
  const m = {
    none: { tone: "green", icon: BadgeCheck, label: "OK" },
    orphaned: { tone: "rose", icon: AlertTriangle, label: "Orphaned tool" },
    unused: { tone: "amber", icon: CalendarClock, label: "Unused tool" },
    former_employee: { tone: "rose", icon: UserMinus, label: "Former employee" },
    excessive_admin: { tone: "amber", icon: Lock, label: "Admin" },
    needs_review: { tone: "blue", icon: RefreshCw, label: "Needs review" },
  };
  const v = m[flag] || { tone: "slate", icon: Info, label: String(flag || "-") };
  return (
    <Pill tone={v.tone} icon={v.icon}>
      {v.label}
    </Pill>
  );
}

// NAV uses translation keys — labels resolved in Sidebar/AppShell with t()
const NAV = [
  { to: "/dashboard",    tKey: "nav_dashboard",    icon: LayoutDashboard },
  { separator: true,     tKey: "nav_access_identity" },
  { to: "/tools",        tKey: "nav_tools",         icon: Boxes },
  { to: "/employees",    tKey: "nav_employees",      icon: Users },
  { to: "/access",       tKey: "nav_access",         icon: GitMerge },
  { to: "/offboarding",  tKey: "nav_offboarding",    icon: UserMinus },
  { separator: true,     tKey: "nav_security" },
  { to: "/security",     tKey: "nav_security",       icon: Shield },
  { separator: true,     tKey: "nav_finance_section" },
  { to: "/finance",      tKey: "nav_finance",        icon: BarChart3 },
  { to: "/licenses",     tKey: "nav_licenses",       icon: Award },
  { to: "/contracts",    tKey: "nav_contracts",      icon: CalendarClock },
  { separator: true,     tKey: "nav_platform" },
  { to: "/integrations", tKey: "nav_integrations",   icon: Plug },
  { to: "/billing",      tKey: "nav_billing",        icon: CreditCard },
  { to: "/settings",     tKey: "nav_settings",       icon: Settings },
];

function Sidebar({ collapsed, setCollapsed }) {
  const location = useLocation();
  const { language } = useLang();
  const t = useTranslation(language);

  
  
  return (
    <div
      className={cx(
        "sticky top-0 flex h-screen shrink-0 flex-col border-r border-slate-800 bg-slate-950/60 backdrop-blur",
        collapsed ? "w-[78px]" : "w-[270px]"
      )}
    >
      <div className="flex items-center justify-between gap-2 p-4">
        <Link to="/dashboard" className="flex items-center gap-2">
          <RDLogo size="sm" onClick={() => window.location.href = "/dashboard"} />
          {!collapsed ? (
            <div>
              <div className="text-sm font-black tracking-tight bg-gradient-to-r from-emerald-400 to-teal-400 bg-clip-text text-transparent">SaasGuard</div>
              <div className="flex items-center gap-1.5">
                <div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>
                <div className="flex items-center gap-1">
                  <div className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />
                  <span className="text-[9px] text-emerald-500 font-bold uppercase">Live</span>
                </div>
              </div>
            </div>
          ) : null}
        </Link>
        <Button variant="ghost" size="sm" onClick={() => setCollapsed((v) => !v)}>
          <Filter className="h-4 w-4" />
          {!collapsed ? t('collapse') : null}
        </Button>
      </div>

      <div className="px-3 pb-3">
        <div className="rounded-2xl border border-slate-800 bg-slate-900/40 p-3">
          <div className="flex items-center gap-2">
            <div className="h-2.5 w-2.5 rounded-full bg-emerald-400" />
            {!collapsed ? <div className="text-xs text-slate-300">{t('live_risk_checks')}</div> : null}
          </div>
          {!collapsed ? (
            <div className="mt-2 text-xs text-slate-500">Real-time invalidation via React Query.</div>
          ) : null}
        </div>
      </div>

      <nav className="flex-1 overflow-auto px-2 pb-6">
        {NAV.map((item, idx) => {
          if (item.separator) {
            return (
              <div key={`sep-${idx}`} className="my-4 px-3">
                {!collapsed && (
                  <div className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    {t(item.tKey)}
                  </div>
                )}
                {!collapsed && <div className="mt-2 h-px bg-slate-800" />}
              </div>
            );
          }
          
          const active = location.pathname.startsWith(item.to);
          const Icon = item.icon;
          return (
            <Link
              key={item.to}
              to={item.to}
              className={cx(
                "mb-1 flex items-center gap-3 rounded-2xl px-3 py-2.5 text-sm transition",
                active
                  ? "bg-blue-600/15 text-blue-200 border border-blue-600/30"
                  : "text-slate-300 hover:bg-slate-900/60"
              )}
            >
              <Icon className="h-4 w-4" />
              {!collapsed ? <span>{t(item.tKey)}</span> : null}
            </Link>
          );
        })}
      </nav>

      <SidebarFooter collapsed={collapsed} />
    </div>
  );
}

function SidebarFooter({ collapsed }) {
  const { user, logout, isDemo, endDemo, firebaseUser } = useAuth();
  const [userProfile, setUserProfile] = useState(null);
  const { language, setLanguage } = useLang();
  const [showLangMenu, setShowLangMenu] = useState(false);

  const languages = [
    { code: 'en', flag: '🇺🇸', name: 'English' },
    { code: 'fr', flag: '🇫🇷', name: 'Français' },
    { code: 'es', flag: '🇪🇸', name: 'Español' },
    { code: 'de', flag: '🇩🇪', name: 'Deutsch' },
    { code: 'ja', flag: '🇯🇵', name: '日本語' },
  ];

  const currentLang = languages.find(l => l.code === language) || languages[0];


  const changeLanguage = (code) => {
    localStorage.setItem('language', code);  // Save BEFORE reload
    localStorage.setItem('language', code);  // Save before reload
    setLanguage(code);
    setShowLangMenu(false);
    window.location.reload();
  };

  // Load user profile from Firestore
  useEffect(() => {
    const loadProfile = async () => {
      if (firebaseUser) {
        const { user: profile } = await getUserProfile(firebaseUser.uid);
        setUserProfile(profile);
      }
    };
    loadProfile();
  }, [firebaseUser]);

  const displayName = userProfile?.fullName || firebaseUser?.displayName || user?.email?.split('@')[0] || 'Demo User';
  const photoURL = firebaseUser?.photoURL;
  const companyName = userProfile?.companyName;
  const jobTitle = userProfile?.jobTitle;

  return (
    <div className="border-t border-slate-800 p-3">
      <div
        className={cx(
          "flex items-center gap-3 rounded-2xl bg-slate-900/40 p-3",
          collapsed ? "justify-center" : ""
        )}
      >
        {/* User Photo or Avatar */}
        <div className="flex h-9 w-9 items-center justify-center rounded-full border border-slate-700 bg-slate-950/30 overflow-hidden">
          {photoURL ? (
            <img src={photoURL} alt={displayName} className="w-full h-full object-cover" />
          ) : (
            <Users className="h-4 w-4 text-slate-200" />
          )}
        </div>
        {!collapsed ? (
          <div className="min-w-0 flex-1">
            <div className="truncate text-xs font-medium text-slate-100">{displayName}</div>
            <div className="mt-0.5 text-xs text-slate-500">
              {jobTitle && companyName ? (
                <span className="text-slate-400">{jobTitle} at {companyName}</span>
              ) : (
                <>
                  <span className="text-slate-300">{user?.email || "demo"}</span>
                  {isDemo && <span className="ml-2 text-blue-300">· DEMO</span>}
                </>
              )}
            </div>
          </div>
        ) : null}
      </div>
      
      {/* Language Selector */}
      {!collapsed && (
        <div className="mt-3 relative">
          <button
            onClick={() => setShowLangMenu(!showLangMenu)}
            className="w-full px-3 py-2 bg-slate-800/50 hover:bg-slate-800 rounded-lg flex items-center justify-between transition-colors"
          >
            <div className="flex items-center gap-2">
              <span className="text-xl">{currentLang.flag}</span>
              <span className="text-sm text-slate-300">{currentLang.name}</span>
            </div>
            <ChevronDown className={`w-4 h-4 text-slate-400 transition-transform ${showLangMenu ? 'rotate-180' : ''}`} />
          </button>
          
          {showLangMenu && (
            <div className="absolute bottom-full left-0 right-0 mb-2 bg-slate-900 border border-slate-700 rounded-lg shadow-2xl overflow-hidden z-50">
              {languages.map(lang => (
                <button
                  key={lang.code}
                  onClick={() => changeLanguage(lang.code)}
                  className={`w-full px-3 py-2 flex items-center gap-2 hover:bg-slate-800 transition-colors ${
                    language === lang.code ? 'bg-blue-600/20' : ''
                  }`}
                >
                  <span className="text-xl">{lang.flag}</span>
                  <span className="text-sm text-white">{lang.name}</span>
                  {language === lang.code && <CheckCircle className="w-4 h-4 text-blue-400 ml-auto" />}
                </button>
              ))}
            </div>
          )}
        </div>
      )}
      
      {!collapsed ? (
        <div className="mt-3 flex gap-2">
          <Button
            variant="secondary"
            className="w-full"
            onClick={() => {
              if (isDemo) endDemo();
              logout();
            }}
          >
            <BadgeX className="h-4 w-4" />
            {isDemo ? "Exit Demo" : "Logout"}
          </Button>
          <Link to="/" className="w-full">
            <Button variant="ghost" className="w-full">
              <ExternalLink className="h-4 w-4" />
              Trial
            </Button>
          </Link>
        </div>
      ) : null}
    </div>
  );
}

function TopBar({ title, right }) {
  const userInfo = JSON.parse(localStorage.getItem('user_info') || '{}');
  const userName = userInfo.fullName || 'Demo User';
  
  return (
    <div className="flex items-center justify-between gap-4 border-b border-slate-800 bg-slate-950/30 p-5">
      <div>
        <div className="text-xl font-semibold text-slate-100">{title}</div>
        <div className="mt-1 text-sm text-slate-500">Keep ownership clean. Reduce security drift.</div>
      </div>
      <div className="flex items-center gap-3">
        <div className="hidden sm:flex items-center gap-2 text-sm text-slate-300">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-600/20 text-blue-300 font-medium">
            {userName.charAt(0).toUpperCase()}
          </div>
          <span>{userName}</span>
        </div>
        {right ? <div className="flex items-center gap-2">{right}</div> : null}
      </div>
    </div>
  );
}

function AppShell({ title, right, children }) {
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const { language } = useLang();
  const t = useTranslation(language);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <div className="pointer-events-none fixed inset-0 -z-10 bg-[radial-gradient(circle_at_top,rgba(59,130,246,0.18),transparent_52%),radial-gradient(circle_at_bottom,rgba(99,102,241,0.10),transparent_55%)]" />
      <div className="flex">
        <div className="hidden md:block">
          <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
        </div>

        <div className="md:hidden">
          <div className="sticky top-0 z-40 flex items-center justify-between border-b border-slate-800 bg-slate-950/80 p-3 backdrop-blur">
            <Button variant="secondary" onClick={() => setMobileOpen(true)}>
              <Filter className="h-4 w-4" />
              Menu
            </Button>
            <Link to="/dashboard" className="flex items-center gap-2">
              <div className="flex h-9 w-9 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-blue-400">
                <Shield className="h-5 w-5 text-white" />
              </div>
              <div className="text-sm font-semibold">SaasGuard</div>
            </Link>
            <div className="w-[86px]" />
          </div>
          <Modal
            open={mobileOpen}
            title={t('navigation')}
            subtitle={t('jump_to')}
            onClose={() => setMobileOpen(false)}
            footer={
              <div className="flex justify-end">
                <Button variant="secondary" onClick={() => setMobileOpen(false)}>
                  Done
                </Button>
              </div>
            }
          >
            <div className="grid gap-2">
              {NAV.filter(n => !n.separator && n.icon).map((n) => (
                <Link
                  key={n.to}
                  to={n.to}
                  onClick={() => setMobileOpen(false)}
                  className="flex items-center gap-3 rounded-2xl border border-slate-800 bg-slate-950/30 p-3 text-sm hover:bg-slate-900/60"
                >
                  <n.icon className="h-4 w-4" />
                  {t(n.tKey)}
                </Link>
              ))}
            </div>
          </Modal>
        </div>

        <main className="min-w-0 flex-1">
          <TopBar title={title} right={right} />
          <div className="p-5">{children}</div>
        </main>
      </div>
    </div>
  );
}

function formatMoney(n) {
  const v = Number(n || 0);
  if (!Number.isFinite(v)) return "€0";
  return `€${Math.round(v)}`;
}

function downloadText(filename, text) {
  const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function toCsv(rows, columns) {
  const esc = (v) => {
    const s = String(v ?? "");
    if (/[",\n]/.test(s)) return `"${s.replaceAll('"', '""')}"`;
    return s;
  };
  const header = columns.map((c) => esc(c)).join(",");
  const body = rows
    .map((r) => columns.map((c) => esc(r[c])).join(","))
    .join("\n");
  return `${header}\n${body}\n`;
}

function parseCsv(text) {
  const lines = text.split(/\r?\n/).filter((l) => l.trim().length);
  if (!lines.length) return [];
  const headers = splitCsvLine(lines[0]).map((h) => h.trim());
  return lines.slice(1).map((line) => {
    const vals = splitCsvLine(line);
    const obj = {};
    for (let i = 0; i < headers.length; i++) obj[headers[i]] = vals[i] ?? "";
    return obj;
  });
}

function splitCsvLine(line) {
  const out = [];
  let cur = "";
  let inQ = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQ && line[i + 1] === '"') {
        cur += '"';
        i++;
      } else {
        inQ = !inQ;
      }
      continue;
    }
    if (ch === "," && !inQ) {
      out.push(cur);
      cur = "";
      continue;
    }
    cur += ch;
  }
  out.push(cur);
  return out;
}

function LiveStat({ label, value }) {
  return (
    <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
      <div className="text-xs font-semibold text-slate-400">{label}</div>
      <motion.div
        className="mt-1 text-xl sm:text-2xl font-semibold"
        initial={{ opacity: 0, y: 6 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.35 }}
      >
        {Number(value || 0).toLocaleString()}
        <span className="text-sm font-normal text-slate-500">+</span>
      </motion.div>
    </div>
  );
}

function MiniStat({ label, value, tone = "blue" }) {
  const tones = {
    blue: "border-blue-600/30 bg-blue-600/10",
    amber: "border-amber-500/30 bg-amber-500/10",
    rose: "border-rose-600/30 bg-rose-600/10",
    slate: "border-slate-800 bg-slate-950/30",
  };
  return (
    <div className={cx("rounded-2xl border p-4", tones[tone] || tones.slate)}>
      <div className="text-xs font-semibold text-slate-400">{label}</div>
      <div className="mt-1 text-xl sm:text-2xl font-semibold">{value}</div>
    </div>
  );
}

function ProgressRow({ label, value }) {
  return (
    <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
      <div className="flex items-center justify-between">
        <div className="text-sm font-semibold text-slate-100">{label}</div>
        <div className="text-xs text-slate-400">{value}%</div>
      </div>
      <div className="mt-3 h-2 rounded-full bg-slate-800">
        <div
          className="h-2 rounded-full bg-blue-600"
          style={{ width: `${Math.max(0, Math.min(100, value))}%` }}
        />
      </div>
    </div>
  );
}

function DataTable({ columns, rows, rowKey, emptyIcon, emptyTitle, emptyBody }) {
  if (!rows.length) {
    return <EmptyState icon={emptyIcon} title={emptyTitle} body={emptyBody} />;
  }
  return (
    <div className="overflow-hidden rounded-2xl border border-slate-800">
      <div className="grid grid-cols-12 gap-3 border-b border-slate-800 bg-slate-950/30 px-4 py-3 text-xs font-semibold text-slate-400">
        {columns.map((c) => (
          <div key={c.key} className={c.className}>
            {c.header}
          </div>
        ))}
      </div>
      <div className="divide-y divide-slate-800">
        {rows.map((r) => (
          <div key={rowKey(r)} className="grid grid-cols-12 gap-3 px-4 py-3 text-sm">
            {columns.map((c) => (
              <div key={c.key} className={cx("min-w-0", c.className)}>
                {c.cell(r)}
              </div>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}

// ============================================================================
// ROI CALCULATOR COMPONENT
// ============================================================================
function ROICalculator() {
  const [tools, setTools] = useState(50);
  const [costPerTool, setCostPerTool] = useState(100);
  const [employees, setEmployees] = useState(200);
  
  // Calculate savings
  const totalSpend = tools * costPerTool * 12;
  const wastePercentage = 30;
  const potentialSavings = Math.round(totalSpend * (wastePercentage / 100));
  const unusedLicenses = Math.round(employees * 0.15); // 15% waste average
  const licenseSavings = unusedLicenses * 50 * 12; // $50/license/month average
  
  return (
    <div className="space-y-8">
      {/* Input Sliders */}
      <div className="grid md:grid-cols-3 gap-6">
        <div>
          <label className="block text-sm font-semibold text-slate-300 mb-3">
            Number of SaaS Tools
          </label>
          <input
            type="range"
            min="10"
            max="200"
            value={tools}
            onChange={(e) => setTools(parseInt(e.target.value))}
            className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-emerald-500"
          />
          <div className="mt-2 text-center text-3xl font-bold text-white">{tools}</div>
        </div>
        
        <div>
          <label className="block text-sm font-semibold text-slate-300 mb-3">
            Avg Cost Per Tool/Month
          </label>
          <input
            type="range"
            min="20"
            max="500"
            step="10"
            value={costPerTool}
            onChange={(e) => setCostPerTool(parseInt(e.target.value))}
            className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-emerald-500"
          />
          <div className="mt-2 text-center text-3xl font-bold text-white">${costPerTool}</div>
        </div>
        
        <div>
          <label className="block text-sm font-semibold text-slate-300 mb-3">
            Number of Employees
          </label>
          <input
            type="range"
            min="10"
            max="1000"
            step="10"
            value={employees}
            onChange={(e) => setEmployees(parseInt(e.target.value))}
            className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-emerald-500"
          />
          <div className="mt-2 text-center text-3xl font-bold text-white">{employees}</div>
        </div>
      </div>
      
      {/* Results */}
      <div className="rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-500/20 to-blue-500/20 p-8">
        <div className="grid md:grid-cols-2 gap-8">
          <div>
            <div className="text-sm font-semibold text-emerald-400 uppercase tracking-wider mb-2">
              Your Annual SaaS Spend
            </div>
            <div className="text-4xl font-black text-white mb-4">
              ${totalSpend.toLocaleString()}
            </div>
          </div>
          
          <div>
            <div className="text-sm font-semibold text-emerald-400 uppercase tracking-wider mb-2">
              Potential Savings with SaasGuard
            </div>
            <div className="text-5xl font-black text-emerald-400 mb-2">
              ${potentialSavings.toLocaleString()}/year
            </div>
            <div className="text-sm text-slate-400">
              ≈ {unusedLicenses} unused licenses • {wastePercentage}% waste reduction
            </div>
          </div>
        </div>
        
        <div className="mt-8 pt-6 border-t border-white/10">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="text-slate-300">
              💰 <span className="font-semibold">ROI in first 90 days</span> with our average customer
            </div>
            <button 
              onClick={() => {
                const trialBtn = document.querySelector('[data-start-trial]');
                if (trialBtn) trialBtn.click();
              }}
              className="px-8 py-4 bg-gradient-to-r from-emerald-600 to-blue-600 hover:from-emerald-500 hover:to-blue-500 rounded-xl font-bold text-lg transition-all hover:scale-105"
            >
              Start Free Trial →
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// TRIAL PAGE WITH IMPROVEMENTS
// ============================================================================
// ============================================================================
// ONBOARDING PAGE - Collect User Information
// ============================================================================
function OnboardingPage() {
  const navigate = useNavigate();
  const { user, firebaseUser } = useAuth();
  const { language } = useLang();
  const t = useTranslation(language);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    workEmail: firebaseUser?.email || '',
    fullName: firebaseUser?.displayName || '',
    companyName: '',
    jobTitle: '',
    companySize: '',
    numTools: 50
  });

  // If no user, redirect to home
  useEffect(() => {
    if (!firebaseUser) {
      navigate('/', { replace: true });
    }
  }, [firebaseUser, navigate]);

  // Check if user already completed onboarding
  useEffect(() => {
    const checkOnboarding = async () => {
      if (firebaseUser) {
        const { user: userData, error } = await getUserProfile(firebaseUser.uid);
        if (userData && userData.onboardingCompleted) {
          navigate('/dashboard', { replace: true });
        }
      }
    };
    checkOnboarding();
  }, [firebaseUser, navigate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Save onboarding data to Firestore
      const { success, error } = await completeOnboarding(firebaseUser.uid, {
        ...formData,
        onboardingCompleted: true,
        onboardingDate: new Date().toISOString()
      });

      if (success) {
        navigate('/dashboard', { replace: true });
      } else {
        alert('Failed to save: ' + error);
      }
    } catch (error) {
      console.error('Onboarding error:', error);
      alert('Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center p-6">
      <div className="w-full max-w-2xl">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-6">
            <RDLogo size="lg" onClick={() => window.location.href = "/dashboard"} />
            <div className="text-3xl font-black bg-gradient-to-r from-blue-400 to-indigo-400 bg-clip-text text-transparent">
              SaasGuard
            </div>
          </div>
          <h1 className="text-4xl font-black text-white mb-3">{t('tell_us_about_yourself')}</h1>
          <p className="text-xl text-slate-400">{t('personalize_experience')}</p>
        </div>

        {/* Onboarding Form */}
        <div className="rounded-3xl border border-white/10 bg-slate-900/60 backdrop-blur-xl p-8 md:p-12">
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Work Email */}
            <div>
              <label className="block text-sm font-semibold text-slate-300 mb-3">
                Work Email
              </label>
              <input
                type="email"
                value={formData.workEmail}
                onChange={(e) => setFormData({ ...formData, workEmail: e.target.value })}
                className="w-full px-6 py-4 bg-slate-950 border border-slate-700 rounded-xl text-white placeholder-slate-500 text-lg focus:border-blue-500 focus:outline-none transition-colors"
                placeholder="you@company.com"
                required
                disabled
              />
            </div>

            {/* Full Name */}
            <div>
              <label className="block text-sm font-semibold text-slate-300 mb-3">
                Full Name
              </label>
              <input
                type="text"
                value={formData.fullName}
                onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                className="w-full px-6 py-4 bg-slate-950 border border-slate-700 rounded-xl text-white placeholder-slate-500 text-lg focus:border-blue-500 focus:outline-none transition-colors"
                placeholder="John Doe"
                required
              />
            </div>

            {/* Company Name */}
            <div>
              <label className="block text-sm font-semibold text-slate-300 mb-3">
                Company Name
              </label>
              <input
                type="text"
                value={formData.companyName}
                onChange={(e) => setFormData({ ...formData, companyName: e.target.value })}
                className="w-full px-6 py-4 bg-slate-950 border border-slate-700 rounded-xl text-white placeholder-slate-500 text-lg focus:border-blue-500 focus:outline-none transition-colors"
                placeholder="Acme Corporation"
                required
              />
            </div>

            {/* Job Title */}
            <div>
              <label className="block text-sm font-semibold text-slate-300 mb-3">
                Job Title
              </label>
              <select
                value={formData.jobTitle}
                onChange={(e) => setFormData({ ...formData, jobTitle: e.target.value })}
                className="w-full px-6 py-4 bg-slate-950 border border-slate-700 rounded-xl text-white text-lg focus:border-blue-500 focus:outline-none transition-colors"
                required
              >
                <option value="">{t('select_role')}</option>
                <option value="CTO">CTO</option>
                <option value="VP of IT">VP of IT</option>
                <option value="IT Manager">IT Manager</option>
                <option value="IT Director">IT Director</option>
                <option value="CEO">CEO</option>
                <option value="CFO">CFO</option>
                <option value="Operations Manager">Operations Manager</option>
                <option value="Security Manager">Security Manager</option>
                <option value="Other">Other</option>
              </select>
            </div>

            {/* Company Size */}
            <div>
              <label className="block text-sm font-semibold text-slate-300 mb-3">
                Company Size
              </label>
              <select
                value={formData.companySize}
                onChange={(e) => setFormData({ ...formData, companySize: e.target.value })}
                className="w-full px-6 py-4 bg-slate-950 border border-slate-700 rounded-xl text-white text-lg focus:border-blue-500 focus:outline-none transition-colors"
                required
              >
                <option value="">{t('select_company_size')}</option>
                <option value="1-50">1-50 employees</option>
                <option value="51-200">51-200 employees</option>
                <option value="201-500">201-500 employees</option>
                <option value="501-1000">501-1,000 employees</option>
                <option value="1000+">1,000+ employees</option>
              </select>
            </div>

            {/* Number of SaaS Tools */}
            <div>
              <label className="block text-sm font-semibold text-slate-300 mb-3">
                Estimated Number of SaaS Tools
              </label>
              <input
                type="range"
                min="5"
                max="200"
                value={formData.numTools}
                onChange={(e) => setFormData({ ...formData, numTools: parseInt(e.target.value) })}
                className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-blue-500"
              />
              <div className="mt-3 text-center text-2xl font-bold text-white">{formData.numTools} tools</div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full px-8 py-5 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 rounded-xl text-white font-bold text-xl transition-all hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-3"
            >
              {loading ? (
                <>
                  <RefreshCw className="w-6 h-6 animate-spin" />
                  Setting up your workspace...
                </>
              ) : (
                <>
                  Continue to Dashboard
                  <ChevronRight className="w-6 h-6" />
                </>
              )}
            </button>

            {/* Terms */}
            <p className="text-center text-sm text-slate-500 mt-6">
              By continuing, you agree to our{' '}
              <Link to="/terms" className="text-blue-400 hover:underline">Terms of Service</Link>
              {' '}and{' '}
              <Link to="/privacy" className="text-blue-400 hover:underline">Privacy Policy</Link>
            </p>
          </form>
        </div>

        {/* Skip Option (for demo) */}
        <div className="text-center mt-6">
          <button
            onClick={() => navigate('/dashboard')}
            className="text-slate-500 hover:text-slate-300 text-sm transition-colors"
          >
            Skip for now →
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// TRIAL PAGE WITH IMPROVEMENTS
// ============================================================================
function TrialPage() {
  const navigate = useNavigate();
  const { language } = useLang();
  const t = useTranslation(language);

  const { login, startDemo } = useAuth();
  const [showAuth, setShowAuth] = useState(false);
  const [showEmailForm, setShowEmailForm] = useState(false);
  const [currentTestimonial, setCurrentTestimonial] = useState(0);
  const [activeFaq, setActiveFaq] = useState(null);
  const [activeStep, setActiveStep] = useState(0);
  const [loading, setLoading] = useState(false);

  // Analytics tracking helper
  const trackEvent = (eventName, params = {}) => {
    if (typeof gtag !== 'undefined') {
      gtag('event', eventName, params);
    }
  };

  // SSO Providers - exact match to screenshot
  const ssoProviders = [
    { id: 'google', name: 'Google', subtitle: 'Sign in with Google account', live: true },
    { id: 'microsoft', name: 'Microsoft', subtitle: 'Microsoft 365 / Azure AD', live: false },
    { id: 'github', name: 'GitHub', subtitle: 'Sign in with GitHub', live: false },
    { id: 'okta', name: 'Okta', subtitle: 'Enterprise SSO via Okta', live: false },
    { id: 'saml', name: 'SAML SSO', subtitle: 'Custom SAML 2.0 provider', live: false },
    { id: 'magic', name: 'Email magic link', subtitle: 'Passwordless — link sent to email', live: true },
  ];

  // Testimonials for carousel
  const testimonials = [
    { quote: "Found $127K in unused licenses in our first week. Nothing else in our stack delivered that kind of ROI that fast.", author: "Sarah Chen", role: "VP of IT", company: "TechFlow Inc.", stat: "$127K saved" },
    { quote: "47 former employees still had admin access across 12 tools. SaasGuard caught every single one in under 10 minutes.", author: "Marcus Rodriguez", role: "CISO", company: "SecureBank", stat: "47 risks closed" },
    { quote: "SOC 2 audit prep used to take 3 weeks of manual spreadsheet work. With SaasGuard's audit reports, we passed in 3 days.", author: "Elena Patel", role: "Compliance Lead", company: "DataCorp", stat: "3-day audit" },
    { quote: "We cancelled 23 unused SaaS tools in month one. That single decision paid for SaasGuard for the next 4 years.", author: "James Wu", role: "IT Director", company: "Velocity Group", stat: "23 tools cut" },
  ];

  // FAQs
  const faqs = [
    { q: "How long does setup take?", a: "Under 5 minutes. Connect via SSO and we'll import everything automatically." },
    { q: "Do I need to install anything?", a: "No. 100% cloud-based. Works in your browser." },
    { q: "What if I have 1000+ tools?", a: "We scale infinitely. Our largest customer tracks 4,200+ applications." },
    { q: "How much can I save?", a: "Average customers save 30% on SaaS spend—typically $50K-$200K annually." },
    { q: "Is my data secure?", a: "Yes. SOC 2 Type II certified, GDPR compliant, ISO 27001 aligned, and AES-256 encrypted at rest and in transit. Data is hosted on Google Cloud Platform in the EU. You own your data and can export or delete it at any time. See our full Security page for details." },
  ];

  // Auto-rotate testimonials
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTestimonial((prev) => (prev + 1) % testimonials.length);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  // Handle SSO provider click
  const handleSSOClick = async (provider) => {
    setLoading(true);
    trackEvent('sso_clicked', { provider: provider.id });
    
    try {
      if (provider.id === 'google') {
        // REAL Firebase Google Authentication
        const user = await login();
        if (user) {
          setShowAuth(false);
          setLoading(false);
          // Check if user completed onboarding
          const { user: userData } = await getUserProfile(user.uid);
          if (userData && userData.onboardingCompleted) {
            navigate("/dashboard", { replace: true });
          } else {
            navigate("/onboarding", { replace: true });
          }
        } else {
          setLoading(false);
        }
      } else if (provider.id === 'magic') {
        setShowEmailForm(true);
        setLoading(false);
      } else {
        // Demo mode for other providers (Microsoft, GitHub, etc)
        await new Promise(resolve => setTimeout(resolve, 1000));
        localStorage.setItem('sso_provider', provider.id);
        setShowAuth(false);
        startDemo();
        navigate("/dashboard", { replace: true });
        setLoading(false);
      }
    } catch (error) {
      console.error('Auth error:', error);
      alert('Sign in failed. Please try again.');
      setLoading(false);
    }
  };

  // Handle email magic link
  const handleEmailSubmit = async (email) => {
    setLoading(true);
    
    const { success, error } = await sendMagicLink(email);
    
    if (success) {
      setShowEmailForm(false);
      setShowAuth(false);
      alert('✅ Check your email! We sent you a magic link to sign in.\n\nClick the link in the email to complete sign-in.');
    } else {
      alert('❌ Failed to send email: ' + error + '\n\nPlease try again or use Google sign-in.');
    }
    
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 text-white">
      {/* Floating Particles Background */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        {[...Array(15)].map((_, i) => (
          <div
            key={i}
            className="absolute w-2 h-2 bg-blue-500/20 rounded-full animate-pulse"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 5}s`,
              animationDuration: `${10 + Math.random() * 10}s`,
            }}
          />
        ))}
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl" />
      </div>

      {/* Navigation */}
      <nav className="relative z-50 border-b border-white/5 bg-slate-950/50 backdrop-blur-2xl sticky top-0">
        <div className="max-w-7xl mx-auto px-6 py-6">
          <div className="flex items-center justify-between">
            <div onClick={() => window.location.href = "/dashboard"} className="flex items-center gap-4 cursor-pointer group">
              <RDLogo size="md" onClick={() => window.location.href = "/dashboard"} />
              <div>
                <div className="text-2xl font-black bg-gradient-to-r from-blue-400 via-indigo-400 to-purple-400 bg-clip-text text-transparent">
                  SaasGuard
                </div>
                <div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>
              </div>
            </div>
            <div className="hidden md:flex items-center gap-8">
              <a href="#features" className="text-sm font-medium text-slate-300 hover:text-white transition-colors">Features</a>
              <a href="#how-it-works" className="text-sm font-medium text-slate-300 hover:text-white transition-colors">How It Works</a>
              <a href="#testimonials" className="text-sm font-medium text-slate-300 hover:text-white transition-colors">Testimonials</a>
              <a href="#faq" className="text-sm font-medium text-slate-300 hover:text-white transition-colors">FAQ</a>
              <button
                onClick={() => { startDemo(); navigate("/dashboard"); }}
                className="px-6 py-3 border border-emerald-600/50 hover:border-emerald-400 bg-emerald-600/10 hover:bg-emerald-600/20 rounded-xl font-semibold transition-all duration-300 text-emerald-400 hover:text-emerald-300 flex items-center gap-2"
              >
                <Play className="w-4 h-4" />
                Live Demo
              </button>
              <button
                onClick={() => setShowAuth(true)}
                className="px-6 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 rounded-xl font-semibold transition-all duration-300 shadow-lg hover:scale-105"
              >
                Get Started Free
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* IMPROVEMENT 1: BETTER HERO COPY */}
      <section className="relative z-10 pt-32 pb-20 px-6">
        <div className="max-w-7xl mx-auto text-center">
          {/* IMPROVEMENT 7: TRUST BADGES */}
          <div className="inline-flex items-center gap-2 px-6 py-3 rounded-full border border-blue-500/30 bg-blue-500/10 mb-8">
            <Shield className="w-5 h-5 text-blue-400" />
            <span className="text-sm font-semibold bg-gradient-to-r from-blue-400 to-indigo-400 bg-clip-text text-transparent">
              SOC 2 Certified • GDPR Compliant • Trusted by 847+ Companies
            </span>
          </div>

          <h1 className="text-6xl md:text-7xl lg:text-9xl font-black mb-8 leading-none tracking-tight">
            <span className="block text-white">Stop Paying for</span>
            <span className="block bg-gradient-to-r from-blue-400 via-indigo-400 to-purple-400 bg-clip-text text-transparent drop-shadow-[0_0_80px_rgba(96,165,250,0.4)]">
              Ghost Users
            </span>
            <span className="block text-white">& Orphaned Tools</span>
          </h1>

          <p className="text-2xl md:text-3xl lg:text-4xl text-slate-300 mb-6 max-w-4xl mx-auto font-light">
            Cut SaaS waste by <span className="text-blue-400 font-bold">30%</span> in your first month. <span className="text-emerald-400 font-bold">$2.4M saved</span> by customers this year.
          </p>
          
          <p className="text-xl text-slate-400 mb-12 max-w-3xl mx-auto leading-relaxed">
            The command centre for IT Directors, CTOs and Security teams. One platform for every SaaS tool, user, and license across your organisation. <span className="text-white font-semibold">14,000+ unused licenses reclaimed.</span> SOC 2 ready. Audit-proof. Zero blind spots.</p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16">
            <button
              onClick={() => {
                trackEvent('trial_started', { location: 'hero', category: 'conversion' });
                setShowAuth(true);
              }}
              className="group px-12 py-6 bg-gradient-to-r from-blue-600 via-indigo-600 to-purple-600 rounded-2xl font-bold text-xl overflow-hidden transition-all duration-300 hover:scale-110 shadow-2xl shadow-blue-500/50 relative"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-1000" />
              <span className="relative flex items-center gap-3">
                <Sparkles className="w-6 h-6 animate-pulse" />
                Find Your Hidden Costs in 60 Seconds
                <ChevronRight className="w-6 h-6 group-hover:translate-x-2 transition-transform" />
              </span>
            </button>
            
            <button 
              onClick={() => {
                document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' });
                trackEvent('demo_clicked', { location: 'hero' });
              }}
              className="px-12 py-6 border-2 border-white/20 hover:border-white/30 bg-white/5 backdrop-blur-xl rounded-2xl font-semibold text-xl transition-all duration-300 hover:scale-105 flex items-center gap-3"
            >
              <Play className="w-5 h-5" />
              See Dashboard Preview
            </button>
          </div>

          {/* Stats - Social Proof */}
          <div className="grid md:grid-cols-3 gap-6 max-w-4xl mx-auto">
            <div className="group relative overflow-hidden rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl p-8 hover:border-white/20 transition-all duration-500 hover:scale-105">
              <div className="absolute inset-0 bg-gradient-to-br from-emerald-400 to-teal-400 opacity-0 group-hover:opacity-10 transition-opacity duration-500" />
              <div className="relative">
                <div className="text-5xl font-black mb-2 bg-gradient-to-r from-emerald-400 to-teal-400 bg-clip-text text-transparent">
                  $2.4M
                </div>
                <div className="text-sm font-semibold text-slate-400 uppercase tracking-wider">Waste Recovered</div>
              </div>
            </div>
            <div className="group relative overflow-hidden rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl p-8 hover:border-white/20 transition-all duration-500 hover:scale-105">
              <div className="absolute inset-0 bg-gradient-to-br from-blue-400 to-indigo-400 opacity-0 group-hover:opacity-10 transition-opacity duration-500" />
              <div className="relative">
                <div className="text-5xl font-black mb-2 bg-gradient-to-r from-blue-400 to-indigo-400 bg-clip-text text-transparent">
                  847+
                </div>
                <div className="text-sm font-semibold text-slate-400 uppercase tracking-wider">Companies Trust Us</div>
              </div>
            </div>
            <div className="group relative overflow-hidden rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl p-8 hover:border-white/20 transition-all duration-500 hover:scale-105">
              <div className="absolute inset-0 bg-gradient-to-br from-purple-400 to-pink-400 opacity-0 group-hover:opacity-10 transition-opacity duration-500" />
              <div className="relative">
                <div className="text-5xl font-black mb-2 bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
                  56K+
                </div>
                <div className="text-sm font-semibold text-slate-400 uppercase tracking-wider">Risks Prevented</div>
              </div>
            </div>
          </div>
          
          {/* SOCIAL PROOF BADGES */}
          <div className="flex flex-wrap items-center justify-center gap-4 mt-16 mb-4">
            {[
              { label: "4.9/5 on G2", sub: "142 verified reviews", icon: "⭐" },
              { label: "Top Rated 2025", sub: "SaaS Management", icon: "🏆" },
              { label: "SOC 2 Type II", sub: "Certified", icon: "🛡️" },
              { label: "GDPR Compliant", sub: "EU Data Residency", icon: "🇪🇺" },
            ].map(b => (
              <div key={b.label} className="flex items-center gap-3 px-4 py-2.5 rounded-xl border border-white/10 bg-white/5 hover:border-emerald-500/30 hover:bg-emerald-500/5 transition-all">
                <span className="text-xl">{b.icon}</span>
                <div>
                  <div className="text-xs font-bold text-white">{b.label}</div>
                  <div className="text-[10px] text-slate-500">{b.sub}</div>
                </div>
              </div>
            ))}
          </div>

          {/* TRUSTED BY - COMPANY LOGOS */}
          <div className="mt-10">
            <p className="text-center text-sm font-semibold text-slate-500 uppercase tracking-wider mb-10">Trusted by leading companies</p>
            <div className="flex flex-wrap items-center justify-center gap-4 lg:gap-6">
              {[
                { name: "Salesforce", color: "from-blue-500 to-blue-700" },
                { name: "HubSpot",    color: "from-orange-500 to-red-600" },
                { name: "Slack",      color: "from-purple-500 to-indigo-600" },
                { name: "Zoom",       color: "from-blue-400 to-blue-600" },
                { name: "GitHub",     color: "from-slate-600 to-slate-800" },
                { name: "Notion",     color: "from-slate-500 to-slate-700" },
                { name: "Figma",      color: "from-pink-500 to-purple-600" },
                { name: "Asana",      color: "from-pink-400 to-rose-600" },
              ].map(({ name, color }) => (
                <div key={name} className="flex items-center gap-2.5 px-5 py-2.5 rounded-xl border border-white/10 bg-white/5 hover:border-white/20 hover:bg-white/10 transition-all duration-300 group">
                  <div className={`w-6 h-6 rounded-md bg-gradient-to-br ${color} flex items-center justify-center text-white text-xs font-black flex-shrink-0`}>{name[0]}</div>
                  <span className="text-sm font-semibold text-slate-400 group-hover:text-white transition-colors">{name}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ROI CALCULATOR WIDGET */}
      <section className="relative z-10 py-32 px-6">
        <div className="max-w-4xl mx-auto">
          <div className="rounded-3xl border border-emerald-500/20 bg-gradient-to-br from-emerald-500/10 via-transparent to-blue-500/10 backdrop-blur-xl p-12">
            <div className="text-center mb-10">
              <h2 className="text-4xl md:text-5xl font-black mb-4 bg-gradient-to-r from-emerald-400 to-blue-400 bg-clip-text text-transparent">
                Calculate Your Savings
              </h2>
              <p className="text-xl text-slate-300">See how much you could save with SaasGuard</p>
            </div>
            
            <ROICalculator />
          </div>
        </div>
      </section>

      {/* IMPROVEMENT 3: INTERACTIVE PRODUCT TOUR */}
      <section id="how-it-works" className="relative z-10 py-32 px-6 bg-gradient-to-b from-transparent via-white/[0.02] to-transparent">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-20">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-purple-500/20 bg-purple-500/10 mb-6">
              <Play className="w-4 h-4 text-purple-400" />
              <span className="text-sm font-semibold text-purple-400">How It Works</span>
            </div>
            <h2 className="text-5xl md:text-6xl font-black mb-6">
              <span className="bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
                From Chaos to Control in 3 Steps
              </span>
            </h2>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {[
              { emoji: "🔌", title: "Connect Your Tools", desc: "One-click SSO with Google, Microsoft, Okta, and 20+ providers. Zero manual entry." },
              { emoji: "🤖", title: "AI Scans Everything", desc: "ML engine analyzes 100K+ access records in seconds. Finds risks you didn't know existed." },
              { emoji: "✅", title: "Fix Issues Instantly", desc: "One-click remediation. Revoke access, assign owners, generate reports — all automated." },
            ].map((step, idx) => (
              <button
                key={idx}
                onClick={() => setActiveStep(idx)}
                className={`text-left p-8 rounded-3xl border-2 transition-all duration-500 ${
                  activeStep === idx ? 'border-blue-500/50 bg-blue-500/10 scale-105' : 'border-white/10 bg-white/5 hover:border-white/20'
                }`}
              >
                <div className="text-6xl mb-4">{step.emoji}</div>
                <h3 className="text-2xl font-bold mb-3 text-white">Step {idx + 1}: {step.title}</h3>
                <p className="text-slate-400 leading-relaxed">{step.desc}</p>
              </button>
            ))}
          </div>

          <div className="flex justify-center gap-3 mt-12">
            {[0, 1, 2].map((idx) => (
              <button
                key={idx}
                onClick={() => setActiveStep(idx)}
                className={`h-2 rounded-full transition-all duration-300 ${
                  activeStep === idx ? 'w-12 bg-blue-500' : 'w-2 bg-slate-700'
                }`}
              />
            ))}
          </div>
        </div>
      </section>

      {/* IMPROVEMENT 5: DASHBOARD PREVIEW */}
      <section id="features" className="relative z-10 py-32 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-5xl md:text-6xl font-black mb-6">
              <span className="bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
                One Dashboard. Total Control.
              </span>
            </h2>
          </div>

          <div className="relative rounded-3xl border-2 border-white/20 bg-gradient-to-br from-slate-900 to-slate-800 p-8 shadow-2xl">
            <div className="flex items-center gap-2 mb-6 pb-4 border-b border-white/10">
              <div className="flex gap-2">
                <div className="w-3 h-3 rounded-full bg-red-500" />
                <div className="w-3 h-3 rounded-full bg-yellow-500" />
                <div className="w-3 h-3 rounded-full bg-green-500" />
              </div>
              <div className="flex-1 text-center text-sm text-slate-500">app.accessguard.io/dashboard</div>
            </div>

            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-2xl font-bold text-white">Welcome back, Roland 👋</h3>
                  <p className="text-slate-400">Here's your security overview</p>
                </div>
                <div className="px-4 py-2 bg-emerald-600/20 border border-emerald-600/30 rounded-xl text-emerald-400 text-sm font-semibold">
                  ✓ All Systems Secure
                </div>
              </div>

              <div className="grid grid-cols-4 gap-4">
                {[
                  { label: "Tools Tracked", value: "47", trend: "+3 this week" },
                  { label: "Active Users", value: "234", trend: "+12 this month" },
                  { label: "Admin Access", value: "18", trend: "2 need review" },
                  { label: "Monthly Spend", value: "$12.4K", trend: "↓ $2.1K saved" },
                ].map((stat, idx) => (
                  <div key={idx} className="rounded-2xl border border-white/10 bg-white/5 p-6">
                    <div className="text-sm text-slate-400 mb-2">{stat.label}</div>
                    <div className="text-3xl font-bold text-white mb-1">{stat.value}</div>
                    <div className="text-xs text-emerald-400">{stat.trend}</div>
                  </div>
                ))}
              </div>

              <div className="rounded-2xl border-2 border-yellow-500/30 bg-yellow-500/10 p-6">
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-xl bg-yellow-500/20 flex items-center justify-center flex-shrink-0">
                    <AlertTriangle className="w-5 h-5 text-yellow-400" />
                  </div>
                  <div className="flex-1">
                    <h4 className="text-lg font-bold text-white mb-2">3 orphaned tools detected</h4>
                    <p className="text-slate-400 text-sm mb-4">GitHub, Figma, and Notion have no assigned owners</p>
                    {/* AssignOwnersButton removed - file missing */}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* IMPROVEMENT 4: SOCIAL PROOF CAROUSEL */}
      <section id="testimonials" className="relative z-10 py-32 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-20">
            <h2 className="text-5xl md:text-6xl font-black mb-6">
              <span className="bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
                Real Results, Real Fast
              </span>
            </h2>
          </div>

          <div className="max-w-5xl mx-auto">
            <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-white/5 to-white/0 backdrop-blur-xl p-12">
              <div className="flex gap-2 mb-8">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="w-6 h-6 fill-yellow-400 text-yellow-400" />
                ))}
              </div>
              
              <p className="text-2xl md:text-3xl text-slate-200 mb-8 leading-relaxed">
                "{testimonials[currentTestimonial].quote}"
              </p>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white font-bold text-xl">
                    {testimonials[currentTestimonial].author.split(' ').map(n => n[0]).join('')}
                  </div>
                  <div>
                    <div className="font-bold text-white text-lg">{testimonials[currentTestimonial].author}</div>
                    <div className="text-slate-400">{testimonials[currentTestimonial].role}</div>
                    <div className="text-sm text-slate-500">{testimonials[currentTestimonial].company}</div>
                  </div>
                </div>

                <div className="hidden md:block text-right">
                  <div className="text-3xl font-black bg-gradient-to-r from-emerald-400 to-teal-400 bg-clip-text text-transparent">
                    {testimonials[currentTestimonial].stat}
                  </div>
                  <div className="text-sm text-slate-500">in first month</div>
                </div>
              </div>

              <div className="flex justify-center gap-2 mt-8">
                {testimonials.map((_, idx) => (
                  <button
                    key={idx}
                    onClick={() => setCurrentTestimonial(idx)}
                    className={`h-2 rounded-full transition-all duration-300 ${
                      currentTestimonial === idx ? 'w-8 bg-blue-500' : 'w-2 bg-slate-700'
                    }`}
                  />
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* COMPARISON TABLE - SaasGuard vs Competitors */}
      <section className="relative z-10 py-32 px-6">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-blue-500/20 bg-blue-500/10 mb-6">
              <BarChart3 className="w-4 h-4 text-blue-400" />
              <span className="text-sm font-semibold text-blue-400">Why SaasGuard</span>
            </div>
            <h2 className="text-5xl md:text-6xl font-black mb-6">
              <span className="bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
                Better Than The Competition
              </span>
            </h2>
            <p className="text-xl text-slate-400">See how we compare to other SaaS management platforms</p>
          </div>

          <div className="rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-white/10 bg-white/5">
                    <th className="text-left p-6 text-sm font-semibold text-slate-400">Feature</th>
                    <th className="p-6 text-center">
                      <div className="flex items-center justify-center gap-2 mb-1"><span className="text-lg font-bold text-white">SaasGuard</span><span className="text-[10px] bg-blue-500 text-white px-1.5 py-0.5 rounded font-bold uppercase tracking-wide">NEW</span></div>
                      <div className="text-sm text-emerald-400">$99/mo</div>
                    </th>
                    <th className="p-6 text-center">
                      <div className="text-lg font-semibold text-slate-400">Zluri</div>
                      <div className="text-sm text-slate-500">$500/mo</div>
                    </th>
                    <th className="p-6 text-center">
                      <div className="text-lg font-semibold text-slate-400">Torii</div>
                      <div className="text-sm text-slate-500">$350/mo</div>
                    </th>
                    <th className="p-6 text-center">
                      <div className="text-lg font-semibold text-slate-400">Manual</div>
                      <div className="text-sm text-slate-500">Free</div>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {[
                    { feature: 'License Tracking', us: true, zluri: true, torii: true, manual: false },
                    { feature: 'Auto-Reclamation', us: true, zluri: false, torii: true, manual: false },
                    { feature: 'AI Cost Recommendations', us: true, zluri: false, torii: false, manual: false },
                    { feature: 'Renewal Alerts (90-day)', us: true, zluri: true, torii: true, manual: false },
                    { feature: 'Invoice Automation', us: true, zluri: false, torii: false, manual: false },
                    { feature: 'Real-time Dashboard', us: true, zluri: true, torii: true, manual: false },
                    { feature: 'CSV Import/Export', us: true, zluri: true, torii: true, manual: true },
                    { feature: 'Role-based Access', us: true, zluri: true, torii: true, manual: false },
                    { feature: 'Slack Integration', us: true, zluri: false, torii: true, manual: false },
                    { feature: 'Free Trial', us: true, zluri: false, torii: true, manual: true },
                  ].map((row, idx) => (
                    <tr key={idx} className="border-b border-white/5 hover:bg-white/5 transition-colors">
                      <td className="p-6 text-slate-300 font-medium">{row.feature}</td>
                      <td className="p-6 text-center">
                        {row.us ? (
                          <CheckCircle className="w-6 h-6 text-emerald-400 mx-auto" />
                        ) : (
                          <X className="w-6 h-6 text-slate-600 mx-auto" />
                        )}
                      </td>
                      <td className="p-6 text-center">
                        {row.zluri ? (
                          <CheckCircle className="w-6 h-6 text-slate-500 mx-auto" />
                        ) : (
                          <X className="w-6 h-6 text-slate-700 mx-auto" />
                        )}
                      </td>
                      <td className="p-6 text-center">
                        {row.torii ? (
                          <CheckCircle className="w-6 h-6 text-slate-500 mx-auto" />
                        ) : (
                          <X className="w-6 h-6 text-slate-700 mx-auto" />
                        )}
                      </td>
                      <td className="p-6 text-center">
                        {row.manual ? (
                          <CheckCircle className="w-6 h-6 text-slate-500 mx-auto" />
                        ) : (
                          <X className="w-6 h-6 text-slate-700 mx-auto" />
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            
            <div className="p-8 bg-gradient-to-r from-emerald-500/10 to-blue-500/10 border-t border-white/10">
              <div className="flex flex-col md:flex-row items-center justify-between gap-4">
                <div>
                  <div className="text-xl font-bold text-white mb-2">Ready to save 30% on SaaS costs?</div>
                  <div className="text-slate-400">Join 847+ companies already using SaasGuard</div>
                </div>
                <button 
                  data-start-trial
                  onClick={() => {
                    const startBtn = document.querySelector('.group.px-12.py-6');
                    if (startBtn) startBtn.click();
                    else window.scrollTo({ top: 0, behavior: 'smooth' });
                  }}
                  className="px-8 py-4 bg-gradient-to-r from-emerald-600 to-blue-600 hover:from-emerald-500 hover:to-blue-500 rounded-xl font-bold text-lg transition-all hover:scale-105 whitespace-nowrap"
                >
                  Start Free Trial
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* IMPROVEMENT 6: FAQ SECTION */}
      <section id="faq" className="relative z-10 py-32 px-6 bg-gradient-to-b from-transparent via-white/[0.02] to-transparent">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-5xl md:text-6xl font-black mb-6">
              <span className="bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
                Frequently Asked Questions
              </span>
            </h2>
          </div>

          <div className="space-y-4">
            {faqs.map((faq, idx) => (
              <div key={idx} className="rounded-2xl border border-white/10 bg-white/5 overflow-hidden">
                <button
                  onClick={() => setActiveFaq(activeFaq === idx ? null : idx)}
                  className="w-full flex items-center justify-between p-6 text-left hover:bg-white/5 transition-colors"
                >
                  <span className="text-xl font-semibold text-white pr-8">{faq.q}</span>
                  <ChevronDown 
                    className={`w-6 h-6 text-slate-400 transition-transform flex-shrink-0 ${
                      activeFaq === idx ? 'rotate-180' : ''
                    }`}
                  />
                </button>
                {activeFaq === idx && (
                  <div className="px-6 pb-6 text-lg text-slate-400 leading-relaxed">
                    {faq.a}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="relative z-10 py-32 px-6">
        <div className="max-w-4xl mx-auto text-center">
          <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-blue-500/10 via-indigo-500/10 to-purple-500/10 backdrop-blur-xl p-16">
            <div className="relative">
              <h2 className="text-5xl md:text-6xl font-black mb-6">
                <span className="bg-gradient-to-r from-white via-blue-100 to-indigo-100 bg-clip-text text-transparent">
                  Ready to Secure Your SaaS?
                </span>
              </h2>
              <p className="text-xl text-slate-300 mb-10">Join 847+ companies protecting their SaaS ecosystem today</p>
              <button
                onClick={() => setShowAuth(true)}
                className="group inline-flex items-center gap-3 px-12 py-6 bg-gradient-to-r from-blue-600 via-indigo-600 to-purple-600 rounded-2xl font-bold text-xl overflow-hidden transition-all duration-300 hover:scale-110 shadow-2xl shadow-blue-500/50 relative"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-1000" />
                <span className="relative flex items-center gap-3">
                  <Sparkles className="w-6 h-6" />
                  Start Free Trial
                  <ChevronRight className="w-6 h-6" />
                </span>
              </button>
              <p className="mt-6 text-sm text-slate-400">No credit card required • 14-day free trial</p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-10 border-t border-white/5 bg-slate-950/50 py-12 px-6">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-4">
            <RDLogo size="sm" onClick={() => window.location.href = "/dashboard"} />
            <div>
              <div className="text-xl font-bold bg-gradient-to-r from-blue-400 to-indigo-400 bg-clip-text text-transparent">SaasGuard</div>
              <div className="text-xs text-slate-500">© 2026 Roland D. • All rights reserved</div>
            </div>
          </div>
          <div className="flex flex-col md:flex-row gap-4 md:gap-8 text-sm text-slate-400 text-center md:text-left">
            <a href="mailto:hello@accessguard.io" className="hover:text-white transition-colors font-semibold text-blue-400 flex items-center gap-2 justify-center md:justify-start">
              <MessageCircle className="w-4 h-4" />
              hello@accessguard.io
            </a>
            <Link to="/privacy" className="hover:text-white transition-colors">Privacy</Link>
            <Link to="/terms" className="hover:text-white transition-colors">Terms</Link>
            <Link to="/security-info" className="hover:text-white transition-colors">Security</Link>
          </div>
        </div>
      </footer>

      {/* SSO AUTH MODAL - EXACT MATCH TO SCREENSHOT */}
      <Modal 
        open={showAuth && !showEmailForm} 
        title="Sign in with SSO" 
        subtitle="Choose a provider to continue" 
        onClose={() => setShowAuth(false)}
      >
        <div className="space-y-3">
          {ssoProviders.map((provider) => (
            <button
              key={provider.id}
              onClick={() => provider.live ? handleSSOClick(provider) : alert("Coming soon — " + provider.name + " SSO is in development. We will notify you when it is ready.")}
              className={"w-full flex items-center justify-between p-5 rounded-2xl border transition-all duration-300 group " + (provider.live ? "border-white/10 bg-white/5 hover:bg-white/10 hover:border-white/20" : "border-white/5 bg-white/2 opacity-60 cursor-not-allowed")}
            >
              <div className="flex items-center gap-4">
                <div className={"w-12 h-12 rounded-xl flex items-center justify-center " + (provider.live ? "bg-slate-800" : "bg-slate-900")}>
                  <Building2 className={"w-6 h-6 " + (provider.live ? "text-slate-300" : "text-slate-600")} />
                </div>
                <div className="text-left">
                  <div className={"font-semibold " + (provider.live ? "text-white" : "text-slate-500")}>Continue with {provider.name}</div>
                  <div className="text-sm text-slate-500">{provider.subtitle}</div>
                </div>
              </div>
              {provider.live
                ? <ChevronRight className="w-5 h-5 text-slate-400 group-hover:text-white transition-colors" />
                : <span className="text-[10px] font-bold text-slate-600 bg-slate-800 px-2 py-0.5 rounded-full uppercase tracking-wide">Soon</span>
              }
            </button>
          ))}
        </div>

        <div className="mt-6 pt-6 border-t border-white/10 text-center text-sm text-slate-400">
          SSO buttons simulate authentication and continue onboarding.
        </div>

        <div className="mt-6 flex items-center justify-between gap-4">
          <button
            onClick={() => setShowAuth(false)}
            className="flex-1 px-6 py-3 text-slate-400 hover:text-white transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={() => { setShowAuth(false); startDemo(); navigate("/dashboard"); }}
            className="flex-1 px-6 py-3 bg-emerald-700 hover:bg-emerald-600 rounded-xl text-white font-bold transition-colors flex items-center justify-center gap-2 border border-emerald-500/30"
          >
            <Play className="w-4 h-4" />
            Try Live Demo — No Sign Up
          </button>
        </div>
      </Modal>

      {/* EMAIL MAGIC LINK FORM MODAL */}
      <Modal
        open={showEmailForm}
        title="Email Magic Link"
        subtitle="We'll send you a magic link to sign in—no password needed"
        onClose={() => { setShowEmailForm(false); setShowAuth(true); }}
      >
        <form onSubmit={(e) => { e.preventDefault(); handleEmailSubmit(e.target.email.value); }} className="space-y-4">
          <input
            type="email"
            name="email"
            placeholder="you@company.com"
            required
            className="w-full px-6 py-4 bg-slate-900 border border-slate-700 rounded-xl text-white placeholder-slate-500 text-lg focus:border-blue-500 focus:outline-none transition-colors"
          />
          
          <button
            type="submit"
            className="w-full px-6 py-4 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 rounded-xl text-white font-semibold text-lg transition-all"
          >
            Send Magic Link
          </button>
          
          <button
            type="button"
            onClick={() => { setShowEmailForm(false); setShowAuth(true); }}
            className="w-full px-6 py-3 text-slate-400 hover:text-white transition-colors"
          >
            ← Back to SSO options
          </button>
        </form>
      </Modal>

      {/* Scroll to Top Button */}
      <ScrollToTop />
    </div>
  );
}

function ExitIntentModal({ open, onClose, onContinue }) {
  return (
    <Modal
      open={open}
      title="Wait — quick win before you go"
      subtitle="See how teams save money fast"
      onClose={onClose}
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>
            Close
          </Button>
          <Button
            onClick={() => {
              onClose();
              onContinue();
            }}
          >
            <Sparkles className="h-4 w-4" />
            Continue
          </Button>
        </div>
      }
    >
      <div className="space-y-3 text-sm text-slate-300">
        <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
          <div className="text-sm font-semibold text-slate-100">Case study (example)</div>
          <div className="mt-2 text-slate-400">“Company X saved $50K in 3 months by removing unused licenses and tightening admin reviews.”</div>
          <div className="mt-3 flex flex-wrap gap-2">
            <Pill tone="amber" icon={AlertTriangle}>
              Unused licenses
            </Pill>
            <Pill tone="rose" icon={UserMinus}>
              Former employee access
            </Pill>
            <Pill tone="blue" icon={Download}>
              Audit exports
            </Pill>
          </div>
        </div>
      </div>
    </Modal>
  );
}

// Executive Dashboard Wrapper
function ExecutivePageWrapper() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  if (!db) return <div className="flex items-center justify-center h-screen"><div className="text-white">{t('loading')}</div></div>;
  
  const derived = {
    tools: db.tools.map(t => ({ ...t, derived_risk: computeToolDerivedRisk(t) })),
    employees: db.employees || [],
    access: db.access || [],
    alerts: buildRiskAlerts({ tools: db.tools, access: db.access || [], employees: db.employees || [] })
  };
  
  return (
    <AppShell title={"Executive View" || 'Executive Dashboard'}>
      <ExecutiveDashboard data={derived} />
    </AppShell>
  );
}

// ============================================================================
// GOOGLE WORKSPACE SYNC BUTTON
// ============================================================================
function GoogleWorkspaceSync() {
  const { firebaseUser } = useAuth();
  const muts = useDbMutations();
  const [syncing, setSyncing] = useState(false);
  const [syncStatus, setSyncStatus] = useState(null);
  const [syncedCount, setSyncedCount] = useState(0);
  const getToken = (u) => u?.stsTokenManager?.accessToken || null;
  const hasPerms = firebaseUser ? getToken(firebaseUser) !== null : false;

  const handleSync = async () => {
    if (!firebaseUser) { setSyncStatus({ type: 'error', message: 'Sign in with Google first.' }); return; }
    const token = getToken(firebaseUser);
    if (!token) { setSyncStatus({ type: 'error', message: 'No access token — sign in with Google.' }); return; }
    setSyncing(true);
    setSyncStatus({ type: 'loading', message: 'Importing from Google Workspace...' });
    try {
      const res = await fetch('https://admin.googleapis.com/admin/directory/v1/users?domain=primary&maxResults=500', {
        headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
      });
      if (!res.ok) throw new Error(`API ${res.status}: ${res.statusText}`);
      const data = await res.json();
      const users = (data.users || []).map(u => ({
        name: u.name.fullName, email: u.primaryEmail,
        status: u.suspended ? 'offboarded' : 'active',
        department: u.orgUnitPath?.split('/').pop() || 'general',
        role: u.isAdmin ? 'admin' : 'user',
        google_user_id: u.id, imported_from: 'google_workspace',
        imported_at: new Date().toISOString(),
      }));
      let count = 0;
      for (const u of users) { try { await muts.addEmployee.mutateAsync(u); count++; } catch {} }
      setSyncedCount(count);
      setSyncStatus({ type: 'success', message: `Imported ${count} users from Google Workspace!` });
      setTimeout(() => window.location.reload(), 2000);
    } catch (err) {
      setSyncStatus({ type: 'error', message: `Sync failed: ${err.message}` });
    } finally { setSyncing(false); }
  };

  if (!firebaseUser) return null;
  return (
    <div className="bg-gradient-to-br from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
      <div className="flex items-center gap-4 mb-4">
        <div className="p-3 bg-blue-500/20 rounded-xl">
          <RefreshCw className={`h-6 w-6 text-blue-400 ${syncing ? 'animate-spin' : ''}`} />
        </div>
        <div className="flex-1">
          <h3 className="text-xl font-bold text-white">Google Workspace Sync</h3>
          <p className="text-sm text-slate-300">Import users automatically from Google Workspace</p>
        </div>
        {hasPerms && (
          <button onClick={handleSync} disabled={syncing}
            className={`px-6 py-3 rounded-xl font-semibold transition-all ${syncing ? 'bg-slate-600 text-slate-400 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-500 text-white'}`}>
            {syncing ? 'Syncing...' : 'Sync Now'}
          </button>
        )}
      </div>
      {!hasPerms && (
        <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-xl p-4">
          <p className="text-sm text-yellow-400">⚠️ Sign in with a Google Workspace admin account to enable sync.</p>
        </div>
      )}
      {syncStatus && (
        <div className={`mt-4 p-4 rounded-xl border ${syncStatus.type === 'success' ? 'bg-emerald-500/10 border-emerald-500/20' : syncStatus.type === 'error' ? 'bg-red-500/10 border-red-500/20' : 'bg-blue-500/10 border-blue-500/20'}`}>
          <p className={`text-sm ${syncStatus.type === 'success' ? 'text-emerald-400' : syncStatus.type === 'error' ? 'text-red-400' : 'text-blue-400'}`}>{syncStatus.message}</p>
          {syncStatus.type === 'success' && syncedCount > 0 && <p className="text-xs text-slate-400 mt-2">Refreshing in 2 seconds...</p>}
        </div>
      )}
    </div>
  );
}

function DashboardPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  // Translation hook
  const { language, setLanguage } = useLang();
  const t = useTranslation(language);

  
  // ADD THESE LINES:
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [orphanedTools] = useState(['GitHub', 'Figma', 'Notion']);
  const [selectedOwners, setSelectedOwners] = useState({});
  const { data: db, isLoading } = useDbQuery();
  const muts = useDbMutations();

  const derived = useMemo(() => {
    if (!db) return null;
    const tools = db.tools.map((t) => ({
      ...t,
      derived_status: computeToolDerivedStatus(t),
      derived_risk: computeToolDerivedRisk(t),
    }));
    const employeesById = Object.fromEntries(db.employees.map((e) => [e.id, e]));
    const toolsById = Object.fromEntries(tools.map((t) => [t.id, t]));
    const access = db.access.map((a) => ({
      ...a,
      derived_risk_flag: computeAccessDerivedRiskFlag(a, employeesById, toolsById),
    }));
    const alerts = buildRiskAlerts({ ...db, tools, access });
    const counts = riskSeverityCounts(alerts);
    const spend = tools.reduce((sum, t) => sum + Number(t.cost_per_month || 0), 0);
    const highRiskTools = tools.filter((t) => t.derived_risk === "high").length;
    const formerAccess = access.filter((a) => a.derived_risk_flag === "former_employee").length;
    return { tools, access, alerts, counts, spend, highRiskTools, formerAccess };
  }, [db]);

  const markReviewed = (accId) => {
    muts.updateAccess.mutate(
      { id: accId, patch: { last_reviewed_date: todayISO(), risk_flag: "none" } },
      { onSuccess: () => toast.success('Marked as reviewed') }
    );
  };

  const revokeAccess = (accId) => {
    muts.updateAccess.mutate(
      { id: accId, patch: { status: "revoked" } },
      { onSuccess: () => toast.success('Access revoked') }
    );
  };

  return (
    <AppShell
      title={"Dashboard"}
      right={
        <div className="flex gap-2">
          <Button
            variant="secondary"
            onClick={() => {
              localStorage.removeItem(LS_KEY);
              
              window.location.reload();
            }}
          >
            <RefreshCw className="h-4 w-4" />
            {"Reset Demo Data"}
          </Button>
          <Link to="/audit">
            <Button>
              <Download className="h-4 w-4" />
              {"Export Audit"}
            </Button>
          </Link>
        </div>
      }
    >

      {/* Executive KPI Strip */}
      {derived && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-4">
          {[
            { label: "Monthly SaaS Spend",
              value: "$" + derived.spend.toLocaleString(),
              sub: derived.tools.filter(t=>t.status==="active").length + " active tools",
              color: "text-white", Icon: BarChart3 },
            { label: "Estimated Waste",
              value: "$" + Math.round(derived.spend * 0.23).toLocaleString(),
              sub: "~23% in orphaned + unused licenses",
              color: "text-amber-400", Icon: TrendingDown },
            { label: "Security Risk",
              value: derived.counts.critical > 3 ? "Critical" : derived.counts.high > 5 ? "High" : derived.counts.critical > 0 ? "Medium" : "Low",
              sub: derived.counts.critical + " critical · " + derived.counts.high + " high alerts",
              color: derived.counts.critical > 0 ? "text-rose-400" : derived.counts.high > 0 ? "text-amber-400" : "text-emerald-400",
              Icon: Shield },
            { label: "Compliance Readiness",
              value: Math.max(40, 100 - derived.counts.critical * 12 - derived.counts.high * 4 - derived.formerAccess * 6) + "%",
              sub: derived.formerAccess + " ex-employee access risks",
              color: "text-blue-400", Icon: BadgeCheck },
          ].map(({ label, value, sub, color, Icon }) => (
            <Card key={label}>
              <CardBody>
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 flex-1">
                    <div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>
                    <div className={"text-2xl font-black " + color}>{value}</div>
                    <div className="text-xs text-slate-500 mt-1 truncate">{sub}</div>
                  </div>
                  <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center flex-shrink-0">
                    <Icon className={"h-4 w-4 " + color} />
                  </div>
                </div>
              </CardBody>
            </Card>
          ))}
        </div>
      )}

      {/* Google Workspace Sync */}
      <GoogleWorkspaceSync />

      {/* AI-Powered Insights */}
      <AIInsights 
        tools={derived?.tools || []} 
        employees={db?.employees || []} 
        spend={derived?.spend || 0} 
        accessData={derived?.access || []} 
      />
      <div className="grid gap-5 lg:grid-cols-12">
        <div className="lg:col-span-8">
          <Card>
            <CardHeader
              title={"Top Alerts"}
              subtitle="Orphaned tools, former employee access, overdue reviews, unused tools."
              right={
                <Pill tone="blue" icon={Sparkles}>
                  {t('live')}
                </Pill>
              }
            />
            <CardBody>
              {isLoading || !derived ? (
                <div className="space-y-2">
                  <SkeletonRow cols={6} />
                  <SkeletonRow cols={6} />
                  <SkeletonRow cols={6} />
                </div>
              ) : derived.alerts.length ? (
                <div className="space-y-3">
                  {derived.alerts.map((a) => (
                    <div
                      key={a.id}
                      className="flex flex-col gap-3 rounded-2xl border border-slate-800 bg-slate-950/30 p-4 md:flex-row md:items-center md:justify-between"
                    >
                      <div className="flex items-start gap-3">
                        <div className="mt-0.5">
                          <RiskBadge risk={a.severity} />
                        </div>
                        <div>
                          <div className="text-sm font-semibold text-slate-100">{a.title}</div>
                          <div className="mt-0.5 text-sm text-slate-400">{a.body}</div>
                        </div>
                      </div>
                      <Link to={a.action.to}>
                        <Button variant="secondary">
                          <a.action.icon className="h-4 w-4" />
                          {a.action.label}
                        </Button>
                      </Link>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState
                  icon={BadgeCheck}
                  title={t("all_clear")}
                  body="No critical issues detected. Keep reviewing admin access and ownership regularly."
                />
              )}
            </CardBody>
          </Card>

          <div className="mt-5 grid gap-5 md:grid-cols-2">
            <Card>
              <CardHeader title={t("risk_counters")} subtitle={t("by_severity")} />
              <CardBody>
                {derived ? (
                  <div className="grid gap-3">
                    <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                      <div className="flex items-center gap-2 text-sm text-slate-200">
                        <AlertTriangle className="h-4 w-4 text-rose-300" />
                        Critical
                      </div>
                      <div className="text-lg font-semibold">{derived.counts.critical}</div>
                    </div>
                    <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                      <div className="flex items-center gap-2 text-sm text-slate-200">
                        <AlertTriangle className="h-4 w-4 text-amber-200" />
                        High
                      </div>
                      <div className="text-lg font-semibold">{derived.counts.high}</div>
                    </div>
                    <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                      <div className="flex items-center gap-2 text-sm text-slate-200">
                        <Info className="h-4 w-4 text-blue-200" />
                        Medium
                      </div>
                      <div className="text-lg font-semibold">{derived.counts.medium}</div>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-2">
                    <SkeletonRow cols={4} />
                    <SkeletonRow cols={4} />
                    <SkeletonRow cols={4} />
                  </div>
                )}
              </CardBody>
            </Card>

            <Card>
              <CardHeader title={t('quick_stats')} subtitle={t("coverage_and_spend")} right={<Pill tone="slate" icon={Activity}>{"Updated"}</Pill>} />
              <CardBody>
                {derived ? (
                  <div className="grid gap-3">
                    <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                      <div className="text-sm text-slate-400">{t('tools_tracked')}</div>
                      <div className="text-lg font-semibold">{derived.tools.length}</div>
                    </div>
                    <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                      <div className="text-sm text-slate-400">{t('high_risk_tools')}</div>
                      <div className="text-lg font-semibold">{derived.highRiskTools}</div>
                    </div>
                    <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                      <div className="text-sm text-slate-400">{t('former_employee_access')}</div>
                      <div className="text-lg font-semibold">{derived.formerAccess}</div>
                    </div>
                    <div className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                      <div className="text-sm text-slate-400">{t('monthly_spend')}</div>
                      <div className="text-lg font-semibold">{formatMoney(derived.spend)}</div>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-2">
                    <SkeletonRow cols={4} />
                    <SkeletonRow cols={4} />
                    <SkeletonRow cols={4} />
                  </div>
                )}
              </CardBody>
            </Card>
          </div>
        </div>

        <div className="lg:col-span-4">
          <Card>
            <CardHeader title={t('quick_actions')} subtitle={t("fast_remediation")} />
            <CardBody>
              <div className="grid gap-3">
                <Link to="/tools">
                  <Button variant="secondary" className="w-full">
                    <Boxes className="h-4 w-4" />
                    {"Assign Tool Owners"}
                  </Button>
                </Link>
                <Link to="/offboarding">
                  <Button variant="secondary" className="w-full">
                    <UserMinus className="h-4 w-4" />
                    {t('revoke_departing_access')}
                  </Button>
                </Link>
                <Link to="/access">
                  <Button className="w-full">
                    <GitMerge className="h-4 w-4" />
                    {t('review_admin_access')}
                  </Button>
                </Link>
              </div>
              <Divider />
              <div className="text-sm font-semibold text-slate-100">{t('overdue_reviews')}</div>
              <div className="mt-1 text-sm text-slate-400">Mark admin access as reviewed after validation.</div>

              {derived ? (
                <div className="mt-4 space-y-3">
                  {derived.access
                    .filter((a) => a.status === "active")
                    .slice(0, 6)
                    .map((a) => (
                      <div key={a.id} className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                        <div>
                          <div className="text-sm font-semibold">{a.tool_name}</div>
                          <div className="mt-0.5 text-xs text-slate-400">
                            {a.employee_name} · {a.employee_email}
                          </div>
                          <div className="mt-2 flex flex-wrap gap-2">
                            <AccessLevelBadge level={a.access_level} />
                            <RiskFlagBadge flag={a.derived_risk_flag} />
                          </div>
                        </div>
                        <div className="mt-3 flex gap-2">
                          <Button size="sm" variant="secondary" onClick={() => markReviewed(a.id)}>
                            <Check className="h-4 w-4" />
                            {t('mark_reviewed')}
                          </Button>
                          <Button size="sm" variant="danger" onClick={() => revokeAccess(a.id)}>
                            <BadgeX className="h-4 w-4" />
                            Revoke
                          </Button>
                        </div>
                      </div>
                    ))}
                </div>
              ) : (
                <div className="mt-4 space-y-2">
                  <SkeletonRow cols={4} />
                  <SkeletonRow cols={4} />
                </div>
              )}
            </CardBody>
          </Card>
        </div>
      </div>

    </AppShell>
  );
}

function ToolForm({ initial, employees, onSubmit, onClose }) {
  const { language } = useLang();
  const t = useTranslation(language);
  const [form, setForm] = useState(
    initial || {
      name: "",
      category: "engineering",
      owner_email: "",
      owner_name: "",
      criticality: "medium",
      url: "",
      description: "",
      status: "active",
      last_used_date: todayISO(),
      cost_per_month: 0,
      risk_score: "low",
      notes: "",
    }
  );

  useEffect(() => {
    const email = (form.owner_email || "").toLowerCase();
    const match = employees.find((e) => (e.email || "").toLowerCase() === email);
    if (match && form.owner_name !== match.full_name) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setForm((f) => ({ ...f, owner_name: match.full_name }));
    }
  }, [form.owner_email, form.owner_name, employees]);

  const canSubmit = form.name.trim().length > 0;

  return (
    <form
      className="grid gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        if (!canSubmit) return;
        onSubmit({
          ...form,
          cost_per_month: Number(form.cost_per_month || 0),
        });
        onClose();
      }}
    >
      <div className="grid gap-3 md:grid-cols-2">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('tool_name')}</div>
          <Input value={form.name} onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))} />
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('category')}</div>
          <Select value={form.category} onChange={(e) => setForm((f) => ({ ...f, category: e.target.value }))}>
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </Select>
        </div>
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('owner_email')}</div>
          <Input value={form.owner_email} onChange={(e) => setForm((f) => ({ ...f, owner_email: e.target.value }))} />
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('owner_name')}</div>
          <Input value={form.owner_name} onChange={(e) => setForm((f) => ({ ...f, owner_name: e.target.value }))} />
        </div>
      </div>

      <div className="grid gap-3 md:grid-cols-3">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('criticality')}</div>
          <Select value={form.criticality} onChange={(e) => setForm((f) => ({ ...f, criticality: e.target.value }))}>
            {CRITICALITY.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </Select>
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Status</div>
          <Select value={form.status} onChange={(e) => setForm((f) => ({ ...f, status: e.target.value }))}>
            {TOOL_STATUS.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </Select>
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('risk_score')}</div>
          <Select value={form.risk_score} onChange={(e) => setForm((f) => ({ ...f, risk_score: e.target.value }))}>
            {RISK_SCORE.map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </Select>
        </div>
      </div>

      <div className="grid gap-3 md:grid-cols-3">
        <div className="md:col-span-2">
          <div className="mb-1 text-xs font-semibold text-slate-400">URL</div>
          <Input value={form.url} onChange={(e) => setForm((f) => ({ ...f, url: e.target.value }))} />
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('last_used')}</div>
          <Input type="date" value={form.last_used_date} onChange={(e) => setForm((f) => ({ ...f, last_used_date: e.target.value }))} />
        </div>
      </div>

      <div>
        <div className="mb-1 text-xs font-semibold text-slate-400">{t('description')}</div>
        <Textarea rows={3} value={form.description} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} />
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Cost / month</div>
          <Input
            type="number"
            value={form.cost_per_month}
            onChange={(e) => setForm((f) => ({ ...f, cost_per_month: e.target.value }))}
          />
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Notes</div>
          <Input value={form.notes} onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))} />
        </div>
      </div>

      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" disabled={!canSubmit}>
          <Check className="h-4 w-4" />
          Save
        </Button>
      </div>
    </form>
  );
}

function ToolsPage() {
  const { data: db, isLoading } = useDbQuery();
  const { language, setLanguage } = useLang();
  const t = useTranslation(language);


  const muts = useDbMutations();

  const [q, setQ] = useState("");
  const [cat, setCat] = useState("");
  const [status, setStatus] = useState("");
  const [risk, setRisk] = useState("");

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);

  const tools = useMemo(() => {
    if (!db) return [];
    return db.tools.map((t) => ({
      ...t,
      derived_status: computeToolDerivedStatus(t),
      derived_risk: computeToolDerivedRisk(t),
    }));
  }, [db]);

  const filtered = useMemo(() => {
    const s = q.trim().toLowerCase();
    return tools
      .filter((t) => {
        if (s && !`${t.name} ${t.owner_name} ${t.owner_email}`.toLowerCase().includes(s)) return false;
        if (cat && t.category !== cat) return false;
        if (status && t.derived_status !== status) return false;
        if (risk && t.derived_risk !== risk) return false;
        return true;
      })
      .sort((a, b) => a.name.localeCompare(b.name));
  }, [tools, q, cat, status, risk]);

  const employees = db?.employees || [];

  return (
    <AppShell
      title={"Tools"}
      right={
        <div className="flex gap-2">
          <Button
            variant="secondary"
            onClick={() => {
              setEditing(null);
              setOpen(true);
            }}
          >
            <Plus className="h-4 w-4" />
            {"Add Tool"}
          </Button>
        </div>
      }
    >
      {/* Spend & Category Overview */}
      <div className="space-y-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-500/20 rounded-2xl p-6">
            <div className="text-slate-400 text-sm mb-2">💰 Monthly Spend</div>
            <div className="text-4xl font-black text-white">
              ${Math.round(tools.reduce((sum, t) => sum + (Number(t.cost_per_month) || 0), 0)).toLocaleString()}
            </div>
            <div className="text-sm text-slate-400 mt-1">{t('total_cost')}</div>
          </div>
          <div className="bg-gradient-to-br from-rose-500/10 to-rose-600/10 border border-rose-500/20 rounded-2xl p-6">
            <div className="text-slate-400 text-sm mb-2">⚠️ High Risk</div>
            <div className="text-4xl font-black text-rose-400">{tools.filter(t => t.derived_risk === 'high').length}</div>
            <div className="text-sm text-slate-400 mt-1">{t('need_attention')}</div>
          </div>
          <div className="bg-gradient-to-br from-amber-500/10 to-amber-600/10 border border-amber-500/20 rounded-2xl p-6">
            <div className="text-slate-400 text-sm mb-2">👻 Unassigned</div>
            <div className="text-4xl font-black text-amber-400">{tools.filter(t => !t.owner_email).length}</div>
            <div className="text-sm text-slate-400 mt-1">{t('no_owner')}</div>
          </div>
          <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-2xl p-6">
            <div className="text-slate-400 text-sm mb-2">🛠️ Total</div>
            <div className="text-4xl font-black text-blue-400">{tools.length}</div>
            <div className="text-sm text-slate-400 mt-1">{t('total_tools')}</div>
          </div>
        </div>
        
        <div>
          <h3 className="text-xl font-bold text-white mb-4">📦 Category Overview</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            {['communication', 'development', 'productivity', 'design', 'security'].map(category => {
              const categoryTools = tools.filter(t => t.category === category);
              const categoryCost = categoryTools.reduce((sum, t) => sum + (Number(t.cost_per_month) || 0), 0);
              return (
                <div key={category} className="bg-slate-900 border border-slate-800 rounded-xl p-4 hover:border-blue-500/50 transition-colors cursor-pointer" onClick={() => setCat(category)}>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-white font-semibold capitalize">{category}</span>
                    <Boxes className="h-5 w-5 text-blue-400" />
                  </div>
                  <div className="text-3xl font-black text-white mb-1">{categoryTools.length}</div>
                  <div className="text-sm text-slate-400">${Math.round(categoryCost).toLocaleString()}/mo</div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      <Card>
        <CardHeader
          title={t('tool_inventory')}
          subtitle={t('tool_inventory_sub')}
          right={<Pill tone="slate" icon={Boxes}>{tools.length} {t('total')}</Pill>}
        />
        <CardBody>
          <div className="grid gap-3 md:grid-cols-12">
            <div className="md:col-span-5">
              <div className="relative">
                <Search className="pointer-events-none absolute left-3 top-3.5 h-4 w-4 text-slate-500" />
                <Input className="pl-9" placeholder={t('search_tools')} value={q} onChange={(e) => setQ(e.target.value)} />
              </div>
            </div>
            <div className="md:col-span-2">
              <Select value={cat} onChange={(e) => setCat(e.target.value)}>
                <option value="">{t('all_categories')}</option>
                {CATEGORIES.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </Select>
            </div>
            <div className="md:col-span-2">
              <Select value={status} onChange={(e) => setStatus(e.target.value)}>
                <option value="">{t('all_status')}</option>
                {TOOL_STATUS.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </Select>
            </div>
            <div className="md:col-span-2">
              <Select value={risk} onChange={(e) => setRisk(e.target.value)}>
                <option value="">{t('all_risk')}</option>
                {RISK_SCORE.map((r) => (
                  <option key={r} value={r}>
                    {r}
                  </option>
                ))}
              </Select>
            </div>
            <div className="md:col-span-1 flex justify-end">
              <Button
                variant="ghost"
                onClick={() => {
                  setQ("");
                  setCat("");
                  setStatus("");
                  setRisk("");
                }}
              >
                <RefreshCw className="h-4 w-4" />
                Reset
              </Button>
            </div>
          </div>

          <div className="mt-4">
            {isLoading ? (
              <div className="space-y-2">
                <SkeletonRow cols={6} />
                <SkeletonRow cols={6} />
                <SkeletonRow cols={6} />
              </div>
            ) : (
              <DataTable
                columns={[
                  {
                    key: "name",
                    header: "Tool",
                    className: "col-span-4",
                    cell: (t) => (
                      <div className="flex items-center gap-3">
                        <CategoryIcon category={t.category} />
                        <div className="min-w-0">
                          <div className="truncate font-semibold">{t.name}</div>
                          <div className="truncate text-xs text-slate-400">{t.url || "—"}</div>
                        </div>
                      </div>
                    ),
                  },
                  {
                    key: "owner",
                    header: "Owner",
                    className: "col-span-3",
                    cell: (t) => (
                      <div className="min-w-0">
                        <div className="truncate text-sm text-slate-200">{t.owner_name || "—"}</div>
                        <div className="truncate text-xs text-slate-500">{t.owner_email || "No owner"}</div>
                      </div>
                    ),
                  },
                  {
                    key: "last",
                    header: "Last used",
                    className: "col-span-2",
                    cell: (t) => <div className="text-slate-200">{t.last_used_date || "—"}</div>,
                  },
                  {
                    key: "risk",
                    header: "Risk",
                    className: "col-span-1",
                    cell: (t) => <RiskBadge risk={t.derived_risk} />,
                  },
                  {
                    key: "status",
                    header: "Status",
                    className: "col-span-1",
                    cell: (t) => <StatusBadge status={t.derived_status} />,
                  },
                  {
                    key: "cost",
                    header: "Cost",
                    className: "col-span-1",
                    cell: (t) => <div className="text-slate-200">{formatMoney(t.cost_per_month)}</div>,
                  },
                  {
                    key: "actions",
                    header: "",
                    className: "col-span-12 md:col-span-12",
                    cell: (t) => (
                      <div className="flex gap-2 justify-end">
                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={() => toast.info(`Edit ${t.name} - Feature coming soon!`)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={() => {
                            if (confirm(`Delete ${t.name}?`)) {
                              toast.success(`${t.name} deleted! (Demo only)`);
                            }
                          }}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    ),
                  },
                ]}
                rows={filtered.map((t) => ({ ...t, __row: t }))}
                rowKey={(r) => r.id}
                emptyIcon={Boxes}
                emptyTitle="No tools"
                emptyBody="Add a tool or relax the filters."
              />
            )}

            {!isLoading && filtered.length ? (
              <div className="mt-3 grid gap-2">
                {filtered.map((t) => (
                  <div key={t.id} className="flex flex-wrap items-center justify-between gap-2 rounded-2xl border border-slate-800 bg-slate-950/30 px-4 py-3">
                    <div className="flex flex-wrap items-center gap-2">
                      <Pill tone="slate" icon={Boxes}>
                        {t.category}
                      </Pill>
                      <StatusBadge status={t.derived_status} />
                      <RiskBadge risk={t.derived_risk} />
                    </div>
                    <div className="flex gap-2">
                      <Button
                        size="sm"
                        variant="secondary"
                        onClick={() => {
                          setEditing(t);
                          setOpen(true);
                        }}
                      >
                        <Pencil className="h-4 w-4" />
                        Edit
                      </Button>
                      <Button
                        size="sm"
                        variant="danger"
                        onClick={() => {
                          if (window.confirm(`Delete ${t.name}?`)) muts.deleteTool.mutate(t.id);
                        }}
                      >
                        <Trash2 className="h-4 w-4" />
                        Delete
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            ) : null}
          </div>
        </CardBody>
      </Card>

      <Modal
        open={open}
        title={editing ? "Edit tool" : "Add Tool"}
        subtitle={t('tool_inventory_sub')}
        onClose={() => setOpen(false)}
      >
        <ToolForm
          initial={editing}
          employees={employees}
          onClose={() => setOpen(false)}
          onSubmit={(tool) => {
            if (editing) muts.updateTool.mutate({ id: editing.id, patch: tool });
            else muts.createTool.mutate(tool);
          }}
        />
      </Modal>
    </AppShell>
  );
}

function EmployeeForm({ initial, onSubmit, onClose }) {
  const { language } = useLang();
  const t = useTranslation(language);
  const [form, setForm] = useState(
    initial || {
      full_name: "",
      email: "",
      department: "engineering",
      role: "",
      status: "active",
      start_date: todayISO(),
      end_date: "",
    }
  );

  const canSubmit = form.full_name.trim() && form.email.trim();

  return (
    <form
      className="grid gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        if (!canSubmit) return;
        onSubmit({ ...form });
        onClose();
      }}
    >
      <div className="grid gap-3 md:grid-cols-2">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('full_name')}</div>
          <Input value={form.full_name} onChange={(e) => setForm((f) => ({ ...f, full_name: e.target.value }))} />
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Email</div>
          <Input value={form.email} onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))} />
        </div>
      </div>

      <div className="grid gap-3 md:grid-cols-3">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('department')}</div>
          <Select value={form.department} onChange={(e) => setForm((f) => ({ ...f, department: e.target.value }))}>
            {EMP_DEPARTMENTS.map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </Select>
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Role</div>
          <Input value={form.role} onChange={(e) => setForm((f) => ({ ...f, role: e.target.value }))} />
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Status</div>
          <Select value={form.status} onChange={(e) => setForm((f) => ({ ...f, status: e.target.value }))}>
            {['active','offboarding','offboarded'].map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </Select>
        </div>
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('start_date')}</div>
          <Input type="date" value={form.start_date} onChange={(e) => setForm((f) => ({ ...f, start_date: e.target.value }))} />
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">End date</div>
          <Input type="date" value={form.end_date} onChange={(e) => setForm((f) => ({ ...f, end_date: e.target.value }))} />
        </div>
      </div>

      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" disabled={!canSubmit}>
          <Check className="h-4 w-4" />
          Save
        </Button>
      </div>
    </form>
  );
}

function EmployeesPage() {
  const { data: db, isLoading } = useDbQuery();
  const { language, setLanguage } = useLang();
  const t = useTranslation(language);


  const muts = useDbMutations();

  const [q, setQ] = useState("");
  const [dept, setDept] = useState("");
  const [status, setStatus] = useState("");

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);

  const toolCounts = useMemo(() => {
    const m = new Map();
    (db?.access || []).forEach((a) => {
      if (a.status !== "active") return;
      m.set(a.employee_id, (m.get(a.employee_id) || 0) + 1);
    });
    return m;
  }, [db]);

  const employees = useMemo(() => {
    return (db?.employees || []).slice().sort((a, b) => a.full_name.localeCompare(b.full_name));
  }, [db]);

  const filtered = useMemo(() => {
    const s = q.trim().toLowerCase();
    return employees.filter((e) => {
      if (s && !`${e.full_name} ${e.email} ${e.role}`.toLowerCase().includes(s)) return false;
      if (dept && e.department !== dept) return false;
      if (status && e.status !== status) return false;
      return true;
    });
  }, [employees, q, dept, status]);

  return (
    <AppShell
      title={"Employees" || 'Employees'}
      right={
        <Button
          variant="secondary"
          onClick={() => {
            setEditing(null);
            setOpen(true);
          }}
        >
          <Plus className="h-4 w-4" />
          Add employee
        </Button>
      }
    >
      {/* Department Overview - Full Width */}
      <div className="mb-6">
        <h3 className="text-xl font-bold text-white mb-4">🏢 Department Overview</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {EMP_DEPARTMENTS.map(dept => {
            const deptEmployees = employees.filter(e => e.department === dept);
            const activeCount = deptEmployees.filter(e => e.status === 'active').length;
            return (
              <div key={dept} className="bg-slate-900 border border-slate-800 rounded-xl p-4 hover:border-blue-500/50 transition-colors cursor-pointer"
                   onClick={() => setDept(dept)}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-white font-semibold capitalize">{dept}</span>
                  <Users className="h-5 w-5 text-blue-400" />
                </div>
                <div className="text-3xl font-black text-white mb-1">{activeCount}</div>
                <div className="text-sm text-slate-400">active employees</div>
              </div>
            );
          })}
        </div>
      </div>

      <Card>
        <CardHeader title={t('employee_directory')} subtitle={t('employee_directory_sub')} right={<Pill tone="slate" icon={Users}>{employees.length} total</Pill>} />
        <CardBody>
          <div className="grid gap-3 md:grid-cols-12">
            <div className="md:col-span-6">
              <div className="relative">
                <Search className="pointer-events-none absolute left-3 top-3.5 h-4 w-4 text-slate-500" />
                <Input className="pl-9" placeholder={t('search_employees')} value={q} onChange={(e) => setQ(e.target.value)} />
              </div>
            </div>
            <div className="md:col-span-3">
              <Select value={dept} onChange={(e) => setDept(e.target.value)}>
                <option value="">{t('all_departments')}</option>
                {EMP_DEPARTMENTS.map((d) => (
                  <option key={d} value={d}>
                    {d}
                  </option>
                ))}
              </Select>
            </div>
            <div className="md:col-span-3">
              <Select value={status} onChange={(e) => setStatus(e.target.value)}>
                <option value="">{t('all_status')}</option>
                {['active','offboarding','offboarded'].map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </Select>
            </div>
          </div>

          <div className="mt-4">
            {isLoading ? (
              <div className="space-y-2">
                <SkeletonRow cols={6} />
                <SkeletonRow cols={6} />
                <SkeletonRow cols={6} />
              </div>
            ) : (
              <div className="grid gap-2">
                {filtered.length ? (
                  filtered.map((e) => (
                    <div key={e.id} className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                      <div className="min-w-0">
                        <div className="truncate text-sm font-semibold">{e.full_name}</div>
                        <div className="truncate text-xs text-slate-500">{e.email}</div>
                        <div className="mt-2 flex flex-wrap gap-2">
                          <Pill tone="slate" icon={Building2}>{e.department}</Pill>
                          <StatusBadge status={e.status} />
                          <Pill tone="blue" icon={GitMerge}>{toolCounts.get(e.id) || 0} tools</Pill>
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <Link to={`/offboarding?employee=${encodeURIComponent(e.id)}`}>
                          <Button size="sm" variant="secondary">
                            <UserMinus className="h-4 w-4" />
                            Offboarding
                          </Button>
                        </Link>
                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={() => {
                            setEditing(e);
                            setOpen(true);
                          }}
                        >
                          <Pencil className="h-4 w-4" />
                          Edit
                        </Button>
                        <Button
                          size="sm"
                          variant="danger"
                          onClick={() => {
                            if (window.confirm(`Delete ${e.full_name}?`)) muts.deleteEmployee.mutate(e.id);
                          }}
                        >
                          <Trash2 className="h-4 w-4" />
                          Delete
                        </Button>
                      </div>
                    </div>
                  ))
                ) : (
                  <EmptyState icon={Users} title={t('no_employees_found')} body="Add employees or relax the filters." />
                )}
              </div>
            )}
          </div>
        </CardBody>
      </Card>

      <Modal open={open} title={editing ? "Edit employee" : "Add employee"} subtitle={t('employee_directory_sub')} onClose={() => setOpen(false)}>
        <EmployeeForm
          initial={editing}
          onClose={() => setOpen(false)}
          onSubmit={(emp) => {
            if (editing) muts.updateEmployee.mutate({ id: editing.id, patch: emp });
            else muts.createEmployee.mutate(emp);
          }}
        />
      </Modal>
    </AppShell>
  );
}

function AccessForm({ initial, tools, employees, onSubmit, onClose }) {
  const { language } = useLang();
  const t = useTranslation(language);
  const [form, setForm] = useState(
    initial || {
      tool_id: tools[0]?.id || "",
      employee_id: employees[0]?.id || "",
      access_level: "viewer",
      granted_date: todayISO(),
      last_accessed_date: todayISO(),
      last_reviewed_date: todayISO(),
      status: "active",
      risk_flag: "none",
    }
  );

  useEffect(() => {
    const tool = tools.find((t) => t.id === form.tool_id);
    const emp = employees.find((e) => e.id === form.employee_id);
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setForm((f) => ({
      ...f,
      tool_name: tool?.name || "",
      employee_name: emp?.full_name || "",
      employee_email: emp?.email || "",
    }));
  }, [form.tool_id, form.employee_id, tools, employees]);

  const canSubmit = form.tool_id && form.employee_id;

  return (
    <form
      className="grid gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        if (!canSubmit) return;
        const tool = tools.find((t) => t.id === form.tool_id);
        const emp = employees.find((e) => e.id === form.employee_id);
        onSubmit({
          ...form,
          tool_name: tool?.name || form.tool_name || "",
          employee_name: emp?.full_name || form.employee_name || "",
          employee_email: emp?.email || form.employee_email || "",
        });
        onClose();
      }}
    >
      <div className="grid gap-3 md:grid-cols-2">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Tool</div>
          <Select value={form.tool_id} onChange={(e) => setForm((f) => ({ ...f, tool_id: e.target.value }))}>
            {tools.map((t) => (
              <option key={t.id} value={t.id}>
                {t.name}
              </option>
            ))}
          </Select>
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Employee</div>
          <Select value={form.employee_id} onChange={(e) => setForm((f) => ({ ...f, employee_id: e.target.value }))}>
            {employees.map((e) => (
              <option key={e.id} value={e.id}>
                {e.full_name} ({e.email})
              </option>
            ))}
          </Select>
        </div>
      </div>

      <div className="grid gap-3 md:grid-cols-3">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('access_level')}</div>
          <Select value={form.access_level} onChange={(e) => setForm((f) => ({ ...f, access_level: e.target.value }))}>
            {ACCESS_LEVEL.map((a) => (
              <option key={a} value={a}>
                {a}
              </option>
            ))}
          </Select>
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Status</div>
          <Select value={form.status} onChange={(e) => setForm((f) => ({ ...f, status: e.target.value }))}>
            {ACCESS_STATUS.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </Select>
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('risk_flag')}</div>
          <Select value={form.risk_flag} onChange={(e) => setForm((f) => ({ ...f, risk_flag: e.target.value }))}>
            {RISK_FLAG.map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </Select>
        </div>
      </div>

      <div className="grid gap-3 md:grid-cols-3">
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">Granted</div>
          <Input type="date" value={form.granted_date} onChange={(e) => setForm((f) => ({ ...f, granted_date: e.target.value }))} />
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('last_accessed')}</div>
          <Input type="date" value={form.last_accessed_date} onChange={(e) => setForm((f) => ({ ...f, last_accessed_date: e.target.value }))} />
        </div>
        <div>
          <div className="mb-1 text-xs font-semibold text-slate-400">{t('last_reviewed')}</div>
          <Input type="date" value={form.last_reviewed_date} onChange={(e) => setForm((f) => ({ ...f, last_reviewed_date: e.target.value }))} />
        </div>
      </div>

      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" disabled={!canSubmit}>
          <Check className="h-4 w-4" />
          Save
        </Button>
      </div>
    </form>
  );
}

function AccessPage() {
  const { data: db, isLoading } = useDbQuery();
  const [language] = useState(() => localStorage.getItem('language') || 'en');
  const t = useTranslation(language);

  const derived = useMemo(() => {
    if (!db) return null;
    
    const employeesById = Object.fromEntries(db.employees.map(e => [e.id, e]));
    const toolsById = Object.fromEntries(db.tools.map(t => [t.id, t]));
    
    const access = db.access.map(a => ({
      ...a,
      employee: employeesById[a.employee_id],
      tool: toolsById[a.tool_id],
      risk: computeAccessDerivedRiskFlag(a, employeesById, toolsById)
    }));
    
    const highRisk = access.filter(a => a.risk === 'former_employee' || a.risk === 'excessive_admin');
    const needsReview = access.filter(a => a.risk === 'needs_review');
    
    return { access, highRisk, needsReview };
  }, [db]);

  if (isLoading || !derived) return <div className="flex items-center justify-center h-screen"><div className="text-white">{t('loading')}</div></div>;

  return (
    <AppShell title={"Access Map" || 'Access Map'}>
      <div className="space-y-6">
        
        {/* KPI Cards - Full Width */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-400 text-sm">{t('total_access')}</span>
              <GitMerge className="h-5 w-5 text-blue-400" />
            </div>
            <div className="text-4xl font-black text-white mb-1">{derived.access.length}</div>
            <div className="text-sm text-slate-400">{t('active_permissions')}</div>
          </div>
          
          <div className="bg-gradient-to-br from-rose-500/10 to-rose-600/10 border border-rose-500/20 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-400 text-sm">{t('high_risk')}</span>
              <AlertTriangle className="h-5 w-5 text-rose-400" />
            </div>
            <div className="text-4xl font-black text-rose-400 mb-1">{derived.highRisk.length}</div>
            <div className="text-sm text-slate-400">{t('urgent_attention')}</div>
          </div>
          
          <div className="bg-gradient-to-br from-amber-500/10 to-amber-600/10 border border-amber-500/20 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-400 text-sm">{t('needs_review')}</span>
              <AlertTriangle className="h-5 w-5 text-amber-400" />
            </div>
            <div className="text-4xl font-black text-amber-400 mb-1">{derived.needsReview.length}</div>
            <div className="text-sm text-slate-400">{t('needs_review')}</div>
          </div>
          
          <div className="bg-gradient-to-br from-emerald-500/10 to-emerald-600/10 border border-emerald-500/20 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-400 text-sm">{t('clean_access')}</span>
              <CheckCircle className="h-5 w-5 text-emerald-400" />
            </div>
            <div className="text-4xl font-black text-emerald-400 mb-1">
              {derived.access.length - derived.highRisk.length - derived.needsReview.length}
            </div>
            <div className="text-sm text-slate-400">{t('no_issues_detected')}</div>
          </div>
        </div>

        {/* Urgent Issues Section - Full Width */}
        {derived.highRisk.length > 0 && (
          <div className="bg-rose-500/10 border border-rose-500/20 rounded-2xl p-6">
            <div className="flex items-center gap-3 mb-4">
              <AlertTriangle className="h-6 w-6 text-rose-400" />
              <h2 className="text-xl font-bold text-white">🚨 Urgent Security Issues</h2>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {derived.highRisk.slice(0, 6).map((access, idx) => (
                <div key={idx} className="bg-slate-900/50 border border-rose-500/30 rounded-xl p-4">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1">
                      <div className="text-white font-semibold">{access.employee?.full_name || 'Unknown'}</div>
                      <div className="text-sm text-slate-400">{access.tool?.name || access.tool_name}</div>
                    </div>
                    <span className="px-2 py-1 bg-rose-500/20 text-rose-400 text-xs font-bold rounded-full">
                      {access.access_level}
                    </span>
                  </div>
                  <div className="text-sm text-rose-300 mb-3">
                    {access.risk === 'former_employee' ? '⚠️ Ex-employee still has access' : '⚠️ Excessive admin access'}
                  </div>
                  <button onClick={() => { if(confirm("Revoke access for this user?")) { toast.success("Access revoked! (Demo)"); } }} className="w-full px-4 py-2 bg-rose-600 hover:bg-rose-500 text-white rounded-lg text-sm font-semibold transition-colors">
                    Revoke Access
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Access Overview Table - Full Width */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
          <div className="p-6 border-b border-slate-800">
            <h2 className="text-xl font-bold text-white">{t('all_permissions')}</h2>
            <p className="text-sm text-slate-400 mt-1">{t('complete_access_overview')}</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-950/50">
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Employee</th>
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Tool</th>
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Access Level</th>
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Status</th>
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Risk</th>
                  <th className="text-right py-4 px-6 text-sm font-semibold text-slate-400">Actions</th>
                </tr>
              </thead>
              <tbody>
                {derived.access.slice(0, 20).map((access, idx) => (
                  <tr key={idx} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center text-white font-bold text-sm">
                          {access.employee?.full_name?.charAt(0) || '?'}
                        </div>
                        <div>
                          <div className="text-white font-medium">{access.employee?.full_name || 'Unknown'}</div>
                          <div className="text-xs text-slate-500">{access.employee?.department}</div>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-6 text-white">{access.tool?.name || access.tool_name}</td>
                    <td className="py-4 px-6">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        access.access_level === 'admin' 
                          ? 'bg-purple-500/20 text-purple-400 border border-purple-500/30' 
                          : 'bg-blue-500/20 text-blue-400 border border-blue-500/30'
                      }`}>
                        {access.access_level}
                      </span>
                    </td>
                    <td className="py-4 px-6">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        access.status === 'active'
                          ? 'bg-emerald-500/20 text-emerald-400'
                          : 'bg-slate-500/20 text-slate-400'
                      }`}>
                        {access.status}
                      </span>
                    </td>
                    <td className="py-4 px-6">
                      {access.risk !== 'none' ? (
                        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                          access.risk === 'former_employee' || access.risk === 'excessive_admin'
                            ? 'bg-rose-500/20 text-rose-400'
                            : 'bg-amber-500/20 text-amber-400'
                        }`}>
                          {access.risk.replace('_', ' ')}
                        </span>
                      ) : (
                        <span className="text-slate-500 text-xs">{t('no_issues')}</span>
                      )}
                    </td>
                    <td className="py-4 px-6 text-right">
                      <button onClick={() => toast.info("Access management panel coming soon!")} className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 text-white rounded-lg text-xs font-semibold transition-colors">
                        Manage
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </AppShell>
  );
}


function OffboardingPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db, isLoading } = useDbQuery();
  const muts = useDbMutations();
  const nav = useNavigate();
  const location = useLocation();

  const params = new URLSearchParams(location.search);
  const pre = params.get("employee") || "";

  const employees = useMemo(() => db?.employees || [], [db]);
  const access = db?.access || [];

  const [tab, setTab] = useState("queue"); // "queue" | "history"
  const [employeeId, setEmployeeId] = useState(pre || employees[0]?.id || "");

  useEffect(() => {
    if (!employeeId && employees[0]?.id) setEmployeeId(employees[0].id);
  }, [employeeId, employees]);

  const employee = employees.find((e) => e.id === employeeId);
  const activeRecords = access.filter((a) => a.employee_id === employeeId && a.status === "active");
  const [checked, setChecked] = useState({});

  const revokeOne = (id) => muts.updateAccess.mutate({ id, patch: { status: "revoked" } });
  const revokeAll = () => {
    activeRecords.forEach((r) => revokeOne(r.id));
    muts.updateEmployee.mutate({
      id: employeeId,
      patch: { status: "offboarded", end_date: employee?.end_date || todayISO() },
    });
  };

  // "Next to be offboarded" — employees with offboarding status or end_date coming up
  const upcoming = useMemo(() => {
    if (!db) return [];
    return db.employees
      .filter((e) => e.status === "offboarding" || (e.end_date && e.end_date >= todayISO() && e.status !== "offboarded"))
      .sort((a, b) => (a.end_date || "9999") > (b.end_date || "9999") ? 1 : -1)
      .slice(0, 5);
  }, [db]);

  // Offboarded employees — history
  const offboarded = useMemo(() => {
    if (!db) return [];
    return db.employees
      .filter((e) => e.status === "offboarded")
      .sort((a, b) => (a.end_date || "") < (b.end_date || "") ? 1 : -1);
  }, [db]);

  const daysUntil = (dateStr) => {
    if (!dateStr) return null;
    const diff = Math.ceil((new Date(dateStr) - new Date()) / 86400000);
    return diff;
  };

  return (
    <AppShell
      title={"Offboarding" || 'Offboarding'}
      right={
        <div className="flex gap-2">
          <Button variant="secondary" onClick={() => nav("/employees")}>
            <Users className="h-4 w-4" /> Employees
          </Button>
        </div>
      }
    >
      <div className="grid gap-5 lg:grid-cols-12">


        {/* Pipeline Stats - Full Width */}
        <div className="lg:col-span-12 mb-5">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-2xl p-6">
              <div className="text-sm text-slate-400 mb-2">📋 Pending</div>
              <div className="text-4xl font-black text-blue-400">
                {upcoming.length}
              </div>
              <div className="text-sm text-slate-400 mt-2">{t('ready_to_offboard')}</div>
            </div>
            
            <div className="bg-gradient-to-br from-amber-500/10 to-amber-600/10 border border-amber-500/20 rounded-2xl p-6">
              <div className="text-sm text-slate-400 mb-2">🔄 In Progress</div>
              <div className="text-4xl font-black text-amber-400">
                {employees.filter(e => e.status === 'offboarding').length}
              </div>
              <div className="text-sm text-slate-400 mt-2">{t('being_processed')}</div>
            </div>
            
            <div className="bg-gradient-to-br from-emerald-500/10 to-emerald-600/10 border border-emerald-500/20 rounded-2xl p-6">
              <div className="text-sm text-slate-400 mb-2">✅ Completed</div>
              <div className="text-4xl font-black text-emerald-400">
                {offboarded.length}
              </div>
              <div className="text-sm text-slate-400 mt-2">{t('this_month')}</div>
            </div>
            
            <div className="bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-500/20 rounded-2xl p-6">
              <div className="text-sm text-slate-400 mb-2">⏱️ Avg Time</div>
              <div className="text-4xl font-black text-purple-400">7</div>
              <div className="text-sm text-slate-400 mt-2">{t('days_to_complete')}</div>
            </div>
          </div>
        </div>

        {/* LEFT: upcoming queue + revoke panel */}
        <div className="lg:col-span-8 space-y-5">

          {/* Tab bar */}
          <div className="flex gap-1 rounded-xl border border-slate-800 bg-slate-900/60 p-1 w-fit">
            {[
              { id: "queue",   label: "Offboarding Queue" },
              { id: "history", label: "Offboarded History" },
            ].map(({ id, label }) => (
              <button
                key={id}
                onClick={() => setTab(id)}
                className={cx(
                  "px-4 py-2 rounded-lg text-sm font-medium transition-colors",
                  tab === id
                    ? "bg-blue-600 text-white shadow"
                    : "text-slate-400 hover:text-slate-200"
                )}
              >
                {label}
              </button>
            ))}
          </div>

          {tab === "queue" && (
            <Card>
              <CardHeader
                title={t('next_offboard')}
                subtitle={t('offboarding_pipeline_sub')}
              />
              <CardBody>
                {isLoading || !db ? (
                  <SkeletonRow cols={5} />
                ) : upcoming.length === 0 ? (
                  <EmptyState icon={UserMinus} title={t('no_offboardings')} body="No employees flagged for offboarding." />
                ) : (
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-slate-800 bg-slate-950/60">
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Employee</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">{t('department')}</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">End Date</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Days Left</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Status</th>
                          <th className="px-4 py-3 text-right text-slate-400 font-semibold">Action</th>
                        </tr>
                      </thead>
                      <tbody>
                        {upcoming.map((e) => {
                          const days = daysUntil(e.end_date);
                          const urgent = days !== null && days <= 3;
                          return (
                            <tr key={e.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                              <td className="px-4 py-3">
                                <div className="font-medium text-white">{e.full_name}</div>
                                <div className="text-xs text-slate-500">{e.email}</div>
                              </td>
                              <td className="px-4 py-3 text-slate-400 capitalize">{e.department || "—"}</td>
                              <td className="px-4 py-3 text-slate-300">{e.end_date || "—"}</td>
                              <td className="px-4 py-3">
                                {days !== null ? (
                                  <span className={cx(
                                    "inline-flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-full",
                                    urgent ? "bg-rose-500/20 text-rose-400" : days <= 7 ? "bg-amber-500/20 text-amber-400" : "bg-slate-700 text-slate-300"
                                  )}>
                                    {days === 0 ? "Today" : days < 0 ? `${Math.abs(days)}d overdue` : `${days}d`}
                                  </span>
                                ) : "—"}
                              </td>
                              <td className="px-4 py-3">
                                <span className={cx(
                                  "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold",
                                  e.status === "offboarding" ? "bg-amber-500/20 text-amber-400" : "bg-blue-500/20 text-blue-400"
                                )}>
                                  {e.status}
                                </span>
                              </td>
                              <td className="px-4 py-3 text-right">
                                <Button size="sm" variant="secondary" onClick={() => { setEmployeeId(e.id); setTab("revoke"); }}>
                                  Revoke access
                                </Button>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                )}
              </CardBody>
            </Card>
          )}

          {tab === "history" && (
            <Card>
              <CardHeader
                title="Offboarded employees"
                subtitle="Complete history with timestamps"
                right={<Pill tone="slate">{offboarded.length} total</Pill>}
              />
              <CardBody>
                {isLoading || !db ? (
                  <SkeletonRow cols={5} />
                ) : offboarded.length === 0 ? (
                  <EmptyState icon={UserMinus} title="No offboarded employees" body="Employees you offboard will appear here." />
                ) : (
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-slate-800 bg-slate-950/60">
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Employee</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">{t('department')}</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Role</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">{t('date_offboarded')}</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">{t('access_revoked')}</th>
                        </tr>
                      </thead>
                      <tbody>
                        {offboarded.map((e) => {
                          const revokedCount = access.filter(a => a.employee_id === e.id && a.status === "revoked").length;
                          const remainingCount = access.filter(a => a.employee_id === e.id && a.status === "active").length;
                          return (
                            <tr key={e.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                              <td className="px-4 py-3">
                                <div className="font-medium text-white">{e.full_name}</div>
                                <div className="text-xs text-slate-500">{e.email}</div>
                              </td>
                              <td className="px-4 py-3 text-slate-400 capitalize">{e.department || "—"}</td>
                              <td className="px-4 py-3 text-slate-400">{e.role || "—"}</td>
                              <td className="px-4 py-3">
                                <div className="text-slate-300">{e.end_date || "—"}</div>
                                {e.end_date && (
                                  <div className="text-xs text-slate-500">
                                    {new Date(e.end_date).toLocaleDateString(language, { weekday: "short", year: "numeric", month: "short", day: "numeric" })}
                                  </div>
                                )}
                              </td>
                              <td className="px-4 py-3">
                                <div className="flex items-center gap-2">
                                  {revokedCount > 0 && (
                                    <span className="text-xs text-emerald-400 font-semibold">{revokedCount} revoked</span>
                                  )}
                                  {remainingCount > 0 && (
                                    <span className="text-xs text-rose-400 font-semibold">{remainingCount} still active ⚠️</span>
                                  )}
                                  {revokedCount === 0 && remainingCount === 0 && (
                                    <span className="text-xs text-slate-500">{t('no_records')}</span>
                                  )}
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                )}
              </CardBody>
            </Card>
          )}

          {/* Revoke panel — always visible below tabs */}
          <Card>
            <CardHeader title={t('revoke_access') || "Revoke access"} subtitle="Select employee and revoke active access" />
            <CardBody>
              {isLoading || !db ? (
                <SkeletonRow cols={6} />
              ) : (
                <div className="grid gap-5">
                  <div className="grid gap-3 md:grid-cols-2">
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">{t('select_employee')}</div>
                      <Select value={employeeId} onChange={(e) => setEmployeeId(e.target.value)}>
                        {employees.map((e) => (
                          <option key={e.id} value={e.id}>
                            {e.full_name} — {e.status}
                          </option>
                        ))}
                      </Select>
                    </div>
                    <div className="flex items-end justify-end gap-2">
                      <Button variant="danger" disabled={!activeRecords.length} onClick={revokeAll}>
                        <BadgeX className="h-4 w-4" /> Revoke All ({activeRecords.length})
                      </Button>
                    </div>
                  </div>
                  {activeRecords.length ? (
                    <div className="grid gap-2">
                      {activeRecords.map((r) => (
                        <div key={r.id} className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                          <div className="min-w-0">
                            <div className="text-sm font-semibold">{r.tool_name}</div>
                            <div className="mt-2 flex flex-wrap gap-2">
                              <AccessLevelBadge level={r.access_level} />
                              <Pill tone="slate" icon={CalendarClock}>Granted: {r.granted_date || "—"}</Pill>
                            </div>
                          </div>
                          <div className="flex items-center gap-2">
                            <label className="flex items-center gap-2 text-xs text-slate-400">
                              <input type="checkbox" checked={Boolean(checked[r.id])}
                                onChange={(e) => setChecked((m) => ({ ...m, [r.id]: e.target.checked }))} />
                              Verified
                            </label>
                            <Button size="sm" variant="danger" onClick={() => revokeOne(r.id)}>
                              <BadgeX className="h-4 w-4" /> Revoke
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <EmptyState icon={UserMinus} title="No active access" body="This employee has no active access records." />
                  )}
                </div>
              )}
            </CardBody>
          </Card>
        </div>

        {/* RIGHT: summary stats */}
        <div className="lg:col-span-4 space-y-5">
          <Card>
            <CardHeader title="Summary" subtitle="Offboarding overview" />
            <CardBody>
              <div className="space-y-3">
                {[
                  { label: "Pending offboarding",  value: upcoming.length,                          color: "text-amber-400"  },
                  { label: "Offboarded total",      value: offboarded.length,                        color: "text-slate-300"  },
                  { label: "Active employees",      value: employees.filter(e => e.status === "active").length, color: "text-emerald-400" },
                  { label: "Access records at risk",value: access.filter(a => {
                      const emp = employees.find(e => e.id === a.employee_id);
                      return emp?.status === "offboarded" && a.status === "active";
                    }).length,                                                                        color: "text-rose-400"   },
                ].map(({ label, value, color }) => (
                  <div key={label} className="flex items-center justify-between rounded-xl border border-slate-800 bg-slate-950/30 px-4 py-3">
                    <span className="text-sm text-slate-400">{label}</span>
                    <span className={cx("text-lg font-bold", color)}>{value}</span>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardHeader title="Offboarding checklist" subtitle="Best practices" />
            <CardBody>
              <div className="space-y-2 text-sm text-slate-400">
                {[
                  "Revoke all SaaS tool access",
                  "Remove from SSO / identity provider",
                  "Transfer ownership of shared docs",
                  "Recover company devices",
                  "Archive or reassign email",
                  "Remove from Slack / Teams",
                  "Cancel user-specific subscriptions",
                ].map((item, i) => (
                  <div key={i} className="flex items-start gap-2">
                    <div className="mt-0.5 h-4 w-4 rounded border border-slate-600 flex-shrink-0" />
                    <span>{item}</span>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>
        </div>
      </div>
    </AppShell>
  );
}

function SetupConnectionsHub() {
  const { language } = useLang();
  const t = useTranslation(language);
  const [setupTab, setSetupTab] = useState('integrations');
  const TABS = [
    { id: 'integrations', label: '🔌 Integrations',  desc: 'Connect your tools' },
    { id: 'import',       label: '📥 Import Data',    desc: 'CSV & data import' },
  ];
  return (
    <AppShell title={t('setup_title')}
      right={
        <div className="flex gap-1 p-1 bg-slate-900 rounded-xl border border-slate-800">
          {TABS.map(tab => (
            <button key={tab.id} onClick={() => setSetupTab(tab.id)}
              className={"px-3 py-1.5 rounded-lg text-xs font-semibold transition-all " + (setupTab === tab.id ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white')}>
              {tab.label}
            </button>
          ))}
        </div>
      }
    >
      {setupTab === 'integrations' && (
        <div className="p-6">
          <div className="mb-6">
            <h2 className="text-2xl font-black text-white mb-1">🔌 Integrations</h2>
            <p className="text-slate-400">Connect SaasGuard to your tools for automatic discovery and user sync</p>
          </div>
          <IntegrationConnectors />
        </div>
      )}
      {setupTab === 'import' && <ImportWizard />}
    </AppShell>
  );
}

function ImportWizard() {
  const { language } = useLang();
  const t = useTranslation(language);
  const muts = useDbMutations();
  const [step, setStep] = useState(0);  // 0=choose, 1=template, 2=upload, 3=done
  const [kind, setKind] = useState(null);
  const [text, setText] = useState('');
  const [imported, setImported] = useState(null);
  const [importing, setImporting] = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const [animDir, setAnimDir] = useState('forward');

  const goTo = (n) => { setAnimDir(n > step ? 'forward' : 'back'); setStep(n); };

  const KINDS = {
    tools:     { icon: '🛠️', label: 'SaaS Tools',     desc: 'Name, cost, owner, category — your software inventory', example: 'Slack, Figma, GitHub, Notion…', color: 'emerald' },
    employees: { icon: '👥', label: 'Employees',       desc: 'Full name, email, department, role, status', example: '230 staff across 8 departments',   color: 'blue' },
    access:    { icon: '🔑', label: 'Access Records',  desc: 'Who has access to what tool at what level',  example: '1,200 tool-to-person mappings',     color: 'violet' },
  };

  const TEMPLATES = {
    tools:     'name,category,owner_email,owner_name,criticality,url,status,cost_per_month\nSlack,communication,jane@co.com,Jane Smith,high,https://slack.com,active,299\nNotion,productivity,tom@co.com,Tom Brown,medium,https://notion.so,active,120\nFigma,design,amy@co.com,Amy Lee,high,https://figma.com,active,75',
    employees: 'full_name,email,department,role,status,start_date\nJane Smith,jane@co.com,Engineering,Engineer,active,2025-01-01\nTom Brown,tom@co.com,Marketing,Manager,active,2024-06-15\nAmy Lee,amy@co.com,Design,Designer,active,2025-03-01',
    access:    'tool_name,employee_email,access_level,granted_date,status\nSlack,jane@co.com,admin,2025-01-01,active\nNotion,tom@co.com,editor,2025-02-01,active\nFigma,amy@co.com,owner,2025-03-01,active',
  };

  const COLS     = { tools: ['name','category','status','criticality','cost_per_month','owner_name'], employees: ['full_name','email','department','role','status'], access: ['tool_name','employee_email','access_level','status'] };
  const REQUIRED = { tools: ['name'], employees: ['full_name','email'], access: ['tool_name','employee_email'] };

  const liveRows = React.useMemo(() => { if (!text.trim()) return []; try { return parseCsv(text); } catch { return []; } }, [text]);
  const cols = kind ? COLS[kind] : [];
  const isRowValid = (row) => kind ? REQUIRED[kind].every(k => row[k]?.trim()) : false;
  const validCount   = liveRows.filter(isRowValid).length;
  const invalidCount = liveRows.length - validCount;

  const handleFileUpload = (file) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (e) => { setText(e.target.result); goTo(2); };
    reader.readAsText(file);
  };

  const handleImport = async () => {
    if (!liveRows.length || !kind) return;
    setImporting(true);
    try {
      await muts.bulkImport.mutateAsync({ kind, records: liveRows });
      setImported({ count: liveRows.length, kind });
      goTo(3);
    } finally { setImporting(false); }
  };

  const reset = () => { setStep(0); setKind(null); setText(''); setImported(null); };

  const STEP_LABELS = ['Choose type', 'Get template', 'Upload & preview', 'Done'];

  // Smart column detector — scores each kind against pasted headers
  const detectKind = (csvText) => {
    const firstLine = csvText.split('\n')[0].toLowerCase();
    const scores = { tools: 0, employees: 0, access: 0 };
    if (firstLine.includes('name') && !firstLine.includes('full')) scores.tools += 2;
    if (firstLine.includes('cost') || firstLine.includes('category') || firstLine.includes('url')) scores.tools += 2;
    if (firstLine.includes('full_name') || firstLine.includes('department') || firstLine.includes('email')) scores.employees += 2;
    if (firstLine.includes('role') || firstLine.includes('start_date')) scores.employees += 1;
    if (firstLine.includes('tool_name') || firstLine.includes('access_level') || firstLine.includes('granted')) scores.access += 2;
    if (firstLine.includes('employee_email')) scores.access += 2;
    const best = Object.entries(scores).sort((a,b) => b[1]-a[1])[0];
    return best[1] > 0 ? best[0] : null;
  };

  const handlePaste = (val) => {
    setText(val);
    const detected = detectKind(val);
    if (detected && detected !== kind) {
      setKind(detected);
      toast.success('Detected type: ' + KINDS[detected].label + ' — smart detection! ✨');
    }
  };

  return (
    <div className="p-6 max-w-3xl mx-auto">
      {/* Animated step progress */}
      <div className="flex items-center mb-8">
        {STEP_LABELS.map((label, i) => {
          const done = step > i;
          const active = step === i;
          return (
            <React.Fragment key={label}>
              <div className="flex flex-col items-center">
                <div className={
                  "h-10 w-10 rounded-full flex items-center justify-center font-bold text-sm transition-all duration-300 " +
                  (done ? 'bg-emerald-500 text-white scale-90' : active ? 'bg-blue-600 text-white ring-4 ring-blue-600/25 scale-110' : 'bg-slate-800 text-slate-500')
                }>
                  {done ? '✓' : i + 1}
                </div>
                <div className={"text-[10px] mt-1.5 font-semibold whitespace-nowrap transition-colors " + (active ? 'text-white' : done ? 'text-emerald-400' : 'text-slate-600')}>{label}</div>
              </div>
              {i < STEP_LABELS.length - 1 && (
                <div className={"flex-1 h-0.5 mx-3 mb-5 transition-all duration-500 " + (step > i ? 'bg-emerald-500' : 'bg-slate-800')} />
              )}
            </React.Fragment>
          );
        })}
      </div>

      {/* STEP 0 — Choose what to import */}
      {step === 0 && (
        <div className="space-y-4">
          <div className="rounded-2xl bg-gradient-to-r from-blue-500/10 to-emerald-500/5 border border-blue-500/20 p-5">
            <div className="flex items-start gap-3">
              <span className="text-2xl mt-0.5">💡</span>
              <div>
                <div className="font-bold text-white mb-1">Fastest way to get started</div>
                <p className="text-sm text-slate-400">Import your existing data in under 5 minutes. We provide CSV templates for each type — just fill them in, save, and upload. No special format required.</p>
              </div>
            </div>
          </div>
          <div>
            <h2 className="text-xl font-bold text-white mb-1">{t('what_importing')}</h2>
            <p className="text-slate-400 text-sm mb-4">Each type has its own template with the correct columns pre-configured.</p>
            <div className="grid gap-3">
              {Object.entries(KINDS).map(([id, meta]) => (
                <button key={id} onClick={() => { setKind(id); goTo(1); }}
                  className={"flex items-center gap-4 p-5 rounded-2xl border transition-all text-left hover:scale-[1.01] active:scale-[0.99] " + (kind === id ? 'border-' + meta.color + '-500/40 bg-' + meta.color + '-500/5' : 'border-slate-800 bg-slate-900/40 hover:border-slate-700')}>
                  <div className="text-4xl flex-shrink-0">{meta.icon}</div>
                  <div className="flex-1 min-w-0">
                    <div className="font-bold text-white text-lg">{meta.label}</div>
                    <div className="text-sm text-slate-400">{meta.desc}</div>
                    <div className="text-xs text-slate-600 mt-0.5">e.g. {meta.example}</div>
                  </div>
                  <ChevronRight className="h-5 w-5 text-slate-600 flex-shrink-0" />
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* STEP 1 — Template */}
      {step === 1 && kind && (
        <div className="space-y-5">
          <button onClick={() => goTo(0)} className="text-sm text-slate-500 hover:text-slate-300 flex items-center gap-1">← Back</button>
          <div className="flex items-center gap-3">
            <span className="text-4xl">{KINDS[kind].icon}</span>
            <div>
              <h2 className="text-xl font-bold text-white">Import {KINDS[kind].label}</h2>
              <p className="text-slate-400 text-sm">{KINDS[kind].desc}</p>
            </div>
          </div>

          {/* Column legend */}
          <Card className="p-5">
            <div className="text-xs font-bold text-slate-500 uppercase tracking-wide mb-3">{t('template_columns')}</div>
            <div className="flex flex-wrap gap-2 mb-3">
              {TEMPLATES[kind].split('\n')[0].split(',').map(col => (
                <span key={col} className={"text-xs px-2.5 py-1 rounded-full font-mono " + (REQUIRED[kind].includes(col) ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/20' : 'bg-slate-800 text-slate-400')}>
                  {col}{REQUIRED[kind].includes(col) ? ' *' : ''}
                </span>
              ))}
            </div>
            <div className="text-xs text-slate-600">* = required. All other columns are optional but recommended.</div>
          </Card>

          {/* Sample data preview */}
          <Card className="p-0 overflow-hidden">
            <div className="px-5 py-3 border-b border-slate-800 flex items-center justify-between">
              <div className="text-sm font-bold text-white">{t('preview_title')}</div>
              <span className="text-xs text-slate-500">This is what your CSV should look like</span>
            </div>
            <div className="overflow-x-auto">
              <table className="text-xs w-full">
                <thead>
                  <tr className="border-b border-slate-800 bg-slate-950/60">
                    {TEMPLATES[kind].split('\n')[0].split(',').map(col => (
                      <th key={col} className="text-left py-2.5 px-4 text-slate-500 font-semibold whitespace-nowrap">{col}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {TEMPLATES[kind].split('\n').slice(1).map((row, i) => (
                    <tr key={i} className="border-b border-slate-800/50 hover:bg-slate-800/30">
                      {row.split(',').map((cell, j) => (
                        <td key={j} className="py-2.5 px-4 text-slate-300 whitespace-nowrap">{cell}</td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>

          <div className="grid sm:grid-cols-2 gap-3">
            <button onClick={() => downloadText(kind + '_template.csv', TEMPLATES[kind])}
              className="flex items-center justify-center gap-2 py-3.5 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-bold transition-all active:scale-[0.98]">
              <Download className="h-4 w-4" /> Download CSV Template
            </button>
            <button onClick={() => { setText(TEMPLATES[kind]); goTo(2); }}
              className="flex items-center justify-center gap-2 py-3.5 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold transition-all text-slate-300">
              Use sample data →
            </button>
          </div>
          <div className="text-center">
            <button onClick={() => goTo(2)} className="text-sm text-emerald-400 hover:underline">I already have a file — skip to upload →</button>
          </div>
        </div>
      )}

      {/* STEP 2 — Upload */}
      {step === 2 && (
        <div className="space-y-4">
          <button onClick={() => goTo(kind ? 1 : 0)} className="text-sm text-slate-500 hover:text-slate-300 flex items-center gap-1">← Back</button>

          {/* Smart detection notice */}
          {kind && (
            <div className="flex items-center gap-2 text-xs text-slate-500 bg-slate-900/60 border border-slate-800 rounded-xl px-4 py-2.5">
              <span className="text-lg">{KINDS[kind].icon}</span>
              <span>Importing as <span className="text-white font-semibold">{KINDS[kind].label}</span></span>
              <button onClick={() => goTo(0)} className="ml-auto text-blue-400 hover:text-blue-300 font-semibold">{t('back')}</button>
            </div>
          )}

          <Card className="p-6">
            <h2 className="text-xl font-bold text-white mb-1">{t('upload')}</h2>
            <p className="text-slate-400 text-sm mb-5">Drag & drop a CSV, or paste the contents below. Type is auto-detected from column headers.</p>

            <div
              onDragOver={e => { e.preventDefault(); setDragOver(true); }}
              onDragLeave={() => setDragOver(false)}
              onDrop={e => { e.preventDefault(); setDragOver(false); handleFileUpload(e.dataTransfer.files[0]); }}
              onClick={() => document.getElementById('csv-import-input').click()}
              className={"relative rounded-2xl border-2 border-dashed flex flex-col items-center justify-center py-14 mb-5 cursor-pointer transition-all duration-200 " + (dragOver ? 'border-emerald-400 bg-emerald-500/10 scale-[1.01]' : 'border-slate-700 hover:border-slate-500 bg-slate-900/40')}
            >
              <input id="csv-import-input" type="file" accept=".csv,.txt" className="hidden" onChange={e => handleFileUpload(e.target.files[0])} />
              <div className={"text-5xl mb-3 transition-all " + (dragOver ? 'scale-125' : '')}>{dragOver ? '📂' : '📁'}</div>
              <div className={"font-bold text-lg transition-colors " + (dragOver ? 'text-emerald-400' : 'text-slate-300')}>
                {dragOver ? 'Release to upload' : 'Drop your CSV here'}
              </div>
              <div className="text-sm text-slate-500 mt-1">or click to browse your files</div>
              <div className="mt-4 flex items-center gap-2 text-xs text-slate-700">
                <span className="px-2 py-0.5 bg-slate-800 rounded font-mono">CSV</span>
                <span className="px-2 py-0.5 bg-slate-800 rounded font-mono">TXT</span>
              </div>
            </div>

            <div className="relative">
              <div className="absolute inset-x-0 -top-2.5 flex justify-center">
                <span className="text-xs text-slate-600 bg-slate-950 px-3">or paste CSV directly — type auto-detected ✨</span>
              </div>
              <textarea rows={4}
                className="w-full bg-slate-900 border border-slate-700 rounded-xl p-3 font-mono text-xs text-slate-300 outline-none focus:border-emerald-500 transition-colors resize-none"
                value={text} onChange={e => handlePaste(e.target.value)}
                placeholder={"Paste CSV here — column headers are auto-detected…"} />
            </div>

            {liveRows.length > 0 && (
              <div className="flex items-center gap-3 mt-3 text-sm flex-wrap">
                <span className="text-slate-500">{liveRows.length} rows detected</span>
                {validCount > 0 && <span className="text-emerald-400 font-semibold">✓ {validCount} valid</span>}
                {invalidCount > 0 && <span className="text-rose-400 font-semibold">✗ {invalidCount} with errors</span>}
              </div>
            )}
          </Card>

          {liveRows.length > 0 && kind && (
            <Card>
              <CardHeader title={t('preview_title')} subtitle={liveRows.length + " rows — review before importing"}
                right={<div className="flex gap-2">{validCount > 0 && <Pill tone="green">✓ {validCount} valid</Pill>}{invalidCount > 0 && <Pill tone="rose">✗ {invalidCount} errors</Pill>}</div>}
              />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-slate-800 bg-slate-950/60">
                        <th className="px-3 py-2 text-left text-slate-500 font-semibold w-8">#</th>
                        {cols.map(c => <th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">{c.replace(/_/g,' ')}</th>)}
                        <th className="px-3 py-2 text-left text-slate-500">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {liveRows.slice(0, 10).map((row, i) => {
                        const valid = isRowValid(row);
                        return (
                          <tr key={i} className={"border-b border-slate-800/60 " + (valid ? '' : 'bg-rose-500/5')}>
                            <td className="px-3 py-2 text-slate-500">{i+1}</td>
                            {cols.map(c => (
                              <td key={c} className={"px-3 py-2 " + (!row[c]?.trim() && REQUIRED[kind].includes(c) ? 'text-rose-400' : 'text-slate-300')}>
                                {row[c] || <span className="text-slate-700 italic">—</span>}
                              </td>
                            ))}
                            <td className="px-3 py-2">
                              {valid
                                ? <span className="text-emerald-400 flex items-center gap-1"><Check className="h-3 w-3" /> OK</span>
                                : <span className="text-rose-400 flex items-center gap-1"><AlertTriangle className="h-3 w-3" /> Missing</span>
                              }
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                  {liveRows.length > 10 && <div className="text-center text-xs text-slate-600 py-2">Showing 10 of {liveRows.length} rows</div>}
                </div>
                <div className="flex items-center justify-between mt-4">
                  <div className="text-xs text-slate-500">Existing records will be updated, not duplicated</div>
                  <button disabled={validCount === 0 || importing} onClick={handleImport}
                    className="flex items-center gap-2 px-6 py-2.5 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-40 rounded-xl font-bold text-sm transition-all active:scale-[0.98]">
                    {importing
                      ? <><RefreshCw className="h-4 w-4 animate-spin" /> Importing…</>
                      : <><Upload className="h-4 w-4" /> Import {validCount} record{validCount !== 1 ? 's' : ''}</>
                    }
                  </button>
                </div>
              </CardBody>
            </Card>
          )}
        </div>
      )}

      {/* STEP 3 — Success */}
      {step === 3 && imported && (
        <Card className="p-10 text-center">
          <div className="text-6xl mb-4 animate-bounce">🎉</div>
          <h2 className="text-2xl font-black text-white mb-2">Import complete!</h2>
          <p className="text-slate-400 mb-2">
            <span className="text-emerald-400 font-bold">{imported.count} {KINDS[imported.kind]?.label}</span> records added to SaasGuard.
          </p>
          <p className="text-sm text-slate-600 mb-8">Risk insights are being calculated now. Check the dashboard for updates.</p>
          <div className="grid sm:grid-cols-2 gap-3 max-w-sm mx-auto">
            <button onClick={reset} className="py-3 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold text-sm transition-all">
              Import More
            </button>
            <button onClick={() => window.location.href = '/' + (imported.kind === 'employees' ? 'employees' : imported.kind === 'access' ? 'access' : 'tools')}
              className="py-3 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-bold text-sm transition-all">
              View {KINDS[imported.kind]?.label} →
            </button>
          </div>
        </Card>
      )}
    </div>
  );
}


function AuditTabContent() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db, isLoading } = useDbQuery();

  const derived = React.useMemo(() => {
    if (!db) return null;
    const tools = db.tools.map((tool) => ({
      ...tool,
      derived_status: computeToolDerivedStatus(tool),
      derived_risk: computeToolDerivedRisk(tool),
    }));
    const employeesById = Object.fromEntries(db.employees.map((e) => [e.id, e]));
    const toolsById = Object.fromEntries(tools.map((t) => [t.id, t]));
    const access = db.access.map((a) => ({
      ...a,
      derived_risk_flag: computeAccessDerivedRiskFlag(a, employeesById, toolsById),
    }));
    const activeTools    = tools.filter(t => t.derived_status === "active").length;
    const unusedTools    = tools.filter(t => t.derived_status === "unused" || t.derived_status === "orphaned").length;
    const highRiskCount  = tools.filter(t => t.derived_risk === "high").length;
    const formerEmpAccess = access.filter(a => a.derived_risk_flag === "former_employee").length;
    const spend          = tools.reduce((s, t) => s + Number(t.cost_per_month || 0), 0);
    const now = new Date();
    const toolsWithLogins = tools.filter(t => {
      if (!t.last_used_date) return false;
      const d = new Date(t.last_used_date);
      return (now - d) / (1000 * 60 * 60 * 24) <= 30;
    }).length;
    const toolUserCount = {};
    db.access.filter(a => a.status === "active").forEach(a => {
      toolUserCount[a.tool_name] = (toolUserCount[a.tool_name] || 0) + 1;
    });
    const topToolsByUsers = Object.entries(toolUserCount).sort((a,b) => b[1]-a[1]).slice(0,8);
    return {
      tools, access, employees: db.employees,
      activeTools, unusedTools, highRiskCount, formerEmpAccess, spend,
      toolsWithLogins, topToolsByUsers,
      healthScore: Math.round(Math.max(0, 100 - (highRiskCount * 10) - (formerEmpAccess * 5) - (unusedTools * 3))),
    };
  }, [db]);

  const exportTools = () => {
    if (!derived) return;
    downloadText(`tools_${todayISO()}.csv`, toCsv(derived.tools,
      ["name","category","owner_email","owner_name","criticality","url","description","derived_status","last_used_date","cost_per_month","derived_risk","notes"]
    ));
  };
  const exportEmployees = () => {
    if (!derived) return;
    downloadText(`employees_${todayISO()}.csv`, toCsv(derived.employees,
      ["full_name","email","department","role","status","start_date","end_date"]
    ));
  };
  const exportAccess = () => {
    if (!derived) return;
    downloadText(`access_${todayISO()}.csv`, toCsv(derived.access,
      ["tool_name","employee_name","employee_email","access_level","granted_date","last_accessed_date","last_reviewed_date","status","derived_risk_flag"]
    ));
  };

  const healthColor = (s) => s >= 80 ? "text-emerald-400" : s >= 60 ? "text-amber-400" : "text-rose-400";
  const healthLabel = (s) => s >= 80 ? "Healthy" : s >= 60 ? "Needs attention" : "At risk";

  if (isLoading || !derived) return (
    <div className="p-8 text-center text-slate-500">Loading audit data...</div>
  );

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h2 className="text-2xl font-black text-white mb-1">📋 Audit Export</h2>
          <p className="text-slate-400">Download full audit packages for compliance, SOC 2, and security reviews</p>
        </div>
        <button
          onClick={() => { exportTools(); exportEmployees(); exportAccess(); }}
          className="flex items-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-500 rounded-xl font-bold text-sm transition-colors"
        >
          <Download className="h-4 w-4" /> Full Audit Package
        </button>
      </div>

      {/* Health Score + KPIs */}
      <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardBody>
            <div className="flex flex-col items-center justify-center py-4 text-center">
              <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-2">{t('app_health_score')}</div>
              <div className={cx("text-5xl font-black", healthColor(derived.healthScore))}>{derived.healthScore}</div>
              <div className={cx("text-sm font-semibold mt-1", healthColor(derived.healthScore))}>{healthLabel(derived.healthScore)}</div>
              <div className="mt-3 w-full bg-slate-800 rounded-full h-2">
                <div className={cx("h-2 rounded-full transition-all", derived.healthScore >= 80 ? "bg-emerald-500" : derived.healthScore >= 60 ? "bg-amber-500" : "bg-rose-500")}
                  style={{ width: `${derived.healthScore}%` }} />
              </div>
            </div>
          </CardBody>
        </Card>
        {[
          { label: 'Active Tools', value: derived.activeTools, icon: Boxes, tone: 'text-white' },
          { label: 'High Risk Tools', value: derived.highRiskCount, icon: AlertTriangle, tone: 'text-rose-400' },
          { label: 'Former Emp. Access', value: derived.formerEmpAccess, icon: UserMinus, tone: 'text-amber-400' },
        ].map(({ label, value, icon: Icon, tone }) => (
          <Card key={label}><CardBody>
            <div className="flex items-start justify-between">
              <div>
                <div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>
                <div className={cx("text-3xl font-black", tone)}>{value}</div>
              </div>
              <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center">
                <Icon className={cx("h-4 w-4", tone)} />
              </div>
            </div>
          </CardBody></Card>
        ))}
      </div>

      {/* Export Cards */}
      <div className="grid md:grid-cols-3 gap-5">
        {[
          { title: '🛠️ Tools Export', desc: 'All SaaS tools with status, risk, cost, and owner data', count: derived.tools.length + ' records', fn: exportTools, file: 'tools_audit.csv' },
          { title: '👥 Employees Export', desc: 'Full staff directory with department, role, and status', count: derived.employees.length + ' records', fn: exportEmployees, file: 'employees_audit.csv' },
          { title: '🔑 Access Export', desc: 'Every access record with risk flags and review dates', count: derived.access.length + ' records', fn: exportAccess, file: 'access_audit.csv' },
        ].map(item => (
          <Card key={item.title} className="p-5">
            <h3 className="text-lg font-bold text-white mb-1">{item.title}</h3>
            <p className="text-sm text-slate-400 mb-2">{item.desc}</p>
            <p className="text-xs text-slate-600 mb-4 font-mono">{item.count}</p>
            <button onClick={item.fn}
              className="w-full flex items-center justify-center gap-2 py-2.5 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold text-sm transition-colors">
              <Download className="h-4 w-4" /> Download {item.file}
            </button>
          </Card>
        ))}
      </div>

      {/* Top Tools by Users */}
      {derived.topToolsByUsers.length > 0 && (
        <Card className="p-5">
          <h3 className="text-lg font-bold text-white mb-4">📊 Top Tools by Active Users</h3>
          <div className="space-y-2">
            {derived.topToolsByUsers.map(([name, count]) => (
              <div key={name} className="flex items-center gap-3">
                <div className="text-sm font-semibold text-slate-300 w-32 truncate">{name}</div>
                <div className="flex-1 bg-slate-800 rounded-full h-2">
                  <div className="bg-blue-500 h-2 rounded-full transition-all"
                    style={{ width: (count / (derived.topToolsByUsers[0]?.[1] || 1) * 100) + '%' }} />
                </div>
                <div className="text-xs text-slate-500 w-16 text-right">{count} users</div>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}


function AuditExportPage() {
  const { data: db, isLoading } = useDbQuery();
  const { language } = useLang();
  const t = useTranslation(language);

  const derived = useMemo(() => {
    if (!db) return null;
    const tools = db.tools.map((tool) => ({
      ...tool,
      derived_status: computeToolDerivedStatus(tool),
      derived_risk: computeToolDerivedRisk(tool),
    }));
    const employeesById = Object.fromEntries(db.employees.map((e) => [e.id, e]));
    const toolsById     = Object.fromEntries(tools.map((t) => [t.id, t]));
    const access = db.access.map((a) => ({
      ...a,
      derived_risk_flag: computeAccessDerivedRiskFlag(a, employeesById, toolsById),
    }));

    // App health
    const activeTools    = tools.filter(t => t.derived_status === "active").length;
    const unusedTools    = tools.filter(t => t.derived_status === "unused" || t.derived_status === "orphaned").length;
    const highRiskCount  = tools.filter(t => t.derived_risk === "high").length;
    const formerEmpAccess = access.filter(a => a.derived_risk_flag === "former_employee").length;
    const spend          = tools.reduce((s, t) => s + Number(t.cost_per_month || 0), 0);

    // Login / usage stats — tools with recent last_used_date
    const now = new Date();
    const toolsWithLogins = tools.filter(t => {
      if (!t.last_used_date) return false;
      const d = new Date(t.last_used_date);
      return (now - d) / (1000 * 60 * 60 * 24) <= 30;
    }).length;

    // Per-tool user count from access records
    const toolUserCount = {};
    db.access.filter(a => a.status === "active").forEach(a => {
      toolUserCount[a.tool_name] = (toolUserCount[a.tool_name] || 0) + 1;
    });
    const topToolsByUsers = Object.entries(toolUserCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8);

    return {
      tools, access, employees: db.employees,
      activeTools, unusedTools, highRiskCount, formerEmpAccess, spend,
      toolsWithLogins, topToolsByUsers,
      healthScore: Math.round(Math.max(0, 100 - (highRiskCount * 10) - (formerEmpAccess * 5) - (unusedTools * 3))),
    };
  }, [db]);

  const exportTools = () => {
    if (!derived) return;
    downloadText(`tools_${todayISO()}.csv`, toCsv(derived.tools,
      ["name","category","owner_email","owner_name","criticality","url","description","derived_status","last_used_date","cost_per_month","derived_risk","notes"]
    ));
  };
  const exportEmployees = () => {
    if (!derived) return;
    downloadText(`employees_${todayISO()}.csv`, toCsv(derived.employees,
      ["full_name","email","department","role","status","start_date","end_date"]
    ));
  };
  const exportAccess = () => {
    if (!derived) return;
    downloadText(`access_${todayISO()}.csv`, toCsv(derived.access,
      ["tool_name","employee_name","employee_email","access_level","granted_date","last_accessed_date","last_reviewed_date","status","derived_risk_flag"]
    ));
  };
  const exportAll = () => { exportTools(); exportEmployees(); exportAccess(); };

  const healthColor = (score) =>
    score >= 80 ? "text-emerald-400" : score >= 60 ? "text-amber-400" : "text-rose-400";
  const healthLabel = (score) =>
    score >= 80 ? "Healthy" : score >= 60 ? "Needs attention" : "At risk";

  return (
    <AppShell
      title={"Export Audit" || 'Audit Export'}
      right={
        <Button onClick={exportAll}>
          <Download className="h-4 w-4" /> Full Audit Package
        </Button>
      }
    >
      <div className="grid gap-5">

        {/* Health + summary row */}
        <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-4">
          <Card className="lg:col-span-1">
            <CardBody>
              <div className="flex flex-col items-center justify-center py-4 text-center">
                <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-2">{t('app_health_score')}</div>
                {isLoading || !derived ? (
                  <div className="h-16 w-16 rounded-full border-4 border-slate-700 animate-pulse" />
                ) : (
                  <>
                    <div className={cx("text-5xl font-black", healthColor(derived.healthScore))}>
                      {derived.healthScore}
                    </div>
                    <div className={cx("text-sm font-semibold mt-1", healthColor(derived.healthScore))}>
                      {healthLabel(derived.healthScore)}
                    </div>
                    <div className="mt-3 w-full bg-slate-800 rounded-full h-2">
                      <div
                        className={cx("h-2 rounded-full transition-all", derived.healthScore >= 80 ? "bg-emerald-500" : derived.healthScore >= 60 ? "bg-amber-500" : "bg-rose-500")}
                        style={{ width: `${derived.healthScore}%` }}
                      />
                    </div>
                  </>
                )}
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody>
              <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-3">{t('tool_inventory')}</div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="text-slate-400">{t('total_tools')}</span><span className="font-bold text-white">{derived?.tools.length ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">{t('active')}</span><span className="font-bold text-emerald-400">{derived?.activeTools ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">{t('orphaned')}</span><span className="font-bold text-amber-400">{derived?.unusedTools ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">{t('high_risk')}</span><span className="font-bold text-rose-400">{derived?.highRiskCount ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">{t('active')}</span><span className="font-bold text-blue-400">{derived?.toolsWithLogins ?? "—"}</span></div>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody>
              <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-3">{t('risk_alerts')}</div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="text-slate-400">{t('total_access_records')}</span><span className="font-bold text-white">{derived?.access.length ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">{t('active')}</span><span className="font-bold text-emerald-400">{derived?.access.filter(a => a.status === "active").length ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Former employee access</span><span className="font-bold text-rose-400">{derived?.formerEmpAccess ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Employees</span><span className="font-bold text-slate-300">{derived?.employees.length ?? "—"}</span></div>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody>
              <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-3">Spend</div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="text-slate-400">{t('monthly_total')}</span><span className="font-bold text-white">{derived ? formatMoney(derived.spend) : "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">{t('annual_projection')}</span><span className="font-bold text-blue-400">{derived ? formatMoney(derived.spend * 12) : "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">{t('avg_per_tool')}</span><span className="font-bold text-slate-300">{derived && derived.tools.length ? formatMoney(derived.spend / derived.tools.length) : "—"}</span></div>
              </div>
            </CardBody>
          </Card>
        </div>

        <div className="grid gap-5 lg:grid-cols-2">
          {/* Tool login / user counts */}
          <Card>
            <CardHeader title="Users logged into tools" subtitle={t('all_permissions_sub')} />
            <CardBody>
              {isLoading || !derived ? <SkeletonRow cols={3} /> : derived.topToolsByUsers.length === 0 ? (
                <EmptyState icon={Users} title="No access data" body="Import access records to see tool usage." />
              ) : (
                <div className="space-y-3">
                  {derived.topToolsByUsers.map(([toolName, count]) => {
                    const pct = Math.round((count / derived.employees.length) * 100);
                    return (
                      <div key={toolName}>
                        <div className="flex items-center justify-between mb-1 text-sm">
                          <span className="text-slate-300 font-medium">{toolName}</span>
                          <span className="text-slate-400">{count} user{count !== 1 ? "s" : ""} <span className="text-slate-600">({pct}%)</span></span>
                        </div>
                        <div className="h-2 w-full rounded-full bg-slate-800">
                          <div className="h-2 rounded-full bg-blue-500 transition-all" style={{ width: `${Math.min(pct, 100)}%` }} />
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </CardBody>
          </Card>

          {/* Export buttons */}
          <Card>
            <CardHeader title="Export reports" subtitle="Timestamped CSV files" />
            <CardBody>
              <div className="space-y-3">
                {[
                  { label: "Tools report", sub: "Inventory, ownership, status, risk, spend", fn: exportTools, count: derived?.tools.length },
                  { label: "Employees report", sub: "Directory with department, role, dates, status", fn: exportEmployees, count: derived?.employees.length },
                  { label: "Access report", sub: "Tool-to-employee mappings and risk flags", fn: exportAccess, count: derived?.access.length },
                ].map(({ label, sub, fn, count }) => (
                  <div key={label} className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                    <div>
                      <div className="text-sm font-semibold text-white">{label}</div>
                      <div className="text-xs text-slate-500 mt-0.5">{sub}</div>
                      {count !== undefined && <div className="text-xs text-slate-600 mt-0.5">{count} records</div>}
                    </div>
                    <Button size="sm" variant="secondary" onClick={fn}>
                      <Download className="h-4 w-4" /> Export
                    </Button>
                  </div>
                ))}
                <div className="rounded-2xl border border-blue-600/30 bg-blue-600/10 p-4 flex items-center justify-between">
                  <div>
                    <div className="text-sm font-semibold text-white">{t('full_audit_package')}</div>
                    <div className="text-xs text-slate-500 mt-0.5">{t('all_three_reports')}</div>
                  </div>
                  <Button size="sm" onClick={exportAll}>
                    <Download className="h-4 w-4" /> Export all
                  </Button>
                </div>
              </div>
            </CardBody>
          </Card>
        </div>

        {/* Summary */}
        <Card>
          <CardHeader title="Audit summary" subtitle="Auto-generated compliance overview" />
          <CardBody>
            {isLoading || !derived ? <SkeletonRow cols={4} /> : (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {[
                  { icon: "✅", title: "Active tools", text: `${derived.activeTools} of ${derived.tools.length} tools are active and accounted for.`, ok: true },
                  derived.unusedTools > 0 && { icon: "⚠️", title: "Unused tools", text: `${derived.unusedTools} tools are unused or orphaned — consider reviewing or decommissioning.`, ok: false },
                  derived.highRiskCount > 0 && { icon: "🔴", title: "High-risk tools", text: `${derived.highRiskCount} tool${derived.highRiskCount !== 1 ? "s" : ""} flagged as high-risk require immediate review.`, ok: false },
                  derived.formerEmpAccess > 0 && { icon: "🚨", title: "Former employee access", text: `${derived.formerEmpAccess} access record${derived.formerEmpAccess !== 1 ? "s" : ""} belong to offboarded employees and should be revoked.`, ok: false },
                  derived.formerEmpAccess === 0 && { icon: "✅", title: "No ghost access", text: "No active access records linked to offboarded employees.", ok: true },
                  { icon: "💰", title: "Monthly spend", text: `Total SaaS spend is ${formatMoney(derived.spend)}/month (${formatMoney(derived.spend * 12)}/year).`, ok: true },
                ].filter(Boolean).map((item) => (
                  <div key={item.title} className={cx(
                    "rounded-xl border p-4 text-sm",
                    item.ok ? "border-emerald-800/40 bg-emerald-950/20" : "border-rose-800/40 bg-rose-950/20"
                  )}>
                    <div className="flex items-center gap-2 font-semibold text-white mb-1">
                      <span>{item.icon}</span>{item.title}
                    </div>
                    <div className="text-slate-400">{item.text}</div>
                  </div>
                ))}
              </div>
            )}
          </CardBody>
        </Card>
      </div>
    </AppShell>
  );
}

function PricingTiers({ currentPlan = 'free' }) {
  const [billingCycle, setBillingCycle] = useState('monthly');
  const plans = [
    {
      id: 'free', name: 'Free', tagline: 'For small teams getting started',
      price: { monthly: 0, annual: 0 },
      features: ['Up to 10 SaaS tools', 'Basic dashboard', '1 team member', 'Email support', 'Monthly reports'],
      popular: false,
    },
    {
      id: 'pro', name: 'Professional', tagline: 'For growing teams',
      price: { monthly: 49, annual: 470 },
      features: ['Unlimited SaaS tools', 'AI-powered insights', 'Executive dashboard', 'Up to 10 team members', 'Priority support', 'Advanced analytics', 'Custom reports', 'API access'],
      popular: true,
    },
    {
      id: 'enterprise', name: 'Enterprise', tagline: 'For large organizations',
      price: { monthly: 'Custom', annual: 'Custom' },
      features: ['Everything in Pro', 'Unlimited team members', 'SSO & SAML', 'Dedicated account manager', '24/7 phone support', 'Custom integrations', 'SLA guarantee', 'On-premise option'],
      popular: false,
    },
  ];
  const getPrice = (p) => {
    const v = p.price[billingCycle];
    if (typeof v !== 'number') return v;
    return billingCycle === 'monthly' ? `$${v}/mo` : `$${v}/yr`;
  };
  const getSavings = (p) => {
    if (billingCycle === 'annual' && typeof p.price.annual === 'number' && p.price.annual > 0) {
      const s = p.price.monthly * 12 - p.price.annual;
      return s > 0 ? `Save $${s}/year` : null;
    }
    return null;
  };
  return (
    <div className="space-y-8">
      <div className="flex items-center justify-center gap-4">
        <span className={`text-sm font-medium ${billingCycle === 'monthly' ? 'text-white' : 'text-slate-400'}`}>Monthly</span>
        <button onClick={() => setBillingCycle(c => c === 'monthly' ? 'annual' : 'monthly')}
          className="relative w-14 h-7 bg-slate-700 rounded-full hover:bg-slate-600 transition-colors">
          <div className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full transition-transform ${billingCycle === 'annual' ? 'translate-x-7' : ''}`} />
        </button>
        <span className={`text-sm font-medium ${billingCycle === 'annual' ? 'text-white' : 'text-slate-400'}`}>Annual</span>
        {billingCycle === 'annual' && <span className="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs font-semibold rounded-full">Save 20%</span>}
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {plans.map((plan) => {
          const isCurrent = plan.id === currentPlan;
          const savings = getSavings(plan);
          return (
            <div key={plan.id} className={`relative rounded-2xl p-8 ${plan.popular ? 'bg-gradient-to-br from-blue-500/20 to-purple-500/20 border-2 border-blue-500' : 'bg-slate-900 border border-slate-800'}`}>
              {plan.popular && <div className="absolute -top-4 left-1/2 -translate-x-1/2"><span className="px-4 py-1 bg-blue-600 text-white text-sm font-bold rounded-full">MOST POPULAR</span></div>}
              <div className="text-center mb-6">
                <h3 className="text-2xl font-black text-white mb-2">{plan.name}</h3>
                <p className="text-sm text-slate-400">{plan.tagline}</p>
              </div>
              <div className="text-center mb-6">
                <div className="text-4xl font-black text-white mb-2">{getPrice(plan)}</div>
                {savings && <div className="text-sm text-emerald-400 font-semibold">{savings}</div>}
              </div>
              <ul className="space-y-3 mb-8">
                {plan.features.map((feat, i) => (
                  <li key={i} className="flex items-start gap-2">
                    <CheckCircle className="h-5 w-5 text-emerald-400 flex-shrink-0 mt-0.5" />
                    <span className="text-sm text-slate-300">{feat}</span>
                  </li>
                ))}
              </ul>
              <button disabled={isCurrent}
                className={`w-full py-3 rounded-xl font-bold transition-all ${isCurrent ? 'bg-slate-700 text-slate-400 cursor-not-allowed' : plan.popular ? 'bg-blue-600 hover:bg-blue-500 text-white' : 'bg-slate-800 hover:bg-slate-700 text-white'}`}>
                {isCurrent ? 'Current Plan' : plan.popular ? 'Upgrade to Pro' : 'Contact Sales'}
              </button>
            </div>
          );
        })}
      </div>
      <div className="text-center">
        <p className="text-sm text-slate-400 mb-4">Trusted by 800+ companies worldwide</p>
        <div className="flex items-center justify-center gap-8 text-slate-500 text-sm">
          <span className="flex items-center gap-1"><Shield className="h-4 w-4" /> SOC 2</span>
          <span className="flex items-center gap-1"><Lock className="h-4 w-4" /> GDPR</span>
          <span className="flex items-center gap-1"><Award className="h-4 w-4" /> 99.9% Uptime</span>
        </div>
      </div>
    </div>
  );
}

function BillingPage() {
  const { data: db } = useDbQuery();
  const muts = useDbMutations();
  const { language } = useLang();
  const t = useTranslation(language);
  const plan = db?.user?.subscription_plan || 'trial';
  const [billing, setBilling] = useState('monthly');
  const [showContactModal, setShowContactModal] = useState(false);
  const [contactEmail, setContactEmail] = useState('');
  const [contactSize, setContactSize] = useState('1-10');
  const [contactSent, setContactSent] = useState(false);

  const trialDaysUsed = 5;
  const trialDaysLeft = 14 - trialDaysUsed;
  const trialPct = (trialDaysUsed / 14) * 100;
  const isTrial = plan === 'trial' || plan === 'free';

  // 5 tiers: Startup / Growth / Scale / Professional / Enterprise
  const plans = [
    {
      id: 'startup',
      tName: 'plan_startup', tTag: 'plan_startup_tag',
      icon: '🎯', monthly: null, annual: null, isTrial: true,
      color: 'from-amber-500 to-orange-600', border: 'border-amber-500/40',
      features: [
        { key: 'f_startup_1', en: 'Full access for 14 days' },
        { key: 'f_startup_2', en: 'All features unlocked' },
        { key: 'f_startup_3', en: 'Up to 10 SaaS tools' },
        { key: 'f_startup_4', en: 'Up to 10 employees' },
        { key: 'f_startup_5', en: 'No credit card required' },
        { key: 'f_startup_6', en: 'Community support' },
      ],
      limits: { tools: 10, employees: 10 },
    },
    {
      id: 'growth',
      tName: 'plan_growth', tTag: 'plan_growth_tag',
      icon: '🚀', monthly: 49, annual: 470,
      color: 'from-blue-600 to-blue-700', border: 'border-blue-500/40',
      features: [
        { key: 'f_growth_1', en: 'Up to 50 SaaS tools' },
        { key: 'f_growth_2', en: 'Up to 50 employees' },
        { key: 'f_growth_3', en: 'Advanced risk scoring' },
        { key: 'f_growth_4', en: 'Finance dashboard' },
        { key: 'f_growth_5', en: 'Audit exports' },
        { key: 'f_growth_6', en: 'Up to 5 team members' },
        { key: 'f_growth_7', en: 'Email support' },
      ],
      limits: { tools: 50, employees: 50 },
    },
    {
      id: 'scale',
      tName: 'plan_scale', tTag: 'plan_scale_tag',
      icon: '⚡', monthly: 99, annual: 950,
      color: 'from-emerald-600 to-teal-700', border: 'border-emerald-500/40',
      popular: true,
      features: [
        { key: 'f_scale_1', en: 'Unlimited SaaS tools' },
        { key: 'f_scale_2', en: 'Unlimited employees' },
        { key: 'f_scale_3', en: 'AI contract analysis' },
        { key: 'f_scale_4', en: 'License management' },
        { key: 'f_scale_5', en: 'Full audit reports' },
        { key: 'f_scale_6', en: 'Up to 15 team members' },
        { key: 'f_scale_7', en: 'Priority support' },
        { key: 'f_scale_8', en: 'API access' },
      ],
    },
    {
      id: 'professional',
      tName: 'plan_professional', tTag: 'plan_professional_tag',
      icon: '💎', monthly: 199, annual: 1910,
      color: 'from-violet-600 to-purple-700', border: 'border-violet-500/40',
      features: [
        { key: 'f_pro_1', en: 'Everything in Scale' },
        { key: 'f_pro_2', en: 'Advanced analytics & BI exports' },
        { key: 'f_pro_3', en: 'Custom integrations' },
        { key: 'f_pro_4', en: 'Unlimited team members' },
        { key: 'f_pro_5', en: 'SSO / SAML (up to 500 users)' },
        { key: 'f_pro_6', en: 'Dedicated onboarding' },
        { key: 'f_pro_7', en: 'SLA 99.9% uptime' },
        { key: 'f_pro_8', en: 'Phone & chat support' },
      ],
    },
    {
      id: 'enterprise',
      tName: 'plan_enterprise', tTag: 'plan_enterprise_tag',
      icon: '🏢', monthly: null, annual: null,
      color: 'from-amber-600 to-orange-700', border: 'border-amber-500/30',
      features: [
        { key: 'f_ent_1', en: 'Everything in Professional' },
        { key: 'f_ent_2', en: 'Unlimited users & workspaces' },
        { key: 'f_ent_3', en: 'SCIM provisioning' },
        { key: 'f_ent_4', en: 'Dedicated account manager' },
        { key: 'f_ent_5', en: '24/7 phone & Slack support' },
        { key: 'f_ent_6', en: 'Custom contracts & invoicing' },
        { key: 'f_ent_7', en: 'On-premise / private cloud option' },
        { key: 'f_ent_8', en: 'Security review & pen test report' },
      ],
    },
  ];

  // Feature translations (inline since they are plan-specific)
  const featureText = {
    en: {
      f_startup_1:'Full access for 14 days',f_startup_2:'All features unlocked',f_startup_3:'Up to 10 SaaS tools',f_startup_4:'Up to 10 employees',f_startup_5:'No credit card required',f_startup_6:'Community support',
      f_growth_1:'Up to 50 SaaS tools',f_growth_2:'Up to 50 employees',f_growth_3:'Advanced risk scoring',f_growth_4:'Finance dashboard',f_growth_5:'Audit exports',f_growth_6:'Up to 5 team members',f_growth_7:'Email support',
      f_scale_1:'Unlimited SaaS tools',f_scale_2:'Unlimited employees',f_scale_3:'AI contract analysis',f_scale_4:'License management',f_scale_5:'Full audit reports',f_scale_6:'Up to 15 team members',f_scale_7:'Priority support',f_scale_8:'API access',
      f_pro_1:'Everything in Scale',f_pro_2:'Advanced analytics & BI exports',f_pro_3:'Custom integrations',f_pro_4:'Unlimited team members',f_pro_5:'SSO / SAML (up to 500 users)',f_pro_6:'Dedicated onboarding',f_pro_7:'SLA 99.9% uptime',f_pro_8:'Phone & chat support',
      f_ent_1:'Everything in Professional',f_ent_2:'Unlimited users & workspaces',f_ent_3:'SCIM provisioning',f_ent_4:'Dedicated account manager',f_ent_5:'24/7 phone & Slack support',f_ent_6:'Custom contracts & invoicing',f_ent_7:'On-premise / private cloud option',f_ent_8:'Security review & pen test report',
    },
    fr: {
      f_startup_1:"Jusqu’à 10 outils SaaS",f_startup_2:"Jusqu’à 10 employés",f_startup_3:"Alertes de risque basiques",f_startup_4:"Export CSV",f_startup_5:"1 membre d’équipe",f_startup_6:"Support communautaire",
      f_growth_1:"Jusqu’à 50 outils SaaS",f_growth_2:"Jusqu’à 50 employés",f_growth_3:"Score de risque avancé",f_growth_4:"Tableau de bord Finance",f_growth_5:"Exports d’audit",f_growth_6:"Jusqu’à 5 membres",f_growth_7:"Support par email",
      f_scale_1:"Outils SaaS illimités",f_scale_2:"Employés illimités",f_scale_3:"Analyse IA des contrats",f_scale_4:"Gestion des licences",f_scale_5:"Rapports d’audit complets",f_scale_6:"Jusqu’à 15 membres",f_scale_7:"Support prioritaire",f_scale_8:"Accès API",
      f_pro_1:"Tout inclus dans Scale",f_pro_2:"Analyses avancées & exports BI",f_pro_3:"Intégrations personnalisées",f_pro_4:"Membres illimités",f_pro_5:"SSO / SAML (jusqu’à 500 utilisateurs)",f_pro_6:"Onboarding dédié",f_pro_7:"SLA 99,9% de disponibilité",f_pro_8:"Support téléphone & chat",
      f_ent_1:"Tout inclus dans Professionnel",f_ent_2:"Utilisateurs & espaces de travail illimités",f_ent_3:"Provisionnement SCIM",f_ent_4:"Responsable de compte dédié",f_ent_5:"Support 24/7 téléphone & Slack",f_ent_6:"Contrats & facturation personnalisés",f_ent_7:"Option sur site / cloud privé",f_ent_8:"Audit de sécurité & rapport de test d’intrusion",
    },
    es: {
      f_startup_1:'Hasta 10 herramientas SaaS',f_startup_2:'Hasta 10 empleados',f_startup_3:'Alertas de riesgo básicas',f_startup_4:'Exportación CSV',f_startup_5:'1 miembro del equipo',f_startup_6:'Soporte comunitario',
      f_growth_1:'Hasta 50 herramientas SaaS',f_growth_2:'Hasta 50 empleados',f_growth_3:'Puntuación de riesgo avanzada',f_growth_4:'Panel de finanzas',f_growth_5:'Exportaciones de auditoría',f_growth_6:'Hasta 5 miembros',f_growth_7:'Soporte por email',
      f_scale_1:'Herramientas SaaS ilimitadas',f_scale_2:'Empleados ilimitados',f_scale_3:'Análisis IA de contratos',f_scale_4:'Gestión de licencias',f_scale_5:'Informes de auditoría completos',f_scale_6:'Hasta 15 miembros',f_scale_7:'Soporte prioritario',f_scale_8:'Acceso API',
      f_pro_1:'Todo en Scale',f_pro_2:'Análisis avanzados y exportaciones BI',f_pro_3:'Integraciones personalizadas',f_pro_4:'Miembros ilimitados',f_pro_5:'SSO / SAML (hasta 500 usuarios)',f_pro_6:'Incorporación dedicada',f_pro_7:'SLA 99,9% de disponibilidad',f_pro_8:'Soporte telefónico y por chat',
      f_ent_1:'Todo en Profesional',f_ent_2:'Usuarios y espacios de trabajo ilimitados',f_ent_3:'Aprovisionamiento SCIM',f_ent_4:'Gestor de cuenta dedicado',f_ent_5:'Soporte 24/7 teléfono y Slack',f_ent_6:'Contratos y facturación personalizados',f_ent_7:'Opción local / nube privada',f_ent_8:'Revisión de seguridad e informe de prueba de penetración',
    },
    de: {
      f_startup_1:'Bis zu 10 SaaS-Tools',f_startup_2:'Bis zu 10 Mitarbeiter',f_startup_3:'Grundlegende Risikowarnungen',f_startup_4:'CSV-Export',f_startup_5:'1 Teammitglied',f_startup_6:'Community-Support',
      f_growth_1:'Bis zu 50 SaaS-Tools',f_growth_2:'Bis zu 50 Mitarbeiter',f_growth_3:'Erweiterte Risikobewertung',f_growth_4:'Finanz-Dashboard',f_growth_5:'Audit-Exporte',f_growth_6:'Bis zu 5 Mitglieder',f_growth_7:'E-Mail-Support',
      f_scale_1:'Unbegrenzte SaaS-Tools',f_scale_2:'Unbegrenzte Mitarbeiter',f_scale_3:'KI-Vertragsanalyse',f_scale_4:'Lizenzverwaltung',f_scale_5:'Vollständige Audit-Berichte',f_scale_6:'Bis zu 15 Mitglieder',f_scale_7:'Prioritäts-Support',f_scale_8:'API-Zugang',
      f_pro_1:'Alles aus Scale',f_pro_2:'Erweiterte Analysen & BI-Exporte',f_pro_3:'Benutzerdefinierte Integrationen',f_pro_4:'Unbegrenzte Mitglieder',f_pro_5:'SSO / SAML (bis 500 Nutzer)',f_pro_6:'Dediziertes Onboarding',f_pro_7:'SLA 99,9% Verfügbarkeit',f_pro_8:'Telefon- & Chat-Support',
      f_ent_1:'Alles aus Professionell',f_ent_2:'Unbegrenzte Benutzer & Arbeitsbereiche',f_ent_3:'SCIM-Bereitstellung',f_ent_4:'Dedizierter Account-Manager',f_ent_5:'24/7 Telefon- & Slack-Support',f_ent_6:'Individuelle Verträge & Abrechnung',f_ent_7:'On-Premise / Private Cloud Option',f_ent_8:'Sicherheitsüberprüfung & Pen-Test-Bericht',
    },
    ja: {
      f_startup_1:'最大10のSaaSツール',f_startup_2:'最大10名の従業員',f_startup_3:'基本リスクアラート',f_startup_4:'CSVエクスポート',f_startup_5:'チームメンバー1名',f_startup_6:'コミュニティサポート',
      f_growth_1:'最大50のSaaSツール',f_growth_2:'最大50名の従業員',f_growth_3:'高度なリスクスコアリング',f_growth_4:'財務ダッシュボード',f_growth_5:'監査エクスポート',f_growth_6:'最大5名のメンバー',f_growth_7:'メールサポート',
      f_scale_1:'SaaSツール無制限',f_scale_2:'従業員無制限',f_scale_3:'AI契約分析',f_scale_4:'ライセンス管理',f_scale_5:'完全な監査レポート',f_scale_6:'最大15名のメンバー',f_scale_7:'優先サポート',f_scale_8:'APIアクセス',
      f_pro_1:'Scaleのすべてを含む',f_pro_2:'高度な分析とBIエクスポート',f_pro_3:'カスタムインテグレーション',f_pro_4:'メンバー無制限',f_pro_5:'SSO / SAML（最大500ユーザー）',f_pro_6:'専任オンボーディング',f_pro_7:'SLA 99.9%稼働率',f_pro_8:'電話・チャットサポート',
      f_ent_1:'Professionalのすべてを含む',f_ent_2:'ユーザーとワークスペース無制限',f_ent_3:'SCIMプロビジョニング',f_ent_4:'専任アカウントマネージャー',f_ent_5:'24/7電話・Slackサポート',f_ent_6:'カスタム契約・請求',f_ent_7:'オンプレミス/プライベートクラウドオプション',f_ent_8:'セキュリティレビュー・ペネトレーションテスト報告書',
    },
  };

  const ft = (key) => (featureText[language] || featureText.en)[key] || featureText.en[key] || key;

  const getPrice = (p) => {
    if (p.isTrial) return t('free_trial_label');
    if (!p.monthly) return t('contact_sales');
    const v = billing === 'monthly' ? p.monthly : p.annual;
    return billing === 'monthly' ? `$${v}/mo` : `$${v}/yr`;
  };

  const getSaving = (p) => {
    if (!p.monthly || !p.annual) return null;
    const saved = p.monthly * 12 - p.annual;
    return saved > 0 ? `Save $${saved}/yr` : null;
  };

  const upgrade = (id) => {
    if (id === 'enterprise') { setShowContactModal(true); return; }
    muts.setPlan?.mutate(id);
  };

  const currentPlanObj = plans.find(p => p.id === plan);

  return (
    <AppShell title={t('billing_title')} right={
      <div className="flex items-center gap-2">
        {isTrial && (
          <span className="flex items-center gap-1.5 text-xs font-bold text-amber-400 bg-amber-500/10 border border-amber-500/20 px-3 py-1.5 rounded-full">
            ⏱ {trialDaysLeft} {t('trial_days_left')}
          </span>
        )}
        <Pill tone="blue" icon={CreditCard}>
          {isTrial ? 'Trial' : (plan.charAt(0).toUpperCase() + plan.slice(1))}
        </Pill>
      </div>
    }>
      <div className="p-2 space-y-8">

        {/* Trial Banner */}
        {isTrial && (
          <div className="rounded-2xl border-2 border-amber-500/40 bg-gradient-to-r from-amber-500/15 via-orange-500/10 to-amber-500/5 p-7 shadow-lg shadow-amber-500/5">
            <div className="flex items-start justify-between gap-6 flex-wrap">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-3 mb-3">
                  <span className="text-3xl">⏳</span>
                  <div>
                    <h3 className="text-xl font-black text-white">{t('trial_banner_title')}</h3>
                    <div className="flex items-center gap-2 mt-0.5">
                      <span className="text-sm font-bold text-amber-400">Day {trialDaysUsed} of 14</span>
                      <span className="text-slate-600">·</span>
                      <span className="text-sm text-slate-400">{trialDaysLeft} {t('trial_days_left')}</span>
                    </div>
                  </div>
                </div>
                <p className="text-slate-300 text-sm mb-4 max-w-lg">{t('trial_no_card')}</p>
                <div className="flex items-center gap-3 mb-3 max-w-xs">
                  <div className="flex-1 bg-slate-800 rounded-full h-3 overflow-hidden">
                    <div className="bg-gradient-to-r from-amber-400 to-orange-400 h-3 rounded-full transition-all" style={{width: trialPct + '%'}} />
                  </div>
                  <span className="text-xs text-amber-400 font-bold whitespace-nowrap">{trialPct.toFixed(0)}% used</span>
                </div>
              </div>
              <div className="flex-shrink-0 text-right">
                <button onClick={() => upgrade('scale')}
                  className="px-7 py-3.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-white font-black rounded-xl transition-all shadow-lg shadow-amber-500/30 text-sm block mb-2">
                  {t('upgrade_now')} ✨
                </button>
                <p className="text-xs text-slate-500">{t('cancel_anytime')}</p>
              </div>
            </div>
          </div>
        )}

        {/* Billing Toggle */}
        <div className="flex flex-col items-center gap-3">
          <h2 className="text-2xl font-black text-white">{t('choose_plan')}</h2>
          <div className="flex items-center gap-3 p-1 bg-slate-900 rounded-xl border border-slate-800">
            {['monthly','annual'].map(c => (
              <button key={c} onClick={() => setBilling(c)}
                className={"px-4 py-2 rounded-lg text-sm font-semibold transition-all " + (billing === c ? 'bg-emerald-600 text-white shadow' : 'text-slate-400 hover:text-white')}>
                {c === 'monthly' ? t('monthly') : t('annual')}
                {c === 'annual' && <span className="ml-1.5 text-[10px] bg-emerald-500/20 text-emerald-400 px-1.5 py-0.5 rounded-full">{t('save_20')}</span>}
              </button>
            ))}
          </div>
        </div>

        {/* Plan Cards — 5 tiers in a responsive grid */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
          {plans.map(p => {
            const isCurrent = plan === p.id || (isTrial && p.id === 'scale');
            return (
              <div key={p.id} className={"relative rounded-2xl border p-5 flex flex-col transition-all " + p.border + (p.popular ? ' shadow-xl shadow-emerald-500/10 ring-1 ring-emerald-500/30' : '')}>
                {p.popular && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 whitespace-nowrap">
                    <span className="bg-gradient-to-r from-emerald-500 to-teal-500 text-white text-xs font-bold px-3 py-1 rounded-full shadow-lg">
                      ⭐ {t('most_popular')}
                    </span>
                  </div>
                )}
                {p.isTrial && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 whitespace-nowrap">
                    <span className="bg-gradient-to-r from-amber-500 to-orange-500 text-white text-xs font-bold px-3 py-1 rounded-full shadow-lg">
                      🎯 {t('trial_badge')}
                    </span>
                  </div>
                )}
                <div className={"h-10 w-10 rounded-xl bg-gradient-to-br flex items-center justify-center text-xl mb-3 " + p.color}>
                  {p.icon}
                </div>
                <div className="font-black text-lg text-white mb-0.5">{t(p.tName)}</div>
                <div className="text-xs text-slate-500 mb-3 min-h-[2rem]">{t(p.tTag)}</div>
                <div className="mb-4">
                  {p.isTrial ? (
                    <div>
                      <span className="text-3xl font-black text-amber-400">{t('free_trial_label')}</span>
                      <div className="text-xs text-slate-400 mt-1">14 days · No credit card</div>
                    </div>
                  ) : (
                    <span className="text-3xl font-black text-white">{getPrice(p)}</span>
                  )}
                  {p.monthly && !p.isTrial && <span className="text-xs text-slate-500 ml-1">/{billing === 'monthly' ? t('monthly') : 'yr'}</span>}
                </div>
                {getSaving(p) && billing === 'annual' && (
                  <span className="text-xs text-emerald-400 font-bold mb-3 block">{getSaving(p)}</span>
                )}
                <div className="flex-1 space-y-2 mb-5">
                  {p.features.map(f => (
                    <div key={f.key} className="flex items-start gap-2">
                      <Check className="h-3.5 w-3.5 text-emerald-400 flex-shrink-0 mt-0.5" />
                      <span className="text-xs text-slate-300">{ft(f.key)}</span>
                    </div>
                  ))}
                </div>
                {isCurrent ? (
                  <div className="text-center py-2.5 rounded-xl bg-slate-800/60 text-slate-400 text-xs font-semibold">
                    {isTrial ? '✓ ' + t('active_trial') : '✓ ' + t('current_plan')}
                  </div>
                ) : p.id === 'enterprise' ? (
                  <button onClick={() => setShowContactModal(true)}
                    className={"w-full py-2.5 rounded-xl border text-xs font-bold transition-all " + p.border + " text-amber-300 hover:bg-amber-500/10"}>
                    {t('contact_sales')}
                  </button>
                ) : (
                  <button onClick={() => upgrade(p.id)}
                    className={"w-full py-2.5 rounded-xl font-bold transition-all text-xs text-white bg-gradient-to-r hover:opacity-90 shadow-lg " + p.color}>
                    {isTrial ? t('upgrade_now').split('—')[0].trim() : 'Upgrade'}
                  </button>
                )}
              </div>
            );
          })}
        </div>

        {/* After-trial explainer */}
        {isTrial && (
          <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6">
            <h3 className="font-bold text-white mb-4">{t('after_trial_title')}</h3>
            <div className="grid sm:grid-cols-3 gap-4">
              {[
                { day: 'Day 14', title: 'Trial ends', desc: "You'll be prompted to choose a plan. Your data stays safe.", color: 'text-amber-400' },
                { day: t('never'), title: 'No surprise charges', desc: "We'll never charge you without your consent.", color: 'text-slate-400' },
                { day: 'Recommended', title: t('plan_scale'), desc: 'Keep all features. Cancel anytime.', color: 'text-emerald-400' },
              ].map(item => (
                <div key={item.day} className="p-4 rounded-xl bg-slate-800/60">
                  <div className={"text-xs font-bold uppercase tracking-wide mb-1 " + item.color}>{item.day}</div>
                  <div className="font-semibold text-white text-sm mb-1">{item.title}</div>
                  <div className="text-xs text-slate-500">{item.desc}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Usage meter */}
        {!isTrial && currentPlanObj?.limits && (
          <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6">
            <h3 className="font-bold text-white mb-4">{t('plan_usage')}</h3>
            <div className="grid sm:grid-cols-2 gap-4">
              {[
                { label: t('nav_tools'), used: db?.tools?.length || 0, max: currentPlanObj.limits.tools },
                { label: t('nav_employees'), used: db?.employees?.length || 0, max: currentPlanObj.limits.employees },
              ].map(({ label, used, max }) => {
                const pct = Math.min((used / max) * 100, 100);
                return (
                  <div key={label}>
                    <div className="flex justify-between text-sm mb-1.5">
                      <span className="text-slate-400">{label}</span>
                      <span className={"font-bold " + (pct > 80 ? 'text-amber-400' : 'text-white')}>{used} / {max}</span>
                    </div>
                    <div className="w-full bg-slate-800 rounded-full h-2">
                      <div className={"h-2 rounded-full transition-all " + (pct > 90 ? 'bg-rose-500' : pct > 70 ? 'bg-amber-500' : 'bg-emerald-500')} style={{width: pct + '%'}} />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* Enterprise Contact Modal */}
      {showContactModal && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-6">
          <div className="bg-slate-900 rounded-3xl border border-white/10 p-8 max-w-md w-full">
            <h3 className="text-2xl font-bold mb-2">{t('talk_to_sales')}</h3>
            <p className="text-slate-400 text-sm mb-6">{t('plan_enterprise_tag')}</p>
            {contactSent ? (
              <div className="text-center py-8">
                <div className="text-4xl mb-3">✅</div>
                <div className="font-bold text-white mb-1">Message sent!</div>
                <div className="text-sm text-slate-400">Our sales team will contact you within 1 business day.</div>
                <button onClick={() => { setShowContactModal(false); setContactSent(false); }} className="mt-6 px-6 py-2 bg-slate-800 rounded-xl text-sm font-semibold hover:bg-slate-700 transition-colors">{t('close')}</button>
              </div>
            ) : (
              <>
                <div className="space-y-4">
                  <div>
                    <label className="text-sm font-medium text-slate-300 block mb-1.5">{t('work_email')}</label>
                    <input value={contactEmail} onChange={e => setContactEmail(e.target.value)}
                      className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none focus:border-emerald-500 transition-colors" placeholder="you@company.com" />
                  </div>
                  <div>
                    <label className="text-sm font-medium text-slate-300 block mb-1.5">{t('company_size')}</label>
                    <select value={contactSize} onChange={e => setContactSize(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none focus:border-emerald-500 transition-colors">
                      {['1–10','11–50','51–200','201–500','500+'].map(o => <option key={o}>{o}</option>)}
                    </select>
                  </div>
                </div>
                <div className="flex gap-3 mt-6">
                  <button onClick={() => setShowContactModal(false)} className="flex-1 py-3 bg-slate-800 rounded-xl font-semibold text-sm hover:bg-slate-700 transition-colors">{t('cancel')}</button>
                  <button onClick={() => { window.open('mailto:sales@saasguard.io?subject=Enterprise%20Enquiry&body=Email%3A%20' + encodeURIComponent(contactEmail) + '%0ASize%3A%20' + encodeURIComponent(contactSize)); setContactSent(true); }}
                    className="flex-1 py-3 bg-gradient-to-r from-amber-600 to-orange-600 hover:opacity-90 rounded-xl font-bold text-sm text-white transition-all">
                    {t('send_enquiry')}
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </AppShell>
  );
}


function IntegrationConnectors() {
  const { language } = useLang();
  const t = useTranslation(language);
  const [connectedIntegrations, setConnectedIntegrations] = useState(['google-workspace', 'slack']);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedStatus, setSelectedStatus] = useState('all');
  
  const integrations = [
    {
      id: 'google-workspace',
      name: 'Google Workspace',
      description: 'Import users, track licenses, scan Gmail for invoices',
      icon: '🔵',
      category: 'Identity & Directory',
      features: ['User Sync', 'License Detection', 'Invoice Scanning'],
      status: 'available',
      setupTime: '5 min',
    },
    {
      id: 'slack',
      name: 'Slack',
      description: 'Send alerts, track usage, manage members',
      icon: '💬',
      category: 'Communication',
      features: ['User Sync', 'Usage Analytics', 'Alert Notifications'],
      status: 'available',
      setupTime: '3 min',
    },
    {
      id: 'microsoft-365',
      name: 'Microsoft 365',
      description: 'Azure AD sync, license tracking, usage monitoring',
      icon: '🟦',
      category: 'Identity & Directory',
      features: ['Azure AD Sync', 'License Management', 'Usage Reports'],
      status: 'available',
      setupTime: '5 min',
    },
    {
      id: 'github',
      name: 'GitHub',
      description: 'Track seats, monitor activity, manage team access',
      icon: '🐙',
      category: 'Development',
      features: ['Seat Tracking', 'Activity Monitoring', 'Team Management'],
      status: 'available',
      setupTime: '2 min',
    },
    {
      id: 'okta',
      name: 'Okta',
      description: 'SSO integration, user provisioning, app discovery',
      icon: '🔐',
      category: 'Identity & Directory',
      features: ['SSO', 'User Provisioning', 'App Discovery'],
      status: 'available',
      setupTime: '10 min',
    },
    {
      id: 'salesforce',
      name: 'Salesforce',
      description: 'Track licenses, monitor usage, optimize seats',
      icon: '☁️',
      category: 'CRM',
      features: ['License Tracking', 'Usage Monitoring', 'Cost Optimization'],
      status: 'available',
      setupTime: '5 min',
    },
    {
      id: 'zoom',
      name: 'Zoom',
      description: 'Track meeting licenses, monitor usage',
      icon: '📹',
      category: 'Communication',
      features: ['License Management', 'Usage Analytics'],
      status: 'coming-soon',
      setupTime: '3 min',
    },
    {
      id: 'asana',
      name: 'Asana',
      description: 'Project management tool tracking',
      icon: '📊',
      category: 'Productivity',
      features: ['Seat Tracking', 'Usage Reports'],
      status: 'coming-soon',
      setupTime: '3 min',
    },
  ];

  const handleConnect = (integrationId) => {
    if (connectedIntegrations.includes(integrationId)) {
      setConnectedIntegrations(connectedIntegrations.filter(id => id !== integrationId));
    } else {
      setConnectedIntegrations([...connectedIntegrations, integrationId]);
    }
  };

  const isConnected = (id) => connectedIntegrations.includes(id);

  const filteredIntegrations = useMemo(() => {
    return integrations.filter(integration => {
      const matchesSearch = integration.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                           integration.description.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesCategory = selectedCategory === 'all' || integration.category === selectedCategory;
      const matchesStatus = selectedStatus === 'all' || 
                           (selectedStatus === 'connected' && isConnected(integration.id)) ||
                           (selectedStatus === 'available' && integration.status === 'available' && !isConnected(integration.id)) ||
                           (selectedStatus === 'coming-soon' && integration.status === 'coming-soon');
      return matchesSearch && matchesCategory && matchesStatus;
    });
  }, [searchQuery, selectedCategory, selectedStatus, connectedIntegrations]);

  const categories = ['all', ...new Set(integrations.map(i => i.category))];
  const connectedCount = connectedIntegrations.length;
  const availableCount = integrations.filter(i => i.status === 'available' && !isConnected(i.id)).length;
  const comingSoonCount = integrations.filter(i => i.status === 'coming-soon').length;

  return (
    <div className="space-y-6">
      {/* Stats Header */}
      <div className="bg-gradient-to-r from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
        <div className="flex items-center gap-4 mb-6">
          <div className="p-4 bg-blue-500/20 rounded-2xl">
            <Plug className="h-8 w-8 text-blue-400" />
          </div>
          <div className="flex-1">
            <h2 className="text-2xl font-black text-white">Integration Marketplace</h2>
            <p className="text-slate-400">Connect your tools to automate SaaS management</p>
          </div>
        </div>
        
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-blue-400">{integrations.length}</div>
            <div className="text-sm text-slate-400 mt-1">Total</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-emerald-400">{connectedCount}</div>
            <div className="text-sm text-slate-400 mt-1">{t('connected')}</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-purple-400">{availableCount}</div>
            <div className="text-sm text-slate-400 mt-1">{t('available')}</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-orange-400">{comingSoonCount}</div>
            <div className="text-sm text-slate-400 mt-1">{t('coming_soon')}</div>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
            <input
              type="text"
              placeholder={t('search_integrations')}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:border-blue-500"
            />
          </div>
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white focus:outline-none focus:border-blue-500"
          >
            {categories.map(cat => (
              <option key={cat} value={cat}>
                {cat === 'all' ? 'All Categories' : cat}
              </option>
            ))}
          </select>
          <select
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
            className="px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white focus:outline-none focus:border-blue-500"
          >
            <option value="all">{t('all_status')}</option>
            <option value="connected">{t('connected')}</option>
            <option value="available">{t('available')}</option>
            <option value="coming-soon">{t('coming_soon')}</option>
          </select>
        </div>
      </div>

      {/* Integration Cards - UNIFORM GRID */}
      {filteredIntegrations.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredIntegrations.map(integration => {
            const connected = isConnected(integration.id);
            const comingSoon = integration.status === 'coming-soon';

            return (
              <div
                key={integration.id}
                className="relative bg-slate-900 border rounded-2xl p-6 flex flex-col min-h-[380px] transition-all hover:shadow-lg"
                style={{
                  borderColor: connected ? 'rgba(16, 185, 129, 0.5)' : comingSoon ? 'rgba(71, 85, 105, 1)' : 'rgba(30, 41, 59, 1)',
                  backgroundColor: connected ? 'rgba(16, 185, 129, 0.05)' : 'rgb(15, 23, 42)',
                  opacity: comingSoon ? 0.7 : 1
                }}
              >
                {/* Status Badge */}
                <div className="absolute top-4 right-4">
                  {connected && (
                    <span className="px-3 py-1 bg-emerald-500/20 text-emerald-400 text-xs font-bold rounded-full flex items-center gap-1">
                      <CheckCircle className="h-3 w-3" />
                      Connected
                    </span>
                  )}
                  {comingSoon && (
                    <span className="px-3 py-1 bg-slate-700 text-slate-400 text-xs font-bold rounded-full">
                      Coming Soon
                    </span>
                  )}
                </div>

                {/* Icon & Title */}
                <div className="flex items-center gap-4 mb-4">
                  <div className="text-5xl">{integration.icon}</div>
                  <div className="flex-1">
                    <h4 className="text-xl font-bold text-white">{integration.name}</h4>
                    <div className="text-xs text-slate-500 mt-1">⏱️ {integration.setupTime} setup</div>
                  </div>
                </div>

                {/* Description */}
                <p className="text-sm text-slate-400 mb-4">{integration.description}</p>

                {/* Features */}
                <div className="space-y-2 mb-4 flex-grow">
                  {integration.features.map((feature, idx) => (
                    <div key={idx} className="flex items-center gap-2 text-sm text-slate-300">
                      <Check className="h-4 w-4 text-blue-400 flex-shrink-0" />
                      {feature}
                    </div>
                  ))}
                </div>

                {/* Connect Button */}
                <button
                  onClick={() => !comingSoon && handleConnect(integration.id)}
                  disabled={comingSoon}
                  className="w-full py-3 rounded-xl font-bold transition-all"
                  style={{
                    backgroundColor: connected ? 'rgb(71, 85, 105)' : comingSoon ? 'rgb(71, 85, 105)' : 'rgb(37, 99, 235)',
                    color: comingSoon ? 'rgb(148, 163, 184)' : 'white',
                    cursor: comingSoon ? 'not-allowed' : 'pointer'
                  }}
                  onMouseEnter={(e) => {
                    if (!comingSoon) {
                      e.currentTarget.style.backgroundColor = connected ? 'rgb(51, 65, 85)' : 'rgb(29, 78, 216)';
                    }
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = connected ? 'rgb(71, 85, 105)' : comingSoon ? 'rgb(71, 85, 105)' : 'rgb(37, 99, 235)';
                  }}
                >
                  {connected ? 'Disconnect' : comingSoon ? 'Coming Soon' : 'Connect'}
                </button>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-12 text-center">
          <div className="text-5xl mb-4">🔍</div>
          <h3 className="text-xl font-bold text-white mb-2">{t('no_integrations_found')}</h3>
          <p className="text-slate-400">{t('filter_adjust')}</p>
        </div>
      )}

      {/* Bottom Sections */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="text-xl font-bold text-white mb-2">{t('need_different_int')}</h3>
          <p className="text-slate-400 mb-4 text-sm">
            Let us know which tools you'd like us to support.
          </p>
          <button onClick={() => toast.info("Integration request form coming soon! For now, email: support@accessguard.com")} className="w-full px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-semibold transition-all">
            Request Integration
          </button>
        </div>

        <div className="bg-gradient-to-br from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
          <h3 className="text-xl font-bold text-white mb-2">{t('need_help')}</h3>
          <p className="text-slate-400 mb-4 text-sm">
            Our team is here to help you optimize your integrations.
          </p>
          <button onClick={() => toast.info("Support form coming soon! For now, email: support@accessguard.com")} className="w-full px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-semibold transition-all">
            Contact Support
          </button>
        </div>
      </div>
    </div>
  );
}

function IntegrationsPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  return (
    <AppShell title={"Integrations" || 'Integrations'}>
      <IntegrationConnectors />
    </AppShell>
  );
}


// ============================================================================
// NEW ENHANCED PAGES - Added for Security, Cost, Analytics, and Settings
// ============================================================================

function SecurityCompliancePage() {
  const [secActiveTab, setSecActiveTab] = useState('security');
  const { language } = useLang();
  const t = useTranslation(language);
  const navigate = useNavigate();
  const { data: db } = useDbQuery();
  const tools = db?.tools || [];
  
  // Calculate security metrics
  const criticalTools = tools.filter(t => t.criticality === 'high' && t.status === 'active').length;
  const orphanedTools = tools.filter(t => t.status === 'orphaned').length;
  const highRiskTools = tools.filter(t => t.risk_score === 'high').length;
  
  const securityScore = Math.max(0, 100 - (orphanedTools * 10) - (highRiskTools * 5));
  
  const alerts = [
    {
      type: 'critical',
      title: `${orphanedTools} orphaned tools detected`,
      description: 'These tools have no assigned owner and may pose security risks',
      tone: 'rose',
      icon: AlertTriangle,
      route: '/tools',
    },
    {
      type: 'warning',
      title: `${highRiskTools} high-risk tools need review`,
      description: `${t('review_admin_access')} and usage patterns for these applications`,
      tone: 'amber',
      icon: AlertTriangle,
      route: '/access',
    },
    {
      type: 'info',
      title: `${criticalTools} critical tools properly secured`,
      description: 'All critical applications have assigned owners and active monitoring',
      tone: 'green',
      icon: BadgeCheck,
      route: null,
    },
  ];

  return (
    <AppShell title={t('security_title')}
      right={
        <div className="flex items-center gap-2">
          <div className="flex gap-1 p-1 bg-slate-900 rounded-xl border border-slate-800">
            {[
              { id: 'security', label: '🛡️ Security' },
              { id: 'audit',    label: '📋 Audit Export' },
            ].map(tab => (
              <button key={tab.id} onClick={() => setSecActiveTab(tab.id)}
                className={"px-4 py-1.5 rounded-lg text-sm font-semibold transition-all " + (secActiveTab === tab.id ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white')}>
                {tab.label}
              </button>
            ))}
          </div>
        </div>
      }
    >
      {secActiveTab === 'security' && (
        <SecurityTabContent />
      )}
      {secActiveTab === 'audit' && (
        <AuditTabContent />
      )}
    </AppShell>
  );
}

function SecurityTabContent() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const navigate = useNavigate();

  const tools = db?.tools || [];
  const access = db?.access || [];
  const employees = db?.employees || [];

  const orphanedTools = tools.filter(t => t.status === 'active' && !t.owner_email).length;
  const highRiskTools = tools.filter(t => computeToolDerivedRisk(t) === 'high').length;
  const criticalTools = tools.filter(t => t.criticality === 'critical').length;
  const securityScore = Math.max(0, 100 - (orphanedTools * 10) - (highRiskTools * 5));

  const alerts = buildRiskAlerts({ tools, access, employees });

  return (
    <div className="p-6 space-y-5">
      {/* Security Score row */}
      <div className="grid gap-5 md:grid-cols-3">
        <Card>
          <CardHeader title={t('security_score')} subtitle={t('security_score_sub')} />
          <CardBody>
            <div className="flex items-center justify-center py-6">
              <div className="relative">
                <svg className="w-32 h-32">
                  <circle cx="64" cy="64" r="56" fill="none" stroke="rgb(51,65,85)" strokeWidth="8" />
                  <circle
                    cx="64" cy="64" r="56" fill="none"
                    stroke={securityScore >= 80 ? 'rgb(34,197,94)' : securityScore >= 60 ? 'rgb(251,191,36)' : 'rgb(239,68,68)'}
                    strokeWidth="8"
                    strokeDasharray={`${2 * Math.PI * 56}`}
                    strokeDashoffset={`${2 * Math.PI * 56 * (1 - securityScore / 100)}`}
                    strokeLinecap="round"
                    transform="rotate(-90 64 64)"
                  />
                </svg>
                <div className="absolute inset-0 flex items-center justify-center flex-col">
                  <div className="text-3xl font-bold text-slate-100">{securityScore}</div>
                  <div className="text-xs text-slate-400">/ 100</div>
                </div>
              </div>
            </div>
            <div className="text-center text-sm text-slate-400">
              {securityScore >= 80 ? 'Good' : securityScore >= 60 ? 'Fair' : 'Needs Attention'}
            </div>
          </CardBody>
        </Card>

        <Card>
          <CardHeader title={t('tools_tracked')} subtitle={t('active_tools_sub')} />
          <CardBody>
            <div className="text-4xl font-bold text-slate-100 mb-2">{tools.filter(t => t.status === 'active').length}</div>
            <div className="text-sm text-slate-400">{criticalTools} critical applications</div>
          </CardBody>
        </Card>

        <Card>
          <CardHeader title={t('risk_alerts')} subtitle={t('risk_alerts_sub')} />
          <CardBody>
            <div className="text-4xl font-bold text-rose-400 mb-2">{orphanedTools + highRiskTools}</div>
            <div className="text-sm text-slate-400">{orphanedTools} orphaned, {highRiskTools} high-risk</div>
          </CardBody>
        </Card>
      </div>

      {/* Security Alerts */}
      <Card>
        <CardHeader title={t('security_alerts')} subtitle={t('security_alerts_sub')} />
        <CardBody>
          <div className="space-y-3">
            {alerts.length === 0 && (
              <div className="text-center text-slate-500 py-6">No active alerts — all clear ✓</div>
            )}
            {alerts.map((alert, idx) => {
              const tone = alert.severity === 'critical' ? 'rose' : alert.severity === 'high' ? 'amber' : 'emerald';
              const AlertIcon = alert.action?.icon || Shield;
              return (
                <div key={idx} className={cx(
                  "flex items-start gap-3 rounded-2xl border p-4",
                  tone === 'rose' ? "border-rose-600/30 bg-rose-600/5" :
                  tone === 'amber' ? "border-amber-500/30 bg-amber-500/5" :
                  "border-emerald-600/30 bg-emerald-600/5"
                )}>
                  <AlertIcon className={cx(
                    "h-5 w-5 mt-0.5 flex-shrink-0",
                    tone === 'rose' ? "text-rose-400" :
                    tone === 'amber' ? "text-amber-400" : "text-emerald-400"
                  )} />
                  <div className="flex-1">
                    <div className={cx("font-semibold mb-1",
                      tone === 'rose' ? "text-rose-100" :
                      tone === 'amber' ? "text-amber-100" : "text-emerald-100"
                    )}>{alert.title}</div>
                    <div className="text-sm text-slate-400">{alert.body || alert.description}</div>
                  </div>
                  {alert.action && (
                    <Button variant="secondary" size="sm" onClick={() => navigate(alert.action.to)}>
                      {alert.action.label}
                    </Button>
                  )}
                </div>
              );
            })}
          </div>
        </CardBody>
      </Card>

      {/* Compliance Status */}
      <Card>
        <CardHeader title={t('compliance_status')} subtitle={t('compliance_status_sub')} />
        <CardBody>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { name: 'SOC 2', status: 'compliant' },
              { name: 'GDPR', status: 'compliant' },
              { name: 'HIPAA', status: 'non-compliant' },
              { name: 'ISO 27001', status: 'compliant' },
            ].map((compliance) => (
              <div key={compliance.name} className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4 text-center">
                <div className="font-semibold text-slate-100 mb-2">{compliance.name}</div>
                {compliance.status === 'compliant' ? (
                  <div className="flex items-center justify-center gap-2 text-emerald-400">
                    <BadgeCheck className="h-4 w-4" />
                    <span className="text-sm font-medium">Compliant</span>
                  </div>
                ) : (
                  <div className="flex items-center justify-center gap-2 text-rose-400">
                    <BadgeX className="h-4 w-4" />
                    <span className="text-sm font-medium">Non-Compliant</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        </CardBody>
      </Card>
    </div>
  );
}


function CostManagementPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const navigate = useNavigate();
  const [sortBy, setSortBy] = useState('cost');
  const [filter, setFilter] = useState('all');

  const tools = db?.tools || [];
  const access = db?.access || [];

  const enriched = tools
    .filter(t => t.status === 'active')
    .map(tool => {
      const activeUsers = access.filter(a => a.tool_id === tool.id && a.access_status === 'active').length;
      const cost = Number(tool.cost_per_month || 0);
      const costPerUser = activeUsers > 0 ? cost / activeUsers : cost;
      const wasteFlag = activeUsers === 0 || costPerUser > 200;
      return { ...tool, activeUsers, cost, costPerUser, wasteFlag };
    })
    .filter(t => filter === 'all' ? true : filter === 'waste' ? t.wasteFlag : !t.wasteFlag)
    .sort((a, b) => sortBy === 'cost' ? b.cost - a.cost : b.costPerUser - a.costPerUser);

  const totalSpend = tools.filter(t => t.status === 'active').reduce((s, t) => s + Number(t.cost_per_month || 0), 0);
  const wasteTools = enriched.filter(t => t.wasteFlag);
  const wasteAmount = wasteTools.reduce((s, t) => s + t.cost, 0);
  const unusedTools = enriched.filter(t => t.activeUsers === 0);

  return (
    <AppShell title="Cost Management">
      <div className="p-6 space-y-6">
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div>
            <h1 className="text-3xl font-black text-white mb-1">💸 Cost Management</h1>
            <p className="text-slate-400">Find waste, optimise spend, reclaim unused licenses</p>
          </div>
          <button onClick={() => navigate('/licenses')} className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors text-sm">
            Manage Licenses →
          </button>
        </div>

        {/* KPIs */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {[
            { label: 'Total Monthly Spend', value: '$' + totalSpend.toLocaleString(), sub: tools.filter(t=>t.status==='active').length + ' active tools', color: 'text-white', Icon: BarChart3 },
            { label: 'Estimated Waste', value: '$' + wasteAmount.toLocaleString(), sub: wasteTools.length + ' flagged tools', color: 'text-rose-400', Icon: TrendingDown },
            { label: 'Unused Tools', value: unusedTools.length, sub: 'no active users assigned', color: 'text-amber-400', Icon: Zap },
            { label: 'Potential Savings', value: '$' + Math.round(wasteAmount * 0.7).toLocaleString(), sub: 'if waste reclaimed', color: 'text-emerald-400', Icon: Target },
          ].map(({ label, value, sub, color, Icon }) => (
            <Card key={label}><CardBody>
              <div className="flex items-start justify-between gap-2">
                <div><div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>
                  <div className={"text-2xl font-black " + color}>{value}</div>
                  <div className="text-xs text-slate-500 mt-1">{sub}</div>
                </div>
                <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center flex-shrink-0">
                  <Icon className={"h-4 w-4 " + color} />
                </div>
              </div>
            </CardBody></Card>
          ))}
        </div>

        {/* Waste Alert */}
        {wasteTools.length > 0 && (
          <Card className="p-5 bg-amber-500/5 border-amber-500/20">
            <div className="flex items-start gap-3">
              <AlertTriangle className="h-5 w-5 text-amber-400 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <div className="font-bold text-white mb-1">⚠️ {wasteTools.length} tools flagged as potential waste</div>
                <p className="text-sm text-slate-400">Tools with no active users or very high cost-per-user. Review and consider cancelling or renegotiating.</p>
              </div>
              <button onClick={() => setFilter('waste')} className="text-sm text-amber-400 font-semibold hover:text-amber-300 whitespace-nowrap">{t('filter')}</button>
            </div>
          </Card>
        )}

        {/* Tools Table */}
        <Card className="p-6">
          <div className="flex items-center justify-between mb-4 flex-wrap gap-3">
            <h2 className="text-xl font-bold">Tool Cost Breakdown</h2>
            <div className="flex gap-2 flex-wrap">
              {[['all','All Tools'],['waste','Waste Only'],['ok','Healthy']].map(([v,l]) => (
                <button key={v} onClick={() => setFilter(v)}
                  className={"px-3 py-1.5 rounded-lg text-sm font-semibold transition-colors " + (filter === v ? 'bg-emerald-600 text-white' : 'bg-slate-800 text-slate-400 hover:text-white')}>
                  {l}
                </button>
              ))}
              <select value={sortBy} onChange={e => setSortBy(e.target.value)}
                className="px-3 py-1.5 rounded-lg text-sm bg-slate-800 text-slate-300 border-0 outline-none">
                <option value="cost">{t('total_cost')}</option>
                <option value="peruser">{t('cost_per_user')}</option>
              </select>
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-800">
                  {['Tool','Category','Monthly Cost','Active Users','Cost / User','Status'].map(h => (
                    <th key={h} className="text-left py-3 px-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {enriched.map((tool, i) => (
                  <tr key={tool.id || i} className="border-b border-slate-800/60 hover:bg-slate-800/30 transition-colors">
                    <td className="py-3 px-3">
                      <div className="font-semibold text-white">{tool.name}</div>
                      <div className="text-xs text-slate-500">{tool.owner || 'No owner'}</div>
                    </td>
                    <td className="py-3 px-3 text-slate-400 text-sm">{tool.category || '—'}</td>
                    <td className="py-3 px-3 font-mono font-bold text-white">${tool.cost.toLocaleString()}</td>
                    <td className="py-3 px-3 text-center">
                      <span className={"font-bold " + (tool.activeUsers === 0 ? 'text-rose-400' : 'text-slate-300')}>{tool.activeUsers}</span>
                    </td>
                    <td className="py-3 px-3 font-mono text-sm text-slate-300">${tool.costPerUser.toFixed(0)}</td>
                    <td className="py-3 px-3">
                      {tool.wasteFlag
                        ? <span className="inline-flex items-center gap-1 text-xs font-semibold text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded-full">⚠ Review</span>
                        : <span className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full">✓ OK</span>
                      }
                    </td>
                  </tr>
                ))}
                {enriched.length === 0 && (
                  <tr><td colSpan={6} className="text-center text-slate-500 py-12">No tools match this filter</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </AppShell>
  );
}

function AnalyticsReportsPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const navigate = useNavigate();

  const tools = db?.tools || [];
  const employees = db?.employees || [];
  const access = db?.access || [];

  const activeTools = tools.filter(t => t.status === 'active');
  const totalSpend = activeTools.reduce((s, t) => s + Number(t.cost_per_month || 0), 0);
  const inactiveUsers = employees.filter(e => e.status === 'inactive' || e.status === 'former').length;

  const categorySpend = Object.values(
    activeTools.reduce((acc, t) => {
      const cat = t.category || 'Other';
      if (!acc[cat]) acc[cat] = { name: cat, spend: 0, count: 0 };
      acc[cat].spend += Number(t.cost_per_month || 0);
      acc[cat].count++;
      return acc;
    }, {})
  ).sort((a, b) => b.spend - a.spend).slice(0, 6);

  const topTools = [...activeTools]
    .sort((a, b) => Number(b.cost_per_month || 0) - Number(a.cost_per_month || 0))
    .slice(0, 8);

  const deptBreakdown = Object.entries(
    employees.reduce((acc, e) => {
      const dept = e.department || 'Other';
      if (!acc[dept]) acc[dept] = { active: 0, inactive: 0 };
      if (e.status === 'active') acc[dept].active++;
      else acc[dept].inactive++;
      return acc;
    }, {})
  ).map(([name, v]) => ({ name, ...v, total: v.active + v.inactive }))
   .sort((a, b) => b.total - a.total).slice(0, 6);

  const exportCSV = () => {
    const rows = [
      ['Category','Monthly Spend','Tool Count'],
      ...categorySpend.map(c => [c.name, c.spend, c.count]),
    ].map(r => r.join(',')).join('\n');
    const a = document.createElement('a');
    a.href = 'data:text/csv,' + encodeURIComponent(rows);
    a.download = 'saasguard-analytics.csv';
    a.click();
  };

  const kpis = [
    { label: 'Total Active Tools', value: activeTools.length, sub: tools.length + ' total tracked', color: 'text-white', Icon: Boxes },
    { label: 'Monthly SaaS Spend', value: '$' + totalSpend.toLocaleString(), sub: 'across ' + activeTools.length + ' tools', color: 'text-emerald-400', Icon: BarChart3 },
    { label: 'Avg Cost Per Tool', value: '$' + (activeTools.length ? Math.round(totalSpend / activeTools.length).toLocaleString() : 0), sub: 'per month', color: 'text-teal-400', Icon: TrendingDown },
    { label: 'Inactive Employees', value: inactiveUsers, sub: 'may retain access', color: 'text-amber-400', Icon: Users },
  ];

  return (
    <AppShell title={t('analytics_title')}>
      <div className="p-6 space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-black text-white mb-1">📊 Analytics & Reports</h1>
            <p className="text-slate-400">Live insights across your entire SaaS stack</p>
          </div>
          <button onClick={exportCSV} className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors text-sm">
            <Download className="h-4 w-4" /> Export CSV
          </button>
        </div>

        {/* KPI Strip */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {kpis.map(({ label, value, sub, color, Icon }) => (
            <Card key={label}><CardBody>
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0 flex-1">
                  <div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>
                  <div className={"text-2xl font-black " + color}>{value}</div>
                  <div className="text-xs text-slate-500 mt-1">{sub}</div>
                </div>
                <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center flex-shrink-0">
                  <Icon className={"h-4 w-4 " + color} />
                </div>
              </div>
            </CardBody></Card>
          ))}
        </div>

        <div className="grid lg:grid-cols-2 gap-6">
          {/* Spend by Category Chart */}
          <Card className="p-6">
            <h2 className="text-xl font-bold mb-4">💰 Spend by Category</h2>
            <div className="space-y-3">
              {categorySpend.map((cat, i) => {
                const pct = totalSpend > 0 ? (cat.spend / totalSpend * 100) : 0;
                const colors = ['bg-emerald-500','bg-teal-500','bg-blue-500','bg-violet-500','bg-amber-500','bg-rose-500'];
                return (
                  <div key={cat.name}>
                    <div className="flex items-center justify-between mb-1.5">
                      <span className="text-sm font-semibold text-slate-200">{cat.name}</span>
                      <div className="flex items-center gap-3">
                        <span className="text-xs text-slate-500">{cat.count} tools</span>
                        <span className="text-sm font-bold text-white">${cat.spend.toLocaleString()}</span>
                      </div>
                    </div>
                    <div className="w-full bg-slate-800 rounded-full h-2.5">
                      <div className={"h-2.5 rounded-full transition-all duration-700 " + colors[i % colors.length]} style={{width: pct + '%'}} />
                    </div>
                  </div>
                );
              })}
            </div>
          </Card>

          {/* Top Tools by Cost */}
          <Card className="p-6">
            <h2 className="text-xl font-bold mb-4">🏆 Top Tools by Cost</h2>
            <div className="space-y-2">
              {topTools.map((tool, i) => (
                <div key={tool.id} className="flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-800/60 transition-colors">
                  <div className="flex-shrink-0 h-7 w-7 rounded-lg bg-gradient-to-br from-emerald-500/20 to-teal-500/20 flex items-center justify-center text-xs font-bold text-emerald-400">
                    {i + 1}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="font-semibold text-sm text-white truncate">{tool.name}</div>
                    <div className="text-xs text-slate-500">{tool.category || 'General'}</div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <div className="text-sm font-bold text-white">${Number(tool.cost_per_month || 0).toLocaleString()}</div>
                    <div className="text-xs text-slate-500">/mo</div>
                  </div>
                </div>
              ))}
              {topTools.length === 0 && <div className="text-center text-slate-500 py-8">{t('no_tools_yet')}</div>}
            </div>
          </Card>
        </div>

        {/* Department Breakdown */}
        <Card className="p-6">
          <h2 className="text-xl font-bold mb-4">🏢 Department Breakdown</h2>
          {deptBreakdown.length > 0 ? (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {deptBreakdown.map(dept => (
                <div key={dept.name} className="p-4 rounded-xl bg-slate-900/60 border border-slate-800">
                  <div className="font-semibold text-white mb-2">{dept.name}</div>
                  <div className="flex gap-4 text-sm">
                    <div><span className="text-emerald-400 font-bold">{dept.active}</span><span className="text-slate-500 ml-1">active</span></div>
                    <div><span className="text-amber-400 font-bold">{dept.inactive}</span><span className="text-slate-500 ml-1">inactive</span></div>
                  </div>
                  <div className="mt-2 w-full bg-slate-800 rounded-full h-1.5">
                    <div className="bg-emerald-500 h-1.5 rounded-full" style={{width: dept.total > 0 ? (dept.active/dept.total*100)+'%' : '0%'}} />
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center text-slate-500 py-12">{t('add_employees_to_see')}</div>
          )}
        </Card>

        {/* Quick Links */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            { label: 'View Finance', to: '/finance', icon: BarChart3, color: 'emerald' },
            { label: 'Manage Licenses', to: '/licenses', icon: Award, color: 'teal' },
            { label: 'Audit Export', to: '/audit', icon: Download, color: 'blue' },
            { label: 'Security Report', to: '/security', icon: Shield, color: 'violet' },
          ].map(({ label, to, icon: Icon, color }) => (
            <button key={to} onClick={() => navigate(to)}
              className={"flex items-center gap-2 p-3 rounded-xl border transition-colors text-sm font-semibold border-slate-800 hover:border-" + color + "-500/40 hover:bg-" + color + "-500/5 text-slate-300 hover:text-white"}>
              <Icon className="h-4 w-4" />{label}
            </button>
          ))}
        </div>
      </div>
    </AppShell>
  );
}

function SettingsPage() {
  const { language, setLanguage } = useLang();
  const t = useTranslation(language);
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('general');
  const [saveMsg, setSaveMsg] = useState('');

  const saved = JSON.parse(localStorage.getItem('sg_general') || '{}');
  const [orgName, setOrgName] = useState(saved.orgName || 'My Organisation');
  const [timezone, setTimezone] = useState(saved.timezone || 'Europe/London');
  const [currency, setCurrency] = useState(saved.currency || 'GBP (£)');
  const [dateFormat, setDateFormat] = useState(saved.dateFormat || 'DD/MM/YYYY');

  const savedSec = JSON.parse(localStorage.getItem('sg_security') || '{}');
  const [mfaEnabled, setMfaEnabled] = useState(savedSec.mfa ?? false);
  const [sessionTimeout, setSessionTimeout] = useState(savedSec.timeout || '60');
  const [ipRestrict, setIpRestrict] = useState(savedSec.ipRestrict ?? false);
  const [auditLog, setAuditLog] = useState(savedSec.auditLog ?? true);

  const [apiKeys, setApiKeys] = useState([
    { id: 'key_1', name: 'Production API', created: '2025-12-01', lastUsed: '2026-03-05', prefix: 'sg_live_••••••••••' },
    { id: 'key_2', name: 'Dev / Testing', created: '2026-01-15', lastUsed: 'Never', prefix: 'sg_test_••••••••••' },
  ]);
  const [newKeyName, setNewKeyName] = useState('');
  const [showNewKey, setShowNewKey] = useState(null);

  const [members, setMembers] = useState([
    { id: 1, name: 'Roland D.', email: 'roland@saasguard.io', role: 'Owner', joined: '2025-11-01', avatar: 'R' },
    { id: 2, name: 'Sarah Chen', email: 'sarah@saasguard.io', role: 'Admin', joined: '2025-12-10', avatar: 'S' },
    { id: 3, name: 'Mike Johnson', email: 'mike@saasguard.io', role: 'Viewer', joined: '2026-01-20', avatar: 'M' },
  ]);
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteRole, setInviteRole] = useState('Viewer');
  const [inviteSent, setInviteSent] = useState(false);

  const save = (key, data) => {
    localStorage.setItem(key, JSON.stringify(data));
    setSaveMsg(t('saved_msg'));
    setTimeout(() => setSaveMsg(''), 2000);
  };

  const generateApiKey = () => {
    if (!newKeyName.trim()) return;
    const key = 'sg_live_' + Math.random().toString(36).slice(2, 18);
    const newK = { id: 'key_' + Date.now(), name: newKeyName, created: new Date().toISOString().slice(0,10), lastUsed: 'Never', prefix: key.slice(0,16) + '••••' };
    setApiKeys(prev => [...prev, newK]);
    setShowNewKey(key);
    setNewKeyName('');
  };

  const tabs = [
    { id: 'general',       label: t('settings_general'),       icon: Wrench },
    { id: 'team',          label: t('settings_team'),          icon: Users },
    { id: 'notifications', label: t('settings_notifications'), icon: Bell },
    { id: 'security',      label: t('settings_security'),      icon: Shield },
    { id: 'api',           label: t('settings_api'),           icon: Zap },
    { id: 'data',          label: t('settings_data'),          icon: Download },
  ];

  const Toggle = ({ checked, onChange }) => (
    <button onClick={() => onChange(!checked)} className={"relative w-11 h-6 rounded-full transition-colors " + (checked ? 'bg-emerald-500' : 'bg-slate-700')}>
      <div className={"absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform " + (checked ? 'translate-x-5' : 'translate-x-0.5')} />
    </button>
  );

  return (
    <AppShell title={t('settings_title')}>
      <div className="p-4 flex gap-5">
        {/* Sidebar tabs */}
        <div className="w-48 flex-shrink-0">
          <Card className="p-2">
            <nav className="space-y-0.5">
              {tabs.map(tab => {
                const Icon = tab.icon;
                return (
                  <button key={tab.id} onClick={() => setActiveTab(tab.id)}
                    className={"w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-left transition-colors text-sm " + (activeTab === tab.id ? 'bg-emerald-600/20 text-emerald-300 font-semibold' : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200')}>
                    <Icon className="h-4 w-4 flex-shrink-0" />{tab.label}
                  </button>
                );
              })}
            </nav>
          </Card>
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0 space-y-4">

          {/* ── GENERAL ── */}
          {activeTab === 'general' && (
            <Card>
              <CardHeader title={t('general_settings')} subtitle={t('general_settings_sub')} />
              <CardBody>
                <div className="space-y-5 max-w-lg">
                  {[
                    { label:'Organisation Name', el: <input value={orgName} onChange={e=>setOrgName(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none focus:border-emerald-500 transition-colors" placeholder="Acme Corp" /> },
                    { label:'Default Currency', el: <select value={currency} onChange={e=>setCurrency(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none"><option>GBP (£)</option><option>USD ($)</option><option>EUR (€)</option><option>JPY (¥)</option></select> },
                    { label:'Time Zone', el: <select value={timezone} onChange={e=>setTimezone(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none"><option>Europe/London</option><option>UTC</option><option>America/New_York</option><option>America/Los_Angeles</option><option>Europe/Paris</option><option>Asia/Tokyo</option></select> },
                    { label:'Date Format', el: <select value={dateFormat} onChange={e=>setDateFormat(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none"><option>DD/MM/YYYY</option><option>MM/DD/YYYY</option><option>YYYY-MM-DD</option></select> },
                    { label:'Language', el: <select value={language} onChange={e=>setLanguage(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none"><option value="en">English</option><option value="fr">Français</option><option value="de">Deutsch</option><option value="es">Español</option><option value="ja">日本語</option></select> },
                  ].map(({ label, el }) => (
                    <div key={label}>
                      <label className="block text-sm font-medium text-slate-300 mb-1.5">{label}</label>
                      {el}
                    </div>
                  ))}
                  <div className="flex items-center gap-3 pt-2">
                    <button onClick={() => save('sg_general', { orgName, timezone, currency, dateFormat })}
                      className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold text-sm transition-colors">
                      Save Changes
                    </button>
                    {saveMsg && <span className="text-sm text-emerald-400 font-semibold">{saveMsg}</span>}
                  </div>
                </div>
              </CardBody>
            </Card>
          )}

          {/* ── TEAM ── */}
          {activeTab === 'team' && (
            <div className="space-y-4">
              <Card>
                <CardHeader title={t('team_members')} subtitle={members.length + " members with access to SaasGuard"} />
                <CardBody>
                  <div className="space-y-2">
                    {members.map(m => (
                      <div key={m.id} className="flex items-center gap-4 p-3 rounded-xl hover:bg-slate-800/50 transition-colors">
                        <div className="h-9 w-9 rounded-full bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center text-white font-bold text-sm flex-shrink-0">{m.avatar}</div>
                        <div className="flex-1 min-w-0">
                          <div className="font-semibold text-white text-sm">{m.name}</div>
                          <div className="text-xs text-slate-500">{m.email}</div>
                        </div>
                        <span className={"text-xs font-semibold px-2.5 py-1 rounded-full " + (m.role === 'Owner' ? 'bg-violet-500/15 text-violet-400' : m.role === 'Admin' ? 'bg-blue-500/15 text-blue-400' : 'bg-slate-700 text-slate-400')}>{m.role}</span>
                        <div className="text-xs text-slate-600">Joined {m.joined}</div>
                        {m.role !== 'Owner' && (
                          <button onClick={() => setMembers(prev => prev.filter(x => x.id !== m.id))} className="text-xs text-rose-500 hover:text-rose-400 transition-colors">Remove</button>
                        )}
                      </div>
                    ))}
                  </div>
                </CardBody>
              </Card>
              <Card>
                <CardHeader title="Invite Team Member" subtitle={t('invite_sub')} />
                <CardBody>
                  {inviteSent ? (
                    <div className="text-center py-4">
                      <div className="text-3xl mb-2">📧</div>
                      <div className="font-bold text-white mb-1">{t('invite_sent_to')} {inviteEmail}</div>
                      <button onClick={() => { setInviteSent(false); setInviteEmail(''); }} className="text-sm text-emerald-400 hover:underline mt-2">{t('invite_another')}</button>
                    </div>
                  ) : (
                    <div className="flex gap-3 flex-wrap">
                      <input value={inviteEmail} onChange={e => setInviteEmail(e.target.value)}
                        className="flex-1 min-w-48 bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none focus:border-emerald-500 transition-colors" placeholder="colleague@company.com" />
                      <select value={inviteRole} onChange={e => setInviteRole(e.target.value)}
                        className="bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none">
                        <option>{t('viewer')}</option><option>{t('admin')}</option>
                      </select>
                      <button onClick={() => { if (inviteEmail) { window.open('mailto:' + inviteEmail + '?subject=Join%20SaasGuard&body=You%27ve%20been%20invited%20to%20SaasGuard.%20Sign%20in%20at%3A%20https%3A%2F%2Faccessguard-v2.web.app'); setInviteSent(true); } }}
                        className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold text-sm transition-colors whitespace-nowrap">
                        Send Invite
                      </button>
                    </div>
                  )}
                </CardBody>
              </Card>
            </div>
          )}

          {/* ── NOTIFICATIONS ── */}
          {activeTab === 'notifications' && (
            <Card>
              <CardHeader title={t('notifications_title')} subtitle={t('notifications_sub')} />
              <CardBody>
                <div className="space-y-1">
                  {[
                    { label: 'New tool added to inventory', sub: 'When a tool is added via import or manually', defaultOn: true },
                    { label: 'Orphaned tool detected', sub: 'Tools with no assigned owner', defaultOn: true },
                    { label: 'High-risk access granted', sub: 'Admin access given to a new user', defaultOn: true },
                    { label: 'Employee offboarding initiated', sub: 'When an offboarding task is started', defaultOn: true },
                    { label: 'Renewal due in 30 days', sub: 'SaaS contract coming up for renewal', defaultOn: true },
                    { label: 'Compliance report ready', sub: 'Weekly compliance digest', defaultOn: false },
                    { label: 'Weekly summary email', sub: 'Overview of spend, risk and usage', defaultOn: true },
                    { label: 'Invoice approval required', sub: 'New invoice needs sign-off', defaultOn: false },
                    { label: t('budget_limit'), sub: 'Monthly spend passes your set limit', defaultOn: true },
                  ].map(n => (
                    <div key={n.label} className="flex items-center justify-between py-3.5 border-b border-slate-800 last:border-0">
                      <div>
                        <div className="text-sm font-medium text-slate-200">{n.label}</div>
                        <div className="text-xs text-slate-500 mt-0.5">{n.sub}</div>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer flex-shrink-0 ml-4">
                        <input type="checkbox" className="sr-only peer" defaultChecked={n.defaultOn} />
                        <div className="w-11 h-6 bg-slate-700 rounded-full peer peer-checked:bg-emerald-600 peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all" />
                      </label>
                    </div>
                  ))}
                </div>
              </CardBody>
            </Card>
          )}

          {/* ── SECURITY ── */}
          {activeTab === 'security' && (
            <div className="space-y-4">
              <Card>
                <CardHeader title={t('security_settings')} subtitle={t('security_settings_sub')} />
                <CardBody>
                  <div className="space-y-4">
                    {[
                      { label: t('require_mfa'), sub: t('require_mfa_sub'), key: 'mfa', val: mfaEnabled, set: setMfaEnabled },
                      { label: t('ip_restriction'), sub: t('ip_restriction_sub'), key: 'ip', val: ipRestrict, set: setIpRestrict },
                      { label: t('audit_logging'), sub: t('audit_logging_sub'), key: 'audit', val: auditLog, set: setAuditLog },
                    ].map(item => (
                      <div key={item.key} className="flex items-center justify-between py-3 border-b border-slate-800 last:border-0">
                        <div>
                          <div className="font-medium text-slate-200 text-sm">{item.label}</div>
                          <div className="text-xs text-slate-500 mt-0.5">{item.sub}</div>
                        </div>
                        <Toggle checked={item.val} onChange={item.set} />
                      </div>
                    ))}
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-1.5">{t('session_timeout')}</label>
                      <select value={sessionTimeout} onChange={e => setSessionTimeout(e.target.value)}
                        className="bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none focus:border-emerald-500">
                        <option value="15">{t('min_15')}</option><option value="30">{t('min_30')}</option><option value="60">{t('hr_1')}</option><option value="480">{t('hr_8')}</option><option value="0">{t('never')}</option>
                      </select>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 mt-5">
                    <button onClick={() => save('sg_security', { mfa: mfaEnabled, timeout: sessionTimeout, ipRestrict, auditLog })}
                      className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold text-sm transition-colors">
                      Save Security Settings
                    </button>
                    {saveMsg && <span className="text-sm text-emerald-400 font-semibold">{saveMsg}</span>}
                  </div>
                </CardBody>
              </Card>
              <Card className="border-amber-500/20 bg-amber-500/5">
                <CardBody>
                  <div className="flex items-start gap-3">
                    <AlertTriangle className="h-5 w-5 text-amber-400 flex-shrink-0 mt-0.5" />
                    <div>
                      <div className="font-bold text-white text-sm mb-1">{t('sso_enterprise')}</div>
                      <p className="text-xs text-slate-400">Connect your Okta, Azure AD, or Google Workspace SSO to enforce centralised authentication.</p>
                      <button onClick={() => navigate('/billing')} className="text-xs text-amber-400 font-semibold hover:underline mt-2 inline-block">View Enterprise Plan →</button>
                    </div>
                  </div>
                </CardBody>
              </Card>
            </div>
          )}

          {/* ── API KEYS ── */}
          {activeTab === 'api' && (
            <div className="space-y-4">
              <Card>
                <CardHeader title={t('api_keys_title')} subtitle={t('api_keys_sub')} />
                <CardBody>
                  {showNewKey && (
                    <div className="mb-4 p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20">
                      <div className="text-sm font-bold text-emerald-400 mb-1">✓ New API key generated — copy it now, it won't be shown again</div>
                      <div className="font-mono text-xs bg-slate-900 px-3 py-2 rounded-lg text-white break-all">{showNewKey}</div>
                      <button onClick={() => { navigator.clipboard.writeText(showNewKey); }} className="text-xs text-emerald-400 mt-2 hover:underline">Copy to clipboard</button>
                    </div>
                  )}
                  <div className="space-y-3">
                    {apiKeys.map(k => (
                      <div key={k.id} className="flex items-center gap-4 p-3 rounded-xl bg-slate-900/60 border border-slate-800">
                        <Zap className="h-4 w-4 text-slate-500 flex-shrink-0" />
                        <div className="flex-1 min-w-0">
                          <div className="font-semibold text-white text-sm">{k.name}</div>
                          <div className="font-mono text-xs text-slate-500">{k.prefix}</div>
                        </div>
                        <div className="text-right text-xs text-slate-600">
                          <div>Created {k.created}</div>
                          <div>Last used: {k.lastUsed}</div>
                        </div>
                        <button onClick={() => setApiKeys(prev => prev.filter(x => x.id !== k.id))} className="text-xs text-rose-500 hover:text-rose-400 transition-colors flex-shrink-0">{t('revoke')}</button>
                      </div>
                    ))}
                  </div>
                </CardBody>
              </Card>
              <Card>
                <CardHeader title="Generate New Key" subtitle="Name it so you remember what it's for" />
                <CardBody>
                  <div className="flex gap-3">
                    <input value={newKeyName} onChange={e => setNewKeyName(e.target.value)}
                      className="flex-1 bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm outline-none focus:border-emerald-500 transition-colors" placeholder={t('key_name_placeholder')} />
                    <button onClick={generateApiKey}
                      className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold text-sm transition-colors whitespace-nowrap">
                      Generate Key
                    </button>
                  </div>
                </CardBody>
              </Card>
            </div>
          )}

          {/* ── DATA & PRIVACY ── */}
          {activeTab === 'data' && (
            <div className="space-y-4">
              <Card>
                <CardHeader title={t('export_data')} subtitle={t('export_data_sub')} />
                <CardBody>
                  <div className="grid sm:grid-cols-3 gap-3">
                    {[
                      { label: 'Tools & Licenses', desc: 'All tool records, costs, owners', icon: Boxes },
                      { label: 'Employees & Access', desc: 'Employee directory and access map', icon: Users },
                      { label: 'Audit Log', desc: 'Full history of all actions', icon: Download },
                    ].map(({ label, desc, icon: Icon }) => (
                      <button key={label} onClick={() => { const a=document.createElement('a');a.href='data:text/plain,SaasGuard Export: '+label;a.download='saasguard-'+label.replace(/ /g,'-').toLowerCase()+'.csv';a.click(); }}
                        className="flex items-start gap-3 p-4 rounded-xl bg-slate-800/60 border border-slate-800 hover:border-emerald-500/30 hover:bg-slate-800 transition-all text-left">
                        <Icon className="h-5 w-5 text-emerald-400 flex-shrink-0 mt-0.5" />
                        <div>
                          <div className="font-semibold text-white text-sm">{label}</div>
                          <div className="text-xs text-slate-500 mt-0.5">{desc}</div>
                        </div>
                      </button>
                    ))}
                  </div>
                </CardBody>
              </Card>
              <Card className="border-rose-500/20 bg-rose-500/5">
                <CardHeader title={t('danger_zone')} subtitle={t('danger_zone_sub')} />
                <CardBody>
                  <div className="space-y-3">
                    {[
                      { label: 'Delete all tool data', desc: 'Removes all tools from your account', btn: 'Delete Tools' },
                      { label: 'Delete all employee data', desc: 'Removes all employee and access records', btn: 'Delete Employees' },
                      { label: 'Delete account', desc: 'Permanently deletes your SaasGuard account and all data', btn: 'Delete Account', danger: true },
                    ].map(item => (
                      <div key={item.label} className="flex items-center justify-between py-3 border-b border-rose-500/10 last:border-0">
                        <div>
                          <div className="font-medium text-slate-200 text-sm">{item.label}</div>
                          <div className="text-xs text-slate-500">{item.desc}</div>
                        </div>
                        <button onClick={() => alert('This action is disabled in the demo.')}
                          className={"text-xs font-semibold px-3 py-1.5 rounded-lg border transition-colors " + (item.danger ? 'border-rose-500/40 text-rose-400 hover:bg-rose-500/10' : 'border-slate-700 text-slate-400 hover:text-white hover:border-slate-600')}>
                          {item.btn}
                        </button>
                      </div>
                    ))}
                  </div>
                </CardBody>
              </Card>
            </div>
          )}
        </div>
      </div>
    </AppShell>
  );
}

function NotFound() {
  const { language } = useLang();
  const t = useTranslation(language);
  return <Navigate to="/" replace />;
}

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      staleTime: 250,
    },
  },
});


// ============================================================================
// LEGAL PAGES - Privacy, Terms, Security
// ============================================================================

function PrivacyPage() {
  const navigate = useNavigate();
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 text-white">
      <nav className="border-b border-white/5 bg-slate-950/50 backdrop-blur-2xl sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-6 flex items-center justify-between">
          <div onClick={() => window.location.href = "/dashboard"} className="flex items-center gap-4 cursor-pointer">
            <RDLogo size="md" />
            <div className="text-2xl font-black bg-gradient-to-r from-blue-400 to-indigo-400 bg-clip-text text-transparent">SaasGuard</div>
          </div>
          <button onClick={() => window.location.href = "/dashboard"} className="text-slate-300 hover:text-white transition-colors">← Back to Home</button>
        </div>
      </nav>

      <div className="max-w-4xl mx-auto px-6 py-20">
        <h1 className="text-6xl font-black mb-6 bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">Privacy Policy</h1>
        <p className="text-slate-400 mb-12">Last updated: February 22, 2026</p>

        <div className="space-y-12">
          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">1. Information We Collect</h2>
            <p className="text-slate-300 leading-relaxed mb-4">We collect information you provide directly to us, including:</p>
            <ul className="list-disc list-inside text-slate-300 space-y-2 ml-4">
              <li>Account information (name, email, company name)</li>
              <li>Usage data (features accessed, time spent, actions taken)</li>
              <li>Integration data (connected SaaS applications, access permissions)</li>
              <li>Payment information (processed securely through our payment partners)</li>
            </ul>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">2. How We Use Your Data</h2>
            <p className="text-slate-300 leading-relaxed mb-4">Your data is used to:</p>
            <ul className="list-disc list-inside text-slate-300 space-y-2 ml-4">
              <li>Provide and improve our SaaS access management services</li>
              <li>Send important updates about your account and security</li>
              <li>Generate insights and recommendations for your organization</li>
              <li>Ensure platform security and prevent unauthorized access</li>
            </ul>
            <p className="text-slate-300 leading-relaxed mt-4"><strong>We never sell your personal information to third parties.</strong></p>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">3. Data Security</h2>
            <p className="text-slate-300 leading-relaxed">We employ industry-standard security measures:</p>
            <ul className="list-disc list-inside text-slate-300 space-y-2 ml-4 mt-4">
              <li>AES-256 encryption for all data at rest and in transit</li>
              <li>SOC 2 Type II certified infrastructure</li>
              <li>Regular security audits and penetration testing</li>
              <li>Multi-factor authentication requirements</li>
              <li>Automated backup and disaster recovery systems</li>
            </ul>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">4. Your Rights</h2>
            <p className="text-slate-300 leading-relaxed mb-4">Under GDPR and other data protection laws, you have the right to:</p>
            <ul className="list-disc list-inside text-slate-300 space-y-2 ml-4">
              <li>Access your personal data</li>
              <li>Correct inaccurate information</li>
              <li>Request deletion of your data</li>
              <li>Export your data in a portable format</li>
              <li>Opt-out of marketing communications</li>
            </ul>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">5. Contact Us</h2>
            <p className="text-slate-300 leading-relaxed">For privacy-related questions or requests:</p>
            <p className="text-blue-400 mt-4">Email: <a href="mailto:privacy@accessguard.io" className="hover:underline">privacy@accessguard.io</a></p>
          </section>
        </div>
      </div>
    </div>
  );
}

function TermsPage() {
  const navigate = useNavigate();
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 text-white">
      <nav className="border-b border-white/5 bg-slate-950/50 backdrop-blur-2xl sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-6 flex items-center justify-between">
          <div onClick={() => window.location.href = "/dashboard"} className="flex items-center gap-4 cursor-pointer">
            <RDLogo size="md" />
            <div className="text-2xl font-black bg-gradient-to-r from-blue-400 to-indigo-400 bg-clip-text text-transparent">SaasGuard</div>
          </div>
          <button onClick={() => window.location.href = "/dashboard"} className="text-slate-300 hover:text-white transition-colors">← Back to Home</button>
        </div>
      </nav>

      <div className="max-w-4xl mx-auto px-6 py-20">
        <h1 className="text-6xl font-black mb-6 bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">Terms of Service</h1>
        <p className="text-slate-400 mb-12">Last updated: February 22, 2026</p>

        <div className="space-y-12">
          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">1. Acceptance of Terms</h2>
            <p className="text-slate-300 leading-relaxed">By accessing or using SaasGuard ("the Service"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our Service.</p>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">2. Service Description</h2>
            <p className="text-slate-300 leading-relaxed mb-4">SaasGuard provides SaaS access management and security tools including:</p>
            <ul className="list-disc list-inside text-slate-300 space-y-2 ml-4">
              <li>Application access tracking and monitoring</li>
              <li>User permission management</li>
              <li>Security risk detection and alerting</li>
              <li>Compliance reporting and audit trails</li>
            </ul>
            <p className="text-slate-300 leading-relaxed mt-4">We reserve the right to modify or discontinue features with reasonable notice.</p>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">3. User Responsibilities</h2>
            <p className="text-slate-300 leading-relaxed mb-4">You agree to:</p>
            <ul className="list-disc list-inside text-slate-300 space-y-2 ml-4">
              <li>Provide accurate and complete registration information</li>
              <li>Maintain the security of your account credentials</li>
              <li>Notify us immediately of any unauthorized access</li>
              <li>Use the Service in compliance with all applicable laws</li>
              <li>Not attempt to reverse engineer or compromise our systems</li>
            </ul>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">4. Payment Terms</h2>
            <p className="text-slate-300 leading-relaxed">Subscriptions are billed monthly or annually in advance. Fees are non-refundable except as required by law or within 14 days of initial purchase. We may change pricing with 30 days notice.</p>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">5. Limitation of Liability</h2>
            <p className="text-slate-300 leading-relaxed">The Service is provided "as is" without warranties. We are not liable for indirect, incidental, or consequential damages arising from your use of the Service.</p>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">6. Termination</h2>
            <p className="text-slate-300 leading-relaxed">Either party may terminate the agreement at any time. Upon termination, your access to the Service will cease and we will delete your data according to our retention policy.</p>
          </section>

          <section>
            <h2 className="text-3xl font-bold mb-4 text-white">7. Contact</h2>
            <p className="text-slate-300 leading-relaxed">For questions about these Terms:</p>
            <p className="text-blue-400 mt-4">Email: <a href="mailto:legal@accessguard.io" className="hover:underline">legal@accessguard.io</a></p>
          </section>
        </div>
      </div>
    </div>
  );
}

function SecurityPage() {
  return (
    <div className="min-h-screen bg-slate-950 text-white">
      <nav className="border-b border-white/5 bg-slate-950/80 backdrop-blur sticky top-0 z-50 px-6 py-4">
        <div className="max-w-5xl mx-auto flex items-center justify-between">
          <div onClick={() => window.location.href = "/"} className="flex items-center gap-3 cursor-pointer">
            <RDLogo size="sm" />
            <span className="text-lg font-black bg-gradient-to-r from-blue-400 to-indigo-400 bg-clip-text text-transparent">SaasGuard</span>
          </div>
          <button onClick={() => window.history.back()} className="text-sm text-slate-400 hover:text-white transition-colors">← Back</button>
        </div>
      </nav>
      <div className="max-w-4xl mx-auto px-6 py-20">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-emerald-500/30 bg-emerald-500/10 mb-6">
            <Shield className="w-4 h-4 text-emerald-400" />
            <span className="text-sm font-semibold text-emerald-400">Security & Trust Centre</span>
          </div>
          <h1 className="text-5xl font-black mb-4 bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">Your Data is Safe With Us</h1>
          <p className="text-xl text-slate-400 max-w-2xl mx-auto">Enterprise-grade security and compliance — built in from day one, not bolted on later.</p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-16">
          {[
            { icon: "🛡️", label: "SOC 2 Type II", sub: "Annually audited" },
            { icon: "🇪🇺", label: "GDPR", sub: "EU data residency" },
            { icon: "🔐", label: "ISO 27001", sub: "Framework aligned" },
            { icon: "🏥", label: "HIPAA", sub: "Ready on request" },
          ].map(b => (
            <div key={b.label} className="rounded-2xl border border-emerald-500/20 bg-emerald-500/5 p-5 text-center hover:border-emerald-500/40 transition-all">
              <div className="text-4xl mb-2">{b.icon}</div>
              <div className="font-bold text-white text-sm">{b.label}</div>
              <div className="text-xs text-emerald-400 mt-1">{b.sub}</div>
            </div>
          ))}
        </div>

        <div className="space-y-5 mb-16">
          {[
            { icon: "🔒", title: "End-to-End Encryption", body: "All data encrypted in transit using TLS 1.3 and at rest using AES-256. Your SaaS inventory, employee records, and access data are never stored in plaintext. Encryption keys are rotated quarterly." },
            { icon: "🏗️", title: "Infrastructure & Hosting", body: "SaasGuard runs on Google Cloud Platform (Firebase/GCP), hosted in the EU (europe-west1) by default. We use isolated, per-organisation Firestore databases. No data is ever co-mingled between customers." },
            { icon: "👤", title: "Data Access Controls", body: "Only you and users you explicitly invite can access your workspace. SaasGuard staff have zero access to your data by default. Any internal access requires approval, is time-limited, and fully audit-logged." },
            { icon: "🔑", title: "Authentication & SSO", body: "We support Google OAuth 2.0, Magic Link (passwordless), and SAML 2.0 for enterprise plans. Multi-factor authentication (MFA) is available on all plans and can be enforced organisation-wide by admins." },
            { icon: "📋", title: "Tamper-Proof Audit Logs", body: "Every action in SaasGuard — logins, access grants, revocations, data exports — is logged with timestamp, user identity, and IP. Logs are immutable and retained for 12 months (Enterprise: 7 years)." },
            { icon: "🗑️", title: "Data Portability & Deletion", body: "You own your data. Export everything in CSV or JSON at any time from Settings. When you cancel, all your data is permanently deleted within 30 days. We do not sell or share your data with any third party." },
            { icon: "🔍", title: "Penetration Testing", body: "Annual third-party penetration tests plus quarterly internal security reviews. Critical vulnerabilities are patched within 24 hours. We operate a responsible disclosure programme and welcome security researchers." },
            { icon: "📡", title: "Uptime & Reliability", body: "99.9% uptime SLA on Pro and Enterprise plans. Automatic failover across multiple GCP availability zones. Backups run every 6 hours. Status page: status.accessguard.io." },
          ].map(item => (
            <div key={item.title} className="rounded-2xl border border-slate-800 bg-slate-900/60 p-6 hover:border-slate-700 transition-all">
              <div className="flex items-start gap-4">
                <div className="text-3xl flex-shrink-0 mt-0.5">{item.icon}</div>
                <div>
                  <h3 className="text-lg font-bold text-white mb-2">{item.title}</h3>
                  <p className="text-slate-400 leading-relaxed">{item.body}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="rounded-2xl border border-blue-500/20 bg-blue-500/5 p-8 mb-8 text-center">
          <h3 className="text-xl font-bold text-white mb-2">Found a Security Issue?</h3>
          <p className="text-slate-400 mb-4 max-w-lg mx-auto">We take every security report seriously. Our security team aims to respond within 24 hours. Responsible disclosure is always acknowledged.</p>
          <a href="mailto:security@accessguard.io" className="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold transition-colors text-white">
            <Lock className="w-4 h-4" />
            security@accessguard.io
          </a>
        </div>

        <div className="rounded-2xl border border-white/10 bg-white/5 p-8 text-center">
          <h3 className="text-xl font-bold text-white mb-2">Download Security Whitepaper</h3>
          <p className="text-slate-400 mb-4">Full technical documentation for your compliance and security teams.</p>
          <button
            onClick={() => { if (window.toast) window.toast.success("Whitepaper request sent — we'll email it within 1 business day."); else alert("We'll email the whitepaper to you within 1 business day. Contact: security@accessguard.io"); }}
            className="inline-flex items-center gap-2 px-6 py-3 border border-white/20 hover:border-white/40 rounded-xl font-semibold text-white transition-colors"
          >
            <Download className="w-4 h-4" />
            Request Whitepaper
          </button>
        </div>

        <div className="mt-10 text-center text-xs text-slate-600">
          Last updated: March 2026 · Questions? <a href="mailto:hello@accessguard.io" className="text-blue-400 hover:underline">hello@accessguard.io</a>
        </div>
      </div>
    </div>
  );
}
// ============================================================================
// TOOLS PAGE - Complete SaaS Tool Management
// ============================================================================
// ============================================================================
// FINOPS PAGES - Finance Dashboard, License Management, Renewals, Invoices
// ============================================================================

// FINANCE DASHBOARD PAGE
function FinanceDashboard() {
  const navigate = useNavigate();
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const [finTab, setFinTab] = useState('overview');
  const [timeRange, setTimeRange] = useState('month');
  const [showBudgetModal, setShowBudgetModal] = useState(false);
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [showReclaimModal, setShowReclaimModal] = useState(false);
  const [selectedBill, setSelectedBill] = useState(null);

  const TABS = [
    { id: 'overview',   label: '💰 ' + t('fin_tab_overview'),   desc: t('fin_tab_overview_desc') },
    { id: 'cost',       label: '💸 ' + t('fin_tab_cost'),       desc: t('fin_tab_cost_desc') },
    { id: 'executive',  label: '📈 ' + t('fin_tab_executive'),  desc: t('fin_tab_executive_desc') },
    { id: 'analytics',  label: '📊 ' + t('fin_tab_reports'),    desc: t('fin_tab_reports_desc') },
  ];

  return (
    <AppShell title={t('nav_finance')}
      right={
        <div className="flex gap-1 p-1 bg-slate-900 rounded-xl border border-slate-800">
          {TABS.map(tab => (
            <button key={tab.id} onClick={() => setFinTab(tab.id)}
              className={"px-3 py-1.5 rounded-lg text-xs font-semibold transition-all " + (finTab === tab.id ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white')}>
              {tab.label}
            </button>
          ))}
        </div>
      }
    >
      {finTab === 'overview' && <FinanceOverviewTab financialData={{
        totalMonthlySpend: 47850, budgetLimit: 55000, lastMonthSpend: 45200,
        upcomingBills: [
          { app: 'Salesforce', amount: 12400, dueDate: '2026-03-01', status: 'pending', category: 'CRM' },
          { app: 'Slack', amount: 2850, dueDate: '2026-03-05', status: 'pending', category: 'Communication' },
          { app: 'GitHub', amount: 3200, dueDate: '2026-03-10', status: 'approved', category: 'Development' },
          { app: 'Zoom', amount: 1950, dueDate: '2026-03-15', status: 'pending', category: 'Communication' },
          { app: 'Adobe Creative Cloud', amount: 5400, dueDate: '2026-03-20', status: 'pending', category: 'Design' },
        ],
        byCategory: [
          { name: 'CRM', spend: 12400, budget: 15000, count: 3 },
          { name: 'Communication', spend: 8200, budget: 10000, count: 5 },
          { name: 'Development', spend: 14300, budget: 18000, count: 8 },
          { name: 'Design', spend: 6800, budget: 8000, count: 4 },
          { name: 'Analytics', spend: 6150, budget: 4000, count: 3 },
        ],
        monthlyTrend: [
          { month: 'Sep', spend: 42100 }, { month: 'Oct', spend: 43800 },
          { month: 'Nov', spend: 45200 }, { month: 'Dec', spend: 44600 },
          { month: 'Jan', spend: 46900 }, { month: 'Feb', spend: 47850 },
        ]
      }} showBudgetModal={showBudgetModal} setShowBudgetModal={setShowBudgetModal}
         selectedBill={selectedBill} setSelectedBill={setSelectedBill}
         showReclaimModal={showReclaimModal} setShowReclaimModal={setShowReclaimModal}
         categoryFilter={categoryFilter} setCategoryFilter={setCategoryFilter} />}
      {finTab === 'cost' && <CostTabContent />}
      {finTab === 'executive' && <ExecutiveTabContent />}
      {finTab === 'analytics' && <AnalyticsTabContent />}
    </AppShell>
  );
}

function FinanceOverviewTab({ financialData, showBudgetModal, setShowBudgetModal, selectedBill, setSelectedBill, showReclaimModal, setShowReclaimModal, categoryFilter, setCategoryFilter }) {
  const { language } = useLang();
  const t = useTranslation(language);
  const navigate = useNavigate();
  const budgetUtilization = (financialData.totalMonthlySpend / financialData.budgetLimit * 100).toFixed(1);
  const savingsVsLastMonth = financialData.lastMonthSpend - financialData.totalMonthlySpend;
  return (
    <div className="p-8">

        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-black mb-2">💰 Finance Dashboard</h1>
          <p className="text-slate-400">Real-time SaaS spend visibility and budget control</p>
        </div>

        {/* Key Metrics */}
        <div className="grid md:grid-cols-4 gap-6 mb-8">
          <Card className="p-6 bg-gradient-to-br from-blue-500/10 to-indigo-500/10 border-blue-500/20">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('total_spend')}</span>
              <CreditCard className="w-5 h-5 text-blue-400" />
            </div>
            <div className="text-3xl font-black text-white mb-1">
              ${financialData.totalMonthlySpend.toLocaleString()}
            </div>
            <div className="text-sm text-slate-400">
              {budgetUtilization}% of ${financialData.budgetLimit.toLocaleString()} budget
            </div>
            <div className="mt-3 w-full bg-slate-800 rounded-full h-2">
              <div 
                className={`h-2 rounded-full ${budgetUtilization > 90 ? 'bg-red-500' : budgetUtilization > 75 ? 'bg-yellow-500' : 'bg-blue-500'}`}
                style={{ width: `${Math.min(budgetUtilization, 100)}%` }}
              />
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('upcoming_bills')}</span>
              <CalendarClock className="w-5 h-5 text-emerald-400" />
            </div>
            <div className="text-3xl font-black text-white mb-1">
              ${financialData.upcomingBills.reduce((sum, bill) => sum + bill.amount, 0).toLocaleString()}
            </div>
            <div className="text-sm text-emerald-400">
              {financialData.upcomingBills.length} bills pending
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">vs Last Month</span>
              <BarChart3 className="w-5 h-5 text-purple-400" />
            </div>
            <div className="text-3xl font-black text-white mb-1">
              {savingsVsLastMonth > 0 ? '+' : ''}${Math.abs(savingsVsLastMonth).toLocaleString()}
            </div>
            <div className={`text-sm ${savingsVsLastMonth > 0 ? 'text-red-400' : 'text-emerald-400'}`}>
              {savingsVsLastMonth > 0 ? 'Increase' : 'Decrease'}
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('category_overview')}</span>
              <Boxes className="w-5 h-5 text-yellow-400" />
            </div>
            <div className="text-3xl font-black text-white mb-1">
              {financialData.byCategory.length}
            </div>
            <div className="text-sm text-slate-400">
              {financialData.byCategory.reduce((sum, cat) => sum + cat.count, 0)} total apps
            </div>
          </Card>
        </div>

        <div className="grid lg:grid-cols-2 gap-8 mb-8">
          {/* Upcoming Bills */}
          <Card className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold">📅 Upcoming Bills</h2>
              <button className="text-sm text-blue-400 hover:underline">View All</button>
            </div>
            <div className="space-y-3">
              {financialData.upcomingBills.map((bill, idx) => (
                <div key={idx} className="flex items-center justify-between p-4 bg-slate-900 rounded-xl border border-white/5 hover:border-white/10 transition-colors">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
                      <CreditCard className="w-6 h-6 text-white" />
                    </div>
                    <div>
                      <div className="font-semibold text-white">{bill.app}</div>
                      <div className="text-sm text-slate-400">Due {bill.dueDate} • {bill.category}</div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold text-white">${bill.amount.toLocaleString()}</div>
                    <Pill tone={bill.status === 'approved' ? 'green' : 'yellow'}>
                      {bill.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                    </Pill>
                  </div>
                </div>
              ))}
            </div>
          </Card>

          {/* Spend by Category */}
          <Card className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold">📊 Spend by Category</h2>
              <Select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}>
                <option value="all">{t('all_categories')}</option>
                <option value="over">{t('at_risk')}</option>
                <option value="under">{t('healthy')}</option>
                <option value="optimal">Optimal (70-90%)</option>
              </Select>
            </div>
            <div className="space-y-4">
              {financialData.byCategory
                .filter(cat => {
                  const utilization = (cat.spend / cat.budget * 100);
                  if (categoryFilter === 'all') return true;
                  if (categoryFilter === 'over') return utilization > 100;
                  if (categoryFilter === 'under') return utilization < 70;
                  if (categoryFilter === 'optimal') return utilization >= 70 && utilization <= 90;
                  return true;
                })
                .map((cat, idx) => {
                const utilization = (cat.spend / cat.budget * 100).toFixed(0);
                return (
                  <div key={idx}>
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-white">{cat.name}</span>
                        <span className="text-xs text-slate-500">({cat.count} apps)</span>
                      </div>
                      <div className="text-sm">
                        <span className="font-bold text-white">${cat.spend.toLocaleString()}</span>
                        <span className="text-slate-400"> / ${cat.budget.toLocaleString()}</span>
                      </div>
                    </div>
                    <div className="w-full bg-slate-800 rounded-full h-2 relative overflow-hidden">
                      <div 
                        className={`h-2 rounded-full transition-all ${utilization > 100 ? 'bg-red-500' : utilization > 80 ? 'bg-yellow-500' : 'bg-blue-500'}`}
                        style={{ width: `${Math.min(utilization, 100)}%` }}
                      />
                    </div>
                    <div className="flex justify-between text-xs text-slate-500 mt-1">
                      <span>{utilization}% utilized</span>
                      {utilization > 100 && <span className="text-red-400">Over budget!</span>}
                    </div>
                  </div>
                );
              })}
            </div>
          </Card>
        </div>

        {/* Monthly Trend Chart */}
        <Card className="p-6">
          <h2 className="text-xl font-bold mb-6">📈 Monthly Spend Trend</h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={financialData.monthlyTrend} barSize={40} margin={{top:8,right:8,left:0,bottom:0}}>
              <defs><linearGradient id="spendGrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#10b981" stopOpacity={0.9}/><stop offset="100%" stopColor="#0891b2" stopOpacity={0.7}/></linearGradient></defs>
              <XAxis dataKey="month" tick={{fill:"#94a3b8",fontSize:12}} axisLine={{stroke:"#334155"}} tickLine={false}/>
              <YAxis tick={{fill:"#94a3b8",fontSize:12}} axisLine={false} tickLine={false} tickFormatter={v=>"$"+(v/1000).toFixed(0)+"K"}/>
              <Tooltip cursor={{fill:"rgba(255,255,255,0.04)"}} contentStyle={{backgroundColor:"#1e293b",border:"1px solid #334155",borderRadius:"12px",color:"#fff",fontSize:"13px"}} formatter={v=>["$"+v.toLocaleString(),"Monthly Spend"]}/>
              <Bar dataKey="spend" fill="url(#spendGrad)" radius={[8,8,0,0]}/>
            </BarChart>
          </ResponsiveContainer>
        </Card>

      {/* Spending Insights Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mt-8">
        <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-2xl p-6">
          <div className="text-sm text-slate-400 mb-2">Top Category</div>
          <div className="text-2xl font-black text-blue-400">CRM</div>
          <div className="text-lg text-white mt-2">$12,400/mo</div>
        </div>
        
        <div className="bg-gradient-to-br from-emerald-500/10 to-emerald-600/10 border border-emerald-500/20 rounded-2xl p-6">
          <div className="text-sm text-slate-400 mb-2">Savings Found</div>
          <div className="text-2xl font-black text-emerald-400">3 Tools</div>
          <div className="text-lg text-white mt-2">$600/mo</div>
        </div>
        
        <div className="bg-gradient-to-br from-orange-500/10 to-orange-600/10 border border-orange-500/20 rounded-2xl p-6">
          <div className="text-sm text-slate-400 mb-2">Cost Increase</div>
          <div className="text-2xl font-black text-orange-400">+12%</div>
          <div className="text-lg text-white mt-2">MoM Growth</div>
        </div>
        
        <div className="bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-500/20 rounded-2xl p-6">
          <div className="text-sm text-slate-400 mb-2">Budget Health</div>
          <div className="text-2xl font-black text-purple-400">85/100</div>
          <div className="w-full bg-slate-800 rounded-full h-2 mt-2">
            <div className="bg-gradient-to-r from-emerald-500 to-blue-500 h-2 rounded-full" style={{width: '85%'}}></div>
          </div>
        </div>

      {/* Smart Recommendations */}
      <div className="bg-gradient-to-br from-emerald-500/10 to-teal-500/10 border border-emerald-500/20 rounded-2xl p-6 mt-6">
        <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
          <Sparkles className="h-6 w-6 text-emerald-400" />
          Smart Recommendations
        </h3>
        <div className="space-y-3">
          <div className="flex items-center justify-between p-4 bg-slate-900/50 rounded-xl border border-slate-800">
            <div className="flex-1">
              <div className="text-white font-semibold">Remove Unused Licenses</div>
              <div className="text-sm text-slate-400">3 tools haven't been used in 90+ days</div>
              <div className="text-sm text-emerald-400 font-semibold mt-1">Save $600/month</div>
            </div>
            <button className="ml-4 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg font-semibold text-sm">
              Review Tools
            </button>
          </div>
          
          <div className="flex items-center justify-between p-4 bg-slate-900/50 rounded-xl border border-slate-800">
            <div className="flex-1">
              <div className="text-white font-semibold">Negotiate Upcoming Renewals</div>
              <div className="text-sm text-slate-400">5 tools renewing next month</div>
              <div className="text-sm text-emerald-400 font-semibold mt-1">Save $450/month</div>
            </div>
            <button className="ml-4 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg font-semibold text-sm">
              View Renewals
            </button>
          </div>
        </div>
      </div>
      </div>
    </div>
  );
}

function CostTabContent() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const navigate = useNavigate();
  const [sortBy, setSortBy] = useState('cost');
  const [filter, setFilter] = useState('all');

  const tools = db?.tools || [];
  const access = db?.access || [];
  const enriched = tools
    .filter(t => t.status === 'active')
    .map(tool => {
      const activeUsers = access.filter(a => a.tool_id === tool.id && a.access_status === 'active').length;
      const cost = Number(tool.cost_per_month || 0);
      const costPerUser = activeUsers > 0 ? cost / activeUsers : cost;
      const wasteFlag = activeUsers === 0 || costPerUser > 200;
      return { ...tool, activeUsers, cost, costPerUser, wasteFlag };
    })
    .filter(t => filter === 'all' ? true : filter === 'waste' ? t.wasteFlag : !t.wasteFlag)
    .sort((a, b) => sortBy === 'cost' ? b.cost - a.cost : b.costPerUser - a.costPerUser);

  const totalSpend = tools.filter(t => t.status === 'active').reduce((s, t) => s + Number(t.cost_per_month || 0), 0);
  const wasteTools = enriched.filter(t => t.wasteFlag);
  const wasteAmount = wasteTools.reduce((s, t) => s + t.cost, 0);
  const unusedTools = enriched.filter(t => t.activeUsers === 0);

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h2 className="text-2xl font-black text-white mb-1">💸 Cost Management</h2>
          <p className="text-slate-400">Find waste, optimise spend, reclaim unused licenses</p>
        </div>
        <button onClick={() => navigate('/licenses')} className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors text-sm">
          Manage Licenses →
        </button>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { label: 'Total Monthly Spend', value: '$' + totalSpend.toLocaleString(), sub: tools.filter(t=>t.status==='active').length + ' active tools', color: 'text-white', Icon: BarChart3 },
          { label: 'Estimated Waste', value: '$' + wasteAmount.toLocaleString(), sub: wasteTools.length + ' flagged tools', color: 'text-rose-400', Icon: TrendingDown },
          { label: 'Unused Tools', value: unusedTools.length, sub: 'no active users assigned', color: 'text-amber-400', Icon: Zap },
          { label: 'Potential Savings', value: '$' + Math.round(wasteAmount * 0.7).toLocaleString(), sub: 'if waste reclaimed', color: 'text-emerald-400', Icon: Target },
        ].map(({ label, value, sub, color, Icon }) => (
          <Card key={label}><CardBody>
            <div className="flex items-start justify-between gap-2">
              <div><div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>
                <div className={"text-2xl font-black " + color}>{value}</div>
                <div className="text-xs text-slate-500 mt-1">{sub}</div>
              </div>
              <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center flex-shrink-0">
                <Icon className={"h-4 w-4 " + color} />
              </div>
            </div>
          </CardBody></Card>
        ))}
      </div>
      {wasteTools.length > 0 && (
        <Card className="p-5 bg-amber-500/5 border-amber-500/20">
          <div className="flex items-start gap-3">
            <AlertTriangle className="h-5 w-5 text-amber-400 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <div className="font-bold text-white mb-1">⚠️ {wasteTools.length} tools flagged as potential waste</div>
              <p className="text-sm text-slate-400">Tools with no active users or very high cost-per-user. Review and consider cancelling or renegotiating.</p>
            </div>
            <button onClick={() => setFilter('waste')} className="text-sm text-amber-400 font-semibold hover:text-amber-300 whitespace-nowrap">{t('filter')}</button>
          </div>
        </Card>
      )}
      <Card className="p-5">
        <div className="flex items-center gap-3 mb-4 flex-wrap">
          <h3 className="font-bold text-white flex-1">{t('top_costliest')}</h3>
          <div className="flex gap-2 flex-wrap">
            {[['all','All'],['waste','Waste Only'],['ok','Healthy']].map(([val, label]) => (
              <button key={val} onClick={() => setFilter(val)}
                className={"px-3 py-1 rounded-lg text-xs font-semibold transition-all " + (filter === val ? 'bg-blue-600 text-white' : 'bg-slate-800 text-slate-400 hover:text-white')}>
                {label}
              </button>
            ))}
            <select value={sortBy} onChange={e => setSortBy(e.target.value)}
              className="px-3 py-1 bg-slate-800 border border-slate-700 rounded-lg text-xs text-slate-300">
              <option value="cost">{t('total_cost')}</option>
              <option value="perUser">{t('cost_per_user')}</option>
            </select>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-800">
                <th className="text-left py-3 px-2 text-xs text-slate-500 font-semibold uppercase">Tool</th>
                <th className="text-right py-3 px-2 text-xs text-slate-500 font-semibold uppercase">Monthly Cost</th>
                <th className="text-right py-3 px-2 text-xs text-slate-500 font-semibold uppercase">{t('active_users')}</th>
                <th className="text-right py-3 px-2 text-xs text-slate-500 font-semibold uppercase">Cost/User</th>
                <th className="text-left py-3 px-2 text-xs text-slate-500 font-semibold uppercase">Flag</th>
              </tr>
            </thead>
            <tbody>
              {enriched.length === 0 ? (
                <tr><td colSpan={5} className="text-center py-10 text-slate-600">No tools tracked yet — import or add tools first</td></tr>
              ) : enriched.map((tool, i) => (
                <tr key={tool.id || i} className="border-b border-slate-800/50 hover:bg-slate-800/30">
                  <td className="py-3 px-2">
                    <div className="font-semibold text-white">{tool.name}</div>
                    <div className="text-xs text-slate-500">{tool.category || '—'}</div>
                  </td>
                  <td className="py-3 px-2 text-right font-mono text-white">${tool.cost.toLocaleString()}</td>
                  <td className="py-3 px-2 text-right text-slate-300">{tool.activeUsers}</td>
                  <td className="py-3 px-2 text-right font-mono text-slate-300">${Math.round(tool.costPerUser).toLocaleString()}</td>
                  <td className="py-3 px-2">
                    {tool.wasteFlag
                      ? <span className="inline-flex items-center gap-1 text-xs bg-amber-500/10 text-amber-400 px-2 py-0.5 rounded-full font-medium"><AlertTriangle className="h-3 w-3" /> Waste</span>
                      : <span className="inline-flex items-center gap-1 text-xs bg-emerald-500/10 text-emerald-400 px-2 py-0.5 rounded-full font-medium"><Check className="h-3 w-3" /> OK</span>
                    }
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}

function ExecutiveTabContent() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  if (!db) return <div className="p-8 text-center text-slate-500">{t('loading')}</div>;
  const derived = {
    tools: db.tools.map(t => ({ ...t, derived_risk: computeToolDerivedRisk(t) })),
    employees: db.employees || [],
    access: db.access || [],
    alerts: buildRiskAlerts({ tools: db.tools, access: db.access || [], employees: db.employees || [] })
  };
  return <div className="p-2"><ExecutiveDashboard data={derived} /></div>;
}

function AnalyticsTabContent() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const navigate = useNavigate();
  const tools = db?.tools || [];
  const employees = db?.employees || [];
  const access = db?.access || [];
  const activeTools = tools.filter(t => t.status === 'active');
  const totalSpend = activeTools.reduce((s, t) => s + Number(t.cost_per_month || 0), 0);
  const inactiveUsers = employees.filter(e => e.status === 'inactive' || e.status === 'former').length;
  const categorySpend = Object.values(
    activeTools.reduce((acc, t) => {
      const cat = t.category || 'Other';
      if (!acc[cat]) acc[cat] = { name: cat, spend: 0, count: 0 };
      acc[cat].spend += Number(t.cost_per_month || 0);
      acc[cat].count++;
      return acc;
    }, {})
  ).sort((a, b) => b.spend - a.spend).slice(0, 6);
  const topTools = [...activeTools].sort((a, b) => Number(b.cost_per_month || 0) - Number(a.cost_per_month || 0)).slice(0, 8);
  const deptBreakdown = Object.entries(
    employees.reduce((acc, e) => {
      const dept = e.department || 'Other';
      if (!acc[dept]) acc[dept] = { active: 0, inactive: 0 };
      if (e.status === 'active') acc[dept].active++;
      else acc[dept].inactive++;
      return acc;
    }, {})
  ).map(([name, v]) => ({ name, ...v, total: v.active + v.inactive })).sort((a, b) => b.total - a.total).slice(0, 6);

  const exportCSV = () => {
    const rows = [['Category','Monthly Spend','Tool Count'], ...categorySpend.map(c => [c.name, c.spend, c.count])].map(r => r.join(',')).join('\n');
    const a = document.createElement('a'); a.href = 'data:text/csv,' + encodeURIComponent(rows); a.download = 'saasguard-analytics.csv'; a.click();
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-black text-white mb-1">📊 Analytics & Reports</h2>
          <p className="text-slate-400">Live insights across your entire SaaS stack</p>
        </div>
        <button onClick={exportCSV} className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors text-sm">
          <Download className="h-4 w-4" /> Export CSV
        </button>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { label: 'Total Active Tools', value: activeTools.length, sub: tools.length + ' total tracked', color: 'text-white', Icon: Boxes },
          { label: 'Monthly SaaS Spend', value: '$' + totalSpend.toLocaleString(), sub: 'across ' + activeTools.length + ' tools', color: 'text-emerald-400', Icon: BarChart3 },
          { label: 'Avg Cost Per Tool', value: '$' + (activeTools.length ? Math.round(totalSpend / activeTools.length).toLocaleString() : 0), sub: 'per month', color: 'text-teal-400', Icon: TrendingDown },
          { label: 'Inactive Employees', value: inactiveUsers, sub: 'may retain access', color: 'text-amber-400', Icon: Users },
        ].map(({ label, value, sub, color, Icon }) => (
          <Card key={label}><CardBody>
            <div className="flex items-start justify-between gap-2">
              <div className="min-w-0 flex-1">
                <div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>
                <div className={"text-2xl font-black " + color}>{value}</div>
                <div className="text-xs text-slate-500 mt-1">{sub}</div>
              </div>
              <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center flex-shrink-0">
                <Icon className={"h-4 w-4 " + color} />
              </div>
            </div>
          </CardBody></Card>
        ))}
      </div>
      <div className="grid lg:grid-cols-2 gap-6">
        <Card className="p-6">
          <h3 className="text-xl font-bold mb-4">💰 Spend by Category</h3>
          <div className="space-y-3">
            {categorySpend.length === 0 && <div className="text-slate-500 text-sm text-center py-4">{t('add_tools_to_see')}</div>}
            {categorySpend.map((cat, i) => {
              const pct = totalSpend > 0 ? (cat.spend / totalSpend * 100) : 0;
              const colors = ['bg-emerald-500','bg-teal-500','bg-blue-500','bg-violet-500','bg-amber-500','bg-rose-500'];
              return (
                <div key={cat.name}>
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-sm font-semibold text-slate-200">{cat.name}</span>
                    <div className="flex items-center gap-3">
                      <span className="text-xs text-slate-500">{cat.count} tools</span>
                      <span className="text-sm font-bold text-white">${cat.spend.toLocaleString()}</span>
                    </div>
                  </div>
                  <div className="w-full bg-slate-800 rounded-full h-2.5">
                    <div className={"h-2.5 rounded-full transition-all duration-700 " + colors[i % colors.length]} style={{width: pct + '%'}} />
                  </div>
                </div>
              );
            })}
          </div>
        </Card>
        <Card className="p-6">
          <h3 className="text-xl font-bold mb-4">🏆 Top Tools by Cost</h3>
          <div className="space-y-2">
            {topTools.length === 0 && <div className="text-slate-500 text-sm text-center py-8">{t('no_tools_yet')}</div>}
            {topTools.map((tool, i) => (
              <div key={tool.id} className="flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-800/60 transition-colors">
                <div className="flex-shrink-0 h-7 w-7 rounded-lg bg-gradient-to-br from-emerald-500/20 to-teal-500/20 flex items-center justify-center text-xs font-bold text-emerald-400">{i+1}</div>
                <div className="min-w-0 flex-1">
                  <div className="font-semibold text-sm text-white truncate">{tool.name}</div>
                  <div className="text-xs text-slate-500">{tool.category || 'General'}</div>
                </div>
                <div className="text-right flex-shrink-0">
                  <div className="text-sm font-bold text-white">${Number(tool.cost_per_month || 0).toLocaleString()}</div>
                  <div className="text-xs text-slate-500">/mo</div>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
      {deptBreakdown.length > 0 && (
        <Card className="p-6">
          <h3 className="text-xl font-bold mb-4">🏢 Department Breakdown</h3>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {deptBreakdown.map(dept => (
              <div key={dept.name} className="p-4 rounded-xl bg-slate-900/60 border border-slate-800">
                <div className="font-semibold text-white mb-2">{dept.name}</div>
                <div className="flex gap-4 text-sm">
                  <div><span className="text-emerald-400 font-bold">{dept.active}</span><span className="text-slate-500 ml-1">active</span></div>
                  <div><span className="text-amber-400 font-bold">{dept.inactive}</span><span className="text-slate-500 ml-1">inactive</span></div>
                </div>
                <div className="mt-2 w-full bg-slate-800 rounded-full h-1.5">
                  <div className="bg-emerald-500 h-1.5 rounded-full" style={{width: dept.total > 0 ? (dept.active/dept.total*100)+'%' : '0%'}} />
                </div>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}




// ============================================================================
// EXECUTIVE DASHBOARD — inlined from ExecutiveDashboard.jsx
// ============================================================================
function ExecutiveDashboard({ data }) {
  const totalSpend = data?.tools?.reduce((sum, t) => sum + (t.cost_per_month || 0), 0) || 0;
  const annualSpend = totalSpend * 12;
  const unusedTools = data?.tools?.filter(t => {
    const lastUsed = new Date(t.last_used_date || 0);
    const daysSinceUse = Math.floor((Date.now() - lastUsed) / (1000 * 60 * 60 * 24));
    return daysSinceUse > 90;
  }) || [];
  const potentialSavings = unusedTools.reduce((sum, t) => sum + (t.cost_per_month || 0), 0);
  const annualSavings = potentialSavings * 12;
  const roi = totalSpend > 0 ? ((potentialSavings / totalSpend) * 100).toFixed(1) : 0;
  const highRiskTools = data?.tools?.filter(t => t.derived_risk === 'high').length || 0;
  const efficiencyScore = Math.min(100, Math.max(0, 85 + (potentialSavings === 0 ? 10 : 0) - (highRiskTools * 2)));
  const criticalAlerts = data?.alerts?.filter(a => a.severity === 'critical').length || 0;
  const categorySpend = {};
  data?.tools?.forEach(tool => {
    const cat = tool.category || 'Other';
    categorySpend[cat] = (categorySpend[cat] || 0) + (tool.cost_per_month || 0);
  });
  const categoryData = Object.entries(categorySpend).map(([name, value]) => ({ name, value })).sort((a, b) => b.value - a.value).slice(0, 6);
  const COLORS = ['#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#6366f1'];
  const trendData = [
    { month: 'Jul', spend: totalSpend * 0.85, savings: potentialSavings * 0.6 },
    { month: 'Aug', spend: totalSpend * 0.90, savings: potentialSavings * 0.7 },
    { month: 'Sep', spend: totalSpend * 0.93, savings: potentialSavings * 0.8 },
    { month: 'Oct', spend: totalSpend * 0.97, savings: potentialSavings * 0.85 },
    { month: 'Nov', spend: totalSpend * 0.99, savings: potentialSavings * 0.92 },
    { month: 'Dec', spend: totalSpend, savings: potentialSavings },
  ];
  const topTools = [...(data?.tools || [])].sort((a, b) => (b.cost_per_month || 0) - (a.cost_per_month || 0)).slice(0, 10);
  return (
    <div className="w-full space-y-6">
      <div className="flex items-center justify-end">
        <button onClick={() => window.print()} className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-white">
          <Download className="h-5 w-5" /> Export Report
        </button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { label: 'Annual SaaS Spend', value: '$' + annualSpend.toLocaleString(), Icon: DollarSign, color: 'blue', trend: '+12%', trendUp: true },
          { label: 'Annual Savings Potential', value: '$' + annualSavings.toLocaleString(), Icon: TrendingUp, color: 'emerald', trend: roi + '%', trendUp: false },
          { label: 'SaaS Tools Tracked', value: data?.tools?.length || 0, Icon: Boxes, color: 'purple' },
          { label: 'Active Risk Items', value: highRiskTools + criticalAlerts, Icon: AlertTriangle, color: 'orange' },
        ].map(({ label, value, Icon, color, trend, trendUp }) => (
          <div key={label} className={`bg-gradient-to-br from-${color}-500/10 to-${color}-600/10 border border-${color}-500/20 rounded-2xl p-6`}>
            <div className="flex items-center justify-between mb-4">
              <div className={`p-3 bg-${color}-500/20 rounded-xl`}><Icon className={`h-6 w-6 text-${color}-400`} /></div>
              {trend && (trendUp
                ? <div className="flex items-center gap-1 text-sm"><ArrowUp className="h-4 w-4 text-red-400" /><span className="text-red-400">{trend}</span></div>
                : <div className="flex items-center gap-1 text-sm"><ArrowDown className="h-4 w-4 text-emerald-400" /><span className="text-emerald-400">{trend}</span></div>
              )}
            </div>
            <div className="text-3xl font-black text-white mb-1">{value}</div>
            <div className="text-sm text-slate-400">{label}</div>
          </div>
        ))}
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="text-xl font-bold text-white mb-6">Spend Trend (6 Months)</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={trendData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="month" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" tickFormatter={val => `$${(val/1000).toFixed(0)}K`} />
              <Tooltip contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155' }} formatter={val => [`$${val.toLocaleString()}`, '']} />
              <Line type="monotone" dataKey="spend" stroke="#3b82f6" strokeWidth={3} />
              <Line type="monotone" dataKey="savings" stroke="#10b981" strokeWidth={3} />
            </LineChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="text-xl font-bold text-white mb-6">Spend by Category</h3>
          <ResponsiveContainer width="100%" height={300}>
            <RPieChart>
              <Pie data={categoryData} cx="50%" cy="50%" labelLine={false} label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`} outerRadius={100} dataKey="value">
                {categoryData.map((entry, index) => <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />)}
              </Pie>
              <Tooltip contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155' }} formatter={val => [`$${val.toLocaleString()}/mo`, '']} />
            </RPieChart>
          </ResponsiveContainer>
        </div>
      </div>
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
        <h3 className="text-xl font-bold text-white mb-6">Top 10 Costliest Tools</h3>
        <table className="w-full">
          <thead><tr className="border-b border-slate-800">
            {['Tool','Category','Monthly','Annual','Risk'].map(h => (
              <th key={h} className={`py-3 px-4 text-sm font-semibold text-slate-400 ${h === 'Monthly' || h === 'Annual' ? 'text-right' : h === 'Risk' ? 'text-center' : 'text-left'}`}>{h}</th>
            ))}
          </tr></thead>
          <tbody>
            {topTools.map((tool, idx) => (
              <tr key={idx} className="border-b border-slate-800/50">
                <td className="py-3 px-4 text-white font-medium">{tool.name}</td>
                <td className="py-3 px-4 text-slate-400">{tool.category || 'Other'}</td>
                <td className="py-3 px-4 text-right text-white">${(tool.cost_per_month || 0).toLocaleString()}</td>
                <td className="py-3 px-4 text-right text-emerald-400">${((tool.cost_per_month || 0) * 12).toLocaleString()}</td>
                <td className="py-3 px-4 text-center">
                  <span className={`px-3 py-1 rounded-full text-xs font-semibold ${tool.derived_risk === 'high' ? 'bg-red-500/20 text-red-400' : tool.derived_risk === 'medium' ? 'bg-yellow-500/20 text-yellow-400' : 'bg-emerald-500/20 text-emerald-400'}`}>
                    {tool.derived_risk || 'low'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="bg-gradient-to-r from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-xl font-bold text-white mb-2">Executive Summary</h3>
            <p className="text-slate-300">Spending <span className="font-bold text-white">${totalSpend.toLocaleString()}/month</span> on {data?.tools?.length || 0} tools. Identified <span className="font-bold text-emerald-400">${potentialSavings.toLocaleString()}/month</span> in savings.{highRiskTools > 0 && <span className="text-orange-400"> {highRiskTools} high-risk tools need attention.</span>}</p>
          </div>
          <div className="text-right"><div className="text-sm text-slate-400 mb-1">Annual ROI</div><div className="text-4xl font-black text-emerald-400">{roi}%</div></div>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// AI INSIGHTS — inlined from DashboardComponents.jsx
// ============================================================================
function AIInsights({ tools, employees, spend, accessData }) {
  const insights = [];
  const unusedTools = tools?.filter(t => {
    const lastUsed = new Date(t.last_used_date || 0);
    return Math.floor((Date.now() - lastUsed) / 86400000) > 90;
  }) || [];
  if (unusedTools.length > 0) {
    const savings = unusedTools.reduce((sum, t) => sum + (t.cost_per_month || 0), 0);
    insights.push({ icon: TrendingDown, title: 'Unused License Opportunity', description: `${unusedTools.length} tools haven't been used in 90+ days. Potential savings: $${savings.toLocaleString()}/month`, savings, priority: 'high', action: 'Review Tools', link: '/tools' });
  }
  const orphanedTools = tools?.filter(t => !t.owner_name || t.owner_name === 'Unassigned') || [];
  if (orphanedTools.length > 0) {
    insights.push({ icon: AlertTriangle, title: 'Unassigned Tools Detected', description: `${orphanedTools.length} tools have no owner. Security risk!`, priority: 'medium', action: 'Assign Owners', link: '/tools' });
  }
  if (insights.length === 0) {
    insights.push({ icon: Sparkles, title: 'All Systems Optimized', description: 'No immediate optimization opportunities detected!', priority: 'low', action: 'View Dashboard', link: '/dashboard' });
  }
  insights.sort((a, b) => ({ critical: 0, high: 1, medium: 2, low: 3 }[a.priority] - { critical: 0, high: 1, medium: 2, low: 3 }[b.priority]));
  const totalSavings = insights.filter(i => i.savings).reduce((sum, i) => sum + i.savings, 0);
  const colors = { critical: 'from-red-500/20 border-red-500/30', high: 'from-orange-500/20 border-orange-500/30', medium: 'from-yellow-500/20 border-yellow-500/30', low: 'from-emerald-500/20 border-emerald-500/30' };
  return (
    <div className="bg-gradient-to-br from-blue-500/10 via-purple-500/10 to-pink-500/10 border border-blue-500/20 rounded-2xl p-6 mb-6">
      <div className="flex items-center gap-3 mb-4">
        <div className="p-2 bg-gradient-to-br from-blue-500 to-purple-500 rounded-xl"><Sparkles className="h-5 w-5 text-white" /></div>
        <div className="flex-1">
          <h3 className="text-lg font-bold text-white">AI-Powered Insights</h3>
          <p className="text-sm text-slate-300">Smart recommendations to optimise your SaaS stack</p>
        </div>
        {totalSavings > 0 && <div className="text-right"><div className="text-2xl font-black text-emerald-400">${totalSavings.toLocaleString()}</div><div className="text-xs text-slate-400">potential monthly savings</div></div>}
      </div>
      <div className="space-y-3">
        {insights.slice(0, 3).map((insight, idx) => {
          const Icon = insight.icon;
          return (
            <div key={idx} className={`p-4 rounded-xl border bg-gradient-to-br ${colors[insight.priority]}`}>
              <div className="flex items-start gap-3">
                <Icon className="h-5 w-5 text-white mt-0.5" />
                <div className="flex-1">
                  <h4 className="font-semibold text-white mb-1">{insight.title}</h4>
                  <p className="text-sm text-slate-300 mb-3">{insight.description}</p>
                  <a href={insight.link} className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-sm font-semibold text-white">{insight.action} →</a>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function LicenseManagement() {
  const { language } = useLang();
  const t = useTranslation(language);
  const navigate = useNavigate();
  const [filter, setFilter] = useState('all');
  const [showReclaimModal, setShowReclaimModal] = useState(false);
  const [selectedApp, setSelectedApp] = useState(null);
  const [showSuccessToast, setShowSuccessToast] = useState(false);

  const licenseData = [
    { app: 'Salesforce', total: 250, used: 187, available: 63, inactive: 42, cost: 12400, costPerLicense: 49.6, lastSync: '2 min ago' },
    { app: 'Microsoft 365', total: 320, used: 298, available: 22, inactive: 18, cost: 9600, costPerLicense: 30, lastSync: '5 min ago' },
    { app: 'Slack', total: 450, used: 412, available: 38, inactive: 67, cost: 2850, costPerLicense: 6.33, lastSync: '1 min ago' },
    { app: 'Zoom', total: 200, used: 143, available: 57, inactive: 89, cost: 1950, costPerLicense: 9.75, lastSync: '10 min ago' },
    { app: 'Adobe Creative Cloud', total: 75, used: 68, available: 7, inactive: 12, cost: 5400, costPerLicense: 72, lastSync: '3 min ago' },
    { app: 'GitHub', total: 150, used: 134, available: 16, inactive: 23, cost: 3200, costPerLicense: 21.33, lastSync: '7 min ago' },
    { app: 'Asana', total: 180, used: 92, available: 88, inactive: 103, cost: 1800, costPerLicense: 10, lastSync: '4 min ago' },
    { app: 'Figma', total: 45, used: 41, available: 4, inactive: 8, cost: 2250, costPerLicense: 50, lastSync: '12 min ago' },
  ];

  // Filter logic
  const filteredLicenseData = licenseData.filter(app => {
    const utilization = (app.used / app.total * 100);
    if (filter === 'all') return true;
    if (filter === 'overprovisioned') return app.available > 20; // More than 20 unused
    if (filter === 'underutilized') return utilization < 50;
    if (filter === 'optimal') return utilization >= 80 && utilization <= 95;
    return true;
  });

  const handleReclaim = (app) => {
    const email = `mailto:admin@company.com?subject=Reclaim License - ${app.app}&body=Please reclaim ${app.available} unused licenses for ${app.app}.`;
    window.location.href = email;
    setShowReclaimModal(false);
    setSelectedApp(app);
    setShowReclaimModal(true);
  };

  const confirmReclaim = () => {
    if (selectedApp) {
      const subject = encodeURIComponent("License Reclaim Request: " + selectedApp.app);
      const body = encodeURIComponent(
        "Hi Team,\n\nPlease reclaim " + selectedApp.inactive + " inactive " + selectedApp.app + " licenses.\n" +
        "Monthly savings: $" + (selectedApp.inactive * selectedApp.costPerLicense).toFixed(2) + "\n\nRegards"
      );
      window.open("mailto:?subject=" + subject + "&body=" + body);
    }
    setShowReclaimModal(false);
    setShowSuccessToast(true);
    setTimeout(() => setShowSuccessToast(false), 3000);
  };

  const handleExport = () => {
    const csv = `Application,Total Licenses,Used,Available,Inactive,Monthly Cost,Cost per License,Waste\n${
      filteredLicenseData.map(app => 
        `${app.app},${app.total},${app.used},${app.available},${app.inactive},${app.cost},${app.costPerLicense.toFixed(2)},${Math.round(app.inactive * app.costPerLicense)}`
      ).join('\n')
    }`;
    
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `license-report-${filter}-${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  };

  const totalLicenses = licenseData.reduce((sum, app) => sum + app.total, 0);
  const totalUsed = licenseData.reduce((sum, app) => sum + app.used, 0);
  const totalInactive = licenseData.reduce((sum, app) => sum + app.inactive, 0);
  const wastedCost = licenseData.reduce((sum, app) => sum + (app.inactive * app.costPerLicense), 0);

  return (
    <AppShell currentPage="licenses">
      <div className="p-8">
        <div className="mb-8">
          <h1 className="text-4xl font-black mb-2">{"Licenses" || "License Management"}</h1>
          <p className="text-slate-400">Track utilization and reclaim unused licenses</p>
        </div>

        {/* Key Metrics */}
        <div className="grid md:grid-cols-4 gap-6 mb-8">
          <Card className="p-6 bg-gradient-to-br from-blue-500/10 to-indigo-500/10 border-blue-500/20">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('total_licenses')}</span>
              <Users className="w-5 h-5 text-blue-400" />
            </div>
            <div className="text-3xl font-black text-white">{totalLicenses.toLocaleString()}</div>
            <div className="text-sm text-slate-400">Across {licenseData.length} applications</div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('active_users')}</span>
              <BadgeCheck className="w-5 h-5 text-emerald-400" />
            </div>
            <div className="text-3xl font-black text-white">{totalUsed.toLocaleString()}</div>
            <div className="text-sm text-emerald-400">{((totalUsed / totalLicenses) * 100).toFixed(1)}% utilization</div>
          </Card>

          <Card className="p-6 bg-gradient-to-br from-red-500/10 to-orange-500/10 border-red-500/20">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('unused_licenses_label')}</span>
              <AlertTriangle className="w-5 h-5 text-red-400" />
            </div>
            <div className="text-3xl font-black text-white">{totalInactive.toLocaleString()}</div>
            <div className="text-sm text-red-400">{t('reclaim_licenses')}</div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('license_waste')}</span>
              <CreditCard className="w-5 h-5 text-yellow-400" />
            </div>
            <div className="text-3xl font-black text-white">${Math.round(wastedCost).toLocaleString()}</div>
            <div className="text-sm text-yellow-400">${Math.round(wastedCost * 12).toLocaleString()}/year</div>
          </Card>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-4 mb-6">
          <Select value={filter} onChange={(e) => setFilter(e.target.value)}>
            <option value="all">{t('all_integrations')}</option>
            <option value="overprovisioned">{t('high_risk')}</option>
            <option value="underutilized">Under-utilized (&lt;50%)</option>
            <option value="optimal">Optimal Usage</option>
          </Select>
          <button 
            onClick={handleExport}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-500 rounded-lg font-semibold flex items-center gap-2 transition-colors"
          >
            <Download className="w-4 h-4" />
            Export Report
          </button>
          <button
            onClick={() => {
              const reclaimable = filteredLicenseData.filter(a => a.inactive > 0);
              const totalInactive = reclaimable.reduce((s, a) => s + a.inactive, 0);
              const totalSavings = reclaimable.reduce((s, a) => s + (a.inactive * a.costPerLicense), 0);
              const subject = encodeURIComponent("Auto-Reclaim Request: " + totalInactive + " Inactive Licenses");
              const body = encodeURIComponent(
                "Hi Team,\n\nPlease process auto-reclaim for all inactive licenses:\n\n" +
                reclaimable.map(a => "- " + a.app + ": " + a.inactive + " inactive licenses ($" + (a.inactive * a.costPerLicense).toFixed(2) + "/mo)").join("\n") +
                "\n\nTotal potential monthly savings: $" + totalSavings.toFixed(2) + "\n\nRegards"
              );
              window.open("mailto:?subject=" + subject + "&body=" + body);
            }}
            className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg font-semibold flex items-center gap-2 transition-colors">
            <Sparkles className="w-4 h-4" />
            Auto-Reclaim All
          </button>
        </div>

        {/* License Table */}
        <Card className="p-6">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/10">
                   <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">{t('application')}</th>
                   <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('total_licenses')}</th>
                   <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('used_licenses')}</th>
                   <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('available_licenses')}</th>
                   <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('inactive_90d')}</th>
                   <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('cost_per_month')}</th>
                   <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('waste')}</th>
                   <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filteredLicenseData.map((app, idx) => {
                  const utilization = (app.used / app.total * 100).toFixed(0);
                  const waste = app.inactive * app.costPerLicense;
                  return (
                    <tr key={idx} className="border-b border-white/5 hover:bg-white/5">
                      <td className="py-4 px-4">
                        <div className="font-semibold text-white">{app.app}</div>
                        <div className="text-xs text-slate-500">Synced {app.lastSync}</div>
                      </td>
                      <td className="py-4 px-4 text-right font-mono text-white">{app.total}</td>
                      <td className="py-4 px-4 text-right">
                        <div className="font-mono text-emerald-400">{app.used}</div>
                        <div className="text-xs text-slate-500">{utilization}%</div>
                      </td>
                      <td className="py-4 px-4 text-right font-mono text-blue-400">{app.available}</td>
                      <td className="py-4 px-4 text-right">
                        <div className="font-mono text-red-400">{app.inactive}</div>
                      </td>
                      <td className="py-4 px-4 text-right font-mono text-white">${app.cost.toLocaleString()}</td>
                      <td className="py-4 px-4 text-right">
                        <div className="font-mono text-yellow-400">${Math.round(waste).toLocaleString()}</div>
                        <div className="text-xs text-slate-500">${Math.round(waste * 12).toLocaleString()}/yr</div>
                      </td>
                      <td className="py-4 px-4 text-right">
                        <button 
                          onClick={() => handleReclaim(app)}
                          className="px-3 py-1 bg-blue-600 hover:bg-blue-500 rounded text-sm font-semibold transition-colors"
                        >
                          Reclaim
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </AppShell>
  );
}

// Continue in next message due to size...
// RENEWAL ALERTS PAGE

function openNegotiateEmail(renewal) {
  const subject = encodeURIComponent(`Renewal Negotiation: ${renewal.app}`);
  const body = encodeURIComponent(`Hi,

I'm reaching out regarding the upcoming renewal for ${renewal.app} on ${renewal.renewalDate}.

Current details:
- Annual cost: $${renewal.cost.toLocaleString()}
- Contract owner: ${renewal.owner}
- Auto-renewal: ${renewal.autoRenew ? 'Yes' : 'No'}

I'd like to discuss:
1. Pricing options for renewal
2. Usage optimization opportunities  
3. Contract term flexibility

Can we schedule a call this week?

Best regards`);
  
  window.location.href = `mailto:vendor@${renewal.app.toLowerCase()}.com?subject=${subject}&body=${body}`;
}

function ContractsRenewalsHub() {
  const { language } = useLang();
  const t = useTranslation(language);
  const [cTab, setCTab] = useState('renewals');
  const TABS = [
    { id: 'renewals',  label: '🔔 ' + t('nav_renewals'),  desc: t('renewals_desc') },
    { id: 'invoices',  label: '📤 ' + t('nav_invoices'),   desc: t('invoices_desc') },
    { id: 'contracts', label: '📄 ' + t('nav_contracts_tab'), desc: t('contracts_desc') },
  ];
  return (
    <AppShell title={t('nav_contracts')}
      right={
        <div className="flex gap-1 p-1 bg-slate-900 rounded-xl border border-slate-800">
          {TABS.map(tab => (
            <button key={tab.id} onClick={() => setCTab(tab.id)}
              className={"px-3 py-1.5 rounded-lg text-xs font-semibold transition-all " + (cTab === tab.id ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white')}>
              {tab.label}
            </button>
          ))}
        </div>
      }
    >
      {cTab === 'renewals'  && <RenewalsTabContent />}
      {cTab === 'invoices'  && <InvoicesTabContent />}
      {cTab === 'contracts' && <ContractsTabContent />}
    </AppShell>
  );
}

function RenewalsTabContent() {
  return <RenewalAlerts />;
}

function RenewalAlerts() {
  const navigate = useNavigate();
  const { language } = useLang();
  const t = useTranslation(language);

  const [view, setView] = useState('list');
  const [showReviewModal, setShowReviewModal] = useState(false);
  const [showNegotiateModal, setShowNegotiateModal] = useState(false);
  const [selectedRenewal, setSelectedRenewal] = useState(null);
  const [showReviewAllModal, setShowReviewAllModal] = useState(false);
  const [showRemindersModal, setShowRemindersModal] = useState(false);
  const [reminderDays, setReminderDays] = useState(30);
  const [reviewedApps, setReviewedApps] = useState([]);

  const renewals = [
    { app: 'Salesforce', renewalDate: '2026-03-15', cost: 12400, term: 'Annual', owner: 'Sarah Chen', daysUntil: 21, status: 'upcoming', autoRenew: true },
    { app: 'Microsoft 365', renewalDate: '2026-04-01', cost: 9600, term: 'Annual', owner: 'Mike Johnson', daysUntil: 38, status: 'upcoming', autoRenew: true },
    { app: 'Slack', renewalDate: '2026-03-25', cost: 2850, term: 'Annual', owner: 'Lisa Wong', daysUntil: 31, status: 'upcoming', autoRenew: false },
    { app: 'Zoom', renewalDate: '2026-03-08', cost: 1950, term: 'Annual', owner: 'David Kim', daysUntil: 14, status: 'critical', autoRenew: true },
    { app: 'GitHub', renewalDate: '2026-05-12', cost: 3200, term: 'Annual', owner: 'Tom Rodriguez', daysUntil: 79, status: 'normal', autoRenew: false },
    { app: 'Adobe CC', renewalDate: '2026-03-05', cost: 5400, term: 'Annual', owner: 'Emma Davis', daysUntil: 11, status: 'critical', autoRenew: true },
    { app: 'Asana', renewalDate: '2026-06-20', cost: 1800, term: 'Annual', owner: 'James Lee', daysUntil: 118, status: 'normal', autoRenew: false },
    { app: 'Figma', renewalDate: '2026-03-18', cost: 2250, term: 'Annual', owner: 'Nina Patel', daysUntil: 24, status: 'upcoming', autoRenew: true },
  ];

  const critical = renewals.filter(r => r.daysUntil <= 30);
  const upcoming = renewals.filter(r => r.daysUntil > 30 && r.daysUntil <= 90);
  const totalRenewalCost = critical.reduce((sum, r) => sum + r.cost, 0);

  // Export as .ics calendar file
  const exportICS = () => {
    const lines = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//SaasGuard//Renewals//EN', 'CALSCALE:GREGORIAN'];
    renewals.forEach(r => {
      const d = r.renewalDate.replace(/-/g, '');
      const uid = r.app.replace(/\s/g, '') + '-renewal@accessguard.io';
      lines.push('BEGIN:VEVENT');
      lines.push('UID:' + uid);
      lines.push('DTSTART;VALUE=DATE:' + d);
      lines.push('DTEND;VALUE=DATE:' + d);
      lines.push('SUMMARY:🔔 ' + r.app + ' Renewal — $' + r.cost.toLocaleString());
      lines.push('DESCRIPTION:Owner: ' + r.owner + '\\nAuto-Renew: ' + (r.autoRenew ? 'Yes ⚠️' : 'No') + '\\nCost: $' + r.cost.toLocaleString());
      lines.push('BEGIN:VALARM');
      lines.push('TRIGGER:-P30D');
      lines.push('ACTION:DISPLAY');
      lines.push('DESCRIPTION:Renewal reminder: ' + r.app);
      lines.push('END:VALARM');
      lines.push('END:VEVENT');
    });
    lines.push('END:VCALENDAR');
    const blob = new Blob([lines.join('\r\n')], { type: 'text/calendar;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'saasguard-renewals.ics';
    a.click();
    URL.revokeObjectURL(url);
    toast.success('Calendar exported — open in Google Calendar or Outlook');
  };

  // Build calendar grid for current month + next 2 months
  const CalendarGrid = () => {
    const today = new Date();
    const months = [0, 1, 2].map(offset => {
      const d = new Date(today.getFullYear(), today.getMonth() + offset, 1);
      return { year: d.getFullYear(), month: d.getMonth(), label: d.toLocaleString('default', { month: 'long', year: 'numeric' }) };
    });

    return (
      <div className="space-y-8">
        {months.map(({ year, month, label }) => {
          const firstDay = new Date(year, month, 1).getDay();
          const daysInMonth = new Date(year, month + 1, 0).getDate();
          const monthRenewals = renewals.filter(r => {
            const rd = new Date(r.renewalDate);
            return rd.getFullYear() === year && rd.getMonth() === month;
          });

          const cells = [];
          for (let i = 0; i < firstDay; i++) cells.push(null);
          for (let d = 1; d <= daysInMonth; d++) cells.push(d);

          return (
            <div key={label}>
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-white">{label}</h3>
                <span className="text-sm text-slate-500">{monthRenewals.length} renewal{monthRenewals.length !== 1 ? 's' : ''}</span>
              </div>
              <div className="grid grid-cols-7 gap-1 mb-2">
                {['Sun','Mon','Tue','Wed','Thu','Fri','Sat'].map(d => (
                  <div key={d} className="text-center text-xs font-semibold text-slate-600 py-1">{d}</div>
                ))}
              </div>
              <div className="grid grid-cols-7 gap-1">
                {cells.map((day, idx) => {
                  if (!day) return <div key={'empty-' + idx} />;
                  const dateStr = `${year}-${String(month + 1).padStart(2,'0')}-${String(day).padStart(2,'0')}`;
                  const dayRenewals = renewals.filter(r => r.renewalDate === dateStr);
                  const isToday = today.getDate() === day && today.getMonth() === month && today.getFullYear() === year;
                  return (
                    <div key={day} className={`min-h-[60px] rounded-lg p-1.5 border transition-all ${
                      dayRenewals.length > 0
                        ? dayRenewals.some(r => r.status === 'critical')
                          ? 'border-red-500/40 bg-red-500/10 hover:bg-red-500/20'
                          : 'border-yellow-500/40 bg-yellow-500/10 hover:bg-yellow-500/20'
                        : isToday
                          ? 'border-blue-500/40 bg-blue-500/10'
                          : 'border-slate-800 bg-slate-900/40 hover:border-slate-700'
                    }`}>
                      <div className={`text-xs font-bold mb-1 ${isToday ? 'text-blue-400' : 'text-slate-400'}`}>{day}</div>
                      {dayRenewals.map(r => (
                        <button
                          key={r.app}
                          onClick={() => { setSelectedRenewal(r); setShowReviewModal(true); }}
                          className={`w-full text-left text-[10px] font-semibold px-1.5 py-0.5 rounded mb-0.5 truncate ${
                            r.status === 'critical' ? 'bg-red-600/60 text-red-100' : 'bg-yellow-600/60 text-yellow-100'
                          }`}
                          title={r.app + ' — $' + r.cost.toLocaleString()}
                        >
                          {r.app}
                        </button>
                      ))}
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}
        <div className="flex items-center gap-4 text-xs text-slate-500">
          <span className="flex items-center gap-1.5"><span className="w-3 h-3 rounded bg-red-500/40 inline-block" /> Critical (≤30 days)</span>
          <span className="flex items-center gap-1.5"><span className="w-3 h-3 rounded bg-yellow-500/40 inline-block" /> Upcoming (31–90 days)</span>
          <span className="flex items-center gap-1.5"><span className="w-3 h-3 rounded bg-blue-500/40 inline-block" /> Today</span>
        </div>
      </div>
    );
  };

  return (
    <div className="p-0">
      <div className="p-8">
        <div className="mb-8">
          <h1 className="text-4xl font-black mb-2">🔔 Renewals</h1>
          <p className="text-slate-400">Stay ahead of contract renewals and avoid auto-renew surprises</p>
        </div>

        {/* Key Metrics */}
        <div className="grid md:grid-cols-4 gap-6 mb-8">
          <Card className="p-6 bg-gradient-to-br from-red-500/10 to-orange-500/10 border-red-500/20">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">Critical (≤30 days)</span>
              <AlertTriangle className="w-5 h-5 text-red-400" />
            </div>
            <div className="text-3xl font-black text-white">{critical.length}</div>
            <div className="text-sm text-red-400">${totalRenewalCost.toLocaleString()} at risk</div>
          </Card>
          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">Upcoming (30–90 days)</span>
              <CalendarClock className="w-5 h-5 text-yellow-400" />
            </div>
            <div className="text-3xl font-black text-white">{upcoming.length}</div>
            <div className="text-sm text-slate-400">{t('need_review_soon')}</div>
          </Card>
          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('auto_renew_enabled')}</span>
              <RefreshCw className="w-5 h-5 text-blue-400" />
            </div>
            <div className="text-3xl font-black text-white">{renewals.filter(r => r.autoRenew).length}</div>
            <div className="text-sm text-blue-400">{t('auto_renew_enabled')}</div>
          </Card>
          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">Total 90-day Cost</span>
              <CreditCard className="w-5 h-5 text-emerald-400" />
            </div>
            <div className="text-3xl font-black text-white">
              ${renewals.filter(r => r.daysUntil <= 90).reduce((s, r) => s + r.cost, 0).toLocaleString()}
            </div>
          </Card>
        </div>

        {/* View Toggle */}
        <div className="flex items-center gap-3 mb-6">
          <button
            onClick={() => setView('calendar')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-semibold transition-all ${view === 'calendar' ? 'bg-blue-600 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
          >
            📅 Calendar View
          </button>
          <button
            onClick={() => setView('list')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-semibold transition-all ${view === 'list' ? 'bg-blue-600 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
          >
            📋 List View
          </button>
          <div className="ml-auto flex items-center gap-3">
            <button
              onClick={() => setShowRemindersModal(true)}
              className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-lg font-semibold transition-all text-slate-300"
            >
              ⏰ Set Reminders
            </button>
            <button
              onClick={exportICS}
              className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg font-semibold transition-all text-white"
              title="Download .ics file — import into Google Calendar, Outlook or Apple Calendar"
            >
              <Download className="w-4 h-4" />
              Export to Calendar (.ics)
            </button>
          </div>
        </div>

        {/* Critical Renewals Alert */}
        {critical.length > 0 && (
          <Card className="p-6 mb-8 bg-gradient-to-r from-red-500/10 to-orange-500/10 border-red-500/20">
            <div className="flex items-start gap-4">
              <AlertTriangle className="w-6 h-6 text-red-400 flex-shrink-0 mt-1" />
              <div className="flex-1">
                <h3 className="text-lg font-bold text-white mb-2">⚠️ {critical.length} Critical Renewals in Next 30 Days</h3>
                <p className="text-slate-300 mb-4">You have ${totalRenewalCost.toLocaleString()} in renewals coming up. Review and take action to avoid surprise charges.</p>
                <div className="flex gap-3">
                  <button onClick={() => setShowReviewAllModal(true)} className="px-4 py-2 bg-red-600 hover:bg-red-500 rounded-lg font-semibold transition-colors">
                    Review All Critical
                  </button>
                </div>
              </div>
            </div>
          </Card>
        )}

        {/* Calendar View */}
        {view === 'calendar' && (
          <Card className="p-6">
            <CalendarGrid />
          </Card>
        )}

        {/* List View */}
        {view === 'list' && (
          <Card className="p-6">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-white/10">
                     <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">{t('application')}</th>
                     <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">{t('renewal_date')}</th>
                     <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('days_until')}</th>
                     <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('renewal_cost')}</th>
                    <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">{t('owner')}</th>
                     <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">Auto-Renew</th>
                     <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">{t('actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {renewals.filter(r => !reviewedApps.includes(r.app)).sort((a,b) => a.daysUntil - b.daysUntil).map((renewal, idx) => (
                    <tr key={idx} className="border-b border-white/5 hover:bg-white/5">
                      <td className="py-4 px-4">
                        <div className="font-semibold text-white">{renewal.app}</div>
                        <div className="text-xs text-slate-500">{renewal.term} contract</div>
                      </td>
                      <td className="py-4 px-4 text-slate-300">{renewal.renewalDate}</td>
                      <td className="py-4 px-4 text-right">
                        <Pill tone={renewal.status === 'critical' ? 'red' : renewal.status === 'upcoming' ? 'yellow' : 'blue'}>
                          {renewal.daysUntil} days
                        </Pill>
                      </td>
                      <td className="py-4 px-4 text-right font-mono text-white">${renewal.cost.toLocaleString()}</td>
                      <td className="py-4 px-4 text-slate-300">{renewal.owner}</td>
                      <td className="py-4 px-4">
                        {renewal.autoRenew
                          ? <Pill tone="red" icon={AlertTriangle}>Enabled</Pill>
                          : <Pill tone="green">Disabled</Pill>
                        }
                      </td>
                      <td className="py-4 px-4 text-right">
                        <div className="flex gap-2 justify-end">
                          <button onClick={() => { setSelectedRenewal(renewal); setShowReviewModal(true); }}
                            className="px-3 py-1.5 bg-blue-600 hover:bg-blue-500 rounded text-sm font-semibold transition-colors">
                            Review
                          </button>
                          <button onClick={() => { setSelectedRenewal(renewal); setShowNegotiateModal(true); }}
                            className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 rounded text-sm font-semibold transition-colors">
                            Negotiate
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        )}

        {/* Reviewed Apps */}
        {reviewedApps.length > 0 && (
          <Card className="p-6 mt-6 border-emerald-500/20 bg-emerald-500/5">
            <div className="flex items-center gap-3 mb-4">
              <BadgeCheck className="h-5 w-5 text-emerald-400" />
              <h3 className="text-lg font-bold text-white">Reviewed</h3>
              <span className="text-xs bg-emerald-500/20 text-emerald-400 px-2 py-0.5 rounded-full font-semibold">{reviewedApps.length} done</span>
            </div>
            <div className="flex flex-wrap gap-2">
              {reviewedApps.map(app => (
                <div key={app} className="flex items-center gap-2 px-3 py-1.5 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-sm">
                  <span className="text-emerald-400 font-semibold">{app}</span>
                  <button onClick={() => setReviewedApps(prev => prev.filter(a => a !== app))} className="text-slate-500 hover:text-slate-300 transition-colors">×</button>
                </div>
              ))}
            </div>
          </Card>
        )}

        {/* Review Modal */}
        {showReviewModal && selectedRenewal && (
          <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-6">
            <div className="bg-slate-900 rounded-3xl border border-white/10 p-8 max-w-lg w-full">
              <h3 className="text-2xl font-bold mb-4">Review: {selectedRenewal.app}</h3>
              <div className="space-y-3 mb-6 text-sm">
                <div className="flex justify-between"><span className="text-slate-400">Renewal Date:</span><span className="font-semibold">{selectedRenewal.renewalDate}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Cost:</span><span className="font-semibold">${selectedRenewal.cost.toLocaleString()}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Days Until:</span><span className={`font-semibold ${selectedRenewal.daysUntil <= 14 ? 'text-red-400' : 'text-yellow-400'}`}>{selectedRenewal.daysUntil} days</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Owner:</span><span className="font-semibold">{selectedRenewal.owner}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Auto-Renew:</span><span className={`font-semibold ${selectedRenewal.autoRenew ? 'text-red-400' : 'text-green-400'}`}>{selectedRenewal.autoRenew ? 'Enabled ⚠️' : 'Disabled ✓'}</span></div>
              </div>
              <div className="bg-blue-500/10 border border-blue-500/20 rounded-xl p-4 mb-6">
                <div className="font-semibold text-blue-400 mb-2 text-sm">Recommended Actions:</div>
                <ul className="text-xs text-slate-300 space-y-1">
                  <li>✓ Verify current usage and necessity</li>
                  <li>✓ Review pricing vs alternatives</li>
                  <li>✓ Contact vendor for better rates</li>
                  {selectedRenewal.autoRenew && <li className="text-red-400">⚠️ Consider disabling auto-renew</li>}
                </ul>
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowReviewModal(false)} className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold transition-colors">{t('cancel')}</button>
                <button onClick={() => { setReviewedApps(prev => [...prev, selectedRenewal.app]); setShowReviewModal(false); }}
                  className="flex-1 px-4 py-3 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors flex items-center justify-center gap-2">
                  ✓ Mark as Reviewed
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Negotiate Modal */}
        {showNegotiateModal && selectedRenewal && (
          <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-6">
            <div className="bg-slate-900 rounded-3xl border border-white/10 p-8 max-w-lg w-full max-h-[90vh] overflow-y-auto">
              <h3 className="text-2xl font-bold mb-4">Negotiate: {selectedRenewal.app}</h3>
              <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-xl p-4 mb-4">
                <div className="font-semibold text-emerald-400 mb-2 text-sm">💡 Leverage Points:</div>
                <ul className="text-xs text-slate-300 space-y-1">
                  <li>✓ Multi-year commit for 15–20% discount</li>
                  <li>✓ Mention competitor pricing</li>
                  <li>✓ Request volume discount</li>
                  <li>✓ Ask for additional licenses at no extra cost</li>
                </ul>
              </div>
              <div className="bg-blue-500/10 border border-blue-500/20 rounded-xl p-4 mb-6">
                <div className="font-semibold text-blue-400 mb-2 text-sm">📧 Email Template:</div>
                <div className="text-xs text-slate-300 bg-slate-950/50 p-3 rounded-lg font-mono leading-relaxed">
                  Hi [Vendor],<br/><br/>
                  We are reviewing our {selectedRenewal.app} subscription (${selectedRenewal.cost.toLocaleString()}/year).<br/><br/>
                  Could you provide:<br/>
                  • Multi-year pricing options<br/>
                  • Volume discounts<br/>
                  • Any current promotions<br/><br/>
                  Thanks,<br/>
                  {selectedRenewal.owner}
                </div>
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowNegotiateModal(false)} className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold transition-colors">{t('close')}</button>
                <button
                  onClick={() => {
                    const subject = encodeURIComponent("Contract Renewal Discussion: " + selectedRenewal.app);
                    const body = encodeURIComponent("Hi [Vendor],\n\nWe are reviewing our " + selectedRenewal.app + " renewal ($" + selectedRenewal.cost.toLocaleString() + "/year).\n\nCould you provide:\n- Multi-year pricing options\n- Volume discounts\n- Any current promotions\n\nThanks,\n" + selectedRenewal.owner);
                    window.open("mailto:?subject=" + subject + "&body=" + body);
                  }}
                  className="flex-1 px-4 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold transition-colors flex items-center justify-center gap-2"
                >
                  📧 Open in Email
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Review All Critical Modal */}
        {showReviewAllModal && (
          <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-6">
            <div className="bg-slate-900 rounded-3xl border border-white/10 p-8 max-w-2xl w-full max-h-[80vh] overflow-y-auto">
              <h3 className="text-2xl font-bold mb-4">⚠️ Critical Renewals (≤30 days)</h3>
              <div className="space-y-4 mb-6">
                {critical.map((renewal, idx) => (
                  <div key={idx} className="p-4 bg-red-500/10 border border-red-500/20 rounded-xl">
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-bold text-lg text-white">{renewal.app}</span>
                      <span className="px-3 py-1 bg-red-600 rounded-full text-sm font-semibold">{renewal.daysUntil} days</span>
                    </div>
                    <div className="grid grid-cols-2 gap-3 text-sm mb-3">
                      <div><div className="text-slate-400">Cost</div><div className="font-semibold">${renewal.cost.toLocaleString()}</div></div>
                      <div><div className="text-slate-400">{t('owner')}</div><div className="font-semibold">{renewal.owner}</div></div>
                    </div>
                    <div className="flex gap-2">
                      <button onClick={() => { setSelectedRenewal(renewal); setShowReviewAllModal(false); setShowReviewModal(true); }}
                        className="px-4 py-2 bg-blue-600 hover:bg-blue-500 rounded-lg text-sm font-semibold transition-colors">{t('review')}</button>
                      <button onClick={() => { setSelectedRenewal(renewal); setShowReviewAllModal(false); setShowNegotiateModal(true); }}
                        className="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded-lg text-sm font-semibold transition-colors">{t('negotiate')}</button>
                    </div>
                  </div>
                ))}
              </div>
              <button onClick={() => setShowReviewAllModal(false)} className="w-full px-4 py-3 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold transition-colors">{t('close')}</button>
            </div>
          </div>
        )}

        {/* Set Reminders Modal */}
        {showRemindersModal && (
          <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-6">
            <div className="bg-slate-900 rounded-3xl border border-white/10 p-8 max-w-lg w-full">
              <h3 className="text-2xl font-bold mb-2">⏰ Set Renewal Reminders</h3>
              <p className="text-slate-400 mb-6">Get notified before renewals so you can review and negotiate</p>
              <div className="space-y-4 mb-6">
                <div>
                  <label className="block text-sm font-semibold text-white mb-2">Remind me this many days before renewal:</label>
                  <input type="range" min="7" max="90" value={reminderDays} onChange={e => setReminderDays(parseInt(e.target.value))}
                    className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-blue-500" />
                  <div className="mt-2 text-center text-3xl font-bold text-white">{reminderDays} days</div>
                </div>
                <div className="bg-blue-500/10 border border-blue-500/20 rounded-xl p-4">
                  <div className="font-semibold text-blue-400 mb-3 text-sm">Notification Channels:</div>
                  <div className="space-y-2">
                    {[
                      { label: 'Email notifications', checked: true },
                      { label: 'Slack notifications', checked: true },
                      { label: 'SMS notifications (Pro)', checked: false },
                    ].map(item => (
                      <label key={item.label} className="flex items-center gap-2 cursor-pointer">
                        <input type="checkbox" defaultChecked={item.checked} className="w-4 h-4 accent-blue-500" />
                        <span className="text-sm text-slate-300">{item.label}</span>
                      </label>
                    ))}
                  </div>
                </div>
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowRemindersModal(false)} className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold transition-colors">{t('cancel')}</button>
                <button onClick={() => { setShowRemindersModal(false); toast.success('Reminders set for ' + reminderDays + ' days before renewal'); }}
                  className="flex-1 px-4 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold transition-colors">
                  Save Reminders
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
        </div>
  );
}

function InvoicesTabContent() {
  const { language } = useLang();
  const t = useTranslation(language);
  return <InvoiceManager />;
}

function InvoiceManager() {
  const navigate = useNavigate();
  const { language, setLanguage } = useLang();
  const t = useTranslation(language);


  const [showUploadModal, setShowUploadModal] = useState(false);
  const [filter, setFilter] = useState('all');
  const [uploadForm, setUploadForm] = useState({ vendor: '', amount: '', dueDate: '', category: 'CRM' });
  const [uploadFileName, setUploadFileName] = useState('');
  const [uploadSuccess, setUploadSuccess] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState(null);
  const [showInvoiceDetail, setShowInvoiceDetail] = useState(false);

  const handleUploadSubmit = (e) => {
    e.preventDefault();
    const existing = JSON.parse(localStorage.getItem('ag_uploaded_invoices') || '[]');
    existing.push({
      id: 'INV-' + Date.now(),
      vendor: uploadForm.vendor,
      amount: parseFloat(uploadForm.amount) || 0,
      dueDate: uploadForm.dueDate,
      category: uploadForm.category,
      fileName: uploadFileName,
      status: 'pending_approval',
      uploadedAt: new Date().toISOString(),
    });
    localStorage.setItem('ag_uploaded_invoices', JSON.stringify(existing));
    setUploadSuccess(true);
    setTimeout(() => {
      setShowUploadModal(false);
      setUploadForm({ vendor: '', amount: '', dueDate: '', category: 'CRM' });
      setUploadFileName('');
      setUploadSuccess(false);
    }, 1500);
  };

  const invoices = [
    { id: 'INV-2401', vendor: 'Salesforce', amount: 12400, date: '2026-02-01', dueDate: '2026-03-01', status: 'pending_approval', category: 'CRM', submittedBy: 'Sarah Chen' },
    { id: 'INV-2402', vendor: 'Slack', amount: 2850, date: '2026-02-05', dueDate: '2026-03-05', status: 'approved', category: 'Communication', submittedBy: 'Mike Johnson' },
    { id: 'INV-2403', vendor: 'GitHub', amount: 3200, date: '2026-02-10', dueDate: '2026-03-10', status: 'paid', category: 'Development', submittedBy: 'Tom Rodriguez' },
    { id: 'INV-2404', vendor: 'Zoom', amount: 1950, date: '2026-02-15', dueDate: '2026-03-15', status: 'pending_approval', category: 'Communication', submittedBy: 'David Kim' },
    { id: 'INV-2405', vendor: 'Adobe CC', amount: 5400, date: '2026-02-20', dueDate: '2026-03-20', status: 'approved', category: 'Design', submittedBy: 'Emma Davis' },
    { id: 'INV-2406', vendor: 'Asana', amount: 1800, date: '2026-01-15', dueDate: '2026-02-15', status: 'overdue', category: 'Productivity', submittedBy: 'James Lee' },
  ];

  const pending = invoices.filter(i => i.status === 'pending_approval');
  const approved = invoices.filter(i => i.status === 'approved');
  const overdue = invoices.filter(i => i.status === 'overdue');
  const totalPending = pending.reduce((sum, inv) => sum + inv.amount, 0);

  // Filter invoices based on selected filter
  const filteredInvoices = invoices.filter(inv => {
    if (filter === 'all') return true;
    if (filter === 'pending') return inv.status === 'pending_approval';
    if (filter === 'approved') return inv.status === 'approved';
    if (filter === 'paid') return inv.status === 'paid';
    if (filter === 'overdue') return inv.status === 'overdue';
    return true;
  });

  // Export to CSV
  const handleExport = () => {
    const csv = `Invoice #,Vendor,Category,Amount,Due Date,Status,Submitted By\n${
      filteredInvoices.map(inv => 
        `${inv.id},${inv.vendor},${inv.category},${inv.amount},${inv.dueDate},${inv.status},${inv.submittedBy}`
      ).join('\n')
    }`;
    
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `invoices-${filter}-${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  };

  return (
    <div>
      <div className="p-8">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-4xl font-black mb-2">📤 Invoice Manager</h1>
            <p className="text-slate-400">Submit and track vendor invoices for finance approval</p>
          </div>
          <button 
            onClick={() => setShowUploadModal(true)}
            className="px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold flex items-center gap-2"
          >
            <Upload className="w-5 h-5" />
            Upload Invoice
          </button>
        </div>

        {/* Key Metrics */}
        <div className="grid md:grid-cols-4 gap-6 mb-8">
          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">Pending Approval</span>
              <CalendarClock className="w-5 h-5 text-yellow-400" />
            </div>
            <div className="text-3xl font-black text-white">{pending.length}</div>
            <div className="text-sm text-yellow-400">${totalPending.toLocaleString()}</div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('approved')}</span>
              <BadgeCheck className="w-5 h-5 text-emerald-400" />
            </div>
            <div className="text-3xl font-black text-white">{approved.length}</div>
            <div className="text-sm text-emerald-400">Ready for payment</div>
          </Card>

          <Card className="p-6 bg-gradient-to-br from-red-500/10 to-orange-500/10 border-red-500/20">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">{t('overdue')}</span>
              <AlertTriangle className="w-5 h-5 text-red-400" />
            </div>
            <div className="text-3xl font-black text-white">{overdue.length}</div>
            <div className="text-sm text-red-400">Needs attention</div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-slate-400">Paid This Month</span>
              <CheckCircle className="w-5 h-5 text-blue-400" />
            </div>
            <div className="text-3xl font-black text-white">
              {invoices.filter(i => i.status === 'paid').length}
            </div>
          </Card>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-4 mb-6">
          <Select value={filter} onChange={(e) => setFilter(e.target.value)}>
            <option value="all">{t('all_invoices')}</option>
            <option value="pending">Pending Approval</option>
            <option value="approved">{t('approved')}</option>
            <option value="paid">Paid</option>
            <option value="overdue">{t('overdue')}</option>
          </Select>
          <button 
            onClick={handleExport}
            className="px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-lg font-semibold flex items-center gap-2 transition-colors"
          >
            <Download className="w-4 h-4" />
            Export Report
          </button>
        </div>

        {/* Invoices Table */}
        <Card className="p-6">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/10">
                  <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">Invoice #</th>
                  <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">Vendor</th>
                  <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">Category</th>
                  <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">Amount</th>
                  <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">Due Date</th>
                  <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">Submitted By</th>
                  <th className="text-left py-4 px-4 text-sm font-semibold text-slate-400">Status</th>
                  <th className="text-right py-4 px-4 text-sm font-semibold text-slate-400">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredInvoices.map((invoice, idx) => (
                  <tr key={idx} className="border-b border-white/5 hover:bg-white/5">
                    <td className="py-4 px-4">
                      <div className="font-mono text-blue-400">{invoice.id}</div>
                      <div className="text-xs text-slate-500">{invoice.date}</div>
                    </td>
                    <td className="py-4 px-4 font-semibold text-white">{invoice.vendor}</td>
                    <td className="py-4 px-4 text-slate-300">{invoice.category}</td>
                    <td className="py-4 px-4 text-right font-mono font-bold text-white">${invoice.amount.toLocaleString()}</td>
                    <td className="py-4 px-4 text-slate-300">{invoice.dueDate}</td>
                    <td className="py-4 px-4 text-slate-300">{invoice.submittedBy}</td>
                    <td className="py-4 px-4">
                      <Pill tone={
                        invoice.status === 'paid' ? 'green' :
                        invoice.status === 'approved' ? 'blue' :
                        invoice.status === 'overdue' ? 'red' : 'yellow'
                      }>
                        {invoice.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                      </Pill>
                    </td>
                    <td className="py-4 px-4 text-right">
                      <div className="flex gap-2 justify-end">
                        <button
                          onClick={() => {
                            setSelectedInvoice(invoice);
                            setShowInvoiceDetail(true);
                          }}
                          className="px-3 py-1 bg-blue-600 hover:bg-blue-500 rounded text-sm transition-colors">View</button>
                        {invoice.status === 'pending_approval' && (
                          <button
                          onClick={() => {
                            const subject = encodeURIComponent("Invoice for Approval: " + invoice.id + " - " + invoice.vendor);
                            const body = encodeURIComponent(
                              "Hi Finance Team,\n\nPlease review and approve the following invoice:\n\n" +
                              "Invoice #: " + invoice.id + "\n" +
                              "Vendor: " + invoice.vendor + "\n" +
                              "Amount: $" + invoice.amount.toLocaleString() + "\n" +
                              "Due Date: " + invoice.dueDate + "\n" +
                              "Category: " + invoice.category + "\n\n" +
                              "Submitted by: " + invoice.submittedBy + "\n\nThank you"
                            );
                            window.open("mailto:finance@accessguard.io?subject=" + subject + "&body=" + body);
                          }}
                          className="px-3 py-1 bg-emerald-600 hover:bg-emerald-500 rounded text-sm transition-colors">Send to Finance</button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        {/* Invoice Detail Modal */}
        {showInvoiceDetail && selectedInvoice && (
          <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-6">
            <div className="bg-slate-900 rounded-3xl border border-white/10 p-8 max-w-lg w-full">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-2xl font-bold">Invoice {selectedInvoice.id}</h3>
                <button onClick={() => setShowInvoiceDetail(false)} className="text-slate-400 hover:text-white text-2xl leading-none">&times;</button>
              </div>
              <div className="space-y-3 mb-6">
                {[
                  ["Vendor", selectedInvoice.vendor],
                  ["Category", selectedInvoice.category],
                  ["Amount", "$" + selectedInvoice.amount.toLocaleString()],
                  ["Due Date", selectedInvoice.dueDate],
                  ["Submitted By", selectedInvoice.submittedBy],
                  ["Status", selectedInvoice.status.replace("_", " ")],
                ].map(([label, value]) => (
                  <div key={label} className="flex justify-between py-2 border-b border-slate-800">
                    <span className="text-slate-400 text-sm">{label}</span>
                    <span className="text-white font-medium text-sm">{value}</span>
                  </div>
                ))}
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowInvoiceDetail(false)} className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold">
                  Close
                </button>
                {selectedInvoice.status === "pending_approval" && (
                  <button
                    onClick={() => {
                      const subject = encodeURIComponent("Invoice for Approval: " + selectedInvoice.id + " - " + selectedInvoice.vendor);
                      const body = encodeURIComponent("Hi Finance Team,\n\nPlease approve invoice " + selectedInvoice.id + " for " + selectedInvoice.vendor + " - $" + selectedInvoice.amount.toLocaleString() + "\n\nDue: " + selectedInvoice.dueDate + "\n\nThank you");
                      window.open("mailto:finance@accessguard.io?subject=" + subject + "&body=" + body);
                    }}
                    className="flex-1 px-4 py-3 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors">
                    📧 Send to Finance
                  </button>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Upload Modal */}
        {showUploadModal && (
          <Modal open={showUploadModal} onClose={() => setShowUploadModal(false)} title="Upload Invoice" subtitle="Submit vendor invoice for finance approval">
            <form 
              className="space-y-4"
              onSubmit={handleUploadSubmit}
            >
              <div>
                <label className="block text-sm font-semibold text-slate-300 mb-2">Vendor Name</label>
                <input type="text" required value={uploadForm.vendor} onChange={e => setUploadForm(f => ({...f, vendor: e.target.value}))} className="w-full px-4 py-3 bg-slate-900 border border-slate-700 rounded-xl text-white" placeholder="e.g. Salesforce" />
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-300 mb-2">Invoice Amount</label>
                <input type="number" required value={uploadForm.amount} onChange={e => setUploadForm(f => ({...f, amount: e.target.value}))} className="w-full px-4 py-3 bg-slate-900 border border-slate-700 rounded-xl text-white" placeholder="0.00" />
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-300 mb-2">Due Date</label>
                <input type="date" required value={uploadForm.dueDate} onChange={e => setUploadForm(f => ({...f, dueDate: e.target.value}))} className="w-full px-4 py-3 bg-slate-900 border border-slate-700 rounded-xl text-white" />
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-300 mb-2">Category</label>
                <Select required>
                  <option>CRM</option>
                  <option>Communication</option>
                  <option>Development</option>
                  <option>Design</option>
                  <option>Analytics</option>
                </Select>
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-300 mb-2">Upload Invoice PDF</label>
                <input type="file" accept=".pdf" className="hidden" id="invoice-upload" onChange={e => setUploadFileName(e.target.files[0]?.name || '')} />
                <label htmlFor="invoice-upload" className="block border-2 border-dashed border-slate-700 rounded-xl p-8 text-center hover:border-blue-500 transition-colors cursor-pointer">
                  <Upload className="w-12 h-12 text-slate-500 mx-auto mb-3" />
                  {uploadFileName ? <p className="text-emerald-400 font-semibold">{uploadFileName}</p> : <p className="text-slate-400">Click to upload or drag and drop</p>}
                  <p className="text-xs text-slate-500 mt-2">PDF up to 10MB</p>
                </label>
              </div>
              <div className="flex gap-3 pt-4">
                <button type="button" onClick={() => setShowUploadModal(false)} className="flex-1 px-6 py-3 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold transition-colors">{t('cancel')}</button>
                <button type="submit" className={`flex-1 px-6 py-3 rounded-xl font-semibold transition-colors ${uploadSuccess ? 'bg-emerald-600' : 'bg-blue-600 hover:bg-blue-500'}`}>{uploadSuccess ? '✅ Uploaded!' : 'Upload & Submit'}</button>
              </div>
            </form>
          </Modal>
        )}
      </div>
        </div>
  );
}

function ContractsTabContent() {
  return <ContractComparisonPage />;
}


function FinishSignUpPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const navigate = useNavigate();
  const [status, setStatus] = useState('processing');
  const [error, setError] = useState('');
  
  useEffect(() => {
    const completeSignIn = async () => {
      const { user, error } = await completeMagicLinkSignIn(window.location.href);
      
      if (user) {
        setStatus('success');
        // Check if user completed onboarding
        const { user: userData } = await getUserProfile(user.uid);
        setTimeout(() => {
          if (userData && userData.onboardingCompleted) {
            navigate('/dashboard', { replace: true });
          } else {
            navigate('/onboarding', { replace: true });
          }
        }, 2000);
      } else {
        setStatus('error');
        setError(error || 'Sign-in failed');
        console.error('Email link sign-in error:', error);
      }
    };
    
    completeSignIn();
  }, [navigate]);
  
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center text-white">
      <div className="text-center p-8">
        {status === 'processing' && (
          <>
            <div className="text-8xl mb-6 animate-pulse">⏳</div>
            <h1 className="text-4xl font-bold mb-4">Signing you in...</h1>
            <p className="text-slate-400 text-lg">Please wait a moment</p>
          </>
        )}
        {status === 'success' && (
          <>
            <div className="text-8xl mb-6 animate-bounce">✅</div>
            <h1 className="text-4xl font-bold mb-4">Success!</h1>
            <p className="text-slate-400 text-lg">Welcome to SaasGuard</p>
            <p className="text-slate-500 mt-2">Redirecting to dashboard...</p>
          </>
        )}
        {status === 'error' && (
          <>
            <div className="text-8xl mb-6">❌</div>
            <h1 className="text-4xl font-bold mb-4">Sign-in Failed</h1>
            <p className="text-slate-400 text-lg mb-6">
              {error === 'Invalid sign-in link' 
                ? 'This link has expired or is invalid.' 
                : 'Something went wrong with your sign-in.'}
            </p>
            <button 
              onClick={() => window.location.href = "/dashboard"}
              className="px-8 py-4 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-lg transition-colors"
            >
              Return to Homepage
            </button>
          </>
        )}
      </div>
    </div>
  );
}


// ============================================================================
// CONTRACT COMPARISON PAGE
// ============================================================================

// ============================================================================
// CONTRACT COMPARISON + NEGOTIATION PAGE  (AI-powered)
// ============================================================================
function ContractComparisonPage() {
  const { language } = useLang();
  const t = useTranslation(language);

  // ── tabs ──────────────────────────────────────────────────
  const [tab, setTab] = useState('negotiations'); // negotiations | compare | ai

  // ── negotiations state ────────────────────────────────────
  const [negotiations, setNegotiations] = useState(() => {
    try { return JSON.parse(localStorage.getItem('ag_negotiations') || '[]'); }
    catch { return []; }
  });
  const saveNegotiations = (list) => {
    localStorage.setItem('ag_negotiations', JSON.stringify(list));
    setNegotiations(list);
  };
  const [showAddNeg, setShowAddNeg] = useState(false);
  const [negForm, setNegForm] = useState({
    id: null, customer: '', assignee: '', salesPerson: '',
    createDate: todayISO(), deadline: '', arr: '', status: 'In Progress',
    currentWith: 'With Our Legal Team', notes: '',
  });
  const resetNegForm = () => setNegForm({
    id: null, customer: '', assignee: '', salesPerson: '',
    createDate: todayISO(), deadline: '', arr: '', status: 'In Progress',
    currentWith: 'With Our Legal Team', notes: '',
  });
  const saveNeg = () => {
    if (!negForm.customer.trim()) return;
    const list = negForm.id
      ? negotiations.map(n => n.id === negForm.id ? { ...negForm } : n)
      : [{ ...negForm, id: `neg_${Date.now()}` }, ...negotiations];
    saveNegotiations(list);
    setShowAddNeg(false);
    resetNegForm();
  };
  const deleteNeg = (id) => saveNegotiations(negotiations.filter(n => n.id !== id));
  const editNeg = (n) => { setNegForm({ ...n }); setShowAddNeg(true); };
  const revertNeg = (id) => {
    const n = negotiations.find(n => n.id === id);
    if (!n) return;
    saveNegotiations([{
      ...n, id: `neg_${Date.now()}`,
      status: 'Reverted', currentWith: 'Reverted to Vendor',
      notes: `Reverted on ${todayISO()}. ${n.notes || ''}`.trim(),
    }, ...negotiations]);
  };

  const STATUS_COLORS = {
    'In Progress':     'bg-blue-500/20 text-blue-400',
    'Waiting on Approval': 'bg-amber-500/20 text-amber-400',
    'Ready for Signing':   'bg-emerald-500/20 text-emerald-400',
    'Signed':          'bg-teal-500/20 text-teal-400',
    'Reverted':        'bg-purple-500/20 text-purple-400',
    'On Hold':         'bg-slate-500/20 text-slate-400',
    'Rejected':        'bg-rose-500/20 text-rose-400',
  };
  const PIPELINE_STAGES = [
    'With Our Legal Team', 'Waiting on Approval', 'Ready for Signing',
    'With Customer', 'Final Review', 'Reverted to Vendor',
  ];

  const daysLeft = (d) => d ? Math.ceil((new Date(d) - new Date()) / 86400000) : null;

  // ── comparison state ──────────────────────────────────────
  const [contracts, setContracts] = useState(() => {
    try { return JSON.parse(localStorage.getItem('ag_contracts') || '[]'); }
    catch { return []; }
  });
  const saveContracts = (list) => {
    localStorage.setItem('ag_contracts', JSON.stringify(list));
    setContracts(list);
  };
  const [compareIds, setCompareIds] = useState([]);
  const [showAddContract, setShowAddContract] = useState(false);
  const [cForm, setCForm] = useState({
    id: null, vendor: '', tool: '', version: 'current',
    startDate: '', endDate: '', value: '', terms: '', sla: '',
    autoRenew: false, notes: '', status: 'active',
  });
  const resetCForm = () => setCForm({
    id: null, vendor: '', tool: '', version: 'current',
    startDate: '', endDate: '', value: '', terms: '', sla: '',
    autoRenew: false, notes: '', status: 'active',
  });
  const saveContract = () => {
    if (!cForm.vendor.trim()) return;
    const list = cForm.id
      ? contracts.map(c => c.id === cForm.id ? { ...cForm } : c)
      : [{ ...cForm, id: `c_${Date.now()}` }, ...contracts];
    saveContracts(list);
    setShowAddContract(false);
    resetCForm();
  };
  const toggleCompare = (id) => setCompareIds(prev =>
    prev.includes(id) ? prev.filter(i => i !== id)
      : prev.length < 2 ? [...prev, id] : [prev[1], id]
  );
  const cmpContracts = compareIds.map(id => contracts.find(c => c.id === id)).filter(Boolean);
  const CFIELDS = [
    { key: 'vendor', label: 'Vendor' }, { key: 'tool', label: 'Tool' },
    { key: 'version', label: 'Version' }, { key: 'startDate', label: 'Start' },
    { key: 'endDate', label: 'End' }, { key: 'value', label: 'Value' },
    { key: 'sla', label: 'SLA' },
    { key: 'autoRenew', label: 'Auto-renew', render: v => v ? 'Yes' : 'No' },
    { key: 'terms', label: 'Terms' }, { key: 'status', label: 'Status' },
    { key: 'notes', label: 'Notes' },
  ];

  // ── AI comparison state ───────────────────────────────────
  const [doc1, setDoc1] = useState('');
  const [doc2, setDoc2] = useState('');
  const [doc1Name, setDoc1Name] = useState('');
  const [doc2Name, setDoc2Name] = useState('');
  const [aiResult, setAiResult] = useState(null);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState('');
  const [chatMessages, setChatMessages] = useState([]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);

  const readFile = (file, setName, setContent) => {
    setName(file.name);
    const reader = new FileReader();
    reader.onload = (e) => setContent(e.target.result);
    reader.readAsText(file);
  };

  const runAiComparison = async () => {
    if (!doc1.trim() || !doc2.trim()) return;
    setAiLoading(true); setAiError(''); setAiResult(null);
    try {
      const resp = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 1000,
          messages: [{
            role: 'user',
            content: `You are a legal contract analyst. Compare these two contracts and respond ONLY with a valid JSON object (no markdown, no explanation outside JSON) with this exact structure:
{
  "summary": "2-3 sentence overview of main differences",
  "differences": [
    { "field": "field name", "doc1": "value in doc1", "doc2": "value in doc2", "severity": "high|medium|low", "recommendation": "what to do" }
  ],
  "risks": ["risk 1", "risk 2"],
  "recommendations": ["rec 1", "rec 2"],
  "verdict": "which contract is better and why in one sentence"
}

CONTRACT 1 (${doc1Name || 'Document 1'}):
${doc1.slice(0, 3000)}

CONTRACT 2 (${doc2Name || 'Document 2'}):
${doc2.slice(0, 3000)}`
          }]
        })
      });
      const data = await resp.json();
      const text = data.content?.[0]?.text || '';
      const clean = text.replace(/```json|```/g, '').trim();
      const parsed = JSON.parse(clean);
      setAiResult(parsed);
      setChatMessages([{
        role: 'assistant',
        content: `I've compared both contracts. ${parsed.summary} Ask me anything about specific clauses, risks, or negotiation strategies.`
      }]);
    } catch (e) {
      setAiError('Could not analyse contracts. Check that both documents contain readable text.');
    } finally { setAiLoading(false); }
  };

  const sendChat = async () => {
    if (!chatInput.trim() || chatLoading) return;
    const userMsg = { role: 'user', content: chatInput };
    const newMessages = [...chatMessages, userMsg];
    setChatMessages(newMessages);
    setChatInput('');
    setChatLoading(true);
    try {
      const context = aiResult
        ? `Context: The user is comparing two contracts. Analysis: ${JSON.stringify(aiResult)}

Doc1 excerpt: ${doc1.slice(0, 1500)}
Doc2 excerpt: ${doc2.slice(0, 1500)}`
        : 'The user is asking about contract negotiation.';
      const resp = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 1000,
          system: `You are an expert contract negotiation advisor for SaaS companies. Be concise and actionable. ${context}`,
          messages: newMessages.map(m => ({ role: m.role, content: m.content }))
        })
      });
      const data = await resp.json();
      const reply = data.content?.[0]?.text || 'Sorry, I could not respond.';
      setChatMessages(prev => [...prev, { role: 'assistant', content: reply }]);
    } catch {
      setChatMessages(prev => [...prev, { role: 'assistant', content: 'Error reaching AI. Please try again.' }]);
    } finally { setChatLoading(false); }
  };

  const sevColor = (s) =>
    s === 'high' ? 'bg-rose-500/20 text-rose-400 border-rose-500/30' :
    s === 'medium' ? 'bg-amber-500/20 text-amber-400 border-amber-500/30' :
    'bg-slate-500/20 text-slate-400 border-slate-500/30';

  return (
    <AppShell
      title="Contracts"
      right={
        <div className="flex gap-2">
          {tab === 'negotiations' && (
            <Button onClick={() => { resetNegForm(); setShowAddNeg(true); }}>
              <Plus className="h-4 w-4" /> New negotiation
            </Button>
          )}
          {tab === 'compare' && (
            <Button variant="secondary" onClick={() => { resetCForm(); setShowAddContract(true); }}>
              <Plus className="h-4 w-4" /> Add contract
            </Button>
          )}
        </div>
      }
    >
      <div className="space-y-5">
        {/* Tab bar */}
        <div className="flex gap-1 rounded-xl border border-slate-800 bg-slate-900/60 p-1 w-fit">
          {[
            { id: 'negotiations', label: '📋 Negotiation Tracker' },
            { id: 'compare',      label: '⇄ Contract Comparison' },
            { id: 'ai',           label: '🤖 AI Analysis' },
          ].map(({ id, label }) => (
            <button key={id} onClick={() => setTab(id)}
              className={cx("px-4 py-2 rounded-lg text-sm font-medium transition-colors",
                tab === id ? "bg-blue-600 text-white shadow" : "text-slate-400 hover:text-slate-200"
              )}>
              {label}
            </button>
          ))}
        </div>

        {/* ══ TAB: NEGOTIATION TRACKER ══════════════════════════════ */}
        {tab === 'negotiations' && (
          <div className="space-y-5">
            {/* Stats row */}
            <div className="grid gap-4 md:grid-cols-4">
              {[
                { label: 'Total',           value: negotiations.length,                                        color: 'text-white' },
                { label: 'In Progress',     value: negotiations.filter(n => n.status === 'In Progress').length, color: 'text-blue-400' },
                { label: 'Ready to Sign',   value: negotiations.filter(n => n.status === 'Ready for Signing').length, color: 'text-emerald-400' },
                { label: 'Total ARR',       value: '$' + negotiations.reduce((s, n) => s + Number((n.arr || '0').replace(/[^0-9.]/g,'')), 0).toLocaleString(), color: 'text-amber-400' },
              ].map(({ label, value, color }) => (
                <Card key={label}><CardBody>
                  <div className="text-xs font-semibold uppercase tracking-widest text-slate-500">{label}</div>
                  <div className={cx("text-3xl font-black mt-1", color)}>{value}</div>
                </CardBody></Card>
              ))}
            </div>

            {/* Add / edit form */}
            {showAddNeg && (
              <Card className="border-blue-600/30">
                <CardHeader
                  title={negForm.id ? 'Edit negotiation' : 'New contract negotiation'}
                  subtitle="Fill in the deal details"
                  right={<Button variant="secondary" size="sm" onClick={() => { setShowAddNeg(false); resetNegForm(); }}>✕</Button>}
                />
                <CardBody>
                  <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {[
                      { key: 'customer',    label: 'Customer *',    type: 'text', ph: 'e.g. Acme Corp' },
                      { key: 'assignee',    label: 'Assignee',      type: 'text', ph: 'Assigned to' },
                      { key: 'salesPerson', label: 'Sales Person',  type: 'text', ph: 'Sales rep name' },
                      { key: 'arr',         label: 'ARR of Contract', type: 'text', ph: '$0.00' },
                      { key: 'createDate',  label: 'Create Date',   type: 'date' },
                      { key: 'deadline',    label: 'Deadline',      type: 'date' },
                    ].map(({ key, label, type, ph }) => (
                      <div key={key}>
                        <div className="mb-1 text-xs font-semibold text-slate-400">{label}</div>
                        <input type={type} value={negForm[key]}
                          onChange={e => setNegForm(f => ({ ...f, [key]: e.target.value }))}
                          placeholder={ph || ''}
                          className="w-full rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                    ))}
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Status</div>
                      <Select value={negForm.status} onChange={e => setNegForm(f => ({ ...f, status: e.target.value }))}>
                        {Object.keys(STATUS_COLORS).map(s => <option key={s} value={s}>{s}</option>)}
                      </Select>
                    </div>
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Currently With</div>
                      <Select value={negForm.currentWith} onChange={e => setNegForm(f => ({ ...f, currentWith: e.target.value }))}>
                        {PIPELINE_STAGES.map(s => <option key={s} value={s}>{s}</option>)}
                      </Select>
                    </div>
                    <div className="lg:col-span-3">
                      <div className="mb-1 text-xs font-semibold text-slate-400">Notes</div>
                      <Textarea rows={2} value={negForm.notes}
                        onChange={e => setNegForm(f => ({ ...f, notes: e.target.value }))}
                        placeholder="Key clauses, outstanding issues, history…" />
                    </div>
                  </div>
                  <div className="mt-4 flex justify-end gap-2">
                    <Button variant="secondary" onClick={() => { setShowAddNeg(false); resetNegForm(); }}>{t('cancel')}</Button>
                    <Button disabled={!negForm.customer.trim()} onClick={saveNeg}>
                      <Check className="h-4 w-4" /> {negForm.id ? 'Save changes' : 'Add negotiation'}
                    </Button>
                  </div>
                </CardBody>
              </Card>
            )}

            {/* Negotiation table */}
            {negotiations.length === 0 ? (
              <EmptyState icon={FileText} title="No negotiations yet"
                body="Track contract negotiations from first draft to signing." />
            ) : (
              <Card>
                <CardHeader title="Contract Negotiation Tracker" subtitle="Track every deal from draft to close" />
                <CardBody>
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-slate-800 bg-slate-950/60">
                          {['Customer','Assignee','Create Date','Deadline','ARR of Contract','Currently With','Sales Person','Status','Actions'].map(h => (
                            <th key={h} className="px-4 py-3 text-left text-slate-400 font-semibold whitespace-nowrap">{h}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {negotiations.map((n) => {
                          const days = daysLeft(n.deadline);
                          return (
                            <tr key={n.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                              <td className="px-4 py-3">
                                <div className="font-semibold text-blue-400 hover:text-blue-300 cursor-pointer" onClick={() => editNeg(n)}>{n.customer}</div>
                              </td>
                              <td className="px-4 py-3">
                                <div className="flex items-center gap-2">
                                  <div className="h-7 w-7 rounded-full bg-gradient-to-br from-blue-500 to-violet-600 flex items-center justify-center text-xs font-bold text-white flex-shrink-0">
                                    {(n.assignee || '?').charAt(0).toUpperCase()}
                                  </div>
                                  <span className="text-slate-300 text-xs">{n.assignee || '—'}</span>
                                </div>
                              </td>
                              <td className="px-4 py-3 text-slate-400 whitespace-nowrap text-xs">
                                {n.createDate ? `${n.createDate} | ${new Date(n.createDate).toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'})}` : '—'}
                              </td>
                              <td className="px-4 py-3 whitespace-nowrap">
                                <div className="text-slate-300 text-xs">{n.deadline ? new Date(n.deadline).toLocaleDateString('en-GB', { day:'2-digit', month:'short', year:'numeric'}) : '—'}</div>
                                {days !== null && (
                                  <div className={cx("text-xs font-semibold",
                                    days < 0 ? 'text-rose-400' : days <= 7 ? 'text-amber-400' : 'text-slate-500'
                                  )}>
                                    {days < 0 ? `${Math.abs(days)}d overdue` : days === 0 ? 'Today' : `${days}d left`}
                                  </div>
                                )}
                              </td>
                              <td className="px-4 py-3 font-semibold text-white">{n.arr || '—'}</td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-1 rounded-full text-xs font-semibold whitespace-nowrap",
                                  n.currentWith === 'Ready for Signing' ? 'bg-emerald-500/20 text-emerald-400' :
                                  n.currentWith === 'Waiting on Approval' ? 'bg-amber-500/20 text-amber-400' :
                                  n.currentWith === 'Reverted to Vendor' ? 'bg-purple-500/20 text-purple-400' :
                                  'bg-slate-500/20 text-slate-400'
                                )}>{n.currentWith}</span>
                              </td>
                              <td className="px-4 py-3 text-slate-300">{n.salesPerson || '—'}</td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-1 rounded-full text-xs font-semibold whitespace-nowrap", STATUS_COLORS[n.status] || 'bg-slate-500/20 text-slate-400')}>
                                  {n.status}
                                </span>
                              </td>
                              <td className="px-4 py-3">
                                <div className="flex items-center gap-1">
                                  <Button size="sm" variant="secondary" onClick={() => editNeg(n)}><Pencil className="h-3 w-3" /></Button>
                                  <Button size="sm" variant="secondary" onClick={() => revertNeg(n.id)} title="Revert to vendor"><RefreshCw className="h-3 w-3" /></Button>
                                  <Button size="sm" variant="danger" onClick={() => deleteNeg(n.id)}><Trash2 className="h-3 w-3" /></Button>
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </CardBody>
              </Card>
            )}

            {/* Legal pipeline view */}
            {negotiations.length > 0 && (
              <Card>
                <CardHeader title="Legal Pipeline" subtitle="Deals by stage" />
                <CardBody>
                  <div className="grid gap-3 md:grid-cols-3 lg:grid-cols-6">
                    {PIPELINE_STAGES.map(stage => {
                      const deals = negotiations.filter(n => n.currentWith === stage);
                      return (
                        <div key={stage} className="rounded-xl border border-slate-800 bg-slate-950/30 p-3">
                          <div className="text-xs font-semibold text-slate-400 mb-2 leading-tight">{stage}</div>
                          <div className="text-2xl font-black text-white">{deals.length}</div>
                          {deals.length > 0 && (
                            <div className="mt-2 space-y-1">
                              {deals.slice(0,3).map(d => (
                                <div key={d.id} className="text-xs text-blue-400 truncate">{d.customer}</div>
                              ))}
                              {deals.length > 3 && <div className="text-xs text-slate-600">+{deals.length-3} more</div>}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </CardBody>
              </Card>
            )}
          </div>
        )}

        {/* ══ TAB: SIDE-BY-SIDE COMPARE ════════════════════════════ */}
        {tab === 'compare' && (
          <div className="space-y-5">
            {showAddContract && (
              <Card className="border-blue-600/30">
                <CardHeader
                  title={cForm.id ? 'Edit contract' : 'Add contract'}
                  right={<Button variant="secondary" size="sm" onClick={() => { setShowAddContract(false); resetCForm(); }}>✕</Button>}
                />
                <CardBody>
                  <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {[
                      { key: 'vendor', label: 'Vendor *', type: 'text', ph: 'e.g. Salesforce' },
                      { key: 'tool',   label: 'Tool *',   type: 'text', ph: 'e.g. Sales Cloud' },
                      { key: 'value',  label: 'Value',    type: 'text', ph: '€12,000/year' },
                      { key: 'sla',    label: 'SLA',      type: 'text', ph: '99.9% uptime' },
                      { key: 'startDate', label: 'Start', type: 'date' },
                      { key: 'endDate',   label: 'End',   type: 'date' },
                    ].map(({ key, label, type, ph }) => (
                      <div key={key}>
                        <div className="mb-1 text-xs font-semibold text-slate-400">{label}</div>
                        <input type={type} value={cForm[key]}
                          onChange={e => setCForm(f => ({ ...f, [key]: e.target.value }))}
                          placeholder={ph || ''}
                          className="w-full rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                    ))}
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Version</div>
                      <Select value={cForm.version} onChange={e => setCForm(f => ({ ...f, version: e.target.value }))}>
                        {['current','new','proposed','old','reverted'].map(v => <option key={v} value={v}>{v}</option>)}
                      </Select>
                    </div>
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Status</div>
                      <Select value={cForm.status} onChange={e => setCForm(f => ({ ...f, status: e.target.value }))}>
                        {['active','draft','expired','negotiating','reverted'].map(v => <option key={v} value={v}>{v}</option>)}
                      </Select>
                    </div>
                    <div className="flex items-center gap-2 mt-4">
                      <input type="checkbox" id="ar" checked={cForm.autoRenew}
                        onChange={e => setCForm(f => ({ ...f, autoRenew: e.target.checked }))}
                        className="h-4 w-4 accent-blue-500" />
                      <label htmlFor="ar" className="text-sm text-slate-300">Auto-renews</label>
                    </div>
                    <div className="lg:col-span-3">
                      <div className="mb-1 text-xs font-semibold text-slate-400">Key terms</div>
                      <Textarea rows={2} value={cForm.terms}
                        onChange={e => setCForm(f => ({ ...f, terms: e.target.value }))}
                        placeholder="Key clauses, pricing, conditions…" />
                    </div>
                    <div className="lg:col-span-3">
                      <div className="mb-1 text-xs font-semibold text-slate-400">Notes</div>
                      <Textarea rows={2} value={cForm.notes}
                        onChange={e => setCForm(f => ({ ...f, notes: e.target.value }))}
                        placeholder="Internal notes…" />
                    </div>
                  </div>
                  <div className="mt-4 flex justify-end gap-2">
                    <Button variant="secondary" onClick={() => { setShowAddContract(false); resetCForm(); }}>{t('cancel')}</Button>
                    <Button disabled={!cForm.vendor.trim()} onClick={saveContract}>
                      <Check className="h-4 w-4" /> {cForm.id ? 'Save' : 'Add'}
                    </Button>
                  </div>
                </CardBody>
              </Card>
            )}

            {contracts.length === 0 ? (
              <EmptyState icon={FileText} title="No contracts" body="Add contracts to compare them side-by-side." />
            ) : (
              <Card>
                <CardHeader
                  title="Select contracts to compare"
                  subtitle="Check 2 contracts then click Compare"
                  right={compareIds.length === 2 && (
                    <Button size="sm" onClick={() => alert("This feature is coming in the next release!")}>
                      <ArrowLeftRight className="h-4 w-4" /> Compare selected
                    </Button>
                  )}
                />
                <CardBody>
                  <div className="overflow-x-auto rounded-xl border border-slate-800 mb-5">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-slate-800 bg-slate-950/60">
                          <th className="px-3 py-3 w-8"></th>
                          {['Vendor','Tool','Version','Value','Expires','Status',''].map(h => (
                            <th key={h} className="px-4 py-3 text-left text-slate-400 font-semibold">{h}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {contracts.map(c => {
                          const sel = compareIds.includes(c.id);
                          const days = c.endDate ? Math.ceil((new Date(c.endDate) - new Date()) / 86400000) : null;
                          return (
                            <tr key={c.id} className={cx("border-b border-slate-800/50 transition-colors", sel ? "bg-blue-600/10" : "hover:bg-slate-800/30")}>
                              <td className="px-3 py-3 text-center">
                                <input type="checkbox" checked={sel} onChange={() => toggleCompare(c.id)} className="h-4 w-4 accent-blue-500" />
                              </td>
                              <td className="px-4 py-3 font-semibold text-white">{c.vendor}</td>
                              <td className="px-4 py-3 text-slate-300">{c.tool}</td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold",
                                  c.version==='current'?'bg-blue-500/20 text-blue-400':
                                  c.version==='new'?'bg-emerald-500/20 text-emerald-400':'bg-slate-500/20 text-slate-400'
                                )}>{c.version}</span>
                              </td>
                              <td className="px-4 py-3 text-slate-300">{c.value||'—'}</td>
                              <td className="px-4 py-3">
                                <div className="text-slate-300 text-xs">{c.endDate||'—'}</div>
                                {days!==null && <div className={cx("text-xs font-semibold", days<0?'text-rose-400':days<=30?'text-amber-400':'text-slate-600')}>{days<0?`${Math.abs(days)}d over`:`${days}d`}</div>}
                              </td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold",
                                  c.status==='active'?'bg-emerald-500/20 text-emerald-400':'bg-slate-500/20 text-slate-400'
                                )}>{c.status}</span>
                              </td>
                              <td className="px-4 py-3">
                                <div className="flex gap-1">
                                  <Button size="sm" variant="secondary" onClick={() => { setCForm({...c}); setShowAddContract(true); }}><Pencil className="h-3 w-3" /></Button>
                                  <Button size="sm" variant="danger" onClick={() => { saveContracts(contracts.filter(x=>x.id!==c.id)); setCompareIds(p=>p.filter(i=>i!==c.id)); }}><Trash2 className="h-3 w-3" /></Button>
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>

                  {/* Side-by-side diff */}
                  {cmpContracts.length === 2 && (
                    <div className="space-y-4">
                      <div className="grid grid-cols-3 gap-4">
                        <div className="text-xs font-semibold text-slate-500 uppercase pt-3">Field</div>
                        {cmpContracts.map((c,i) => (
                          <div key={c.id} className={cx("rounded-xl border p-4", i===0?'border-blue-600/40':'border-emerald-600/40')}>
                            <div className="flex items-center gap-2">
                              <span className={cx("h-3 w-3 rounded-full", i===0?'bg-blue-500':'bg-emerald-500')} />
                              <span className="font-bold text-white">{c.vendor}</span>
                            </div>
                            <div className="text-xs text-slate-400 mt-1">{c.tool} · {c.version}</div>
                          </div>
                        ))}
                      </div>
                      {CFIELDS.map(({ key, label, render }) => {
                        const vals = cmpContracts.map(c => render ? render(c[key]) : String(c[key]||''));
                        const diff = vals[0] !== vals[1];
                        return (
                          <div key={key} className={cx("grid grid-cols-3 gap-4 px-3 py-3 rounded-xl",
                            diff ? 'bg-amber-500/10 border border-amber-500/20' : 'hover:bg-slate-800/20'
                          )}>
                            <div className="flex items-center gap-2 text-sm font-semibold text-slate-400">
                              {diff && <span className="h-2 w-2 rounded-full bg-amber-400 flex-shrink-0" />}
                              {label}
                            </div>
                            {vals.map((v,i) => (
                              <div key={i} className={cx("text-sm break-words", diff?(i===0?'text-blue-300':'text-emerald-300'):'text-slate-300')}>
                                {v || <span className="text-slate-600 italic">—</span>}
                              </div>
                            ))}
                          </div>
                        );
                      })}
                      {/* Differences badge */}
                      {(() => {
                        const diffs = CFIELDS.filter(({ key, render }) => {
                          const vs = cmpContracts.map(c => render?render(c[key]):String(c[key]||''));
                          return vs[0]!==vs[1];
                        });
                        return (
                          <div className={cx("rounded-xl border p-4", diffs.length?'border-amber-500/30':'border-emerald-500/30')}>
                            <div className="font-semibold text-white mb-2">{diffs.length} difference{diffs.length!==1?'s':''} found</div>
                            {diffs.length > 0 ? (
                              <div className="flex flex-wrap gap-2">
                                {diffs.map(({label}) => (
                                  <span key={label} className="px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/20 text-amber-400">{label}</span>
                                ))}
                              </div>
                            ) : (
                              <div className="text-emerald-400 text-sm">Both contracts are identical.</div>
                            )}
                            <div className="mt-4 flex gap-2">
                              {cmpContracts.map(c => (
                                <Button key={c.id} size="sm" variant="secondary" onClick={() => {
                                  saveContracts([{...c, id:`c_${Date.now()}`, version:'reverted', status:'reverted', notes:`Reverted on ${todayISO()}`}, ...contracts]);
                                }}>
                                  <RefreshCw className="h-3 w-3" /> Revert to "{c.vendor} {c.version}"
                                </Button>
                              ))}
                            </div>
                          </div>
                        );
                      })()}
                    </div>
                  )}
                </CardBody>
              </Card>
            )}
          </div>
        )}

        {/* ══ TAB: AI ANALYSIS ══════════════════════════════════════ */}
        {tab === 'ai' && (
          <div className="space-y-5">
            {/* Upload row */}
            <div className="grid gap-5 md:grid-cols-2">
              {[
                { label: 'Contract 1', name: doc1Name, setName: setDoc1Name, setContent: setDoc1, content: doc1 },
                { label: 'Contract 2', name: doc2Name, setName: setDoc2Name, setContent: setDoc2, content: doc2 },
              ].map(({ label, name, setName, setContent, content }, idx) => (
                <Card key={label} className={content ? 'border-blue-600/30' : ''}>
                  <CardBody>
                    <div className="text-sm font-semibold text-slate-400 mb-3">{label}</div>
                    {name ? (
                      <div className="flex items-center gap-3 p-3 rounded-xl border border-slate-700 bg-slate-900/40">
                        <FileText className="h-8 w-8 text-blue-400 flex-shrink-0" />
                        <div className="min-w-0">
                          <div className="font-medium text-white text-sm truncate">{name}</div>
                          <div className="text-xs text-slate-500">{content.length.toLocaleString()} characters</div>
                        </div>
                        <Button size="sm" variant="secondary" onClick={() => { setName(''); setContent(''); }}>
                          <X className="h-3 w-3" />
                        </Button>
                      </div>
                    ) : (
                      <label className="flex flex-col items-center justify-center h-32 rounded-xl border-2 border-dashed border-slate-700 hover:border-blue-500 transition-colors cursor-pointer bg-slate-900/20 hover:bg-slate-800/20">
                        <Upload className="h-8 w-8 text-slate-500 mb-2" />
                        <span className="text-sm text-slate-400">Upload .txt or .md file</span>
                        <span className="text-xs text-slate-600 mt-1">or paste text below</span>
                        <input type="file" className="hidden" accept=".txt,.md,.csv"
                          onChange={e => e.target.files?.[0] && readFile(e.target.files[0], setName, setContent)} />
                      </label>
                    )}
                    <div className="mt-3">
                      <Textarea rows={4} value={content}
                        onChange={e => { setContent(e.target.value); if(!name) setName('Pasted text'); }}
                        placeholder={`Paste ${label.toLowerCase()} text here…`}
                        className="font-mono text-xs" />
                    </div>
                  </CardBody>
                </Card>
              ))}
            </div>

            {/* Generate button */}
            <div className="flex justify-center">
              <Button
                disabled={!doc1.trim() || !doc2.trim() || aiLoading}
                onClick={runAiComparison}
                className="px-8"
              >
                {aiLoading
                  ? <><RefreshCw className="h-4 w-4 animate-spin" /> Analysing contracts…</>
                  : <><Sparkles className="h-4 w-4" /> Generate AI Comparison</>
                }
              </Button>
            </div>

            {aiError && (
              <div className="rounded-xl border border-rose-500/30 bg-rose-500/10 p-4 text-rose-400 text-sm">{aiError}</div>
            )}

            {/* AI Results */}
            {aiResult && (
              <div className="space-y-5">
                {/* Verdict */}
                <Card className="border-blue-600/30">
                  <CardBody>
                    <div className="flex items-start gap-3">
                      <Sparkles className="h-6 w-6 text-blue-400 flex-shrink-0 mt-0.5" />
                      <div>
                        <div className="text-xs font-semibold uppercase tracking-widest text-blue-400 mb-1">AI Verdict</div>
                        <div className="text-white font-semibold">{aiResult.verdict}</div>
                        <div className="text-slate-400 text-sm mt-1">{aiResult.summary}</div>
                      </div>
                    </div>
                  </CardBody>
                </Card>

                <div className="grid gap-5 lg:grid-cols-2">
                  {/* Differences */}
                  <Card>
                    <CardHeader title={`${aiResult.differences?.length || 0} Differences Found`} subtitle="Field-by-field comparison" />
                    <CardBody>
                      <div className="space-y-3">
                        {(aiResult.differences || []).map((d, i) => (
                          <div key={i} className={cx("rounded-xl border p-3", sevColor(d.severity))}>
                            <div className="flex items-center justify-between mb-2">
                              <span className="font-semibold text-sm text-white">{d.field}</span>
                              <span className={cx("px-2 py-0.5 rounded-full text-xs font-bold border", sevColor(d.severity))}>
                                {d.severity}
                              </span>
                            </div>
                            <div className="grid grid-cols-2 gap-3 text-xs mb-2">
                              <div>
                                <div className="text-blue-400 font-semibold mb-1">{doc1Name || 'Doc 1'}</div>
                                <div className="text-slate-300">{d.doc1 || '—'}</div>
                              </div>
                              <div>
                                <div className="text-emerald-400 font-semibold mb-1">{doc2Name || 'Doc 2'}</div>
                                <div className="text-slate-300">{d.doc2 || '—'}</div>
                              </div>
                            </div>
                            {d.recommendation && (
                              <div className="text-xs text-slate-400 border-t border-slate-700 pt-2 mt-1">
                                💡 {d.recommendation}
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    </CardBody>
                  </Card>

                  {/* Risks + Recommendations */}
                  <div className="space-y-5">
                    <Card>
                      <CardHeader title="Risks Identified" />
                      <CardBody>
                        <div className="space-y-2">
                          {(aiResult.risks || []).map((r, i) => (
                            <div key={i} className="flex items-start gap-2 text-sm">
                              <AlertTriangle className="h-4 w-4 text-amber-400 flex-shrink-0 mt-0.5" />
                              <span className="text-slate-300">{r}</span>
                            </div>
                          ))}
                        </div>
                      </CardBody>
                    </Card>
                    <Card>
                      <CardHeader title="Recommendations" />
                      <CardBody>
                        <div className="space-y-2">
                          {(aiResult.recommendations || []).map((r, i) => (
                            <div key={i} className="flex items-start gap-2 text-sm">
                              <CheckCircle className="h-4 w-4 text-emerald-400 flex-shrink-0 mt-0.5" />
                              <span className="text-slate-300">{r}</span>
                            </div>
                          ))}
                        </div>
                      </CardBody>
                    </Card>
                  </div>
                </div>

                {/* AI Chat */}
                <Card>
                  <CardHeader
                    title="Ask the AI"
                    subtitle="Ask follow-up questions about the contracts"
                    right={<Pill tone="blue" icon={Bot}>AI Advisor</Pill>}
                  />
                  <CardBody>
                    <div className="space-y-3 max-h-80 overflow-y-auto mb-4 pr-1">
                      {chatMessages.map((m, i) => (
                        <div key={i} className={cx("flex gap-3", m.role === 'user' ? "flex-row-reverse" : "")}>
                          <div className={cx("h-7 w-7 rounded-full flex-shrink-0 flex items-center justify-center text-xs font-bold",
                            m.role === 'user' ? "bg-blue-600 text-white" : "bg-slate-700 text-slate-300"
                          )}>
                            {m.role === 'user' ? 'U' : <Sparkles className="h-4 w-4" />}
                          </div>
                          <div className={cx("rounded-2xl px-4 py-3 text-sm max-w-[80%]",
                            m.role === 'user' ? "bg-blue-600/20 text-white" : "bg-slate-800 text-slate-200"
                          )}>
                            {m.content}
                          </div>
                        </div>
                      ))}
                      {chatLoading && (
                        <div className="flex gap-3">
                          <div className="h-7 w-7 rounded-full bg-slate-700 flex items-center justify-center">
                            <Sparkles className="h-4 w-4 text-slate-300" />
                          </div>
                          <div className="rounded-2xl px-4 py-3 bg-slate-800 text-slate-400 text-sm">
                            <RefreshCw className="h-4 w-4 animate-spin inline" />
                          </div>
                        </div>
                      )}
                    </div>
                    <div className="flex gap-2">
                      <input
                        value={chatInput}
                        onChange={e => setChatInput(e.target.value)}
                        onKeyDown={e => e.key === 'Enter' && !e.shiftKey && sendChat()}
                        placeholder="Ask about specific clauses, risks, negotiation tactics…"
                        className="flex-1 rounded-xl border border-slate-700 bg-slate-900 px-4 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <Button disabled={!chatInput.trim() || chatLoading} onClick={sendChat}>
                        <MessageCircle className="h-4 w-4" />
                      </Button>
                    </div>
                    <div className="mt-2 flex flex-wrap gap-2">
                      {[
                        'Which contract has better SLA terms?',
                        'What should I negotiate on?',
                        'What are the biggest risks?',
                        'Which is better value?',
                      ].map(q => (
                        <button key={q} onClick={() => { setChatInput(q); }}
                          className="text-xs px-3 py-1 rounded-full border border-slate-700 text-slate-400 hover:border-blue-500 hover:text-blue-400 transition-colors">
                          {q}
                        </button>
                      ))}
                    </div>
                  </CardBody>
                </Card>
              </div>
            )}
          </div>
        )}
      </div>
    </AppShell>
  );
}

// ─────────────────────────────────────────────────────────────
// FLOATING SUPPORT CHATBOT
// ─────────────────────────────────────────────────────────────
function FloatingChatbot() {
  const { language } = useLang();
  const t = useTranslation(language);
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [initialized, setInitialized] = useState(false);
  const bottomRef = React.useRef(null);

  React.useEffect(() => {
    if (open && !initialized) {
      setMessages([{ role: 'assistant', content: t('chatbot_welcome') }]);
      setInitialized(true);
    }
  }, [open, initialized, t]);

  React.useEffect(() => {
    if (bottomRef.current) bottomRef.current.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const send = async () => {
    if (!input.trim() || loading) return;
    const userMsg = { role: 'user', content: input };
    const newMessages = [...messages, userMsg];
    setMessages(newMessages);
    setInput('');
    setLoading(true);
    try {
      const resp = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 1000,
          system: `You are a helpful support assistant for SaasGuard, a SaaS management platform. Help users with questions about features, pricing (Free Trial 14 days no credit card, Growth $49/mo, Scale $99/mo, Professional $199/mo, Enterprise custom), and how to use the platform. Be concise and friendly. If you cannot help, suggest they email support@saasguard.io.`,
          messages: newMessages.map(m => ({ role: m.role, content: m.content }))
        })
      });
      const data = await resp.json();
      const reply = data.content?.[0]?.text || 'Sorry, I could not respond right now.';
      setMessages(prev => [...prev, { role: 'assistant', content: reply }]);
    } catch {
      setMessages(prev => [...prev, { role: 'assistant', content: 'Connection error. Please try again or email support@saasguard.io' }]);
    } finally { setLoading(false); }
  };

  const handleKey = (e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } };

  return (
    <div className="fixed bottom-6 right-6 z-50 flex flex-col items-end gap-3">
      {open && (
        <div className="w-80 h-[480px] bg-slate-900 border border-slate-700 rounded-2xl shadow-2xl flex flex-col overflow-hidden">
          <div className="flex items-center justify-between px-4 py-3 bg-gradient-to-r from-blue-600 to-blue-700 flex-shrink-0">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center text-sm">🤖</div>
              <div>
                <div className="text-white font-bold text-sm">{t('chatbot_title')}</div>
                <div className="text-blue-200 text-xs flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block" /> Online
                </div>
              </div>
            </div>
            <button onClick={() => setOpen(false)} className="text-white/70 hover:text-white transition-colors text-xl leading-none">&times;</button>
          </div>
          <div className="flex-1 overflow-y-auto p-4 space-y-3">
            {messages.map((m, i) => (
              <div key={i} className={"flex " + (m.role === 'user' ? 'justify-end' : 'justify-start')}>
                <div className={"max-w-[85%] px-3 py-2 rounded-2xl text-sm leading-relaxed " + (m.role === 'user' ? 'bg-blue-600 text-white rounded-br-sm' : 'bg-slate-800 text-slate-200 rounded-bl-sm')}>
                  {m.content}
                </div>
              </div>
            ))}
            {loading && (
              <div className="flex justify-start">
                <div className="bg-slate-800 px-3 py-2 rounded-2xl rounded-bl-sm">
                  <div className="flex gap-1 items-center h-4">
                    <span className="w-1.5 h-1.5 bg-slate-500 rounded-full animate-bounce" style={{animationDelay:'0ms'}} />
                    <span className="w-1.5 h-1.5 bg-slate-500 rounded-full animate-bounce" style={{animationDelay:'150ms'}} />
                    <span className="w-1.5 h-1.5 bg-slate-500 rounded-full animate-bounce" style={{animationDelay:'300ms'}} />
                  </div>
                </div>
              </div>
            )}
            <div ref={bottomRef} />
          </div>
          <div className="p-3 border-t border-slate-800 flex gap-2 flex-shrink-0">
            <input
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={handleKey}
              placeholder={t('chatbot_placeholder')}
              className="flex-1 bg-slate-800 border border-slate-700 rounded-xl px-3 py-2 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-blue-500"
            />
            <button onClick={send} disabled={!input.trim() || loading}
              className="px-3 py-2 bg-blue-600 hover:bg-blue-500 disabled:opacity-40 text-white rounded-xl transition-colors">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
              </svg>
            </button>
          </div>
        </div>
      )}
      <button onClick={() => setOpen(o => !o)}
        className="w-14 h-14 rounded-full bg-gradient-to-br from-blue-500 to-blue-700 hover:from-blue-400 hover:to-blue-600 shadow-lg shadow-blue-900/40 flex items-center justify-center transition-all hover:scale-105 active:scale-95">
        {open
          ? <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
          : <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" /></svg>
        }
      </button>
    </div>
  );
}


export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Toaster position="top-right" toastOptions={{ style: { background: "#1e293b", color: "#f1f5f9", border: "1px solid #334155" } }} />
        <LanguageProvider>
        <BrowserRouter>
          <Routes>
          <Route path="/" element={<TrialPage />} />
          <Route path="/privacy" element={<PrivacyPage />} />
          <Route path="/terms" element={<TermsPage />} />
          <Route path="/security-info" element={<SecurityPage />} />
          <Route path="/finishSignUp" element={<FinishSignUpPage />} />
          <Route path="/onboarding" element={<OnboardingPage />} />
          <Route
            path="/dashboard"
            element={
              <RequireAuth>
                <DashboardPage />
              </RequireAuth>
            }
          />
          <Route
            path="/executive"
            element={<RequireAuth><FinanceDashboard /></RequireAuth>}
          />
          <Route
            path="/tools"
            element={<RequireAuth><ToolsPage /></RequireAuth>}
          />
          <Route
            path="/employees"
            element={<RequireAuth><EmployeesPage /></RequireAuth>}
          />
          <Route
            path="/access"
            element={<RequireAuth><AccessPage /></RequireAuth>}
          />
          <Route
            path="/integrations"
            element={<RequireAuth><SetupConnectionsHub /></RequireAuth>}
          />
          <Route
            path="/import"
            element={<RequireAuth><SetupConnectionsHub /></RequireAuth>}
          />
          <Route
            path="/offboarding"
            element={<RequireAuth><OffboardingPage /></RequireAuth>}
          />
          <Route
            path="/audit"
            element={<RequireAuth><SecurityCompliancePage /></RequireAuth>}
          />
          <Route
            path="/billing"
            element={<RequireAuth><BillingPage /></RequireAuth>}
          />
          <Route
            path="/security"
            element={<RequireAuth><SecurityCompliancePage /></RequireAuth>}
          />
          <Route
            path="/cost"
            element={<RequireAuth><FinanceDashboard /></RequireAuth>}
          />
          <Route path="/analytics" element={<Navigate to="/finance" replace />} />
          <Route
            path="/settings"
            element={<RequireAuth><SettingsPage /></RequireAuth>}
          />
          <Route
            path="/finance"
            element={<RequireAuth><FinanceDashboard /></RequireAuth>}
          />
          <Route
            path="/licenses"
            element={<RequireAuth><LicenseManagement /></RequireAuth>}
          />
          <Route
            path="/renewals"
            element={<RequireAuth><ContractsRenewalsHub /></RequireAuth>}
          />
          <Route
            path="/invoices"
            element={<RequireAuth><ContractsRenewalsHub /></RequireAuth>}
          />
          <Route
            path="/contracts"
            element={<RequireAuth><ContractsRenewalsHub /></RequireAuth>}
          />
          <Route path="*" element={<NotFound />} />
        </Routes>
        <FloatingChatbot />
        </BrowserRouter>
        </LanguageProvider>
    </QueryClientProvider>
  );
}