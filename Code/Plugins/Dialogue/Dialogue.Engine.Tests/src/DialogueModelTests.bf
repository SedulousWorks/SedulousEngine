using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Dialogue;

namespace Dialogue.Tests;

/// The compiled dialogue file and the cast: each reads back as written, a resource finds a
/// conversation and a line's text by id, a cast a speaker and a mood, and a speaker's fields are
/// reflected for the inspector.
class DialogueModelTests
{
	static void RoundTrip(ISerializable written, ISerializable read)
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			written.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		Test.Assert(stream.Seek(0, .Begin) == 0);
		let reader = scope BinarySerializer(stream, .Read);
		read.Serialize(reader);
		Test.Assert(reader.IsOk);
	}

	static Guid MakeGuid(uint8 seed) => Guid(seed, seed, 0, 0, 0, 0, 0, 0, 0, 0, seed);

	[Test]
	public static void ACompiledDialogueFileReadsBackAsItWasWritten()
	{
		let written = scope DialogueSource();
		written.Cast = MakeGuid(41);
		let talk = new DialogueConversation();
		written.Conversations.Add(talk);
		talk.Id.Set("gate_talk");
		talk.Level.Set("Levels/Village");
		let line = new DialogueStep(.Line);
		line.Speaker.Set("keeper");
		line.Mood.Set("worried");
		line.LineId.Set("gate_talk.1");
		line.SourceLine = 2;
		talk.Steps.Add(line);
		let test = new DialogueStep(.If);
		test.Flag.Set("met_keeper");
		test.Negate = true;
		test.Next = 4;
		talk.Steps.Add(test);
		let fade = new DialogueStep(.Fade);
		fade.Seconds = 1.5f;
		fade.HasColor = true;
		fade.Color = .(1.0f, 1.0f, 1.0f, 1.0f);
		talk.Steps.Add(fade);
		let command = new DialogueStep(.Command);
		command.Name.Set("move");
		command.Waits = true;
		let who = new DialogueArgument();
		who.Name.Set("who");
		who.Text.Set("Grey Cat");
		command.Arguments.Add(who);
		let running = new DialogueArgument();
		running.Name.Set("running");
		running.Present = true;
		command.Arguments.Add(running);
		talk.Steps.Add(command);
		talk.Steps.Add(new DialogueStep(.End));
		written.Lines.Add(new .("gate_talk.1", "The gate has been quiet since dawn."));

		let read = scope DialogueSource();
		RoundTrip(written, read);
		Test.Assert(read.Cast == written.Cast);
		Test.Assert(read.Conversations.Count == 1);
		let back = read.Conversations[0];
		Test.Assert((back.Id == "gate_talk") && (back.Level == "Levels/Village"));
		Test.Assert(back.Steps.Count == 5);
		Test.Assert(back.Steps[0].Kind == .Line);
		Test.Assert((back.Steps[0].Speaker == "keeper") && (back.Steps[0].Mood == "worried"));
		Test.Assert(back.Steps[0].SourceLine == 2);
		Test.Assert(back.Steps[1].Negate && (back.Steps[1].Next == 4));
		Test.Assert(Math.Abs(back.Steps[2].Seconds - 1.5f) < 1e-5f);
		Test.Assert(back.Steps[2].HasColor && (back.Steps[2].Color.X == 1.0f));
		Test.Assert(back.Steps[3].Waits && (back.Steps[3].Arguments.Count == 2));
		Test.Assert(back.Steps[3].Arguments[0].Text == "Grey Cat");
		Test.Assert(back.Steps[3].Arguments[1].Present);
		Test.Assert(back.Steps[4].Kind == .End);
		Test.Assert((read.Lines.Count == 1) && (read.Lines[0].Text == "The gate has been quiet since dawn."));
	}

	[Test]
	public static void AResourceFindsAConversationAndALinesTextById()
	{
		let resource = scope DialogueResource();
		let first = new DialogueConversation();
		first.Id.Set("first");
		resource.Conversations.Add(first);
		let second = new DialogueConversation();
		second.Id.Set("second");
		resource.Conversations.Add(second);
		resource.Lines.Add(new .("first.1", "Hello."));
		Test.Assert(resource.Find("second") === second);
		Test.Assert(resource.Find("third") == null);
		Test.Assert(resource.Text("first.1") == "Hello.");
		Test.Assert(resource.Text("first.2").IsEmpty);
	}

	[Test]
	public static void ACastReadsBackAsItWasWrittenAndFindsASpeakerAndAMood()
	{
		let written = scope DialogueCastSource();
		let keeper = new DialogueSpeaker();
		written.Speakers.Add(keeper);
		keeper.Id.Set("keeper");
		keeper.ShownName.Set("The Keeper");
		keeper.PlateColor = .(0.2f, 0.4f, 0.6f, 1.0f);
		keeper.Moods.Add(new .("neutral", .()));
		keeper.Moods.Add(new .("worried", MakeGuid(7)));
		keeper.Clips.Add(MakeGuid(8));
		keeper.Entity.Set("Keeper");
		let narrator = new DialogueSpeaker();
		narrator.Id.Set("narrator");
		narrator.Plate = false;
		written.Speakers.Add(narrator);

		let read = scope DialogueCastSource();
		RoundTrip(written, read);
		Test.Assert(read.Speakers.Count == 2);
		let back = read.Speakers[0];
		Test.Assert(back.ShownName == "The Keeper");
		Test.Assert(Math.Abs(back.PlateColor.Y - 0.4f) < 1e-5f);
		Test.Assert((back.Moods.Count == 2) && (back.Moods[1].Portrait == MakeGuid(7)));
		Test.Assert((back.Clips.Count == 1) && (back.Clips[0] == MakeGuid(8)));
		Test.Assert(back.Entity == "Keeper");
		Test.Assert(!read.Speakers[1].Plate);

		let cast = scope DialogueCastResource();
		Swap!(cast.Speakers, read.Speakers);
		Test.Assert(cast.Find("keeper") != null);
		Test.Assert(cast.Find("keeper").FindMood("worried") != null);
		Test.Assert(cast.Find("keeper").FindMood("angry") == null);
		Test.Assert(cast.Find("stranger") == null);
	}

	[Test]
	public static void ASpeakersFieldsAreReflectedForTheInspector()
	{
		String[?] names = .("Id", "ShownName", "Plate", "PlateColor", "Moods", "Portrait", "Clips", "Talk", "Voice", "Entity");
		for (let name in names)
			Test.Assert(typeof(DialogueSpeaker).GetField(name) case .Ok, name);
		Test.Assert(typeof(DialogueMood).GetField("Portrait") case .Ok);
	}
}
