using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Run;
using Sedulous.Scene;

namespace Dialogue;

/// A line for the game to show. On the run's bus as DialogueLine, which a behavior's
/// `onDialogueLine(DialogueLineNotice@ notice)` hears.
[Scriptable, ScriptPayload]
class DialogueLineNotice : IScriptWeaklyHeld
{
	/// The dialogue file.
	[Scriptable, ReadOnly]
	public Guid Dialogue = .();
	[Scriptable, ReadOnly]
	public String Conversation = new .() ~ delete _;
	/// A cast id.
	[Scriptable, ReadOnly]
	public String Speaker = new .() ~ delete _;
	/// The cast's name for them; empty shows none.
	[Scriptable, ReadOnly]
	public String ShownName = new .() ~ delete _;
	[Scriptable, ReadOnly]
	public String Mood = new .() ~ delete _;
	/// The mood's, else the speaker's; nil for none.
	[Scriptable, ReadOnly]
	public Guid Portrait = .();
	/// Its `{Action}`s filled in.
	[Scriptable, ReadOnly]
	public String Text = new .() ~ delete _;
	[Scriptable, ReadOnly]
	public String LineId = new .() ~ delete _;

	// Where scripts' handles to it resolve: the bus deletes it once delivered, and a handle a
	// script kept reads as gone from then.
	private ScriptWeakSlot mScriptSlot;

	public ~this()
	{
		mScriptSlot.Free();
	}

	public ScriptWeakRef TakeScriptWeak() => mScriptSlot.Take(this);
}

/// The answers for the game to offer; the runner's Choose takes one. On the run's bus as
/// DialogueChoice (`onDialogueChoice(DialogueChoiceNotice@ notice)`); a script reads the answers
/// by index.
[Scriptable, ScriptPayload]
class DialogueChoiceNotice : IScriptWeaklyHeld
{
	[Scriptable, ReadOnly]
	public Guid Dialogue = .();
	[Scriptable, ReadOnly]
	public String Conversation = new .() ~ delete _;
	/// Their texts, `{Action}`s filled in.
	public List<String> Answers = new .() ~ DeleteContainerAndItems!(_);
	public List<String> LineIds = new .() ~ DeleteContainerAndItems!(_);

	[Scriptable]
	public int32 AnswerCount() => (int32)Answers.Count;
	/// Answer `index`'s text; empty past the last.
	[Scriptable]
	public StringView Answer(int32 index) => ((index >= 0) && (index < Answers.Count)) ? Answers[index] : "";
	[Scriptable]
	public StringView AnswerLineId(int32 index) => ((index >= 0) && (index < LineIds.Count)) ? LineIds[index] : "";

	// Where scripts' handles to it resolve: the bus deletes it once delivered, and a handle a
	// script kept reads as gone from then.
	private ScriptWeakSlot mScriptSlot;

	public ~this()
	{
		mScriptSlot.Free();
	}

	public ScriptWeakRef TakeScriptWeak() => mScriptSlot.Take(this);
}

/// A declared command for the game to carry out. On the run's bus as DialogueCommand
/// (`onDialogueCommand(DialogueCommandNotice@ notice)`); a script reads its arguments by their
/// names in the command's form.
[Scriptable, ScriptPayload]
class DialogueCommandNotice : IScriptWeaklyHeld
{
	[Scriptable, ReadOnly]
	public Guid Dialogue = .();
	[Scriptable, ReadOnly]
	public String Conversation = new .() ~ delete _;
	[Scriptable, ReadOnly]
	public String Name = new .() ~ delete _;
	/// The conversation waits for the runner's Done.
	[Scriptable, ReadOnly]
	public bool Waits = false;
	/// The conversation has ended with its place saved.
	[Scriptable, ReadOnly]
	public bool Leaves = false;
	public List<DialogueArgument> Arguments = new .() ~ DeleteContainerAndItems!(_);
	/// Where an entity argument is looked for (the run's scene), weakly.
	public ScriptWeakRef Scene;

