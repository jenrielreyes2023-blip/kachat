# KatsKlub

KatsKlub is a focused chat space for direct conversations, groups, and voice or video calls. The Flutter client uses Tencent Cloud Chat and CallKit, with a calm paper-and-ink interface designed for readable, low-friction messaging.

## Visual direction

The refreshed interface uses a warm paper background, deep ink surfaces, violet interaction states, and coral highlights. The custom KatsKlub mark is rendered as an inline SVG so it stays crisp across screen sizes without relying on a generic chat icon. The web target loads Plus Jakarta Sans for a friendly, readable typographic voice and falls back gracefully on native targets.

## Getting started

Install the Flutter SDK, then run:

```bash
flutter pub get
flutter run
```

The app expects the token endpoint configured in `lib/main.dart` to return a `userSig`, optional `nickName`, and optional `avatarUrl` for the submitted KatsKlub ID.

## Main experiences

- Sign in with a KatsKlub ID and sync the profile with Tencent Cloud.
- Browse recent conversations and open direct or group chats.
- Start voice and video calls from a direct chat.
- Browse contacts and groups.
- Review the signed-in profile and sign out securely.
