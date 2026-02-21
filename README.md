# Omnicore — Expo Chime SDK for React Native

A React Native video conferencing app built with [Expo Modules API](https://docs.expo.dev/versions/latest/sdk/modules/) and [Amazon Chime SDK](https://aws.amazon.com/chime/chime-sdk/). The native module bridges the Chime SDK for both Android (Kotlin) and iOS (Swift), exposing a clean React hook-based API for real-time audio/video meetings.

Forked from [vintasoftware/expo-chime-demo](https://github.com/vintasoftware/expo-chime-demo) — credit to [Vinta Software](https://github.com/vintasoftware) for the original Android implementation.

<img src="https://github.com/user-attachments/assets/b96f9a6d-8113-4a60-b5a0-cfb0afa39b05" alt="Expo Chime Demo screenshot" width="200" />

## Supported Platforms

- Android (arm64)
- iOS (arm64)

> AWS Chime SDK does not support x86 emulators. Use a physical device or an arm64 simulator (Apple Silicon Mac).

## Features

- Real-time video conferencing with multi-participant video grid
- Audio/video controls (mute/unmute, camera on/off)
- Local video preview with camera mirroring (iOS)
- Dynamic video tile layout
- Runtime permissions handling for camera and microphone

## Tech Stack

- **Expo SDK 52** with Expo Modules API
- **React Native 0.76** with New Architecture enabled
- **Amazon Chime SDK** — Android 0.25.3 / iOS 0.27.2
- **NativeWind** (Tailwind CSS) for styling
- **gluestack-ui v2** for UI components
- **Expo Router** for file-based navigation

## Project Structure

```
├── app/                          # Expo Router screens
│   ├── _layout.tsx               # Root layout
│   └── (app)/
│       ├── index.tsx             # Home / join screen
│       ├── [meeting].tsx         # Meeting screen
│       └── _layout.tsx           # App layout
├── components/                   # React components
│   ├── MeetingScreen.tsx         # Meeting UI
│   ├── Modal.tsx                 # Modal component
│   ├── LoadingScreen.tsx
│   └── ui/                       # gluestack-ui components
├── modules/expo-aws-chime/       # Native module
│   ├── index.ts                  # Public API exports
│   ├── expo-module.config.json   # Platform registration
│   ├── android/
│   │   ├── build.gradle
│   │   └── src/main/java/expo/modules/awschime/
│   │       ├── ExpoAWSChimeModule.kt   # Native module (Kotlin)
│   │       └── ExpoAWSChimeView.kt     # Video render view
│   ├── ios/
│   │   ├── ExpoAWSChime.podspec
│   │   ├── ExpoAWSChimeModule.swift    # Native module (Swift)
│   │   └── ExpoAWSChimeView.swift      # Video render view
│   └── src/
│       ├── ChimeAPI.ts                 # API client
│       ├── ExpoAWSChime.types.ts       # TypeScript types
│       ├── ExpoAWSChimeModule.ts       # JS bridge
│       ├── ExpoAWSChimeView.tsx        # Native view wrapper
│       ├── useChimeMeeting.tsx         # React hook + context
│       └── utils/config.ts            # Environment config
└── assets/                       # Fonts and images
```

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (LTS)
- [Expo CLI](https://docs.expo.dev/get-started/installation/)
- For Android: Android Studio with an arm64 device (physical or emulator on Apple Silicon)
- For iOS: Xcode with CocoaPods (`brew install cocoapods`)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/mundurragacl/omnicore-chime-reactnative.git
cd expo-chime-demo
```

2. Install dependencies:
```bash
npm install
```

3. Deploy the [serverless demo backend](https://github.com/aws/amazon-chime-sdk-js/tree/main/demos/serverless) from the Chime SDK JS repo and note the API Gateway URL. It looks like:
```
https://<id>.execute-api.<region>.amazonaws.com/Prod/
```

4. Configure environment variables:
```bash
cp .env.local.example .env.local
```
Then edit `.env.local`:
```
EXPO_PUBLIC_CHIME_API_URL=https://<id>.execute-api.<region>.amazonaws.com/Prod/
EXPO_PUBLIC_CHIME_API_REGION=us-east-1
```

### Running on Android

1. Connect a physical device or start an arm64 emulator via Android Studio. For physical devices, [Wi-Fi pairing](https://developer.android.com/studio/run/device#wireless) is the easiest option.

2. Build and run:
```bash
npx expo run:android
```

### Running on iOS

1. Generate the native project and install pods:
```bash
npx expo prebuild --platform ios
```

2. Build and run on a device or simulator:
```bash
npx expo run:ios
```

Or open `ios/expochimedemoapp.xcworkspace` in Xcode and build from there.

## Native Module API

The `expo-aws-chime` module exposes the following through the Expo Modules API:

**Functions:**
- `startMeeting(meetingInfo, attendeeInfo)` — Join a Chime meeting session
- `stopMeeting()` — Leave and clean up the session
- `mute()` / `unmute()` — Toggle local audio
- `startLocalVideo()` / `stopLocalVideo()` — Toggle local camera

**Events:**
- `onMeetingStart` / `onMeetingEnd`
- `onAttendeesJoin` / `onAttendeesLeave`
- `onAttendeesMute` / `onAttendeesUnmute`
- `onAddVideoTile` / `onRemoveVideoTile`
- `onError`

**View:**
- `ExpoAWSChimeView` — Native video render view with `tileId` and `isLocal` props

**React integration:**
- `ChimeMeetingProvider` — Context provider wrapping all meeting state
- `useChimeMeeting()` — Hook exposing meeting state and controls

## License

This project is licensed under the MIT License — see the `LICENSE.txt` file for details.