	/// The argument `name`, or null.
	public DialogueArgument Find(StringView name)
	{
		for (let argument in Arguments)
		{
			if (argument.Name == name)
				return argument;
		}
		return null;
	}

	/// Whether the argument `name` was written (an optional part, `[running]`).
	[Scriptable]
	public bool Has(StringView name) => Find(name)?.Present ?? false;
	/// The argument `name` as written; empty when absent.
	[Scriptable]
	public StringView Text(StringView name) => Find(name)?.Text ?? "";
	[Scriptable]
	public float Number(StringView name) => Find(name)?.Number ?? 0.0f;
	/// An asset argument's asset; nil when absent.
	[Scriptable]
	public Guid Asset(StringView name) => Find(name)?.Asset ?? .();
	/// An entity argument's entity in the run's scene, by its name; invalid when there is none.
	[Scriptable]
	public EntityHandle Entity(StringView name)
	{
		let argument = Find(name);
		let scene = Scene.Resolve() as Sedulous.Scene.Scene;
		if ((argument == null) || (scene == null))
			return .Invalid;
		return scene.FindEntityByName(argument.Text);
	}

	// Where scripts' handles to it resolve: the bus deletes it once delivered, and a handle a
	// script kept reads as gone from then.
	private ScriptWeakSlot mScriptSlot;

	public ~this()
	{
		mScriptSlot.Free();
	}

	public ScriptWeakRef TakeScriptWeak() => mScriptSlot.Take(this);
}

/// The conversation ended: reached its end, was stopped, or left for a command. On the run's bus
/// as DialogueEnded (`onDialogueEnded(DialogueEndedNotice@ notice)`).
[Scriptable, ScriptPayload]
class DialogueEndedNotice : IScriptWeaklyHeld
{
	[Scriptable, ReadOnly]
	public Guid Dialogue = .();
	[Scriptable, ReadOnly]
	public String Conversation = new .() ~ delete _;
	/// By the runner's Stop.
	[Scriptable, ReadOnly]
	public bool Stopped = false;
	/// By a command that leaves; the runner's Resume goes on from there.
	[Scriptable, ReadOnly]
	public bool Left = false;

	// Where scripts' handles to it resolve: the bus deletes it once delivered, and a handle a
	// script kept reads as gone from then.
	private ScriptWeakSlot mScriptSlot;

	public ~this()
	{
		mScriptSlot.Free();
	}

	public ScriptWeakRef TakeScriptWeak() => mScriptSlot.Take(this);
}

/// The names the notices go out under on the run's bus (a behavior's `on<Name>` hears them), and
/// the save store's key for the resume record.
static class DialogueEvents
{
	public const String Line = "DialogueLine";
	public const String Choice = "DialogueChoice";
	public const String Command = "DialogueCommand";
	public const String Ended = "DialogueEnded";
	public const String ResumeKey = "dialogue.resume";
}

/// What a runner needs from the game around it.
interface IDialogueHost
{
	/// The dialogue file `id`, loaded (BORROWED, the host's, current until the runner's next call
	/// into the host); null when there is none. The runner asks again each time it steps, so a file
	/// reloaded under it is the one it reads.
	DialogueResource LoadDialogue(Guid id);
	/// The cast `id`, loaded (BORROWED, as LoadDialogue's); null when there is none.
	DialogueCastResource LoadCast(Guid id);

	/// The save store's boolean `key` (false when absent), and writing it.
	bool ReadFlag(StringView key);
	void WriteFlag(StringView key, bool on);
	/// The save store's text `key` into `outText` (nothing when absent), and writing it (empty
	/// removes it).
	void ReadText(StringView key, String outText);
	void WriteText(StringView key, StringView text);

	/// What the input action `action` is bound to, as a line shows it, into `outLabel`; nothing
	/// keeps `{action}`.
	void ActionLabel(StringView action, String outLabel);

