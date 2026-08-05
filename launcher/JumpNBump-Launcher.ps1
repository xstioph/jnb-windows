Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$packageRoot = $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $packageRoot 'jumpnbump.exe'))) {
    $packageRoot = Split-Path -Parent $PSScriptRoot
}

$gamePath = Join-Path $packageRoot 'jumpnbump.exe'
$levelsPath = Join-Path $packageRoot 'levels'

$form = New-Object System.Windows.Forms.Form
$form.Text = "Jump 'n Bump - Level Launcher"
$form.StartPosition = 'CenterScreen'
$form.ClientSize = New-Object System.Drawing.Size(620, 430)
$form.MinimumSize = New-Object System.Drawing.Size(520, 360)

$heading = New-Object System.Windows.Forms.Label
$heading.Text = 'Choose a level'
$heading.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$heading.AutoSize = $true
$heading.Location = New-Object System.Drawing.Point(18, 16)
$form.Controls.Add($heading)

$levelList = New-Object System.Windows.Forms.ListBox
$levelList.Location = New-Object System.Drawing.Point(20, 58)
$levelList.Size = New-Object System.Drawing.Size(580, 275)
$levelList.Anchor = 'Top,Bottom,Left,Right'
$levelList.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$levelList.DisplayMember = 'Name'
$form.Controls.Add($levelList)

$fullscreen = New-Object System.Windows.Forms.CheckBox
$fullscreen.Text = 'Fullscreen'
$fullscreen.AutoSize = $true
$fullscreen.Location = New-Object System.Drawing.Point(20, 350)
$fullscreen.Anchor = 'Bottom,Left'
$form.Controls.Add($fullscreen)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = 'Refresh'
$refreshButton.Size = New-Object System.Drawing.Size(90, 34)
$refreshButton.Location = New-Object System.Drawing.Point(405, 342)
$refreshButton.Anchor = 'Bottom,Right'
$form.Controls.Add($refreshButton)

$playButton = New-Object System.Windows.Forms.Button
$playButton.Text = 'Play'
$playButton.Size = New-Object System.Drawing.Size(100, 34)
$playButton.Location = New-Object System.Drawing.Point(500, 342)
$playButton.Anchor = 'Bottom,Right'
$playButton.Enabled = $false
$form.AcceptButton = $playButton
$form.Controls.Add($playButton)

$status = New-Object System.Windows.Forms.Label
$status.AutoEllipsis = $true
$status.Location = New-Object System.Drawing.Point(20, 392)
$status.Size = New-Object System.Drawing.Size(580, 22)
$status.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($status)

function Refresh-Levels {
    $levelList.Items.Clear()
    if (-not (Test-Path -LiteralPath $levelsPath)) {
        New-Item -ItemType Directory -Path $levelsPath | Out-Null
    }

    $files = Get-ChildItem -LiteralPath $levelsPath -Filter '*.dat' -File -Recurse |
        Sort-Object FullName

    foreach ($file in $files) {
        $relativeName = $file.FullName.Substring($levelsPath.Length).TrimStart('\')
        [void]$levelList.Items.Add([pscustomobject]@{
            Name = [System.IO.Path]::ChangeExtension($relativeName, $null)
            Path = $file.FullName
        })
    }

    if ($levelList.Items.Count -gt 0) {
        $levelList.SelectedIndex = 0
        $status.Text = "$($levelList.Items.Count) level(s) found."
    }
    else {
        $status.Text = "No .dat levels found in: $levelsPath"
    }
}

function Start-SelectedLevel {
    if ($null -eq $levelList.SelectedItem) {
        return
    }
    if (-not (Test-Path -LiteralPath $gamePath)) {
        [System.Windows.Forms.MessageBox]::Show(
            "jumpnbump.exe was not found in:`n$packageRoot",
            "Jump 'n Bump",
            'OK',
            'Error'
        ) | Out-Null
        return
    }

    $selected = $levelList.SelectedItem
    $arguments = '-dat "' + $selected.Path.Replace('"', '\"') + '"'
    if ($fullscreen.Checked) {
        $arguments += ' -fullscreen'
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $gamePath
    $startInfo.Arguments = $arguments
    $startInfo.WorkingDirectory = $packageRoot
    $startInfo.UseShellExecute = $false

    try {
        $form.Hide()
        $process = [System.Diagnostics.Process]::Start($startInfo)
        $process.WaitForExit()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "Unable to start Jump 'n Bump",
            'OK',
            'Error'
        ) | Out-Null
    }
    finally {
        $form.Show()
        $form.Activate()
    }
}

$levelList.Add_SelectedIndexChanged({
    $playButton.Enabled = $null -ne $levelList.SelectedItem
})
$levelList.Add_DoubleClick({ Start-SelectedLevel })
$refreshButton.Add_Click({ Refresh-Levels })
$playButton.Add_Click({ Start-SelectedLevel })
$form.Add_Shown({ Refresh-Levels })

[void]$form.ShowDialog()

