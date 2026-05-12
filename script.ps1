Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Relaunch as admin if not already elevated
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$originalTime = Get-Date
$script:pendingDate = $null

# --- Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Date & Time Randomizer"
$form.Size = New-Object System.Drawing.Size(420, 340)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 35)
$form.ForeColor = [System.Drawing.Color]::White

# --- Title ---
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Date & Time Randomizer"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 255)
$lblTitle.Location = New-Object System.Drawing.Point(60, 15)
$lblTitle.Size = New-Object System.Drawing.Size(310, 32)
$form.Controls.Add($lblTitle)

# --- Current time ---
$lblCurrentCaption = New-Object System.Windows.Forms.Label
$lblCurrentCaption.Text = "Current System Time"
$lblCurrentCaption.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblCurrentCaption.ForeColor = [System.Drawing.Color]::LightGray
$lblCurrentCaption.Location = New-Object System.Drawing.Point(20, 62)
$lblCurrentCaption.Size = New-Object System.Drawing.Size(180, 18)
$form.Controls.Add($lblCurrentCaption)

$lblCurrent = New-Object System.Windows.Forms.Label
$lblCurrent.Text = (Get-Date).ToString("MM/dd/yyyy  HH:mm:ss")
$lblCurrent.Font = New-Object System.Drawing.Font("Consolas", 13, [System.Drawing.FontStyle]::Bold)
$lblCurrent.ForeColor = [System.Drawing.Color]::FromArgb(80, 220, 120)
$lblCurrent.Location = New-Object System.Drawing.Point(20, 82)
$lblCurrent.Size = New-Object System.Drawing.Size(370, 28)
$form.Controls.Add($lblCurrent)

# --- Randomized time ---
$lblRandomCaption = New-Object System.Windows.Forms.Label
$lblRandomCaption.Text = "Randomized Preview"
$lblRandomCaption.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblRandomCaption.ForeColor = [System.Drawing.Color]::LightGray
$lblRandomCaption.Location = New-Object System.Drawing.Point(20, 125)
$lblRandomCaption.Size = New-Object System.Drawing.Size(180, 18)
$form.Controls.Add($lblRandomCaption)

$lblRandom = New-Object System.Windows.Forms.Label
$lblRandom.Text = "-"
$lblRandom.Font = New-Object System.Drawing.Font("Consolas", 13, [System.Drawing.FontStyle]::Bold)
$lblRandom.ForeColor = [System.Drawing.Color]::FromArgb(255, 165, 50)
$lblRandom.Location = New-Object System.Drawing.Point(20, 145)
$lblRandom.Size = New-Object System.Drawing.Size(370, 28)
$form.Controls.Add($lblRandom)

# --- Year range row ---
$lblYearRange = New-Object System.Windows.Forms.Label
$lblYearRange.Text = "Year range:"
$lblYearRange.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblYearRange.ForeColor = [System.Drawing.Color]::LightGray
$lblYearRange.Location = New-Object System.Drawing.Point(20, 188)
$lblYearRange.Size = New-Object System.Drawing.Size(80, 22)
$form.Controls.Add($lblYearRange)

$numMin = New-Object System.Windows.Forms.NumericUpDown
$numMin.Minimum = 1970; $numMin.Maximum = 2099; $numMin.Value = 2000
$numMin.Font = New-Object System.Drawing.Font("Consolas", 10)
$numMin.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 60)
$numMin.ForeColor = [System.Drawing.Color]::White
$numMin.Location = New-Object System.Drawing.Point(105, 185)
$numMin.Size = New-Object System.Drawing.Size(75, 26)
$form.Controls.Add($numMin)

$lblTo = New-Object System.Windows.Forms.Label
$lblTo.Text = "to"
$lblTo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblTo.ForeColor = [System.Drawing.Color]::LightGray
$lblTo.Location = New-Object System.Drawing.Point(185, 188)
$lblTo.Size = New-Object System.Drawing.Size(20, 22)
$form.Controls.Add($lblTo)

$numMax = New-Object System.Windows.Forms.NumericUpDown
$numMax.Minimum = 1970; $numMax.Maximum = 2099; $numMax.Value = 2035
$numMax.Font = New-Object System.Drawing.Font("Consolas", 10)
$numMax.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 60)
$numMax.ForeColor = [System.Drawing.Color]::White
$numMax.Location = New-Object System.Drawing.Point(210, 185)
$numMax.Size = New-Object System.Drawing.Size(75, 26)
$form.Controls.Add($numMax)

# --- Buttons ---
function New-StyledButton($text, $x, $color) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object System.Drawing.Point($x, 230)
    $btn.Size = New-Object System.Drawing.Size(108, 40)
    $btn.BackColor = $color
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $btn
}

$btnRandomize = New-StyledButton "Randomize" 20  ([System.Drawing.Color]::FromArgb(0, 110, 200))
$btnApply     = New-StyledButton "Apply"     143 ([System.Drawing.Color]::FromArgb(20, 160, 70))
$btnRestore   = New-StyledButton "Restore"   266 ([System.Drawing.Color]::FromArgb(180, 45, 45))

$btnApply.Enabled = $false

$btnRandomize.Add_Click({
    $minY = [int]$numMin.Value
    $maxY = [int]$numMax.Value
    if ($minY -gt $maxY) { $minY, $maxY = $maxY, $minY }
    $year   = Get-Random -Minimum $minY -Maximum ($maxY + 1)
    $month  = Get-Random -Minimum 1    -Maximum 13
    $day    = Get-Random -Minimum 1    -Maximum 29   # 28 is safe for every month
    $hour   = Get-Random -Minimum 0    -Maximum 24
    $minute = Get-Random -Minimum 0    -Maximum 60
    $second = Get-Random -Minimum 0    -Maximum 60
    $script:pendingDate = Get-Date -Year $year -Month $month -Day $day -Hour $hour -Minute $minute -Second $second
    $lblRandom.Text = $script:pendingDate.ToString("MM/dd/yyyy  HH:mm:ss")
    $btnApply.Enabled = $true
})

