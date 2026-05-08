---
name: scheduler-and-jobs
description: Production-grade Frappe background jobs and scheduler — queue selection, idempotency, retries, distributed locks, monitoring stuck jobs, debugging worker hangs, chunked long-running jobs. Use when designing or debugging frappe.enqueue / scheduler_events code, troubleshooting stuck jobs, or making jobs robust against retries and worker restarts. Complements server-scripts (which covers basic syntax) with the production reality.
---

# Scheduler & Background Jobs (Production)

Reference for making Frappe background jobs and scheduled tasks robust under real-world load. The `server-scripts` skill covers basic `frappe.enqueue` and `scheduler_events` syntax; this is its production-grade companion.

## Queue selection

Frappe ships three RQ queues with different timeout defaults:

| Queue | Default timeout | Use for |
|-------|-----------------|---------|
| `short` | 60 seconds | Quick fire-and-forget: send one email, update one cache key, recompute one denormalized field |
| `default` | 300 seconds (5 min) | Most normal jobs: process one document, sync a small batch |
| `long` | 1500 seconds (25 min) | Bulk imports, monthly reports, heavy data migrations |

```python
frappe.enqueue("my_app.tasks.send_one_email", queue="short", recipient="x@y.com")
frappe.enqueue("my_app.tasks.process_invoice", queue="default", invoice="SINV-001")
frappe.enqueue("my_app.tasks.monthly_aging_report", queue="long")
```

**Mismatch consequences:**
- Job on `short` that runs >60s: **killed mid-execution** with no rollback. Half-written state persists.
- Job on `long` that takes 5s: hogs a long-queue worker slot another truly-long job needs. Smaller blast radius.

When in doubt, set an explicit `timeout` and use `default`:

```python
frappe.enqueue(
    "my_app.tasks.process_invoice",
    queue="default",
    timeout=180,
    invoice="SINV-001",
)
```

## `now=True`, `enqueue_after_commit`, `is_async`

```python
frappe.enqueue(method, queue="default", now=False, enqueue_after_commit=False, is_async=True, **kwargs)
```

| Flag | What it does | When to use |
|------|--------------|-------------|
| `now=True` | Runs the function in the current process synchronously, no Redis | **Tests only.** In production it defeats the purpose of enqueueing — the request thread blocks. |
| `enqueue_after_commit=True` | Defers the enqueue until the current DB transaction commits | When you enqueue from a `validate` / `before_save` hook on a doc that's about to be saved. Without this flag, the worker may pick up the job and try to read the doc before the request thread commits — race condition. |
| `is_async=False` | Runs in the current process (similar to `now=True`) | Almost never. Use `now=True` for tests; otherwise let it queue. |

**The `enqueue_after_commit` rule:** if you call `frappe.enqueue` from any document lifecycle hook (validate, before_save, on_update, on_submit, on_cancel) and the job needs the doc to exist or have its latest state, set `enqueue_after_commit=True`. Otherwise the job races the commit.

```python
class SalesInvoice(Document):
    def on_submit(self):
        # Worker needs to see the submitted invoice — wait for commit
        frappe.enqueue(
            "my_app.tasks.send_invoice_email",
            queue="short",
            timeout=60,
            enqueue_after_commit=True,
            invoice_name=self.name,
        )
```

## Cron expressions in `scheduler_events`

The team convention is to prefer `cron:` over the named keys (`hourly`, `daily`, `weekly`, `monthly`) — explicit cron expressions are more obvious to read and grep for. The named keys are still fine for "I genuinely want this every hour" but `cron` is preferred when the cadence is anything else or when you want to see the schedule at a glance.

```python
# hooks.py — pattern from edu_quality
scheduler_events = {
    "all": [
        "edu_quality.api.student_application.get_and_schedule_pending_walkouts",
        "edu_quality.overrides_hooks.item.upload_all_imported_to_drive",
    ],
    "cron": {
        "0 * * * *":    ["edu_quality.tasks.cron"],
        "0 19 * * *":   ["edu_quality.tasks.send_bulk_notification_cmap_to_guardian"],
        "0 1 * * *":    ["edu_quality.edu_quality.scheduled_tasks.assessment_pdf_scheduler.attach_daily_assessment_pdfs"],
        "0 6 * * *":    [
            "edu_quality.tasks.schedule_birthday_greeting",
            "edu_quality.tasks.event_reminder",
        ],
        "* * * * *":    [
            "edu_quality.cmap_jobs.send_ptm_notifications_to_students",
            "edu_quality.cmap_jobs.notify_teacher_before_one_hour_job",
        ],
    },
}
```

Common patterns:

