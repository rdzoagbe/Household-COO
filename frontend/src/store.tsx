import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { api, User, tokenStore } from './api';

export type Lang = 'en' | 'es';

const TRANSLATIONS: Record<Lang, Record<string, string>> = {
  en: {
    app_name: 'Household COO',
    tagline: 'Your family\'s Chief of Staff',
    subtitle: 'AI that carries the mental load.',
    sign_in: 'Continue with Google',
    sign_in_secure: 'Secure sign-in · Used by calm households',
    feed: 'Feed',
    calendar: 'Calendar',
    vault: 'Vault',
    settings: 'Settings',
    this_week: 'This week',
    open_items: 'open items',
    open_item: 'open item',
    sunday_brief: 'Sunday Brief',
    sunday_brief_subtitle: 'Your week, distilled.',
    generate_brief: 'Generate Brief',
    generating: 'The COO is thinking...',
    close: 'Close',
    add_card: 'Add to feed',
    camera: 'Scan flyer',
    voice: 'Voice capture',
    manual: 'Manual entry',
    title: 'Title',
    description: 'Description',
    type: 'Type',
    assignee: 'Assignee',
    save: 'Save',
    cancel: 'Cancel',
    mark_done: 'Mark done',
    done: 'Done',
    sign_slip: 'Sign Slip',
    rsvp: 'RSVP',
    task: 'Task',
    no_items: 'Nothing on your plate. Breathe.',
    no_events: 'No events scheduled.',
    no_docs: 'Vault is empty.',
    upcoming: 'Upcoming',
    completed: 'Completed',
    language: 'Language',
    log_out: 'Sign out',
    family: 'Family',
    loading: 'Loading...',
    greeting_morning: 'Good morning,',
    greeting_afternoon: 'Good afternoon,',
    greeting_evening: 'Good evening,',
    on_your_desk: 'On your desk',
    signed_in_as: 'Signed in as',
    due: 'Due',
    no_due: 'No deadline',
    source_ai: 'Captured by AI',
    source_manual: 'Added manually',
    source_voice: 'From voice',
    source_camera: 'From flyer',
    choose_type: 'Choose a type',
    add_document: 'Add document',
    doc_category: 'Category',
    document: 'Document',
    medical: 'Medical',
    school: 'School',
    insurance: 'Insurance',
    legal: 'Legal',
    recurrence: 'Repeat',
    reminder: 'Reminder',
    rec_none: 'Once',
    rec_daily: 'Daily',
    rec_weekly: 'Weekly',
    rec_monthly: 'Monthly',
    rem_none: 'None',
    rem_15: '15m before',
    rem_60: '1h before',
    rem_1440: '1d before',
    reminders: 'Reminders today',
    reminder_for: 'Reminder for',
    record: 'Record',
    stop: 'Stop',
    voice_capture: 'Voice capture',
    voice_hint: 'Tap to record a quick note. AI will classify it.',
    listening: 'Listening...',
    transcribing: 'Transcribing with Whisper...',
    use_draft: 'Use this',
    retry: 'Try again',
    transcript: 'Transcript',
    not_supported_web: 'Voice capture requires a modern browser.',
    kids: 'Kids',
    stars: 'stars',
    redeem: 'Redeem',
    rewards: 'Rewards',
    add_reward: 'Add reward',
    reward_cost: 'Cost (stars)',
    not_enough_stars: 'Not enough stars',
    redeemed: 'Redeemed!',
    no_rewards: 'No rewards yet. Add one to get started.',
    earn_stars: 'Complete tasks to earn stars',
    parent_picks: 'Parent picks',
    conflict_found: 'Heads up: conflict with',
    scanning: 'Reading the flyer...',
    scan_flyer: 'Scan flyer',
    choose_photo: 'Choose photo',
  },
  es: {
    app_name: 'Household COO',
    tagline: 'El Jefe de Gabinete de tu familia',
    subtitle: 'IA que carga con la carga mental.',
    sign_in: 'Continuar con Google',
    sign_in_secure: 'Inicio seguro · Para hogares tranquilos',
    feed: 'Feed',
    calendar: 'Calendario',
    vault: 'Bóveda',
    settings: 'Ajustes',
    this_week: 'Esta semana',
    open_items: 'pendientes',
    open_item: 'pendiente',
    sunday_brief: 'Informe Dominical',
    sunday_brief_subtitle: 'Tu semana, destilada.',
    generate_brief: 'Generar Informe',
    generating: 'El COO está pensando...',
    close: 'Cerrar',
    add_card: 'Añadir al feed',
    camera: 'Escanear folleto',
    voice: 'Captura de voz',
    manual: 'Entrada manual',
    title: 'Título',
    description: 'Descripción',
    type: 'Tipo',
    assignee: 'Asignado a',
    save: 'Guardar',
    cancel: 'Cancelar',
    mark_done: 'Marcar hecho',
    done: 'Hecho',
    sign_slip: 'Permiso',
    rsvp: 'RSVP',
    task: 'Tarea',
    no_items: 'Nada en tu mesa. Respira.',
    no_events: 'Sin eventos programados.',
    no_docs: 'La bóveda está vacía.',
    upcoming: 'Próximos',
    completed: 'Completados',
    language: 'Idioma',
    log_out: 'Cerrar sesión',
    family: 'Familia',
    loading: 'Cargando...',
    greeting_morning: 'Buenos días,',
    greeting_afternoon: 'Buenas tardes,',
    greeting_evening: 'Buenas noches,',
    on_your_desk: 'En tu escritorio',
    signed_in_as: 'Sesión de',
    due: 'Vence',
    no_due: 'Sin fecha',
    source_ai: 'Capturado por IA',
    source_manual: 'Añadido manualmente',
    source_voice: 'Por voz',
    source_camera: 'De folleto',
    choose_type: 'Elige un tipo',
    add_document: 'Añadir documento',
    doc_category: 'Categoría',
    document: 'Documento',
    medical: 'Médico',
    school: 'Escolar',
    insurance: 'Seguro',
    legal: 'Legal',
    recurrence: 'Repetir',
    reminder: 'Recordatorio',
    rec_none: 'Una vez',
    rec_daily: 'Diario',
    rec_weekly: 'Semanal',
    rec_monthly: 'Mensual',
    rem_none: 'Ninguno',
    rem_15: '15m antes',
    rem_60: '1h antes',
    rem_1440: '1d antes',
    reminders: 'Recordatorios hoy',
    reminder_for: 'Recordatorio para',
    record: 'Grabar',
    stop: 'Detener',
    voice_capture: 'Captura de voz',
    voice_hint: 'Toca para grabar una nota rápida. La IA la clasificará.',
    listening: 'Escuchando...',
    transcribing: 'Transcribiendo con Whisper...',
    use_draft: 'Usar esto',
    retry: 'Reintentar',
    transcript: 'Transcripción',
    not_supported_web: 'La captura de voz requiere un navegador moderno.',
    kids: 'Niños',
    stars: 'estrellas',
    redeem: 'Canjear',
    rewards: 'Recompensas',
    add_reward: 'Añadir recompensa',
    reward_cost: 'Costo (estrellas)',
    not_enough_stars: 'No hay suficientes estrellas',
    redeemed: '¡Canjeado!',
    no_rewards: 'Aún sin recompensas. Añade una.',
    earn_stars: 'Completa tareas para ganar estrellas',
    parent_picks: 'Elecciones del padre',
    conflict_found: 'Atención: conflicto con',
    scanning: 'Leyendo el folleto...',
    scan_flyer: 'Escanear folleto',
    choose_photo: 'Elegir foto',
  },
};

