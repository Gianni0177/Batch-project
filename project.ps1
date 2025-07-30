Write-Host "Inizializzazione Installazione..."
Write-Host "Aggiornamento di tutti i pacchetti tramite Winget. Questa operazione potrebbe richiedere del tempo..."
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --wait
Write-Host "Aggiornamento Winget completato."
Write-Host "--------------------------------"

Write-Host "Inizio installazione delle applicazioni di base."

$programmi = @(
    @{ Nome = "Wintoys"; ID = "Microsoft.Wintoys" },
    @{ Nome = "Microsoft Powertoys"; ID = "Microsoft.PowerToys" },
    @{ Nome = "WinDBG Utility"; ID = "Microsoft.WinDbg" },
    @{ Nome = "Microsoft PC Manager"; ID = "Microsoft.PCManager" },
    @{ Nome = "Google Chrome"; ID = "Google.Chrome" },
    @{ Nome = "Foxit PDF Reader"; ID = "Foxit.FoxitReader" }
)


foreach ($programma in $programmi) {
    Write-Host "Installazione di: $($programma.Nome)..."
    
    try {
        winget install --id $programma.ID --silent --accept-package-agreements --accept-source-agreements --wait
        Write-Host "Installazione di $($programma.Nome) completata."
    }
    catch {
        # Se si verifica un errore, scrive un messaggio di avviso e continua con il programma successivo
        Write-Host "ERRORE: Impossibile installare $($programma.Nome) (ID: $($programma.ID))."
        # Stampa il messaggio di errore specifico
        Write-Host "Dettagli errore: $_"
    }
    Write-Host "----------------"
}

Write-Host "Processo di installazione delle applicazioni di base terminato."
