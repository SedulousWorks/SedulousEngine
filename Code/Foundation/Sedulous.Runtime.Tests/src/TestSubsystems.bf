using System;
using System.Collections;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

/// A shared log every test subsystem writes into, so ORDER can be asserted rather than
/// just the fact that something happened.
static class Trace
{
	public static List<String> Lines = new .() ~ DeleteContainerAndItems!(_);

	public static void Clear()
	{
		for (let line in Lines)
			delete line;
		Lines.Clear();
	}

	public static void Add(StringView line) => Lines.Add(new String(line));

	public static bool Has(StringView line)
	{
		for (let entry in Lines)
			if (entry == line)
				return true;
		return false;
	}

	public static int IndexOf(StringView line)
	{
		for (int i < Lines.Count)
			if (Lines[i] == line)
				return i;
		return -1;
	}

	/// True only when BOTH lines are present and `first` came before `second`.
	///
	/// Comparing IndexOf results directly is a trap: a missing line reads as -1, which
	/// compares as "earliest", so an ordering assertion passes precisely when the step it
	/// was checking never happened at all.
	public static bool Before(StringView first, StringView second)
	{
		let a = IndexOf(first);
		let b = IndexOf(second);
		if ((a < 0) || (b < 0))
			return false;
		return a < b;
	}

	public static void Join(String outText)
	{
		for (let line in Lines)
		{
			if (!outText.IsEmpty)
				outText.Append(',');
			outText.Append(line);
		}
	}
}

class Recording : Subsystem
{
	public String Label = new .() ~ delete _;
	private int32 mOrder;

	public int32 Inits;
	public int32 Readies;
	public int32 Shutdowns;
	public int32 Updates;

	public this(StringView label, int32 order = 0)
	{
		Label.Set(label);
		mOrder = order;
	}

	public override int32 UpdateOrder => mOrder;

	protected override void OnInit() { Inits++; Trace.Add(scope $"{Label}.init"); }
	protected override void OnReady() { Readies++; Trace.Add(scope $"{Label}.ready"); }
	protected override void OnPrepareShutdown() { Trace.Add(scope $"{Label}.prepare"); }
	protected override void OnShutdown() { Shutdowns++; Trace.Add(scope $"{Label}.shutdown"); }

	public override void BeginFrame(float dt) { Trace.Add(scope $"{Label}.begin"); }
	public override void Update(float dt) { Updates++; Trace.Add(scope $"{Label}.update"); }
	public override void PostUpdate(float dt) { Trace.Add(scope $"{Label}.post"); }
	public override void EndFrame() { Trace.Add(scope $"{Label}.end"); }
}

class Early : Recording
{
	public this() : base("early", -10) {}
}

class Middle : Recording
{
	public this() : base("middle", 0) {}
}

class Late : Recording
{
	public this() : base("late", 10) {}
}