interface StoreState {
  user: User | null;
  loading: boolean;
  lang: Lang;
  t: (key: string, params?: Record<string, string | number>) => string;
  setLang: (l: Lang) => Promise<void>;
  refreshUser: () => Promise<void>;
  logout: () => Promise<void>;
  setUserFromAuth: (user: User, token: string) => Promise<void>;
}

const StoreContext = createContext<StoreState | null>(null);

export function StoreProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [lang, setLangState] = useState<Lang>('en');

  const t = useCallback(
    (key: string, params?: Record<string, string | number>) => {
      let s = TRANSLATIONS[lang][key] || TRANSLATIONS.en[key] || key;
      if (params) {
        for (const [k, v] of Object.entries(params)) {
          s = s.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v));
        }
      }
      return s;
    },
    [lang]
  );

  const refreshUser = useCallback(async () => {
    try {
      const u = await api.me();
      setUser(u);
      if (u.language === 'en' || u.language === 'es') setLangState(u.language);
    } catch {
      setUser(null);
      await tokenStore.clear();
    } finally {
      setLoading(false);
    }
  }, []);

  const setLang = useCallback(async (l: Lang) => {
    setLangState(l);
    if (user) {
      try {
        await api.setLanguage(l);
      } catch {
        /* ignore */
      }
    }
  }, [user]);

  const logout = useCallback(async () => {
    try {
      await api.logout();
    } catch { /* ignore */ }
    await tokenStore.clear();
    setUser(null);
  }, []);

  const setUserFromAuth = useCallback(async (u: User, token: string) => {
    await tokenStore.set(token);
    setUser(u);
    if (u.language === 'en' || u.language === 'es') setLangState(u.language);
    setLoading(false);
  }, []);

  useEffect(() => {
    refreshUser();
  }, [refreshUser]);

  return (
    <StoreContext.Provider
      value={{ user, loading, lang, t, setLang, refreshUser, logout, setUserFromAuth }}
    >
      {children}
    </StoreContext.Provider>
  );
}

export function useStore() {
  const ctx = useContext(StoreContext);
  if (!ctx) throw new Error('useStore must be inside StoreProvider');
  return ctx;
}
