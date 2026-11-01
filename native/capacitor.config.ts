import type { CapacitorConfig } from '@capacitor/cli';

// EST — native shell (Android / iOS) around the field app.
// appId is the permanent store identity: it cannot change after the first
// Play Console / App Store Connect upload — confirm before publishing.
const config: CapacitorConfig = {
  appId: 'in.est.surveillance',
  appName: 'EST',
  webDir: 'www',
  server: {
    // Serve the bundled web app from https://localhost so Supabase, secure
    // cookies and the geolocation API behave exactly as on the website.
    androidScheme: 'https',
    iosScheme: 'https',
  },
  android: {
    allowMixedContent: false,
    backgroundColor: '#0d2018',
  },
  ios: {
    contentInset: 'automatic',
    backgroundColor: '#0d2018',
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 1200,
      launchAutoHide: true,
      backgroundColor: '#0d2018',
      showSpinner: false,
      androidScaleType: 'CENTER_CROP',
      splashImmersive: true,
    },
    StatusBar: {
      style: 'DARK',
      backgroundColor: '#0d2018',
      overlaysWebView: false,
    },
  },
};

export default config;
