$jsonPath = Join-Path $PSScriptRoot "data/config.json"

function Get-ProgramListFromJson {
    param (
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Host "ERRORE: File di configurazione non trovato in '$Path'." -ForegroundColor Red
        return $null
    }

    try {
        $configData = Get-Content -Path $Path -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host "ERRORE: Impossibile leggere o analizzare il file JSON. Controlla la sintassi del file." -ForegroundColor Red
        Write-Host "Dettagli errore: $_" -ForegroundColor Red
        return $null
    }

    $configNames = $configData.PSObject.Properties.Name
    if ($configNames.Count -eq 0) {
        Write-Host "ERRORE: Nessuna configurazione trovata nel file JSON." -ForegroundColor Red
        return $null
    }

    Write-Host "Scegli una configurazione da installare:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $configNames.Count; $i++) {
        Write-Host "  [$($i+1)] $($configNames[$i])"
    }

    do {
        try {
            $choice = Read-Host "Inserisci il numero della tua scelta"
            $choiceIndex = [int]$choice - 1
            if ($choiceIndex -ge 0 -and $choiceIndex -lt $configNames.Count) {
                $validChoice = $true
            } else {
                Write-Host "Scelta non valida. Riprova." -ForegroundColor Yellow
                $validChoice = $false
            }
        }
        catch {
            Write-Host "Input non valido. Inserisci solo un numero. Riprova." -ForegroundColor Yellow
            $validChoice = $false
        }
    } while (-not $validChoice)

    $selectedConfigName = $configNames[$choiceIndex]
    return $configData.$selectedConfigName
}

Write-Host "Inizializzazione Installazione..." -ForegroundColor Green

Write-Host "Aggiornamento di tutti i pacchetti tramite Winget. Questa operazione potrebbe richiedere del tempo..." -ForegroundColor Cyan
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --wait
Write-Host "Aggiornamento Winget completato." -ForegroundColor Green
Write-Host "--------------------------------"

Write-Host "Caricamento configurazioni dal file JSON..." -ForegroundColor Cyan

$programmiDaInstallare = Get-ProgramListFromJson -Path $jsonPath

if ($null -ne $programmiDaInstallare) {
    Write-Host "Inizio installazione delle applicazioni selezionate." -ForegroundColor Cyan

    foreach ($programma in $programmiDaInstallare) {
        Write-Host "Installazione di: $($programma.Nome)..." -ForegroundColor Yellow
        
        try {
            winget install --id $programma.ID --silent --accept-package-agreements --accept-source-agreements --wait
            Write-Host "Installazione di $($programma.Nome) completata." -ForegroundColor Green
        }
        catch {
            Write-Host "ERRORE: Impossibile installare $($programma.Nome) (ID: $($programma.ID))." -ForegroundColor Red
            Write-Host "Dettagli errore: $_" -ForegroundColor Red
        }
        Write-Host "----------------"
    }
} else {
    Write-Host "Nessuna azione di installazione eseguita a causa di errori precedenti." -ForegroundColor Yellow
}

Write-Host "Processo di installazione terminato." -ForegroundColor Green