	/// Starts a staging step (Play, Sound, Fade, Sequence) with the cast `cast` (null: none); a
	/// token to ask after while the conversation waits for it, 0 for nothing to wait on.
	uint32 Stage(DialogueStep step, DialogueCastResource cast);
	/// Whether the staging `token` is still going.
	bool IsStaging(uint32 token);

	/// The runner's clock, every frame whether or not a conversation plays (a fade goes on after
	/// the conversation that began it).
	void Update(float deltaTime) {}

	/// What the runner tells the game. The notice is the host's from the call on (it deletes it, or
	/// hands it on). `speaker` is the line's speaker's entry in the cast (BORROWED, for the call);
	/// null when the cast has none.
	void OnLine(DialogueLineNotice notice, DialogueSpeaker speaker);
	/// The line shown has been advanced past, or the conversation ended on it.
	void OnLineEnded() {}
	void OnChoice(DialogueChoiceNotice notice);
	void OnCommand(DialogueCommandNotice notice);
	void OnEnded(DialogueEndedNotice notice);
}

/// What the runner is waiting on.
enum DialogueWait : uint8
{
	/// Not playing, or between steps.
	Nothing,
	/// Advance.
	Line,
	/// Choose.
	Choice,
	/// A `wait`.
	Time,
	/// A clip, sound, fade or sequence told to wait.
	Staging,
	/// Done.
	Command,
}

/// Plays one conversation at a time. It walks a conversation's steps from the first and stops at a
/// step that waits: a line until it is advanced, a choice until one answer is chosen, a `wait` for
/// its time, staging told to wait until it is done, a command told to wait until the game says it
/// is done. A command that leaves ends the conversation with its place saved, for the game to
/// resume once it comes back.
///
/// What it needs from the game around it goes through IDialogueHost: loading dialogue files and
/// casts, the flags and the resume record (the run's save store, under the settings' prefix), the
/// staging and what it tells the game. The run's own host is the engine's; a test gives it a
/// stand-in.
///
/// It keeps the file's guid and the conversation's id, not the loaded file: it asks the host for
/// the file each time it steps, so a file reloaded mid conversation (its old product released) is
/// never read after it went.
///
/// Resume anchors on a line, not a step index, so a save survives a patch to the conversation: the
/// record holds the dialogue file, the conversation, the step to go on at, the id of the last line
/// shown and a hash of the conversation's steps. When the hash matches, the runner goes on at the
/// step; otherwise at that line, if the conversation still has it; otherwise from the start. The
/// record is written as each line shows and when a command leaves, so a game that saves mid
/// conversation saves its place too, and it is cleared when the conversation ends.
class DialogueRunner : IRunService
{
	// The resume record's fields, in order, joined by `|` (none of them holds one: a guid, a
	// conversation id and a line id are words, the step and the hash numbers).
	const int cResumeDialogue = 0;
	const int cResumeConversation = 1;
	const int cResumeStep = 2;
	const int cResumeLine = 3;
	const int cResumeHash = 4;
	const int cResumeFieldCount = 5;

	DialogueSettings mSettings; // BORROWED, outlives the runner
	protected IDialogueHost mHost; // BORROWED, outlives the runner
	Guid mDialogue = .();
	String mConversation = new .() ~ delete _;
	Guid mCast = .();
	int mStep = 0;
	bool mPlaying = false;
	DialogueWait mWait = .Nothing;
	float mTimer = 0.0f;
	uint32 mStaging = 0;
	/// The id of the last line shown, the resume record's anchor.
	String mLastLine = new .() ~ delete _;
	bool mPumping = false;
	/// A line shown on its own (a sequence's), not a conversation's; 0 for none.
	uint32 mShownLine = 0;
	uint32 mNextLine = 1;

	/// `settings` and `host` outlive the runner.
	public this(DialogueSettings settings, IDialogueHost host)
	{
		mSettings = settings;
		mHost = host;
	}

	public bool IsPlaying => mPlaying;
	public DialogueWait Waiting => mWait;

