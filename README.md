# Glazia Home Secure App

Flutter mobile app for the Glazia Home Secure backend.

## Backend URL

The default API URL is:

```text
http://10.0.2.2:3000
```

That is the Android emulator address for a server running on your Mac at `localhost:3000`.

For iOS simulator, desktop, web, or a physical device, override it:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

For a physical phone, use your Mac's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000
```
