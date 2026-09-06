# Preview archives

A preview is an exact module source snapshot, with a ZIP, JSON manifest, and SHA-256 sidecar. It contains no AAEmu host, client assets, databases, or runtime evidence.

## Create a preview

From a clean, committed module checkout:

```powershell
& ./scripts/New-PlayerBotsPreview.ps1 -OutputDirectory ./artifacts/preview-v1 -Ref HEAD
```

`-Ref` can be a different commit or tag. The script reads that revision's module manifest, archives that revision, and verifies patch and migration hashes against the ZIP entries. The filename, version, commit, and sidecars describe the requested snapshot, not the checkout.

Git attributes and line-ending rules affect archived text bytes. A mismatch with the requested manifest is rejected; the packager never substitutes a checkout hash. Existing outputs are never overwritten, and a failed archive is retained for inspection. Use a new output directory for another attempt.

The archive includes product source, public guides, installers, declared compatibility patches, and the live monitor. Tests and local operational records stay out of the user archive. Contributor tooling remains in the Git repository.

## Verify and install

Compare `Get-FileHash <archive.zip> -Algorithm SHA256` (or `sha256sum`) with the sidecar. Check the manifest's module commit, host base, patch identities, and migration hash. A matching checksum proves file identity, not gameplay acceptance.

Extract `archeage-playerbots/` into `AAEmu/modules/`, then follow [Installation](INSTALLATION.md) for the matching pinned host and migration. Do not layer an archive over an unrelated module checkout or an older patched host.

Contributors should run `scripts/Test-PlayerBotsPreview.ps1` as described in [Testing](TESTING.md) when changing the packager.