	/// Plays the conversation `conversation` of the dialogue file `dialogue` (its first when
	/// empty). False, logged, when one is already playing or there is no such conversation.
	public bool Play(Guid dialogue, StringView conversation)
	{
		if (mPlaying)
		{
			GlobalLog(.Warning, "Dialogue: play: the conversation `{}` is still playing", mConversation);
			return false;
		}
		if (mShownLine != 0)
			EndLine(mShownLine); // a conversation takes over from a sequence's line
		let file = mHost.LoadDialogue(dialogue);
		if (file == null)
		{
			GlobalLog(.Warning, "Dialogue: play: no dialogue file {}", dialogue);
			return false;
		}
		let found = conversation.IsEmpty ? (file.Conversations.IsEmpty ? null : file.Conversations[0]) : file.Find(conversation);
		if (found == null)
		{
			GlobalLog(.Warning, "Dialogue: play: the dialogue file {} has no conversation `{}`", dialogue, conversation);
			return false;
		}
		Begin(file, dialogue, found, 0);
		Pump();
		return true;
	}

	/// Goes on past the line showing; false when none is.
	public bool Advance()
	{
		if (mShownLine != 0)
		{
			EndLine(mShownLine);
			return true;
		}
		if (mWait != .Line)
			return false;
		mHost.OnLineEnded();
		mWait = .Nothing;
		mStep++;
		Pump();
		return true;
	}

	/// Takes answer `index` of the choice offered; false when none is, or no such answer.
	public bool Choose(int32 index)
	{
		if (mWait != .Choice)
			return false;
		let steps = Current()?.Steps;
		if ((steps == null) || (mStep >= steps.Count))
			return false;
		let choice = steps[mStep];
		if ((index < 0) || ((uint32)index >= choice.Count) || (mStep + 1 + index >= steps.Count))
			return false;
		let answer = steps[mStep + 1 + index];
		mWait = .Nothing;
		mStep = answer.Next;
		Pump();
		return true;
	}

	/// The command the conversation waits on is done; false when it waits on none.
	public bool Done()
	{
		if (mWait != .Command)
			return false;
		mWait = .Nothing;
		Pump();
		return true;
	}

	/// Ends the conversation now; its place is not kept.
	public void Stop()
	{
		if (mPlaying)
			Finish(true, false);
	}

	/// Shows one line on its own (a sequence's line track): the game hears it as a conversation's
	/// line, Advance ends it, and DialogueEnded (no conversation) follows. Its token, or 0, logged,
	/// while a conversation plays. A line already shown gives way. `cast` is BORROWED, for the call.
	public uint32 ShowLine(DialogueCastResource cast, StringView speaker, StringView mood, StringView text, StringView lineId)
	{
		if (mPlaying)
		{
			GlobalLog(.Warning, "Dialogue: a sequence's line waits for no one: the conversation `{}` is playing", mConversation);
			return 0;
		}
		if (mShownLine != 0)
			EndLine(mShownLine);
		let notice = LineNotice(cast, speaker, mood, text, lineId, let entry);
		mShownLine = mNextLine++;
		mHost.OnLine(notice, entry);
		return mShownLine;
	}

	/// Whether the line `token` is still shown.
	public bool IsShowing(uint32 token) => (token != 0) && (token == mShownLine);

	/// Ends the line `token` if it is still shown (its play let go of it).
	public void EndLine(uint32 token)
	{
		if ((token == 0) || (token != mShownLine))
			return;
		mShownLine = 0;
		mHost.OnLineEnded();
		mHost.OnEnded(new DialogueEndedNotice());
	}

