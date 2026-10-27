$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    $branch = git branch --show-current
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') { throw 'Switch to main before syncing.' }
    $dirty = git status --porcelain
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read Git status.' }
    if ($dirty) { throw 'Local changes found. Commit or stash them before syncing; nothing was discarded.' }
    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { throw 'Pull failed. Resolve the reported issue; no reset was performed.' }
} finally { Pop-Location }
