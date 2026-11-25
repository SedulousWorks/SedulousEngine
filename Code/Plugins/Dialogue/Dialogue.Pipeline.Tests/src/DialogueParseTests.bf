using System;
using System.Collections;
using Dialogue;

namespace Dialogue.Tests;

/// A dialogue file's text into conversations: lines, choices and ifs compiled to jumps, the
/// built-in statements, declared commands matched by their forms, and every problem at its line.
class DialogueParseTests
{
	static void Parse(StringView text, DialogueParse parse)
	{
		String[?] texts = .(
			"move <who:entity> to <target:entity> [running] [and wait]",
			"camera <target:entity> [for <seconds:number=2>]",
			"shake <how:gentle|strong|violent> [for <seconds:number=1>]",
			"fight <foe:list(foes)> leaves",
			"give item <item:list(items)> [<count:number=1>]",
			"give coins <purse:copper|silver|gold> <count:number>",
			"cue <event:text> waits");
		let forms = scope List<DialogueCommandForm>();
		defer { ClearAndDeleteItems!(forms); }
		let error = scope String();
		for (let form in texts)
		{
			let parsed = new DialogueCommandForm();
			forms.Add(parsed);
			Test.Assert(DialogueFormat.ParseCommandForm(form, parsed, error), error);
		}
		DialogueFormat.ParseDialogue(text, (Span<DialogueCommandForm>)forms, parse);
	}

	/// The one conversation of a file that must parse cleanly.
	static DialogueConversation Only(DialogueParse parse)
	{
		for (let problem in parse.Problems)
			Console.WriteLine($"{problem.Line}: {problem.Message}");
		Test.Assert(parse.Ok);
		Test.Assert(parse.Conversations.Count == 1);
		return parse.Conversations[0];
	}

	static DialogueArgument Argument(DialogueStep step, StringView name)
	{
		for (let argument in step.Arguments)
		{
			if (argument.Name == name)
				return argument;
		}
		Test.Assert(false, scope $"no argument {name}");
		return null;
	}

	/// Whether a problem at `line` says something containing `words`.
	static bool HasProblem(DialogueParse parse, uint32 line, StringView words)
	{
		for (let problem in parse.Problems)
		{
			if ((problem.Line == line) && problem.Message.Contains(words))
				return true;
		}
		return false;
	}

	static StringView Text(DialogueParse parse, StringView id)
	{
		for (let line in parse.Lines)
		{
			if (line.Id == id)
				return line.Text;
		}
		return "";
	}

	static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	[Test]
	public static void LinesWithASpeakerAndAMoodCommentsAndBlankLinesLeftOut()
	{
		let parse = scope DialogueParse();
		Parse("# the keeper at the gate\n" +
			"conversation gate_talk\n" +
			"\n" +
			"@ keeper worried: The gate has been quiet since dawn.\n" +
			"   @ visitor: Press {Interact} to knock. #1 on the list.\n" +
			"@ keeper: Time: half past. #line:keeper_time\n", parse);
		let talk = Only(parse);
		Test.Assert(talk.Id == "gate_talk");
		Test.Assert(talk.Level.IsEmpty);
		Test.Assert(talk.Steps.Count == 4);
		Test.Assert(talk.Steps[0].Kind == .Line);
		Test.Assert(talk.Steps[0].Speaker == "keeper");
		Test.Assert(talk.Steps[0].Mood == "worried");
		Test.Assert(talk.Steps[0].LineId == "gate_talk.1");
		Test.Assert(talk.Steps[0].SourceLine == 4);
		Test.Assert(talk.Steps[1].Mood.IsEmpty);
		Test.Assert(talk.Steps[2].LineId == "keeper_time");
		Test.Assert(talk.Steps[3].Kind == .End);
		Test.Assert(Text(parse, "gate_talk.1") == "The gate has been quiet since dawn.");
		Test.Assert(Text(parse, "gate_talk.2") == "Press {Interact} to knock. #1 on the list.");
		Test.Assert(Text(parse, "keeper_time") == "Time: half past.");
	}