	// A line's notice: its speaker's name, mood and portrait from `cast` (null: none), its text
	// filled; `entry` the speaker's cast entry, or null.
	DialogueLineNotice LineNotice(DialogueCastResource cast, StringView speaker, StringView mood, StringView text, StringView lineId,
		out DialogueSpeaker entry)
	{
		let notice = new DialogueLineNotice();
		notice.Speaker.Set(speaker);
		notice.Mood.Set(mood);
		notice.LineId.Set(lineId);
		Fill(text, notice.Text);
		entry = cast?.Find(speaker);
		if (entry != null)
		{
			notice.ShownName.Set(entry.ShownName);
			if (notice.Mood.IsEmpty && !entry.Moods.IsEmpty)
				notice.Mood.Set(entry.Moods[0].Name); // the first is the default
			let found = entry.FindMood(notice.Mood);
			notice.Portrait = ((found != null) && (found.Portrait != .())) ? found.Portrait : entry.Portrait;
		}
		return notice;
	}

	/// Goes on with the conversation the resume record names; false when there is none, or one is
	/// playing.
	public bool Resume()
	{
		if (mPlaying)
			return false;
		let record = mHost.ReadText(DialogueEvents.ResumeKey, .. scope .());
		if (record.IsEmpty)
			return false;
		let fields = scope List<StringView>();
		for (let field in record.Split('|'))
			fields.Add(field);
		Guid dialogue = .();
		if (fields.Count == cResumeFieldCount)
		{
			if (Guid.Parse(fields[cResumeDialogue]) case .Ok(let parsed))
				dialogue = parsed;
		}
		if (dialogue == .())
		{
			GlobalLog(.Warning, "Dialogue: resume: the record `{}` is not one", record);
			mHost.WriteText(DialogueEvents.ResumeKey, "");
			return false;
		}
		let file = mHost.LoadDialogue(dialogue);
		let conversation = (file != null) ? file.Find(fields[cResumeConversation]) : null;
		if (conversation == null)
		{
			GlobalLog(.Warning, "Dialogue: resume: the dialogue file {} has no conversation `{}` now", dialogue, fields[cResumeConversation]);
			mHost.WriteText(DialogueEvents.ResumeKey, "");
			return false;
		}
		let line = fields[cResumeLine];
		int step = 0;
		let hash = HashSteps(conversation).ToString(.. scope .());
		int saved = -1;
		if (int.Parse(fields[cResumeStep]) case .Ok(let parsed))
			saved = parsed;
		if ((fields[cResumeHash] == hash) && (saved >= 0) && (saved < conversation.Steps.Count))
		{
			step = saved; // the conversation is as it was saved
		}
		else
		{
			bool found = false;
			for (int i = 0; (i < conversation.Steps.Count) && !line.IsEmpty; i++)
			{
				let candidate = conversation.Steps[i];
				if ((candidate.Kind == .Line) && (candidate.LineId == line))
				{
					step = i;
					found = true;
					break;
				}
			}
			if (!found)
				GlobalLog(.Warning, "Dialogue: resume: the conversation `{}` changed since the save; it starts again", conversation.Id);
		}
		Begin(file, dialogue, conversation, step);
		mLastLine.Set(line);
		Pump();
		return true;
	}

	/// A flag, by its name without the settings' prefix.
	public bool Flag(StringView name) => mHost.ReadFlag(FlagKey(name, .. scope .()));
	public void SetFlag(StringView name, bool on) => mHost.WriteFlag(FlagKey(name, .. scope .()), on);

	/// Steps the clock: the host's, then a `wait` counts down and staging is asked after.
	public void Update(float deltaTime)
	{
		mHost.Update(deltaTime);
		if (!mPlaying)
			return;
		if (mWait == .Time)
		{
			mTimer -= deltaTime;
			if (mTimer > 0.0f)
				return;
		}
		else if (mWait == .Staging)
		{
			if (mHost.IsStaging(mStaging))
				return;
			mStaging = 0;
		}
		else
		{
			return;
		}
		mWait = .Nothing;
		Pump();
	}

	public void OnRunUpdate(IRun run, float deltaTime) => Update(deltaTime);

	/// The run is ending: nothing is left to tell, and the resume record stays for the next.
	public void OnRunStopping(IRun run)
	{
		mShownLine = 0;
		mPlaying = false;
		mWait = .Nothing;
		mConversation.Clear();
		mDialogue = .();
		mCast = .();
	}

