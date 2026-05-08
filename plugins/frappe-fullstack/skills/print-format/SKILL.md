---
name: print-format
description: Frappe Print Format design — Jinja templates for receipts, certificates, invoices; PDF generation; page handling; multi-currency; wkhtmltopdf rendering. Use when designing or modifying a Print Format, troubleshooting PDF rendering, or formatting documents for print. Follows the team convention of self-contained formats — no `letter_head`/`footer` injection.
---

# Frappe Print Format Reference

Reference for designing Print Formats in Frappe v14+, aligned with the team's edu_quality conventions: **self-contained formats** (no `letter_head` / `footer` injection), `wkhtmltopdf` pinned as the PDF engine, `dd-MM-yyyy` date format, and `Rs.` instead of `₹` to dodge font issues.

## Team conventions

These are the rules, not suggestions. New formats follow them; reviews flag deviations.

1. **Do NOT use `{{ letter_head }}` or `{{ footer }}`.** Every print format is self-contained: header (with logo/QR if needed), body, signature block — all inline in the template. The Letter Head DocType is not part of our print pipeline.
2. **Pin `pdf_generator: "wkhtmltopdf"`** in the Print Format JSON. Don't rely on the system default; v15 introduced Chromium and the team has not adopted it.
3. **Date format: `formatdate(doc.field, "dd-MM-yyyy")`** everywhere. No raw date rendering.
4. **Currency: `fmt_money(amt, currency="INR") | replace("₹", "Rs.")`** or hardcode `Rs.` directly. The wkhtml fonts we ship don't reliably render `₹`; the team standard is `Rs.`.
5. **Margins `15.0` all around**, `page_number: "Hide"`, `standard: "Yes"`, `print_format_type: "Jinja"`.
6. **`module` set to the module name**. Files live at `{app}/{module}/print_format/{slug}/{slug}.json`.

## When to use which type

Frappe supports four ways to define a print format:

| Type | Where it lives | When to use |
|------|----------------|-------------|
| **Standard** | Auto-generated from DocType fields | Quick default for new DocTypes; never edit |
| **Custom (Print Format Builder)** | DB row with `format_data` JSON | Non-developers customizing layout via the UI; commit the JSON via fixtures |
| **Jinja (file-based)** | DB row with raw `html`, exported as JSON | Developers; full control; goes through git |
| **Server-side** | Controller method `get_print_html` | Programmatic generation; e.g. dynamic per-customer layouts |

For anything code-reviewed and version-controlled, use **Jinja** (`custom_format: 1` with hand-written `html`). The Print Format Builder (`custom_format: 0` with `format_data`) is fine for layout-only formats but its JSON isn't readable in diffs.

## File layout

```
my_app/
└── my_module/
    └── print_format/
        └── fee_receipt/
            ├── __init__.py
            └── fee_receipt.json     # Print Format DocType row, exported via bench export-fixtures
```

The HTML lives **inside the JSON** in the `html` field. We don't ship separate `.html` files — keep everything in one fixture row so it round-trips through `bench export-fixtures`.

Register in `hooks.py`:
```python
fixtures = [
    {"dt": "Print Format", "filters": [["module", "=", "Edu Quality"]]}
]
```

## Manifest field reference

A typical hand-written Jinja format JSON:

```json
{
    "doctype": "Print Format",
    "name": "Fee Receipt",
    "doc_type": "Payment Entry",
    "module": "Fees",
    "print_format_type": "Jinja",
    "custom_format": 1,
    "standard": "Yes",
    "pdf_generator": "wkhtmltopdf",
    "default_print_language": "en",
    "page_number": "Hide",
    "font_size": 14,
    "margin_top": 15.0,
    "margin_bottom": 15.0,
    "margin_left": 15.0,
    "margin_right": 15.0,
    "html": "<style>...</style><table>...</table>"
}
```

