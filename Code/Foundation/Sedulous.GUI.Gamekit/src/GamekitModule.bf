using System;

namespace Sedulous.GUI;

// A game's screens: the screen stack and button prompts, with the core's leaving, back command,
// input kind and data tweens under it. Sedulous.UI's counterpart: Sedulous.UI.Gamekit.

static
{
	private static bool sGamekitElementsRegistered = false;

	/// Registers the gamekit's element types (Screens, Screen, Prompt), once: a host calls it at
	/// start-up beside RegisterGuiElements, so markup and scripts can make them.
	public static void RegisterGamekitElements()
	{
		if (sGamekitElementsRegistered)
			return;
		sGamekitElementsRegistered = true;
		ElementTypes.Register(ScreenStack.StaticGuiType);
		ElementTypes.Register(Screen.StaticGuiType);
		ElementTypes.Register(Prompt.StaticGuiType);
	}
}
