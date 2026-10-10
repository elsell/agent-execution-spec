---
title: Sequence diagram
description: The agent cycle from a scheduled wake-up through discovery, claims, execution, and cleanup.
---

This diagram shows the accepted discovery path and per-item processing. Failure behavior is defined in the specification. Items can execute concurrently; the loop represents each item's lifecycle rather than requiring serial execution.

```mermaid
sequenceDiagram
    participant S as Scheduler
    participant P as Platform
    participant D as discover.sh
    participant C as claim.sh (optional)
    participant R as run.sh
    participant O as Events and logs

    S->>P: Scheduled wake-up
    alt Agent cycle already active
        P-->>S: Skip wake-up, do not queue
    else No active cycle
        P->>P: Establish exclusive agent cycle
        P->>D: Execute with item limit
        D-->>P: JSON lines and exit status
        P->>P: Validate complete output

        alt Discovery rejected
            P->>O: Record discovery failure
        else Discovery accepted
            Note over P,R: Process accepted items with at most maxConcurrentRuns active runs
            loop Each accepted work item
                P->>P: Acquire internal item claim
                opt Internal claim acquired and hook configured
                    P->>C: acquire(item), attempt ID available
                    C-->>P: Acquired with token and lease, busy, or failure
                end

                alt Required claims acquired
                    P->>R: Execute with envelope on stdin
                    R->>O: Domain events and ordinary logs
                    Note over P,C: Renew applicable claims while run is active
                    Note over P,R: Timeout or ownership loss triggers termination
                    R-->>P: Execution ends
                    P->>O: Record execution outcome
                    opt External claim acquired
                        P->>C: release(item, token)
                        C-->>P: Released, already gone, or failure
                        Note over P,C: Cleanup retries are bounded
                    end
                    P->>P: Release internal item claim
                else Claim unavailable or acquisition failed
                    P->>P: Skip item, release held internal claim
                end
            end
        end
        P->>P: End cycle after all items and cleanup settle
    end
```
