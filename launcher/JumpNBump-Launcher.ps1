Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$packageRoot = $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $packageRoot 'jumpnbump.exe'))) {
    $packageRoot = Split-Path -Parent $PSScriptRoot
}

$gamePath = Join-Path $packageRoot 'jumpnbump.exe'
$levelsPath = Join-Path $packageRoot 'levels'
$settingsDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'JumpNBump'
$settingsPath = Join-Path $settingsDirectory 'launcher-settings.json'

$form = New-Object System.Windows.Forms.Form
$form.Text = "Jump 'n Bump - Level Launcher"
$form.StartPosition = 'CenterScreen'
$form.ClientSize = New-Object System.Drawing.Size(620, 500)
$form.MinimumSize = New-Object System.Drawing.Size(560, 470)

$heading = New-Object System.Windows.Forms.Label
$heading.Text = 'Choose a level'
$heading.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$heading.AutoSize = $true
$heading.Location = New-Object System.Drawing.Point(18, 16)
$form.Controls.Add($heading)

$levelList = New-Object System.Windows.Forms.ListBox
$levelList.Location = New-Object System.Drawing.Point(20, 58)
$levelList.Size = New-Object System.Drawing.Size(580, 250)
$levelList.Anchor = 'Top,Bottom,Left,Right'
$levelList.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$levelList.DisplayMember = 'Name'
$form.Controls.Add($levelList)

$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Text = 'Options'
$optionsGroup.Location = New-Object System.Drawing.Point(20, 320)
$optionsGroup.Size = New-Object System.Drawing.Size(580, 100)
$optionsGroup.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($optionsGroup)

$fullscreen = New-Object System.Windows.Forms.CheckBox
$fullscreen.Text = 'Fullscreen'
$fullscreen.AutoSize = $true
$fullscreen.Location = New-Object System.Drawing.Point(18, 25)
$optionsGroup.Controls.Add($fullscreen)

$mirror = New-Object System.Windows.Forms.CheckBox
$mirror.Text = 'Mirror level'
$mirror.AutoSize = $true
$mirror.Location = New-Object System.Drawing.Point(155, 25)
$optionsGroup.Controls.Add($mirror)

$noGore = New-Object System.Windows.Forms.CheckBox
$noGore.Text = 'No gore'
$noGore.AutoSize = $true
$noGore.Location = New-Object System.Drawing.Point(290, 25)
$optionsGroup.Controls.Add($noGore)

$noFlies = New-Object System.Windows.Forms.CheckBox
$noFlies.Text = 'No flies'
$noFlies.AutoSize = $true
$noFlies.Location = New-Object System.Drawing.Point(420, 25)
$optionsGroup.Controls.Add($noFlies)

$noMusic = New-Object System.Windows.Forms.CheckBox
$noMusic.Text = 'No music'
$noMusic.AutoSize = $true
$noMusic.Location = New-Object System.Drawing.Point(18, 61)
$optionsGroup.Controls.Add($noMusic)

$musicOnly = New-Object System.Windows.Forms.CheckBox
$musicOnly.Text = 'Music only (no effects)'
$musicOnly.AutoSize = $true
$musicOnly.Location = New-Object System.Drawing.Point(155, 61)
$optionsGroup.Controls.Add($musicOnly)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = 'Refresh'
$refreshButton.Size = New-Object System.Drawing.Size(90, 34)
$refreshButton.Location = New-Object System.Drawing.Point(405, 430)
$refreshButton.Anchor = 'Bottom,Right'
$form.Controls.Add($refreshButton)

$playButton = New-Object System.Windows.Forms.Button
$playButton.Text = 'Play'
$playButton.Size = New-Object System.Drawing.Size(100, 34)
$playButton.Location = New-Object System.Drawing.Point(500, 430)
$playButton.Anchor = 'Bottom,Right'
$playButton.Enabled = $false
$form.AcceptButton = $playButton
$form.Controls.Add($playButton)

$status = New-Object System.Windows.Forms.Label
$status.AutoEllipsis = $true
$status.Location = New-Object System.Drawing.Point(20, 474)
$status.Size = New-Object System.Drawing.Size(580, 22)
$status.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($status)

function Set-CheckboxFromSetting {
    param($Settings, [string]$Name, $Checkbox)

    $property = $Settings.PSObject.Properties[$Name]
    if ($null -ne $property) {
        $Checkbox.Checked = [bool]$property.Value
    }
}

function Load-Settings {
    if (-not (Test-Path -LiteralPath $settingsPath)) {
        return
    }

    try {
        $settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
        Set-CheckboxFromSetting $settings 'Fullscreen' $fullscreen
        Set-CheckboxFromSetting $settings 'Mirror' $mirror
        Set-CheckboxFromSetting $settings 'NoGore' $noGore
        Set-CheckboxFromSetting $settings 'NoFlies' $noFlies
        Set-CheckboxFromSetting $settings 'MusicOnly' $musicOnly
        Set-CheckboxFromSetting $settings 'NoMusic' $noMusic
    }
    catch {
        # Invalid or outdated settings should not prevent the launcher starting.
    }
}

function Save-Settings {
    try {
        if (-not (Test-Path -LiteralPath $settingsDirectory)) {
            New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
        }

        [ordered]@{
            Fullscreen = $fullscreen.Checked
            Mirror = $mirror.Checked
            NoGore = $noGore.Checked
            NoFlies = $noFlies.Checked
            NoMusic = $noMusic.Checked
            MusicOnly = $musicOnly.Checked
        } | ConvertTo-Json | Set-Content -LiteralPath $settingsPath -Encoding UTF8
    }
    catch {
        # Playing the game is more important than persisting launcher settings.
    }
}

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
    if ($mirror.Checked) {
        $arguments += ' -mirror'
    }
    if ($noGore.Checked) {
        $arguments += ' -nogore'
    }
    if ($noFlies.Checked) {
        $arguments += ' -noflies'
    }
    if ($noMusic.Checked) {
        $arguments += ' -nomusic'
    }
    if ($musicOnly.Checked) {
        $arguments += ' -musicnosound'
    }

    Save-Settings

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
$noMusic.Add_CheckedChanged({
    if ($noMusic.Checked -and $musicOnly.Checked) {
        $musicOnly.Checked = $false
    }
})
$musicOnly.Add_CheckedChanged({
    if ($musicOnly.Checked -and $noMusic.Checked) {
        $noMusic.Checked = $false
    }
})
$levelList.Add_DoubleClick({ Start-SelectedLevel })
$refreshButton.Add_Click({ Refresh-Levels })
$playButton.Add_Click({ Start-SelectedLevel })
$form.Add_FormClosing({ Save-Settings })
$form.Add_Shown({
    Load-Settings
    Refresh-Levels
})

[void]$form.ShowDialog()
