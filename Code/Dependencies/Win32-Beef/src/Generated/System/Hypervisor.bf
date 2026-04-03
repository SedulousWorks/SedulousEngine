using Win32.Foundation;
using Win32.System.Power;
using Win32.System.HostComputeSystem;
using System;

namespace Win32.System.Hypervisor;

#region Constants
public static
{
	public const uint32 HVSOCKET_CONNECT_TIMEOUT = 1;
	public const uint32 HVSOCKET_CONNECT_TIMEOUT_MAX = 300000;
	public const uint32 HVSOCKET_CONTAINER_PASSTHRU = 2;
	public const uint32 HVSOCKET_CONNECTED_SUSPEND = 4;
	public const uint32 HV_PROTOCOL_RAW = 1;
	public const uint32 HVSOCKET_ADDRESS_FLAG_PASSTHRU = 1;
	public const uint32 WHV_PROCESSOR_FEATURES_BANKS_COUNT = 2;
	public const uint32 WHV_SYNTHETIC_PROCESSOR_FEATURES_BANKS_COUNT = 1;
	public const uint32 WHV_READ_WRITE_GPA_RANGE_MAX_SIZE = 16;
	public const uint32 WHV_HYPERCALL_CONTEXT_MAX_XMM_REGISTERS = 6;
	public const uint32 WHV_MAX_DEVICE_ID_SIZE_IN_CHARS = 200;
	public const uint32 WHV_VPCI_TYPE0_BAR_COUNT = 6;
	public const uint32 WHV_ANY_VP = 4294967295;
	public const uint32 WHV_SYNIC_MESSAGE_SIZE = 256;
	public const String VM_GENCOUNTER_SYMBOLIC_LINK_NAME = "\\VmGenerationCounter";
	public const uint32 IOCTL_VMGENCOUNTER_READ = 3325956;
	public const uint32 HDV_PCI_BAR_COUNT = 6;
	public const Guid HV_GUID_ZERO = .(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
	public const Guid HV_GUID_BROADCAST = .(0xffffffff, 0xffff, 0xffff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff);
	public const Guid HV_GUID_CHILDREN = .(0x90db8b89, 0x0d35, 0x4f79, 0x8c, 0xe9, 0x49, 0xea, 0x0a, 0xc8, 0xb7, 0xcd);
	public const Guid HV_GUID_LOOPBACK = .(0xe0e16197, 0xdd56, 0x4a10, 0x91, 0x95, 0x5e, 0xe7, 0xa1, 0x55, 0xa8, 0x38);
	public const Guid HV_GUID_PARENT = .(0xa42e7cda, 0xd03f, 0x480c, 0x9c, 0xc2, 0xa4, 0xde, 0x20, 0xab, 0xb8, 0x78);
	public const Guid HV_GUID_SILOHOST = .(0x36bd0c5c, 0x7276, 0x4223, 0x88, 0xba, 0x7d, 0x03, 0xb6, 0x54, 0xc5, 0x68);
	public const Guid HV_GUID_VSOCK_TEMPLATE = .(0x00000000, 0xfacb, 0x11e6, 0xbd, 0x58, 0x64, 0x00, 0x6a, 0x79, 0x86, 0xd3);
	public const Guid GUID_DEVINTERFACE_VM_GENCOUNTER = .(0x3ff2c92b, 0x6598, 0x4e60, 0x8e, 0x1c, 0x0c, 0xcf, 0x49, 0x27, 0xe3, 0x19);
}
#endregion

#region TypeDefs
typealias WHV_PARTITION_HANDLE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum WHV_CAPABILITY_CODE : int32
{
	WHvCapabilityCodeHypervisorPresent = 0,
	WHvCapabilityCodeFeatures = 1,
	WHvCapabilityCodeExtendedVmExits = 2,
	WHvCapabilityCodeExceptionExitBitmap = 3,
	WHvCapabilityCodeX64MsrExitBitmap = 4,
	WHvCapabilityCodeGpaRangePopulateFlags = 5,
	WHvCapabilityCodeSchedulerFeatures = 6,
	WHvCapabilityCodeProcessorVendor = 4096,
	WHvCapabilityCodeProcessorFeatures = 4097,
	WHvCapabilityCodeProcessorClFlushSize = 4098,
	WHvCapabilityCodeProcessorXsaveFeatures = 4099,
	WHvCapabilityCodeProcessorClockFrequency = 4100,
	WHvCapabilityCodeInterruptClockFrequency = 4101,
	WHvCapabilityCodeProcessorFeaturesBanks = 4102,
	WHvCapabilityCodeProcessorFrequencyCap = 4103,
	WHvCapabilityCodeSyntheticProcessorFeaturesBanks = 4104,
	WHvCapabilityCodeProcessorPerfmonFeatures = 4105,
}


[AllowDuplicates]
public enum WHV_PROCESSOR_VENDOR : int32
{
	WHvProcessorVendorAmd = 0,
	WHvProcessorVendorIntel = 1,
	WHvProcessorVendorHygon = 2,
}


[AllowDuplicates]
public enum WHV_PARTITION_PROPERTY_CODE : int32
{
	WHvPartitionPropertyCodeExtendedVmExits = 1,
	WHvPartitionPropertyCodeExceptionExitBitmap = 2,
	WHvPartitionPropertyCodeSeparateSecurityDomain = 3,
	WHvPartitionPropertyCodeNestedVirtualization = 4,
	WHvPartitionPropertyCodeX64MsrExitBitmap = 5,
	WHvPartitionPropertyCodePrimaryNumaNode = 6,
	WHvPartitionPropertyCodeCpuReserve = 7,
	WHvPartitionPropertyCodeCpuCap = 8,
	WHvPartitionPropertyCodeCpuWeight = 9,
	WHvPartitionPropertyCodeCpuGroupId = 10,
	WHvPartitionPropertyCodeProcessorFrequencyCap = 11,
	WHvPartitionPropertyCodeAllowDeviceAssignment = 12,
	WHvPartitionPropertyCodeDisableSmt = 13,
	WHvPartitionPropertyCodeProcessorFeatures = 4097,
	WHvPartitionPropertyCodeProcessorClFlushSize = 4098,
	WHvPartitionPropertyCodeCpuidExitList = 4099,
	WHvPartitionPropertyCodeCpuidResultList = 4100,
	WHvPartitionPropertyCodeLocalApicEmulationMode = 4101,
	WHvPartitionPropertyCodeProcessorXsaveFeatures = 4102,
	WHvPartitionPropertyCodeProcessorClockFrequency = 4103,
	WHvPartitionPropertyCodeInterruptClockFrequency = 4104,
	WHvPartitionPropertyCodeApicRemoteReadSupport = 4105,
	WHvPartitionPropertyCodeProcessorFeaturesBanks = 4106,
	WHvPartitionPropertyCodeReferenceTime = 4107,
	WHvPartitionPropertyCodeSyntheticProcessorFeaturesBanks = 4108,
	WHvPartitionPropertyCodeCpuidResultList2 = 4109,
	WHvPartitionPropertyCodeProcessorPerfmonFeatures = 4110,
	WHvPartitionPropertyCodeMsrActionList = 4111,
	WHvPartitionPropertyCodeUnimplementedMsrAction = 4112,
	WHvPartitionPropertyCodeProcessorCount = 8191,
}


[AllowDuplicates]
public enum WHV_MEMORY_ACCESS_TYPE : int32
{
	WHvMemoryAccessRead = 0,
	WHvMemoryAccessWrite = 1,
	WHvMemoryAccessExecute = 2,
}


[AllowDuplicates]
public enum WHV_X64_CPUID_RESULT2_FLAGS : uint32
{
	WHvX64CpuidResult2FlagSubleafSpecific = 1,
	WHvX64CpuidResult2FlagVpSpecific = 2,
}


[AllowDuplicates]
public enum WHV_MSR_ACTION : int32
{
	WHvMsrActionArchitectureDefault = 0,
	WHvMsrActionIgnoreWriteReadZero = 1,
	WHvMsrActionExit = 2,
}


[AllowDuplicates]
public enum WHV_EXCEPTION_TYPE : int32
{
	WHvX64ExceptionTypeDivideErrorFault = 0,
	WHvX64ExceptionTypeDebugTrapOrFault = 1,
	WHvX64ExceptionTypeBreakpointTrap = 3,
	WHvX64ExceptionTypeOverflowTrap = 4,
	WHvX64ExceptionTypeBoundRangeFault = 5,
	WHvX64ExceptionTypeInvalidOpcodeFault = 6,
	WHvX64ExceptionTypeDeviceNotAvailableFault = 7,
	WHvX64ExceptionTypeDoubleFaultAbort = 8,
	WHvX64ExceptionTypeInvalidTaskStateSegmentFault = 10,
	WHvX64ExceptionTypeSegmentNotPresentFault = 11,
	WHvX64ExceptionTypeStackFault = 12,
	WHvX64ExceptionTypeGeneralProtectionFault = 13,
	WHvX64ExceptionTypePageFault = 14,
	WHvX64ExceptionTypeFloatingPointErrorFault = 16,
	WHvX64ExceptionTypeAlignmentCheckFault = 17,
	WHvX64ExceptionTypeMachineCheckAbort = 18,
	WHvX64ExceptionTypeSimdFloatingPointFault = 19,
}


[AllowDuplicates]
public enum WHV_X64_LOCAL_APIC_EMULATION_MODE : int32
{
	WHvX64LocalApicEmulationModeNone = 0,
	WHvX64LocalApicEmulationModeXApic = 1,
	WHvX64LocalApicEmulationModeX2Apic = 2,
}


[AllowDuplicates]
public enum WHV_MAP_GPA_RANGE_FLAGS : uint32
{
	WHvMapGpaRangeFlagNone = 0,
	WHvMapGpaRangeFlagRead = 1,
	WHvMapGpaRangeFlagWrite = 2,
	WHvMapGpaRangeFlagExecute = 4,
	WHvMapGpaRangeFlagTrackDirtyPages = 8,
}


[AllowDuplicates]
public enum WHV_TRANSLATE_GVA_FLAGS : uint32
{
	WHvTranslateGvaFlagNone = 0,
	WHvTranslateGvaFlagValidateRead = 1,
	WHvTranslateGvaFlagValidateWrite = 2,
	WHvTranslateGvaFlagValidateExecute = 4,
	WHvTranslateGvaFlagPrivilegeExempt = 8,
	WHvTranslateGvaFlagSetPageTableBits = 16,
	WHvTranslateGvaFlagEnforceSmap = 256,
	WHvTranslateGvaFlagOverrideSmap = 512,
}


[AllowDuplicates]
public enum WHV_TRANSLATE_GVA_RESULT_CODE : int32
{
	WHvTranslateGvaResultSuccess = 0,
	WHvTranslateGvaResultPageNotPresent = 1,
	WHvTranslateGvaResultPrivilegeViolation = 2,
	WHvTranslateGvaResultInvalidPageTableFlags = 3,
	WHvTranslateGvaResultGpaUnmapped = 4,
	WHvTranslateGvaResultGpaNoReadAccess = 5,
	WHvTranslateGvaResultGpaNoWriteAccess = 6,
	WHvTranslateGvaResultGpaIllegalOverlayAccess = 7,
	WHvTranslateGvaResultIntercept = 8,
}


[AllowDuplicates]
public enum WHV_CACHE_TYPE : int32
{
	WHvCacheTypeUncached = 0,
	WHvCacheTypeWriteCombining = 1,
	WHvCacheTypeWriteThrough = 4,
	WHvCacheTypeWriteBack = 6,
}


[AllowDuplicates]
public enum WHV_REGISTER_NAME : int32
{
	WHvX64RegisterRax = 0,
	WHvX64RegisterRcx = 1,
	WHvX64RegisterRdx = 2,
	WHvX64RegisterRbx = 3,
	WHvX64RegisterRsp = 4,
	WHvX64RegisterRbp = 5,
	WHvX64RegisterRsi = 6,
	WHvX64RegisterRdi = 7,
	WHvX64RegisterR8 = 8,
	WHvX64RegisterR9 = 9,
	WHvX64RegisterR10 = 10,
	WHvX64RegisterR11 = 11,
	WHvX64RegisterR12 = 12,
	WHvX64RegisterR13 = 13,
	WHvX64RegisterR14 = 14,
	WHvX64RegisterR15 = 15,
	WHvX64RegisterRip = 16,
	WHvX64RegisterRflags = 17,
	WHvX64RegisterEs = 18,
	WHvX64RegisterCs = 19,
	WHvX64RegisterSs = 20,
	WHvX64RegisterDs = 21,
	WHvX64RegisterFs = 22,
	WHvX64RegisterGs = 23,
	WHvX64RegisterLdtr = 24,
	WHvX64RegisterTr = 25,
	WHvX64RegisterIdtr = 26,
	WHvX64RegisterGdtr = 27,
	WHvX64RegisterCr0 = 28,
	WHvX64RegisterCr2 = 29,
	WHvX64RegisterCr3 = 30,
	WHvX64RegisterCr4 = 31,
	WHvX64RegisterCr8 = 32,
	WHvX64RegisterDr0 = 33,
	WHvX64RegisterDr1 = 34,
	WHvX64RegisterDr2 = 35,
	WHvX64RegisterDr3 = 36,
	WHvX64RegisterDr6 = 37,
	WHvX64RegisterDr7 = 38,
	WHvX64RegisterXCr0 = 39,
	WHvX64RegisterVirtualCr0 = 40,
	WHvX64RegisterVirtualCr3 = 41,
	WHvX64RegisterVirtualCr4 = 42,
	WHvX64RegisterVirtualCr8 = 43,
	WHvX64RegisterXmm0 = 4096,
	WHvX64RegisterXmm1 = 4097,
	WHvX64RegisterXmm2 = 4098,
	WHvX64RegisterXmm3 = 4099,
	WHvX64RegisterXmm4 = 4100,
	WHvX64RegisterXmm5 = 4101,
	WHvX64RegisterXmm6 = 4102,
	WHvX64RegisterXmm7 = 4103,
	WHvX64RegisterXmm8 = 4104,
	WHvX64RegisterXmm9 = 4105,
	WHvX64RegisterXmm10 = 4106,
	WHvX64RegisterXmm11 = 4107,
	WHvX64RegisterXmm12 = 4108,
	WHvX64RegisterXmm13 = 4109,
	WHvX64RegisterXmm14 = 4110,
	WHvX64RegisterXmm15 = 4111,
	WHvX64RegisterFpMmx0 = 4112,
	WHvX64RegisterFpMmx1 = 4113,
	WHvX64RegisterFpMmx2 = 4114,
	WHvX64RegisterFpMmx3 = 4115,
	WHvX64RegisterFpMmx4 = 4116,
	WHvX64RegisterFpMmx5 = 4117,
	WHvX64RegisterFpMmx6 = 4118,
	WHvX64RegisterFpMmx7 = 4119,
	WHvX64RegisterFpControlStatus = 4120,
	WHvX64RegisterXmmControlStatus = 4121,
	WHvX64RegisterTsc = 8192,
	WHvX64RegisterEfer = 8193,
	WHvX64RegisterKernelGsBase = 8194,
	WHvX64RegisterApicBase = 8195,
	WHvX64RegisterPat = 8196,
	WHvX64RegisterSysenterCs = 8197,
	WHvX64RegisterSysenterEip = 8198,
	WHvX64RegisterSysenterEsp = 8199,
	WHvX64RegisterStar = 8200,
	WHvX64RegisterLstar = 8201,
	WHvX64RegisterCstar = 8202,
	WHvX64RegisterSfmask = 8203,
	WHvX64RegisterInitialApicId = 8204,
	WHvX64RegisterMsrMtrrCap = 8205,
	WHvX64RegisterMsrMtrrDefType = 8206,
	WHvX64RegisterMsrMtrrPhysBase0 = 8208,
	WHvX64RegisterMsrMtrrPhysBase1 = 8209,
	WHvX64RegisterMsrMtrrPhysBase2 = 8210,
	WHvX64RegisterMsrMtrrPhysBase3 = 8211,
	WHvX64RegisterMsrMtrrPhysBase4 = 8212,
	WHvX64RegisterMsrMtrrPhysBase5 = 8213,
	WHvX64RegisterMsrMtrrPhysBase6 = 8214,
	WHvX64RegisterMsrMtrrPhysBase7 = 8215,
	WHvX64RegisterMsrMtrrPhysBase8 = 8216,
	WHvX64RegisterMsrMtrrPhysBase9 = 8217,
	WHvX64RegisterMsrMtrrPhysBaseA = 8218,
	WHvX64RegisterMsrMtrrPhysBaseB = 8219,
	WHvX64RegisterMsrMtrrPhysBaseC = 8220,
	WHvX64RegisterMsrMtrrPhysBaseD = 8221,
	WHvX64RegisterMsrMtrrPhysBaseE = 8222,
	WHvX64RegisterMsrMtrrPhysBaseF = 8223,
	WHvX64RegisterMsrMtrrPhysMask0 = 8256,
	WHvX64RegisterMsrMtrrPhysMask1 = 8257,
	WHvX64RegisterMsrMtrrPhysMask2 = 8258,
	WHvX64RegisterMsrMtrrPhysMask3 = 8259,
	WHvX64RegisterMsrMtrrPhysMask4 = 8260,
	WHvX64RegisterMsrMtrrPhysMask5 = 8261,
	WHvX64RegisterMsrMtrrPhysMask6 = 8262,
	WHvX64RegisterMsrMtrrPhysMask7 = 8263,
	WHvX64RegisterMsrMtrrPhysMask8 = 8264,
	WHvX64RegisterMsrMtrrPhysMask9 = 8265,
	WHvX64RegisterMsrMtrrPhysMaskA = 8266,
	WHvX64RegisterMsrMtrrPhysMaskB = 8267,
	WHvX64RegisterMsrMtrrPhysMaskC = 8268,
	WHvX64RegisterMsrMtrrPhysMaskD = 8269,
	WHvX64RegisterMsrMtrrPhysMaskE = 8270,
	WHvX64RegisterMsrMtrrPhysMaskF = 8271,
	WHvX64RegisterMsrMtrrFix64k00000 = 8304,
	WHvX64RegisterMsrMtrrFix16k80000 = 8305,
	WHvX64RegisterMsrMtrrFix16kA0000 = 8306,
	WHvX64RegisterMsrMtrrFix4kC0000 = 8307,
	WHvX64RegisterMsrMtrrFix4kC8000 = 8308,
	WHvX64RegisterMsrMtrrFix4kD0000 = 8309,
	WHvX64RegisterMsrMtrrFix4kD8000 = 8310,
	WHvX64RegisterMsrMtrrFix4kE0000 = 8311,
	WHvX64RegisterMsrMtrrFix4kE8000 = 8312,
	WHvX64RegisterMsrMtrrFix4kF0000 = 8313,
	WHvX64RegisterMsrMtrrFix4kF8000 = 8314,
	WHvX64RegisterTscAux = 8315,
	WHvX64RegisterBndcfgs = 8316,
	WHvX64RegisterMCount = 8318,
	WHvX64RegisterACount = 8319,
	WHvX64RegisterSpecCtrl = 8324,
	WHvX64RegisterPredCmd = 8325,
	WHvX64RegisterTscVirtualOffset = 8327,
	WHvX64RegisterTsxCtrl = 8328,
	WHvX64RegisterXss = 8331,
	WHvX64RegisterUCet = 8332,
	WHvX64RegisterSCet = 8333,
	WHvX64RegisterSsp = 8334,
	WHvX64RegisterPl0Ssp = 8335,
	WHvX64RegisterPl1Ssp = 8336,
	WHvX64RegisterPl2Ssp = 8337,
	WHvX64RegisterPl3Ssp = 8338,
	WHvX64RegisterInterruptSspTableAddr = 8339,
	WHvX64RegisterTscDeadline = 8341,
	WHvX64RegisterTscAdjust = 8342,
	WHvX64RegisterUmwaitControl = 8344,
	WHvX64RegisterXfd = 8345,
	WHvX64RegisterXfdErr = 8346,
	WHvX64RegisterApicId = 12290,
	WHvX64RegisterApicVersion = 12291,
	WHvX64RegisterApicTpr = 12296,
	WHvX64RegisterApicPpr = 12298,
	WHvX64RegisterApicEoi = 12299,
	WHvX64RegisterApicLdr = 12301,
	WHvX64RegisterApicSpurious = 12303,
	WHvX64RegisterApicIsr0 = 12304,
	WHvX64RegisterApicIsr1 = 12305,
	WHvX64RegisterApicIsr2 = 12306,
	WHvX64RegisterApicIsr3 = 12307,
	WHvX64RegisterApicIsr4 = 12308,
	WHvX64RegisterApicIsr5 = 12309,
	WHvX64RegisterApicIsr6 = 12310,
	WHvX64RegisterApicIsr7 = 12311,
	WHvX64RegisterApicTmr0 = 12312,
	WHvX64RegisterApicTmr1 = 12313,
	WHvX64RegisterApicTmr2 = 12314,
	WHvX64RegisterApicTmr3 = 12315,
	WHvX64RegisterApicTmr4 = 12316,
	WHvX64RegisterApicTmr5 = 12317,
	WHvX64RegisterApicTmr6 = 12318,
	WHvX64RegisterApicTmr7 = 12319,
	WHvX64RegisterApicIrr0 = 12320,
	WHvX64RegisterApicIrr1 = 12321,
	WHvX64RegisterApicIrr2 = 12322,
	WHvX64RegisterApicIrr3 = 12323,
	WHvX64RegisterApicIrr4 = 12324,
	WHvX64RegisterApicIrr5 = 12325,
	WHvX64RegisterApicIrr6 = 12326,
	WHvX64RegisterApicIrr7 = 12327,
	WHvX64RegisterApicEse = 12328,
	WHvX64RegisterApicIcr = 12336,
	WHvX64RegisterApicLvtTimer = 12338,
	WHvX64RegisterApicLvtThermal = 12339,
	WHvX64RegisterApicLvtPerfmon = 12340,
	WHvX64RegisterApicLvtLint0 = 12341,
	WHvX64RegisterApicLvtLint1 = 12342,
	WHvX64RegisterApicLvtError = 12343,
	WHvX64RegisterApicInitCount = 12344,
	WHvX64RegisterApicCurrentCount = 12345,
	WHvX64RegisterApicDivide = 12350,
	WHvX64RegisterApicSelfIpi = 12351,
	WHvRegisterSint0 = 16384,
	WHvRegisterSint1 = 16385,
	WHvRegisterSint2 = 16386,
	WHvRegisterSint3 = 16387,
	WHvRegisterSint4 = 16388,
	WHvRegisterSint5 = 16389,
	WHvRegisterSint6 = 16390,
	WHvRegisterSint7 = 16391,
	WHvRegisterSint8 = 16392,
	WHvRegisterSint9 = 16393,
	WHvRegisterSint10 = 16394,
	WHvRegisterSint11 = 16395,
	WHvRegisterSint12 = 16396,
	WHvRegisterSint13 = 16397,
	WHvRegisterSint14 = 16398,
	WHvRegisterSint15 = 16399,
	WHvRegisterScontrol = 16400,
	WHvRegisterSversion = 16401,
	WHvRegisterSiefp = 16402,
	WHvRegisterSimp = 16403,
	WHvRegisterEom = 16404,
	WHvRegisterVpRuntime = 20480,
	WHvX64RegisterHypercall = 20481,
	WHvRegisterGuestOsId = 20482,
	WHvRegisterVpAssistPage = 20499,
	WHvRegisterReferenceTsc = 20503,
	WHvRegisterReferenceTscSequence = 20506,
	WHvRegisterPendingInterruption = -2147483648,
	WHvRegisterInterruptState = -2147483647,
	WHvRegisterPendingEvent = -2147483646,
	WHvX64RegisterDeliverabilityNotifications = -2147483644,
	WHvRegisterInternalActivityState = -2147483643,
	WHvX64RegisterPendingDebugException = -2147483642,
}


[AllowDuplicates]
public enum WHV_X64_PENDING_EVENT_TYPE : int32
{
	WHvX64PendingEventException = 0,
	WHvX64PendingEventExtInt = 5,
}


[AllowDuplicates]
public enum WHV_RUN_VP_EXIT_REASON : int32
{
	WHvRunVpExitReasonNone = 0,
	WHvRunVpExitReasonMemoryAccess = 1,
	WHvRunVpExitReasonX64IoPortAccess = 2,
	WHvRunVpExitReasonUnrecoverableException = 4,
	WHvRunVpExitReasonInvalidVpRegisterValue = 5,
	WHvRunVpExitReasonUnsupportedFeature = 6,
	WHvRunVpExitReasonX64InterruptWindow = 7,
	WHvRunVpExitReasonX64Halt = 8,
	WHvRunVpExitReasonX64ApicEoi = 9,
	WHvRunVpExitReasonSynicSintDeliverable = 10,
	WHvRunVpExitReasonX64MsrAccess = 4096,
	WHvRunVpExitReasonX64Cpuid = 4097,
	WHvRunVpExitReasonException = 4098,
	WHvRunVpExitReasonX64Rdtsc = 4099,
	WHvRunVpExitReasonX64ApicSmiTrap = 4100,
	WHvRunVpExitReasonHypercall = 4101,
	WHvRunVpExitReasonX64ApicInitSipiTrap = 4102,
	WHvRunVpExitReasonX64ApicWriteTrap = 4103,
	WHvRunVpExitReasonCanceled = 8193,
}


[AllowDuplicates]
public enum WHV_X64_UNSUPPORTED_FEATURE_CODE : int32
{
	WHvUnsupportedFeatureIntercept = 1,
	WHvUnsupportedFeatureTaskSwitchTss = 2,
}


[AllowDuplicates]
public enum WHV_RUN_VP_CANCEL_REASON : int32
{
	WHvRunVpCancelReasonUser = 0,
}


[AllowDuplicates]
public enum WHV_X64_PENDING_INTERRUPTION_TYPE : int32
{
	WHvX64PendingInterrupt = 0,
	WHvX64PendingNmi = 2,
	WHvX64PendingException = 3,
}


[AllowDuplicates]
public enum WHV_X64_APIC_WRITE_TYPE : int32
{
	WHvX64ApicWriteTypeLdr = 208,
	WHvX64ApicWriteTypeDfr = 224,
	WHvX64ApicWriteTypeSvr = 240,
	WHvX64ApicWriteTypeLint0 = 848,
	WHvX64ApicWriteTypeLint1 = 864,
}


[AllowDuplicates]
public enum WHV_INTERRUPT_TYPE : int32
{
	WHvX64InterruptTypeFixed = 0,
	WHvX64InterruptTypeLowestPriority = 1,
	WHvX64InterruptTypeNmi = 4,
	WHvX64InterruptTypeInit = 5,
	WHvX64InterruptTypeSipi = 6,
	WHvX64InterruptTypeLocalInt1 = 9,
}


[AllowDuplicates]
public enum WHV_INTERRUPT_DESTINATION_MODE : int32
{
	WHvX64InterruptDestinationModePhysical = 0,
	WHvX64InterruptDestinationModeLogical = 1,
}


[AllowDuplicates]
public enum WHV_INTERRUPT_TRIGGER_MODE : int32
{
	WHvX64InterruptTriggerModeEdge = 0,
	WHvX64InterruptTriggerModeLevel = 1,
}


[AllowDuplicates]
public enum WHV_PARTITION_COUNTER_SET : int32
{
	WHvPartitionCounterSetMemory = 0,
}


[AllowDuplicates]
public enum WHV_PROCESSOR_COUNTER_SET : int32
{
	WHvProcessorCounterSetRuntime = 0,
	WHvProcessorCounterSetIntercepts = 1,
	WHvProcessorCounterSetEvents = 2,
	WHvProcessorCounterSetApic = 3,
	WHvProcessorCounterSetSyntheticFeatures = 4,
}


[AllowDuplicates]
public enum WHV_ADVISE_GPA_RANGE_CODE : int32
{
	WHvAdviseGpaRangeCodePopulate = 0,
	WHvAdviseGpaRangeCodePin = 1,
	WHvAdviseGpaRangeCodeUnpin = 2,
}


[AllowDuplicates]
public enum WHV_VIRTUAL_PROCESSOR_STATE_TYPE : int32
{
	WHvVirtualProcessorStateTypeSynicMessagePage = 0,
	WHvVirtualProcessorStateTypeSynicEventFlagPage = 1,
	WHvVirtualProcessorStateTypeSynicTimerState = 2,
	WHvVirtualProcessorStateTypeInterruptControllerState2 = 4096,
	WHvVirtualProcessorStateTypeXsaveState = 4097,
}


[AllowDuplicates]
public enum WHV_ALLOCATE_VPCI_RESOURCE_FLAGS : uint32
{
	WHvAllocateVpciResourceFlagNone = 0,
	WHvAllocateVpciResourceFlagAllowDirectP2P = 1,
}


[AllowDuplicates]
public enum WHV_VPCI_DEVICE_NOTIFICATION_TYPE : int32
{
	WHvVpciDeviceNotificationUndefined = 0,
	WHvVpciDeviceNotificationMmioRemapping = 1,
	WHvVpciDeviceNotificationSurpriseRemoval = 2,
}


[AllowDuplicates]
public enum WHV_CREATE_VPCI_DEVICE_FLAGS : uint32
{
	WHvCreateVpciDeviceFlagNone = 0,
	WHvCreateVpciDeviceFlagPhysicallyBacked = 1,
	WHvCreateVpciDeviceFlagUseLogicalInterrupts = 2,
}


[AllowDuplicates]
public enum WHV_VPCI_DEVICE_PROPERTY_CODE : int32
{
	WHvVpciDevicePropertyCodeUndefined = 0,
	WHvVpciDevicePropertyCodeHardwareIDs = 1,
	WHvVpciDevicePropertyCodeProbedBARs = 2,
}


[AllowDuplicates]
public enum WHV_VPCI_MMIO_RANGE_FLAGS : uint32
{
	WHvVpciMmioRangeFlagReadAccess = 1,
	WHvVpciMmioRangeFlagWriteAccess = 2,
}


[AllowDuplicates]
public enum WHV_VPCI_DEVICE_REGISTER_SPACE : int32
{
	WHvVpciConfigSpace = -1,
	WHvVpciBar0 = 0,
	WHvVpciBar1 = 1,
	WHvVpciBar2 = 2,
	WHvVpciBar3 = 3,
	WHvVpciBar4 = 4,
	WHvVpciBar5 = 5,
}


[AllowDuplicates]
public enum WHV_VPCI_INTERRUPT_TARGET_FLAGS : uint32
{
	WHvVpciInterruptTargetFlagNone = 0,
	WHvVpciInterruptTargetFlagMulticast = 1,
}


[AllowDuplicates]
public enum WHV_TRIGGER_TYPE : int32
{
	WHvTriggerTypeInterrupt = 0,
	WHvTriggerTypeSynicEvent = 1,
	WHvTriggerTypeDeviceInterrupt = 2,
}


[AllowDuplicates]
public enum WHV_VIRTUAL_PROCESSOR_PROPERTY_CODE : int32
{
	WHvVirtualProcessorPropertyCodeNumaNode = 0,
}


[AllowDuplicates]
public enum WHV_NOTIFICATION_PORT_TYPE : int32
{
	WHvNotificationPortTypeEvent = 2,
	WHvNotificationPortTypeDoorbell = 4,
}


[AllowDuplicates]
public enum WHV_NOTIFICATION_PORT_PROPERTY_CODE : int32
{
	WHvNotificationPortPropertyPreferredTargetVp = 1,
	WHvNotificationPortPropertyPreferredTargetDuration = 5,
}


[AllowDuplicates]
public enum HDV_DEVICE_TYPE : int32
{
	HdvDeviceTypeUndefined = 0,
	HdvDeviceTypePCI = 1,
}


[AllowDuplicates]
public enum HDV_PCI_BAR_SELECTOR : int32
{
	HDV_PCI_BAR0 = 0,
	HDV_PCI_BAR1 = 1,
	HDV_PCI_BAR2 = 2,
	HDV_PCI_BAR3 = 3,
	HDV_PCI_BAR4 = 4,
	HDV_PCI_BAR5 = 5,
}


[AllowDuplicates]
public enum HDV_DOORBELL_FLAGS : int32
{
	HDV_DOORBELL_FLAG_TRIGGER_SIZE_ANY = 0,
	HDV_DOORBELL_FLAG_TRIGGER_SIZE_BYTE = 1,
	HDV_DOORBELL_FLAG_TRIGGER_SIZE_WORD = 2,
	HDV_DOORBELL_FLAG_TRIGGER_SIZE_DWORD = 3,
	HDV_DOORBELL_FLAG_TRIGGER_SIZE_QWORD = 4,
	HDV_DOORBELL_FLAG_TRIGGER_ANY_VALUE = -2147483648,
}


[AllowDuplicates]
public enum HDV_MMIO_MAPPING_FLAGS : uint32
{
	HdvMmioMappingFlagNone = 0,
	HdvMmioMappingFlagWriteable = 1,
	HdvMmioMappingFlagExecutable = 2,
}


[AllowDuplicates]
public enum HDV_PCI_INTERFACE_VERSION : int32
{
	HdvPciDeviceInterfaceVersionInvalid = 0,
	HdvPciDeviceInterfaceVersion1 = 1,
}


[AllowDuplicates]
public enum PAGING_MODE : int32
{
	Paging_Invalid = 0,
	Paging_NonPaged = 1,
	Paging_32Bit = 2,
	Paging_Pae = 3,
	Paging_Long = 4,
	Paging_Armv8 = 5,
}


[AllowDuplicates]
public enum VIRTUAL_PROCESSOR_ARCH : int32
{
	Arch_Unknown = 0,
	Arch_x86 = 1,
	Arch_x64 = 2,
	Arch_Armv8 = 3,
}


[AllowDuplicates]
public enum VIRTUAL_PROCESSOR_VENDOR : int32
{
	ProcessorVendor_Unknown = 0,
	ProcessorVendor_Amd = 1,
	ProcessorVendor_Intel = 2,
	ProcessorVendor_Hygon = 3,
	ProcessorVendor_Arm = 4,
}


[AllowDuplicates]
public enum GUEST_OS_VENDOR : int32
{
	GuestOsVendorUndefined = 0,
	GuestOsVendorMicrosoft = 1,
	GuestOsVendorHPE = 2,
	GuestOsVendorLANCOM = 512,
}


[AllowDuplicates]
public enum GUEST_OS_MICROSOFT_IDS : int32
{
	GuestOsMicrosoftUndefined = 0,
	GuestOsMicrosoftMSDOS = 1,
	GuestOsMicrosoftWindows3x = 2,
	GuestOsMicrosoftWindows9x = 3,
	GuestOsMicrosoftWindowsNT = 4,
	GuestOsMicrosoftWindowsCE = 5,
}


[AllowDuplicates]
public enum GUEST_OS_OPENSOURCE_IDS : int32
{
	GuestOsOpenSourceUndefined = 0,
	GuestOsOpenSourceLinux = 1,
	GuestOsOpenSourceFreeBSD = 2,
	GuestOsOpenSourceXen = 3,
	GuestOsOpenSourceIllumos = 4,
}


[AllowDuplicates]
public enum REGISTER_ID : int32
{
	X64_RegisterRax = 0,
	X64_RegisterRcx = 1,
	X64_RegisterRdx = 2,
	X64_RegisterRbx = 3,
	X64_RegisterRsp = 4,
	X64_RegisterRbp = 5,
	X64_RegisterRsi = 6,
	X64_RegisterRdi = 7,
	X64_RegisterR8 = 8,
	X64_RegisterR9 = 9,
	X64_RegisterR10 = 10,
	X64_RegisterR11 = 11,
	X64_RegisterR12 = 12,
	X64_RegisterR13 = 13,
	X64_RegisterR14 = 14,
	X64_RegisterR15 = 15,
	X64_RegisterRip = 16,
	X64_RegisterRFlags = 17,
	X64_RegisterXmm0 = 18,
	X64_RegisterXmm1 = 19,
	X64_RegisterXmm2 = 20,
	X64_RegisterXmm3 = 21,
	X64_RegisterXmm4 = 22,
	X64_RegisterXmm5 = 23,
	X64_RegisterXmm6 = 24,
	X64_RegisterXmm7 = 25,
	X64_RegisterXmm8 = 26,
	X64_RegisterXmm9 = 27,
	X64_RegisterXmm10 = 28,
	X64_RegisterXmm11 = 29,
	X64_RegisterXmm12 = 30,
	X64_RegisterXmm13 = 31,
	X64_RegisterXmm14 = 32,
	X64_RegisterXmm15 = 33,
	X64_RegisterFpMmx0 = 34,
	X64_RegisterFpMmx1 = 35,
	X64_RegisterFpMmx2 = 36,
	X64_RegisterFpMmx3 = 37,
	X64_RegisterFpMmx4 = 38,
	X64_RegisterFpMmx5 = 39,
	X64_RegisterFpMmx6 = 40,
	X64_RegisterFpMmx7 = 41,
	X64_RegisterFpControlStatus = 42,
	X64_RegisterXmmControlStatus = 43,
	X64_RegisterCr0 = 44,
	X64_RegisterCr2 = 45,
	X64_RegisterCr3 = 46,
	X64_RegisterCr4 = 47,
	X64_RegisterCr8 = 48,
	X64_RegisterEfer = 49,
	X64_RegisterDr0 = 50,
	X64_RegisterDr1 = 51,
	X64_RegisterDr2 = 52,
	X64_RegisterDr3 = 53,
	X64_RegisterDr6 = 54,
	X64_RegisterDr7 = 55,
	X64_RegisterEs = 56,
	X64_RegisterCs = 57,
	X64_RegisterSs = 58,
	X64_RegisterDs = 59,
	X64_RegisterFs = 60,
	X64_RegisterGs = 61,
	X64_RegisterLdtr = 62,
	X64_RegisterTr = 63,
	X64_RegisterIdtr = 64,
	X64_RegisterGdtr = 65,
	X64_RegisterMax = 66,
	ARM64_RegisterX0 = 67,
	ARM64_RegisterX1 = 68,
	ARM64_RegisterX2 = 69,
	ARM64_RegisterX3 = 70,
	ARM64_RegisterX4 = 71,
	ARM64_RegisterX5 = 72,
	ARM64_RegisterX6 = 73,
	ARM64_RegisterX7 = 74,
	ARM64_RegisterX8 = 75,
	ARM64_RegisterX9 = 76,
	ARM64_RegisterX10 = 77,
	ARM64_RegisterX11 = 78,
	ARM64_RegisterX12 = 79,
	ARM64_RegisterX13 = 80,
	ARM64_RegisterX14 = 81,
	ARM64_RegisterX15 = 82,
	ARM64_RegisterX16 = 83,
	ARM64_RegisterX17 = 84,
	ARM64_RegisterX18 = 85,
	ARM64_RegisterX19 = 86,
	ARM64_RegisterX20 = 87,
	ARM64_RegisterX21 = 88,
	ARM64_RegisterX22 = 89,
	ARM64_RegisterX23 = 90,
	ARM64_RegisterX24 = 91,
	ARM64_RegisterX25 = 92,
	ARM64_RegisterX26 = 93,
	ARM64_RegisterX27 = 94,
	ARM64_RegisterX28 = 95,
	ARM64_RegisterXFp = 96,
	ARM64_RegisterXLr = 97,
	ARM64_RegisterPc = 98,
	ARM64_RegisterSpEl0 = 99,
	ARM64_RegisterSpEl1 = 100,
	ARM64_RegisterCpsr = 101,
	ARM64_RegisterQ0 = 102,
	ARM64_RegisterQ1 = 103,
	ARM64_RegisterQ2 = 104,
	ARM64_RegisterQ3 = 105,
	ARM64_RegisterQ4 = 106,
	ARM64_RegisterQ5 = 107,
	ARM64_RegisterQ6 = 108,
	ARM64_RegisterQ7 = 109,
	ARM64_RegisterQ8 = 110,
	ARM64_RegisterQ9 = 111,
	ARM64_RegisterQ10 = 112,
	ARM64_RegisterQ11 = 113,
	ARM64_RegisterQ12 = 114,
	ARM64_RegisterQ13 = 115,
	ARM64_RegisterQ14 = 116,
	ARM64_RegisterQ15 = 117,
	ARM64_RegisterQ16 = 118,
	ARM64_RegisterQ17 = 119,
	ARM64_RegisterQ18 = 120,
	ARM64_RegisterQ19 = 121,
	ARM64_RegisterQ20 = 122,
	ARM64_RegisterQ21 = 123,
	ARM64_RegisterQ22 = 124,
	ARM64_RegisterQ23 = 125,
	ARM64_RegisterQ24 = 126,
	ARM64_RegisterQ25 = 127,
	ARM64_RegisterQ26 = 128,
	ARM64_RegisterQ27 = 129,
	ARM64_RegisterQ28 = 130,
	ARM64_RegisterQ29 = 131,
	ARM64_RegisterQ30 = 132,
	ARM64_RegisterQ31 = 133,
	ARM64_RegisterFpStatus = 134,
	ARM64_RegisterFpControl = 135,
	ARM64_RegisterEsrEl1 = 136,
	ARM64_RegisterSpsrEl1 = 137,
	ARM64_RegisterFarEl1 = 138,
	ARM64_RegisterParEl1 = 139,
	ARM64_RegisterElrEl1 = 140,
	ARM64_RegisterTtbr0El1 = 141,
	ARM64_RegisterTtbr1El1 = 142,
	ARM64_RegisterVbarEl1 = 143,
	ARM64_RegisterSctlrEl1 = 144,
	ARM64_RegisterActlrEl1 = 145,
	ARM64_RegisterTcrEl1 = 146,
	ARM64_RegisterMairEl1 = 147,
	ARM64_RegisterAmairEl1 = 148,
	ARM64_RegisterTpidrEl0 = 149,
	ARM64_RegisterTpidrroEl0 = 150,
	ARM64_RegisterTpidrEl1 = 151,
	ARM64_RegisterContextIdrEl1 = 152,
	ARM64_RegisterCpacrEl1 = 153,
	ARM64_RegisterCsselrEl1 = 154,
	ARM64_RegisterCntkctlEl1 = 155,
	ARM64_RegisterCntvCvalEl0 = 156,
	ARM64_RegisterCntvCtlEl0 = 157,
	ARM64_RegisterMax = 158,
}

#endregion

#region Function Pointers
public function HRESULT WHV_EMULATOR_IO_PORT_CALLBACK(void* Context, WHV_EMULATOR_IO_ACCESS_INFO* IoAccess);

public function HRESULT WHV_EMULATOR_MEMORY_CALLBACK(void* Context, WHV_EMULATOR_MEMORY_ACCESS_INFO* MemoryAccess);

public function HRESULT WHV_EMULATOR_GET_VIRTUAL_PROCESSOR_REGISTERS_CALLBACK(void* Context, WHV_REGISTER_NAME* RegisterNames, uint32 RegisterCount, WHV_REGISTER_VALUE* RegisterValues);

public function HRESULT WHV_EMULATOR_SET_VIRTUAL_PROCESSOR_REGISTERS_CALLBACK(void* Context, WHV_REGISTER_NAME* RegisterNames, uint32 RegisterCount, WHV_REGISTER_VALUE* RegisterValues);

public function HRESULT WHV_EMULATOR_TRANSLATE_GVA_PAGE_CALLBACK(void* Context, uint64 Gva, WHV_TRANSLATE_GVA_FLAGS TranslateFlags, WHV_TRANSLATE_GVA_RESULT_CODE* TranslationResult, uint64* Gpa);

public function HRESULT HDV_PCI_DEVICE_INITIALIZE(void* deviceContext);

public function void HDV_PCI_DEVICE_TEARDOWN(void* deviceContext);

public function HRESULT HDV_PCI_DEVICE_SET_CONFIGURATION(void* deviceContext, uint32 configurationValueCount, PWSTR* configurationValues);

public function HRESULT HDV_PCI_DEVICE_GET_DETAILS(void* deviceContext, HDV_PCI_PNP_ID* pnpId, uint32 probedBarsCount, uint32* probedBars);

public function HRESULT HDV_PCI_DEVICE_START(void* deviceContext);

public function void HDV_PCI_DEVICE_STOP(void* deviceContext);

public function HRESULT HDV_PCI_READ_CONFIG_SPACE(void* deviceContext, uint32 offset, uint32* value);

public function HRESULT HDV_PCI_WRITE_CONFIG_SPACE(void* deviceContext, uint32 offset, uint32 value);

public function HRESULT HDV_PCI_READ_INTERCEPTED_MEMORY(void* deviceContext, HDV_PCI_BAR_SELECTOR barIndex, uint64 offset, uint64 length, uint8* value);

public function HRESULT HDV_PCI_WRITE_INTERCEPTED_MEMORY(void* deviceContext, HDV_PCI_BAR_SELECTOR barIndex, uint64 offset, uint64 length, uint8* value);

public function void GUEST_SYMBOLS_PROVIDER_DEBUG_INFO_CALLBACK(PSTR InfoMessage);

public function BOOL FOUND_IMAGE_CALLBACK(void* Context, DOS_IMAGE_INFO* ImageInfo);

#endregion

#region Structs
[CRepr, Union]
public struct WHV_CAPABILITY_FEATURES
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_EXTENDED_VM_EXITS
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_PROCESSOR_FEATURES
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_PROCESSOR_FEATURES1
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr]
public struct WHV_PROCESSOR_FEATURES_BANKS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public WHV_PROCESSOR_FEATURES Bank0;
			public WHV_PROCESSOR_FEATURES1 Bank1;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint64[2] AsUINT64;
	}
	public uint32 BanksCount;
	public uint32 Reserved0;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Union]
