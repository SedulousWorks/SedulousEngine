using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The log capture: full text, the category off the prefix, incremental polling by
/// sequence, and an honest dropped count when the ring overflows.
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
}
