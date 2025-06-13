#####################################################################################
#
# Name: Convert Identity Portal (Sigma) (FORMs ONLY) export to pretty json + layout + JS handler extractor
#
# - This script focuses on the complexity within an Identity Portal Form with embedded Javascript.
# - Using the Identity Portal admin console, export only a single IP FORM, then run this powershell script to import it as a txt file.
#
# Goals:
# - Converts TXT to .pretty.json with fixed trim ending - sorted by tag {can be re-imported}
# - Extracts all layout blocks to per-form .layout.json files with deep sort {allow search within notepad++ / compare with winmerge}
# - Extracts all inline JS handlers to readable .js.txt files {allow search within notepad++ / compare with winmerge}
# - Creates combined handler summary .txt
# - Opens all outputs in Notepad++
#
# ANA 06/2025  - Version 6.6.7
#
#####################################################################################

function Select-TxtFile {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Text files (*.txt)|*.txt"
    $dialog.Title = "Select a TXT file with JSON content"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

function Decode-JSString {
    param([string]$js)
    try {
        return ($js -replace '\n', "`r`n") `
                   -replace '\u0027', "'" `
                   -replace '\\', '\\' `
                   -replace '\"', '"'
    } catch {
        Write-Warning "Failed to decode JS string: $_"
        return $js
    }
}

function Sort-NestedByTag {
    param ([object]$input)
    if ($input -is [System.Collections.IDictionary]) {
        $sorted = @{}
        foreach ($key in ($input.Keys | Sort-Object)) {
            $sorted[$key] = Sort-NestedByTag $input[$key]
        }
        return $sorted
    } elseif ($input -is [System.Collections.IEnumerable] -and !$input.GetType().Name.Contains('String')) {
        return ($input | Sort-Object {
            if ($_ -is [PSCustomObject] -and $_.tag) { return $_.tag }
            return $_
        }) | ForEach-Object { Sort-NestedByTag $_ }
    } else {
        return $input
    }
}

function ConvertTo-LayoutObjects {
    param([object]$layoutRaw)
    if ($layoutRaw -is [string]) {
        try {
            return ConvertFrom-Json $layoutRaw
        } catch {
            try {
                $decoded = $layoutRaw -replace '\\n', '' -replace '\\t', '' -replace '\\r', ''
                return ConvertFrom-Json $decoded
            } catch {
                Write-Warning "Layout is a string but not valid JSON after decode attempt"
                return @()
            }
        }
    }
    if ($layoutRaw -is [System.Collections.IDictionary]) {
        return @($layoutRaw)
    }
    if ($layoutRaw -is [System.Collections.IEnumerable] -and !$layoutRaw.GetType().Name.Contains('String')) {
        return Sort-NestedByTag $layoutRaw
    }
    Write-Warning "Layout was neither an object nor a list"
    return @()
}

$filePath = Select-TxtFile
if ($filePath) {
    try {
        $jsonContent = Get-Content -Path $filePath -Raw
        if (-not $jsonContent) {
            throw "The file is empty or could not be read."
        }
        try {
            $jsonObject = $jsonContent | ConvertFrom-Json
        } catch {
            Write-Output "First 200 characters of file:`n$jsonContent.Substring(0, [Math]::Min(200, $jsonContent.Length))"
            throw "ConvertFrom-Json failed: $_"
        }
        if (-not $jsonObject.export -or $jsonObject.export.Count -eq 0) {
            throw "The 'export' array is missing or empty in the JSON file."
        }

        # Minimal sort formProps by .tag for each form
        foreach ($item in $jsonObject.export) {
            if ($item.formProps -is [System.Collections.IEnumerable]) {
                $item.formProps = $item.formProps | Sort-Object tag
            }
        }

        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        $folder = [System.IO.Path]::GetDirectoryName($filePath)
        $firstFormName = if ($jsonObject.export[0].name) { $jsonObject.export[0].name } elseif ($jsonObject.export[0].tag) { $jsonObject.export[0].tag } else { "form" }
        $safeFirstFormName = ($firstFormName -replace '[^\w\-]', '_') -replace '_+', '_'
        $prettyPath = Join-Path $folder "$baseName`_${safeFirstFormName}.pretty.json"
        ($jsonObject | ConvertTo-Json -Depth 20).TrimEnd("`r", "`n") | Set-Content -Path $prettyPath -Encoding UTF8 -NoNewline
        Write-Output "Pretty JSON (gold standard + sorted formProps) saved to $prettyPath"

        $outputFilePaths = @()
        $handlerTextAllForms = ""
        $summaryIndex = 1
        $layoutIndex = 0

        foreach ($item in $jsonObject.export) {
            $formName = if ($item.name) { $item.name } elseif ($item.tag) { $item.tag } else { "form_$layoutIndex" }
            $safeFormName = ($formName -replace '[^\w\-]', '_') -replace '_+', '_'
            if ($item.layout) {
                try {
                    $layoutObjects = ConvertTo-LayoutObjects $item.layout
                    if ($layoutObjects.Count -eq 0) {
                        throw "Parsed layout is empty or unrecognized."
                    }
                    $layoutFile = Join-Path $folder "$baseName`_${safeFormName}.layout.json"
                    ($layoutObjects | ConvertTo-Json -Depth 20) | Set-Content -Path $layoutFile -Encoding UTF8
                    Write-Output "Saved layout to $layoutFile"
                    $outputFilePaths += $layoutFile
                    $formHeaderWritten = $false
                    $formSummary = ""
                    foreach ($layoutBlock in $layoutObjects) {
                        $controlList = @()
                        if ($layoutBlock.type -eq 'tab' -and $layoutBlock.tabs) {
                            foreach ($tab in $layoutBlock.tabs) {
                                $controlList += $tab.layout
                            }
                        } elseif ($layoutBlock.layout) {
                            $controlList += $layoutBlock.layout
                        } else {
                            $controlList += $layoutBlock
                        }
                        foreach ($control in $controlList) {
                            foreach ($prop in @("onChange", "initializationHandler", "validateHandler")) {
                                $handlerProp = $control.PSObject.Properties[$prop]
                                if ($handlerProp) {
                                    $handlerRaw = $handlerProp.Value
                                    $decoded = Decode-JSString $handlerRaw
                                    $fieldName = if ($control.label) { $control.label } elseif ($control.ref) { $control.ref } else { "field" }
                                    $safeFieldName = ($fieldName -replace '[^\w\-]', '_') -replace '_+', '_'
                                    if (-not $formHeaderWritten) {
                                        $handlerTextAllForms += @"
####################################################################
# FORM: $formName - HANDLER SUMMARY
####################################################################
"@
                                        $formHeaderWritten = $true
                                    }
                                    $handlerTextAllForms += @"
[$prop for $fieldName]
----------------------------------------
$decoded
"@
                                    $formSummary += "[$prop for $fieldName]`r`n"
                                    $handlerFile = Join-Path $folder "$baseName`_${safeFormName}.${safeFieldName}.${prop}.js.txt"
                                    $decoded | Set-Content -Path $handlerFile -Encoding UTF8
                                    $outputFilePaths += $handlerFile
                                }
                            }
                        }
                    }
                    if ($formSummary) {
                        $handlerTextAllForms += "`r`nSUMMARY of handlers for form ${summaryIndex}: $formName`r`n$formSummary`r`n"
                        $summaryIndex++
                    }
                } catch {
                    Write-Warning "Skipping layout ${layoutIndex}: Failed to parse layout JSON - $_"
                }
            }
            $layoutIndex++
        }

        if ($handlerTextAllForms) {
            $handlerOutFile = Join-Path $folder "$baseName`_${safeFirstFormName}.handler_summary.txt"
            $handlerTextAllForms | Set-Content -Path $handlerOutFile -Encoding UTF8
            Write-Output "Combined handlers saved to $handlerOutFile"
            $outputFilePaths += $handlerOutFile
        }

        $notepadPlusPlus = "C:\\Program Files\\Notepad++\\notepad++.exe"
        if (Test-Path $notepadPlusPlus) {
            $allFiles = @($prettyPath) + $outputFilePaths
            $quoted = $allFiles | ForEach-Object { '"' + $_ + '"' }
            Start-Process -FilePath $notepadPlusPlus -ArgumentList ($quoted -join ' ')
        } else {
            Write-Output "Notepad++ not found at: $notepadPlusPlus"
        }

    } catch {
        Write-Error "Failed to process JSON. Error: $_"
    }
} else {
    Write-Output "Operation cancelled."
}
