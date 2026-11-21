## Summary

<!-- Describe what this PR adds or changes and why. -->

## Affected Chart(s)

- [ ] `9router`
- [ ] `aws-alb-gateway`
- [ ] `crw`
- [ ] `metrics-accumulator`
- [ ] Repository / CI / Docs

## Checklist

- [ ] Bumped `version` in `Chart.yaml` following SemVer (if chart templates or defaults changed).
- [ ] Updated `values.schema.json` and chart `README.md` for any new or changed values.
- [ ] Verified `helm lint --strict` and `helm template` pass on defaults and all `examples/*.yaml`.
- [ ] Verified no personal domains, secrets, or environment-specific values were introduced.
- [ ] Updated `artifacthub.io/changes` in `Chart.yaml` for the new release.
