import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useFocusEffect } from 'expo-router';
import { AmbientBackground } from '../../src/components/AmbientBackground';
import { GlassCard } from '../../src/components/GlassCard';
import { useStore } from '../../src/store';
import { api, Card } from '../../src/api';

const TYPE_COLOR: Record<string, string> = {
  SIGN_SLIP: '#F97316',
  RSVP: '#6366F1',
  TASK: '#10B981',
};

function groupByDay(cards: Card[]) {
  const groups: Record<string, Card[]> = {};
  cards.forEach((c) => {
    if (!c.due_date) return;
    const key = new Date(c.due_date).toISOString().slice(0, 10);
    groups[key] = groups[key] || [];
    groups[key].push(c);
  });
  return Object.keys(groups)
    .sort()
    .map((k) => ({ day: k, items: groups[k] }));
}

export default function CalendarScreen() {
  const { t, lang } = useStore();
  const [cards, setCards] = useState<Card[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try {
      const res = await api.listCards();
      setCards(res.filter((c) => c.status === 'OPEN' && c.due_date));
    } catch (e) {
      console.log(e);
    } finally {
      setLoading(false);
    }
  }, []);

  useFocusEffect(
    useCallback(() => {
      load();
    }, [load])
  );

  useEffect(() => {
    load();
  }, [load]);

  const groups = useMemo(() => groupByDay(cards), [cards]);

  const formatDay = (d: string) => {
    const date = new Date(d);
    const now = new Date();
    const diffDays = Math.round(
      (date.setHours(0, 0, 0, 0) - new Date(now.setHours(0, 0, 0, 0)).getTime()) / (1000 * 60 * 60 * 24)
    );
    if (diffDays === 0) return lang === 'es' ? 'Hoy' : 'Today';
    if (diffDays === 1) return lang === 'es' ? 'Mañana' : 'Tomorrow';
    return new Date(d).toLocaleDateString(lang === 'es' ? 'es-ES' : 'en-US', {
      weekday: 'long',
      month: 'short',
      day: 'numeric',
    });
  };

  return (
    <View style={styles.container}>
      <AmbientBackground />
      <SafeAreaView style={{ flex: 1 }} edges={['top']}>
        <ScrollView contentContainerStyle={styles.scroll}>
          <Text style={styles.title}>{t('calendar')}</Text>
          <Text style={styles.sub}>{t('upcoming')}</Text>

          {loading ? (
            <ActivityIndicator color="#fff" style={{ marginTop: 40 }} />
          ) : groups.length === 0 ? (
            <View style={styles.empty}>
              <Text style={styles.emptyText}>{t('no_events')}</Text>
            </View>
          ) : (
            groups.map((g) => (
              <View key={g.day} style={{ marginBottom: 18 }}>
                <Text style={styles.dayLabel}>{formatDay(g.day)}</Text>
                {g.items.map((c) => {
                  const color = TYPE_COLOR[c.type];
                  return (
                    <GlassCard key={c.card_id} style={{ marginTop: 10 }}>
                      <View style={styles.row}>
                        <View style={[styles.dot, { backgroundColor: color }]} />
                        <View style={{ flex: 1 }}>
                          <Text style={styles.itemTitle} numberOfLines={2}>
                            {c.title}
                          </Text>
                          {c.assignee ? (
                            <Text style={styles.meta}>{c.assignee}</Text>
                          ) : null}
                        </View>
                        <Text style={[styles.typeLabel, { color }]}>
                          {c.type === 'SIGN_SLIP'
                            ? t('sign_slip')
                            : c.type === 'RSVP'
                            ? t('rsvp')
                            : t('task')}
                        </Text>
                      </View>
                    </GlassCard>
                  );
                })}
              </View>
            ))
          )}

          <View style={{ height: 200 }} />
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#080910' },
  scroll: { paddingHorizontal: 20, paddingTop: 14 },
  title: {
    fontFamily: 'PlayfairDisplay_400Regular_Italic',
    color: '#fff',
    fontSize: 40,
    lineHeight: 46,
  },
  sub: {
    fontFamily: 'Inter_400Regular',
    color: 'rgba(255,255,255,0.55)',
    fontSize: 13,
    marginBottom: 22,
  },
  dayLabel: {
    fontFamily: 'Inter_600SemiBold',
    color: 'rgba(255,255,255,0.75)',
    fontSize: 13,
    letterSpacing: 0.3,
  },
  row: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  dot: { width: 10, height: 10, borderRadius: 9999 },
  itemTitle: {
    fontFamily: 'Inter_500Medium',
    color: '#fff',
    fontSize: 15,
  },
  meta: { color: 'rgba(255,255,255,0.5)', fontFamily: 'Inter_400Regular', fontSize: 12, marginTop: 2 },
  typeLabel: {
    fontFamily: 'Inter_600SemiBold',
    fontSize: 10,
    letterSpacing: 0.8,
    textTransform: 'uppercase',
  },
  empty: { paddingVertical: 60, alignItems: 'center' },
  emptyText: {
    fontFamily: 'PlayfairDisplay_400Regular_Italic',
    color: 'rgba(255,255,255,0.5)',
    fontSize: 20,
  },
});