public struct WHV_SYNTHETIC_PROCESSOR_FEATURES
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr]
public struct WHV_SYNTHETIC_PROCESSOR_FEATURES_BANKS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public WHV_SYNTHETIC_PROCESSOR_FEATURES Bank0;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint64* AsUINT64 mut => &AsUINT64_impl;
		private uint64[ANYSIZE_ARRAY] AsUINT64_impl;
	}
	public uint32 BanksCount;
	public uint32 Reserved0;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Union]
public struct WHV_PROCESSOR_XSAVE_FEATURES
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_PROCESSOR_PERFMON_FEATURES
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_X64_MSR_EXIT_BITMAP
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public uint64 AsUINT64;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct WHV_MEMORY_RANGE_ENTRY
{
	public uint64 GuestAddress;
	public uint64 SizeInBytes;
}

[CRepr, Union]
public struct WHV_ADVISE_GPA_RANGE_POPULATE_FLAGS
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public uint32 AsUINT32;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct WHV_ADVISE_GPA_RANGE_POPULATE
{
	public WHV_ADVISE_GPA_RANGE_POPULATE_FLAGS Flags;
	public WHV_MEMORY_ACCESS_TYPE AccessType;
}

[CRepr]
public struct WHV_CAPABILITY_PROCESSOR_FREQUENCY_CAP
{
	public uint32 _bitfield;
	public uint32 HighestFrequencyMhz;
	public uint32 NominalFrequencyMhz;
	public uint32 LowestFrequencyMhz;
	public uint32 FrequencyStepMhz;
}

