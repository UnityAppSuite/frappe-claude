---
name: react-native
description: Invoke the React Native frontend agent for Frappe-backed Expo mobile apps. Use for screens, navigation, GPS tracking, Redux state, React Query v4, camera, location, push notifications, and Expo/EAS builds.
argument-hint: "task description"
context: fork
agent: frappe-fullstack:react-native-frontend
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# React Native Frontend Development

You are working on a React Native / Expo mobile app task for a Frappe-backed application.

## Task

$ARGUMENTS

## Key Rules

1. Read existing files before editing
2. Transport endpoints MUST use the transporter app (never `edu_quality.api.transport.*`)
3. API response: `response.data.message`
4. React Query v4 — positional args syntax (not v5 object syntax)
5. Network-aware: `useNetwork()` before requests; `onConnectionRestored` for refetch
6. GPS: validate coords before sending (NaN check, valid range)
7. New API hooks in `src/hooks/apis/` following v4 React Query pattern
8. New screens added to `src/navigation/AppNavigation.tsx`
