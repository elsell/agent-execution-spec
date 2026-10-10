---
title: Terminology
description: Shared language for applications, agents, cycles, work items, and the platform that runs them.
---

An **application** groups repository configuration and agents. An **agent** is the developer-provided bundle of scripts and optional configuration. An **agent cycle** is one scheduled invocation of discovery followed by processing its accepted work items.

## Platform-owned components

| Term | Meaning in this specification |
| --- | --- |
| **Scheduler** | The platform-owned component responsible for when an agent cycle is triggered. It invokes the execution harness. Scheduling may use cron, a Go program, a Windows service, or another implementation. |
| **Execution harness** | The platform-owned component invoked by the scheduler to execute an agent cycle. It calls `discover.sh`, validates discovery output, coordinates claims and concurrent `run.sh` invocations, applies timeouts and cleanup, and integrates with platform events, logging, and retention. |
| **Platform** | The broader system that provides the scheduler, execution harness, and supporting capabilities. |

**Execution harness** is the term used throughout this specification. The execution harness is supplied by the platform; the developer supplies the agent scripts that it invokes.

These are distinct responsibilities, not a requirement for separate services, processes, or executables. A execution harness script is one possible implementation. The scheduling technology and the execution harness's implementation language remain unspecified.

The relationship is: **scheduler → execution harness → developer-provided agent scripts**. The execution harness carries out a cycle; it is not the agent definition or an individual `run.sh` invocation.

## Application, agent, and cycle

| Term | Meaning in this specification |
| --- | --- |
| **Application** | The repository-level configuration: repository, Git ref, agents directory, named images, and defaults for its agents. The exact declarative schema remains open. |
| **Agent** | A directory containing `discover.sh` and `run.sh`, with optional `claim.sh` and `agent.yaml`. This names the developer-provided definition, rather than a particular running process. |
| **Agent cycle** | One invocation of discovery and the processing of its accepted items, through completion or skipping and bounded cleanup. This is the unit that must not overlap for the same agent. |
| **Work item** | One piece of work described by an envelope with `id` and `data`. The developer defines its domain meaning. |
| **Work-item ID** | The opaque, nonempty string used to identify work within an agent’s scope. It does not identify a particular execution. |
| **Run** | One invocation of `run.sh` for one work item. `maxConcurrentRuns` counts active runs within a cycle. |
| **Attempt** | An effort to process a work item, including acquiring the required claims, running it if acquired, and cleanup. An acquisition failure can end an attempt before `run.sh` starts. |
| **Attempt ID** | The platform-provided identifier for that attempt, also available to its claim-hook operations. Exact variable names remain open. |

The useful distinction is **definition versus execution**: an agent is what the developer supplies; a cycle is one time that agent wakes up; a run handles one item inside that cycle. A later attempt can handle the same work-item ID again.

Prefer “start an agent cycle” over “start an agent” when describing scheduling. Prefer “run a work item” when describing `run.sh`.

## Discovery has two meanings

| Phrase | Meaning |
| --- | --- |
| **Agent discovery** | The platform scans the configured repository directory to find agent bundles. |
| **Work discovery** | An agent’s `discover.sh` lists work items that appear ready to execute. |

Use the full phrase when the context could mean either. `discover.sh` always refers to work discovery.

## Coordination and observability

| Term | Meaning in this specification |
| --- | --- |
| **Internal claim** | Platform-managed ownership for an agent and work-item ID within the coordination scope. |
| **External claim hook** | Optional `claim.sh` operations that supplement internal claiming with integration-specific coordination. |
| **Ownership token** | The opaque value returned by external acquisition and supplied to renewal and release. It identifies that ownership. |
| **Lease** | A claim with a limited lifetime that requires renewal. External `lease_seconds: null` instead represents a non-expiring claim. |
| **Domain event** | An optional developer-defined event, emitted using `@agent` and JSON with `event` and optional `data`. |
| **Execution logs** | Captured script output, subject to the platform’s documented limits and retention. |

An internal claim is distinct from exclusive ownership of the whole agent cycle. The exact coordination scope and cycle recovery behavior remain [unresolved](../gaps/).

## Example of the language

> An application points to a repository containing an uppercase agent. On a scheduled wake-up, the scheduler invokes the execution harness to carry out an agent cycle. The execution harness calls `discover.sh`, which returns the item `message`. The execution harness validates discovery output, acquires the internal claim, invokes `run.sh`, records the attempt's outcome through the platform's observability systems, and releases the claim. The cycle ends when its work and cleanup have settled.

The platform ensures that a scheduled wake-up during an active cycle is skipped without queueing a later cycle. These names do not change that guarantee or resolve the open questions about cycle recovery.
