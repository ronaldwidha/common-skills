<!-- Add to the repository's layout / source map: -->

- `worklog/`: durable work records; `worklog/README.md` is the status index.
- `bugs/`: bugs and known limitations; `bugs/README.md` is the status index and counts.
- `releases/`: published baseline, target versions, launch requirements, and release notes; `releases/README.md` is the index.
- `.agents/skills/common-work-*`: the project lifecycle skills, copied from common-skills. Update them with its
  `install.sh --project`; don't edit the copies here.

<!-- Add as its own section: -->

## Project lifecycle

- Non-trivial work: use `common-work-start`. Write `worklog/<slug>-<id>/intent.md` and `plan.md` before
  implementing, and `output.md` when done.
- A defect or limitation found: register it right away with `common-work-bug-register`.
- Work with a target version: keep `releases/<version>/` current in the same change with `common-work-release`.

Status follows evidence. Update the three indexes in the same change as the records. New IDs are a slug plus 12
random hex characters, never a shared counter.
