using System;
using System.Collections;
using Sedulous.Core;
using Dialogue;

namespace Dialogue.Tests;

/// Dialogue.Engine's runner, playing conversations written as text and parsed here (the parser is
/// this suite's), against a stand-in host that records what the runner tells the game and holds the
/// save store. Lines, choices and branches; flags under the settings' prefix; waits, staging and
/// commands that wait or leave; jumps within a file and into another; resume after a load, and
/// after a patch to the conversation; a second play refused, a stop, a host that answers at once.
class DialogueRunnerTests
{
	static Guid MakeGuid(uint8 seed) => Guid(seed, seed, 0, 0, 0, 0, 0, 0, 0, 0, seed);

	static DialogueResource Compile(StringView text, Guid cast = .())
	{
		let forms = scope List<DialogueCommandForm>();
		defer { ClearAndDeleteItems!(forms); }
		String[?] texts = .("cue <event:text> waits", "fight <foe:word> leaves", "note <what:text>");
		let error = scope String();
		for (let form in texts)
		{
			let parsed = new DialogueCommandForm();
			forms.Add(parsed);
			Test.Assert(DialogueFormat.ParseCommandForm(form, parsed, error), error);
		}
		let parse = scope DialogueParse();
		DialogueFormat.ParseDialogue(text, forms, parse);
		for (let problem in parse.Problems)
		{
			Console.WriteLine($"{problem.Line}: {problem.Message}");
			Test.Assert(problem.Warning);
		}
		Test.Assert(parse.Ok);
		let resource = new DialogueResource();
		resource.Cast = cast;
		Swap!(resource.Conversations, parse.Conversations);
		Swap!(resource.Lines, parse.Lines);
		return resource;
	}

	/// The game around the runner: its files, its save store, its staging, and a log of what it was
	/// told, one entry each.
	class StandIn : IDialogueHost
	{
		public Dictionary<Guid, DialogueResource> Files = new .() ~ DeleteDictionaryAndValues!(_);
		public Guid CastId;
		public DialogueCastResource Cast = new .() ~ delete _;
		public Dictionary<String, String> Store = new .() ~ DeleteDictionaryAndKeysAndValues!(_);
		public List<String> Told = new .() ~ DeleteContainerAndItems!(_);
		/// The tokens still going.
		public List<uint32> Staging = new .() ~ delete _;
		public uint32 NextToken = 1;
		public bool AdvanceAtOnce = false;
		public DialogueRunner Runner;
		public DialogueLineNotice LastLine ~ delete _;
		public DialogueChoiceNotice LastChoice ~ delete _;
		public DialogueCommandNotice LastCommand ~ delete _;
		public DialogueEndedNotice LastEnded ~ delete _;

		/// Puts `file` in as `id`, replacing what was there.
		public void Put(Guid id, DialogueResource file)
		{
			if (Files.GetAndRemove(id) case .Ok(let old))
				delete old.value;
			Files[id] = file;
		}

		public DialogueResource LoadDialogue(Guid id) => Files.TryGetValue(id, let file) ? file : null;
		public DialogueCastResource LoadCast(Guid id) => (id == CastId) ? Cast : null;

		public bool ReadFlag(StringView key) => Read(key) == "true";
		public void WriteFlag(StringView key, bool on) => Write(key, on ? "true" : "false");
		public void ReadText(StringView key, String outText) => outText.Append(Read(key));
		public void WriteText(StringView key, StringView text) => Write(key, text);

		public void ActionLabel(StringView action, String outLabel)
		{
			if (action == "Interact")
				outLabel.Append("E");
		}

		public uint32 Stage(DialogueStep step, DialogueCastResource cast)
		{
			Told.Add(new $"stage {(step.Name.IsEmpty ? "fade" : step.Name)}");
			Staging.Add(NextToken);
			return NextToken++;
		}

		public bool IsStaging(uint32 token) => Staging.Contains(token);

		public uint32 LinesEnded = 0;
		public float Clock = 0.0f;

		public void Update(float deltaTime) { Clock += deltaTime; }
		public void OnLineEnded() { LinesEnded++; }

		public void OnLine(DialogueLineNotice notice, DialogueSpeaker speaker)
		{
			delete LastLine;
			LastLine = notice;
			Told.Add(new $"{notice.Speaker}: {notice.Text}");
			if (AdvanceAtOnce)
				Runner.Advance();
		}

		public void OnChoice(DialogueChoiceNotice notice)
		{
			delete LastChoice;
			LastChoice = notice;
			let joined = scope String();
			for (let answer in notice.Answers)
			{
				if (!joined.IsEmpty)
					joined.Append(" | ");
				joined.Append(answer);
			}
			Told.Add(new $"choice {joined}");
		}