| Cron | Meaning |
|------|---------|
| `*/15 * * * *` | Every 15 minutes |
| `0 * * * *` | Top of every hour |
| `0 9 * * 1-5` | 9 AM Monday–Friday |
| `0 0 * * 0` | Midnight Sunday |
| `0 0 1 * *` | Midnight on the 1st of every month |
| `*/30 9-17 * * 1-5` | Every 30 minutes, 9 AM–5 PM, weekdays |

Scheduler runs in the `default` queue. **For long scheduled jobs, the scheduler entry point should `frappe.enqueue` to the `long` queue rather than blocking the scheduler thread** — this is the team's standard two-step pattern (see `assessment_pdf_scheduler.py`):

```python
def attach_daily_assessment_pdfs():
    """Scheduler entry point — fast handoff."""
    frappe.enqueue(
        _process_daily_assessment_pdfs,
        queue="long",
        timeout=3600,  # 1 hour
        job_name="daily_assessment_pdf_attachment",
    )
    return {"success": True, "message": "Daily Assessment PDF attachment job has been queued"}


def _process_daily_assessment_pdfs():
    # The actual work
    ...
```

Note the deterministic `job_name` — running the scheduler twice in the same window is a no-op because `frappe.enqueue` dedups jobs with the same name in the queue.

Common patterns:

| Cron | Meaning |
|------|---------|
| `*/15 * * * *` | Every 15 minutes |
| `0 * * * *` | Top of every hour |
| `0 9 * * 1-5` | 9 AM Monday–Friday |
| `0 0 * * 0` | Midnight Sunday |
| `0 0 1 * *` | Midnight on the 1st of every month |
| `*/30 9-17 * * 1-5` | Every 30 minutes, 9 AM–5 PM, weekdays |

Scheduler runs in the `default` queue. For long scheduled jobs, the scheduler invocation should `frappe.enqueue` to the `long` queue rather than blocking the scheduler thread:

```python
def daily_cleanup():
    """Scheduler entry point — fast: just enqueue the real work."""
    frappe.enqueue("my_app.tasks._do_cleanup", queue="long", timeout=1800)

def _do_cleanup():
    # The actual work
    ...
```

## Idempotency

A job is idempotent if running it twice produces the same end state as running it once. Workers crash, retries happen, scheduler windows can overlap — assume your job WILL run twice.

### Pattern 1: check before mutate

```python
def sync_customer_to_external(customer_id):
    # Has this customer already been synced today?
    today = frappe.utils.nowdate()
    if frappe.db.exists("External Sync Log", {
        "customer": customer_id,
        "sync_date": today,
        "status": "Success",
    }):
        return  # Already done — exit cleanly

    # ... do the sync ...

    frappe.get_doc({
        "doctype": "External Sync Log",
        "customer": customer_id,
        "sync_date": today,
        "status": "Success",
    }).insert(ignore_permissions=True)
    frappe.db.commit()
```

### Pattern 2: dedup via `job_name`

`frappe.enqueue` accepts a `job_name`. If a job with the same name is already in the queue or running, the new enqueue is dropped (returns `None`):

```python
frappe.enqueue(
    "my_app.tasks.recompute_customer_balance",
    queue="short",
    job_name=f"recompute-balance-{customer_id}",
    customer=customer_id,
)
```

Use stable, deterministic job names. Random suffixes defeat the dedup.

### Pattern 3: optimistic update with version check

```python
def update_inventory(item_code, expected_qty, new_qty):
    rows = frappe.db.sql(
        """UPDATE `tabBin`
           SET actual_qty = %s
           WHERE item_code = %s AND actual_qty = %s""",
        (new_qty, item_code, expected_qty),
    )
    if not rows:
        # Someone else updated it first; this run is stale
        return
```

## Distributed locks

When two workers might run the same critical section concurrently (e.g. two webhooks triggering the same recalculation), use Frappe's cache as a lock:

```python
def with_lock(key, ttl=300):
    """Poor man's lock via Redis cache. Returns True if acquired."""
    cache = frappe.cache()
    if cache.get_value(key):
        return False
    cache.set_value(key, frappe.session.user or "unknown", expires_in_sec=ttl)
    return True

def release_lock(key):
    frappe.cache().delete_value(key)


def recompute_customer_balance(customer_id):
    lock_key = f"recompute-balance:{customer_id}"
    if not with_lock(lock_key, ttl=120):
        return  # another worker is doing it
    try:
        # ... heavy recompute ...
        frappe.db.commit()
    finally:
        release_lock(lock_key)
```

This is **not** atomic — there's a tiny race between `get_value` and `set_value`. For true atomicity, use Redis SETNX directly:

```python
def acquire_lock(key, ttl=300):
    redis = frappe.cache()
    # SETNX returns 1 if set, 0 if already exists
    acquired = redis.execute_command("SET", key, "1", "NX", "EX", ttl)
    return acquired is not None
```

