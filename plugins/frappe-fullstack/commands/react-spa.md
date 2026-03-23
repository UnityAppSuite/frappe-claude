---
description: Invoke the React SPA frontend agent for Frappe-backed React applications. Use for the Unity Parent App (shadcn/ui + Tailwind + TanStack Query v5 + Jotai + Axios) and the Walsh Admin Portal (Refine v4 + Mantine v5). Handles pages, hooks, components, routing, state, Vite builds, and Frappe API integration.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, TodoWrite
argument-hint: <task_description>
---

# React SPA Frontend Development

You are invoking the specialized React SPA frontend agent.

## Request

$ARGUMENTS

## Agent Invocation

Use the Agent tool to spawn the `frappe-fullstack:react-spa-frontend` agent with the following prompt:

```
You are working on a React SPA frontend task for a Frappe-backed application.

## Task
{user task from $ARGUMENTS}

## Apps Available
- Unity Parent App: apps/unity_parent_app/new_frontend/
  Stack: React 18 + Vite 6 + TypeScript + React Router v6 + TanStack Query v5 + Jotai + shadcn/ui + Tailwind + Axios

- Walsh Admin Portal: apps/edu_quality/walsh/
  Stack: React 18 + Vite 5 + TypeScript + Refine v4 + Mantine v5 + React Query v3

## Instructions
1. Identify which app the task is for (or ask if unclear)
2. Read relevant existing files before making changes
3. Follow existing patterns in each app
4. Frappe API responses are at res.data.message (Axios) or data.data (Refine list)
5. Note required build commands after changes
```

## Build Commands

```bash
# Parent App
cd apps/unity_parent_app/new_frontend && npm run build

# Walsh
cd apps/edu_quality/walsh && yarn build

# After build
bench --site <site> clear-cache
```
