---
name: react-native-patterns
description: React Native / Expo patterns for Frappe-backed mobile apps. Reference for Axios API calls, React Query v4, Redux Toolkit, React Navigation, expo-location, NetworkContext, transport journey lifecycle, attendance flow, and EAS builds.
user-invocable: false
---

# React Native Patterns for Frappe Mobile Apps

Quick reference for building Expo React Native apps that integrate with a Frappe backend.

## App Overview

**Location:** `chatnext-mobile-old/`
**Stack:** React Native 0.71 + Expo ~48 + React Navigation v6 + Redux Toolkit + TanStack React Query v4 + Axios

---

## Frappe API Integration

All API calls go through the pre-configured Axios instance:

```typescript
import apiClient from '../utils/apiClient';

// POST to whitelisted method
const res = await apiClient.post(
  '/api/method/transporter.transporter.api.transport.create_journey',
  { vehicle, route, route_stops: JSON.stringify(stops) }
);
const result = res.data.message; // Frappe wraps response in .message

// GET resource
const res = await apiClient.get('/api/resource/Route List?fields=["*"]');
const routes = res.data.data; // list response in .data
```

**Auth headers** (site name + CSRF token) are injected automatically by the request interceptor in `src/utils/apiClient.ts`.

### Canonical Transport Endpoints

```
# Always use transporter app — NEVER edu_quality.api.transport.*
POST /api/method/transporter.transporter.api.transport.create_journey
POST /api/method/transporter.transporter.api.transport.add_gps_log
POST /api/method/transporter.transporter.api.transport.end_journey_api
GET  /api/method/transporter.transporter.api.transport.get_active_journey
POST /api/method/transporter.transporter.api.transport.cleanup_room_silent

# Attendance
POST /api/method/edu_quality.edu_quality.server_scripts.student.mark_entry

# Routes
GET  /api/method/edu_quality.api.route_list.get_route_list_with_stops
GET  /api/method/edu_quality.api.route_list.get_route_student_attendance
```

---

## React Query v4

> **Important:** v4 uses positional arguments — NOT the v5 object syntax.

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// Query — positional args
const { data, isLoading, refetch } = useQuery(
  ['route-list', schoolId],                          // key array
  () => apiClient.get('/api/resource/...').then(r => r.data.data),
  {
    staleTime: 5 * 60 * 1000,
    enabled: !!schoolId,
    retry: 2,
  }
);

// Mutation
const queryClient = useQueryClient();
const { mutate, isLoading: isSaving } = useMutation(
  (params: CreateParams) =>
    apiClient.post('/api/method/...', params).then(r => r.data.message),
  {
    onSuccess: () => queryClient.invalidateQueries(['route-list']),
    onError: (err) => console.error('Failed:', err),
  }
);
```

---

## Redux Toolkit

```typescript
// Read from store
import { useSelector, useDispatch } from 'react-redux';
import type { RootState } from '../store';

const baseUrl = useSelector((s: RootState) => s.path.baseURL);
const dispatch = useDispatch();

// Dispatch actions
import { setBaseURL } from '../store/pathSlice';
dispatch(setBaseURL('https://school.example.com'));
```

---

## React Navigation

```typescript
import { useNavigation, useRoute } from '@react-navigation/native';

const navigation = useNavigation();
const route = useRoute();

// Navigate
navigation.navigate('LocationTracker');
navigation.navigate('AttendanceScreen', { routeId: 'ROUTE-001' });

// Go back
navigation.goBack();

// Add screen to navigator (AppNavigation.tsx)
<Stack.Screen name="NewScreen" component={NewScreenComponent} />
```

---

## Network Awareness

```typescript
import { useNetwork } from '../contexts/NetworkContext';

const { isConnected, isInternetReachable, onConnectionRestored } = useNetwork();

// Gate API calls
if (!isConnected || !isInternetReachable) {
  return; // skip, queue, or show offline UI
}

// Refetch on reconnect
useEffect(() => {
  return onConnectionRestored(() => {
    refetch();
  });
}, []);
```

---

## Location (GPS)

```typescript
import * as Location from 'expo-location';

// Request permission
const { status } = await Location.requestForegroundPermissionsAsync();
if (status !== 'granted') return;

// One-time location
const loc = await Location.getCurrentPositionAsync({
  accuracy: Location.Accuracy.High,
});
const { latitude, longitude } = loc.coords;

// Watch position
const sub = await Location.watchPositionAsync(
  { accuracy: Location.Accuracy.High, timeInterval: 5000, distanceInterval: 10 },
  (loc) => {
    const { latitude, longitude } = loc.coords;
    // validate before use
    if (isNaN(latitude) || isNaN(longitude)) return;
  }
);
// Cleanup: sub.remove();
```

---

## Transport Journey Lifecycle

```
Boot
 └─ TransportDashboard.tsx
     └─ fetchActiveJourney() → if found, setIsStartJourney(true) [crash recovery]

Start Journey
 └─ LocationTracker.tsx → useTransportApi.createJourney(vehicle, route, stops)
     → returns { journey_id, websocket_room, status: "success" | "resumed" }

GPS Logging (every 30s)
 └─ useTransportApi.sendGpsLog({ currentLocation, optimisedRoute, current_stop_index, roomID })

Attendance
 └─ AttendanceScreen.tsx → mark_entry(student, status, reason)
     reason = "Pickup - Double-tap onboard" | "Drop - Double-tap onboard"

End Journey
 └─ useTransportApi.endJourney(journeyId, vehicle, route)
```

---

## Attendance Marking

```typescript
// reason format expected by the backend
const reason = `${isPickup ? 'Pickup' : 'Drop'} - Double-tap onboard`;

await apiClient.post(
  '/api/method/edu_quality.edu_quality.server_scripts.student.mark_entry',
  {
    student: studentId,
    status: isPickup ? 'Present' : 'Present',
    reason,
    date: format(new Date(), 'yyyy-MM-dd'),
    time: format(new Date(), 'HH:mm:ss'),
  }
);
```

---

## AsyncStorage (Persistence)

```typescript
import AsyncStorage from '@react-native-async-storage/async-storage';

// Save
await AsyncStorage.setItem('journey_id', journeyId);

// Read
const journeyId = await AsyncStorage.getItem('journey_id');

// Remove
await AsyncStorage.removeItem('journey_id');
```

---

## Push Notifications

```typescript
import * as Notifications from 'expo-notifications';

// Get token
const { data: token } = await Notifications.getExpoPushTokenAsync();
// Register token with backend via /api/method/...register_push_token

// Handle foreground notifications
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});
```

---

## Build Commands

```bash
cd chatnext-mobile-old

npx expo start --dev-client      # Dev with custom native modules
npx expo run:android             # Debug APK on connected device
npx expo run:ios                 # Debug on iOS simulator / device

eas build --platform android --profile preview   # APK via EAS
eas build --platform android --profile production # AAB for Play Store
eas build --platform ios --profile production     # IPA for App Store
```

---

## Coordinate Validation

Always validate GPS coordinates before sending to the server:

```typescript
function isValidCoord(lat: number, lng: number): boolean {
  return (
    !isNaN(lat) && !isNaN(lng) &&
    lat >= -90 && lat <= 90 &&
    lng >= -180 && lng <= 180 &&
    lat !== 0 && lng !== 0
  );
}
```