		public void OnCommand(DialogueCommandNotice notice)
		{
			delete LastCommand;
			LastCommand = notice;
			Told.Add(new $"command {notice.Name}");
		}

		public void OnEnded(DialogueEndedNotice notice)
		{
			delete LastEnded;
			LastEnded = notice;
			Told.Add(new $"ended {notice.Conversation}");
		}

		public StringView Read(StringView key) => Store.TryGetAlt(key, ?, let value) ? (StringView)value : "";

		public void Write(StringView key, StringView value)
		{
			if (Store.GetAndRemoveAlt(key) case .Ok(let old))
			{
				delete old.key;
				delete old.value;
			}
			if (!value.IsEmpty)
				Store[new .(key)] = new .(value);
		}

		/// What it was told since the last call, one entry a line.
		public String TakeTold(String outText)
		{
			for (let entry in Told)
			{
				outText.Append(entry);
				outText.Append('\n');
			}
			ClearAndDeleteItems!(Told);
			return outText;
		}
	}

	class Fixture
	{
		public DialogueSettings Settings = new .() ~ delete _;
		public StandIn Host = new .() ~ delete _;
		public DialogueRunner Runner ~ delete _;
		public Guid Gate = MakeGuid(1);
		String mTold = new .() ~ delete _;

		public this()
		{
			Runner = new .(Settings, Host);
			Host.Runner = Runner;
			Host.CastId = MakeGuid(2);
			let keeper = new DialogueSpeaker();
			keeper.Id.Set("keeper");
			keeper.ShownName.Set("The Keeper");
			keeper.Portrait = MakeGuid(3);
			keeper.Moods.Add(new .("calm", .()));
			keeper.Moods.Add(new .("worried", MakeGuid(4)));
			Host.Cast.Speakers.Add(keeper);
			let visitor = new DialogueSpeaker();
			visitor.Id.Set("visitor");
			Host.Cast.Speakers.Add(visitor);
		}

		public void Add(Guid id, StringView text) => Host.Put(id, Compile(text, Host.CastId));

		/// What the host was told since the last call.
		public StringView Told() => Host.TakeTold(mTold..Clear());
	}

	[Test]
	public static void LinesWaitForAdvanceAChoiceForAnAnswerAndItsFlagsGoInTheSaveStore()
	{
		let f = scope Fixture();
		f.Add(f.Gate, "conversation gate\n" +
			"@ keeper: Who goes there? Press {Interact}, {{or}} not.\n" +
			"choice\n" +
			"> A friend.\n" +
			"  set friendly\n" +
			"  @ keeper worried: A friend, then.\n" +
			"> Nobody.\n" +
			"  @ visitor: Nobody at all.\n" +
			"end\n" +
			"@ keeper: Go on.\n");
		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(f.Runner.IsPlaying);
		Test.Assert(f.Runner.Waiting == .Line);
		Test.Assert(f.Told() == "keeper: Who goes there? Press E, {or} not.\n");
		Test.Assert(f.Host.LastLine.ShownName == "The Keeper");
		Test.Assert(f.Host.LastLine.Mood == "calm", "the speaker's first, unnamed");
		Test.Assert(f.Host.LastLine.Portrait == MakeGuid(3), "the mood has none: the speaker's");
		Test.Assert(f.Host.LastLine.LineId == "gate.1");
		Test.Assert(f.Host.LastLine.Dialogue == f.Gate);
		Test.Assert(!f.Runner.Choose(0), "no choice offered yet");

		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Host.LinesEnded == 1, "the line advanced past");
		Test.Assert(f.Runner.Waiting == .Choice);
		Test.Assert(f.Told() == "choice A friend. | Nobody.\n");
		Test.Assert(f.Host.LastChoice.LineIds.Count == 2);
		Test.Assert(!f.Runner.Advance(), "no line showing");
		Test.Assert(!f.Runner.Choose(2));

