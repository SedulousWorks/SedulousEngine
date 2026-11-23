using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Engine.Sequence;

/// The names a play reports under. As entity events (an owner's, or an event track's actor) a
/// behaviour hears them as onSequenceEvent(name, value), onSequenceHeld(marker) and
/// onSequenceFinished(); on the run's bus the same handlers hear them with a SequenceNotice.
static class SequenceEvents
{
	public const String Event = "sequenceEvent";
	public const String Held = "sequenceHeld";
	public const String Finished = "sequenceFinished";

	public const String EventBus = "SequenceEvent";
	public const String HeldBus = "SequenceHeld";
	public const String FinishedBus = "SequenceFinished";
}

/// What a play with no owner reports on the run's bus: which play (its id), which sequence, and
/// the event's own name and value (an event key's; a hold's marker name).
///
/// Plain bytes, so a script holds its own copy: the name and value are views of interned text
/// (SequenceText) that lives as long as the process, and a notice a script keeps past its handler
/// still reads them.
[Scriptable, ScriptPayload]
struct SequenceNotice
{
	/// The play's id, as its SequencePlay's Id() answers.
	[Scriptable]
	public int32 Play = 0;
	/// The sequence asset played.
	[Scriptable]
	public Guid Sequence = .();
	private StringView mName = "";
	private StringView mValue = "";

	public this() {}

	public this(int32 play, Guid sequence, StringView name, StringView value)
	{
		Play = play;
		Sequence = sequence;
		mName = SequenceText.Intern(name);
		mValue = SequenceText.Intern(value);
	}

	/// The event's name, or the hold's marker name; empty for the end.
	[Scriptable]
	public StringView Name => mName;
	/// The event's value; empty for a hold and the end.
	[Scriptable]
	public StringView Value => mValue;
}

/// The text a notice names, interned for the life of the process: event and marker names come
/// from authored sequences, so the set stays as small as what was authored.
static class SequenceText
{
	private static HashSet<String> sText = new .() ~ DeleteContainerAndItems!(_);
	private static Monitor sLock = new .() ~ delete _;

	/// A view of `text` that stays valid for the life of the process.
	public static StringView Intern(StringView text)
	{
		if (text.IsEmpty)
			return "";
		using (sLock.Enter())
		{
			if (sText.TryAddAlt(text, let entry))
				*entry = new String(text);
			return *entry;
		}
	}
}
