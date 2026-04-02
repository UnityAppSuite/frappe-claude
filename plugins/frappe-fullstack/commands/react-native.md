---
description: Invoke the React Native frontend agent for Frappe-backed Expo mobile apps. Use for screens, navigation, transport journey lifecycle, GPS tracking, attendance marking, Redux state, React Query v4, camera, location, push notifications, network awareness, and Expo/EAS builds.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, TodoWrite
argument-hint: <task_description>
---

# React Native Frontend Development

You are invoking the specialized React Native frontend agent.

## Request

$ARGUMENTS

## Agent Invocation

Use the Agent tool to spawn the `frappe-fullstack:react-native-frontend` agent with the following prompt:

```
You are working on a React Native / Expo mobile app task for a Frappe-backed application.

## Task
{user task from $ARGUMENTS}

## App Location
chatnext-mobile-old/

## Stack
React Native 0.71 + Expo ~48 + React Navigation v6 + Redux Toolkit + TanStack React Query v4 + Axios

## Key Rules
1. Read existing files before editing
2. Transport endpoints MUST use the transporter app:
   - transporter.transporter.api.transport.create_journey
   - transporter.transporter.api.transport.add_gps_log
   - transporter.transporter.api.transport.end_journey_api
   - transporter.transporter.api.transport.get_active_journey
   Never use edu_quality.api.transport.* for these
3. API response: response.data.message
4. React Query v4 — positional args syntax (not v5 object syntax)
5. Network-aware: useNetwork() before requests; onConnectionRestored for refetch
6. GPS: validate coords before sending (NaN check, valid range)
7. Journey lifecycle: useJourneyLogic.ts + LocationTracker.tsx

## Instructions
1. Read the relevant screen/hook file first
2. New API hooks in src/hooks/apis/ following v4 React Query pattern
3. New screens added to src/navigation/AppNavigation.tsx
4. GPS/camera: physical device required for testing
```

## Build Commands

```bash
cd chatnext-mobile-old
npx expo start --dev-client   # Development
npx expo run:android          # Android
eas build --platform android  # EAS cloud build
```
