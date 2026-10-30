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
	/// shove a crate behind it. Top right: the ImGui panel is top left. Styled through the
	/// markup's inline CSS, as WebScene's HUD is.
	public const String cHud = """
		<Panel flex-direction="column" align-items="end" padding="12">
		  <Panel flex-direction="column" gap="8" padding="12" width="220"
		         background-color="rgb(28, 32, 40)" border-radius="8">
		    <Label id="hud-title" text="PhysicsPlayground" font-size="18"/>
		    <Button id="hud-btn" text="Clicks: 0" width="180" height="36"/>
		  </Panel>
		</Panel>
		""";

	/// The world tier: a clickable counter standing ON A SURFACE in the arena.
	public const String cKiosk = """
		<Panel flex-direction="column" gap="10" padding="14"
		       background-color="rgb(28, 32, 40)" border-radius="10">
		  <Label text="KIOSK" font-size="22"/>
		  <Button id="kiosk-btn" text="Taps: 0" width="260" height="56"/>
		</Panel>
		""";

	/// The billboard tier: a nameplate riding the character.
	public const String cNameplate = """
		<Panel padding="4" background-color="rgb(20, 24, 30)" border-radius="4">
		  <Label text="Hero" font-size="13"/>
		</Panel>
		""";
}
