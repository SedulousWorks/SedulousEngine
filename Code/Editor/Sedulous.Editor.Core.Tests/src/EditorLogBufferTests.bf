using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// The log capture: full text, the category off the prefix, incremental polling by
/// sequence, an honest dropped count when the ring overflows, the references a line carries, and
/// the recognizers that find more in its text.
static class EditorLogBufferTests
{
	[Test]
	public static void EntriesKeepTheirTextAndCategoryAndPollIncrementally()
	{
		let buffer = scope EditorLogBuffer(8);
		buffer.Log(.Information, "Cook: cooked {} of {}", 3, 4);
		buffer.Log(.Warning, "a line with no prefix, and a very long path /some/where/deep/inside/the/project/tree/file.png");
		buffer.Log(.Error, "Scene.Loader: not: a category");

		let all = scope List<EditorLogEntry>();
		defer { ClearAndDeleteItems(all); }
		let high = buffer.CollectSince(0, all);
		Test.Assert(all.Count == 3);
		Test.Assert(high == 3);
		Test.Assert((all[0].Category == "Cook") && (all[0].Message == "cooked 3 of 4") && (all[0].Sequence == 1));
		Test.Assert(all[1].Category.IsEmpty && all[1].Message.EndsWith("file.png"));
		Test.Assert((all[2].Category == "Scene.Loader") && (all[2].Message == "not: a category") && (all[2].Level == .Error));
		Test.Assert(buffer.LatestSequence == 3);
		// Each stamped with its time since the buffer was made, in order, and the copies carry it.
		Test.Assert(all[0].Time >= TimeSpan(0));
		Test.Assert((all[1].Time >= all[0].Time) && (all[2].Time >= all[1].Time));
		{
			// The clock moves: a line written later is stamped later, and the copy says so.
			let timed = scope EditorLogBuffer();
			timed.Write(.Information, "early");
			System.Threading.Thread.Sleep(20);
			timed.Write(.Information, "late");
			let stamped = scope List<EditorLogEntry>();
			defer { ClearAndDeleteItems(stamped); }
			timed.CollectSince(0, stamped);
			Test.Assert(stamped.Count == 2);
			Test.Assert(stamped[1].Time - stamped[0].Time >= TimeSpan.FromMilliseconds(15));
		}

		let newer = scope List<EditorLogEntry>();
		defer { ClearAndDeleteItems(newer); }
		Test.Assert(buffer.CollectSince(high, newer) == high);
		Test.Assert(newer.Count == 0, "nothing new since the high water");
		buffer.Write(.Information, "Agent: marker");
		Test.Assert(buffer.CollectSince(high, newer) == 4);
		Test.Assert((newer.Count == 1) && (newer[0].Category == "Agent"));
	}

	[Test]
	public static void OverflowDropsTheOldestAndSaysSo()
	{
		let buffer = scope EditorLogBuffer(3);
		for (int i < 5)
			buffer.Log(.Information, "line {}", i);
		Test.Assert(buffer.Count == 3);
		Test.Assert(buffer.DroppedCount == 2);
		let kept = scope List<EditorLogEntry>();
		defer { ClearAndDeleteItems(kept); }
		Test.Assert(buffer.CollectSince(0, kept) == 5);
		Test.Assert((kept.Count == 3) && (kept[0].Message == "line 2") && (kept[2].Message == "line 4"));
		Test.Assert(kept[0].Sequence == 3, "sequences keep advancing across the drop");
	}

	/// Added to the global composite, it captures what the engine logs through GlobalLog.
	[Test]
	public static void OnTheGlobalLoggerItCapturesLogOutput()
	{
		let buffer = new EditorLogBuffer(16);
		let composite = new CompositeLogger();
		composite.Add(buffer, true);
		InitGlobalLogger(composite, true);
		defer ShutdownGlobalLogger();
		GlobalLog(.Warning, "Cook: something {}", "happened");
		let entries = scope List<EditorLogEntry>();
		defer { ClearAndDeleteItems(entries); }
		Test.Assert(buffer.CollectSince(0, entries) == 1);
		Test.Assert((entries.Count == 1) && (entries[0].Category == "Cook") && (entries[0].Message == "something happened"));
	}