	[Test]
	public static void AConversationNamesItsLevelAndAFileHoldsSeveral()
	{
		let parse = scope DialogueParse();
		Parse("conversation first in village\n" +
			"@ keeper: One.\n" +
			"conversation second\n" +
			"@ keeper: Two.\n", parse);
		Test.Assert(parse.Ok);
		Test.Assert(parse.Conversations.Count == 2);
		Test.Assert(parse.Conversations[0].Level == "village");
		Test.Assert(parse.Conversations[1].Steps[0].LineId == "second.1");

		// The level is a dialogue asset's name, one word; nothing else follows `in`.
		let spaced = scope DialogueParse();
		Parse("conversation square in Old Village\n" +
			"@ keeper: Here.\n" +
			"conversation alone in\n", spaced);
		Test.Assert(HasProblem(spaced, 1, "the level a dialogue asset's name"));
		Test.Assert(HasProblem(spaced, 3, "the level a dialogue asset's name"));
	}

	[Test]
	public static void AChoiceCompilesToItsAnswersTableThenEachAnswersStatements()
	{
		let parse = scope DialogueParse();
		Parse("conversation ask\n" +
			"choice\n" +
			"  > Who are you?\n" +
			"    @ keeper: The keeper.\n" +
			"  > Goodbye. #line:bye\n" +
			"end\n" +
			"@ keeper: Well then.\n", parse);
		let ask = Only(parse);
		// Choice, Answer, Answer, [Line, Skip], [Skip], Line, End
		Test.Assert(ask.Steps.Count == 8);
		Test.Assert(ask.Steps[0].Kind == .Choice);
		Test.Assert(ask.Steps[0].Count == 2);
		Test.Assert(ask.Steps[1].Kind == .Answer);
		Test.Assert(ask.Steps[1].LineId == "ask.1");
		Test.Assert(ask.Steps[1].Next == 3);
		Test.Assert(ask.Steps[2].LineId == "bye");
		Test.Assert(ask.Steps[2].Next == 5);
		Test.Assert(ask.Steps[3].Kind == .Line);
		Test.Assert(ask.Steps[3].LineId == "ask.2");
		Test.Assert(ask.Steps[4].Kind == .Skip);
		Test.Assert(ask.Steps[4].Next == 6);
		Test.Assert(ask.Steps[5].Kind == .Skip);
		Test.Assert(ask.Steps[5].Next == 6);
		Test.Assert(ask.Steps[6].Kind == .Line);
		Test.Assert(Text(parse, "ask.1") == "Who are you?");
		Test.Assert(Text(parse, "bye") == "Goodbye.");
	}

	[Test]
	public static void AnIfWithAndWithoutElseAndBlocksNestedInAnAnswer()
	{
		let parse = scope DialogueParse();
		Parse("conversation branch\n" +
			"if not met\n" +
			"  set met\n" +
			"else\n" +
			"  clear met\n" +
			"end\n" +
			"choice\n" +
			"> Ask\n" +
			"  if met\n" +
			"    @ keeper: Again?\n" +
			"  end\n" +
			"end\n", parse);
		let branch = Only(parse);
		// 0 If, 1 Set, 2 Skip, 3 Clear, 4 Choice, 5 Answer, 6 If, 7 Line, 8 Skip, 9 End
		Test.Assert(branch.Steps.Count == 10);
		Test.Assert(branch.Steps[0].Kind == .If);
		Test.Assert(branch.Steps[0].Negate);
		Test.Assert(branch.Steps[0].Flag == "met");
		Test.Assert(branch.Steps[0].Next == 3, "to the else side");
		Test.Assert(branch.Steps[1].Kind == .Set);
		Test.Assert(branch.Steps[2].Kind == .Skip);
		Test.Assert(branch.Steps[2].Next == 4, "past the else side");
		Test.Assert(branch.Steps[3].Kind == .Clear);
		Test.Assert(branch.Steps[5].Next == 6);
		Test.Assert(branch.Steps[6].Kind == .If);
		Test.Assert(!branch.Steps[6].Negate);
		Test.Assert(branch.Steps[6].Next == 8, "the answer's if, moved to where its answer starts");
		Test.Assert(branch.Steps[8].Kind == .Skip);
		Test.Assert(branch.Steps[8].Next == 9);
	}

