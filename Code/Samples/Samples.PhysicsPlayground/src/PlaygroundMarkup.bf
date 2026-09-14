using System;

namespace Samples.PhysicsPlayground;

/// The three documents this sample instantiates, as markup.
///
/// Runtime documents rather than cooked assets, because what is being shown is the UI TIERS
/// living in a physics scene; where the markup came from is the content pipeline's business
/// and is proved elsewhere.
static class PlaygroundMarkup
{
	/// The screen tier. Its button exists to prove CONSUMPTION: clicking it must not also
	/// shove a crate behind it. Explicit sizes, because an unsized child of a root Flex
	/// stretches into a bar.
	public const String cHud = """
		<Flex direction="vertical" align="start" padding="12" spacing="8">
		  <Panel padding="12" width="220"
		         style="background: rounded-rect(rgb(28, 32, 40), radius=8);">
		    <Flex direction="vertical" spacing="8">
		      <Label id="hud-title" text="PhysicsPlayground" font-size="18"/>
		      <Button id="hud-btn" text="Clicks: 0" width="180" height="36"/>
		    </Flex>
		  </Panel>
		</Flex>
		""";

	/// The world tier: a clickable counter standing ON A SURFACE in the arena.
	public const String cKiosk = """
		<Panel padding="14" style="background: rounded-rect(rgb(28, 32, 40), radius=10);">
		  <Flex direction="vertical" spacing="10">
		    <Label text="KIOSK" font-size="22"/>
		    <Button id="kiosk-btn" text="Taps: 0" width="260" height="56"/>
		  </Flex>
		</Panel>
		""";

	/// The billboard tier: a nameplate riding the character.
	public const String cNameplate = """
		<Panel padding="4" style="background: rounded-rect(rgb(20, 24, 30), radius=4);">
		  <Label text="Hero" font-size="13"/>
		</Panel>
		""";
}
