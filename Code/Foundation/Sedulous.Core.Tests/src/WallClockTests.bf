using System;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

/// The wall clock is in Unix seconds and agrees with a file's modified time; CivilTimeOf reads a
/// time as a calendar date and a clock; the local offset is one a zone can have.
class WallClockTests
{
	private const String kScratch = "scratch_wall_clock";

	[Test]
	public static void TheWallClockIsInUnixSecondsAndAgreesWithAFilesModifiedTime()
	{
		let now = GetUnixTime();
		Test.Assert(now > 1767225600, "after 2026-01-01, when this was written");
		Test.Assert(now < 4102444800, "before 2100: seconds, not milliseconds");

		// A file written now has a modified time within a few seconds of the clock.
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		defer RemoveDirectoryRecursive(kScratch);
		let path = PathJoin(kScratch, "now.bin", .. scope String());
		uint8[1] one = .(7);
		Test.Assert(WriteFile(path, .(&one[0], 1)) case .Ok);
		Test.Assert(FileStat(path, ?, let modifiedTicks));
		let modified = UnixTimeOfTicks(modifiedTicks);
		Test.Assert(modified >= now - 5);
		Test.Assert(modified <= GetUnixTime() + 5);

		// Ticks before the epoch round down, as seconds do.
		Test.Assert(UnixTimeOfTicks(cUnixEpochTicks) == 0);
		Test.Assert(UnixTimeOfTicks(cUnixEpochTicks - 1) == -1);
	}

	[Test]
	public static void CivilTimeOfReadsAUnixTimeAsACalendarDateAndAClock()
	{
		let epoch = CivilTimeOf(0);
		Test.Assert((epoch.Year == 1970) && (epoch.Month == 1) && (epoch.Day == 1));
		let leap = CivilTimeOf(951782400 + 3723); // 2000-02-29 01:02:03 UTC
		Test.Assert((leap.Year == 2000) && (leap.Month == 2) && (leap.Day == 29));
		Test.Assert((leap.Hour == 1) && (leap.Minute == 2) && (leap.Second == 3));
		let before = CivilTimeOf(-1); // 1969-12-31 23:59:59
		Test.Assert((before.Year == 1969) && (before.Month == 12) && (before.Day == 31));
		Test.Assert(before.Hour == 23);
		Test.Assert(CivilTimeOf(1793491200).Day == 1); // 2026-11-01

		// The local offset is a whole number of minutes, within the zones there are.
		let offset = GetLocalTimeOffset(GetUnixTime());
		Test.Assert(offset % 60 == 0);
		Test.Assert(offset >= -12 * 3600);
		Test.Assert(offset <= 14 * 3600);
	}
}
