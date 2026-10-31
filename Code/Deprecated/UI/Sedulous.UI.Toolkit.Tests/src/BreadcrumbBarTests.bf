using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The path bar: splitting, reading segments back, and rebuilding the path from them.
class BreadcrumbBarTests
{
	[Test]
	public static void SetPathSplitsTrimsAndDropsEmptySegments()
	{
		let bar = new BreadcrumbBar();
		defer bar.ReleaseRef();

		Test.Assert(bar.SegmentCount == 0);

		// A leading and a trailing separator, and spaces around one piece.
		bar.SetPath("/home/ robert /Dev/");
		Test.Assert(bar.SegmentCount == 3);
		Test.Assert(bar.GetSegment(0) == "home");
		Test.Assert(bar.GetSegment(1) == "robert");
		Test.Assert(bar.GetSegment(2) == "Dev");
	}

	[Test]
	public static void AnOutOfRangeSegmentIsEmpty()
	{
		let bar = new BreadcrumbBar();
		defer bar.ReleaseRef();

		bar.SetPath("Project/Assets/Textures");
		Test.Assert(bar.GetSegment(99).IsEmpty);
		Test.Assert(bar.GetSegment(-1).IsEmpty);
	}

	[Test]
	public static void SetSegmentsReplacesThePath()
	{
		let bar = new BreadcrumbBar();
		defer bar.ReleaseRef();

		bar.SetPath("Project/Assets/Textures");

		StringView[3] segments = .("Home", "Documents", "File.txt");
		bar.SetSegments(segments);

		Test.Assert(bar.SegmentCount == 3);
		Test.Assert(bar.GetSegment(0) == "Home");
		Test.Assert(bar.GetSegment(2) == "File.txt");
	}

	/// What a click handler needs: the path down to what was clicked, which is the whole reason
	/// the segments are kept rather than only drawn.
	[Test]
	public static void GetPathUpToRebuildsThePrefix()
	{
		let bar = new BreadcrumbBar();
		defer bar.ReleaseRef();

		bar.SetPath("A/B/C/D");

		let path = scope String();
		bar.GetPathUpTo(1, path);
		Test.Assert(path == "A/B");

		let full = scope String();
		bar.GetPathUpTo(99, full);
		Test.Assert(full == "A/B/C/D", "past the end stops at the last segment");
	}
}
