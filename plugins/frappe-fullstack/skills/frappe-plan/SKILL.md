---
name: frappe-plan
description: Create a comprehensive implementation plan for Frappe/ERPNext features with technical design, task breakdown, and documentation. Saves plan to a markdown file.
argument-hint: "feature description"
context: fork
agent: frappe-fullstack:frappe-planner
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, EnterPlanMode, ExitPlanMode
---

# Frappe Feature Planning

Create a comprehensive implementation plan for a Frappe/ERPNext feature or module.

## Feature

$ARGUMENTS

## Process

1. **Enter Plan Mode** — Use `EnterPlanMode` to signal planning phase
2. **Ask Clarifications** — Use `AskUserQuestion` for requirements
3. **Explore Codebase** — Find existing patterns, DocTypes, hooks
4. **Design Solution** — Data model, architecture, API design
5. **Write Plan** — Save to feature folder as `plan/PLAN.md`
6. **Exit Plan Mode** — Use `ExitPlanMode` for user approval

## Plan Sections

- Overview & Requirements (functional, non-functional)
- Technical Design (data model, backend, frontend, integrations)
- Implementation Plan (phased tasks with dependencies)
- Testing & Deployment strategy
- Open Questions

## After Approval

Suggest next commands:
- `/frappe-fullstack:frappe-doctype-create` for DocType scaffolding
- `/frappe-fullstack:frappe-backend` for backend logic
- `/frappe-fullstack:frappe-frontend` for frontend logic
- `/frappe-fullstack:frappe-fullstack` for full-stack implementation
