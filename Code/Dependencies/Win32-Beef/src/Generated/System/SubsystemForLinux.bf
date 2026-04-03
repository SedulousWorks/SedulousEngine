using Win32.Foundation;
using System;

namespace Win32.System.SubsystemForLinux;

#region Enums

[AllowDuplicates]
public enum WSL_DISTRIBUTION_FLAGS : uint32
{
	WSL_DISTRIBUTION_FLAGS_NONE = 0,
	WSL_DISTRIBUTION_FLAGS_ENABLE_INTEROP = 1,
	WSL_DISTRIBUTION_FLAGS_APPEND_NT_PATH = 2,
	WSL_DISTRIBUTION_FLAGS_ENABLE_DRIVE_MOUNTING = 4,
}

#endregion


#region Functions
public static
{
	[Import("Api-ms-win-wsl-api-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WslIsDistributionRegistered(PWSTR distributionName);

	[Import("Api-ms-win-wsl-api-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WslRegisterDistribution(PWSTR distributionName, PWSTR tarGzFilename);

	[Import("Api-ms-win-wsl-api-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WslUnregisterDistribution(PWSTR distributionName);

	[Import("Api-ms-win-wsl-api-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WslConfigureDistribution(PWSTR distributionName, uint32 defaultUID, WSL_DISTRIBUTION_FLAGS wslDistributionFlags);

	[Import("Api-ms-win-wsl-api-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WslGetDistributionConfiguration(PWSTR distributionName, uint32* distributionVersion, uint32* defaultUID, WSL_DISTRIBUTION_FLAGS* wslDistributionFlags, PSTR** defaultEnvironmentVariables, uint32* defaultEnvironmentVariableCount);

	[Import("Api-ms-win-wsl-api-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WslLaunchInteractive(PWSTR distributionName, PWSTR command, BOOL useCurrentWorkingDirectory, uint32* exitCode);

	[Import("Api-ms-win-wsl-api-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WslLaunch(PWSTR distributionName, PWSTR command, BOOL useCurrentWorkingDirectory, HANDLE stdIn, HANDLE stdOut, HANDLE stdErr, HANDLE* process);

}
#endregion
