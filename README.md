# Inhalte von Ordnern vergleichen

![Screenshot compare-folders](https://raw.githubusercontent.com/patbec/compare-folders/master/screenshot-compare-folders.png)

### Beschreibung

Mit diesem PowerShell Script können Inhalte von Ordnern verglichen werden. Zusätzlich kann eine Logdatei im CSV Format erstellt werden, diese enthält eine Übersicht von Dateien die im Zielverzeichnis nicht existieren oder Unterschiede aufweisen.

Die CSV Datei ist wie folgt aufgebaut:
```
Zahl|Dateipfad
```

Die Zahl steht hierbei für den Dateistatus:
```
# 0 = Datei in Ordnung
# 1 = Datei ist Ungleich
# 2 = Datei wurde nicht gefunden
```

Mit dem optionalen Parameter **-logfile** kann der Speicherort der Logdatei festgelegt werden. Wenn der Parameter **-uselogfile** nicht festgelegt wurde wird beim Start gefragt, ob eine Logdatei erstellt werden soll.

Beispiele:
```
compare-folders.ps1 -sourceFolder C:\Test -targetFolder C:\Sicherungen\Test
compare-folders.ps1 -sourceFolder C:\Test -targetFolder C:\Sicherungen\Test -logfile C:\output.csv
compare-folders.ps1 -sourceFolder C:\Test -targetFolder C:\Sicherungen\Test -logfile C:\output.csv -uselogfile 1
```

Um sich die ausführliche Hilfe anzuzeigen verwenden Sie den folgenden Befehl:
```
Get-Help <pfad>\compare-folders.ps1 -detailed
```
