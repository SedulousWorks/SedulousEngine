# Every native dependency at once, on Windows: each <name>-Beef/build-native.ps1 in this folder,
# in turn.
#
#   ./build-all-native.ps1 status [names...]  which committed archives are older than their sources
#   ./build-all-native.ps1 build  [names...]  configure and build each one's Debug and Release (Win64)
#
# Names are folder names (joltc-Beef, or just joltc, in any case); none means all of them. A build
# goes on past a failure and lists the failures at the end. Bulkan, Win32-Beef, SDL3-Beef, wgpu-Beef,
# Dxc-Beef and gpui have no build script: they are bindings over a system or prebuilt library. The
# wasm32 archives are built from bash (build-all-native.sh wasm).
#
# status reads git, not file times: a platform's archives are outdated when a commit touched the
# library's native sources (C, C++, headers, assembly, CMake) after the last commit that touched its
# dist/<Config>-<Platform> folder. That commit is named, since one that changed only a comment or
# another platform's flags needs no rebuild. MISSING is a library with a build script and no
# Windows archives yet.

$option = $args[0]
$names = @($args | Select-Object -Skip 1)

Push-Location $PSScriptRoot
try
{
	# The dependencies with a PowerShell build script, filtered by the names given.
	function Get-Selected
	{
		Get-ChildItem -Directory | Where-Object { Test-Path (Join-Path $_.FullName "build-native.ps1") } | Where-Object {
			if ($names.Count -eq 0) { return $true }
			$dir = $_.Name.ToLowerInvariant()
			foreach ($want in $names)
			{
				$name = $want.ToLowerInvariant() -replace '-beef$', ''
				if (($dir -eq "$name-beef") -or ($dir -eq $name)) { return $true }
			}
			return $false
		} | ForEach-Object { $_.Name }
	}

	# The last commit time (seconds) of the given pathspecs, or 0.
	function Get-LastCommit([string[]] $specs)
	{
		$t = git log -1 --format=%ct -- @specs 2>$null
		if ($t) { return [long]$t } else { return 0 }
	}

	function Get-NativeSources([string] $dep)
	{
		$specs = @()
		foreach ($ext in @("c", "cc", "cpp", "cxx", "h", "hh", "hpp", "hxx", "inl", "S", "s", "asm"))
		{
			$specs += ":(glob)$dep/**/*.$ext"
		}
		$specs += ":(glob)$dep/**/CMakeLists.txt"
		$specs += ":(glob)$dep/**/*.cmake"
		$specs += ":(exclude)$dep/dist"
		return $specs
	}

	function Format-Day([long] $seconds) { return [DateTimeOffset]::FromUnixTimeSeconds($seconds).ToString("yyyy-MM-dd") }

	function Show-Status
	{
		"{0,-24} {1,-9} {2}" -f "dependency", "platform", "archives"
		foreach ($dep in Get-Selected)
		{
			$specs = Get-NativeSources $dep
			$sources = Get-LastCommit $specs
			$newest = git log -1 --format="%h %s" -- @specs 2>$null
			if ($newest -and $newest.Length -gt 60) { $newest = $newest.Substring(0, 60) }
			foreach ($platform in @("Win64", "Linux64", "wasm32"))
			{
				$oldest = 0
				$any = $false
				foreach ($cfg in @("Debug", "Release"))
				{
					$folder = "$dep/dist/$cfg-$platform"
					if (!(Test-Path $folder)) { continue }
					$any = $true
					$archive = Get-LastCommit @($folder)
					if (($oldest -eq 0) -or ($archive -lt $oldest)) { $oldest = $archive }
				}
				if (!$any)
				{
					if ($platform -eq "Win64") { "{0,-24} {1,-9} {2}" -f $dep, $platform, "MISSING" }
					continue
				}
				if ($oldest -eq 0) { $state = "not committed" }
				elseif ($oldest -lt $sources) { $state = "OUTDATED (built $(Format-Day $oldest); sources $(Format-Day $sources): $newest)" }
				else { $state = "up to date ($(Format-Day $oldest))" }
				"{0,-24} {1,-9} {2}" -f $dep, $platform, $state
			}
		}
	}

	$failed = @()
	# One step of one dependency's script; whether it worked. Its output goes to the console, not
	# the pipeline, or the function's result would be that output and always read as true.
	function Invoke-Step([string] $dep, [string[]] $step)
	{
		Write-Host "==== ${dep}: $($step -join ' ')"
		Push-Location $dep
		try
		{
			$global:LASTEXITCODE = 0
			& ./build-native.ps1 @step | Out-Host
			# A script's cmake failing shows as a nonzero exit code, not an exception.
			if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
			return $true
		}
		catch
		{
			$script:failed += "$dep ($($step -join ' ')): $_"
			return $false
		}
		finally { Pop-Location }
	}

	if ($option -eq "status")
	{
		Show-Status
	}
	elseif ($option -eq "build")
	{
		foreach ($dep in Get-Selected)
		{
			if (Invoke-Step $dep @("make")) { Invoke-Step $dep @("build", "ALL") | Out-Null }
		}
		if ($failed.Count -gt 0)
		{
			""
			"FAILED:"
			$failed | ForEach-Object { "  $_" }
			exit 1
		}
	}
	else
	{
		"Usage: build-all-native.ps1 [status|build] [names...]"
		exit 1
	}
}
finally
{
	Pop-Location
}