[CRepr, Union]
public struct WHV_SCHEDULER_FEATURES
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_CAPABILITY
{
	public BOOL HypervisorPresent;
	public WHV_CAPABILITY_FEATURES Features;
	public WHV_EXTENDED_VM_EXITS ExtendedVmExits;
	public WHV_PROCESSOR_VENDOR ProcessorVendor;
	public WHV_PROCESSOR_FEATURES ProcessorFeatures;
	public WHV_SYNTHETIC_PROCESSOR_FEATURES_BANKS SyntheticProcessorFeaturesBanks;
	public WHV_PROCESSOR_XSAVE_FEATURES ProcessorXsaveFeatures;
	public uint8 ProcessorClFlushSize;
	public uint64 ExceptionExitBitmap;
	public WHV_X64_MSR_EXIT_BITMAP X64MsrExitBitmap;
	public uint64 ProcessorClockFrequency;
	public uint64 InterruptClockFrequency;
	public WHV_PROCESSOR_FEATURES_BANKS ProcessorFeaturesBanks;
	public WHV_ADVISE_GPA_RANGE_POPULATE_FLAGS GpaRangePopulateFlags;
	public WHV_CAPABILITY_PROCESSOR_FREQUENCY_CAP ProcessorFrequencyCap;
	public WHV_PROCESSOR_PERFMON_FEATURES ProcessorPerfmonFeatures;
	public WHV_SCHEDULER_FEATURES SchedulerFeatures;
}

