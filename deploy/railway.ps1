<#
.SYNOPSIS
  Déploie ProLink sur Railway via la CLI : PostgreSQL, Redis, API FastAPI, back-office Next.js.

.DESCRIPTION
  À lancer depuis la racine du dépôt, après `railway login` et `railway init` (ou `railway link`).

    .\deploy\railway.ps1 -Setup     # 1re fois : crée Postgres, Redis, api, backoffice, variables, domaines, puis déploie
    .\deploy\railway.ps1            # redéploie api + backoffice
    .\deploy\railway.ps1 -Only api  # redéploie un seul service (api | backoffice)

  Les variables qui référencent d'autres services utilisent la syntaxe Railway ${{Service.VAR}} :
  elles sont résolues par Railway, pas par PowerShell (d'où les guillemets simples).
#>
param(
  [switch]$Setup,
  [ValidateSet('all', 'api', 'backoffice')]
  [string]$Only = 'all'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Invoke-Railway {
  # La CLI écrit sa progression sur stderr : ne pas la traiter comme une erreur PowerShell.
  $ErrorActionPreference = 'Continue'
  Write-Host "> railway $($args -join ' ')" -ForegroundColor DarkGray
  & railway @args
  if ($LASTEXITCODE -ne 0) { throw "railway $($args[0]) a échoué (code $LASTEXITCODE)" }
}

# --- Pré-requis --------------------------------------------------------------
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
  throw 'CLI Railway introuvable : npm i -g @railway/cli (ou scoop install railway)'
}
& railway whoami *> $null
if ($LASTEXITCODE -ne 0) { throw "Non connecté : lancez d'abord  railway login" }
& railway status *> $null
if ($LASTEXITCODE -ne 0) {
  throw "Aucun projet lié : lancez  railway init --name prolink  (ou  railway link  si le projet existe déjà)"
}

# --- Création des services (une seule fois) ---------------------------------
if ($Setup) {
  Write-Host "`n== Bases de données ==" -ForegroundColor Cyan
  Invoke-Railway add --database postgres   # service « Postgres »
  Invoke-Railway add --database redis      # service « Redis »

  Write-Host "`n== Services applicatifs ==" -ForegroundColor Cyan
  Invoke-Railway add --service api
  Invoke-Railway add --service backoffice

  Write-Host "`n== Variables api ==" -ForegroundColor Cyan
  # PowerShell 5.1 retire les guillemets des arguments passés aux exécutables : on les échappe.
  $q = if ($PSVersionTable.PSVersion.Major -lt 7) { '\"' } else { '"' }
  Invoke-Railway variable set --service api --skip-deploys `
    'DATABASE_URL=${{Postgres.DATABASE_URL}}' `
    'REDIS_URL=${{Redis.REDIS_URL}}' `
    'PORT=8000' `
    'ENVIRONMENT=staging' `
    'SEED_DEMO=true' `
    'OTP_DEV_ECHO=true' `
    ('CORS_ORIGINS=[{0}https://${{{{backoffice.RAILWAY_PUBLIC_DOMAIN}}}}{0},{0}*{0}]' -f $q) `
    'TRANSLATION_PROVIDER=libretranslate' `
    'TRANSLATION_BASE_URL=https://libretranslate.de'
  # Secret aléatoire (hex) ; appel direct pour ne pas l'afficher dans la console.
  $bytes = New-Object byte[] 48
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $jwt = -join ($bytes | ForEach-Object { $_.ToString('x2') })
  $ErrorActionPreference = 'Continue'
  & railway variable set "JWT_SECRET=$jwt" --service api --skip-deploys *> $null
  $ErrorActionPreference = 'Stop'
  if ($LASTEXITCODE -ne 0) { throw 'Échec de JWT_SECRET' }

  Write-Host "`n== Variables backoffice ==" -ForegroundColor Cyan
  Invoke-Railway variable set --service backoffice --skip-deploys `
    'PORT=3000' `
    'NEXT_PUBLIC_API_URL=https://${{api.RAILWAY_PUBLIC_DOMAIN}}'

  Write-Host "`n== Domaines publics ==" -ForegroundColor Cyan
  Invoke-Railway domain --service api --port 8000
  Invoke-Railway domain --service backoffice --port 3000
}

# --- Déploiement (upload du dossier, build Dockerfile, config railway.toml) -
if ($Only -in 'all', 'api') {
  Write-Host "`n== Déploiement api ==" -ForegroundColor Cyan
  Invoke-Railway up Api --path-as-root --service api --detach -m 'deploy api (CLI)'
}
if ($Only -in 'all', 'backoffice') {
  Write-Host "`n== Déploiement backoffice ==" -ForegroundColor Cyan
  Invoke-Railway up backoffice --path-as-root --service backoffice --detach -m 'deploy backoffice (CLI)'
}

Write-Host "`nDéploiements lancés. Suivi :" -ForegroundColor Green
Write-Host '  railway logs --service api'
Write-Host '  railway logs --service backoffice'
Write-Host '  railway domain list --service api'
