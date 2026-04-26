export const theme = {
  colors: {
    bg: '#080910',
    bgElevated: '#0E1018',
    text: '#FFFFFF',
    textSoft: 'rgba(255,255,255,0.72)',
    textMuted: 'rgba(255,255,255,0.50)',
    textFaint: 'rgba(255,255,255,0.34)',
    surface: 'rgba(255,255,255,0.045)',
    surfaceStrong: 'rgba(255,255,255,0.075)',
    surfaceBorder: 'rgba(255,255,255,0.10)',
    surfaceBorderStrong: 'rgba(255,255,255,0.16)',
    indigo: '#6366F1',
    orange: '#F97316',
    emerald: '#10B981',
    danger: '#EF4444',
    warning: '#F59E0B',
    black: '#080910',
  },
  radius: {
    sm: 12,
    md: 18,
    lg: 24,
    xl: 30,
    pill: 9999,
  },
  spacing: {
    xs: 6,
    sm: 10,
    md: 14,
    lg: 18,
    xl: 24,
    xxl: 32,
  },
  shadow: {
    card: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 14 },
      shadowOpacity: 0.38,
      shadowRadius: 24,
      elevation: 8,
    },
    floating: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 18 },
      shadowOpacity: 0.45,
      shadowRadius: 28,
      elevation: 12,
    },
  },
} as const;

export const typeColors = {
  SIGN_SLIP: theme.colors.orange,
  RSVP: theme.colors.indigo,
  TASK: theme.colors.emerald,
} as const;

export type CardTone = keyof typeof typeColors;
