# Scritto in PowerShell
# Questo script aggiorna i pacchetti winget e permette all'utente di scegliere,
# visualizzare e installare configurazioni di applicazioni da un file JSON
# con opzioni di controllo avanzate.

# --- Impostazioni Iniziali ---
$jsonPath = Join-Path $PSScriptRoot "data/config.json"

# --- Funzioni Ausiliarie ---

function Select-InstallationConfiguration {
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
        Write-Host "ERRORE: Impossibile leggere o analizzare il file JSON. Controlla la sintassi." -ForegroundColor Red
        return $null
    }

    $configNames = $configData.PSObject.Properties.Name
    if ($configNames.Count -eq 0) {
        Write-Host "ERRORE: Nessuna configurazione trovata nel file JSON." -ForegroundColor Red
        return $null
    }

    # Mostra il menu di scelta dettagliato
    Write-Host "Scegli una configurazione da installare:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $configNames.Count; $i++) {
        $configName = $configNames[$i]
        Write-Host "----------------------------------------"
        Write-Host "  [$($i+1)] $configName" -ForegroundColor Yellow
        # Mostra il contenuto di ogni pacchetto
        $programsInConfig = $configData.$configName
        foreach ($program in $programsInConfig) {
            Write-Host "      - $($program.Nome)"
        }
    }
    Write-Host "----------------------------------------"
    Write-Host "  [X] Esci dal programma" -ForegroundColor Red

    # Chiede all'utente di scegliere e valida l'input
    do {
        $choice = Read-Host "Inserisci il numero della tua scelta o 'X' per uscire"
        if ($choice -eq 'x') {
            return $null # L'utente ha scelto di uscire
        }
        try {
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

function Start-InstallationProcess {
    param (
        [System.Collections.ArrayList]$ProgramList
    )

    # Chiede la modalità di installazione
    Write-Host "Come vuoi procedere con l'installazione?" -ForegroundColor Cyan
    Write-Host "  [1] Installa tutto il pacchetto in una volta"
    Write-Host "  [2] Chiedi conferma per ogni singola applicazione"
    
    do {
        $mode = Read-Host "Scegli la modalità (1 o 2)"
        if ($mode -eq '1' -or $mode -eq '2') {
            $validMode = $true
        } else {
            Write-Host "Scelta non valida. Inserisci 1 o 2." -ForegroundColor Yellow
            $validMode = $false
        }
    } while (-not $validMode)

    # Itera e installa in base alla modalità scelta
    foreach ($programma in $ProgramList) {
        $doInstall = $false
        if ($mode -eq '1') {
            $doInstall = $true # Installa tutto
        } else {
            # Chiedi conferma per ogni app
            $confirm = Read-Host "Vuoi installare $($programma.Nome)? (S/N)"
            if ($confirm -match '^[sS]$') {
                $doInstall = $true
            }
        }

        if ($doInstall) {
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
        } else {
            Write-Host "Installazione di $($programma.Nome) saltata." -ForegroundColor Gray
        }
    }
}


# --- Inizio Script Principale ---

Write-Host "Inizializzazione Installazione..." -ForegroundColor Green

# --- Scelta Aggiornamento Winget ---
$updateChoice = Read-Host "Vuoi cercare e installare aggiornamenti per i programmi esistenti prima di procedere? (S/N)"
if ($updateChoice -match '^[sS]$') {
    Write-Host "Aggiornamento di tutti i pacchetti tramite Winget. Questa operazione potrebbe richiedere del tempo..." -ForegroundColor Cyan
    winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --wait
    Write-Host "Aggiornamento Winget completato." -ForegroundColor Green
}
else {
    Write-Host "Aggiornamento dei pacchetti saltato." -ForegroundColor Gray
}
Write-Host "================================================"


# --- Loop Principale di Installazione ---
$continueInstallation = $true
do {
    # Ottiene la lista di programmi dal JSON in base alla scelta dell'utente
    $programmiDaInstallare = Select-InstallationConfiguration -Path $jsonPath

    if ($null -ne $programmiDaInstallare) {
        # Converte in ArrayList per poterlo passare alla funzione
        $programListAsArrayList = [System.Collections.ArrayList]$programmiDaInstallare
        Start-InstallationProcess -ProgramList $programListAsArrayList
        
        Write-Host "Installazione del pacchetto completata." -ForegroundColor Green
        $another = Read-Host "Vuoi installare un altro pacchetto? (S/N)"
        if ($another -notmatch '^[sS]$') {
            $continueInstallation = $false
        }
    } else {
        # L'utente ha scelto di uscire dal menu di selezione
        $continueInstallation = $false
    }

} while ($continueInstallation)

Write-Host "Processo di installazione terminato. A presto!" -ForegroundColor Green
