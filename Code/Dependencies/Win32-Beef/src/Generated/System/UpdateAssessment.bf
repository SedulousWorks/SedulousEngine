using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.System.UpdateAssessment;

#region Enums

[AllowDuplicates]
public enum UpdateImpactLevel : int32
{
	UpdateImpactLevel_None = 0,
	UpdateImpactLevel_Low = 1,
	UpdateImpactLevel_Medium = 2,
	UpdateImpactLevel_High = 3,
}


[AllowDuplicates]
public enum UpdateAssessmentStatus : int32
{
	UpdateAssessmentStatus_Latest = 0,
	UpdateAssessmentStatus_NotLatestSoftRestriction = 1,
	UpdateAssessmentStatus_NotLatestHardRestriction = 2,
	UpdateAssessmentStatus_NotLatestEndOfSupport = 3,
	UpdateAssessmentStatus_NotLatestServicingTrain = 4,
	UpdateAssessmentStatus_NotLatestDeferredFeature = 5,
	UpdateAssessmentStatus_NotLatestDeferredQuality = 6,
	UpdateAssessmentStatus_NotLatestPausedFeature = 7,
	UpdateAssessmentStatus_NotLatestPausedQuality = 8,
	UpdateAssessmentStatus_NotLatestManaged = 9,
	UpdateAssessmentStatus_NotLatestUnknown = 10,
	UpdateAssessmentStatus_NotLatestTargetedVersion = 11,
}

#endregion


#region Structs
[CRepr]
public struct UpdateAssessment
{
	public UpdateAssessmentStatus status;
	public UpdateImpactLevel impact;
	public uint32 daysOutOfDate;
}

[CRepr]
public struct OSUpdateAssessment
{
	public BOOL isEndOfSupport;
	public UpdateAssessment assessmentForCurrent;
	public UpdateAssessment assessmentForUpToDate;
	public UpdateAssessmentStatus securityStatus;
	public FILETIME assessmentTime;
	public FILETIME releaseInfoTime;
	public PWSTR currentOSBuild;
	public FILETIME currentOSReleaseTime;
	public PWSTR upToDateOSBuild;
	public FILETIME upToDateOSReleaseTime;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_WaaSAssessor = .(0x098ef871, 0xfa9f, 0x46af, 0x89, 0x58, 0xc0, 0x83, 0x51, 0x5d, 0x7c, 0x9c);


}
#endregion

#region COM Types
[CRepr]struct IWaaSAssessor : IUnknown
{
	public new const Guid IID = .(0x2347bbef, 0x1a3b, 0x45a4, 0x90, 0x2d, 0x3e, 0x09, 0xc2, 0x69, 0xb4, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OSUpdateAssessment* result) GetOSUpdateAssessment;
	}


	public HRESULT GetOSUpdateAssessment(OSUpdateAssessment* result) mut => VT.[Friend]GetOSUpdateAssessment(&this, result);
}

#endregion
