---
title: Agent execution specification
description: A minimal execution contract for discover-and-run agents.
---

:::note[Draft for review]
This draft contains only the behavior discussed. [Unresolved details](./gaps/) are listed separately. See the [sequence diagram](./sequence/) for the execution flow.
:::

## Purpose and scope

The specification defines agents that discover ready work and execute individual work items. Developer simplicity is a core design constraint.

An agent provides:

- `discover.sh`
- `run.sh`
- Optional `claim.sh`
- Optional `agent.yaml`

The platform handles scheduling, execution, internal claims, concurrency, timeouts, and observability. Credentials and environment provisioning are assumed to be supplied by the platform and are outside this initial specification. Cron is a possible implementation, not part of the contract.

## Application and agent configuration

An application corresponds to a repository and defines its repository reference, Git ref, agents directory, named container images, and default image.

The platform recursively discovers agent directories containing `discover.sh` and `run.sh`. An agent can use the application’s default image without an `agent.yaml`.

An optional `agent.yaml` can select a named application image:

```yaml
image: worker
```

The selected image runs the agent’s scripts.

The application provides defaults for the discovery interval and `maxConcurrentRuns`. Agents can override either. `maxConcurrentRuns` limits both the number of items returned by discovery and the number of active runs within a cycle.

Scripts execute with the agent directory as their working directory. Scripts for an attempt come from the same repository revision. The platform supplies agent identity and a unique attempt ID through environment variables; exact names remain unresolved.

## Work-item envelope

```json
{"id":"work-123","data":{"anything":"the agent needs"}}
```

Both fields are required:

- `id`: a nonempty string, opaque to the platform and scoped to the agent.
- `data`: any JSON value, interpreted by the developer’s scripts.

The developer determines work identity, including whether a revision belongs in the ID.

A previously successful ID may run again if discovery returns it. Discovery indicates that work currently needs execution; the developer owns determining completion and stopping completed work from appearing.

## Agent cycle and scheduling

An agent cycle consists of discovery followed by execution of the accepted items.

Only one cycle for an agent may be active at a time. The cycle stays active until its items have finished or been skipped and bounded cleanup has completed.

A scheduled wake-up during an active cycle is skipped. It is not queued for later. After completion, the agent waits for its next scheduled wake-up.

Different agents may have active cycles simultaneously.

## Discovery

`discover.sh` is read-only with respect to the work.

The platform supplies a limit equal to `maxConcurrentRuns`. Discovery returns no more than that many items that appear ready to execute, based on the information available to it.

Discovery writes newline-delimited JSON to stdout: one work-item envelope per line. No work means empty stdout. Diagnostic logs go to stderr.

The platform reads the complete output and requires a successful exit before accepting any items. Streaming execution is not specified.

The entire discovery attempt is rejected if:

- The script fails or times out.
- Any output line is malformed.
- An envelope is invalid or missing a required field.
- An ID repeats.
- The item count exceeds the supplied limit.

No items run from rejected discovery output. The platform records the failure and waits for the next scheduled cycle.

Readiness may change after discovery. Claims provide the subsequent ownership check. Items that cannot be claimed are skipped without fetching replacements during that cycle.

## Execution

`run.sh` receives one work-item envelope on stdin.

The implementation must be idempotent and tolerate work becoming irrelevant before execution.

Exit zero means the item was handled, including when nothing remains to do. A nonzero exit means the attempt failed.

One failed or timed-out run does not cancel other runs in the cycle. Future discovery determines whether an item needs another attempt.

## Claims

The platform always acquires an internal work-item claim before invoking an optional external claim hook.

Only one valid internal claim may exist for an agent and work-item ID within the platform’s coordination scope.

`claim.sh` supplements internal claiming; it does not replace it. It supports three operations:

```text
claim.sh acquire
claim.sh renew
claim.sh release
```

If configured, external acquisition must succeed before `run.sh` starts.

External coordination may be best effort. A shared label, for example, does not guarantee atomic acquisition across outside workers. Adding ownership metadata helps identify attempts but does not itself eliminate races. Those limitations must be documented by the integration.

### Acquisition

`claim.sh acquire` receives the work-item envelope on stdin. The platform also supplies the attempt ID.

A successful acquisition returns:

```json
{"status":"acquired","token":"opaque-value","lease_seconds":60}
```

An already claimed item returns:

```json
{"status":"busy"}
```

`token` identifies the external ownership for this attempt.

A positive `lease_seconds` requires renewal. `null` means no automatic expiration and no renewal calls. Release is still called after execution; abandoned-claim recovery remains the developer’s responsibility.

Acquisition succeeds only when the hook exits zero and returns a valid `acquired` response.

If acquisition returns `busy`, execution is skipped and the internal claim is released.

If acquisition times out, exits nonzero, or returns invalid output:

- The platform must not invoke `run`.
- The platform must not retry acquisition within that attempt.
- Remaining hook execution must be terminated before the internal claim is released.
- The platform records the acquisition failure.
- Without a valid ownership token, the platform does not call external release.

External changes may have occurred despite failure. Recovery of abandoned external claims belongs to the hook implementer and may use expiration or manual cleanup.

### Renewal and ownership loss

Renewal receives the work item and ownership token, with the same attempt ID available.

The platform renews claims while execution is active.

External renewal has two semantic outcomes:

- Renewed: supplies a new lease duration.
- Lost: ownership is gone, so the platform immediately attempts to stop the run.

A nonzero exit means renewal could not be confirmed. The platform may retry while the existing lease remains valid. If the lease expires, the platform attempts to stop the run.

Ownership loss does not guarantee immediate cessation of execution. Stale execution may overlap a later attempt.

### Release

Release receives the work item and ownership token, with the same attempt ID available.

After a run exits, successfully or otherwise, the platform calls external release before releasing its internal claim.

Exit zero means released or already gone. Nonzero means cleanup failed.

Release must be safe to repeat and must not remove another attempt’s claim. A shared marker alone may be insufficient to satisfy that requirement.

Cleanup failures are recorded separately from the run’s outcome. Retries are bounded so cleanup cannot hold the cycle open indefinitely. External markers may remain and require developer cleanup.

## Timeouts

The agreed defaults are:

| Operation | Default |
| --- | ---: |
| Discovery | 5 minutes |
| Individual run | 3 hours |
| Individual claim-hook call | 30 seconds |
| Graceful termination period | 30 seconds |

These are configurable platform defaults; run timeout can be overridden per agent.

On timeout, the platform attempts termination and records failure. After the termination period, it forcibly terminates the relevant execution environment.

Claims are retained during shutdown rather than deliberately released while execution is still terminating. Ownership may nevertheless expire or be lost.

## Events and logs

Scripts may emit domain events to stderr using the agreed prefix:

```text
@agent {"event":"pull_request.opened","data":{"url":"https://..."}}
```

`event` is a required, developer-defined string. `data` is optional domain-specific JSON.

The platform attaches timestamp, agent ID, work-item ID, and attempt ID where applicable. It also records execution started, succeeded, and failed events.

These events support a common activity timeline and grouping by event name. The specification does not require progress percentages or interpretation of domain-specific event meaning.

The platform captures execution logs subject to documented storage limits and retention periods, and makes retained logs available.

A malformed prefixed event produces a platform warning event without failing execution. Ordinary text is not a parsing error. Malformed lines remain ordinary output subject to log limits.

Truncation must be visible. Repeated parsing warnings may be combined. Structured events also have documented size and volume limits.
