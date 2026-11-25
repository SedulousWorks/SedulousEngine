using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Run;

namespace Dialogue;

/// `Dialogue`: the calling script's run's runner (`Dialogue.Play(gate, "gate")`). A dialogue file is
/// reached by its guid, as every asset is: a property tagged with its type. What the runner tells
/// the game reaches a behavior's handlers as `onDialogueLine(DialogueLineNotice@)`,
/// `onDialogueChoice(DialogueChoiceNotice@)`, `onDialogueCommand(DialogueCommandNotice@)` and
/// `onDialogueEnded(DialogueEndedNotice@)`. Each run holds one; a script outside every run (an
/// editor tool) finds the plugin's idle one, which reads every call as refused and does nothing.
[Scriptable, ServiceFacade("Dialogue")]
class DialogueFacade
{
	/// BORROWED: the run whose runner this reaches; null for the idle one.
	private RunBase mRun;

	public this(RunBase run)
	{
		mRun = run;
	}

	/// The run's runner, asked for at each call; null outside a run.
	private DialogueRunService Runner => mRun?.Get<DialogueRunService>();

	/// Plays the dialogue file's conversation `conversation` (its first when empty); false when one
	/// is playing or there is no such conversation.
	[Scriptable]
	public bool Play(Guid dialogue, StringView conversation = "") => Runner?.Play(dialogue, conversation) ?? false;
	[Scriptable]
	public bool IsPlaying() => Runner?.IsPlaying ?? false;
	/// Goes on past the line showing; false when none is.
	[Scriptable]
	public bool Advance() => Runner?.Advance() ?? false;
	/// Takes answer `index` (from 0) of the choice offered.
	[Scriptable]
	public bool Choose(int32 index) => Runner?.Choose(index) ?? false;
	/// The command the conversation waits on is done.
	[Scriptable]
	public bool Done() => Runner?.Done() ?? false;
	[Scriptable]
	public void Stop() => Runner?.Stop();
	/// Goes on with the conversation the save holds a place in (after a load, or back from a
	/// command that left).
	[Scriptable]
	public bool Resume() => Runner?.Resume() ?? false;
	[Scriptable]
	public bool Flag(StringView name) => Runner?.Flag(name) ?? false;
	[Scriptable]
	public void SetFlag(StringView name, bool on) => Runner?.SetFlag(name, on);
	/// Plays the speaker `speaker` as `entity` in what follows (an invalid entity: the cast's
	/// again).
	[Scriptable]
	public void Bind(StringView speaker, EntityHandle entity) => Runner?.Bind(speaker, entity);
}

/// The dialogue's script types (the facade and the notices), which the Engine part puts on the
/// process's script surfaces while the plugin is enabled.
static class DialogueScriptSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), scope StringView[]("Dialogue."), scope StringView[](ScriptDomains.Runtime));
	}
}
