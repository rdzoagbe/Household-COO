import React, { useEffect } from 'react';
import { View, Text, StyleSheet, Pressable, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import * as AuthSession from 'expo-auth-session';
import * as Google from 'expo-auth-session/providers/google';

WebBrowser.maybeCompleteAuthSession();

export default function Landing() {
  const router = useRouter();

  const webClientId = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID;
  const androidClientId = process.env.EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID;

  const [request, response, promptAsync] = Google.useAuthRequest({
    androidClientId,
    webClientId,
  });

  useEffect(() => {
    console.log('Google webClientId:', webClientId);
    console.log('Google androidClientId:', androidClientId);
    console.log('Google auth request:', request);
  }, [request, webClientId, androidClientId]);

  useEffect(() => {
    const handleGoogleResponse = async () => {
      if (!response || response.type !== 'success') return;

      try {
        const code = response.params?.code;

        if (!code) {
          Alert.alert('Sign-in failed', 'Google did not return an authorization code.');
          return;
        }

        if (!request?.redirectUri || !request?.codeVerifier) {
          Alert.alert('Sign-in failed', 'Google request is missing redirect URI or code verifier.');
          return;
        }

        if (!androidClientId) {
          Alert.alert('Sign-in failed', 'Android Google Client ID is missing.');
          return;
        }

        const tokenResult = await AuthSession.exchangeCodeAsync(
          {
            clientId: androidClientId,
            code,
            redirectUri: request.redirectUri,
            extraParams: {
              code_verifier: request.codeVerifier,
            },
          },
          {
            tokenEndpoint: 'https://oauth2.googleapis.com/token',
          }
        );

        const idToken =
          tokenResult.idToken ||
          (tokenResult as any).params?.id_token;

        if (!idToken) {
          console.log('Google token result:', tokenResult);
          Alert.alert('Sign-in failed', 'Google did not return an ID token.');
          return;
        }

        const { api } = await import('../src/api');
        const result = await api.exchangeSession(idToken);

        console.log('Signed in user:', result.user);

        router.replace('/(tabs)/feed');
      } catch (error: any) {
        console.error('google sign-in exchange failed', error);
        Alert.alert('Sign-in failed', error?.message || 'Please try again.');
      }
    };

    handleGoogleResponse();
  }, [response, request, router, androidClientId]);

  const signIn = async () => {
    try {
      if (!webClientId || !androidClientId) {
        Alert.alert(
          'Google Sign-In not configured',
          'Missing Google OAuth client IDs in .env.'
        );
        return;
      }

      await promptAsync();
    } catch (error: any) {
      console.error('google prompt failed', error);
      Alert.alert('Sign-in failed', error?.message || 'Please try again.');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Household COO</Text>
      <Text style={styles.subtitle}>Your household chief of staff</Text>

      <Pressable
        onPress={signIn}
        disabled={!request}
        style={[styles.button, !request && styles.disabled]}
      >
        <Text style={styles.buttonText}>Sign in with Google</Text>
      </Pressable>

      <Text style={styles.note}>Landing page test</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#111',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  title: {
    color: '#fff',
    fontSize: 32,
    fontWeight: '700',
    marginBottom: 8,
  },
  subtitle: {
    color: '#bbb',
    fontSize: 16,
    marginBottom: 24,
    textAlign: 'center',
  },
  button: {
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderRadius: 999,
  },
  disabled: {
    opacity: 0.5,
  },
  buttonText: {
    color: '#111',
    fontWeight: '700',
  },
  note: {
    color: '#888',
    marginTop: 18,
  },
});