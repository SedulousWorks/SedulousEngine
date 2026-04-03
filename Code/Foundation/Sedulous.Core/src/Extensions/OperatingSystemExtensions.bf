namespace System;

extension OperatingSystem
{
	public static bool IsWindows()
	{
		var platformId = Environment.OSVersion.Platform;
		return platformId == .Win32NT || platformId == .Win32S || platformId == .Win32Windows || platformId == .WinCE;
	}

	public static bool IsLinux()
	{
		return false;
	}

	public static bool IsAndroid()
	{
		return false;
	}

	public static bool IsMacOS()
	{
		var platformId = Environment.OSVersion.Platform;
		return platformId == .MacOSX;
	}

	public static bool IsIOS()
	{
		return false;
	}

	public static bool IsBrowser()
	{
		return false;
	}

}