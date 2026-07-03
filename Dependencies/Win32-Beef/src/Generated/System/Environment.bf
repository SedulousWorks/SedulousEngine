using Win32.Foundation;
using System;

namespace Win32.System.Environment;

#region Constants
public static
{
	public const uint32 ENCLAVE_RUNTIME_POLICY_ALLOW_FULL_DEBUG = 1;
	public const uint32 ENCLAVE_RUNTIME_POLICY_ALLOW_DYNAMIC_DEBUG = 2;
	public const uint32 ENCLAVE_UNSEAL_FLAG_STALE_KEY = 1;
	public const uint32 ENCLAVE_FLAG_FULL_DEBUG_ENABLED = 1;
	public const uint32 ENCLAVE_FLAG_DYNAMIC_DEBUG_ENABLED = 2;
	public const uint32 ENCLAVE_FLAG_DYNAMIC_DEBUG_ACTIVE = 4;
	public const uint32 VBS_ENCLAVE_REPORT_PKG_HEADER_VERSION_CURRENT = 1;
	public const uint32 VBS_ENCLAVE_REPORT_SIGNATURE_SCHEME_SHA256_RSA_PSS_SHA256 = 1;
	public const uint32 VBS_ENCLAVE_REPORT_VERSION_CURRENT = 1;
	public const uint32 ENCLAVE_REPORT_DATA_LENGTH = 64;
	public const uint32 VBS_ENCLAVE_VARDATA_INVALID = 0;
	public const uint32 VBS_ENCLAVE_VARDATA_MODULE = 1;
	public const uint32 ENCLAVE_VBS_BASIC_KEY_FLAG_MEASUREMENT = 1;
	public const uint32 ENCLAVE_VBS_BASIC_KEY_FLAG_FAMILY_ID = 2;
	public const uint32 ENCLAVE_VBS_BASIC_KEY_FLAG_IMAGE_ID = 4;
	public const uint32 ENCLAVE_VBS_BASIC_KEY_FLAG_DEBUG_KEY = 8;
}
#endregion

#region Enums

[AllowDuplicates]
public enum ENCLAVE_SEALING_IDENTITY_POLICY : int32
{
	ENCLAVE_IDENTITY_POLICY_SEAL_INVALID = 0,
	ENCLAVE_IDENTITY_POLICY_SEAL_EXACT_CODE = 1,
	ENCLAVE_IDENTITY_POLICY_SEAL_SAME_PRIMARY_CODE = 2,
	ENCLAVE_IDENTITY_POLICY_SEAL_SAME_IMAGE = 3,
	ENCLAVE_IDENTITY_POLICY_SEAL_SAME_FAMILY = 4,
	ENCLAVE_IDENTITY_POLICY_SEAL_SAME_AUTHOR = 5,
}

#endregion

#region Function Pointers
#if BF_64_BIT
public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_RETURN_FROM_EXCEPTION(VBS_BASIC_ENCLAVE_EXCEPTION_AMD64* ExceptionRecord);
#endif

#if BF_64_BIT || BF_ARM_64
public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_TERMINATE_THREAD(VBS_BASIC_ENCLAVE_THREAD_DESCRIPTOR64* ThreadDescriptor);
#endif

#if BF_64_BIT || BF_ARM_64
public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_INTERRUPT_THREAD(VBS_BASIC_ENCLAVE_THREAD_DESCRIPTOR64* ThreadDescriptor);
#endif

#if BF_64_BIT || BF_ARM_64
public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_CREATE_THREAD(VBS_BASIC_ENCLAVE_THREAD_DESCRIPTOR64* ThreadDescriptor);
#endif

public function void VBS_BASIC_ENCLAVE_BASIC_CALL_RETURN_FROM_ENCLAVE(uint ReturnValue);

#if BF_32_BIT || BF_ARM_64
public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_RETURN_FROM_EXCEPTION(void* ExceptionRecord);
#endif