[CRepr]
public struct WHV_X64_CPUID_RESULT
{
	public uint32 Function;
	public uint32[3] Reserved;
	public uint32 Eax;
	public uint32 Ebx;
	public uint32 Ecx;
	public uint32 Edx;
}

[CRepr]
public struct WHV_CPUID_OUTPUT
{
	public uint32 Eax;
	public uint32 Ebx;
	public uint32 Ecx;
	public uint32 Edx;
}

[CRepr]
public struct WHV_X64_CPUID_RESULT2
{
	public uint32 Function;
	public uint32 Index;
	public uint32 VpIndex;
	public WHV_X64_CPUID_RESULT2_FLAGS Flags;
	public WHV_CPUID_OUTPUT Output;
	public WHV_CPUID_OUTPUT Mask;
}

[CRepr]
public struct WHV_MSR_ACTION_ENTRY
{
	public uint32 Index;
	public uint8 ReadAction;
	public uint8 WriteAction;
	public uint16 Reserved;
}

[CRepr, Union]
public struct WHV_PARTITION_PROPERTY
{
	public WHV_EXTENDED_VM_EXITS ExtendedVmExits;
	public WHV_PROCESSOR_FEATURES ProcessorFeatures;
	public WHV_SYNTHETIC_PROCESSOR_FEATURES_BANKS SyntheticProcessorFeaturesBanks;
	public WHV_PROCESSOR_XSAVE_FEATURES ProcessorXsaveFeatures;
	public uint8 ProcessorClFlushSize;
	public uint32 ProcessorCount;
	public uint32* CpuidExitList mut => &CpuidExitList_impl;
	private uint32[ANYSIZE_ARRAY] CpuidExitList_impl;
	public WHV_X64_CPUID_RESULT* CpuidResultList mut => &CpuidResultList_impl;
	private WHV_X64_CPUID_RESULT[ANYSIZE_ARRAY] CpuidResultList_impl;
	public WHV_X64_CPUID_RESULT2* CpuidResultList2 mut => &CpuidResultList2_impl;
	private WHV_X64_CPUID_RESULT2[ANYSIZE_ARRAY] CpuidResultList2_impl;
	public WHV_MSR_ACTION_ENTRY* MsrActionList mut => &MsrActionList_impl;
	private WHV_MSR_ACTION_ENTRY[ANYSIZE_ARRAY] MsrActionList_impl;
	public WHV_MSR_ACTION UnimplementedMsrAction;
	public uint64 ExceptionExitBitmap;
	public WHV_X64_LOCAL_APIC_EMULATION_MODE LocalApicEmulationMode;
	public BOOL SeparateSecurityDomain;
	public BOOL NestedVirtualization;
	public WHV_X64_MSR_EXIT_BITMAP X64MsrExitBitmap;
	public uint64 ProcessorClockFrequency;
	public uint64 InterruptClockFrequency;
	public BOOL ApicRemoteRead;
	public WHV_PROCESSOR_FEATURES_BANKS ProcessorFeaturesBanks;
	public uint64 ReferenceTime;
	public uint16 PrimaryNumaNode;
	public uint32 CpuReserve;
	public uint32 CpuCap;
	public uint32 CpuWeight;
	public uint64 CpuGroupId;
	public uint32 ProcessorFrequencyCap;
	public BOOL AllowDeviceAssignment;
	public WHV_PROCESSOR_PERFMON_FEATURES ProcessorPerfmonFeatures;
	public BOOL DisableSmt;
}