		Test.Assert(f.Runner.Choose(0));
		Test.Assert(f.Told() == "keeper: A friend, then.\n");
		Test.Assert(f.Host.LastLine.Portrait == MakeGuid(4), "the mood's own");
		Test.Assert(f.Runner.Flag("friendly"));
		Test.Assert(f.Host.Read("flag.friendly") == "true");
		Test.Assert(!f.Host.Read(DialogueEvents.ResumeKey).IsEmpty, "its place, as each line shows");

		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "keeper: Go on.\n");
		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "ended gate\n");
		Test.Assert(!f.Runner.IsPlaying);
		Test.Assert(!f.Host.LastEnded.Stopped);
		Test.Assert(!f.Host.LastEnded.Left);
		Test.Assert(f.Host.Read(DialogueEvents.ResumeKey).IsEmpty, "ended: nothing to resume");

		// Again, taking the second answer: its own statements.
		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(f.Runner.Advance());
		f.Told();
		Test.Assert(f.Runner.Choose(1));
		Test.Assert(f.Told() == "visitor: Nobody at all.\n");
	}

	[Test]
	public static void ABranchReadsAFlagSetByScriptOrByAConversation()
	{
		let f = scope Fixture();
		f.Add(f.Gate, "conversation gate\n" +
			"if met\n" +
			"  @ keeper: Back again.\n" +
			"else\n" +
			"  @ keeper: New here?\n" +
			"end\n" +
			"if not met\n" +
			"  set met\n" +
			"end\n");
		Test.Assert(f.Runner.Play(f.Gate, ""), "the first conversation");
		Test.Assert(f.Told() == "keeper: New here?\n");
		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "ended gate\n");
		Test.Assert(f.Runner.Flag("met"));

		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(f.Told() == "keeper: Back again.\n");
		let ended = f.Host.LinesEnded;
		f.Runner.Stop();
		Test.Assert(f.Host.LinesEnded == ended + 1, "stopped on a line: it ends too");
		Test.Assert(f.Told() == "ended gate\n");
		Test.Assert(f.Host.LastEnded.Stopped);

		f.Runner.SetFlag("met", false);
		Test.Assert(f.Host.Read("flag.met") == "false");
		f.Settings.FlagPrefix.Set("story.");
		f.Runner.SetFlag("met", true);
		Test.Assert(f.Host.Read("story.met") == "true");
	}

	[Test]
	public static void AWaitCountsDownStagingWaitsWhenToldToAndAFadeAlways()
	{
		let f = scope Fixture();
		f.Add(f.Gate, "conversation gate\n" +
			"wait 1\n" +
			"sound creak\n" +
			"sequence opening and wait\n" +
			"fade out\n" +
			"@ keeper: Done.\n");
		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(f.Runner.Waiting == .Time);
		f.Runner.Update(0.6f);
		Test.Assert(Math.Abs(f.Host.Clock - 0.6f) < 1e-5f, "the host's clock");
		Test.Assert(f.Told().IsEmpty);
		f.Runner.Update(0.6f);
		Test.Assert(f.Told() == "stage creak\nstage opening\n", "the sound does not wait");
		Test.Assert(f.Runner.Waiting == .Staging);
		f.Runner.Update(1.0f);
		Test.Assert(f.Told().IsEmpty, "the sequence is still going");
		f.Host.Staging.Clear();
		f.Runner.Update(0.1f);
		Test.Assert(f.Told() == "stage fade\n");
		Test.Assert(f.Runner.Waiting == .Staging);
		f.Host.Staging.Clear();
		f.Runner.Update(0.1f);
		Test.Assert(f.Told() == "keeper: Done.\n");
	}

	[Test]
	public static void ACommandThatWaitsHoldsForDoneOneThatLeavesEndsWithItsPlaceKept()
	{
		let f = scope Fixture();
		f.Add(f.Gate, "conversation gate\n" +
			"note the gate\n" +
			"cue lights dim\n" +
			"@ keeper: Something stirs.\n" +
			"fight wolf\n" +
			"@ keeper: You won.\n");
		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(f.Told() == "command note\ncommand cue\n");
		Test.Assert(f.Host.LastCommand.Waits);
		Test.Assert(f.Host.LastCommand.Find("event") != null);
		Test.Assert(f.Host.LastCommand.Find("event").Text == "lights dim");
		Test.Assert(f.Runner.Waiting == .Command);
		Test.Assert(!f.Runner.Advance());
		Test.Assert(f.Runner.Done());
		Test.Assert(f.Told() == "keeper: Something stirs.\n");
		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "command fight\nended gate\n");
		Test.Assert(f.Host.LastCommand.Leaves);
		Test.Assert(f.Host.LastEnded.Left);
		Test.Assert(!f.Runner.IsPlaying);

		// The game comes back from the fight (a load between, say): the conversation goes on after it.
		let again = scope DialogueRunner(f.Settings, f.Host);
		f.Host.Runner = again;
		Test.Assert(again.Resume());
		Test.Assert(f.Told() == "keeper: You won.\n");
		Test.Assert(again.Advance());
		Test.Assert(f.Told() == "ended gate\n");
		Test.Assert(!again.Resume(), "nothing left to resume");
	}

	[Test]
	public static void AJumpWithinTheFileAndIntoAnother()
	{
		let f = scope Fixture();
		let lane = MakeGuid(10);
		f.Add(f.Gate, "conversation gate\n" +
			"@ keeper: This way.\n" +
			"jump path\n" +
			"conversation path\n" +
			"@ keeper: Along the path.\n" +
			"jump gate in lane\n");
		f.Add(lane, "conversation gate\n" + // the same id as the first file's: ids are a file's own
			"@ visitor: The lane's gate.\n");
		// The cook resolves `in lane` to the file's guid; here, by hand.
		f.Host.Files[f.Gate].Conversations[1].Steps[1].Asset = lane;

		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "keeper: This way.\nkeeper: Along the path.\n");
		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "visitor: The lane's gate.\n");
		Test.Assert(f.Host.LastLine.Dialogue == lane);
		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "ended gate\n");
		Test.Assert(f.Host.LastEnded.Dialogue == lane);
	}

	[Test]
	public static void ResumeAfterALoadAndAfterAPatchToTheConversation()
	{
		let f = scope Fixture();
		f.Add(f.Gate, "conversation gate\n" +
			"@ keeper: One.\n" +
			"@ keeper: Two. #line:two\n" +
			"@ keeper: Three.\n");
		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "keeper: One.\nkeeper: Two.\n");

		// Saved on the second line; loaded into a new run: the line shows again.
		{
			let loaded = scope DialogueRunner(f.Settings, f.Host);
			f.Host.Runner = loaded;
			Test.Assert(loaded.Resume());
			Test.Assert(f.Told() == "keeper: Two.\n");
			Test.Assert(!loaded.Resume(), "already playing");
		}

		// A patch inserts a line above it: the step moved, the line is found by its id.
		f.Add(f.Gate, "conversation gate\n" +
			"@ keeper: Zero.\n" +
			"@ keeper: One.\n" +
			"@ keeper: Two. #line:two\n" +
			"@ keeper: Three.\n");
		{
			let patched = scope DialogueRunner(f.Settings, f.Host);
			f.Host.Runner = patched;
			Test.Assert(patched.Resume());
			Test.Assert(f.Told() == "keeper: Two.\n");
		}

		// A patch that drops the line: the conversation starts again.
		f.Add(f.Gate, "conversation gate\n" +
			"@ keeper: Only this.\n");
		{
			let dropped = scope DialogueRunner(f.Settings, f.Host);
			f.Host.Runner = dropped;
			Test.Assert(dropped.Resume());
			Test.Assert(f.Told() == "keeper: Only this.\n");
		}
	}

	[Test]
	public static void OneConversationAtATimeAHostMayAnswerALineAtOnce()
	{
		let f = scope Fixture();
		f.Add(f.Gate, "conversation gate\n" +
			"@ keeper: One.\n" +
			"@ keeper: Two.\n" +
			"conversation other\n" +
			"@ visitor: Other.\n");
		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(!f.Runner.Play(f.Gate, "other"));
		Test.Assert(!f.Runner.Play(f.Gate, "missing"));
		f.Runner.Stop();
		f.Told();
		Test.Assert(!f.Runner.Play(f.Gate, "missing"));
		Test.Assert(!f.Runner.Play(MakeGuid(99), "gate"));

		f.Host.AdvanceAtOnce = true;
		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(f.Told() == "keeper: One.\nkeeper: Two.\nended gate\n");
		Test.Assert(!f.Runner.IsPlaying);
	}

	/// A file reloaded under a playing conversation (its old product gone) is the one the runner
	/// reads from then on.
	[Test]
	public static void AFileReplacedMidConversationIsReadAsItIsNow()
	{
		let f = scope Fixture();
		f.Add(f.Gate, "conversation gate\n" +
			"@ keeper: One.\n" +
			"@ keeper: Two.\n");
		Test.Assert(f.Runner.Play(f.Gate, "gate"));
		Test.Assert(f.Told() == "keeper: One.\n");
		f.Add(f.Gate, "conversation gate\n" +
			"@ keeper: One.\n" +
			"@ keeper: Two, reworded.\n");
		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "keeper: Two, reworded.\n");
		f.Add(f.Gate, "conversation elsewhere\n" +
			"@ keeper: Gone.\n");
		Test.Assert(f.Runner.Advance());
		Test.Assert(f.Told() == "ended gate\n", "its conversation gone: it ends");
		Test.Assert(!f.Runner.IsPlaying);
	}
}
