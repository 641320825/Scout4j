# Contributing

Thanks for improving the Java Enterprise Workflow skill.

## Contribution principles

- Keep the skill generic and portable.
- Do not add private company assumptions, internal service names, secrets, or environment-specific paths.
- Do not add benchmark fixture names or standard-answer snippets to general references.
- Prefer pattern-level guidance over one-off code shapes.
- If a lesson cannot be safely generalized, put it in `references/benchmark.md` or in an evaluation repository instead of the main workflow references.

## Before editing

1. Read `SKILL.md` and the most relevant file under `references/`.
2. Check whether the lesson is broadly applicable across Java teams.
3. If the change is based on a benchmark failure, rewrite it as a general principle and remove fixture-specific names.

## Validation

Run from the repository root:

```bash
python3 scripts/check_java_skill_deoverfit.py
```

Expected result: `de-overfit grep OK`.

Also run markdown/diff checks available in the host repository, for example:

```bash
git diff --check -- skills/java-enterprise-workflow
```

If you modify evaluation scripts or fixtures outside this skill package, also run their dedicated tests/checks.

## Pull request checklist

- [ ] The change is generic and not fixture-specific.
- [ ] No secrets or private paths were added.
- [ ] No benchmark answer key leaked into general references.
- [ ] Verification commands and results are documented.
- [ ] Documentation matches implementation.