[CRepr]
public struct WHV_TRANSLATE_GVA_RESULT
{
	public WHV_TRANSLATE_GVA_RESULT_CODE ResultCode;
	public uint32 Reserved;
}

[CRepr, Union]
public struct WHV_ADVISE_GPA_RANGE
{
	public WHV_ADVISE_GPA_RANGE_POPULATE Populate;
}

[CRepr, Union]
public struct WHV_ACCESS_GPA_CONTROLS
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public WHV_CACHE_TYPE CacheType;
		public uint32 Reserved;
	}
	public uint64 AsUINT64;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union]
public struct WHV_UINT128
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 Low64;
		public uint64 High64;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint32[4] Dword;
}

[CRepr, Union]
public struct WHV_X64_FP_REGISTER
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 Mantissa;
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public WHV_UINT128 AsUINT128;
}

[CRepr, Union]
public struct WHV_X64_FP_CONTROL_STATUS_REGISTER
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		[CRepr, Union]
		public struct _Anonymous_e__Union
		{
			[CRepr]
			public struct _Anonymous_e__Struct
			{
				public uint32 LastFpEip;
				public uint16 LastFpCs;
				public uint16 Reserved2;
			}
			public uint64 LastFpRip;
			public using _Anonymous_e__Struct Anonymous;
		}
		public uint16 FpControl;
		public uint16 FpStatus;
		public uint8 FpTag;
		public uint8 Reserved;
		public uint16 LastFpOp;
		public using _Anonymous_e__Union Anonymous;
	}
	public using _Anonymous_e__Struct Anonymous;
	public WHV_UINT128 AsUINT128;
}

[CRepr, Union]
public struct WHV_X64_XMM_CONTROL_STATUS_REGISTER
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		[CRepr, Union]
		public struct _Anonymous_e__Union
		{
			[CRepr]
			public struct _Anonymous_e__Struct
			{
				public uint32 LastFpDp;
				public uint16 LastFpDs;
				public uint16 Reserved;
			}
			public uint64 LastFpRdp;
			public using _Anonymous_e__Struct Anonymous;
		}
		public using _Anonymous_e__Union Anonymous;
		public uint32 XmmStatusControl;
		public uint32 XmmStatusControlMask;
	}
	public using _Anonymous_e__Struct Anonymous;
	public WHV_UINT128 AsUINT128;
}

[CRepr]
public struct WHV_X64_SEGMENT_REGISTER
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint16 Attributes;
	}
	public uint64 Base;
	public uint32 Limit;
	public uint16 Selector;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WHV_X64_TABLE_REGISTER
{
	public uint16[3] Pad;
	public uint16 Limit;
	public uint64 Base;
}

[CRepr, Union]
public struct WHV_X64_INTERRUPT_STATE_REGISTER
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_X64_PENDING_INTERRUPTION_REGISTER
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
		public uint32 ErrorCode;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_X64_DELIVERABILITY_NOTIFICATIONS_REGISTER
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_X64_PENDING_EXCEPTION_EVENT
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
		public uint32 ErrorCode;
		public uint64 ExceptionParameter;
	}
	public using _Anonymous_e__Struct Anonymous;
	public WHV_UINT128 AsUINT128;
}

[CRepr, Union]
public struct WHV_X64_PENDING_EXT_INT_EVENT
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
		public uint64 Reserved2;
	}
	public using _Anonymous_e__Struct Anonymous;
	public WHV_UINT128 AsUINT128;
}

[CRepr, Union]
public struct WHV_INTERNAL_ACTIVITY_REGISTER
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr, Union]
public struct WHV_X64_PENDING_DEBUG_EXCEPTION
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public uint64 AsUINT64;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct WHV_SYNIC_SINT_DELIVERABLE_CONTEXT
{
	public uint16 DeliverableSints;
	public uint16 Reserved1;
	public uint32 Reserved2;
}

[CRepr, Union]
public struct WHV_REGISTER_VALUE
{
	public WHV_UINT128 Reg128;
	public uint64 Reg64;
	public uint32 Reg32;
	public uint16 Reg16;
	public uint8 Reg8;
	public WHV_X64_FP_REGISTER Fp;
	public WHV_X64_FP_CONTROL_STATUS_REGISTER FpControlStatus;
	public WHV_X64_XMM_CONTROL_STATUS_REGISTER XmmControlStatus;
	public WHV_X64_SEGMENT_REGISTER Segment;
	public WHV_X64_TABLE_REGISTER Table;
	public WHV_X64_INTERRUPT_STATE_REGISTER InterruptState;
	public WHV_X64_PENDING_INTERRUPTION_REGISTER PendingInterruption;
	public WHV_X64_DELIVERABILITY_NOTIFICATIONS_REGISTER DeliverabilityNotifications;
	public WHV_X64_PENDING_EXCEPTION_EVENT ExceptionEvent;
	public WHV_X64_PENDING_EXT_INT_EVENT ExtIntEvent;
	public WHV_INTERNAL_ACTIVITY_REGISTER InternalActivity;
	public WHV_X64_PENDING_DEBUG_EXCEPTION PendingDebugException;
}

[CRepr, Union]
public struct WHV_X64_VP_EXECUTION_STATE
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint16 AsUINT16;
}

[CRepr]
public struct WHV_VP_EXIT_CONTEXT
{
	public WHV_X64_VP_EXECUTION_STATE ExecutionState;
	public uint8 _bitfield;
	public uint8 Reserved;
	public uint32 Reserved2;
	public WHV_X64_SEGMENT_REGISTER Cs;
	public uint64 Rip;
	public uint64 Rflags;
}

[CRepr, Union]
public struct WHV_MEMORY_ACCESS_INFO
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint32 AsUINT32;
}

[CRepr]
public struct WHV_MEMORY_ACCESS_CONTEXT
{
	public uint8 InstructionByteCount;
	public uint8[3] Reserved;
	public uint8[16] InstructionBytes;
	public WHV_MEMORY_ACCESS_INFO AccessInfo;
	public uint64 Gpa;
	public uint64 Gva;
}

[CRepr, Union]
public struct WHV_X64_IO_PORT_ACCESS_INFO
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint32 AsUINT32;
}

[CRepr]
public struct WHV_X64_IO_PORT_ACCESS_CONTEXT
{
	public uint8 InstructionByteCount;
	public uint8[3] Reserved;
	public uint8[16] InstructionBytes;
	public WHV_X64_IO_PORT_ACCESS_INFO AccessInfo;
	public uint16 PortNumber;
	public uint16[3] Reserved2;
	public uint64 Rax;
	public uint64 Rcx;
	public uint64 Rsi;
	public uint64 Rdi;
	public WHV_X64_SEGMENT_REGISTER Ds;
	public WHV_X64_SEGMENT_REGISTER Es;
}

[CRepr, Union]
public struct WHV_X64_MSR_ACCESS_INFO
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint32 AsUINT32;
}

[CRepr]
public struct WHV_X64_MSR_ACCESS_CONTEXT
{
	public WHV_X64_MSR_ACCESS_INFO AccessInfo;
	public uint32 MsrNumber;
	public uint64 Rax;
	public uint64 Rdx;
}

