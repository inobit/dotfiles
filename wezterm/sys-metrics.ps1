$ErrorActionPreference = "SilentlyContinue"

$outFile = "$env:TEMP\wezterm-sys-metrics.json"

$cpu = 0
try {
	$cpu = [int](Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
} catch {}
if ($cpu -eq 0) {
	try {
		$cpu = [int](Get-CimInstance Win32_Processor)[0].LoadPercentage
	} catch {}
}

$used = 0
$total = 0
try {
	$os = Get-CimInstance Win32_OperatingSystem
	$total = [int64]$os.TotalVisibleMemorySize
	$used = $total - [int64]$os.FreePhysicalMemory
} catch {}

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$json = '{"cpu":' + $cpu + ',"mem_used_kb":' + $used + ',"mem_total_kb":' + $total + ',"ts":' + $now + '}'
[System.IO.File]::WriteAllText($outFile, $json)