| Field | Convention |
|-------|------------|
| `doc_type` | The DocType this prints |
| `module` | Sentence Case module name (e.g. `"Fees"`, `"Edu Quality"`) — must match an installed module |
| `print_format_type` | `"Jinja"` always |
| `custom_format` | `1` for hand-written `html`; `0` if using `format_data` (Builder) |
| `standard` | `"Yes"` for shipped formats |
| `pdf_generator` | `"wkhtmltopdf"` pinned |
| `font_size` | `14` is the team default; `16` for receipts |
| `margin_*` | `15.0` all four sides |
| `page_number` | `"Hide"` |

## Jinja context

Inside the template, these variables are available:

| Variable | What it is |
|----------|------------|
| `doc` | The full document being printed (with all child tables) |
| `frappe` | The full `frappe` namespace — `frappe.utils.*`, `frappe.db.*` |
| `_` | Translation function — `_("Total")` |
| `print_settings` | The `Print Settings` Single doc |
| `lang` | Language code (`"en"`, `"hi"`, ...) |

Note `letter_head` and `footer` are populated by Frappe but the team convention is **don't reference them** — every format is self-contained.

## Inline DB lookups

Templates pulling from related DocTypes use `frappe.db.get_value` directly in Jinja. This is the team idiom for receipts that need data the Payment Entry doesn't carry:

```jinja
{% set reference_number = frappe.db.get_value('Student', doc.party, 'reference_number') %}
{% set program = frappe.db.get_value(doc.reference_doctype, doc.reference_name, 'program') %}
{% set class = frappe.db.get_value('Program', program, 'program_name') %}

<p><b>Receipt No:</b> {{ doc.name }}</p>
<p><b>Reference:</b> {{ reference_number }}</p>
<p><b>Class:</b> {{ class }}</p>
```

Each `frappe.db.get_value` is one query. For more than 5–6 lookups in a template, do them in a controller `get_context` instead — Jinja loops with DB lookups inside become N+1 problems on bulk print runs.

## Currency formatting

The team standard is `Rs.` (not `₹`) for INR. Two ways:

```jinja
{# Option 1 — hardcode prefix #}
<td>Rs. {{ "{:,.2f}".format(item.amount) }}</td>

{# Option 2 — fmt_money with replace #}
<td>{{ frappe.utils.fmt_money(item.amount, currency="INR") | replace("₹", "Rs.") }}</td>
```

Option 2 picks up the precision configured on the Currency doctype; Option 1 is simpler when precision is fixed at 2.

For multi-currency (rare in our stack — almost everything is INR), pass the currency from the doc:
```jinja
{{ frappe.utils.fmt_money(doc.grand_total, currency=doc.currency) | replace("₹", "Rs.") }}
```

In-words (common on receipts):
```jinja
{{ frappe.utils.money_in_words(doc.grand_total, "INR") }}
```

## Date and time formatting

The team convention is `dd-MM-yyyy`:

```jinja
{{ frappe.utils.formatdate(doc.posting_date, "dd-MM-yyyy") }}
{# → "15-01-2026" #}
```

Other formats when needed:
```jinja
{{ frappe.utils.formatdate(doc.posting_date, "dd MMM yyyy") }}      {# 15 Jan 2026 #}
{{ frappe.utils.format_time(doc.posting_time, "HH:mm") }}            {# 14:30 #}
{{ frappe.utils.format_datetime(doc.creation, "dd-MM-yyyy HH:mm") }} {# 15-01-2026 14:30 #}

{# Quick "today" stamp inside the template #}
{{ frappe.utils.nowdate() }}
```

Never render `doc.posting_date` raw — it's a `datetime.date` object and prints inconsistently across PDF engines.

## Page breaks and table flow

Force a page break:
```html
<div class="page-break"></div>
```

For tables that flow across pages, repeat the header by using a proper `<thead>`:

```html
<table>
  <thead>
    <tr><th>Item</th><th>Qty</th><th>Rate</th><th>Amount</th></tr>
  </thead>
  <tbody>
    {% for row in doc.items %}
    <tr style="page-break-inside: avoid;">
      <td>{{ row.item_code }}</td>
      <td class="text-right">{{ row.qty }}</td>
      <td class="text-right">Rs. {{ "{:,.2f}".format(row.rate) }}</td>
      <td class="text-right">Rs. {{ "{:,.2f}".format(row.amount) }}</td>
    </tr>
    {% endfor %}
  </tbody>
</table>
```

