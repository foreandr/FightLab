$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    $branch = git branch --show-current
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') { throw 'Switch to main before syncing.' }

    # Protect tracked edits (including staged changes). Untracked local/generated
    # files do not by themselves block a safe fast-forward pull. Git refuses
    # the pull automatically if a remote file would overwrite an untracked file.
    git diff --quiet --exit-code
    if ($LASTEXITCODE -ne 0) { throw 'Tracked local changes found. Commit or stash them before syncing.' }
    git diff --cached --quiet --exit-code
    if ($LASTEXITCODE -ne 0) { throw 'Staged local changes found. Commit or stash them before syncing.' }

    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { throw 'Pull failed. Resolve the reported issue; no reset was performed.' }
} finally { Pop-Location }
