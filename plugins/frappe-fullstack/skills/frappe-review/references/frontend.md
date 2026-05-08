# Frontend Review — React / Vue / React Native + Frappe Client Scripts

Covers React (incl. shadcn/ui, Refine, TanStack Query, Jotai), Vue 3 / Frappe UI, React Native / Expo, classic Frappe client scripts, and general JS/TS patterns.

---

## React & JSX

### 🟠 Major — hooks misuse
```jsx
// BAD — stale closure
useEffect(() => { fetchStudents(classId); }, []); // classId missing from deps

// GOOD
useEffect(() => { fetchStudents(classId); }, [classId]);

// BAD — side effect in render body
function StudentList() {
  fetch('/api/students'); // outside useEffect!
  return <div>...</div>;
}
```
Flag:
- `useEffect` with empty deps `[]` when outer-scope variables are used inside
- `useEffect` without cleanup for subscriptions / timers / event listeners
- Setting state inside `useEffect` without proper dependencies (infinite loop)
- `useState` for derived data that should be `useMemo`
- Object/array literals passed as deps and recreated each render

### 🟠 Major — component issues
- Components over 200 lines without splitting
- Prop drilling through 3+ levels (consider context or state lib)
- Missing `key` on list-rendered elements, or array index as key on dynamic lists
- Direct DOM manipulation (`document.querySelector`, `document.getElementById`) in React
- `dangerouslySetInnerHTML` without sanitization → 🔴 Critical (XSS)

### 🟡 Minor — React style
- Missing TypeScript types / PropTypes for component props
- Default export mixed with named exports inconsistently
- Event handler not using `useCallback` when passed to a memoized child
- Inline function definitions in JSX creating new references each render (when it actually matters)
- Missing error boundaries around components that fetch data
- Not destructuring props: `function Comp(props)` vs `function Comp({ name, age })`

### 💡 Suggestions
- Complex conditional rendering could use early returns
- Repeated state shape → consider `useReducer` instead of multiple `useState`
- Frequent re-renders with same props → `React.memo()`

---

## Vue (Frappe UI / Vue 3)

### 🟠 Major
- Mutating props directly instead of emitting events to parent
- `v-if` for frequent toggles where `v-show` is cheaper (or vice versa)
- Watchers on entire objects without `{ deep: true }` when needed (or deep-watching when not, killing perf)
- `v-for` without `:key`
- Mixing Options API and Composition API in the same component without reason
- `this.$forceUpdate()` — almost always indicates a reactivity bug

### 🟡 Minor
- Component not using `<script setup>` (v15 Frappe UI standard)
- Missing `defineProps` / `defineEmits` type declarations
- Oversized `<template>` blocks — extract sub-components
- Not using computed properties for derived state
- `ref()` when `reactive()` is more appropriate (or vice versa)

### Frappe UI components
- 🟡 Reinventing components that exist in Frappe UI (`Button`, `Dialog`, `Input`, `FormControl`, …)
- 🟡 Custom CSS overriding Frappe UI design tokens without justification

---

## React Native / Expo

### 🔴 Critical
- Sensitive data (tokens, passwords) in `AsyncStorage` without encryption — use `expo-secure-store`
- `eval()` or dynamic code execution

### 🟠 Major — performance
```jsx
// BAD — ScrollView for long lists
<ScrollView>
  {students.map(s => <StudentCard key={s.id} student={s} />)}
</ScrollView>

// GOOD — FlatList
<FlatList
  data={students}
  renderItem={({ item }) => <StudentCard student={item} />}
  keyExtractor={item => item.id}
/>
```
Flag:
- `ScrollView` for lists with potentially >20 items
- Missing `keyExtractor` on `FlatList` / `SectionList`
- Images without explicit dimensions or without `resizeMode`
- Inline styles on frequently re-rendered components — use `StyleSheet.create`
- Missing `KeyboardAvoidingView` on forms
- `react-native-reanimated` worklets accessing JS-thread variables