For a signature/footer block that should never split:
```html
<div style="page-break-inside: avoid; margin-top: 36pt;">
  <p>For {{ frappe.db.get_value("Company", doc.company, "company_name") }}</p>
  <div style="height: 36pt;"></div>
  <hr>
  <small>Authorized Signatory</small>
</div>
```

## Custom CSS

Inline at the top of the template's `html`. Frappe wraps the body so a `<head>` block is ignored — `<style>` must be in the body.

```html
<style>
  table, th, td, tr {
    font-size: 16px;
    border: 2px solid black;
  }
  th {
    font-weight: bold;
    color: #000;
    background-color: #D3D3D3;
  }
  .description { text-align: center; }
  .text-right { text-align: right; }
  p { font-size: 16px; }
  @media print {
    .no-print { display: none; }
  }
</style>
```

For images, use absolute URLs (the PDF engine fetches them in a separate process):
```html
<img width="150" height="150" src="{{ doc.custom_qr_code_base }}" />
<img src="{{ frappe.utils.get_url() }}/files/logo.png" />
```

A bare `/files/logo.png` works in browser preview but fails in PDF generation — wkhtmltopdf has a separate fetcher that doesn't share cookies/session.

## wkhtmltopdf gotchas

We pin wkhtmltopdf via `pdf_generator: "wkhtmltopdf"`. It's a Webkit-2015-era engine with quirks:

| Quirk | Workaround |
|-------|------------|
| No CSS Grid / modern flexbox | Use tables for layout |
| Limited `@font-face` support | Stick to system fonts; if you need a custom font, the team standard is to NOT depend on it for symbols |
| Renders `₹` as `?` with most fonts | Use `Rs.` (team standard) or pick a Unicode-broad font like Noto/DejaVu |
| `<style>` in `<head>` ignored | Put `<style>` in the body |
| Relative URLs for images don't fetch | Use `{{ frappe.utils.get_url() }}/...` for absolute URLs |
| `page-break-inside: avoid` is honored | Use it on rows and signature blocks |
| Async images can race with rendering | Set explicit `width` and `height` on `<img>` |

## Server-side print formats

For dynamic generation (different layout per customer tier, conditional sections beyond Jinja), define `get_print_html` on the controller:

```python
class FeeReceipt(Document):
    def get_print_html(self, print_format=None, no_letterhead=0, **kwargs):
        if self.school_type == "International":
            template = "templates/print_formats/intl_receipt.html"
        else:
            template = "templates/print_formats/standard_receipt.html"

        return frappe.render_template(template, {"doc": self})
```

The Print Format DocType row should still exist with `print_format_type: "Server"` so it appears in the dropdown. The `no_letterhead` parameter is part of the contract but the team always operates as if it's true — letter heads are never rendered.

## Common gotchas

- **Child table rows truncated in PDF** — usually a `page-break-inside: avoid` missing on the row, or a `overflow: hidden` cutting off content past the page.
- **CSS not applied in PDF** — paths must be absolute (`{{ frappe.utils.get_url() }}/path`); `<style>` blocks must be in the body, not a `<head>`.
- **`₹` rendered as `?`** — use `Rs.` per team convention.
- **Date in template shows `2026-01-15 00:00:00`** — using raw `doc.posting_date` instead of `formatdate(doc.posting_date, "dd-MM-yyyy")`.
- **Repeating header missing on page 2+** — table missing the `<thead>` element.
- **Logo missing in printed PDF but visible in preview** — relative URL. Use `{{ frappe.utils.get_url() }}/files/logo.png`.
- **Print Format Builder format keeps reverting on migrate** — DB row is being re-imported from fixtures every migration. Pick one source of truth: either committed fixture or hand-edited DB.
- **`format_data` JSON has stale field references after a DocType change** — the Builder embeds field names; rename a field and the format breaks silently. Check after any DocType edit.

