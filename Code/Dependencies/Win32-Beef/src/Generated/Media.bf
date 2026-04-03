using Win32.Media.Multimedia;
using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.Media;

#region Constants
public static
{
	public const uint32 TIMERR_NOERROR = 0;
	public const uint32 TIMERR_NOCANDO = 97;
	public const uint32 TIMERR_STRUCT = 129;
	public const uint32 MAXPNAMELEN = 32;
	public const uint32 MAXERRORLENGTH = 256;
	public const uint32 MM_MICROSOFT = 1;
	public const uint32 MM_MIDI_MAPPER = 1;
	public const uint32 MM_WAVE_MAPPER = 2;
	public const uint32 MM_SNDBLST_MIDIOUT = 3;
	public const uint32 MM_SNDBLST_MIDIIN = 4;
	public const uint32 MM_SNDBLST_SYNTH = 5;
	public const uint32 MM_SNDBLST_WAVEOUT = 6;
	public const uint32 MM_SNDBLST_WAVEIN = 7;
	public const uint32 MM_ADLIB = 9;
	public const uint32 MM_MPU401_MIDIOUT = 10;
	public const uint32 MM_MPU401_MIDIIN = 11;
	public const uint32 MM_PC_JOYSTICK = 12;
	public const uint32 TIME_MS = 1;
	public const uint32 TIME_SAMPLES = 2;
	public const uint32 TIME_BYTES = 4;
	public const uint32 TIME_SMPTE = 8;
	public const uint32 TIME_MIDI = 16;
	public const uint32 TIME_TICKS = 32;
	public const uint32 MM_JOY1MOVE = 928;
	public const uint32 MM_JOY2MOVE = 929;
	public const uint32 MM_JOY1ZMOVE = 930;
	public const uint32 MM_JOY2ZMOVE = 931;
	public const uint32 MM_JOY1BUTTONDOWN = 949;
	public const uint32 MM_JOY2BUTTONDOWN = 950;
	public const uint32 MM_JOY1BUTTONUP = 951;
	public const uint32 MM_JOY2BUTTONUP = 952;
	public const uint32 MM_MCINOTIFY = 953;
	public const uint32 MM_WOM_OPEN = 955;
	public const uint32 MM_WOM_CLOSE = 956;
	public const uint32 MM_WOM_DONE = 957;
	public const uint32 MM_WIM_OPEN = 958;
	public const uint32 MM_WIM_CLOSE = 959;
	public const uint32 MM_WIM_DATA = 960;
	public const uint32 MM_MIM_OPEN = 961;
	public const uint32 MM_MIM_CLOSE = 962;
	public const uint32 MM_MIM_DATA = 963;
	public const uint32 MM_MIM_LONGDATA = 964;
	public const uint32 MM_MIM_ERROR = 965;
	public const uint32 MM_MIM_LONGERROR = 966;
	public const uint32 MM_MOM_OPEN = 967;
	public const uint32 MM_MOM_CLOSE = 968;
	public const uint32 MM_MOM_DONE = 969;
	public const uint32 MM_DRVM_OPEN = 976;
	public const uint32 MM_DRVM_CLOSE = 977;
	public const uint32 MM_DRVM_DATA = 978;
	public const uint32 MM_DRVM_ERROR = 979;
	public const uint32 MM_STREAM_OPEN = 980;
	public const uint32 MM_STREAM_CLOSE = 981;
	public const uint32 MM_STREAM_DONE = 982;
	public const uint32 MM_STREAM_ERROR = 983;
	public const uint32 MM_MOM_POSITIONCB = 970;
	public const uint32 MM_MCISIGNAL = 971;
	public const uint32 MM_MIM_MOREDATA = 972;
	public const uint32 MM_MIXM_LINE_CHANGE = 976;
	public const uint32 MM_MIXM_CONTROL_CHANGE = 977;
	public const uint32 MMSYSERR_BASE = 0;
	public const uint32 WAVERR_BASE = 32;
	public const uint32 MIDIERR_BASE = 64;
	public const uint32 TIMERR_BASE = 96;
	public const uint32 JOYERR_BASE = 160;
	public const uint32 MCIERR_BASE = 256;
	public const uint32 MIXERR_BASE = 1024;
	public const uint32 MCI_STRING_OFFSET = 512;
	public const uint32 MCI_VD_OFFSET = 1024;
	public const uint32 MCI_CD_OFFSET = 1088;
	public const uint32 MCI_WAVE_OFFSET = 1152;
	public const uint32 MCI_SEQ_OFFSET = 1216;
	public const uint32 MMSYSERR_NOERROR = 0;
	public const uint32 MMSYSERR_ERROR = 1;
	public const uint32 MMSYSERR_BADDEVICEID = 2;
	public const uint32 MMSYSERR_NOTENABLED = 3;
	public const uint32 MMSYSERR_ALLOCATED = 4;
	public const uint32 MMSYSERR_INVALHANDLE = 5;
	public const uint32 MMSYSERR_NODRIVER = 6;
	public const uint32 MMSYSERR_NOMEM = 7;
	public const uint32 MMSYSERR_NOTSUPPORTED = 8;
	public const uint32 MMSYSERR_BADERRNUM = 9;
	public const uint32 MMSYSERR_INVALFLAG = 10;
	public const uint32 MMSYSERR_INVALPARAM = 11;
	public const uint32 MMSYSERR_HANDLEBUSY = 12;
	public const uint32 MMSYSERR_INVALIDALIAS = 13;
	public const uint32 MMSYSERR_BADDB = 14;
	public const uint32 MMSYSERR_KEYNOTFOUND = 15;
	public const uint32 MMSYSERR_READERROR = 16;
	public const uint32 MMSYSERR_WRITEERROR = 17;
	public const uint32 MMSYSERR_DELETEERROR = 18;
	public const uint32 MMSYSERR_VALNOTFOUND = 19;
	public const uint32 MMSYSERR_NODRIVERCB = 20;
	public const uint32 MMSYSERR_MOREDATA = 21;
	public const uint32 MMSYSERR_LASTERROR = 21;
	public const uint32 TIME_ONESHOT = 0;
	public const uint32 TIME_PERIODIC = 1;
	public const uint32 TIME_CALLBACK_FUNCTION = 0;
	public const uint32 TIME_CALLBACK_EVENT_SET = 16;
	public const uint32 TIME_CALLBACK_EVENT_PULSE = 32;
	public const uint32 TIME_KILL_SYNCHRONOUS = 256;
}
#endregion

