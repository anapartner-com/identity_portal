#####################################################################################
#
# Goal: Review & reduce analysis effort of Symantec vApp Identity Portal (FULL or FORM) export txt files 
# 
#  PowerShell Script to open TXT or JSON file created by Identity Portal
#  and convert it into clean, pretty JSON for human management.
#
#   -Recursively detects & parses any deeply escaped JSON strings (like "layout").
#   -Unescapes double-escaped characters, Unicode (\u0027), and line breaks.
#   -Outputs a readable .pretty.json file.
#   -Opens result in Notepad++ if installed.
#
#
#  ANA 04/2025  -  Version 1.0
#
#####################################################################################

function Select-TxtFile {
    Add-Type -AssemblyName System.Windows.Forms

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Text or JSON files (*.txt;*.json)|*.txt;*.json"
    $openFileDialog.Title = "Select a TXT or JSON file with raw Identity Portal export"

    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $openFileDialog.FileName
    } else {
        Write-Output "No file selected."
        return $null
    }
}

function Try-ParseJsonString {
    param (
        [string]$value
    )

    $trimmed = $value.Trim()

    # Skip short or clearly non-JSON strings
    if ($trimmed.Length -lt 3 -or ($trimmed[0] -ne '{' -and $trimmed[0] -ne '[')) {
        return $value
    }

    # Attempt 1: Direct parse
    try {
        return $trimmed | ConvertFrom-Json -ErrorAction Stop
    } catch {}

    # Attempt 2: Manual unescaping and clean-up
    try {
        $unescaped = $trimmed `
            -replace '\\r', "`r" `
            -replace '\\n', "`n" `
            -replace '\\\"', '"' `
            -replace '\\"', '"' `
            -replace '\\u0027', "'" `
            -replace '\\\\', '\'  # turn \\ into \

        # Remove outer quotes if it's a JSON string wrapped in quotes
        if ($unescaped.StartsWith('"') -and $unescaped.EndsWith('"')) {
            $unescaped = $unescaped.Substring(1, $unescaped.Length - 2)
        }

        return $unescaped | ConvertFrom-Json -ErrorAction Stop
    } catch {}

    # Attempt 3: Deep unescape using Regex
    try {
        $regexUnescaped = [System.Text.RegularExpressions.Regex]::Unescape($trimmed)
        return $regexUnescaped | ConvertFrom-Json -ErrorAction Stop
    } catch {}

    return $value  # Return original string if all attempts fail
}

function RecursivelyConvertEmbeddedJson {
    param (
        [object]$inputObject
    )

    if ($inputObject -is [System.Collections.IDictionary]) {
        $converted = @{}
        foreach ($key in $inputObject.Keys) {
            $val = $inputObject[$key]

            if ($val -is [string]) {
                $parsed = Try-ParseJsonString -value $val
                $converted[$key] = RecursivelyConvertEmbeddedJson -inputObject $parsed
            } else {
                $converted[$key] = RecursivelyConvertEmbeddedJson -inputObject $val
            }
        }
        return $converted
    } elseif ($inputObject -is [System.Collections.IEnumerable] -and $inputObject -notlike '*String*') {
        $convertedList = @()
        foreach ($item in $inputObject) {
            $convertedList += RecursivelyConvertEmbeddedJson -inputObject $item
        }
        return $convertedList
    } else {
        return $inputObject
    }
}

function Sort-JsonRecursively {
    param (
        [Parameter(Mandatory = $true)]
        [object]$jsonObject
    )

    $sortedObject = @{}

    foreach ($key in ($jsonObject.PSObject.Properties.Name | Sort-Object)) {
        $value = $jsonObject.$key

        if ($value -is [System.Collections.IDictionary]) {
            $sortedObject[$key] = Sort-JsonRecursively -jsonObject $value
        } elseif ($value -is [System.Collections.IEnumerable] -and $value -notlike '*String*') {
            $sortedArray = @()
            foreach ($item in $value) {
                if ($item -is [PSCustomObject]) {
                    $sortedArray += Sort-JsonRecursively -jsonObject $item
                } else {
                    $sortedArray += $item
                }
            }
            $sortedObject[$key] = $sortedArray
        } else {
            $sortedObject[$key] = $value
        }
    }

    return [PSCustomObject]$sortedObject
}

# --- MAIN EXECUTION ---
$filePath = Select-TxtFile

if ($filePath) {
    $jsonContent = Get-Content -Path $filePath -Raw

    try {
        $jsonObject = $jsonContent | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Output "Error: The selected file does not contain valid top-level JSON."
        exit
    }

    # Recursively fix escaped JSON strings
    $convertedObject = RecursivelyConvertEmbeddedJson -inputObject $jsonObject

    # Optional: recursively sort keys for readability
    $sortedJsonObject = Sort-JsonRecursively -jsonObject $convertedObject

    # Pretty print the final result
    $prettyJson = $sortedJsonObject | ConvertTo-Json -Depth 15 -Compress:$false
    $trimmedJson = $prettyJson.TrimEnd("`r", "`n")

    # Save to .pretty.json
    $outputPath = [System.IO.Path]::ChangeExtension($filePath, "pretty.json")
    $trimmedJson | Set-Content -Path $outputPath -NoNewline

    Write-Output "Pretty JSON saved to $outputPath"

    # Open in Notepad++ if available
    $notepadPlusPlusPath = "C:\Program Files\Notepad++\notepad++.exe"
    if (Test-Path $notepadPlusPlusPath) {
        Start-Process -FilePath $notepadPlusPlusPath -ArgumentList "`"$outputPath`""
    } else {
        Write-Output "Notepad++ is not installed at: $notepadPlusPlusPath"
    }
} else {
    Write-Output "Operation cancelled."
}
