[CmdletBinding()]
param(
    [string]$Section = 'all',
    [ValidateSet('Json', 'Text')]
    [string]$Format = 'Json',
    [string]$Name
)

$ErrorActionPreference = 'Stop'

$extraPaths = @(
    (Join-Path $HOME '.bun\bin'),
    (Join-Path $HOME 'AppData\Roaming\fnm\aliases\default'),
    (Join-Path $HOME '.local\bin'),
    (Join-Path $HOME 'scoop\shims'),
    'C:\Program Files\dotnet',
    'C:\Program Files\PowerShell\7'
)

foreach ($path in $extraPaths) {
    if ((Test-Path -LiteralPath $path) -and (($env:PATH -split ';') -notcontains $path)) {
        $env:PATH = "$path;$env:PATH"
    }
}

function Get-ProgramVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string[]]$Arguments = @('--version'),
        [string]$Pattern
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) {
        return [ordered]@{ available = $false }
    }

    try {
        $output = & $command.Source @Arguments 2>&1
        $line = $output |
            ForEach-Object { $_.ToString().Trim() } |
            Where-Object { $_ -and (-not $Pattern -or $_ -match $Pattern) } |
            Select-Object -First 1

        return [ordered]@{
            available = $true
            version = if ($line) { $line } else { $null }
            path = $command.Source
        }
    }
    catch {
        return [ordered]@{
            available = $false
            path = $command.Source
            error = $_.Exception.Message
        }
    }
}

function Get-ProgramVersionAtPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string[]]$Arguments = @('--version')
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [ordered]@{ available = $false; path = $Path }
    }

    try {
        $output = & $Path @Arguments 2>&1
        $line = $output |
            ForEach-Object { $_.ToString().Trim() } |
            Where-Object { $_ } |
            Select-Object -First 1

        return [ordered]@{
            available = $true
            version = if ($line) { $line } else { $null }
            path = $Path
        }
    }
    catch {
        return [ordered]@{
            available = $false
            path = $Path
            error = $_.Exception.Message
        }
    }
}

function Get-OSInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $release = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    [ordered]@{
        caption = $os.Caption
        version = $os.Version
        build = $os.BuildNumber
        ubr = $release.UBR
        display_version = $release.DisplayVersion
        architecture = $os.OSArchitecture
        timezone = (Get-TimeZone).Id
    }
}

