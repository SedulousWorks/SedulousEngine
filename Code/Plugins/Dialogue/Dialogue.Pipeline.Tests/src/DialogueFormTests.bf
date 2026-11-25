using System;
using Dialogue;

namespace Dialogue.Tests;

/// A declared command's form: its literal words, arguments and optional parts, every kind, a
/// default, how it waits, and what is not a form, refused with why.
class DialogueFormTests
{
	static DialogueCommandForm Parsed(StringView text, DialogueCommandForm form)
	{
		let error = scope String();
		Test.Assert(DialogueFormat.ParseCommandForm(text, form, error), error);
		return form;
	}

	static void Refusal(StringView text, String error)
	{
		let form = scope DialogueCommandForm();
		Test.Assert(!DialogueFormat.ParseCommandForm(text, form, error), scope String(text));
		Test.Assert(!error.IsEmpty, scope String(text));
	}

	[Test]
	public static void AFormsLiteralWordsArgumentsAndOptionalParts()
	{
		let move = Parsed("move <who:entity> to <target:entity> [running] [and wait]", scope .());
		Test.Assert(move.Name == "move");
		Test.Assert(move.Wait == .Never);
		Test.Assert((move.GroupCount == 2) && (move.WaitGroup == 2));
		Test.Assert(move.Parts.Count == 7);
		Test.Assert(move.Parts[0].Literal);
		Test.Assert(!move.Parts[1].Literal);
		Test.Assert(move.Parts[1].Name == "who");
		Test.Assert(move.Parts[1].Kind == .Entity);
		Test.Assert(move.Parts[2].Word == "to");
		Test.Assert(move.Parts[4].Word == "running");
		Test.Assert(move.Parts[4].Group == 1);
	}

	[Test]
	public static void EveryKindADefaultAndHowACommandWaits()
	{
		let camera = Parsed("camera <target:entity> [for <seconds:number=2>]", scope .());
		Test.Assert(camera.Parts.Count == 4);
		Test.Assert(camera.Parts[3].Kind == .Number);
		Test.Assert(camera.Parts[3].HasDefault);
		Test.Assert(camera.Parts[3].DefaultValue == "2");

		let shake = Parsed("shake <how:gentle|strong|violent>", scope .());
		Test.Assert(shake.Parts[1].Choices.Count == 3);
		Test.Assert(shake.Parts[1].Kind == .OneOf);
		Test.Assert(shake.Parts[1].Choices[2] == "violent");

		let fight = Parsed("fight <foe:list(foes)> leaves", scope .());
		Test.Assert(fight.Wait == .Leaves);
		Test.Assert(fight.Parts[1].Kind == .List);
		Test.Assert(fight.Parts[1].ListName == "foes");

		let show = Parsed("show card <card:asset(TextureAsset)> waits", scope .());
		Test.Assert(show.Name == "show card");
		Test.Assert(show.Wait == .Always);
		Test.Assert(show.Parts[2].Kind == .Asset);
		Test.Assert(show.Parts[2].AssetType == "TextureAsset");

		let note = Parsed("note <who:speaker> <what:flag> <tag:word> <text:text>", scope .());
		Test.Assert(note.Parts[1].Kind == .Speaker);
		Test.Assert(note.Parts[2].Kind == .Flag);
		Test.Assert(note.Parts[3].Kind == .Word);
		Test.Assert(note.Parts[4].Kind == .Text);
	}

	[Test]
	public static void WhatIsNotAFormIsRefusedAndWhy()
	{
		String[?] refused = .(
			"",
			"<who:entity> waves", // no name first
			"wave [at <who:entity>", // a group not closed
			"wave at <who:entity>]", // a close with nothing open
			"wave [at [<who:entity>]]", // a group in a group
			"wave []", // an empty group
			"wave <who>", // no kind
			"wave <who:person>", // an unknown kind
			"wave <who:entity", // an argument not closed
			"wave <a b:entity>", // a name of two words
			"wave <who:entity> <who:entity>", // two of one name
			"wave <how:slow|>", // an empty choice
			"wave <who:entity=Cat>", // a default outside an optional part
			"wave [for <s:number=soon>]", // a number's default not a number
			"wave [and wait] waits", // waits two ways
			"@ <who:speaker>");
		for (let text in refused)
			Refusal(text, scope .());
		// A group opened inside another is refused for itself, not for a stray `]` after it.
		let nested = scope String();
		Refusal("wave [at [<who:entity>]", nested);
		Test.Assert(nested.Contains("holds no other"));
		let builtIn = scope String();
		Refusal("play <who:entity> loudly", builtIn);
		Test.Assert(builtIn.Contains("play"));
	}
}
