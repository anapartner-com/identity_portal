#####################################################################################
#  Name: Script #2: DELTA REVIEW WINMERGE
#  Goal: Review & reduce analysis effort of Symantec vApp Identity Portal (FULL) export files 
#        Between different ENV or the SAME env at different times or monitor updates
# 
#  PowerShell Script to ensure UTF-8 Encoding, Sort JSON using native PowerShell,
#
#  Focus on three (3) comparison operations:
#
#     1) Full file sort by type, then tag, then compare with WinMerge
#     2) Filter & export by type=FORM, then sort by tag and compare with WinMerge
#     3) Filter & export by type=PLUGIN, then sort by tag and compare with WinMerge
#    
#  A deep recursive sort by tag will be performed for operations 1 and 2.
#
#  ANA 05/2025  Version 1.2
#
#####################################################################################

function Get-FilePath {
    param ([string]$initialDirectory = [System.Environment]::GetFolderPath("Desktop"))
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.InitialDirectory = $initialDirectory
    $dialog.Filter = "Portal TXT files (*.txt)|*.txt|JSON files (*.json)|*.json"
    $dialog.Multiselect = $false
    $dialog.Title = "Select a JSON file"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    } else {
        Write-Host "No file selected. Exiting script."
        exit
    }
}

function Write-UTF8NoBOM {
    param ([string]$filePath, [string[]]$content)
    $streamWriter = [System.IO.StreamWriter]::new($filePath, $false, [System.Text.Encoding]::UTF8)
    $content | ForEach-Object { $streamWriter.WriteLine($_) }
    $streamWriter.Close()
}

function Sort-NestedByTag {
    param ([array]$jsonData)
    $jsonData = $jsonData | Sort-Object { $_.tag }
    foreach ($item in $jsonData) {
        foreach ($prop in $item.PSObject.Properties) {
            if ($prop.Value -is [System.Collections.IEnumerable] -and $prop.Value -ne $null -and $prop.Value -ne $item) {
                $prop.Value = Sort-NestedByTag -jsonData $prop.Value
            }
        }
    }
    return $jsonData
}

# Select files
$inputFilePath1 = Get-FilePath
$inputFilePath2 = Get-FilePath

# Paths
$winMergePath = "C:\Program Files (x86)\WinMerge\WinMergeU.exe"
$encodedFilePath1 = "$inputFilePath1.encoded.txt"
$encodedFilePath2 = "$inputFilePath2.encoded.txt"
$prettyFilePath1 = "$inputFilePath1.pretty.json"
$prettyFilePath2 = "$inputFilePath2.pretty.json"
$filteredFilePath1 = "$inputFilePath1.filtered_sorted_by_form.json"
$filteredFilePath2 = "$inputFilePath2.filtered_sorted_by_form.json"
$pluginFilePath1 = "$inputFilePath1.filtered_sorted_by_plugin.json"
$pluginFilePath2 = "$inputFilePath2.filtered_sorted_by_plugin.json"
$deepSortFilePath1 = "$inputFilePath1.full_sort_by_type_then_deep_sorted_by_tag.json"
$deepSortFilePath2 = "$inputFilePath2.full_sort_by_type_then_deep_sorted_by_tag.json"

# UTF-8 convert
Write-Host "Converting files to UTF-8 without BOM..."
$content1 = Get-Content "$inputFilePath1" -Raw
Write-UTF8NoBOM -filePath "$encodedFilePath1" -content $content1
$content2 = Get-Content "$inputFilePath2" -Raw
Write-UTF8NoBOM -filePath "$encodedFilePath2" -content $content2

# Load and prettify
Write-Host "Prettifying JSON files..."
$jsonData1 = Get-Content -Raw -Path $encodedFilePath1 | ConvertFrom-Json
$jsonData2 = Get-Content -Raw -Path $encodedFilePath2 | ConvertFrom-Json
($jsonData1 | ConvertTo-Json -Depth 20).TrimEnd("`r", "`n") | Set-Content -Path $prettyFilePath1 -Encoding utf8 -NoNewline
($jsonData2 | ConvertTo-Json -Depth 20).TrimEnd("`r", "`n") | Set-Content -Path $prettyFilePath2 -Encoding utf8 -NoNewline
Write-Host "Pretty files saved."

# Filter FORM
Write-Host "Filtering FORM data..."
$filteredData1 = $jsonData1.export | Where-Object { $_.tag -like 'FORM_*' -and $_.type -eq 'FORM' } | Sort-Object { $_.type }, { $_.tag }
$filteredData2 = $jsonData2.export | Where-Object { $_.tag -like 'FORM_*' -and $_.type -eq 'FORM' } | Sort-Object { $_.type }, { $_.tag }
if ($filteredData1.Count -gt 0) {
    $filteredData1 = Sort-NestedByTag -jsonData $filteredData1
    ($filteredData1 | ConvertTo-Json -Depth 20).TrimEnd("`r", "`n") | Set-Content -Path $filteredFilePath1 -Encoding utf8 -NoNewline
}
if ($filteredData2.Count -gt 0) {
    $filteredData2 = Sort-NestedByTag -jsonData $filteredData2
    ($filteredData2 | ConvertTo-Json -Depth 20).TrimEnd("`r", "`n") | Set-Content -Path $filteredFilePath2 -Encoding utf8 -NoNewline
}

# Filter PLUGIN
Write-Host "Filtering PLUGIN data..."
$pluginData1 = $jsonData1.export | Where-Object { $_.type -eq 'PLUGIN' } | Sort-Object { $_.tag }
$pluginData2 = $jsonData2.export | Where-Object { $_.type -eq 'PLUGIN' } | Sort-Object { $_.tag }
if ($pluginData1.Count -gt 0) {
    $pluginData1 = Sort-NestedByTag -jsonData $pluginData1
    ($pluginData1 | ConvertTo-Json -Depth 20).TrimEnd("`r", "`n") | Set-Content -Path $pluginFilePath1 -Encoding utf8 -NoNewline
}
if ($pluginData2.Count -gt 0) {
    $pluginData2 = Sort-NestedByTag -jsonData $pluginData2
    ($pluginData2 | ConvertTo-Json -Depth 20).TrimEnd("`r", "`n") | Set-Content -Path $pluginFilePath2 -Encoding utf8 -NoNewline
}

# Full sort
Write-Host "Performing full deep sort..."
$sortedData1 = $jsonData1.export | Sort-Object { $_.type }, { $_.tag }
$sortedData2 = $jsonData2.export | Sort-Object { $_.type }, { $_.tag }
$sortedData1 = Sort-NestedByTag -jsonData $sortedData1
$sortedData2 = Sort-NestedByTag -jsonData $sortedData2
($sortedData1 | ConvertTo-Json -Depth 20).TrimEnd("`r", "`n") | Set-Content -Path $deepSortFilePath1 -Encoding utf8 -NoNewline
($sortedData2 | ConvertTo-Json -Depth 20).TrimEnd("`r", "`n") | Set-Content -Path $deepSortFilePath2 -Encoding utf8 -NoNewline

# Launch WinMerge comparisons
Write-Host "Launching WinMerge comparisons..."
& $winMergePath /s $filteredFilePath1 $filteredFilePath2
& $winMergePath /s $pluginFilePath1 $pluginFilePath2
& $winMergePath /s $deepSortFilePath1 $deepSortFilePath2

Write-Host "Analysis complete."