[CRepr]
public struct WHV_X64_CPUID_ACCESS_CONTEXT
{
	public uint64 Rax;
	public uint64 Rcx;
	public uint64 Rdx;
	public uint64 Rbx;
	public uint64 DefaultResultRax;
	public uint64 DefaultResultRcx;
	public uint64 DefaultResultRdx;
	public uint64 DefaultResultRbx;
}

[CRepr, Union]
public struct WHV_VP_EXCEPTION_INFO
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint32 AsUINT32;
}

[CRepr]
public struct WHV_VP_EXCEPTION_CONTEXT
{
	public uint8 InstructionByteCount;
	public uint8[3] Reserved;
	public uint8[16] InstructionBytes;
	public WHV_VP_EXCEPTION_INFO ExceptionInfo;
	public uint8 ExceptionType;
	public uint8[3] Reserved2;
	public uint32 ErrorCode;
	public uint64 ExceptionParameter;
}

[CRepr]
public struct WHV_X64_UNSUPPORTED_FEATURE_CONTEXT
{
	public WHV_X64_UNSUPPORTED_FEATURE_CODE FeatureCode;
	public uint32 Reserved;
	public uint64 FeatureParameter;
}

[CRepr]
public struct WHV_RUN_VP_CANCELED_CONTEXT
{
	public WHV_RUN_VP_CANCEL_REASON CancelReason;
}

[CRepr]
public struct WHV_X64_INTERRUPTION_DELIVERABLE_CONTEXT
{
	public WHV_X64_PENDING_INTERRUPTION_TYPE DeliverableType;
}

[CRepr]
public struct WHV_X64_APIC_EOI_CONTEXT
{
	public uint32 InterruptVector;
}

[CRepr, Union]
public struct WHV_X64_RDTSC_INFO
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 AsUINT64;
}

[CRepr]
public struct WHV_X64_RDTSC_CONTEXT
{
	public uint64 TscAux;
	public uint64 VirtualOffset;
	public uint64 Tsc;
	public uint64 ReferenceTime;
	public WHV_X64_RDTSC_INFO RdtscInfo;
}

[CRepr]
public struct WHV_X64_APIC_SMI_CONTEXT
{
	public uint64 ApicIcr;
}

[CRepr]
public struct WHV_HYPERCALL_CONTEXT
{
	public uint64 Rax;
	public uint64 Rbx;
	public uint64 Rcx;
	public uint64 Rdx;
	public uint64 R8;
	public uint64 Rsi;
	public uint64 Rdi;
	public uint64 Reserved0;
	public WHV_UINT128[6] XmmRegisters;
	public uint64[2] Reserved1;
}

[CRepr]
public struct WHV_X64_APIC_INIT_SIPI_CONTEXT
{
	public uint64 ApicIcr;
}

[CRepr]
public struct WHV_X64_APIC_WRITE_CONTEXT
{
	public WHV_X64_APIC_WRITE_TYPE Type;
	public uint32 Reserved;
	public uint64 WriteValue;
}

[CRepr]
public struct WHV_RUN_VP_EXIT_CONTEXT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public WHV_MEMORY_ACCESS_CONTEXT MemoryAccess;
		public WHV_X64_IO_PORT_ACCESS_CONTEXT IoPortAccess;
		public WHV_X64_MSR_ACCESS_CONTEXT MsrAccess;
		public WHV_X64_CPUID_ACCESS_CONTEXT CpuidAccess;
		public WHV_VP_EXCEPTION_CONTEXT VpException;
		public WHV_X64_INTERRUPTION_DELIVERABLE_CONTEXT InterruptWindow;
		public WHV_X64_UNSUPPORTED_FEATURE_CONTEXT UnsupportedFeature;
		public WHV_RUN_VP_CANCELED_CONTEXT CancelReason;
		public WHV_X64_APIC_EOI_CONTEXT ApicEoi;
		public WHV_X64_RDTSC_CONTEXT ReadTsc;
		public WHV_X64_APIC_SMI_CONTEXT ApicSmi;
		public WHV_HYPERCALL_CONTEXT Hypercall;
		public WHV_X64_APIC_INIT_SIPI_CONTEXT ApicInitSipi;
		public WHV_X64_APIC_WRITE_CONTEXT ApicWrite;
		public WHV_SYNIC_SINT_DELIVERABLE_CONTEXT SynicSintDeliverable;
	}
	public WHV_RUN_VP_EXIT_REASON ExitReason;
	public uint32 Reserved;
	public WHV_VP_EXIT_CONTEXT VpContext;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WHV_INTERRUPT_CONTROL
{
	public uint64 _bitfield;
	public uint32 Destination;
	public uint32 Vector;
}

[CRepr]
public struct WHV_DOORBELL_MATCH_DATA
{
	public uint64 GuestAddress;
	public uint64 Value;
	public uint32 Length;
	public uint32 _bitfield;
}

[CRepr]
public struct WHV_PARTITION_MEMORY_COUNTERS
{
	public uint64 Mapped4KPageCount;
	public uint64 Mapped2MPageCount;
	public uint64 Mapped1GPageCount;
}

[CRepr]
public struct WHV_PROCESSOR_RUNTIME_COUNTERS
{
	public uint64 TotalRuntime100ns;
	public uint64 HypervisorRuntime100ns;
}

[CRepr]
public struct WHV_PROCESSOR_INTERCEPT_COUNTER
{
	public uint64 Count;
	public uint64 Time100ns;
}

[CRepr]
public struct WHV_PROCESSOR_INTERCEPT_COUNTERS
{
	public WHV_PROCESSOR_INTERCEPT_COUNTER PageInvalidations;
	public WHV_PROCESSOR_INTERCEPT_COUNTER ControlRegisterAccesses;
	public WHV_PROCESSOR_INTERCEPT_COUNTER IoInstructions;
	public WHV_PROCESSOR_INTERCEPT_COUNTER HaltInstructions;
	public WHV_PROCESSOR_INTERCEPT_COUNTER CpuidInstructions;
	public WHV_PROCESSOR_INTERCEPT_COUNTER MsrAccesses;
	public WHV_PROCESSOR_INTERCEPT_COUNTER OtherIntercepts;
	public WHV_PROCESSOR_INTERCEPT_COUNTER PendingInterrupts;
	public WHV_PROCESSOR_INTERCEPT_COUNTER EmulatedInstructions;
	public WHV_PROCESSOR_INTERCEPT_COUNTER DebugRegisterAccesses;
	public WHV_PROCESSOR_INTERCEPT_COUNTER PageFaultIntercepts;
	public WHV_PROCESSOR_INTERCEPT_COUNTER NestedPageFaultIntercepts;
	public WHV_PROCESSOR_INTERCEPT_COUNTER Hypercalls;
	public WHV_PROCESSOR_INTERCEPT_COUNTER RdpmcInstructions;
}

[CRepr]
public struct WHV_PROCESSOR_EVENT_COUNTERS
{
	public uint64 PageFaultCount;
	public uint64 ExceptionCount;
	public uint64 InterruptCount;
}

[CRepr]
public struct WHV_PROCESSOR_APIC_COUNTERS
{
	public uint64 MmioAccessCount;
	public uint64 EoiAccessCount;
	public uint64 TprAccessCount;
	public uint64 SentIpiCount;
	public uint64 SelfIpiCount;
}

[CRepr]
public struct WHV_PROCESSOR_SYNTHETIC_FEATURES_COUNTERS
{
	public uint64 SyntheticInterruptsCount;
	public uint64 LongSpinWaitHypercallsCount;
	public uint64 OtherHypercallsCount;
	public uint64 SyntheticInterruptHypercallsCount;
	public uint64 VirtualInterruptHypercallsCount;
	public uint64 VirtualMmuHypercallsCount;
}

[CRepr]
public struct WHV_SYNIC_EVENT_PARAMETERS
{
	public uint32 VpIndex;
	public uint8 TargetSint;
	public uint8 Reserved;
	public uint16 FlagNumber;
}

[CRepr]
public struct WHV_SRIOV_RESOURCE_DESCRIPTOR
{
	public char16[200] PnpInstanceId;
	public LUID VirtualFunctionId;
	public uint16 VirtualFunctionIndex;
	public uint16 Reserved;
}

[CRepr]
public struct WHV_VPCI_DEVICE_NOTIFICATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint64 Reserved2;
	}
	public WHV_VPCI_DEVICE_NOTIFICATION_TYPE NotificationType;
	public uint32 Reserved1;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WHV_VPCI_HARDWARE_IDS
{
	public uint16 VendorID;
	public uint16 DeviceID;
	public uint8 RevisionID;
	public uint8 ProgIf;
	public uint8 SubClass;
	public uint8 BaseClass;
	public uint16 SubVendorID;
	public uint16 SubSystemID;
}

[CRepr]
public struct WHV_VPCI_PROBED_BARS
{
	public uint32[6] Value;
}

[CRepr]
public struct WHV_VPCI_MMIO_MAPPING
{
	public WHV_VPCI_DEVICE_REGISTER_SPACE Location;
	public WHV_VPCI_MMIO_RANGE_FLAGS Flags;
	public uint64 SizeInBytes;
	public uint64 OffsetInBytes;
	public void* VirtualAddress;
}

[CRepr]
public struct WHV_VPCI_DEVICE_REGISTER
{
	public WHV_VPCI_DEVICE_REGISTER_SPACE Location;
	public uint32 SizeInBytes;
	public uint64 OffsetInBytes;
}

[CRepr]
public struct WHV_VPCI_INTERRUPT_TARGET
{
	public uint32 Vector;
	public WHV_VPCI_INTERRUPT_TARGET_FLAGS Flags;
	public uint32 ProcessorCount;
	public uint32* Processors mut => &Processors_impl;
	private uint32[ANYSIZE_ARRAY] Processors_impl;
}

[CRepr]
public struct WHV_TRIGGER_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _DeviceInterrupt_e__Struct
		{
			public uint64 LogicalDeviceId;
			public uint64 MsiAddress;
			public uint32 MsiData;
			public uint32 Reserved;
		}
		public WHV_INTERRUPT_CONTROL Interrupt;
		public WHV_SYNIC_EVENT_PARAMETERS SynicEvent;
		public _DeviceInterrupt_e__Struct DeviceInterrupt;
	}
	public WHV_TRIGGER_TYPE TriggerType;
	public uint32 Reserved;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WHV_VIRTUAL_PROCESSOR_PROPERTY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint16 NumaNode;
		public uint64 Padding;
	}
	public WHV_VIRTUAL_PROCESSOR_PROPERTY_CODE PropertyCode;
	public uint32 Reserved;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WHV_NOTIFICATION_PORT_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Event_e__Struct
		{
			public uint32 ConnectionId;
		}
		public WHV_DOORBELL_MATCH_DATA Doorbell;
		public _Event_e__Struct Event;
	}
	public WHV_NOTIFICATION_PORT_TYPE NotificationPortType;
	public uint32 Reserved;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Union]
public struct WHV_EMULATOR_STATUS
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint32 AsUINT32;
}

[CRepr]
public struct WHV_EMULATOR_MEMORY_ACCESS_INFO
{
	public uint64 GpaAddress;
	public uint8 Direction;
	public uint8 AccessSize;
	public uint8[8] Data;
}

[CRepr]
public struct WHV_EMULATOR_IO_ACCESS_INFO
{
	public uint8 Direction;
	public uint16 Port;
	public uint16 AccessSize;
	public uint32 Data;
}

[CRepr]
public struct WHV_EMULATOR_CALLBACKS
{
	public uint32 Size;
	public uint32 Reserved;
	public WHV_EMULATOR_IO_PORT_CALLBACK WHvEmulatorIoPortCallback;
	public WHV_EMULATOR_MEMORY_CALLBACK WHvEmulatorMemoryCallback;
	public WHV_EMULATOR_GET_VIRTUAL_PROCESSOR_REGISTERS_CALLBACK WHvEmulatorGetVirtualProcessorRegisters;
	public WHV_EMULATOR_SET_VIRTUAL_PROCESSOR_REGISTERS_CALLBACK WHvEmulatorSetVirtualProcessorRegisters;
	public WHV_EMULATOR_TRANSLATE_GVA_PAGE_CALLBACK WHvEmulatorTranslateGvaPage;
}