	/// The hash of a conversation's steps the resume record keeps.
	public static uint64 HashSteps(DialogueConversation conversation)
	{
		uint64 Text(StringView text, uint64 hash)
		{
			let next = HashBytes(text.Ptr, text.Length, hash);
			uint8 end = 0; // so "ab","c" and "a","bc" differ
			return HashBytes(&end, 1, next);
		}
		var hash = FnvOffsetBasis;
		for (let step in conversation.Steps)
		{
			var kind = (uint8)step.Kind;
			hash = HashBytes(&kind, 1, hash);
			hash = Text(step.LineId, hash);
			hash = Text(step.Name, hash);
			hash = Text(step.File, hash);
			hash = Text(step.Flag, hash);
			var negate = step.Negate;
			hash = HashBytes(&negate, sizeof(bool), hash);
			var next = step.Next;
			hash = HashBytes(&next, sizeof(int32), hash);
			var count = step.Count;
			hash = HashBytes(&count, sizeof(uint32), hash);
		}
		return hash;
	}

	// The conversation playing, from the file as the host has it now; null when it is gone.
	DialogueConversation Current()
	{
		let file = mHost.LoadDialogue(mDialogue);
		return (file != null) ? file.Find(mConversation) : null;
	}

	// Starts `conversation` of the loaded `file` at step `step`.
	void Begin(DialogueResource file, Guid dialogue, DialogueConversation conversation, int step)
	{
		mCast = file.Cast;
		mDialogue = dialogue;
		mConversation.Set(conversation.Id);
		mStep = step;
		mWait = .Nothing;
		mStaging = 0;
		mLastLine.Clear();
		mPlaying = true;
	}

	// Runs steps until one waits or the conversation ends.
	void Pump()
	{
		// A host may answer a notice at once (advance a line from inside OnLine): that call moves
		// the runner on and this loop goes on from there, rather than a second loop inside it.
		if (mPumping)
			return;
		mPumping = true;
		defer { mPumping = false; }
		while (mPlaying && (mWait == .Nothing))
		{
			let file = mHost.LoadDialogue(mDialogue);
			let conversation = (file != null) ? file.Find(mConversation) : null;
			if (conversation == null)
			{
				GlobalLog(.Warning, "Dialogue: the conversation `{}` is gone from its dialogue file {}", mConversation, mDialogue);
				Finish(false, false);
				break;
			}
			let steps = conversation.Steps;
			if (mStep >= steps.Count)
			{
				Finish(false, false);
				break;
			}
			let step = steps[mStep];
			switch (step.Kind)
			{
			case .Line:
				let cast = (mCast != .()) ? mHost.LoadCast(mCast) : null;
				let notice = LineNotice(cast, step.Speaker, step.Mood, file.Text(step.LineId), step.LineId, let speaker);
				notice.Dialogue = mDialogue;
				notice.Conversation.Set(mConversation);
				mLastLine.Set(step.LineId);
				WriteResume(conversation, mStep);
				mWait = .Line;
				mHost.OnLine(notice, speaker);
			case .Choice:
				let notice = new DialogueChoiceNotice();
				notice.Dialogue = mDialogue;
				notice.Conversation.Set(mConversation);
				for (int a = 1; (a <= step.Count) && (mStep + a < steps.Count); a++)
				{
					let answer = steps[mStep + a];
					let text = new String();
					Fill(file.Text(answer.LineId), text);
					notice.Answers.Add(text);
					notice.LineIds.Add(new .(answer.LineId));
				}
				mWait = .Choice;
				mHost.OnChoice(notice);
			case .Answer, .Skip: // only a choice reaches its answers' statements
				if (step.Next < 0)
				{
					Finish(false, false);
					break;
				}
				mStep = step.Next;
			case .If:
				if (Flag(step.Flag) != step.Negate)
					mStep++;
				else if (step.Next < 0)
					Finish(false, false);
				else
					mStep = step.Next;
			case .Set, .Clear:
				SetFlag(step.Flag, step.Kind == .Set);
				mStep++;
			case .Wait:
				mStep++;
				if (step.Seconds > 0.0f)
				{
					mTimer = step.Seconds;
					mWait = .Time;
				}
			case .Play, .Sound, .Fade, .Sequence:
				let cast = (mCast != .()) ? mHost.LoadCast(mCast) : null;
				let token = mHost.Stage(step, cast);
				mStep++;
				// A fade always waits; the others when told to (`and wait`).
				if ((token != 0) && (step.Waits || (step.Kind == .Fade)))
				{
					mStaging = token;
					mWait = .Staging;
				}
			case .Jump:
				let dialogue = (step.Asset == .()) ? mDialogue : step.Asset;
				let target = (step.Asset == .()) ? file : mHost.LoadDialogue(step.Asset);
				let next = (target != null) ? target.Find(step.Name) : null;
				if (next == null)
				{
					GlobalLog(.Warning, "Dialogue: jump: no conversation `{}` to jump to", step.Name);
					Finish(false, false);
					break;
				}
				Begin(target, dialogue, next, 0);
			case .Command:
				let notice = new DialogueCommandNotice();
				notice.Dialogue = mDialogue;
				notice.Conversation.Set(mConversation);
				notice.Name.Set(step.Name);
				for (let argument in step.Arguments)
				{
					let copy = new DialogueArgument();
					copy.Name.Set(argument.Name);
					copy.Text.Set(argument.Text);
					copy.Number = argument.Number;
					copy.Asset = argument.Asset;
					copy.Present = argument.Present;
					notice.Arguments.Add(copy);
				}
				notice.Waits = step.Waits && !step.Leaves;
				notice.Leaves = step.Leaves;
				mStep++;
				if (step.Leaves)
				{
					WriteResume(conversation, mStep);
					mHost.OnCommand(notice);
					Finish(false, true);
					break;
				}
				if (notice.Waits)
					mWait = .Command;
				mHost.OnCommand(notice);
			case .End:
				Finish(false, false);
			}
		}
	}

