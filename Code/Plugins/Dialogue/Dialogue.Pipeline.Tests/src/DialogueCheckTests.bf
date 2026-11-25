using System;
using System.Collections;
using Dialogue;

namespace Dialogue.Tests;

/// The cook's checks: speakers, moods and clips against the cast, assets by their names in the
/// dialogue assets with their types, flags, jumps and ids against the project's other files, and
/// what nothing reaches.
class DialogueCheckTests
{
	static Guid MakeGuid(uint8 seed) => Guid(seed, seed, 0, 0, 0, 0, 0, 0, 0, 0, seed);

	/// A project's assets: a name and a type for each, by guid.
	class TableAssets : IDialogueAssets
	{
		public List<(Guid id, String name, String type)> Entries = new .() ~ { for (let entry in _) { delete entry.name; delete entry.type; } delete _; };

		public Guid Add(StringView name, StringView type, uint8 seed)
		{
			let id = MakeGuid(seed);
			Entries.Add((id, new .(name), new .(type)));
			return id;
		}

		public void NameOf(Guid id, String outName)
		{
			for (let entry in Entries)
			{
				if (entry.id == id)
					outName.Append(entry.name);
			}
		}

		public void TypeOf(Guid id, String outType)
		{
			for (let entry in Entries)
			{
				if (entry.id == id)
					outType.Append(entry.type);
			}
		}
	}

	class Project
	{
		public TableAssets Assets = new .() ~ delete _;
		public List<DialogueSpeaker> Cast = new .() ~ DeleteContainerAndItems!(_);
		public List<DialogueAssetEntry> DialogueAssets = new .() ~ DeleteContainerAndItems!(_);
		public List<DialogueCommandForm> Commands = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Provided = new .() ~ DeleteContainerAndItems!(_);
		public List<String> OtherConversations = new .() ~ DeleteContainerAndItems!(_);
		public List<String> OtherLineIds = new .() ~ DeleteContainerAndItems!(_);
		public List<String> OtherFlagsSet = new .() ~ DeleteContainerAndItems!(_);
		public Guid Wave;
		public Guid Creak;
		public Guid GateOpen;
		public Guid Card;

		public this()
		{
			Wave = Assets.Add("Wave", "AnimationClipAsset", 1);
			let nod = Assets.Add("Nod", "AnimationClipAsset", 2);
			Creak = Assets.Add("Door Creak", "AudioClipAsset", 3);
			GateOpen = Assets.Add("Gate Open", "SequenceAsset", 4);
			Card = Assets.Add("Title", "TextureAsset", 5);
			DialogueAssets.Add(new .("door_creak", Creak));
			DialogueAssets.Add(new .("gate_open", GateOpen));
			DialogueAssets.Add(new .("title_card", Card));
			DialogueAssets.Add(new .("lost", MakeGuid(99))); // refers to nothing
			let keeper = new DialogueSpeaker();
			keeper.Id.Set("keeper");
			keeper.Moods.Add(new .("neutral", .()));
			keeper.Moods.Add(new .("worried", .()));
			keeper.Clips.Add(Wave);
			keeper.Clips.Add(nod);
			Cast.Add(keeper);
			let visitor = new DialogueSpeaker();
			visitor.Id.Set("visitor");
			Cast.Add(visitor);
			String[?] forms = .("show card <card:asset(TextureAsset)>", "greet <who:speaker>");
			let error = scope String();
			for (let text in forms)
			{
				let form = new DialogueCommandForm();
				Commands.Add(form);
				Test.Assert(DialogueFormat.ParseCommandForm(text, form, error), error);
			}
			Provided.Add(new .("seen_*"));
			Provided.Add(new .("has_lamp"));
			OtherConversations.Add(new .("farewell"));
			OtherLineIds.Add(new .("taken"));
			OtherFlagsSet.Add(new .("met_elsewhere"));
		}