[CRepr]
public struct SOCKADDR_HV
{
	public uint16 Family;
	public uint16 Reserved;
	public Guid VmId;
	public Guid ServiceId;
}

[CRepr]
public struct HVSOCKET_ADDRESS_INFO
{
	public Guid SystemId;
	public Guid VirtualMachineId;
	public Guid SiloId;
	public uint32 Flags;
}

[CRepr]
public struct VM_GENCOUNTER
{
	public uint64 GenerationCount;
	public uint64 GenerationCountHigh;
}

[CRepr]
public struct HDV_PCI_PNP_ID
{
	public uint16 VendorID;
	public uint16 DeviceID;
	public uint8 RevisionID;
	public uint8 ProgIf;
	public uint8 SubClass;
	public uint8 BaseClass;
	public uint16 SubVendorID;
	public uint16 SubSystemID;
}

[CRepr]
public struct HDV_PCI_DEVICE_INTERFACE
{
	public HDV_PCI_INTERFACE_VERSION Version;
	public HDV_PCI_DEVICE_INITIALIZE Initialize;
	public HDV_PCI_DEVICE_TEARDOWN Teardown;
	public HDV_PCI_DEVICE_SET_CONFIGURATION SetConfiguration;
	public HDV_PCI_DEVICE_GET_DETAILS GetDetails;
	public HDV_PCI_DEVICE_START Start;
	public HDV_PCI_DEVICE_STOP Stop;
	public HDV_PCI_READ_CONFIG_SPACE ReadConfigSpace;
	public HDV_PCI_WRITE_CONFIG_SPACE WriteConfigSpace;
	public HDV_PCI_READ_INTERCEPTED_MEMORY ReadInterceptedMemory;
	public HDV_PCI_WRITE_INTERCEPTED_MEMORY WriteInterceptedMemory;
}

[CRepr]
public struct GPA_MEMORY_CHUNK
{
	public uint64 GuestPhysicalStartPageIndex;
	public uint64 PageCount;
}

[CRepr, Union]
public struct GUEST_OS_INFO
{
	[CRepr]
	public struct _OpenSource_e__Struct
	{
		public uint64 _bitfield;
	}
	[CRepr]
	public struct _ClosedSource_e__Struct
	{
		public uint64 _bitfield;
	}
	public uint64 AsUINT64;
	public _ClosedSource_e__Struct ClosedSource;
	public _OpenSource_e__Struct OpenSource;
}

[CRepr, Union]
public struct VIRTUAL_PROCESSOR_REGISTER
{
	[CRepr, Union]
	public struct _X64_e__Union
	{
		[CRepr]
		public struct _XmmControlStatus_e__Struct
		{
			[CRepr, Union]
			public struct _Anonymous_e__Union
			{
				[CRepr]
				public struct _Anonymous_e__Struct
				{
					public uint32 LastFpDp;
					public uint16 LastFpDs;
				}
				public uint64 LastFpRdp;
				public using _Anonymous_e__Struct Anonymous;
			}
			public using _Anonymous_e__Union Anonymous;
			public uint32 XmmStatusControl;
			public uint32 XmmStatusControlMask;
		}
		[CRepr]
		public struct _FpControlStatus_e__Struct
		{
			[CRepr, Union]
			public struct _Anonymous_e__Union
			{
				[CRepr]
				public struct _Anonymous_e__Struct
				{
					public uint32 LastFpEip;
					public uint16 LastFpCs;
				}
				public uint64 LastFpRip;
				public using _Anonymous_e__Struct Anonymous;
			}
			public uint16 FpControl;
			public uint16 FpStatus;
			public uint8 FpTag;
			public uint8 Reserved;
			public uint16 LastFpOp;
			public using _Anonymous_e__Union Anonymous;
		}
		[CRepr]
		public struct _Segment_e__Struct
		{
			[CRepr, Union]
			public struct _Anonymous_e__Union
			{
				[CRepr]
				public struct _Anonymous_e__Struct
				{
					public uint16 _bitfield;
				}
				public uint16 Attributes;
				public using _Anonymous_e__Struct Anonymous;
			}
			public uint64 Base;
			public uint32 Limit;
			public uint16 Selector;
			public using _Anonymous_e__Union Anonymous;
		}
		[CRepr]
		public struct _Table_e__Struct
		{
			public uint16 Limit;
			public uint64 Base;
		}
		public _Segment_e__Struct Segment;
		public _Table_e__Struct Table;
		public _FpControlStatus_e__Struct FpControlStatus;
		public _XmmControlStatus_e__Struct XmmControlStatus;
	}
	[CRepr]
	public struct _Reg128_e__Struct
	{
		public uint64 Low64;
		public uint64 High64;
	}
	public uint64 Reg64;
	public uint32 Reg32;
	public uint16 Reg16;
	public uint8 Reg8;
	public _Reg128_e__Struct Reg128;
	public _X64_e__Union X64;
}

[CRepr]
public struct DOS_IMAGE_INFO
{
	public PSTR PdbName;
	public uint64 ImageBaseAddress;
	public uint32 ImageSize;
	public uint32 Timestamp;
}

[CRepr]
public struct MODULE_INFO
{
	public PSTR ProcessImageName;
	public DOS_IMAGE_INFO Image;
}

#endregion