For most ERPNext workloads the cache-based lock is fine. Reserve SETNX for jobs that handle money or stock where double-execution matters.

## Retries

Frappe does **not** auto-retry failed jobs. The standard pattern: catch transient errors and re-enqueue with backoff.

```python
def sync_with_retry(account_id, attempt=1, max_attempts=3):
    try:
        result = call_external_api(account_id)
        save_result(account_id, result)
        frappe.db.commit()
    except (ConnectionError, TimeoutError) as e:
        if attempt >= max_attempts:
            frappe.log_error(
                title=f"Sync failed after {max_attempts} attempts: {account_id}",
                message=frappe.get_traceback(),
            )
            raise

        # Exponential backoff: 1m, 2m, 4m, ...
        delay_minutes = 2 ** (attempt - 1)
        frappe.enqueue(
            "my_app.tasks.sync_with_retry",
            queue="default",
            timeout=300,
            enqueue_after_commit=True,
            account_id=account_id,
            attempt=attempt + 1,
            max_attempts=max_attempts,
            # Note: Frappe doesn't have native delayed enqueue; you'd need
            # to schedule via cron or use the scheduler hook for true delay.
        )
```

For true delayed retries (rather than re-enqueueing immediately), use a scheduled job that polls a "Retry Queue" DocType, or upgrade to a custom RQ scheduler.

## Monitoring

```bash
# Pending jobs in all queues for a site
bench --site mysite show-pending-jobs

# Scheduler health (jobs per minute, last run, errors)
bench --site mysite scheduler-events
bench --site mysite doctor

# Restart workers (clears any stuck job state in worker memory)
bench restart

# Watch worker output live (bench start mode)
tail -F sites/mysite/logs/worker.log
tail -F sites/mysite/logs/scheduler.log
```

The `frappe-debug` skill in this plugin starts the bench-error-log monitor, which surfaces worker errors live during a debug session.

For deeper introspection, RQ has a CLI:

```bash
# Inside bench env
bench --site mysite execute "frappe.utils.background_jobs.get_workers"

# Or via rq-info if installed
rq info -u redis://localhost:11000
```

## Debugging stuck jobs

Symptoms: a job is queued but never finishes, or worker process is alive but doing nothing.

1. **Check pending-jobs** — does the job appear?
   ```bash
   bench --site mysite show-pending-jobs
   ```

2. **Check worker logs** for the job's start line — did it begin?
   ```bash
   grep "<job_id>" sites/mysite/logs/worker.log
   ```

3. **Worker process state** — is it CPU-bound or stuck on I/O?
   ```bash
   ps aux | grep rq
   strace -p <pid>          # what syscall is it blocked on?
   py-spy dump --pid <pid>  # what Python frame is it in? (best tool)
   ```

4. **Cancel and restart**:
   ```bash
   bench --site mysite cancel-running-jobs
   bench restart-workers
   ```

5. **Common causes**:
   - Job acquired a lock and crashed before releasing → next run blocks forever
   - Job did `frappe.db.commit()` mid-loop with no rollback handling, leaving DB in odd state
   - Job is waiting on an external API with no timeout
   - Worker memory leak from a long-running job that loaded too much into memory; restart workers

## Memory leaks

Workers don't restart between jobs. A job that leaks (e.g. holds a reference to a 100MB result set) leaves that memory allocated for the next job.

Mitigations:
- For known-heavy jobs, set RQ to recycle the worker after N jobs (`bench config set worker.max_jobs_per_worker 100`).
- Restart workers daily via cron: `bench restart-workers`.
- Avoid global caches in worker code; use `frappe.cache()` (Redis) instead.

## Long-running jobs: chunking + progress

Jobs >5 minutes should chunk and publish progress so the user (or admin) can see they're alive:

```python
def reindex_all_customers():
    customers = frappe.get_all("Customer", pluck="name", limit_page_length=0)
    total = len(customers)
    chunk_size = 200
    user = frappe.session.user

    for i in range(0, total, chunk_size):
        chunk = customers[i:i + chunk_size]
        for customer in chunk:
            try:
                _reindex_one(customer)
            except Exception:
                frappe.log_error(title=f"reindex failed: {customer}")
                # Continue with the rest — don't let one bad row kill the run

        frappe.db.commit()  # commit each chunk; partial progress is preserved on crash

        frappe.publish_realtime(
            "reindex_progress",
            {"current": i + len(chunk), "total": total},
            user=user,
        )

    frappe.publish_realtime("reindex_done", {"total": total}, user=user)
```

Why commit per chunk: if the worker dies on chunk 8 of 50, you lose chunk 8 only — chunks 1–7 are durably written. Without per-chunk commits, the entire run rolls back.

