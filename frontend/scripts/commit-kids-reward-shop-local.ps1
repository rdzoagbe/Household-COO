# Household COO - Commit local Kids Reward Shop redesign
# This script assumes polish-kids-reward-shop.ps1 already wrote the new Reward Shop UI locally.
# It fixes the TypeScript progress width issue, verifies, commits only kids.tsx, and pushes.

$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\TheKwekuRO\Documents\Household-COO"
$FrontendPath = Join-Path $RepoPath "frontend"
$KidsFile = Join-Path $FrontendPath "app\(tabs)\kids.tsx"
$BranchName = "fix/kids-premium-dark-default"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Set-Location $RepoPath

git switch $BranchName

if (!(Test-Path $KidsFile)) {
  throw "kids.tsx not found at $KidsFile"
}

$content = [System.IO.File]::ReadAllText($KidsFile, [System.Text.Encoding]::UTF8)

# React Native type definitions can reject a percent string inferred as plain string.
# Cast the dynamic progress width so TypeScript accepts the progress bar style.
$content = $content.Replace(
  "{ width: progressWidth, backgroundColor: theme.colors.accent }",
  "{ width: progressWidth as any, backgroundColor: theme.colors.accent }"
)

# Keep the reward footer spacing tight.
$content = $content.Replace("<View style={{ height: 220 }} />", "<View style={{ height: 170 }} />")
$content = $content.Replace("<View style={{ height: 190 }} />", "<View style={{ height: 170 }} />")

[System.IO.File]::WriteAllText($KidsFile, $content, $Utf8NoBom)

Set-Location $FrontendPath
npm run verify

if ($LASTEXITCODE -ne 0) {
  Write-Host "Verification failed. Not committing." -ForegroundColor Red
  exit $LASTEXITCODE
}

Set-Location $RepoPath

git add "frontend/app/(tabs)/kids.tsx"

git diff --cached --quiet

if ($LASTEXITCODE -eq 0) {
  Write-Host "No kids.tsx changes to commit." -ForegroundColor Yellow
  exit 0
}

git commit -m "Polish Kids reward shop cards"
git push origin $BranchName

Write-Host "Kids Reward Shop redesign committed and pushed." -ForegroundColor Green
