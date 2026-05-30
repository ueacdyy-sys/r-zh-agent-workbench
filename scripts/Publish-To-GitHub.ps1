[CmdletBinding()]
param(
  [string]$RepoName = "r-zh-agent-workbench",
  [ValidateSet("public", "private")]
  [string]$Visibility = "public",
  [switch]$CreateRelease
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw "GitHub CLI is not installed or not on PATH."
}

gh auth status

if (-not (Test-Path -LiteralPath ".git")) {
  git init
}

git status --short

Write-Output "Creating GitHub repository: $RepoName ($Visibility)"
gh repo create $RepoName "--$Visibility" --source . --remote origin --push

git push origin --tags

if ($CreateRelease) {
  $notes = "docs\release-notes-v0.1.0-alpha.md"
  if (-not (Test-Path -LiteralPath $notes)) {
    throw "Release notes not found: $notes"
  }
  gh release create v0.1.0-alpha --title "R Zh Agent Workbench v0.1.0-alpha" --notes-file $notes
}