### 🟡 Minor
- Platform-specific code without `Platform.OS` checks or platform files (`.ios.js` / `.android.js`)
- Hardcoded pixel values that should use responsive sizing
- Missing `accessible` / `accessibilityLabel` on interactive elements
- `setTimeout` for animations instead of `Animated` / Reanimated
- List item components not wrapped in `React.memo`

---

## Frappe frontend integration

### 🟠 Major — API calls
```javascript
// BAD — no error handling on frappe.call
frappe.call({
  method: 'app.api.get_students',
  args: { class: classId }
}).then(r => setStudents(r.message));

// GOOD — error handling + freeze
frappe.call({
  method: 'app.api.get_students',
  args: { class: classId },
  freeze: true,
  freeze_message: __('Loading students...')
}).then(r => {
  if (r.message) setStudents(r.message);
}).catch(err => {
  frappe.msgprint(__('Failed to load students'));
  console.error(err);
});
```
Flag:
- `frappe.call` without `.catch()` / error callback on writes
- `frappe.xcall` without try/catch in async context
- `frappe.call({ async: false, ... })` — blocks the UI thread, never acceptable
- Missing `freeze: true` on long calls — user double-clicks and submits twice
- Hardcoded API method paths that should reference a constant
- Not using `__()` for user-facing strings

### Classic Frappe form scripts
- 🟠 Client script modifying server-side fields without validation
- 🟠 Not using `frappe.ui.form.on` properly (missing doctype parameter)
- 🟡 `cur_frm` in new code — prefer the `frm` parameter from event handlers
- 🟡 Missing `frm.dirty()` check before making server calls
- 🟡 Setting field values inside `refresh` without guarding `frm.is_new()` / `frm.doc.docstatus` — infinite save loops or "you have unsaved changes" on view
- 🟡 Heavy logic in `refresh` that should be in `onload` or a triggered event

---

## State management

### 🟠 Major
- Global mutable state outside the chosen state lib
- State stored in module-level variables that persist between renders / navigations
- Async state without race-condition handling (component unmounted before response)
- Missing cleanup: component fetches data but doesn't cancel on unmount

### 🟡 Minor
- State that belongs in URL / query params held in component state
- Form state not reset on route change
- Derived state stored separately instead of computed from source

### TanStack Query / React Query
- 🟠 Mutations without `onError` handler when they touch user data
- 🟡 Missing `queryKey` invalidation after a related mutation
- 🟡 `staleTime: 0` everywhere — defeats the cache

---

## CSS & styling

### 🟠 Major
- `!important` used more than once in the same file
- Inline styles with dynamic values that could be CSS variables
- Z-index wars (`z-index: 99999`)
- Fixed pixel widths breaking responsive layouts

### 🟡 Minor
- Color values not using design tokens / CSS variables
- Duplicate style rules across components
- Magic numbers in margins / paddings without comment
- Missing responsive breakpoints on layout components

---

## General JavaScript / TypeScript

### 🔴 Critical
- `eval()`, `new Function()`, `innerHTML` with user input → XSS
- Credentials or tokens in frontend code

### 🟠 Major
- `var` instead of `const` / `let` (upgrade to 🟠 if it causes scoping bugs)
- `==` instead of `===` without intentional coercion
- Unhandled promise rejections (missing `.catch()` or `try/catch` on `await`)
- Modifying function parameters (objects/arrays) instead of copying
- `async` function without any `await` inside

### 🟡 Minor
- `console.log` left in production code
- Nested ternaries that hurt readability
- Not using optional chaining (`?.`) where null checks are verbose
- String concatenation instead of template literals
- Unused variables / imports (linter should catch — flag if present)

### TypeScript
- 🟠 Type assertion (`as Type`) hiding actual mismatches
- 🟡 `any` without justification
- 🟡 Missing return type on exported functions
- 🟡 Not using `interface` / `type` for API response shapes
