<#
.SYNOPSIS
    Ein einfaches PowerShell Script um den Inhalt von Ordnern zu vergleichen.
.DESCRIPTION
    Mit diesem PowerShell Script können Inhalte von Ordnern verglichen werden. Zusätzlich kann eine Logdatei im CSV Format erstellt werden, diese enthält eine Überischt von Dateien die im Zielverzeichnis nicht existieren oder Unterschiede aufweisen.

    Die CSV Datei ist wie folgt aufgebaut:
    Zahl|Dateipfad

    Die Zahl steht hierbei für den Dateistatus:
    # 0 = Datei in Ordnung
    # 1 = Datei ist Ungleich
    # 2 = Datei wurde nicht gefunden

    Mit dem optionalen Parameter '-logfile' kann der Speicherort der Logdatei festgelegt werden. Wenn der Parameter '-uselogfile' nicht festgelegt wurde wird beim Start gefragt ob eine Logdatei erstellt werden soll.

    Beispiele:
    compare-folders.ps1 -sourceFolder C:\Test -targetFolder C:\Sicherungen\Test
    compare-folders.ps1 -sourceFolder C:\Test -targetFolder C:\Sicherungen\Test -logfile C:\output.csv
    compare-folders.ps1 -sourceFolder C:\Test -targetFolder C:\Sicherungen\Test -logfile C:\output.csv -uselogfile 1
.PARAMETER sourceFolder
    Quellverzeichnis 
.PARAMETER targetFolder
    Zielverzeichnis
.PARAMETER logfile
    Speicherort der Logdatei, ist dieser Parameter nicht festgelegt wird die Logdatei unter dem Namen 'output.csv' im aktuellen Arbeitsverzeichnis erstellt.
.PARAMETER uselogfile
    Gibt an ob eine Logdatei erstellt werden soll, ist dieser Parameter nicht festgelegt wird beim Start gefragt ob eine Logdatei erstellt werden soll.
.NOTES
    Author: Patrick Becker
    Date:   01.08.2017    
#>

 param (
    [Parameter(Mandatory=$true)][string]$sourceFolder,
    [Parameter(Mandatory=$true)][string]$targetFolder,
    [string]$logfile = "output.csv",
    [bool]$uselogfile = $(
        $title = "Logdatei"
        $message = "Soll während der Ausführung eine Logdatei ($logfile) erstellt werden? (J/N)"

        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&Nein", `
            "Diesen Schritt überspringen"

        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Ja", `
         "Eine Logdatei erstellen"

        $options = [System.Management.Automation.Host.ChoiceDescription[]]($no, $yes)
        return $host.ui.PromptForChoice($title, $message, $options, 0)
    )
 )

function CompareFiles
{
    param
    (
        [parameter(
            Mandatory = $true,
            HelpMessage = "Specifies the 1st file to compare. Make sure it's an absolute path with the file name and its extension."
        )]
        [string]
        $file1,

        [parameter(
            Mandatory = $true,
            HelpMessage = "Specifies the 2nd file to compare. Make sure it's an absolute path with the file name and its extension."
        )]
        [string]
        $file2
    )

    ( Get-FileHash $file1 ).Hash -eq ( Get-FileHash $file2 ).Hash
}

function CheckFolderExist
{
    param
    (
        [parameter(
            Mandatory = $true,
            HelpMessage = "Prüft ob der angegebene Ordner existiert, falls nicht wird eine Ausnahme ausgelöst."
        )]
        [string]
        $folder
    )

    if (-not (Test-Path $folder)) {
        throw [System.IO.DirectoryNotFoundException] "Der Ordner $folder existiert nicht."
    }
}

# Start

Try
{
    # Array mit folgenden Zählwerten: OK, Ungleich, Nicht gefunden
    [int[]] $c_files = @(0,0,0)

    # Status der aktuellen Datei
    # 0 = Datei in Ordnung
    # 1 = Datei ist Ungleich
    # 2 = Datei wurde nicht gefunden
    $status = -1

    CheckFolderExist $sourceFolder
    CheckFolderExist $targetFolder

    if ($uselogfile -eq 1) {
        $stream = [System.IO.StreamWriter] $logfile

        # CSV Header
        $stream.WriteLine("-1|$sourceFolder")
        $stream.WriteLine("-1|$targetFolder")
    }

    $files  = Get-ChildItem -Recurse -Attributes !Directory+!System -Path $sourceFolder

    Write-Host "`n### Dateien werden überprüft ###`n"

    foreach($file in $files ) {
        $sourceFile = $file.FullName.Remove(0, $sourceFolder.Length)
        $targetPath = join-path $targetFolder $sourceFile

        Write-Debug "$file.FullName $targetPath"

        if (Test-Path $targetPath) {
            if (CompareFiles $file.FullName $targetPath) {
                $status = 0
            } else {
                $status = 1
            }

        } else {
            $status = 2
        }

        switch ($status)
            {
                0 { Write-Host -NoNewline -Foreground Green "[ OK ] " }
                1 { Write-Host -NoNewline -Foreground Red "[ Ungleich ] " }
                2 { Write-Host -NoNewline -Foreground Yellow "[ Nicht gefunden ] " }
            }

        $c_files[$status] +=1
        if ($uselogfile -eq 1) {
            $stream.WriteLine("{0}|{1}", $status, $targetPath) }

        Write-Host $sourceFile
    }

    Write-Host "`n### Prüfung abgeschlossen ###`n"

    # Bericht Ausgeben

    Write-Host ("Quellverzeichnis`t{0}" -f $sourceFolder)
    Write-Host ("Zielverzeichnis `t{0}`n" -f $targetFolder)


    if ($c_files[1] -eq 0) {
        Write-Host "Es wurden keine unterschiedlichen Dateien gefunden."
    } else {
        Write-Host ("Es wurde(n) {0} unterschiedliche Datei(en) gefunden." -f $c_files[1])
    }

    if ($c_files[2] -ne 0) {
        $filecounter = $c_files[0] + $c_files[1] + $c_files[2]
        Write-Host -Foreground Yellow ("Von {0} Dateien wurde(n) {1} Datei(en) nicht im Zielverzeichnis gefunden." -f $filecounter, $c_files[2])
    }

} catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

    Write-Host -Foreground Red -Background Black "Es ist ein Fehler aufgereten:`n$ErrorMessage"

} finally {
    if ($uselogfile -eq 1 -and $stream) {
        $stream.Close()
    }
}