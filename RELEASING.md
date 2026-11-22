# Releasing ColorsForMe

Maintainer notes. The release pipeline lives in `.github/workflows/release.yml`.

## How the pipeline works

- It runs on a push of a tag matching `v*` and on manual dispatch.
- Jobs: determine the version from the tag, build `ColorsForMe-<version>.zip`, create the GitHub release with the zip attached, and optionally upload the zip to CurseForge.
- The zip contains the addon folder `ColorsForMe` at its top level (`ColorsForMe/ColorsForMe.toc`), ready to be extracted into an AddOns folder. The `## Version:` line in the packaged toc is set from the tag.
- **The pipeline is disabled by default.** Every job runs only when the repository variable `RELEASE_ENABLED` is exactly `true`. Until then, tag pushes only show skipped jobs.

## Enable

```
gh variable set RELEASE_ENABLED --body true
```

## Publish to CurseForge (optional)

```
gh secret set CF_API_KEY
gh variable set CF_PROJECT_ID --body <numeric project id>
gh variable set CF_GAME_VERSION_ID --body <numeric game version id>
```

Instead of `CF_GAME_VERSION_ID` you can set `gh variable set CF_GAME_VERSION --body <version name>`, which is looked up by name. Without `CF_API_KEY`, `CF_PROJECT_ID` and a game version, the CurseForge job logs a warning and exits without uploading.

The CurseForge game version for toc `## Interface: 16001` must be looked up at https://wow.curseforge.com/api/game/wow/versions. This has not been verified yet.

## Release a new version

1. Bump `## Version:` in `ColorsForMe/ColorsForMe.toc`.
2. Add an entry to `CHANGELOG.md`.
3. Commit and push to `main`.
4. `git tag vX.Y.Z` (the tag must be new and higher than the previous one).
5. `git push origin vX.Y.Z`.
6. Check `gh run list --limit 1`, then `gh release view vX.Y.Z` to confirm the zip asset.

## Disable again

```
gh variable delete RELEASE_ENABLED
```