	[Test]
	public static void TheBuiltInStatements()
	{
		let parse = scope DialogueParse();
		Parse("conversation staged\n" +
			"wait 1.5\n" +
			"play keeper Wave Hello and wait\n" +
			"play keeper Nod\n" +
			"sound door_creak at keeper\n" +
			"sound wind\n" +
			"fade out\n" +
			"fade in for 0.5 #FFFFFF\n" +
			"sequence gate_open and wait\n" +
			"jump farewell\n" +
			"jump farewell in farewells\n", parse);
		let staged = Only(parse);
		Test.Assert(staged.Steps.Count == 11);
		Test.Assert(staged.Steps[0].Kind == .Wait);
		Test.Assert(Near(staged.Steps[0].Seconds, 1.5f));
		Test.Assert(staged.Steps[1].Kind == .Play);
		Test.Assert(staged.Steps[1].Speaker == "keeper");
		Test.Assert(staged.Steps[1].Name == "Wave Hello");
		Test.Assert(staged.Steps[1].Waits);
		Test.Assert(!staged.Steps[2].Waits);
		Test.Assert(staged.Steps[3].Kind == .Sound);
		Test.Assert(staged.Steps[3].Name == "door_creak");
		Test.Assert(staged.Steps[3].Speaker == "keeper");
		Test.Assert(staged.Steps[4].Speaker.IsEmpty);
		Test.Assert(staged.Steps[5].Kind == .Fade);
		Test.Assert(!staged.Steps[5].FadeIn);
		Test.Assert(staged.Steps[5].Seconds < 0.0f, "the settings' length");
		Test.Assert(!staged.Steps[5].HasColor);
		Test.Assert(staged.Steps[6].FadeIn);
		Test.Assert(Near(staged.Steps[6].Seconds, 0.5f));
		Test.Assert(staged.Steps[6].HasColor);
		Test.Assert(Near(staged.Steps[6].Color.Z, 1.0f));
		Test.Assert(Near(staged.Steps[6].Color.W, 1.0f), "#RRGGBB is opaque");
		Test.Assert(staged.Steps[7].Kind == .Sequence);
		Test.Assert(staged.Steps[7].Name == "gate_open");
		Test.Assert(staged.Steps[7].Waits);
		Test.Assert(staged.Steps[8].Kind == .Jump);
		Test.Assert(staged.Steps[8].Name == "farewell");
		Test.Assert(staged.Steps[8].File.IsEmpty);
		Test.Assert(staged.Steps[9].Kind == .Jump);
		Test.Assert(staged.Steps[9].Name == "farewell");
		Test.Assert(staged.Steps[9].File == "farewells");
	}

	[Test]
	public static void ADeclaredCommandsArgumentsRunToTheNextLiteralWord()
	{
		let parse = scope DialogueParse();
		Parse("conversation walk\n" +
			"move Grey Cat to Player running and wait\n" +
			"move Player to Old Well 01\n" +
			"camera Old Well 01 for 2.5\n" +
			"camera Garden Gate\n" +
			"move Player to \"Path to Mill\"\n" +
			"move \"Path to Mill\" to Player\n", parse);
		let walk = Only(parse);
		Test.Assert(walk.Steps.Count == 7);
		let cat = walk.Steps[0];
		Test.Assert(cat.Kind == .Command);
		Test.Assert(cat.Name == "move");
		Test.Assert(Argument(cat, "who").Text == "Grey Cat");
		Test.Assert(Argument(cat, "target").Text == "Player");
		Test.Assert(Argument(cat, "running").Present);
		Test.Assert(cat.Waits);
		let well = walk.Steps[1];
		Test.Assert(Argument(well, "target").Text == "Old Well 01");
		Test.Assert(!Argument(well, "running").Present);
		Test.Assert(!well.Waits);
		Test.Assert(Argument(walk.Steps[2], "target").Text == "Old Well 01");
		Test.Assert(Near(Argument(walk.Steps[2], "seconds").Number, 2.5f));
		Test.Assert(Near(Argument(walk.Steps[3], "seconds").Number, 2.0f), "the default");
		Test.Assert(!Argument(walk.Steps[3], "seconds").Present);
		Test.Assert(Argument(walk.Steps[4], "target").Text == "Path to Mill");
		Test.Assert(Argument(walk.Steps[5], "who").Text == "Path to Mill");
	}