#region TypeDefs
typealias HTASK = int;

#endregion


#region Enums

[AllowDuplicates]
public enum TIMECODE_SAMPLE_FLAGS : uint32
{
	ED_DEVCAP_TIMECODE_READ = 4121,
	ED_DEVCAP_ATN_READ = 5047,
	ED_DEVCAP_RTC_READ = 5050,
}

#endregion

#region Function Pointers
public function void LPDRVCALLBACK(HDRVR hdrvr, uint32 uMsg, uint dwUser, uint dw1, uint dw2);

public function void LPTIMECALLBACK(uint32 uTimerID, uint32 uMsg, uint dwUser, uint dw1, uint dw2);

#endregion

#region Structs
[CRepr, Packed(1)]
public struct MMTIME
{
	[CRepr, Union, Packed(1)]
	public struct _u_e__Union
	{
		[CRepr]
		public struct _smpte_e__Struct
		{
			public uint8 hour;
			public uint8 min;
			public uint8 sec;
			public uint8 frame;
			public uint8 fps;
			public uint8 dummy;
			public uint8[2] pad;
		}
		[CRepr, Packed(1)]
		public struct _midi_e__Struct
		{
			public uint32 songptrpos;
		}
		public uint32 ms;
		public uint32 sample;
		public uint32 cb;
		public uint32 ticks;
		public _smpte_e__Struct smpte;
		public _midi_e__Struct midi;
	}
	public uint32 wType;
	public _u_e__Union u;
}

[CRepr]
public struct TIMECAPS
{
	public uint32 wPeriodMin;
	public uint32 wPeriodMax;
}

[CRepr, Union]
public struct TIMECODE
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint16 wFrameRate;
		public uint16 wFrameFract;
		public uint32 dwFrames;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint64 qw;
}

[CRepr]
public struct TIMECODE_SAMPLE
{
	public int64 qwTick;
	public TIMECODE timecode;
	public uint32 dwUser;
	public TIMECODE_SAMPLE_FLAGS dwFlags;
}

#endregion

#region COM Types
[CRepr]struct IReferenceClock : IUnknown
{
	public new const Guid IID = .(0x56a86897, 0x0ad4, 0x11ce, 0xb0, 0x3a, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pTime) GetTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 baseTime, int64 streamTime, HANDLE hEvent, uint* pdwAdviseCookie) AdviseTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 startTime, int64 periodTime, HANDLE hSemaphore, uint* pdwAdviseCookie) AdvisePeriodic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint dwAdviseCookie) Unadvise;
	}


	public HRESULT GetTime(int64* pTime) mut => VT.[Friend]GetTime(&this, pTime);

	public HRESULT AdviseTime(int64 baseTime, int64 streamTime, HANDLE hEvent, uint* pdwAdviseCookie) mut => VT.[Friend]AdviseTime(&this, baseTime, streamTime, hEvent, pdwAdviseCookie);

	public HRESULT AdvisePeriodic(int64 startTime, int64 periodTime, HANDLE hSemaphore, uint* pdwAdviseCookie) mut => VT.[Friend]AdvisePeriodic(&this, startTime, periodTime, hSemaphore, pdwAdviseCookie);

	public HRESULT Unadvise(uint dwAdviseCookie) mut => VT.[Friend]Unadvise(&this, dwAdviseCookie);
}

[CRepr]struct IReferenceClockTimerControl : IUnknown
{
	public new const Guid IID = .(0xebec459c, 0x2eca, 0x4d42, 0xa8, 0xaf, 0x30, 0xdf, 0x55, 0x76, 0x14, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 timerResolution) SetDefaultTimerResolution;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pTimerResolution) GetDefaultTimerResolution;
	}


	public HRESULT SetDefaultTimerResolution(int64 timerResolution) mut => VT.[Friend]SetDefaultTimerResolution(&this, timerResolution);

	public HRESULT GetDefaultTimerResolution(int64* pTimerResolution) mut => VT.[Friend]GetDefaultTimerResolution(&this, pTimerResolution);
}

[CRepr]struct IReferenceClock2 : IReferenceClock
{
	public new const Guid IID = .(0x36b73885, 0xc2c8, 0x11cf, 0x8b, 0x46, 0x00, 0x80, 0x5f, 0x6c, 0xef, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IReferenceClock.VTable
	{
	}

}

#endregion

#region Functions
public static
{
	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 timeGetSystemTime(MMTIME* pmmt, uint32 cbmmt);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 timeGetTime();

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 timeGetDevCaps(TIMECAPS* ptc, uint32 cbtc);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 timeBeginPeriod(uint32 uPeriod);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 timeEndPeriod(uint32 uPeriod);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 timeSetEvent(uint32 uDelay, uint32 uResolution, LPTIMECALLBACK fptc, uint dwUser, uint32 fuEvent);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 timeKillEvent(uint32 uTimerID);

}
#endregion
