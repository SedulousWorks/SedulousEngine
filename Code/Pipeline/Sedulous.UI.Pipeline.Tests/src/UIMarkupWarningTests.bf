using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Gamekit;
using Sedulous.UI.Pipeline;

namespace Sedulous.UI.Pipeline.Tests;

/// What the loader says about markup it accepted but did not fully understand, which is what
/// the cook turns into warnings.
class UIMarkupWarningTests
{
	[Test]
	public static void SilentDropsSurfaceAsWarnings()
	{
		MarkupLoader.Initialize();
		let warnings = scope List<String>();
		defer { ClearAndDeleteItems!(warnings); }

		let tree = MarkupLoader.LoadFromString(
			"""
			<Flex direction="vertical">
			  <Label fontSize="20" text="typo"/>
			  <NotARealControl/>
			  <Button id="ok" text="fine" height="40"/>
			</Flex>
			""", null, warnings);

		// The tree still BUILDS: a typo'd attribute and an unknown child are dropped, not fatal.
		// Silent is the problem, which is what the warnings answer.
		Test.Assert(tree != null);
		Test.Assert(warnings.Count == 2);
		Test.Assert(warnings[0].StartsWith("unknown attribute 'fontSize'"));
		Test.Assert(warnings[1].StartsWith("unknown element <NotARealControl>"));
		tree.ReleaseRef();

		// And a clean document warns about nothing.
		ClearAndDeleteItems!(warnings);
		let clean = MarkupLoader.LoadFromString(UIStarterContent.cDocument, null, warnings);
		Test.Assert(clean != null);
		Test.Assert(warnings.IsEmpty);
		clean.ReleaseRef();
	}

	[Test]
	public static void AScreenChildKeepsItsIdentifierAndIsFindable()
	{
		// The repro: a screen root with nested identified labels. A facade searching the screen
		// root recursively needs the nested label to carry its markup identifier as its name,
		// and the bug this guards is that search coming back empty on a live display.
		MarkupLoader.Initialize();
		GamekitMarkup.Register();

		let tree = MarkupLoader.LoadFromString(
			"""
			<screen mode="overlay">
			  <Panel><Flex><Label id="hud-timer" text="90"/></Flex></Panel>
			</screen>
			""");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();

		// The root IS the gamekit screen, used directly rather than wrapped.
		Test.Assert((tree as UIScreen) != null);
		let group = tree as ViewGroup;
		Test.Assert(group != null);
		Test.Assert(group.FindByName("hud-timer") != null);
		Test.Assert(group.FindByName<Label>("hud-timer") != null);
	}
}