	[Test]
	public static void CommandsOfTwoWordsChoicesAndHowACommandWaitsOrLeaves()
	{
		let parse = scope DialogueParse();
		Parse("conversation reward\n" +
			"give item Brass Key\n" +
			"give item Apple 3\n" +
			"give coins silver 12\n" +
			"shake strong\n" +
			"cue lights dim\n" +
			"fight Grey Wolf\n", parse);
		let reward = Only(parse);
		Test.Assert(reward.Steps.Count == 7);
		Test.Assert(reward.Steps[0].Name == "give item");
		Test.Assert(Argument(reward.Steps[0], "item").Text == "Brass Key");
		Test.Assert(Near(Argument(reward.Steps[0], "count").Number, 1.0f));
		// The fewest words that let the rest match: the optional count takes the 3.
		Test.Assert(Argument(reward.Steps[1], "item").Text == "Apple");
		Test.Assert(Near(Argument(reward.Steps[1], "count").Number, 3.0f));
		Test.Assert(reward.Steps[2].Name == "give coins");
		Test.Assert(Argument(reward.Steps[2], "purse").Text == "silver");
		Test.Assert(Near(Argument(reward.Steps[2], "count").Number, 12.0f));
		Test.Assert(Argument(reward.Steps[3], "how").Text == "strong");
		Test.Assert(reward.Steps[4].Waits);
		Test.Assert(Argument(reward.Steps[4], "event").Text == "lights dim");
		Test.Assert(reward.Steps[5].Leaves);
		Test.Assert(!reward.Steps[5].Waits);
	}

	[Test]
	public static void AQuotedWordIsNeverAFormsLiteralWord()
	{
		let parse = scope DialogueParse();
		Parse("conversation quoted\n" +
			"move Player \"to\" Old Well\n", parse);
		Test.Assert(!parse.Ok);
		Test.Assert(HasProblem(parse, 2, "the nearest is `move"));
	}

	[Test]
	public static void AJumpNamesAnotherFileByOneWord()
	{
		let parse = scope DialogueParse();
		Parse("conversation gate\n" +
			"jump farewell in far-wells\n", parse);
		Test.Assert(HasProblem(parse, 2, "names a dialogue file by its dialogue asset's name, a word"));
	}

	[Test]
	public static void EveryProblemAtItsLine()
	{
		let parse = scope DialogueParse();
		Parse("@ keeper: Before any conversation.\n" + // 1
			"conversation trouble\n" + // 2
			"@ keeper Hello there\n" + // 3: no colon
			"@ keeper:\n" + // 4: says nothing
			"@ two words here: Hi\n" + // 5: three words
			"> An answer alone\n" + // 6
			"else\n" + // 7
			"end\n" + // 8
			"choice\n" + // 9: no answers
			"end\n" + // 10
			"wait soon\n" + // 11
			"fade sideways\n" + // 12
			"fade in #12345\n" + // 13
			"shake wildly\n" + // 14
			"dance a jig\n" + // 15
			"move Player to \"Unclosed\n" + // 16
			"if\n" + // 17
			"end\n" + // 18
			"choice\n" + // 19: not closed
			"> Leave\n" + // 20
			"conversation trouble\n" + // 21: a second
			"if met\n" + // 22: not closed
			"@ keeper: Hi. #line:same\n" + // 23
			"@ keeper: Hi. #line:same\n", parse); // 24
		Test.Assert(!parse.Ok);
		Test.Assert(HasProblem(parse, 1, "before any"));
		Test.Assert(HasProblem(parse, 3, "a line is"));
		Test.Assert(HasProblem(parse, 4, "says nothing"));
		Test.Assert(HasProblem(parse, 5, "a line is"));
		Test.Assert(HasProblem(parse, 6, "outside a choice"));
		Test.Assert(HasProblem(parse, 7, "outside an `if`"));
		Test.Assert(HasProblem(parse, 8, "nothing open"));
		Test.Assert(HasProblem(parse, 9, "needs"));
		Test.Assert(HasProblem(parse, 11, "`wait` is"));
		Test.Assert(HasProblem(parse, 12, "`fade` is"));
		Test.Assert(HasProblem(parse, 13, "colour"));
		Test.Assert(HasProblem(parse, 14, "the nearest is `shake"));
		Test.Assert(HasProblem(parse, 15, "`dance` is no statement"));
		Test.Assert(HasProblem(parse, 16, "quote"));
		Test.Assert(HasProblem(parse, 17, "`if [not] <flag>`"));
		Test.Assert(HasProblem(parse, 19, "not closed by `end`"));
		Test.Assert(HasProblem(parse, 21, "a second conversation"));
		Test.Assert(HasProblem(parse, 22, "not closed by `end`"));
		Test.Assert(HasProblem(parse, 24, "a second line"));
		for (int i = 1; i < parse.Problems.Count; i++)
			Test.Assert(parse.Problems[i - 1].Line <= parse.Problems[i].Line);
	}

	[Test]
	public static void AnEmptyFileHasNothingAndNoProblem()
	{
		let parse = scope DialogueParse();
		Parse("# nothing yet\n\n", parse);
		Test.Assert(parse.Ok);
		Test.Assert(parse.Conversations.IsEmpty);
	}
}
