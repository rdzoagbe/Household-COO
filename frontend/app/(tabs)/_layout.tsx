import React from 'react';
import { Tabs } from 'expo-router';
import { View, StyleSheet, Text, Platform } from 'react-native';
import { BlurView } from 'expo-blur';
import { Home, Calendar as CalendarIcon, Lock, Settings as SettingsIcon } from 'lucide-react-native';
import { useStore } from '../../src/store';

function TabIcon({ focused, Icon, label }: { focused: boolean; Icon: any; label: string }) {
  return (
    <View style={styles.tabItem}>
      <Icon color={focused ? '#fff' : 'rgba(255,255,255,0.45)'} size={20} />
      <Text style={[styles.tabLabel, { color: focused ? '#fff' : 'rgba(255,255,255,0.45)' }]}>
        {label}
      </Text>
    </View>
  );
}

export default function TabLayout() {
  const { t } = useStore();
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
        tabBarStyle: {
          position: 'absolute',
          left: 20,
          right: 20,
          bottom: 110,
          height: 60,
          borderRadius: 9999,
          backgroundColor: 'rgba(14,15,22,0.75)',
          borderTopWidth: 1,
          borderWidth: 1,
          borderColor: 'rgba(255,255,255,0.08)',
          elevation: 0,
          shadowColor: '#000',
          shadowOpacity: 0.5,
          shadowRadius: 16,
          paddingHorizontal: 10,
        },
        tabBarBackground: () =>
          Platform.OS === 'web' ? null : (
            <BlurView
              intensity={30}
              tint="dark"
              style={[StyleSheet.absoluteFill, { borderRadius: 9999 }]}
            />
          ),
      }}
    >
      <Tabs.Screen
        name="feed"
        options={{
          tabBarIcon: ({ focused }) => <TabIcon focused={focused} Icon={Home} label={t('feed')} />,
        }}
      />
      <Tabs.Screen
        name="calendar"
        options={{
          tabBarIcon: ({ focused }) => <TabIcon focused={focused} Icon={CalendarIcon} label={t('calendar')} />,
        }}
      />
      <Tabs.Screen
        name="vault"
        options={{
          tabBarIcon: ({ focused }) => <TabIcon focused={focused} Icon={Lock} label={t('vault')} />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          tabBarIcon: ({ focused }) => <TabIcon focused={focused} Icon={SettingsIcon} label={t('settings')} />,
        }}
      />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  tabItem: {
    alignItems: 'center',
    justifyContent: 'center',
    gap: 3,
    minWidth: 60,
    paddingTop: 8,
  },
  tabLabel: {
    fontFamily: 'Inter_500Medium',
    fontSize: 10,
    letterSpacing: 0.5,
  },
});
