[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $OutputDirectory
)

$ErrorActionPreference = 'Stop'
$moduleRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$runRoot = Join-Path ([IO.Path]::GetFullPath($OutputDirectory)) ("preview-test-" + [Guid]::NewGuid().ToString('N'))
$fixture = Join-Path $runRoot 'repository'
[IO.Directory]::CreateDirectory($fixture) | Out-Null

function Invoke-FixtureGit {
    & git -C $fixture @args
    if ($LASTEXITCODE -ne 0) { throw "Fixture git failed: $args" }
}

function Assert-Equal($actual, $expected, [string] $label) {
    if ($actual -cne $expected) { throw "$label expected '$expected', got '$actual'." }
}

function Write-Manifest($manifest) {
    [IO.File]::WriteAllText((Join-Path $fixture 'playerbots.module.json'),
        ($manifest | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
}

function Set-FixtureVersion([string] $version) {
    $manifest = Get-Content -LiteralPath (Join-Path $fixture 'playerbots.module.json') -Raw | ConvertFrom-Json
    $manifest.version = $version
    $manifest.name = "Cross-ref fixture $version"
    foreach ($track in $manifest.hostTracks) {
        $path = Join-Path $fixture $track.compatibilityPatch
        [IO.File]::WriteAllText($path, [IO.File]::ReadAllText($path).Replace("`r`n", "`n") + "`n# preview fixture $version`n")
        $track.compatibilityPatchSha256 = (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()
        $track.status = "fixture-$version"
    }
    $manifest.install.compatibilityPatchSha256 = (Get-FileHash -LiteralPath (
        Join-Path $fixture $manifest.install.compatibilityPatch)).Hash.ToLowerInvariant()
    $migration = Join-Path $fixture $manifest.install.databaseMigration
    [IO.File]::WriteAllText($migration, [IO.File]::ReadAllText($migration).Replace("`r`n", "`n") + "`n-- preview fixture $version`n")
    $manifest.install.databaseMigrationSha256 = (Get-FileHash -LiteralPath $migration).Hash.ToLowerInvariant()
    Write-Manifest $manifest
    return $manifest
}

function Assert-Rejected([scriptblock] $action, [string] $message) {
    $caught = $null
    try { & $action | Out-Null } catch { $caught = $_.Exception.Message }
    if (!$caught -or !$caught.Contains($message)) {
        throw "Expected rejection containing '$message', got '$caught'."
    }
}

# Keep every fixture and archive for inspection, including failed runs.
$snapshot = Join-Path $runRoot 'source.zip'
& git -C $moduleRoot archive --format=zip "--output=$snapshot" HEAD
if ($LASTEXITCODE -ne 0) { throw 'Could not archive the fixture source.' }
[IO.Compression.ZipFile]::ExtractToDirectory($snapshot, $fixture)
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'New-PlayerBotsPreview.ps1') `
    -Destination (Join-Path $fixture 'scripts/New-PlayerBotsPreview.ps1')
Invoke-FixtureGit init --quiet
Invoke-FixtureGit config user.name 'Preview regression'
Invoke-FixtureGit config user.email 'preview-test@example.invalid'
Invoke-FixtureGit config core.autocrlf false
Invoke-FixtureGit config commit.gpgSign false
# Make fixture byte expectations independent of the machine's native EOL.
# The packager must still validate the archive, including Git attribute effects.
[IO.File]::AppendAllText((Join-Path $fixture '.gitattributes'), "`n*.sql -text`n")
$requestedManifest = Set-FixtureVersion '9.1.0-requested'
Invoke-FixtureGit add --all
Invoke-FixtureGit commit --quiet -m 'Requested archive fixture'
$requested = (Invoke-FixtureGit rev-parse HEAD).Trim()
$checkoutManifest = Set-FixtureVersion '9.2.0-checkout'
Invoke-FixtureGit add --all
Invoke-FixtureGit commit --quiet -m 'Different checkout fixture'
$checkout = (Invoke-FixtureGit rev-parse HEAD).Trim()
if ($requested -eq $checkout) { throw 'Regression requires two different commits.' }

$packager = Join-Path $fixture 'scripts/New-PlayerBotsPreview.ps1'
$output = Join-Path $runRoot 'packages'
$result = & $packager -OutputDirectory $output -Ref $requested
$sidecar = Get-Content -LiteralPath $result.Manifest -Raw | ConvertFrom-Json
Assert-Equal $sidecar.commit $requested 'Commit'
Assert-Equal $sidecar.version $requestedManifest.version 'Version'
Assert-Equal $sidecar.name $requestedManifest.name 'Name'
Assert-Equal ([IO.Path]::GetFileName($result.Archive)) `
    "archeage-playerbots-9.1.0-requested-$($requested.Substring(0, 7)).zip" 'Archive filename'

$zip = [IO.Compression.ZipFile]::OpenRead($result.Archive)
try {
    $reader = [IO.StreamReader]::new($zip.GetEntry('archeage-playerbots/playerbots.module.json').Open())
    try { $archived = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
    Assert-Equal $archived.version $requestedManifest.version 'Archived version'
    foreach ($track in $requestedManifest.hostTracks) {
        $actualTrack = $sidecar.hostTracks | Where-Object id -EQ $track.id
        Assert-Equal $actualTrack.status $track.status 'Track status'
        Assert-Equal $actualTrack.testedBaseCommit $track.testedBaseCommit 'Host base'
        Assert-Equal $actualTrack.compatibilityPatchSha256 $track.compatibilityPatchSha256 'Patch sidecar hash'
    }
    $checks = @($requestedManifest.hostTracks | ForEach-Object {
        @{ Path = $_.compatibilityPatch; Hash = $_.compatibilityPatchSha256 }
    })
    $checks += @{ Path = $requestedManifest.install.databaseMigration; Hash = $requestedManifest.install.databaseMigrationSha256 }
    foreach ($check in $checks) {
        $stream = $zip.GetEntry("archeage-playerbots/$($check.Path)").Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $hash = [Convert]::ToHexString($sha.ComputeHash($stream)).ToLowerInvariant() }
        finally { $sha.Dispose(); $stream.Dispose() }
        Assert-Equal $hash $check.Hash 'Archived byte hash'
    }
    Assert-Equal $sidecar.archive.entries $zip.Entries.Count 'Entry count'
} finally { $zip.Dispose() }
Assert-Equal $sidecar.databaseMigration.sha256 $requestedManifest.install.databaseMigrationSha256 'Migration sidecar hash'
$archiveHash = (Get-FileHash -LiteralPath $result.Archive).Hash.ToLowerInvariant()
Assert-Equal $sidecar.archive.sha256 $archiveHash 'Archive hash'
Assert-Equal $sidecar.archive.bytes (Get-Item -LiteralPath $result.Archive).Length 'Archive length'
Assert-Equal (Get-Content -LiteralPath $result.Checksum -Raw).Trim() `
    "$archiveHash *$([IO.Path]::GetFileName($result.Archive))" 'Checksum file'

$originalHashes = @($result.Archive, $result.Manifest, $result.Checksum | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash })
Assert-Rejected { & $packager -OutputDirectory $output -Ref $requested } 'Refusing to overwrite'
$afterHashes = @($result.Archive, $result.Manifest, $result.Checksum | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash })
Assert-Equal ($afterHashes -join ',') ($originalHashes -join ',') 'Preserved outputs'

# A valid checkout must not hide a corrupt requested ref.
$checkoutManifest.hostTracks[0].compatibilityPatchSha256 = '0' * 64
Write-Manifest $checkoutManifest
Invoke-FixtureGit add --all
Invoke-FixtureGit commit --quiet -m 'Invalid archived patch hash'
$badPatch = (Invoke-FixtureGit rev-parse HEAD).Trim()
$checkoutManifest.hostTracks[0].compatibilityPatchSha256 = $checkoutManifest.install.compatibilityPatchSha256
$checkoutManifest.install.databaseMigrationSha256 = '0' * 64
Write-Manifest $checkoutManifest
Invoke-FixtureGit add --all
Invoke-FixtureGit commit --quiet -m 'Invalid archived migration hash'
$badMigration = (Invoke-FixtureGit rev-parse HEAD).Trim()
Invoke-FixtureGit switch --detach $checkout
Assert-Rejected { & $packager -OutputDirectory (Join-Path $runRoot 'bad-patch') -Ref $badPatch } 'Archived hash mismatch'
Assert-Rejected { & $packager -OutputDirectory (Join-Path $runRoot 'bad-migration') -Ref $badMigration } 'Archived hash mismatch'

[pscustomobject]@{
    Result = 'PASS'
    RequestedCommit = $requested
    CheckoutCommit = $checkout
    Archive = $result.Archive
    RetainedArtifacts = $runRoot
    Checks = 'cross-ref metadata and byte hashes; archive checksum; overwrite refusal; corrupt archived patch and migration rejection'
}
