using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Project;

namespace Dialogue;

/// The dialogue plugin's project settings, read from the project's entry for the plugin when it
/// loads (PluginContext.Settings<T>) and edited in Project Settings. Each field marked [Setting] is
/// a row there.
[Reflect(.All)]
class DialogueSettings : ISerializable
{
	/// The commands the game declares, each a form: literal words, `<name:kind>` arguments,
	/// `[optional parts]` and how it waits ("move <who:entity> to <target:entity> [and wait]").
	[Setting("Commands", "Dialogue")]
	public List<String> Commands = new .() ~ DeleteContainerAndItems!(_);
	/// Flags provided from outside the conversations (set by the application's own code), so a
	/// conversation may read them though none sets them: a name, or a prefix ending in `*`
	/// ("seen_*").
	[Setting("Provided flags", "Dialogue")]
	public List<String> ProvidedFlags = new .() ~ DeleteContainerAndItems!(_);
	/// Where flags live in the run's save store: `<prefix><flag>`.
	[Setting("Flag prefix", "Dialogue")]
	public String FlagPrefix = new .("flag.") ~ delete _;
	/// The plugin's own dialogue box shows lines and choices.
	[Setting("Stock box", "Dialogue")]
	public bool StockBox = false;
	/// The stock box types a line out at this many characters a second; 0 shows it whole.
	[Setting("Typing speed", "Dialogue"), Range(0, 200, 1)]
	public uint32 TypingSpeed = 40;
	/// The input map action that advances a line in the stock box.
	[Setting("Advance action", "Dialogue")]
	public String AdvanceAction = new .("Interact") ~ delete _;
	/// The stock box shows the speaker's portrait on the right.
	[Setting("Portrait on the right", "Dialogue")]
	public bool PortraitOnRight = false;

	public void Serialize(ISerializer ar)
	{
		ar.Key("commands");
		SerializeList(ar, Commands);
		ar.Key("providedFlags");
		SerializeList(ar, ProvidedFlags);
		Sedulous.Core.Serialization.Serialize(ar, "flagPrefix", FlagPrefix);
		SerializeValue(ar, "stockBox", ref StockBox);
		SerializeValue(ar, "typingSpeed", ref TypingSpeed);
		Sedulous.Core.Serialization.Serialize(ar, "advanceAction", AdvanceAction);
		SerializeValue(ar, "portraitOnRight", ref PortraitOnRight);
	}
}