#if BF_32_BIT
public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_TERMINATE_THREAD(VBS_BASIC_ENCLAVE_THREAD_DESCRIPTOR32* ThreadDescriptor);
#endif

#if BF_32_BIT
public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_INTERRUPT_THREAD(VBS_BASIC_ENCLAVE_THREAD_DESCRIPTOR32* ThreadDescriptor);
#endif

public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_COMMIT_PAGES(void* EnclaveAddress, uint NumberOfBytes, void* SourceAddress, uint32 PageProtection);

public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_DECOMMIT_PAGES(void* EnclaveAddress, uint NumberOfBytes);

public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_PROTECT_PAGES(void* EnclaveAddress, uint NumberOfytes, uint32 PageProtection);

#if BF_32_BIT
public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_CREATE_THREAD(VBS_BASIC_ENCLAVE_THREAD_DESCRIPTOR32* ThreadDescriptor);
#endif

public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_GET_ENCLAVE_INFORMATION(ENCLAVE_INFORMATION* EnclaveInfo);

public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_GENERATE_KEY(ENCLAVE_VBS_BASIC_KEY_REQUEST* KeyRequest, uint32 RequestedKeySize, uint8* ReturnedKey);

public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_GENERATE_REPORT(uint8* EnclaveData, void* Report, uint32 BufferSize, uint32* OutputSize);

public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_VERIFY_REPORT(void* Report, uint32 ReportSize);

public function int32 VBS_BASIC_ENCLAVE_BASIC_CALL_GENERATE_RANDOM_DATA(uint8* Buffer, uint32 NumberOfBytes, uint64* Generation);

#endregion

#region Structs
[CRepr, Packed(1)]
public struct ENCLAVE_IDENTITY
{
	public uint8[32] OwnerId;
	public uint8[32] UniqueId;
	public uint8[32] AuthorId;
	public uint8[16] FamilyId;
	public uint8[16] ImageId;
	public uint32 EnclaveSvn;
	public uint32 SecureKernelSvn;
	public uint32 PlatformSvn;
	public uint32 Flags;
	public uint32 SigningLevel;
	public uint32 EnclaveType;
}

[CRepr, Packed(1)]
public struct VBS_ENCLAVE_REPORT_PKG_HEADER
{
	public uint32 PackageSize;
	public uint32 Version;
	public uint32 SignatureScheme;
	public uint32 SignedStatementSize;
	public uint32 SignatureSize;
	public uint32 Reserved;
}

[CRepr, Packed(1)]
public struct VBS_ENCLAVE_REPORT
{
	public uint32 ReportSize;
	public uint32 ReportVersion;
	public uint8[64] EnclaveData;
	public ENCLAVE_IDENTITY EnclaveIdentity;
}

[CRepr, Packed(1)]
public struct VBS_ENCLAVE_REPORT_VARDATA_HEADER
{
	public uint32 DataType;
	public uint32 Size;
}

[CRepr, Packed(1)]
public struct VBS_ENCLAVE_REPORT_MODULE
{
	public VBS_ENCLAVE_REPORT_VARDATA_HEADER Header;
	public uint8[32] UniqueId;
	public uint8[32] AuthorId;
	public uint8[16] FamilyId;
	public uint8[16] ImageId;
	public uint32 Svn;
	public char16* ModuleName mut => &ModuleName_impl;
	private char16[ANYSIZE_ARRAY] ModuleName_impl;
}

[CRepr]
public struct ENCLAVE_INFORMATION
{
	public uint32 EnclaveType;
	public uint32 Reserved;
	public void* BaseAddress;
	public uint Size;
	public ENCLAVE_IDENTITY Identity;
}

[CRepr]
public struct VBS_BASIC_ENCLAVE_THREAD_DESCRIPTOR32
{
	public uint32[4] ThreadContext;
	public uint32 EntryPoint;
	public uint32 StackPointer;
	public uint32 ExceptionEntryPoint;
	public uint32 ExceptionStack;
	public uint32 ExceptionActive;
}

