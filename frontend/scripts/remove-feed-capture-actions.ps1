# Household COO - Remove Feed capture actions
# Removes the feed capture/search bar and quick Voice/Camera/Manual action entry points.
# Keeps Sunday Brief and actionable Needs Attention cards.

$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\TheKwekuRO\Documents\Household-COO"
$FrontendPath = Join-Path $RepoPath "frontend"
$FeedFile = Join-Path $FrontendPath "app\(tabs)\feed.tsx"
$BranchName = "feed-actionable-attention"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Remove-BalancedTagBlock {
  param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][int]$SearchFrom,
    [Parameter(Mandatory=$true)][string]$StartNeedle,
    [Parameter(Mandatory=$true)][string]$TagName
  )

  $start = $Text.IndexOf($StartNeedle, $SearchFrom)
  if ($start -lt 0) { return $Text }

  $lineStart = $Text.LastIndexOf("`n", [Math]::Max(0, $start))
  if ($lineStart -lt 0) { $lineStart = 0 } else { $lineStart++ }

  $openPattern = "<$TagName\b"
  $closePattern = "</$TagName>"
  $selfClosePattern = "/>"
  $pos = $start
  $depth = 0

  while ($pos -lt $Text.Length) {
    $nextOpen = [regex]::Match($Text.Substring($pos), $openPattern)
    $nextClose = [regex]::Match($Text.Substring($pos), $closePattern)

    $openIndex = if ($nextOpen.Success) { $pos + $nextOpen.Index } else { [int]::MaxValue }
    $closeIndex = if ($nextClose.Success) { $pos + $nextClose.Index } else { [int]::MaxValue }

    if ($openIndex -eq [int]::MaxValue -and $closeIndex -eq [int]::MaxValue) {
      throw "Could not find closing </$TagName> for $StartNeedle"
    }

    if ($openIndex -lt $closeIndex) {
      $tagEndMatch = [regex]::Match($Text.Substring($openIndex), ">")
      if (-not $tagEndMatch.Success) { throw "Malformed <$TagName> block." }
      $tagEnd = $openIndex + $tagEndMatch.Index
      $tagText = $Text.Substring($openIndex, $tagEnd - $openIndex + 1)
      if ($tagText.TrimEnd().EndsWith("/>")) {
        if ($depth -eq 0) {
          $end = $tagEnd + 1
          $lineEnd = $Text.IndexOf("`n", $end)
          if ($lineEnd -lt 0) { $lineEnd = $end } else { $lineEnd++ }
          return $Text.Remove($lineStart, $lineEnd - $lineStart)
        }
      } else {
        $depth++
      }
      $pos = $tagEnd + 1
    } else {
      $depth--
      $closeEnd = $closeIndex + $closePattern.Length
      if ($depth -eq 0) {
        $lineEnd = $Text.IndexOf("`n", $closeEnd)
        if ($lineEnd -lt 0) { $lineEnd = $closeEnd } else { $lineEnd++ }
        return $Text.Remove($lineStart, $lineEnd - $lineStart)
      }
      $pos = $closeEnd
    }
  }

  throw "Could not remove block $StartNeedle"
}

Set-Location $RepoPath

git fetch origin
git switch $BranchName
git pull origin $BranchName

if (!(Test-Path $FeedFile)) {
  throw "feed.tsx not found at $FeedFile"
}

$content = [System.IO.File]::ReadAllText($FeedFile, [System.Text.Encoding]::UTF8)
$content = $content.Replace("`r`n", "`n").Replace("`r", "`n")
$content = [regex]::Replace($content, "\n{3,}", "`n`n")

# Remove capture-specific UI blocks.
$content = Remove-BalancedTagBlock -Text $content -SearchFrom 0 -StartNeedle 'testID="command-capture"' -TagName 'PressScale'

