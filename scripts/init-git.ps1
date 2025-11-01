param(
  [string]$RemoteUrl = "https://github.com/dragosdehelean/CityAir-Compare.git",
  [string]$Branch = "main"
)

function Ensure-GitInstalled {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git) {
    Write-Error "Git is not installed or not in PATH. Install Git and retry."
    exit 1
  }
}

Ensure-GitInstalled

if (-not (Test-Path .git)) {
  git init | Out-Null
}

git branch -M $Branch

$userName = git config user.name
$userEmail = git config user.email
if (-not $userName) { git config user.name "CityAir Local" | Out-Null }
if (-not $userEmail) { git config user.email "local@example.com" | Out-Null }

git add -A

# Determine if HEAD exists
git rev-parse --verify HEAD 2>$null | Out-Null
$headExists = ($LASTEXITCODE -eq 0)

if (-not $headExists) {
  # First commit
  try {
    git commit -m "chore: initial docs (SPECS, AGENTS, PLAN)" | Out-Null
  } catch {
    Write-Warning "Nothing to commit for initial commit."
  }
} else {
  # Commit only if there are staged changes
  git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) {
    git commit -m "chore: add/updated docs" | Out-Null
  }
}

# Configure remote origin
if (git remote | Select-String -Quiet '^origin$') {
  git remote set-url origin $RemoteUrl | Out-Null
} else {
  git remote add origin $RemoteUrl | Out-Null
}

try {
  git push -u origin $Branch
} catch {
  Write-Warning "Push failed. Authenticate with 'gh auth login' or set a PAT, then rerun: git push -u origin $Branch"
}

