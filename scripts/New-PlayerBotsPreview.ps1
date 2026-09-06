[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $OutputDirectory,

    [string] $Ref = 'HEAD'
)

$ErrorActionPreference = 'Stop'
$moduleRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path

$status = @(& git -C $moduleRoot status --porcelain=v1)
if ($LASTEXITCODE -ne 0) {
    throw 'Could not inspect the PlayerBots Git worktree.'
}
if ($status.Count -ne 0) {
    throw 'Refusing to package a dirty PlayerBots worktree. Commit the intended preview first.'
}

$commit = (& git -C $moduleRoot rev-parse "$Ref^{commit}").Trim()
if ($LASTEXITCODE -ne 0 -or $commit -notmatch '^[0-9a-f]{40}$') {
    throw "Could not resolve '$Ref' to one Git commit."
}

$manifestJson = @(& git -C $moduleRoot show "${commit}:playerbots.module.json") -join "`n"
if ($LASTEXITCODE -ne 0) {
    throw "Could not read playerbots.module.json from '$commit'."
}
$moduleManifest = $manifestJson | ConvertFrom-Json
$version = [string]$moduleManifest.version
if ($version -notmatch '^[0-9A-Za-z][0-9A-Za-z.+-]*$') {
    throw "Module version '$version' is not safe for an artifact name."
}

function Get-ArchiveHash($zip, [string] $path) {
    $entry = $zip.GetEntry("archeage-playerbots/$path")
    if ($null -eq $entry) { throw "Preview archive is missing '$path'." }
    $stream = $entry.Open()
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [Convert]::ToHexString($sha.ComputeHash($stream)).ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Assert-ArchiveHash($zip, [string] $path, [string] $expectedHash) {
    $actualHash = Get-ArchiveHash $zip $path
    if ($expectedHash -notmatch '^[0-9a-fA-F]{64}$' -or $actualHash -ne $expectedHash.ToLowerInvariant()) {
        throw "Archived hash mismatch for '$path'."
    }
    return $actualHash
}

$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($outputRoot) | Out-Null
$shortCommit = $commit.Substring(0, 7)
$artifactBase = "archeage-playerbots-$version-$shortCommit"
$archivePath = Join-Path $outputRoot "$artifactBase.zip"
$previewManifestPath = Join-Path $outputRoot "$artifactBase.manifest.json"
$checksumPath = Join-Path $outputRoot "$artifactBase.sha256"

foreach ($target in @($archivePath, $previewManifestPath, $checksumPath)) {
    if (Test-Path -LiteralPath $target) {
        throw "Refusing to overwrite existing preview artifact '$target'."
    }
}

$archiveEntries = @(
    'README.md',
    'CHANGELOG.md',
    'CONTRIBUTING.md',
    'SECURITY.md',
    'LICENSE.GPL',
    'LICENSE.MIT',
    'playerbots.module.json',
    'assets',
    'build',
    'docs',
    'sql',
    'src',
    'compatibility/README.md',
    'scripts/Install-PlayerBots.ps1',
    'scripts/install-playerbots.sh',
    'scripts/autonomy/README.md',
    'scripts/autonomy/Show-LiveBotMonitor.ps1'
)
$archiveEntries += @($moduleManifest.hostTracks | ForEach-Object { [string]$_.compatibilityPatch })
$archiveEntries += [string]$moduleManifest.install.compatibilityPatch
$archiveEntries = @($archiveEntries | Select-Object -Unique)

& git -C $moduleRoot archive --format=zip '--prefix=archeage-playerbots/' `
    "--output=$archivePath" $commit -- $archiveEntries
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
    throw 'Git could not create the preview archive.'
}

$requiredEntries = @(
    'archeage-playerbots/README.md',
    'archeage-playerbots/LICENSE.GPL',
    'archeage-playerbots/playerbots.module.json',
    'archeage-playerbots/scripts/Install-PlayerBots.ps1',
    'archeage-playerbots/scripts/install-playerbots.sh',
    'archeage-playerbots/src/AAEmu.Game/Bots/Questing/BotQuestLifecycleController.cs',
    'archeage-playerbots/scripts/autonomy/Show-LiveBotMonitor.ps1'
)

$zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    # Verify the bytes consumers receive, never files from the current checkout.
    $reader = [System.IO.StreamReader]::new($zip.GetEntry('archeage-playerbots/playerbots.module.json').Open())
    try { $moduleManifest = $reader.ReadToEnd() | ConvertFrom-Json }
    finally { $reader.Dispose() }
    foreach ($track in $moduleManifest.hostTracks) {
        $null = Assert-ArchiveHash $zip ([string]$track.compatibilityPatch) ([string]$track.compatibilityPatchSha256)
    }
    $null = Assert-ArchiveHash $zip ([string]$moduleManifest.install.compatibilityPatch) `
        ([string]$moduleManifest.install.compatibilityPatchSha256)
    $actualMigrationHash = Assert-ArchiveHash $zip ([string]$moduleManifest.install.databaseMigration) `
        ([string]$moduleManifest.install.databaseMigrationSha256)
    $entryNames = @($zip.Entries | ForEach-Object FullName)
    foreach ($requiredEntry in $requiredEntries) {
        if ($requiredEntry -notin $entryNames) {
            throw "Preview archive is missing required entry '$requiredEntry'."
        }
    }
    if ($entryNames | Where-Object { $_ -match '(^|/)\.git(/|$)' }) {
        throw 'Preview archive unexpectedly contains Git internals.'
    }
    $forbiddenEntries = @($entryNames | Where-Object {
        $_ -match '^archeage-playerbots/(ops|tests|tools)/' -or
        $_ -eq 'archeage-playerbots/AGENTS.md' -or
        $_ -match '^archeage-playerbots/scripts/(Test-|combat/|evidence/|scale/)'
    })
    if ($forbiddenEntries.Count -gt 0) {
        throw "Preview archive contains internal files: $($forbiddenEntries -join ', ')"
    }
    $entryCount = $entryNames.Count
}
finally {
    $zip.Dispose()
}

$archiveInfo = Get-Item -LiteralPath $archivePath
$archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
$previewManifest = [ordered]@{
    schemaVersion = 1
    name = [string]$moduleManifest.name
    version = $version
    commit = $commit
    createdUtc = [DateTime]::UtcNow.ToString('O')
    archive = [ordered]@{
        file = $archiveInfo.Name
        sha256 = $archiveHash
        bytes = $archiveInfo.Length
        entries = $entryCount
        extractAs = 'modules/archeage-playerbots'
    }
    hostTracks = @($moduleManifest.hostTracks | ForEach-Object {
        [ordered]@{
            id = [string]$_.id
            track = [string]$_.track
            status = [string]$_.status
            testedBaseCommit = [string]$_.testedBaseCommit
            compatibilityPatch = [string]$_.compatibilityPatch
            compatibilityPatchSha256 = ([string]$_.compatibilityPatchSha256).ToLowerInvariant()
        }
    })
    databaseMigration = [ordered]@{
        path = [string]$moduleManifest.install.databaseMigration
        sha256 = $actualMigrationHash
    }
}

$json = $previewManifest | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($previewManifestPath, $json + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($checksumPath, "$archiveHash *$($archiveInfo.Name)" + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    Archive = $archivePath
    Manifest = $previewManifestPath
    Checksum = $checksumPath
    Commit = $commit
    Sha256 = $archiveHash
    Bytes = $archiveInfo.Length
    Entries = $entryCount
}
