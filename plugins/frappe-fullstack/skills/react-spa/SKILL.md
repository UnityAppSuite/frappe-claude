---
name: react-spa
description: Invoke the React SPA frontend agent for Frappe-backed React applications. Handles the Unity Parent App (shadcn/ui + TanStack Query v5 + Jotai) and Walsh Admin Portal (Refine v4 + Mantine v5).
argument-hint: "task description"
context: fork
agent: frappe-fullstack:react-spa-frontend
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# React SPA Frontend Development

You are working on a React SPA frontend task for a Frappe-backed application.

## Task

$ARGUMENTS

## Apps

- **Unity Parent App**: `apps/unity_parent_app/new_frontend/`
  Stack: React 18 + Vite 6 + TypeScript + React Router v6 + TanStack Query v5 + Jotai + shadcn/ui + Tailwind + Axios

- **Walsh Admin Portal**: `apps/edu_quality/walsh/`
  Stack: React 18 + Vite 5 + TypeScript + Refine v4 + Mantine v5 + React Query v3

## Instructions

1. Identify which app the task is for (or ask if unclear)
2. Read relevant existing files before making changes
3. Follow existing patterns in each app
4. Frappe API responses are at `res.data.message` (Axios) or `data.data` (Refine list)