[CRepr]
public struct VBS_BASIC_ENCLAVE_THREAD_DESCRIPTOR64
{
	public uint64[4] ThreadContext;
	public uint64 EntryPoint;
	public uint64 StackPointer;
	public uint64 ExceptionEntryPoint;
	public uint64 ExceptionStack;
	public uint32 ExceptionActive;
}

[CRepr]
public struct VBS_BASIC_ENCLAVE_EXCEPTION_AMD64
{
	public uint32 ExceptionCode;
	public uint32 NumberParameters;
	public uint[3] ExceptionInformation;
	public uint ExceptionRAX;
	public uint ExceptionRCX;
	public uint ExceptionRIP;
	public uint ExceptionRFLAGS;
	public uint ExceptionRSP;
}

[CRepr]
public struct ENCLAVE_VBS_BASIC_KEY_REQUEST
{
	public uint32 RequestSize;
	public uint32 Flags;
	public uint32 EnclaveSVN;
	public uint32 SystemKeyID;
	public uint32 CurrentSystemKeyID;
}

[CRepr]
public struct VBS_BASIC_ENCLAVE_SYSCALL_PAGE
{
	public VBS_BASIC_ENCLAVE_BASIC_CALL_RETURN_FROM_ENCLAVE ReturnFromEnclave;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_RETURN_FROM_EXCEPTION ReturnFromException;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_TERMINATE_THREAD TerminateThread;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_INTERRUPT_THREAD InterruptThread;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_COMMIT_PAGES CommitPages;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_DECOMMIT_PAGES DecommitPages;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_PROTECT_PAGES ProtectPages;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_CREATE_THREAD CreateThread;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_GET_ENCLAVE_INFORMATION GetEnclaveInformation;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_GENERATE_KEY GenerateKey;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_GENERATE_REPORT GenerateReport;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_VERIFY_REPORT VerifyReport;
	public VBS_BASIC_ENCLAVE_BASIC_CALL_GENERATE_RANDOM_DATA GenerateRandomData;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetEnvironmentStringsW(PWSTR NewEnvironment);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR GetCommandLineA();
	public static PSTR GetCommandLine() => GetCommandLineA();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR GetCommandLineW();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR GetEnvironmentStrings();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR GetEnvironmentStringsW();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeEnvironmentStringsA(PSTR penv);
	public static BOOL FreeEnvironmentStrings(PSTR penv) => FreeEnvironmentStringsA(penv);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeEnvironmentStringsW(PWSTR penv);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEnvironmentVariableA(PSTR lpName, uint8* lpBuffer, uint32 nSize);
	public static uint32 GetEnvironmentVariable(PSTR lpName, uint8* lpBuffer, uint32 nSize) => GetEnvironmentVariableA(lpName, lpBuffer, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEnvironmentVariableW(PWSTR lpName, char16* lpBuffer, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetEnvironmentVariableA(PSTR lpName, PSTR lpValue);
	public static BOOL SetEnvironmentVariable(PSTR lpName, PSTR lpValue) => SetEnvironmentVariableA(lpName, lpValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetEnvironmentVariableW(PWSTR lpName, PWSTR lpValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ExpandEnvironmentStringsA(PSTR lpSrc, uint8* lpDst, uint32 nSize);
	public static uint32 ExpandEnvironmentStrings(PSTR lpSrc, uint8* lpDst, uint32 nSize) => ExpandEnvironmentStringsA(lpSrc, lpDst, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ExpandEnvironmentStringsW(PWSTR lpSrc, char16* lpDst, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCurrentDirectoryA(PSTR lpPathName);
	public static BOOL SetCurrentDirectory(PSTR lpPathName) => SetCurrentDirectoryA(lpPathName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCurrentDirectoryW(PWSTR lpPathName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCurrentDirectoryA(uint32 nBufferLength, uint8* lpBuffer);
	public static uint32 GetCurrentDirectory(uint32 nBufferLength, uint8* lpBuffer) => GetCurrentDirectoryA(nBufferLength, lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCurrentDirectoryW(uint32 nBufferLength, char16* lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL NeedCurrentDirectoryForExePathA(PSTR ExeName);
	public static BOOL NeedCurrentDirectoryForExePath(PSTR ExeName) => NeedCurrentDirectoryForExePathA(ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL NeedCurrentDirectoryForExePathW(PWSTR ExeName);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateEnvironmentBlock(void** lpEnvironment, HANDLE hToken, BOOL bInherit);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DestroyEnvironmentBlock(void* lpEnvironment);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ExpandEnvironmentStringsForUserA(HANDLE hToken, PSTR lpSrc, uint8* lpDest, uint32 dwSize);
	public static BOOL ExpandEnvironmentStringsForUser(HANDLE hToken, PSTR lpSrc, uint8* lpDest, uint32 dwSize) => ExpandEnvironmentStringsForUserA(hToken, lpSrc, lpDest, dwSize);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ExpandEnvironmentStringsForUserW(HANDLE hToken, PWSTR lpSrc, char16* lpDest, uint32 dwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsEnclaveTypeSupported(uint32 flEnclaveType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CreateEnclave(HANDLE hProcess, void* lpAddress, uint dwSize, uint dwInitialCommitment, uint32 flEnclaveType, void* lpEnclaveInformation, uint32 dwInfoLength, uint32* lpEnclaveError);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LoadEnclaveData(HANDLE hProcess, void* lpAddress, void* lpBuffer, uint nSize, uint32 flProtect, void* lpPageInformation, uint32 dwInfoLength, uint* lpNumberOfBytesWritten, uint32* lpEnclaveError);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeEnclave(HANDLE hProcess, void* lpAddress, void* lpEnclaveInformation, uint32 dwInfoLength, uint32* lpEnclaveError);

	[Import("api-ms-win-core-enclave-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LoadEnclaveImageA(void* lpEnclaveAddress, PSTR lpImageName);
	public static BOOL LoadEnclaveImage(void* lpEnclaveAddress, PSTR lpImageName) => LoadEnclaveImageA(lpEnclaveAddress, lpImageName);

	[Import("api-ms-win-core-enclave-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LoadEnclaveImageW(void* lpEnclaveAddress, PWSTR lpImageName);

	[Import("vertdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CallEnclave(int lpRoutine, void* lpParameter, BOOL fWaitForThread, void** lpReturnValue);

	[Import("vertdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TerminateEnclave(void* lpAddress, BOOL fWait);

	[Import("api-ms-win-core-enclave-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteEnclave(void* lpAddress);

	[Import("vertdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EnclaveGetAttestationReport(uint8* EnclaveData, void* Report, uint32 BufferSize, uint32* OutputSize);

	[Import("vertdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EnclaveVerifyAttestationReport(uint32 EnclaveType, void* Report, uint32 ReportSize);

	[Import("vertdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EnclaveSealData(void* DataToEncrypt, uint32 DataToEncryptSize, ENCLAVE_SEALING_IDENTITY_POLICY IdentityPolicy, uint32 RuntimePolicy, void* ProtectedBlob, uint32 BufferSize, uint32* ProtectedBlobSize);

	[Import("vertdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EnclaveUnsealData(void* ProtectedBlob, uint32 ProtectedBlobSize, void* DecryptedData, uint32 BufferSize, uint32* DecryptedDataSize, ENCLAVE_IDENTITY* SealingIdentity, uint32* UnsealingFlags);

	[Import("vertdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EnclaveGetEnclaveInformation(uint32 InformationSize, ENCLAVE_INFORMATION* EnclaveInformation);

}
#endregion
