# skill-ask-epics

EPICS documentation assistant — answers questions about EPICS (Experimental Physics
and Industrial Control System) by searching a locally indexed corpus of 26
`epics-base` GitHub repos (IOC core, Channel Access, PVAccess, pvxs, pvaPy, p4p,
record types, Java/Python bindings, etc.).

This is an **externalized knowledge-wrapper skill**. It is centrally deployed to
S3DF (`/sdf/group/lcls/ds/dm/apps/dev/`) by the meta-deploy in
[carbonscott/deploy-opencode](https://github.com/carbonscott/deploy-opencode);
individual users do not clone this repo directly.

## Layout

```
claude/skills/ask-epics/      ← Claude Code skill copy
opencode/skills/ask-epics/    ← OpenCode skill copy (byte-identical)
  ├── SKILL.md                ← Skill description + workflow
  ├── env.sh                  ← Sets EPICS_DOCS_ROOT (sources env.local)
  ├── env.local               ← Facility overrides (S3DF default committed)
  ├── setup.sh                ← One-time setup for non-S3DF users
  └── bin/                    ← docs-index FTS5 search CLI

tools/epics-docs/             ← Cron-managed sync + reindex
  ├── env.sh                  ← Exports EPICS_DOCS_APP_DIR + EPICS_DOCS_DATA_DIR
  └── scripts/
      └── epics-docs-cron.sh  ← status/enable/disable/run commands
```

## Deploy targets

`deploy.sh ask-epics` in the meta-deploy rsyncs:

| Source in this repo | Destination on S3DF |
|---|---|
| `opencode/skills/ask-epics/` | `/sdf/group/lcls/ds/dm/apps/dev/opencode/skills/ask-epics/` |
| `tools/epics-docs/` | `/sdf/group/lcls/ds/dm/apps/dev/tools/epics-docs/` |

After deploy, `env.sh` and `setup.sh` see the **deployed** paths under
`/sdf/group/lcls/ds/dm/apps/dev/...` and continue to work without modification —
all internal paths are resolved relative to `$BASH_SOURCE` at runtime, and
`env.local` hardcodes the S3DF data root.

## Cron schedule

The corpus is refreshed by `tools/epics-docs/scripts/epics-docs-cron.sh`,
installed manually on `sdfcron001`:

```
# crontab -e on sdfcron001
0 3 * * 0  /sdf/group/lcls/ds/dm/apps/dev/tools/epics-docs/scripts/epics-docs-cron.sh run >> /sdf/group/lcls/ds/dm/apps/dev/data/epics-docs/cron.log 2>&1
```

That's weekly on Sunday at 03:00. The helper script automates the install:

```
ssh sdfcron001
/sdf/group/lcls/ds/dm/apps/dev/tools/epics-docs/scripts/epics-docs-cron.sh enable    # add entry
/sdf/group/lcls/ds/dm/apps/dev/tools/epics-docs/scripts/epics-docs-cron.sh status    # verify
/sdf/group/lcls/ds/dm/apps/dev/tools/epics-docs/scripts/epics-docs-cron.sh disable   # remove
```

The cron job:
1. `git pull --ff-only` for each of the 26 `epics-base/*` clones under
   `$EPICS_DOCS_DATA_DIR` (`/sdf/group/lcls/ds/dm/apps/dev/data/epics-docs`)
2. Incremental rebuild of the FTS5 search index (`search.db`)
3. `chgrp -R ps-data` + `chmod -R g+rX` so all `ps-data` group members can read

## Data dependency

The indexed corpus lives at
`/sdf/group/lcls/ds/dm/apps/dev/data/epics-docs/` on S3DF. It is **not** in
this repo — too large and refreshed weekly. The initial clone of all 26 repos
is bootstrapped by `setup.sh` (only needed for non-S3DF deployments); on S3DF
the data is already present and maintained by the cron job above.

## License

Per-skill license follows the upstream `epics-base` projects (EPICS Open
License). Skill description, env scripts, and tooling are MIT-style; see
individual files.