	/// Writers on several threads lose nothing and corrupt nothing: every sequence is
	/// present once and every message is whole.
	[Test]
	public static void ConcurrentWritersLoseNothing()
	{
		let buffer = scope EditorLogBuffer(1024);
		const int cThreads = 4;
		const int cPerThread = 100;
		let threads = scope List<System.Threading.Thread>();
		for (int t < cThreads)
		{
			let index = t;
			let thread = new System.Threading.Thread(new [=]() =>
				{
					for (int i < cPerThread)
						buffer.Log(.Information, "T{}: line {} of a message long enough to notice a tear", index, i);
				});
			threads.Add(thread);
			thread.Start(false);
		}
		for (let thread in threads)
		{
			thread.Join();
			delete thread;
		}
		let entries = scope List<EditorLogEntry>();
		defer { ClearAndDeleteItems(entries); }
		Test.Assert(buffer.CollectSince(0, entries) == cThreads * cPerThread);
		Test.Assert(entries.Count == cThreads * cPerThread);
		Test.Assert(buffer.DroppedCount == 0);
		for (int i < entries.Count)
		{
			Test.Assert(entries[i].Sequence == (uint64)(i + 1), "sequences are dense and ordered");
			Test.Assert(entries[i].Category.StartsWith("T") && entries[i].Message.EndsWith("a tear"), "whole");
		}
	}

	[Test]
	public static void AnEntryKeepsTheReferencesItsLogCallAttached()
	{
		let buffer = scope EditorLogBuffer(8);
		let source = LogReference.ForSource("/p/Code/A.as", 3);
		defer delete source;
		LogReference[1] carried = .(source);
		buffer.LogReferenced(.Warning, carried, "Script: a problem");
		buffer.Log(.Warning, "Script: no reference");

		let entries = scope List<EditorLogEntry>();
		defer { ClearAndDeleteItems(entries); }
		buffer.CollectSince(0, entries);
		Test.Assert(entries.Count == 2);
		Test.Assert(entries[0].References.Count == 1);
		Test.Assert(entries[0].References[0].Field(0) == "/p/Code/A.as");
		Test.Assert(entries[0].References[0] != source, "a copy");
		Test.Assert(entries[1].References.IsEmpty);
	}

	[Test]
	public static void PathsInTheProjectBecomeSourceReferencesWithTheirLineAndColumn()
	{
		let recognizers = scope LogReferenceRecognizers();
		recognizers.Add(LogReferenceRecognizers.SourcePath("/home/me/Game/"));

		// A compiler's file(line,col), with the part taking in the numbers.
		let build = "/home/me/Game/Code/Player.as(12,5): error: no 'speed'";
		let found = scope List<LogReference>();
		defer { ClearAndDeleteItems!(found); }
		recognizers.Recognize(build, found);
		Test.Assert(found.Count == 1);
		Test.Assert(found[0].Kind == LogReference.Source);
		Test.Assert(found[0].Field(0) == "/home/me/Game/Code/Player.as");
		Test.Assert(found[0].Field(1) == "12");
		Test.Assert(found[0].Field(2) == "5");
		Test.Assert(StringView(build, found[0].Start, found[0].Length) == "/home/me/Game/Code/Player.as(12,5)");

		// file:line:col, a path in the Code folder read under the project, a Windows path, and a
		// path that ends a sentence.
		ClearAndDeleteItems!(found);
		recognizers.Recognize("see Code/Enemies/Boss.as:7 and \\home\\me\\Game\\Sources\\a.png. Also /home/me/Game/x.as:3:9.", found);
		Test.Assert(found.Count == 3);
		Test.Assert(found[0].Field(0) == "/home/me/Game/Code/Enemies/Boss.as");
		Test.Assert(found[0].Field(1) == "7");
		Test.Assert(found[0].Field(2).IsEmpty);
		Test.Assert(found[1].Field(0) == "/home/me/Game/Sources/a.png");
		Test.Assert(found[1].Field(1).IsEmpty);
		Test.Assert(found[2].Field(0) == "/home/me/Game/x.as");
		Test.Assert(found[2].Field(2) == "9");

		// A path outside the project, and a word that only contains "Code/", are not.
		ClearAndDeleteItems!(found);
		recognizers.Recognize("/home/other/Game/Code/A.as:1 and MyCode/x.as", found);
		Test.Assert(found.IsEmpty);
	}

