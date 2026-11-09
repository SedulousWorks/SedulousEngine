using System;
using Sedulous.Run;
using Sedulous.GUI;

namespace Masquerade;

/// The run GUI as the game's code reaches it: the screen stack, and an element by id. The HUD is
/// the game's (MasqueradeGame pushes it before a round's map loads), and its elements are looked up
/// each time, since a new round's HUD is a new tree.
static class Hud
{
	/// The run GUI's root; null in a run without a GUI, or outside a run.
	public static Node Root(IRun run)
	{
		let gui = RunServices.Get<GuiFacade>(run);
		return (gui != null) ? gui.Root() : null;
	}

	/// The run GUI's screen stack; null without one.
	public static ScreenStack Screens(IRun run)
	{
		let root = Root(run);
		return (root != null) ? (root.FindElement("screens") as ScreenStack) : null;
	}

	/// The element `id` anywhere under the root, or null (the HUD is not up).
	public static Node Find(IRun run, StringView id)
	{
		let root = Root(run);
		return (root != null) ? root.FindElement(id) : null;
	}

	/// The element `id`, the top screen first: a screen just cleared or popped away is still in
	/// the tree while its exit plays, with the same ids, and would be found first.
	public static Node FindOnTop(IRun run, StringView id)
	{
		let root = Root(run);
		if (root == null)
			return null;
		let stack = root.FindElement("screens") as ScreenStack;
		let top = (stack != null) ? stack.Top : null;
		let found = (top != null) ? top.FindElement(id) : null;
		return (found != null) ? found : root.FindElement(id);
	}

	/// `node`'s text, when it is a label.
	public static void SetText(Node node, StringView text)
	{
		if (let label = node as Label)
			label.Text = text;
	}

	/// `node`'s `property` eased to `value` over `seconds`; nought sets it at once.
	public static void Fade(Node node, StringView property, StringView value, float seconds, StringView easing)
	{
		if (node != null)
			node.Animate(property, value, seconds, easing).ReleaseRef();
	}
}
