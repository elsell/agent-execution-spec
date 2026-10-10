---
title: Unresolved details
description: Open questions deliberately left unresolved in the conversation draft.
---

These are not additional requirements:

- Whether to adopt “orchestrator” for the execution-coordination role; see the [terminology discussion](../terminology/).
- Exact application schema, configuration field names beyond those shown, and default discovery interval and concurrency.
- Stable agent identity and coordination scope, including behavior across repository changes or multiple application registrations.
- Exact environment-variable names and how discovery receives its item limit.
- Exact JSON layouts for renewal and release inputs, and renewal responses.
- When lease duration starts, renewal timing, internal lease durations, and cleanup retry bounds.
- Crash recovery for an entire agent cycle, including how exclusive cycle ownership interacts with stale execution.
- What happens if execution cannot be confirmed terminated.
- Exact warning and platform lifecycle event names, log access mechanism, and concrete storage and event limits.
- Checkout and image-resolution details, including whether revision consistency extends across the whole cycle.

The draft leaves these open rather than choosing behavior we have not discussed.
