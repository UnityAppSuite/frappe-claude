---
name: react-spa-patterns
description: React SPA patterns for Frappe-backed applications. Reference for TanStack Query, Axios, Jotai, shadcn/ui, Tailwind, Refine v4, Mantine v5, React Router, Vite config, and Frappe API integration in the Unity Parent App and Walsh Admin Portal.
user-invocable: false
---

# React SPA Patterns for Frappe

Quick reference for building React SPAs that integrate with a Frappe backend.

## Project Overview

| App | Path | Stack |
|-----|------|-------|
| Unity Parent App | `apps/unity_parent_app/new_frontend/` | React 18 + Vite 6 + shadcn/ui + Tailwind + TanStack Query v5 + Jotai + Axios |
| Walsh Admin Portal | `apps/edu_quality/walsh/` | React 18 + Vite 5 + Refine v4 + Mantine v5 + React Query v3 |

---

## Frappe API Integration

### Axios (Parent App)

```typescript
// src/utils/axiosInstance.ts — pre-configured with withCredentials: true
import axiosInstance from '@/utils/axiosInstance';

// Call a whitelisted method
const res = await axiosInstance.post(
  '/api/method/app.module.function',
  { student_id: 'STU-001' }
);
const data = res.data.message; // Frappe wraps in .message

// Fetch a resource
const res = await axiosInstance.get('/api/resource/Student/STU-001');
const student = res.data.data;
```

### Refine Data Provider (Walsh)

```typescript
import { useList, useOne, useCreate, useUpdate, useDelete } from "@refinedev/core";

// List
const { data } = useList({
  resource: "Student",
  filters: [{ field: "enabled", operator: "eq", value: 1 }],
  pagination: { pageSize: 50 },
  meta: { dataProviderName: "default" }, // or "notices", "cmap"
});
// data.data = array of records

// Create
const { mutate: create } = useCreate();
create({ resource: "Student", values: { ... } });

// Custom method (not REST)
const res = await dataProvider.custom({
  url: '/api/method/edu_quality.api.module.function',
  method: 'post',
  payload: { param: value },
});
```

---

## TanStack Query Patterns

### Parent App (v5)

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// Query
const { data, isLoading, error } = useQuery({
  queryKey: ['students', academicYear],
  queryFn: () =>
    axiosInstance.post('/api/method/...', { academic_year: academicYear })
      .then(r => r.data.message),
  staleTime: 5 * 60 * 1000,
  enabled: !!academicYear,
});

// Mutation with cache invalidation
const queryClient = useQueryClient();
const { mutate } = useMutation({
  mutationFn: (data) => axiosInstance.post('/api/method/...', data).then(r => r.data.message),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['students'] }),
});
```

### Walsh (v3)

```typescript
import { useQuery, useMutation } from 'react-query';

const { data } = useQuery(
  ['key', dep],
  () => fetch('/api/method/...').then(r => r.json()).then(r => r.message),
  { staleTime: 60_000 }
);
```

---

## State Management

### Jotai (Parent App)

```typescript
// Define atom
import { atom } from 'jotai';
export const activeStudentAtom = atom<string | null>(null);

// Read + write in component
import { useAtom, useAtomValue, useSetAtom } from 'jotai';
const [student, setStudent] = useAtom(activeStudentAtom);
const student = useAtomValue(activeStudentAtom); // read-only
const setStudent = useSetAtom(activeStudentAtom); // write-only
```

---

## Routing

### React Router v6 (Parent App)

```tsx
// App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
<BrowserRouter basename="/parent-app">
  <Routes>
    <Route path="/" element={<Home />} />
    <Route path="/transport" element={<Transport />} />
  </Routes>
</BrowserRouter>

// Navigation in component
import { useNavigate, useParams } from 'react-router-dom';
const navigate = useNavigate();
navigate('/transport?active_student=STU-001');
```

### Refine Router (Walsh)

```tsx
// Routes are driven by Refine resources + react-router-v6 integration
// Add to resources array in <Refine> component
resources={[
  {
    name: "notices",
    list: "/notices",
    create: "/notices/create",
    edit: "/notices/edit/:id",
    meta: { dataProviderName: "notices" },
  },
]}
```

---

## UI Components

### shadcn/ui + Tailwind (Parent App)

```tsx
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { cn } from "@/lib/utils"; // clsx + tailwind-merge

// Variants with CVA
import { cva } from "class-variance-authority";
const buttonVariants = cva("base-classes", {
  variants: { size: { sm: "...", lg: "..." } },
});
```

### Mantine v5 (Walsh)

```tsx
import { Button, TextInput, Select, Stack, Group, Modal } from "@mantine/core";
import { useDisclosure } from "@mantine/hooks";
import { notifications } from "@mantine/notifications";

const [opened, { open, close }] = useDisclosure(false);
notifications.show({ title: "Saved", message: "Record updated", color: "green" });
```

---

## Real-Time (Parent App Only)

```typescript
// src/utils/frappeSocket.ts
import { subscribeToRoom, onRealtimeEvent, offRealtimeEvent, unsubscribeFromRoom } from '@/utils/frappeSocket';

// Subscribe to a room
subscribeToRoom(`transport_journey_${journeyId}`);

// Listen for events
const handler = (data: unknown) => { /* handle */ };
onRealtimeEvent('transport_gps_update', handler);

// Cleanup
offRealtimeEvent('transport_gps_update', handler);
unsubscribeFromRoom(`transport_journey_${journeyId}`);
```

---

## Build & Deploy

```bash
# Parent App
cd apps/unity_parent_app/new_frontend
npm run dev                  # Dev server :8080
npm run build                # Build → public/new_frontend/ + copy www/parent-app.html

# Walsh
cd apps/edu_quality/walsh
yarn dev                     # Dev server :8080
yarn build                   # TS compile → Vite build → public/walsh/ + copy www/walsh.html

# After any build
bench --site <site> clear-cache
bench build --app <app>      # Only needed if static assets changed
```

---

## Common Patterns

### Protected Route (Parent App)

```tsx
import { Navigate } from 'react-router-dom';
import { isLoggedIn } from '@/utils/cookies';

const ProtectedRoute = ({ children }) =>
  isLoggedIn() ? children : <Navigate to="/login" replace />;
```

### Error Boundary

```tsx
// Wrap pages in ErrorBoundary from src/components/
import ErrorBoundary from '@/components/ErrorBoundary';
<ErrorBoundary fallback={<ErrorPage />}>
  <MyPage />
</ErrorBoundary>
```

### Frappe File Upload

```typescript
const formData = new FormData();
formData.append('file', file);
formData.append('doctype', 'Student');
formData.append('docname', studentId);
const res = await axiosInstance.post('/api/method/upload_file', formData, {
  headers: { 'Content-Type': 'multipart/form-data' },
});
```