		public void Check(StringView text, DialogueParse parse, bool withCast = true, bool withAssets = true)
		{
			DialogueFormat.ParseDialogue(text, (Span<DialogueCommandForm>)Commands, parse);
			let inputs = scope DialogueCheckInputs();
			inputs.Cast = withCast ? Cast : null;
			inputs.DialogueAssets = withAssets ? DialogueAssets : null;
			inputs.Commands = Commands;
			inputs.ProvidedFlags = Provided;
			inputs.OtherConversations = OtherConversations;
			inputs.OtherLineIds = OtherLineIds;
			inputs.OtherFlagsSet = OtherFlagsSet;
			inputs.Assets = Assets;
			DialogueChecks.CheckDialogue(parse, inputs);
		}
	}

	static bool HasProblem(DialogueParse parse, uint32 line, StringView words, bool warning = false)
	{
		for (let problem in parse.Problems)
		{
			if ((problem.Line == line) && (problem.Warning == warning) && problem.Message.Contains(words))
				return true;
		}
		return false;
	}

	static void RequireClean(DialogueParse parse)
	{
		for (let problem in parse.Problems)
			Console.WriteLine($"{problem.Line}: {problem.Message}");
		Test.Assert(parse.Problems.IsEmpty);
	}

	[Test]
	public static void AFileThatNamesOnlyWhatTheProjectHasIsCleanItsAssetsResolved()
	{
		let project = scope Project();
		let parse = scope DialogueParse();
		project.Check("conversation gate\n" +
			"@ keeper worried: Who goes there?\n" +
			"@ visitor: Only me.\n" +
			"play keeper Wave and wait\n" +
			"sound door_creak at keeper\n" +
			"sequence gate_open and wait\n" +
			"show card title_card\n" +
			"greet visitor\n" +
			"if seen_gate\n" +
			"  set met\n" +
			"end\n" +
			"if has_lamp\n" +
			"end\n" +
			"if met_elsewhere\n" +
			"end\n" +
			"if met\n" +
			"end\n" +
			"jump farewell\n", parse);
		RequireClean(parse);
		let steps = parse.Conversations[0].Steps;
		Test.Assert(steps[2].Asset == project.Wave);
		Test.Assert(steps[3].Asset == project.Creak);
		Test.Assert(steps[4].Asset == project.GateOpen);
		Test.Assert(steps[5].Arguments.Count == 1);
		Test.Assert(steps[5].Arguments[0].Asset == project.Card);
	}

	[Test]
	public static void WhatTheProjectDoesNotHaveEachAtItsLine()
	{
		let project = scope Project();
		let parse = scope DialogueParse();
		project.Check("conversation farewell\n" + // 1: another file has it
			"@ stranger: Hello.\n" + // 2
			"@ keeper angry: Leave.\n" + // 3
			"play keeper Dance\n" + // 4
			"play stranger Wave\n" + // 5
			"sound missing\n" + // 6
			"sound gate_open\n" + // 7: not a sound
			"sequence lost\n" + // 8: refers to nothing
			"show card door_creak\n" + // 9: not a texture
			"greet stranger\n" + // 10
			"if never_set\n" + // 11
			"end\n" + // 12
			"@ keeper: Taken. #line:taken\n" + // 13
			"jump nowhere\n", parse); // 14
		Test.Assert(HasProblem(parse, 1, "another dialogue file has a conversation"));
		Test.Assert(HasProblem(parse, 2, "no speaker `stranger`"));
		Test.Assert(HasProblem(parse, 3, "no mood `angry` (has neutral, worried)"));
		Test.Assert(HasProblem(parse, 4, "no clip `Dance` (has Wave, Nod)"));
		Test.Assert(HasProblem(parse, 5, "no speaker `stranger`"));
		Test.Assert(HasProblem(parse, 6, "no dialogue asset `missing`"));
		Test.Assert(HasProblem(parse, 7, "`gate_open` is of type SequenceAsset, which is no sound"));
		Test.Assert(HasProblem(parse, 8, "`lost` refers to no asset"));
		Test.Assert(HasProblem(parse, 9, "is of type AudioClipAsset, which is no TextureAsset"));
		Test.Assert(HasProblem(parse, 10, "no speaker `stranger`"));
		Test.Assert(HasProblem(parse, 11, "`never_set` is read but nothing sets it"));
		Test.Assert(HasProblem(parse, 13, "another dialogue file has a line `#line:taken`"));
		Test.Assert(HasProblem(parse, 14, "no conversation `nowhere`"));
		Test.Assert(!parse.Ok);
		for (int i = 1; i < parse.Problems.Count; i++)
			Test.Assert(parse.Problems[i - 1].Line <= parse.Problems[i].Line, "by line");
	}

