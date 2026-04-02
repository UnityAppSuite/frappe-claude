---
name: frappe-doctype-field
description: Add, modify, or remove fields from an existing Frappe DocType with automatic JSON updates
argument-hint: "DocType Name action field_details"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Manage DocType Fields

Add, modify, or remove fields from an existing Frappe DocType.

## Arguments

Parse the user's input: $ARGUMENTS

- **doctype_name**: Name of the existing DocType
- **action**: add, modify, remove, list
- **field_details**: Field specifications (for add/modify)

## Examples

```
/frappe-fullstack:frappe-doctype-field "Sales Order" list
/frappe-fullstack:frappe-doctype-field "Sales Order" add customer_reference Data
/frappe-fullstack:frappe-doctype-field "Sales Order" add priority Select "Low\nMedium\nHigh"
/frappe-fullstack:frappe-doctype-field "Sales Order" modify customer_name label "Client Name"
/frappe-fullstack:frappe-doctype-field "Sales Order" remove customer_reference
```

## Process

### Step 1: Find DocType JSON

```bash
find . -name "*.json" -path "*/doctype/*" | xargs grep -l '"name": "<DocType Name>"'
```

### Step 2: Read & Validate

- Parse current fields and their order
- For **add**: check field name doesn't exist, validate type, suggest position
- For **modify**: verify field exists, validate new values
- For **remove**: check for dependencies in code, filters, reports

### Step 3: Apply Changes

Use `insert_after` for positioning new fields. Update `field_order` array.

### Step 4: Update Related Files

- Client script: add/remove field handlers
- Controller: update validation/calculations
- Remind to run migrate

## Field Types

| Type | Usage | Options |
|------|-------|---------|
| Data | Short text | - |
| Text | Long text | - |
| Select | Dropdown | `\n` separated |
| Check | Checkbox | - |
| Int/Float | Numbers | - |
| Currency | Money | - |
| Date/Datetime | Dates | - |
| Link | Reference | DocType name |
| Dynamic Link | Polymorphic | Field with DocType |
| Table | Child table | Child DocType name |
| Attach | File upload | - |
| Section/Column/Tab Break | Layout | - |

## Field Properties

```json
{
  "reqd": 1, "unique": 0, "default": "value",
  "in_list_view": 1, "in_standard_filter": 1,
  "depends_on": "eval:doc.field=='value'",
  "fetch_from": "link_field.field_name",
  "read_only": 0, "hidden": 0
}
```

## Post-Change

1. `bench --site <site> migrate`
2. `bench --site <site> clear-cache`
3. Update controller/client script if logic needed