$quickIndex = $content.IndexOf('{labels.quickActions}')
if ($quickIndex -ge 0) {
  $content = Remove-BalancedTagBlock -Text $content -SearchFrom ([Math]::Max(0, $quickIndex - 300)) -StartNeedle '{labels.quickActions}' -TagName 'View'
  $content = Remove-BalancedTagBlock -Text $content -SearchFrom ([Math]::Max(0, $quickIndex - 300)) -StartNeedle 'style={styles.actionRow}' -TagName 'View'
}

# Remove now-unused capture modal blocks.
$content = Remove-BalancedTagBlock -Text $content -SearchFrom 0 -StartNeedle '<CameraCaptureModal' -TagName 'CameraCaptureModal'
$content = Remove-BalancedTagBlock -Text $content -SearchFrom 0 -StartNeedle '<VoiceCaptureModal' -TagName 'VoiceCaptureModal'
$content = Remove-BalancedTagBlock -Text $content -SearchFrom 0 -StartNeedle '<AddCardModal' -TagName 'AddCardModal'

# Remove capture-specific imports.
$content = [regex]::Replace($content, "(?m)^\s*(Camera|Mic|PlusCircle|Search|SlidersHorizontal),\s*\n", "")
$content = [regex]::Replace($content, "(?m)^import \{ AddCardModal \} from '../../src/components/AddCardModal';\s*\n", "")
$content = [regex]::Replace($content, "(?m)^import \{ VoiceCaptureModal \} from '../../src/components/VoiceCaptureModal';\s*\n", "")
$content = [regex]::Replace($content, "(?m)^import \{ CameraCaptureModal \} from '../../src/components/CameraCaptureModal';\s*\n", "")

# Remove VoiceDraft and capture state/function.
$content = [regex]::Replace($content, "(?s)interface VoiceDraft \{.*?\}\s*\n\s*type Labels =", "type Labels =", 1)
$content = $content.Replace("import { api, Card, CardType, FamilyMember } from '../../src/api';", "import { api, Card, FamilyMember } from '../../src/api';")
$content = [regex]::Replace($content, "(?m)^\s*const \[showAdd, setShowAdd\] = useState\(false\);\s*\n", "")
$content = [regex]::Replace($content, "(?m)^\s*const \[showVoice, setShowVoice\] = useState\(false\);\s*\n", "")
$content = [regex]::Replace($content, "(?m)^\s*const \[showCamera, setShowCamera\] = useState\(false\);\s*\n", "")
$content = [regex]::Replace($content, "(?m)^\s*const \[addSource, setAddSource\] = useState<[^\n]+\n", "")
$content = [regex]::Replace($content, "(?m)^\s*const \[voiceDraft, setVoiceDraft\] = useState<[^\n]+\n", "")
$content = [regex]::Replace($content, "(?s)\n\s*const openManual = \(\) => \{.*?\n\s*\};\s*\n", "`n", 1)

# Remove stale styles for the removed areas.
$staleStyles = @('searchShell', 'searchText', 'filterButton', 'actionRow', 'actionTile', 'actionText')
foreach ($styleName in $staleStyles) {
  $content = [regex]::Replace($content, "(?m)^\s*$styleName:\s*\{[^\n]*\},\s*\n", "")
  $content = [regex]::Replace($content, "(?ms)^\s*$styleName:\s*\{.*?\n\s*\},\s*\n", "")
}

$content = [regex]::Replace($content, "\n{3,}", "`n`n")
[System.IO.File]::WriteAllText($FeedFile, $content.Replace("`n", "`r`n"), $Utf8NoBom)

Set-Location $FrontendPath
npm run verify

if ($LASTEXITCODE -ne 0) {
  Write-Host "Verification failed. Not committing." -ForegroundColor Red
  exit $LASTEXITCODE
}

Set-Location $RepoPath

git add "frontend/app/(tabs)/feed.tsx"

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
  Write-Host "No feed capture actions found to remove." -ForegroundColor Yellow
  exit 0
}

git commit -m "Remove feed capture action entry points"
git push origin $BranchName

Write-Host "Feed capture actions removed and pushed." -ForegroundColor Green