	[Test]
	public static void WithNoDialogueAssetsTheFileIsToldOnce()
	{
		let project = scope Project();
		let parse = scope DialogueParse();
		project.Check("conversation bare\n" +
			"sound door_creak\n" +
			"sequence gate_open\n", parse, true, false);
		Test.Assert(parse.Problems.Count == 1);
		Test.Assert(HasProblem(parse, 2, "name no dialogue assets"));
	}

	[Test]
	public static void WithNoCastTheFileIsToldOnce()
	{
		let project = scope Project();
		let parse = scope DialogueParse();
		project.Check("conversation alone\n" +
			"@ keeper: One.\n" +
			"@ keeper: Two.\n", parse, false);
		Test.Assert(parse.Problems.Count == 1);
		Test.Assert(HasProblem(parse, 2, "name no cast"));
	}

	[Test]
	public static void WhatNothingReachesIsAWarningNotAnError()
	{
		let project = scope Project();
		let parse = scope DialogueParse();
		project.Check("conversation early\n" +
			"@ keeper: Off you go.\n" +
			"jump farewell\n" +
			"@ keeper: Never said.\n", parse);
		Test.Assert(parse.Ok);
		Test.Assert(HasProblem(parse, 4, "nothing reaches", true));
		Test.Assert(!HasProblem(parse, 2, "nothing reaches", true));
	}

	[Test]
	public static void WhatAFileGivesTheOthersChecksItsIdsWrittenAndItsFlags()
	{
		let parse = scope DialogueParse();
		DialogueFormat.ParseDialogue("conversation gate\n" +
			"@ keeper: Placed by its line.\n" +
			"@ keeper: Named. #line:gate_named\n" +
			"set met\n" +
			"if met\n" +
			"end\n", .(), parse);
		Test.Assert(parse.Ok);
		let conversations = scope List<String>();
		let lineIds = scope List<String>();
		let flagsSet = scope List<String>();
		let flagsRead = scope List<String>();
		defer
		{
			ClearAndDeleteItems!(conversations);
			ClearAndDeleteItems!(lineIds);
			ClearAndDeleteItems!(flagsSet);
			ClearAndDeleteItems!(flagsRead);
		}
		DialogueChecks.CollectDialogueFacts(parse, conversations, lineIds, flagsSet, flagsRead);
		Test.Assert((conversations.Count == 1) && (conversations[0] == "gate"));
		Test.Assert((lineIds.Count == 1) && (lineIds[0] == "gate_named"), "only the ids written, not those made from a line's place");
		Test.Assert((flagsSet.Count == 1) && (flagsSet[0] == "met"));
		Test.Assert((flagsRead.Count == 1) && (flagsRead[0] == "met"));
	}

	[Test]
	public static void AProvidedFlagByNameOrByPrefix()
	{
		String[?] provided = .("seen_*", "has_lamp");
		Test.Assert(DialogueChecks.IsProvidedFlag("seen_gate", provided));
		Test.Assert(DialogueChecks.IsProvidedFlag("seen_", provided));
		Test.Assert(DialogueChecks.IsProvidedFlag("has_lamp", provided));
		Test.Assert(!DialogueChecks.IsProvidedFlag("has_lamps", provided));
		Test.Assert(!DialogueChecks.IsProvidedFlag("unseen", provided));
	}
}
