using System;
using Sedulous.Input;
using Sedulous.Engine.Input;

namespace Sedulous.Engine.Input.Tests;

/// The runtime hookup around the action runtime: which source is active, and the scene the
/// active source speaks for.
class InputSubsystemTests
{
	/// The binding rides the override rather than being set on its own, so a source and the
	/// scene it represents can never disagree.
	[Test]
	public static void ThePerSurfaceSceneBindingRidesTheSourceOverride()
	{
		let input = scope InputSubsystem(null);
		Test.Assert(input.BoundSceneKey == null);
		Test.Assert(input.UnboundScenePolicy == .AllScenes, "the player's default");

		let devices = scope StubSource();
		int sceneStandIn = 0; // any stable address serves as a key
		input.SetSourceProvider(devices, &sceneStandIn);
		Test.Assert(input.BoundSceneKey == &sceneStandIn);
		Test.Assert(input.ActiveSource === devices);

		// Re-setting without a scene UN-binds: the tab stops playing, its provider stays.
		input.SetSourceProvider(devices, null);
		Test.Assert(input.BoundSceneKey == null);

		// Clearing the provider always clears the binding, since the shell source is
		// un-bound by definition.
		input.SetSourceProvider(devices, &sceneStandIn);
		input.SetSourceProvider(null, &sceneStandIn);
		Test.Assert(input.BoundSceneKey == null);

		input.UnboundScenePolicy = .ScreenTierOnly;
		Test.Assert(input.UnboundScenePolicy == .ScreenTierOnly);
	}

	/// A closing tab clears its own source before it is destroyed, and must not disturb a
	/// different one that is still open.
	[Test]
	public static void ClearSourceProviderIfDropsOnlyItsOwnDanglingOverride()
	{
		let input = scope InputSubsystem(null);
		let tabA = scope StubSource();
		let tabB = scope StubSource();
		int keyA = 0;

		input.SetSourceProvider(tabA, &keyA);
		Test.Assert(input.ActiveSource === tabA);

		// A NON active tab closing leaves the active override alone.
		input.ClearSourceProviderIf(tabB);
		Test.Assert(input.ActiveSource === tabA);
		Test.Assert(input.BoundSceneKey == &keyA);

		// The ACTIVE tab closing drops the override and its binding, and the active source
		// falls back to the always valid shell one, so the next pump cannot dangle.
		input.ClearSourceProviderIf(tabA);
		Test.Assert(input.ActiveSource !== tabA);
		Test.Assert(input.BoundSceneKey == null);

		// Idempotent once cleared.
		input.ClearSourceProviderIf(tabA);
		Test.Assert(input.ActiveSource !== tabA);
	}
}
