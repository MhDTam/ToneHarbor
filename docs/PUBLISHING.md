# Publishing source

Publish the clean export, rather than this workspace's local builds/design archive:

```powershell
pwsh -File tool/export_source.ps1
```

This creates `OpenSource/ToneHarbor/`, `OpenSource/ToneHarbor-source.zip` and an external SHA-256 manifest, refusing to overwrite existing output. The exporter uses a source allowlist, skips symbolic links/build directories and excludes executable binaries, personal media, databases, signing files and local logs.

From the exported directory:

```powershell
git init -b main
git add .
git diff --cached --stat
git commit -m "Prepare ToneHarbor open-source project"
```

Create an empty GitHub repository, copy its actual URL, then use it with `git remote add origin` and `git push -u origin main`. No account/URL is prefilled. Source preparation does not publish a repository.

Before pushing, review staged paths, license notices and dependency inventory. The project owner has authorized MIT publication of original code/artwork. Export checks are safeguards, not an exhaustive guarantee against every possible secret. Test/build from a fresh export using the locked dependencies.

Enable private vulnerability reporting in GitHub settings if desired. The CI workflow checks/builds Windows but does not publish releases; remote success is known only after a workflow runs.

## Binary releases

`tool/build_windows.ps1` produces an unsigned portable directory with notices and **without FFmpeg**. Keep the executable, libraries, assets and `NOTICES.Z` together. Upload archives to GitHub Releases separately from Git source. Test startup/Open with under a fresh Windows user account before a public binary release.

Bundling FFmpeg requires licensing and corresponding source materials for the exact executable, including applicable dependencies. The historical build-information file does not establish correspondence for another binary. See `THIRD_PARTY_NOTICES.md`.
