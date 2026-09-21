using System;
using Sedulous.Core.Logging;

namespace Sedulous.Core.Tests;

/// Level filtering, formatting and formatter ownership. The logger is constructed by the
/// test rather than reached through the global, which is the point of dropping the
/// global from the contract.
class BaseLoggerTests
{
	[Test]
	public static void DeliversAtOrAboveTheMinimumLevel()
	{
		let capture = scope CapturingLogger(.Information);
		// The level-named methods are an extension on ILogger, so they resolve when the
		// logger is held as the interface, which is how it is meant to be passed.
		ILogger log = capture;

		log.LogInformation("loaded {} meshes", 12);
		Test.Assert(capture.Count == 1);
		Test.Assert(capture.LastLevel == .Information);
		Test.Assert(capture.LastLine.Contains("loaded 12 meshes"));

		// Below the minimum is dropped.
		log.LogDebug("verbose {}", 1);
		Test.Assert(capture.Count == 1);

		// Above it is delivered.
		log.LogError("device {} lost", 3);
		Test.Assert(capture.Count == 2);
		Test.Assert(capture.LastLevel == .Error);
		Test.Assert(capture.LastLine.Contains("device 3 lost"));
	}

	[Test]
	public static void EveryLevelHasAFrontendMethod()
	{
		let capture = scope CapturingLogger(.Trace);
		ILogger log = capture;

		log.LogTrace("t");
		log.LogDebug("d");
		log.LogInformation("i");
		log.LogWarning("w");
		log.LogError("e");
		log.LogCritical("c");

		Test.Assert(capture.Count == 6);
		Test.Assert(capture.Levels[0] == .Trace);
		Test.Assert(capture.Levels[1] == .Debug);
		Test.Assert(capture.Levels[2] == .Information);
		Test.Assert(capture.Levels[3] == .Warning);
		Test.Assert(capture.Levels[4] == .Error);
		Test.Assert(capture.Levels[5] == .Critical);
	}

	/// None filters everything, including Critical, which is the whole reason it sits
	/// above the real levels rather than below them.
	[Test]
	public static void NoneSilencesEverything()
	{
		let capture = scope CapturingLogger(.None);
		ILogger log = capture;
		log.LogTrace("t");
		log.LogCritical("c");
		Test.Assert(capture.Count == 0);

		// And a logger cannot be asked to emit at None itself.
		log.MinimumLogLevel = .Trace;
		log.Log(.None, "sentinel");
		Test.Assert(capture.Count == 0);
	}

	[Test]
	public static void TheLevelCanChangeAfterConstruction()
	{
		let capture = scope CapturingLogger(.Error);
		ILogger log = capture;
		log.LogInformation("dropped");
		Test.Assert(capture.Count == 0);

		log.MinimumLogLevel = .Trace;
		log.LogInformation("kept");
		Test.Assert(capture.Count == 1);
	}

	/// The property that makes this design work: a filtered-out call never formats its
	/// message. The probe reaches Log either way, but only a message that is actually
	/// built asks it to render.
	[Test]
	public static void AFilteredCallNeverFormatsItsMessage()
	{
		let capture = scope CapturingLogger(.Warning);
		ILogger log = capture;

		FormatProbe.Reset();
		log.LogDebug("value is {}", scope FormatProbe());
		Test.Assert(capture.Count == 0);
		Test.Assert(FormatProbe.sRenderCount == 0);

		// The same call at an enabled level does render it.
		FormatProbe.Reset();
		log.LogError("value is {}", scope FormatProbe());
		Test.Assert(capture.Count == 1);
		Test.Assert(FormatProbe.sRenderCount == 1);
		Test.Assert(capture.LastLine.Contains("value is probe"));
	}

	[Test]
	public static void IsEnabledMatchesWhatGetsDelivered()
	{
		let log = scope CapturingLogger(.Warning);

		Test.Assert(!log.IsEnabled(.Trace));
		Test.Assert(!log.IsEnabled(.Information));
		Test.Assert(log.IsEnabled(.Warning));
		Test.Assert(log.IsEnabled(.Critical));
		Test.Assert(!log.IsEnabled(.None));
	}

	/// A logger given no formatter makes and owns a default one. Passing one in leaves
	/// ownership with the caller unless they say otherwise, which is the facility rather
	/// than policy part: Core never decides who deletes.
	[Test]
	public static void FormatterOwnershipFollowsTheFlag()
	{
		// Default: the logger built one and will delete it.
		let owning = scope CapturingLogger(.Trace);
		Test.Assert(owning.Formatter != null);

		// Borrowed: the test owns this one, and the logger must not delete it.
		let borrowed = scope DefaultLogFormatter();
		let user = scope CapturingLogger(.Trace, "Test", borrowed, false);
		Test.Assert(user.Formatter == borrowed);

		// Replacing restores a default the logger owns.
		user.SetFormatter(null);
		Test.Assert(user.Formatter != null);
		Test.Assert(user.Formatter != borrowed);
	}

	[Test]
	public static void NameIsCarriedOntoTheLine()
	{
		let capture = scope CapturingLogger(.Trace, "Renderer");
		ILogger log = capture;
		Test.Assert(log.Name == "Renderer");
		log.LogInformation("hello");
		Test.Assert(capture.LastLine.Contains("Renderer"));
	}
}
