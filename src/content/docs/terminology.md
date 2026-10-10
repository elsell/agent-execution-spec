---
title: Terminology
description: Shared language for applications, agents, cycles, work items, and the platform that runs them.
---

An **application** groups repository configuration and agents. An **agent** is the developer-provided bundle of scripts and optional configuration. An **agent cycle** is one scheduled invocation of discovery followed by processing its accepted work items.

:::note[Naming discussion]
The definitions below describe concepts already discussed. **Orchestrator** is the proposed name for the platform role that manages applications and coordinates agent execution. It is not yet a settled replacement for “platform” in the contract. This page introduces no new execution requirements or required components.
:::

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

## What should we call the component that runs it?

**Proposed: orchestrator.** It names the role that manages application configuration and coordinates the already-agreed execution behavior: wake-ups, discovery, validation, claims, runs, timeouts, cleanup, and recording outcomes.

The role may be implemented by multiple processes or services. Choosing this name does not require one central process or decide the platform’s architecture.

| Candidate | When the name fits | Recommendation for this draft |
| --- | --- | --- |
| **Orchestrator** | Coordinating multiple operations through an execution lifecycle. | Proposed name for the role that coordinates agent cycles. |
| **Controller** | Observing actual state and taking action to reconcile it with desired state. | Appropriate if an implementation uses a reconciliation loop to manage applications or their execution resources. |
| **Scheduler** | Determining when work should start. | Keep this name for the wake-up responsibility; it does not describe the whole lifecycle. |
| **Platform** | The broader system providing execution and its surrounding capabilities. | Retain the current contract term while the narrower name is being discussed. |

“Controller” is not incorrect, and there is no universally mandatory name. In the Kubernetes sense, a controller reconciles current and desired state; merely calling scripts does not establish that design. See the [Kubernetes controller documentation](https://kubernetes.io/docs/concepts/architecture/controller/). This is background for the naming discussion, not a Kubernetes dependency.

An implementation could have an application controller as part of its orchestrator. We do not need to prescribe that split to define the script contract. Here, “manages an application” describes responsibility, not an API ownership field or a decision about where configuration is stored.

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

> An application points to a repository containing an uppercase agent. On a scheduled wake-up, the platform starts an agent cycle. Work discovery returns the item `message`. The platform acquires its internal claim, invokes `run.sh`, records the attempt’s outcome, and releases the claim. The cycle ends when its work and cleanup have settled.

If we adopt the proposed name, “the orchestrator” can replace “the platform” where we mean that execution-coordination role specifically.
