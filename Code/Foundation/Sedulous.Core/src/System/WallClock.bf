using System;

namespace Sedulous.Core;

/// A date and a time of day on the proleptic Gregorian calendar.
struct CivilTime
{
	public int32 Year = 1970;
	/// 1 to 12.
	public uint32 Month = 1;
	/// 1 to 31.
	public uint32 Day = 1;
	public uint32 Hour = 0;
	public uint32 Minute = 0;
	public uint32 Second = 0;
}

/// The wall clock, the user's time zone, and calendar dates: when something happened, as a user
/// reads it. Not for measuring durations: the wall clock jumps when the system's clock is set.
///
/// Not corlib's TimeZoneInfo.Local, which off Windows is UTC (its tz file reader is a stub), so
/// the offset comes from the platform: localtime_r on Linux, the zone's rules on Windows, the
/// page's Date in a browser.
static
{
	/// DateTime's ticks (100 ns since 0001-01-01) at 1970-01-01 UTC: 719,162 days.
	public const int64 cUnixEpochTicks = 719162L * TimeSpan.TicksPerDay;

	/// The wall clock: seconds since 1970-01-01 UTC.
	public static int64 GetUnixTime() => UnixTimeOfTicks(DateTime.UtcNow.Ticks);

	/// A UTC time in DateTime's ticks (FileStat's modified time) as Unix seconds, rounded down.
	public static int64 UnixTimeOfTicks(int64 utcTicks)
	{
		let since = utcTicks - cUnixEpochTicks;
		var seconds = since / TimeSpan.TicksPerSecond;
		if ((since % TimeSpan.TicksPerSecond) < 0)
			seconds--;
		return seconds;
	}

	/// Seconds the user's time zone is ahead of UTC at `unixTime`, summer time included: add it
	/// to a Unix time to read the local date and clock with CivilTimeOf. 0 when the platform
	/// cannot say.
	public static int64 GetLocalTimeOffset(int64 unixTime)
	{
#if BF_PLATFORM_WINDOWS
		// Through SYSTEMTIME so the zone's rule for that date (summer time or not) applies.
		let ft = (uint64)(unixTime + cWindowsToUnixSeconds) * 10000000UL;
		WallClockFileTime utcFile = .() { mLow = (uint32)(ft & 0xFFFFFFFFUL), mHigh = (uint32)(ft >> 32) };
		Windows.SystemTime utc = default;
		Windows.SystemTime local = default;
		WallClockFileTime localFile = default;
		if (!FileTimeToSystemTime(&utcFile, &utc) || !SystemTimeToTzSpecificLocalTime(null, &utc, &local) ||
			!SystemTimeToFileTime(&local, &localFile))
			return 0;
		let lt = ((uint64)localFile.mHigh << 32) | localFile.mLow;
		return ((int64)lt - (int64)ft) / 10000000L;
#elif BF_PLATFORM_WASM
		// The page's Date knows the user's zone; getTimezoneOffset is minutes behind UTC.
		let script = scope String()..AppendF("-new Date({}).getTimezoneOffset() * 60", unixTime * 1000);
		return emscripten_run_script_int(script.CStr());
#else
		int64 seconds = unixTime;
		WallClockTm local = default;
		if (localtime_r(&seconds, &local) == null)
			return 0;
		return local.mGmtOffset;
#endif
	}

	/// The calendar date and time `seconds` after 1970-01-01 00:00 (Howard Hinnant's
	/// civil_from_days): UTC for a Unix time, local time for one plus GetLocalTimeOffset.
	public static CivilTime CivilTimeOf(int64 seconds)
	{
		var days = seconds / 86400;
		var rest = seconds % 86400;
		if (rest < 0)
		{
			rest += 86400;
			days--;
		}
		days += 719468;
		let era = ((days >= 0) ? days : (days - 146096)) / 146097;
		let doe = days - era * 146097;
		let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
		let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
		let mp = (5 * doy + 2) / 153;
		CivilTime civil = .();
		civil.Day = (uint32)(doy - (153 * mp + 2) / 5 + 1);
		civil.Month = (uint32)((mp < 10) ? (mp + 3) : (mp - 9));
		civil.Year = (int32)(yoe + era * 400 + ((civil.Month <= 2) ? 1 : 0));
		civil.Hour = (uint32)(rest / 3600);
		civil.Minute = (uint32)(rest % 3600 / 60);
		civil.Second = (uint32)(rest % 60);
		return civil;
	}

#if BF_PLATFORM_WINDOWS
	/// Seconds from 1601-01-01 (a FILETIME's zero) to 1970-01-01.
	private const int64 cWindowsToUnixSeconds = 11644473600L;

	[Import("kernel32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern Windows.IntBool FileTimeToSystemTime(WallClockFileTime* fileTime, Windows.SystemTime* systemTime);
	[Import("kernel32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern Windows.IntBool SystemTimeToTzSpecificLocalTime(void* timeZone, Windows.SystemTime* universal, Windows.SystemTime* local);
	[Import("kernel32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern Windows.IntBool SystemTimeToFileTime(Windows.SystemTime* systemTime, WallClockFileTime* fileTime);
#elif BF_PLATFORM_WASM
	[CLink]
	private static extern int32 emscripten_run_script_int(char8* script);
#else
	/// time_t is 64 bits on every 64-bit Linux.
	[CLink]
	private static extern WallClockTm* localtime_r(int64* time, WallClockTm* result);
#endif
}

#if BF_PLATFORM_WINDOWS
/// A FILETIME: 100 ns since 1601-01-01, in two halves.
[CRepr]
struct WallClockFileTime
{
	public uint32 mLow;
	public uint32 mHigh;
}
#elif !BF_PLATFORM_WASM
/// glibc's struct tm, the fields localtime_r fills; tm_gmtoff is a long.
[CRepr]
struct WallClockTm
{
	public int32 mSecond;
	public int32 mMinute;
	public int32 mHour;
	public int32 mMonthDay;
	public int32 mMonth;
	public int32 mYear;
	public int32 mWeekDay;
	public int32 mYearDay;
	public int32 mIsDst;
	public int mGmtOffset;
	public char8* mZone;
}
#endif