#region Functions
public static
{
	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetCapability(WHV_CAPABILITY_CODE CapabilityCode, void* CapabilityBuffer, uint32 CapabilityBufferSizeInBytes, uint32* WrittenSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvCreatePartition(WHV_PARTITION_HANDLE* Partition);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSetupPartition(WHV_PARTITION_HANDLE Partition);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvResetPartition(WHV_PARTITION_HANDLE Partition);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvDeletePartition(WHV_PARTITION_HANDLE Partition);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetPartitionProperty(WHV_PARTITION_HANDLE Partition, WHV_PARTITION_PROPERTY_CODE PropertyCode, void* PropertyBuffer, uint32 PropertyBufferSizeInBytes, uint32* WrittenSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSetPartitionProperty(WHV_PARTITION_HANDLE Partition, WHV_PARTITION_PROPERTY_CODE PropertyCode, void* PropertyBuffer, uint32 PropertyBufferSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSuspendPartitionTime(WHV_PARTITION_HANDLE Partition);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvResumePartitionTime(WHV_PARTITION_HANDLE Partition);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvMapGpaRange(WHV_PARTITION_HANDLE Partition, void* SourceAddress, uint64 GuestAddress, uint64 SizeInBytes, WHV_MAP_GPA_RANGE_FLAGS Flags);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvMapGpaRange2(WHV_PARTITION_HANDLE Partition, HANDLE Process, void* SourceAddress, uint64 GuestAddress, uint64 SizeInBytes, WHV_MAP_GPA_RANGE_FLAGS Flags);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvUnmapGpaRange(WHV_PARTITION_HANDLE Partition, uint64 GuestAddress, uint64 SizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvTranslateGva(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, uint64 Gva, WHV_TRANSLATE_GVA_FLAGS TranslateFlags, WHV_TRANSLATE_GVA_RESULT* TranslationResult, uint64* Gpa);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvCreateVirtualProcessor(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, uint32 Flags);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvCreateVirtualProcessor2(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, WHV_VIRTUAL_PROCESSOR_PROPERTY* Properties, uint32 PropertyCount);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvDeleteVirtualProcessor(WHV_PARTITION_HANDLE Partition, uint32 VpIndex);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvRunVirtualProcessor(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, void* ExitContext, uint32 ExitContextSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvCancelRunVirtualProcessor(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, uint32 Flags);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVirtualProcessorRegisters(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, WHV_REGISTER_NAME* RegisterNames, uint32 RegisterCount, WHV_REGISTER_VALUE* RegisterValues);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSetVirtualProcessorRegisters(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, WHV_REGISTER_NAME* RegisterNames, uint32 RegisterCount, WHV_REGISTER_VALUE* RegisterValues);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVirtualProcessorInterruptControllerState(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, void* State, uint32 StateSize, uint32* WrittenSize);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSetVirtualProcessorInterruptControllerState(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, void* State, uint32 StateSize);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvRequestInterrupt(WHV_PARTITION_HANDLE Partition, WHV_INTERRUPT_CONTROL* Interrupt, uint32 InterruptControlSize);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVirtualProcessorXsaveState(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, void* Buffer, uint32 BufferSizeInBytes, uint32* BytesWritten);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSetVirtualProcessorXsaveState(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, void* Buffer, uint32 BufferSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvQueryGpaRangeDirtyBitmap(WHV_PARTITION_HANDLE Partition, uint64 GuestAddress, uint64 RangeSizeInBytes, uint64* Bitmap, uint32 BitmapSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetPartitionCounters(WHV_PARTITION_HANDLE Partition, WHV_PARTITION_COUNTER_SET CounterSet, void* Buffer, uint32 BufferSizeInBytes, uint32* BytesWritten);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVirtualProcessorCounters(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, WHV_PROCESSOR_COUNTER_SET CounterSet, void* Buffer, uint32 BufferSizeInBytes, uint32* BytesWritten);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVirtualProcessorInterruptControllerState2(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, void* State, uint32 StateSize, uint32* WrittenSize);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSetVirtualProcessorInterruptControllerState2(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, void* State, uint32 StateSize);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvRegisterPartitionDoorbellEvent(WHV_PARTITION_HANDLE Partition, WHV_DOORBELL_MATCH_DATA* MatchData, HANDLE EventHandle);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvUnregisterPartitionDoorbellEvent(WHV_PARTITION_HANDLE Partition, WHV_DOORBELL_MATCH_DATA* MatchData);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvAdviseGpaRange(WHV_PARTITION_HANDLE Partition, WHV_MEMORY_RANGE_ENTRY* GpaRanges, uint32 GpaRangesCount, WHV_ADVISE_GPA_RANGE_CODE Advice, void* AdviceBuffer, uint32 AdviceBufferSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvReadGpaRange(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, uint64 GuestAddress, WHV_ACCESS_GPA_CONTROLS Controls, void* Data, uint32 DataSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvWriteGpaRange(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, uint64 GuestAddress, WHV_ACCESS_GPA_CONTROLS Controls, void* Data, uint32 DataSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSignalVirtualProcessorSynicEvent(WHV_PARTITION_HANDLE Partition, WHV_SYNIC_EVENT_PARAMETERS SynicEvent, BOOL* NewlySignaled);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVirtualProcessorState(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, WHV_VIRTUAL_PROCESSOR_STATE_TYPE StateType, void* Buffer, uint32 BufferSizeInBytes, uint32* BytesWritten);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSetVirtualProcessorState(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, WHV_VIRTUAL_PROCESSOR_STATE_TYPE StateType, void* Buffer, uint32 BufferSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvAllocateVpciResource(Guid* ProviderId, WHV_ALLOCATE_VPCI_RESOURCE_FLAGS Flags, void* ResourceDescriptor, uint32 ResourceDescriptorSizeInBytes, HANDLE* VpciResource);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvCreateVpciDevice(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, HANDLE VpciResource, WHV_CREATE_VPCI_DEVICE_FLAGS Flags, HANDLE NotificationEventHandle);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvDeleteVpciDevice(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVpciDeviceProperty(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, WHV_VPCI_DEVICE_PROPERTY_CODE PropertyCode, void* PropertyBuffer, uint32 PropertyBufferSizeInBytes, uint32* WrittenSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVpciDeviceNotification(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, WHV_VPCI_DEVICE_NOTIFICATION* Notification, uint32 NotificationSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvMapVpciDeviceMmioRanges(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, uint32* MappingCount, WHV_VPCI_MMIO_MAPPING** Mappings);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvUnmapVpciDeviceMmioRanges(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSetVpciDevicePowerState(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, DEVICE_POWER_STATE PowerState);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvReadVpciDeviceRegister(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, WHV_VPCI_DEVICE_REGISTER* Register, void* Data);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvWriteVpciDeviceRegister(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, WHV_VPCI_DEVICE_REGISTER* Register, void* Data);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvMapVpciDeviceInterrupt(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, uint32 Index, uint32 MessageCount, WHV_VPCI_INTERRUPT_TARGET* Target, uint64* MsiAddress, uint32* MsiData);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvUnmapVpciDeviceInterrupt(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, uint32 Index);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvRetargetVpciDeviceInterrupt(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, uint64 MsiAddress, uint32 MsiData, WHV_VPCI_INTERRUPT_TARGET* Target);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvRequestVpciDeviceInterrupt(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, uint64 MsiAddress, uint32 MsiData);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVpciDeviceInterruptTarget(WHV_PARTITION_HANDLE Partition, uint64 LogicalDeviceId, uint32 Index, uint32 MultiMessageNumber, WHV_VPCI_INTERRUPT_TARGET* Target, uint32 TargetSizeInBytes, uint32* BytesWritten);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvCreateTrigger(WHV_PARTITION_HANDLE Partition, WHV_TRIGGER_PARAMETERS* Parameters, void** TriggerHandle, HANDLE* EventHandle);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvUpdateTriggerParameters(WHV_PARTITION_HANDLE Partition, WHV_TRIGGER_PARAMETERS* Parameters, void* TriggerHandle);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvDeleteTrigger(WHV_PARTITION_HANDLE Partition, void* TriggerHandle);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvCreateNotificationPort(WHV_PARTITION_HANDLE Partition, WHV_NOTIFICATION_PORT_PARAMETERS* Parameters, HANDLE EventHandle, void** PortHandle);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvSetNotificationPortProperty(WHV_PARTITION_HANDLE Partition, void* PortHandle, WHV_NOTIFICATION_PORT_PROPERTY_CODE PropertyCode, uint64 PropertyValue);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvDeleteNotificationPort(WHV_PARTITION_HANDLE Partition, void* PortHandle);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvPostVirtualProcessorSynicMessage(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, uint32 SintIndex, void* Message, uint32 MessageSizeInBytes);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetVirtualProcessorCpuidOutput(WHV_PARTITION_HANDLE Partition, uint32 VpIndex, uint32 Eax, uint32 Ecx, WHV_CPUID_OUTPUT* CpuidOutput);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvGetInterruptTargetVpSet(WHV_PARTITION_HANDLE Partition, uint64 Destination, WHV_INTERRUPT_DESTINATION_MODE DestinationMode, uint32* TargetVps, uint32 VpCount, uint32* TargetVpCount);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvStartPartitionMigration(WHV_PARTITION_HANDLE Partition, HANDLE* MigrationHandle);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvCancelPartitionMigration(WHV_PARTITION_HANDLE Partition);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvCompletePartitionMigration(WHV_PARTITION_HANDLE Partition);

	[Import("WinHvPlatform.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvAcceptPartitionMigration(HANDLE MigrationHandle, WHV_PARTITION_HANDLE* Partition);

	[Import("WinHvEmulation.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvEmulatorCreateEmulator(WHV_EMULATOR_CALLBACKS* Callbacks, void** Emulator);

	[Import("WinHvEmulation.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvEmulatorDestroyEmulator(void* Emulator);

	[Import("WinHvEmulation.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvEmulatorTryIoEmulation(void* Emulator, void* Context, WHV_VP_EXIT_CONTEXT* VpContext, WHV_X64_IO_PORT_ACCESS_CONTEXT* IoInstructionContext, WHV_EMULATOR_STATUS* EmulatorReturnStatus);

	[Import("WinHvEmulation.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WHvEmulatorTryMmioEmulation(void* Emulator, void* Context, WHV_VP_EXIT_CONTEXT* VpContext, WHV_MEMORY_ACCESS_CONTEXT* MmioInstructionContext, WHV_EMULATOR_STATUS* EmulatorReturnStatus);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvInitializeDeviceHost(HCS_SYSTEM computeSystem, void** deviceHostHandle);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvTeardownDeviceHost(void* deviceHostHandle);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvCreateDeviceInstance(void* deviceHostHandle, HDV_DEVICE_TYPE deviceType, in Guid deviceClassId, in Guid deviceInstanceId, void* deviceInterface, void* deviceContext, void** deviceHandle);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvReadGuestMemory(void* requestor, uint64 guestPhysicalAddress, uint32 byteCount, uint8* buffer);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvWriteGuestMemory(void* requestor, uint64 guestPhysicalAddress, uint32 byteCount, uint8* buffer);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvCreateGuestMemoryAperture(void* requestor, uint64 guestPhysicalAddress, uint32 byteCount, BOOL writeProtected, void** mappedAddress);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvDestroyGuestMemoryAperture(void* requestor, void* mappedAddress);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvDeliverGuestInterrupt(void* requestor, uint64 msiAddress, uint32 msiData);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvRegisterDoorbell(void* requestor, HDV_PCI_BAR_SELECTOR BarIndex, uint64 BarOffset, uint64 TriggerValue, uint64 Flags, HANDLE DoorbellEvent);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvUnregisterDoorbell(void* requestor, HDV_PCI_BAR_SELECTOR BarIndex, uint64 BarOffset, uint64 TriggerValue, uint64 Flags);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvCreateSectionBackedMmioRange(void* requestor, HDV_PCI_BAR_SELECTOR barIndex, uint64 offsetInPages, uint64 lengthInPages, HDV_MMIO_MAPPING_FLAGS MappingFlags, HANDLE sectionHandle, uint64 sectionOffsetInPages);

	[Import("vmdevicehost.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HdvDestroySectionBackedMmioRange(void* requestor, HDV_PCI_BAR_SELECTOR barIndex, uint64 offsetInPages);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LocateSavedStateFiles(PWSTR vmName, PWSTR snapshotName, PWSTR* binPath, PWSTR* vsvPath, PWSTR* vmrsPath);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadSavedStateFile(PWSTR vmrsFile, void** vmSavedStateDumpHandle);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ApplyPendingSavedStateFileReplayLog(PWSTR vmrsFile);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadSavedStateFiles(PWSTR binFile, PWSTR vsvFile, void** vmSavedStateDumpHandle);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReleaseSavedStateFiles(void* vmSavedStateDumpHandle);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetGuestEnabledVirtualTrustLevels(void* vmSavedStateDumpHandle, uint32* virtualTrustLevels);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetGuestOsInfo(void* vmSavedStateDumpHandle, uint8 virtualTrustLevel, GUEST_OS_INFO* guestOsInfo);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetVpCount(void* vmSavedStateDumpHandle, uint32* vpCount);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetArchitecture(void* vmSavedStateDumpHandle, uint32 vpId, VIRTUAL_PROCESSOR_ARCH* architecture);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ForceArchitecture(void* vmSavedStateDumpHandle, uint32 vpId, VIRTUAL_PROCESSOR_ARCH architecture);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetActiveVirtualTrustLevel(void* vmSavedStateDumpHandle, uint32 vpId, uint8* virtualTrustLevel);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetEnabledVirtualTrustLevels(void* vmSavedStateDumpHandle, uint32 vpId, uint32* virtualTrustLevels);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ForceActiveVirtualTrustLevel(void* vmSavedStateDumpHandle, uint32 vpId, uint8 virtualTrustLevel);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsActiveVirtualTrustLevelEnabled(void* vmSavedStateDumpHandle, uint32 vpId, BOOL* activeVirtualTrustLevelEnabled);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsNestedVirtualizationEnabled(void* vmSavedStateDumpHandle, BOOL* enabled);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetNestedVirtualizationMode(void* vmSavedStateDumpHandle, uint32 vpId, BOOL* enabled);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ForceNestedHostMode(void* vmSavedStateDumpHandle, uint32 vpId, BOOL hostMode, BOOL* oldMode);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InKernelSpace(void* vmSavedStateDumpHandle, uint32 vpId, BOOL* inKernelSpace);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetRegisterValue(void* vmSavedStateDumpHandle, uint32 vpId, uint32 registerId, VIRTUAL_PROCESSOR_REGISTER* registerValue);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetPagingMode(void* vmSavedStateDumpHandle, uint32 vpId, PAGING_MODE* pagingMode);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ForcePagingMode(void* vmSavedStateDumpHandle, uint32 vpId, PAGING_MODE pagingMode);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReadGuestPhysicalAddress(void* vmSavedStateDumpHandle, uint64 physicalAddress, void* buffer, uint32 bufferSize, uint32* bytesRead);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GuestVirtualAddressToPhysicalAddress(void* vmSavedStateDumpHandle, uint32 vpId, uint64 virtualAddress, uint64* physicalAddress, uint64* unmappedRegionSize);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetGuestPhysicalMemoryChunks(void* vmSavedStateDumpHandle, uint64* memoryChunkPageSize, GPA_MEMORY_CHUNK* memoryChunks, uint64* memoryChunkCount);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GuestPhysicalAddressToRawSavedMemoryOffset(void* vmSavedStateDumpHandle, uint64 physicalAddress, uint64* rawSavedMemoryOffset);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReadGuestRawSavedMemory(void* vmSavedStateDumpHandle, uint64 rawSavedMemoryOffset, void* buffer, uint32 bufferSize, uint32* bytesRead);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetGuestRawSavedMemorySize(void* vmSavedStateDumpHandle, uint64* guestRawSavedMemorySize);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetMemoryBlockCacheLimit(void* vmSavedStateDumpHandle, uint64 memoryBlockCacheLimit);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetMemoryBlockCacheLimit(void* vmSavedStateDumpHandle, uint64* memoryBlockCacheLimit);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ApplyGuestMemoryFix(void* vmSavedStateDumpHandle, uint32 vpId, uint64 virtualAddress, void* fixBuffer, uint32 fixBufferSize);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadSavedStateSymbolProvider(void* vmSavedStateDumpHandle, PWSTR userSymbols, BOOL force);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReleaseSavedStateSymbolProvider(void* vmSavedStateDumpHandle);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE GetSavedStateSymbolProviderHandle(void* vmSavedStateDumpHandle);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetSavedStateSymbolProviderDebugInfoCallback(void* vmSavedStateDumpHandle, GUEST_SYMBOLS_PROVIDER_DEBUG_INFO_CALLBACK Callback);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadSavedStateModuleSymbols(void* vmSavedStateDumpHandle, PSTR imageName, PSTR moduleName, uint64 baseAddress, uint32 sizeOfBase);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadSavedStateModuleSymbolsEx(void* vmSavedStateDumpHandle, PSTR imageName, uint32 imageTimestamp, PSTR moduleName, uint64 baseAddress, uint32 sizeOfBase);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ResolveSavedStateGlobalVariableAddress(void* vmSavedStateDumpHandle, uint32 vpId, PSTR globalName, uint64* virtualAddress, uint32* size);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReadSavedStateGlobalVariable(void* vmSavedStateDumpHandle, uint32 vpId, PSTR globalName, void* buffer, uint32 bufferSize);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetSavedStateSymbolTypeSize(void* vmSavedStateDumpHandle, uint32 vpId, PSTR typeName, uint32* size);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FindSavedStateSymbolFieldInType(void* vmSavedStateDumpHandle, uint32 vpId, PSTR typeName, PWSTR fieldName, uint32* offset, BOOL* found);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetSavedStateSymbolFieldInfo(void* vmSavedStateDumpHandle, uint32 vpId, PSTR typeName, PWSTR* typeFieldInfoMap);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScanMemoryForDosImages(void* vmSavedStateDumpHandle, uint32 vpId, uint64 startAddress, uint64 endAddress, void* callbackContext, FOUND_IMAGE_CALLBACK foundImageCallback, uint64* standaloneAddress, uint32 standaloneAddressCount);

	[Import("VmSavedStateDumpProvider.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CallStackUnwind(void* vmSavedStateDumpHandle, uint32 vpId, MODULE_INFO* imageInfo, uint32 imageInfoCount, uint32 frameCount, PWSTR* callStack);

}
#endregion
