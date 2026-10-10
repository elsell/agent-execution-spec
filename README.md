# Agent Execution Specification

Discussion draft defining the execution contract for agents exposing `discover.sh` and `run.sh`, with optional external claim hooks.

- [Read the published specification](https://elsell.github.io/agent-execution-spec/)
- [Specification source](src/content/docs/index.md)
- [Sequence diagram](src/content/docs/sequence.md)
- [Unresolved details](src/content/docs/gaps.md)

The content preserves the conversation draft. Unresolved details are listed separately rather than assigned new behavior. Website tooling is not part of the execution specification.

## Local development

With Node.js 22 and pnpm 10:

```sh
pnpm install --frozen-lockfile
pnpm dev
```

`pnpm build` generates the static site. Pushes to `main` build and deploy it to GitHub Pages through `.github/workflows/pages.yml`.

Edit the Markdown in `src/content/docs/`. The Mermaid source is rendered both by GitHub and by the documentation site.
