<!-- Add to the repository's layout / source map: -->

- `worklog/`: work records; `worklog/README.md` is the index, `worklog/decisions.md` the standing decisions.
- `bugs/`: bugs and known limitations; `bugs/README.md` is the index and counts.
- `releases/`: published baseline, what's in the field, target versions; `releases/README.md` is the index.
- `.agents/skills/common-work-*`: the project lifecycle skills, copied from common-skills. Update them with its
  `install.sh --project`; don't edit the copies here.

<!-- Add as its own section, replacing any existing lifecycle / records section. Point at the skills; don't restate
     their rules. -->

## Project lifecycle

- Non-trivial work: `common-work-start`.
- A defect or limitation found: `common-work-bug-register`, right away.
- Work with a target version, or any change to persisted data: `common-work-release`. Read `releases/README.md`
  before changing stores, schemas, preference keys, or formats.
