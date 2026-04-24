import React from 'react';
import { View, Text } from 'react-native';

export default function Index() {
  return (
    <View style={{ flex: 1, backgroundColor: '#111', alignItems: 'center', justifyContent: 'center' }}>
      <Text style={{ color: '#fff', fontSize: 24 }}>Landing route is rendering</Text>
    </View>
  );
}