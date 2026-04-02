---
name: frappe-test
description: Run Frappe tests with various options including specific DocTypes, modules, apps, and coverage reporting
argument-hint: "app --doctype Name --module Name --coverage"
allowed-tools: Bash, Read, Grep, Glob
---

# Run Frappe Tests

Execute Frappe test suites with filtering and reporting options.

## Arguments

Parse the user's input: $ARGUMENTS

- **app_name**: (Optional) App to test
- **--doctype**: Test specific DocType
- **--module**: Test specific module
- **--coverage**: Generate coverage report
- **--failfast**: Stop on first failure

## Process

### Step 1: Detect Environment

```bash
cat sites/currentsite.txt 2>/dev/null || echo "No default site"
ls apps/
```

### Step 2: Run Tests

| Scope | Command |
|-------|---------|
| All tests | `bench --site <site> run-tests` |
| App | `bench --site <site> run-tests --app my_app` |
| Module | `bench --site <site> run-tests --module my_app.my_module.doctype.my_doctype` |
| DocType | `bench --site <site> run-tests --doctype "My DocType"` |
| With coverage | `bench --site <site> run-tests --app my_app --coverage` |
| Single test | `bench --site <site> run-tests --module <path> --test test_method_name` |
| Verbose | Add `-v` flag |

### Step 3: Analyze Results

Parse output for: passed, failed, errors, skipped, coverage percentage.

## Writing Tests

```python
import frappe
from frappe.tests.utils import FrappeTestCase

class TestMyDocType(FrappeTestCase):
    def setUp(self):
        self.doc = make_test_doc()

    def tearDown(self):
        frappe.db.rollback()

    def test_create_document(self):
        doc = frappe.get_doc({"doctype": "My DocType", "field1": "value1"})
        doc.insert()
        self.assertTrue(doc.name)

    def test_validate_required_field(self):
        doc = frappe.get_doc({"doctype": "My DocType"})
        with self.assertRaises(frappe.MandatoryError):
            doc.insert()
```

## Common Patterns

- **Test permissions**: `frappe.set_user("test@example.com")` then assert `PermissionError`
- **Test with settings**: Use `change_settings` context manager
- **Test fixtures**: Create `test_records.json` in DocType directory
- **Debug**: Run in bench console with `test.setUp(); test.test_method()`

## Output

After running: summary (passed/failed/errors), failed test details, coverage %, fix suggestions.
