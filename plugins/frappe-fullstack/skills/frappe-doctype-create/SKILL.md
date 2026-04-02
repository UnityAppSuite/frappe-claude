---
name: frappe-doctype-create
description: Create a new Frappe DocType with complete scaffolding including JSON definition, Python controller, JavaScript client script, and tests
argument-hint: "DocType Name module_name --child --single --submittable"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Create Frappe DocType

Create a new DocType in a Frappe application with all necessary files.

## Arguments

Parse the user's input: $ARGUMENTS

- **doctype_name**: Name of the DocType (e.g., "Project Task", "Customer Feedback")
- **module_name**: (Optional) Module to create DocType in
- **--child**: Create as child table (istable=1)
- **--single**: Create as Single DocType (issingle=1)
- **--submittable**: Create as submittable document (is_submittable=1)

## Process

### Step 1: Discover Project Structure

1. Find the Frappe app: `find . -name "hooks.py" -path "*/apps/*" | head -5`
2. Read hooks.py for app structure
3. Check modules.txt for available modules
4. If module not specified, ask user

### Step 2: Create Directory Structure

Convert DocType name to snake_case directory name and create:
```bash
mkdir -p <app>/<module>/doctype/<doctype_dir>
touch <app>/<module>/doctype/<doctype_dir>/__init__.py
```

### Step 3: Ask About Fields

Suggest fields based on DocType name:
- **Status field**: Draft -> Active -> Completed
- **Date range**: start_date, end_date
- **Amount fields**: qty, rate, amount, total
- **References**: customer, supplier, user links

### Step 4: Create Files

**DocType JSON** with fields, permissions, naming, sort configuration.

**Python Controller**:
```python
import frappe
from frappe import _
from frappe.model.document import Document

class <ClassName>(Document):
    def validate(self):
        pass
```

**JavaScript Client Script**:
```javascript
frappe.ui.form.on('<DocType Name>', {
    refresh: function(frm) { },
    validate: function(frm) { }
});
```

**Test File**:
```python
import frappe
from frappe.tests.utils import FrappeTestCase

class Test<ClassName>(FrappeTestCase):
    def test_create_document(self):
        doc = frappe.get_doc({"doctype": "<DocType Name>"})
        doc.insert()
        self.assertTrue(doc.name)
```

### Step 5: Migrate

Remind user: `bench --site <sitename> migrate`

## Field Type Quick Reference

| Data | Field Type | Notes |
|------|------------|-------|
| Text (short) | Data | Max 140 chars |
| Text (long) | Text | Unlimited |
| Number | Int/Float | Use Float for decimals |
| Money | Currency | Company currency aware |
| Date | Date/Datetime | |
| Yes/No | Check | Checkbox |
| Dropdown | Select | Options separated by \n |
| Reference | Link | options = DocType name |
| Child items | Table | options = Child DocType |
| File | Attach | Single file |
| Image | Attach Image | With preview |

## Output

After completion, provide:
1. Summary of files created
2. List of fields added
3. Next steps: migrate, customize layout, add logic