	void Finish(bool stopped, bool left)
	{
		let notice = new DialogueEndedNotice();
		notice.Dialogue = mDialogue;
		notice.Conversation.Set(mConversation);
		notice.Stopped = stopped;
		notice.Left = left;
		if (mWait == .Line)
			mHost.OnLineEnded();
		// Cleared before the game hears it, so it may play another from its handler.
		mPlaying = false;
		mWait = .Nothing;
		mConversation.Clear();
		mStaging = 0;
		if (!left)
			mHost.WriteText(DialogueEvents.ResumeKey, "");
		mHost.OnEnded(notice);
	}

	void WriteResume(DialogueConversation conversation, int step)
	{
		let record = scope String();
		record.AppendF("{}|{}|{}|{}|{}", mDialogue, conversation.Id, step, mLastLine, HashSteps(conversation));
		mHost.WriteText(DialogueEvents.ResumeKey, record);
	}

	void FlagKey(StringView name, String outKey)
	{
		outKey.Append(mSettings.FlagPrefix);
		outKey.Append(name);
	}

	// `text` with each `{Action}` filled with its binding's label, into `outText`; `{{` and `}}`
	// are braces, and an action the host has no label for stays as written.
	void Fill(StringView text, String outText)
	{
		for (int i = 0; i < text.Length; i++)
		{
			let c = text[i];
			if (((c == '{') || (c == '}')) && (i + 1 < text.Length) && (text[i + 1] == c))
			{
				outText.Append(c);
				i++;
				continue;
			}
			if (c != '{')
			{
				outText.Append(c);
				continue;
			}
			let close = text.IndexOf('}', i + 1);
			if (close < 0)
			{
				outText.Append(text.Substring(i));
				break;
			}
			let label = mHost.ActionLabel(text.Substring(i + 1, close - i - 1), .. scope .());
			outText.Append(label.IsEmpty ? text.Substring(i, close - i + 1) : (StringView)label);
			i = close;
		}
	}
}