## Example: fee receipt (matches edu_quality style)

```html
{# fees/print_format/fee_receipt/fee_receipt.html — embedded in the JSON's `html` field #}
<style>
  table, th, td, tr {
    font-size: 16px;
    border: 2px solid black;
    border-collapse: collapse;
  }
  th {
    font-weight: bold;
    color: #000;
    background-color: #D3D3D3;
    padding: 6px;
  }
  td { padding: 6px; }
  .description { text-align: center; }
  .text-right { text-align: right; }
  p { font-size: 16px; }
</style>

{% set reference_number = frappe.db.get_value('Student', doc.party, 'reference_number') %}
{% set program_field = 'program' if (doc.reference_doctype == "Fees" or doc.reference_doctype == "Student Applicant") else "next_program" %}
{% set program = frappe.db.get_value(doc.reference_doctype, doc.reference_name, program_field) %}
{% set class_name = frappe.db.get_value('Program', program, 'program_name') %}
{% set yr = frappe.db.get_value(doc.reference_doctype, doc.reference_name, 'academic_year') %}

<table style="width: 100%; border: none;">
  <tr style="border: none;">
    <td style="border: none; vertical-align: top;">
      <p><b>Receipt No:</b> {{ doc.name }}</p>
      <p><b>Reference No:</b> {{ reference_number }}</p>
      <p><b>Class:</b> {{ class_name }}</p>
      <p><b>Academic Year:</b> {{ yr }}</p>
    </td>
    <td style="border: none; vertical-align: top;">
      {% set fname = frappe.db.get_value('Student', doc.party, 'first_name') or '' %}
      {% set lname = frappe.db.get_value('Student', doc.party, 'last_name') or '' %}
      <p><b>Date:</b> {{ frappe.utils.formatdate(doc.posting_date, "dd-MM-yyyy") }}</p>
      <p><b>Name:</b> {{ fname ~ ' ' ~ lname }}</p>
      <p><b>Installment:</b> {{ doc.get_payment_term() }}</p>
    </td>
  </tr>
</table>

<table style="width: 100%; margin-top: 12px;">
  <tr>
    <th>Fee Category</th>
    <th class="text-right">Amount</th>
  </tr>
  {% for i in doc.get_components() %}
    {% if i.custom_company == doc.company %}
      {% set display_name = frappe.db.get_value("Fee Category", i.fees_category, 'display_name') %}
      <tr>
        <td>{{ display_name or i.fees_category }}</td>
        <td class="text-right">Rs. {{ "{:,.2f}".format(i.amount) }}</td>
      </tr>
    {% endif %}
  {% endfor %}
  <tr>
    <td><b>Total</b></td>
    <td class="text-right"><b>{{ doc.get_formatted_total() | replace("₹", "Rs.") }}</b></td>
  </tr>
</table>

{% set transaction_id = frappe.db.get_value('Payment Request', {'name': doc.reference_no}, 'transaction_id') %}
{% set formatted_amount = frappe.utils.fmt_money(doc.unallocated_amount, currency="INR") | replace("₹", "Rs.") %}

<p class="description" style="margin-top: 18px;">
  Payment of {{ formatted_amount }} received by {{ doc.mode_of_payment }}
</p>

{% if transaction_id %}
  <p class="description">(Payment Gateway ID: {{ transaction_id }}) dated {{ frappe.utils.formatdate(doc.posting_date, "dd-MM-yyyy") }}</p>
{% else %}
  <p class="description">(Payment Reference No: {{ doc.reference_no }}) dated {{ frappe.utils.formatdate(doc.posting_date, "dd-MM-yyyy") }}</p>
{% endif %}

<p class="description">Subject to credit of amount by the relevant bank into our account.</p>
<p class="description">Electronically generated receipt. Does not require a signature.</p>
```

## See also

- `frappe-api` skill — for `frappe.utils.*` reference
- `references/doctype-json.md` (in `frappe-review` skill) — for DocType field types referenced in templates
- `bench-commands` skill — `bench export-fixtures` to commit your Print Format DocType row