## Common anti-patterns

| Anti-pattern | Why it bites |
|--------------|--------------|
| Job mutates `frappe.local.user` and doesn't restore | Next job in the worker runs as that user |
| Job sets `frappe.flags.ignore_permissions = True` and doesn't reset | Subsequent jobs bypass perms unintentionally |
| Job depends on `frappe.session.user` | `session.user` is the user who enqueued — usually not what you want for scheduled jobs |
| Job calls `frappe.db.commit()` from inside a `validate()` controller hook (because it called `enqueue(now=True)`) | Breaks the calling request's transaction |
| Job has no `frappe.db.commit()` at the end | Changes lost on worker restart |
| Job catches all exceptions and silently swallows | Real failures invisible until the error log fills |
| Scheduled job enqueues itself with `now=False` | Self-enqueueing loops can stack; use `now=True` only if synchronous is intended |
| Cron `* * * * *` (every minute) doing real work | Use the `scheduler_events: "all"` slot or queue to `default` |

## Example: robust nightly sync

A nightly job that pulls from an external API, processes per-customer, is idempotent, retries on transient failures, locks against concurrent runs, and reports progress:

```python
# my_app/hooks.py
scheduler_events = {
    "cron": {
        "0 2 * * *": ["my_app.tasks.nightly_sync_kickoff"],
    },
}

# my_app/tasks.py
import frappe
from frappe.utils import nowdate, add_to_date


def nightly_sync_kickoff():
    """Scheduler entry — fast handoff to the long queue."""
    frappe.enqueue(
        "my_app.tasks._nightly_sync",
        queue="long",
        timeout=3600,
        job_name=f"nightly-sync-{nowdate()}",  # dedup on the date
    )


def _nightly_sync():
    lock_key = f"nightly-sync:{nowdate()}"

    # Acquire run lock — prevents overlap if yesterday's run is still going
    if not frappe.cache().execute_command("SET", lock_key, "1", "NX", "EX", 7200):
        frappe.log_error(title="nightly_sync skipped: previous run still active")
        return

    try:
        accounts = frappe.get_all(
            "External Account",
            filters={"sync_enabled": 1},
            pluck="name",
        )
        total = len(accounts)
        succeeded = failed = 0

        for i, account_id in enumerate(accounts):
            # Idempotency: skip if already synced today
            today_log = frappe.db.exists("External Sync Log", {
                "account": account_id,
                "sync_date": nowdate(),
                "status": "Success",
            })
            if today_log:
                succeeded += 1
                continue

            try:
                _sync_one_account(account_id)
                _log_sync(account_id, status="Success")
                succeeded += 1
            except (ConnectionError, TimeoutError) as e:
                # Transient — schedule a retry tomorrow morning
                _log_sync(account_id, status="Retry", error=str(e))
                _enqueue_retry(account_id)
                failed += 1
            except Exception:
                # Permanent — log and move on
                frappe.log_error(
                    title=f"nightly_sync permanent failure: {account_id}",
                    message=frappe.get_traceback(),
                )
                _log_sync(account_id, status="Failed", error=frappe.get_traceback())
                failed += 1

            # Commit per-account so partial progress is durable
            frappe.db.commit()

            if (i + 1) % 50 == 0:
                # Periodic progress log
                frappe.logger().info(f"nightly_sync: {i + 1}/{total} processed")

        frappe.logger().info(
            f"nightly_sync done: {succeeded} succeeded, {failed} failed of {total}"
        )

    finally:
        frappe.cache().delete_value(lock_key)


def _sync_one_account(account_id):
    # ... actual API call + DB writes ...
    pass


def _log_sync(account_id, status, error=None):
    frappe.get_doc({
        "doctype": "External Sync Log",
        "account": account_id,
        "sync_date": nowdate(),
        "status": status,
        "error_message": error,
    }).insert(ignore_permissions=True)


def _enqueue_retry(account_id):
    """Re-enqueue this account for a one-off retry in 30 min."""
    frappe.enqueue(
        "my_app.tasks._sync_one_account",
        queue="default",
        timeout=300,
        job_name=f"sync-retry-{account_id}-{nowdate()}",  # dedup on (account, date)
        account_id=account_id,
    )
```

## See also

- `server-scripts` skill — basic `frappe.enqueue` and `scheduler_events` syntax
- `bench-commands` skill — `bench show-pending-jobs`, `bench restart-workers`, `bench doctor`
- `frappe-debug` skill — bench error log monitor catches worker exceptions live
- `/frappe-perf` command — runs `bench doctor` + `show-pending-jobs` and surfaces stuck jobs
- `references/frappe-python.md` (in `frappe-review` skill) — review-time checks for queue mismatches, missing idempotency, `now=True` in production
