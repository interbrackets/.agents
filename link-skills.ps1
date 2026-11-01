# Links every skill in ~/.agents/skills into ~/.claude/skills, where Claude Code discovers them.
# Run it after adding or removing a skill, and once on each new machine.
# Safe to re-run: it only creates and removes junctions, never a real folder, and it leaves the
# app-managed synced and .trash folders alone.

$source = Join-Path $HOME '.agents\skills'
$target = Join-Path $HOME '.claude\skills'

if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target | Out-Null }

$skills = Get-ChildItem $source -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }

foreach ($skill in $skills) {
  $link = Join-Path $target $skill.Name
  $existing = Get-Item $link -Force -ErrorAction SilentlyContinue
  if (-not $existing) {
    New-Item -ItemType Junction -Path $link -Target $skill.FullName | Out-Null
    "linked   $($skill.Name)"
  } elseif ($existing.LinkType -ne 'Junction') {
    Write-Warning "skipped  $($skill.Name): a real folder is in the way at $link"
  }
}

$names = $skills.Name
Get-ChildItem $target -Directory -Force |
  Where-Object { $_.LinkType -eq 'Junction' -and $names -notcontains $_.Name } |
  ForEach-Object {
    $_.Delete()
    "removed  $($_.Name)"
  }

"$($skills.Count) skills available"