	[Test]
	public static void TheIdsOfKnownAssetsBecomeAssetReferencesOverlapsKeepTheFirst()
	{
		let known = Guid.Parse("0e9b3a52-1c1f-4c2e-9d3b-5a7f1e2d3c4b").Value;
		let recognizers = scope LogReferenceRecognizers();
		recognizers.Add(LogReferenceRecognizers.AssetId(new [=known] (id) => id == known));
		recognizers.Add(LogReferenceRecognizers.SourcePath("/p"));

		let message = "{0e9b3a52-1c1f-4c2e-9d3b-5a7f1e2d3c4b} reads /p/Code/a.as; 11111111-2222-3333-4444-555555555555 is unknown";
		let found = scope List<LogReference>();
		defer { ClearAndDeleteItems!(found); }
		recognizers.Recognize(message, found);
		Test.Assert(found.Count == 2);
		Test.Assert(found[0].Kind == LogReference.Asset);
		Test.Assert(found[0].Start == 0);
		Test.Assert(found[0].Length == 38); // the braces too
		Test.Assert(found[1].Kind == LogReference.Source);

		// A line's references: the attached first, then the recognized.
		let attached = LogReference.ForSource("/p/Code/b.as");
		defer delete attached;
		LogReference[1] carried = .(attached);
		let all = scope List<LogReference>();
		defer { ClearAndDeleteItems!(all); }
		recognizers.Of(message, carried, all);
		Test.Assert(all.Count == 3);
		Test.Assert(all[0].Field(0) == "/p/Code/b.as");
		Test.Assert(all[1].Kind == LogReference.Asset);

		// A path that a longer one already covers is dropped: the first, else the longer, is kept.
		let overlapping = scope LogReferenceRecognizers();
		overlapping.Add(LogReferenceRecognizers.SourcePath("/p"));
		overlapping.Add(LogReferenceRecognizers.SourcePath("/p/Code"));
		let one = scope List<LogReference>();
		defer { ClearAndDeleteItems!(one); }
		overlapping.Recognize("at /p/Code/a.as:4", one);
		Test.Assert((one.Count == 1) && (one[0].Field(0) == "/p/Code/a.as") && (one[0].Field(1) == "4"));
	}

	/// A script's problems name their file by its source path under Code/, as the AngelScript
	/// runtime writes them: a compile error's place, and each frame of a fault's stack, link to the
	/// file at the line. A recognized place over an attached reference's part links once.
	[Test]
	public static void AScriptsProblemsLinkToTheFileAtTheLine()
	{
		let recognizers = scope LogReferenceRecognizers();
		recognizers.Add(LogReferenceRecognizers.SourcePath("/home/me/Game"));
		let found = scope List<LogReference>();
		defer { ClearAndDeleteItems!(found); }

		recognizers.Recognize("Code/Scripts/Player.as(12,4): error: 'speed' is not declared", found);
		Test.Assert(found.Count == 1);
		Test.Assert(found[0].Field(0) == "/home/me/Game/Code/Scripts/Player.as");
		Test.Assert((found[0].Field(1) == "12") && (found[0].Field(2) == "4"));

		ClearAndDeleteItems!(found);
		recognizers.Recognize("Code/Scripts/Player.as(7,1): exception: Null pointer access\n  at void Player::onUpdate(float) (Code/Scripts/Player.as:7)\n  at void Base::tick() (Code/Scripts/Base.as:30)", found);
		Test.Assert(found.Count == 3);
		Test.Assert(found[1].Field(0) == "/home/me/Game/Code/Scripts/Player.as" && (found[1].Field(1) == "7"));
		Test.Assert(found[2].Field(0) == "/home/me/Game/Code/Scripts/Base.as" && (found[2].Field(1) == "30"));

		// An attached reference over a part: the recognized one there is dropped.
		let message = "Code/Scripts/Player.as:12: bad";
		let attached = LogReference.ForSource("Code/Scripts/Player.as", 12);
		defer delete attached;
		attached.Length = 25;
		LogReference[1] carried = .(attached);
		let all = scope List<LogReference>();
		defer { ClearAndDeleteItems!(all); }
		recognizers.Of(message, carried, all);
		Test.Assert(all.Count == 1);
		Test.Assert(all[0].Field(0) == "Code/Scripts/Player.as");
	}
}