function Get-HardwareInfo {
    $computer = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    [ordered]@{
        cpu = $cpu.Name.Trim()
        ram_gb = [math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
    }
}

function Get-ShellInfo {
    [ordered]@{
        powershell = $PSVersionTable.PSVersion.ToString()
        edition = $PSVersionTable.PSEdition
        executable = [Environment]::ProcessPath
        current_user = [Environment]::UserName
        console_output_encoding = [Console]::OutputEncoding.WebName
    }
}

function Get-ToolchainInfo {
    [ordered]@{
        node = Get-ProgramVersion -Name 'node'
        npm = Get-ProgramVersion -Name 'npm.cmd'
        bun = Get-ProgramVersion -Name 'bun'
        uv = Get-ProgramVersion -Name 'uv'
        python = if (Test-Path -LiteralPath (Join-Path $HOME '.local\bin\python.exe')) {
            Get-ProgramVersionAtPath -Path (Join-Path $HOME '.local\bin\python.exe')
        }
        else {
            Get-ProgramVersion -Name 'python'
        }
        dotnet = Get-ProgramVersion -Name 'dotnet'
        java = if (Test-Path -LiteralPath (Join-Path $HOME 'scoop\apps\temurin-jdk\current\bin\java.exe')) {
            Get-ProgramVersionAtPath `
                -Path (Join-Path $HOME 'scoop\apps\temurin-jdk\current\bin\java.exe') `
                -Arguments @('-version')
        }
        else {
            Get-ProgramVersion -Name 'java' -Arguments @('-version')
        }
        git = Get-ProgramVersion -Name 'git'
        seven_zip = Get-ProgramVersion -Name '7z' -Arguments @('i') -Pattern '^7-Zip'
        openchamber = Get-ProgramVersion -Name 'openchamber'
        magpie = Get-ProgramVersion -Name 'magpie'
    }
}

function Get-DiskInfo {
    $drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    [ordered]@{
        drive = 'C:'
        total_gb = [math]::Round($drive.Size / 1GB, 1)
        free_gb = [math]::Round($drive.FreeSpace / 1GB, 1)
        used_gb = [math]::Round(($drive.Size - $drive.FreeSpace) / 1GB, 1)
    }
}

function Get-WSLInfo {
    $command = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if (-not $command) {
        return [ordered]@{ available = $false }
    }

    $output = & $command.Source -l -v 2>&1
    $exitCode = $LASTEXITCODE
    $lines = @(
        $output |
            ForEach-Object { $_.ToString().Replace([string][char]0, '').TrimEnd() } |
            Where-Object { $_.Trim() }
    )

    $stateNames = 'Running|Stopped|Installing|Uninstalling|Converting|Starting|Unknown'
    $distros = @(
        foreach ($line in $lines) {
            if ($line -match "^\s*(?<default>\*)?\s*(?<name>.+?)\s+(?<state>$stateNames)\s+(?<version>\d+)\s*$") {
                [ordered]@{
                    name = $Matches['name'].Trim()
                    state = $Matches['state']
                    version = [int]$Matches['version']
                    default = [bool]$Matches['default']
                }
            }
        }
    )

    $defaultName = $null
    foreach ($distro in $distros) {
        if ($distro.default) {
            $defaultName = $distro.name
            break
        }
    }

    $result = [ordered]@{
        available = $true
        exit_code = $exitCode
        default = $defaultName
        distros = $distros
    }

    # Keep the raw lines when the output is localized or changes shape, rather than returning nothing.
    if ($distros.Count -eq 0) {
        $result.raw = $lines
    }

    $result
}

function Get-NetworkInfo {
    [ordered]@{
        http_proxy = $env:HTTP_PROXY
        https_proxy = $env:HTTPS_PROXY
        no_proxy = $env:NO_PROXY
    }
}

function Get-ConfigInfo {
    $paths = [ordered]@{
        environment_snapshot = (Join-Path $HOME '.agents\ENVIRONMENT.md')
        environment_skill = (Join-Path $HOME '.config\magpie\library\skills\environment\SKILL.md')
        shared_skills = (Join-Path $HOME '.agents\skills')
        opencode_agents = (Join-Path $HOME '.config\opencode\AGENTS.md')
        opencode_config = (Join-Path $HOME '.config\opencode\opencode.json')
        codex_home = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
    }

    [ordered]@{
        paths = $paths
        exists = [ordered]@{
            environment_snapshot = Test-Path -LiteralPath $paths.environment_snapshot
            environment_skill = Test-Path -LiteralPath $paths.environment_skill
            shared_skills = Test-Path -LiteralPath $paths.shared_skills
            opencode_agents = Test-Path -LiteralPath $paths.opencode_agents
            opencode_config = Test-Path -LiteralPath $paths.opencode_config
            codex_home = Test-Path -LiteralPath $paths.codex_home
        }
    }
}

function Get-ServicesInfo {
    param([string]$Filter)

    $services = @(Get-CimInstance Win32_Service)

    if ($Filter) {
        $matched = @(
            $services |
                Where-Object { $_.Name -like "*$Filter*" -or $_.DisplayName -like "*$Filter*" } |
                Sort-Object Name
        )

        return [ordered]@{
            filter = $Filter
            count = $matched.Count
            services = @(
                $matched |
                    Select-Object -First 50 |
                    ForEach-Object {
                        [ordered]@{
                            name = $_.Name
                            display_name = $_.DisplayName
                            state = $_.State
                            start_mode = $_.StartMode
                            process_id = $_.ProcessId
                        }
                    }
            )
        }
    }

    $running = @($services | Where-Object { $_.State -eq 'Running' })
    $stopped = @($services | Where-Object { $_.State -eq 'Stopped' })
    $autoStopped = @(
        $services |
            Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } |
            Sort-Object Name
    )

    [ordered]@{
        total = $services.Count
        running = $running.Count
        stopped = $stopped.Count
        auto_not_running = @(
            $autoStopped |
                ForEach-Object {
                    [ordered]@{
                        name = $_.Name
                        display_name = $_.DisplayName
                        state = $_.State
                    }
                }
        )
    }
}

$requested = @(
    $Section -split '[, ]+' |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Where-Object { $_ }
)

$known = @('os', 'hardware', 'shell', 'toolchain', 'disk', 'wsl', 'network', 'config', 'services')
if ($requested -contains 'all') {
    $requested = $known
}

$unknown = @($requested | Where-Object { $known -notcontains $_ })
if ($unknown.Count -gt 0) {
    throw "Unknown section(s): $($unknown -join ', '). Valid sections: $($known -join ', '), all"
}

if ($Name -and ($requested -notcontains 'services')) {
    throw 'The -Name parameter only applies to the services section.'
}

$result = [ordered]@{}
foreach ($sectionName in $requested) {
    $result[$sectionName] = switch ($sectionName) {
        'os' { Get-OSInfo }
        'hardware' { Get-HardwareInfo }
        'shell' { Get-ShellInfo }
        'toolchain' { Get-ToolchainInfo }
        'disk' { Get-DiskInfo }
        'wsl' { Get-WSLInfo }
        'network' { Get-NetworkInfo }
        'config' { Get-ConfigInfo }
        'services' { Get-ServicesInfo -Filter $Name }
    }
}

if ($Format -eq 'Json') {
    $result | ConvertTo-Json -Depth 8
}
else {
    foreach ($sectionName in $requested) {
        "## $sectionName"
        $result[$sectionName] | ConvertTo-Json -Depth 8
        ''
    }
}
