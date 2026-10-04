using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;
using Sedulous.Engine.UI.Script;

namespace Sedulous.Engine.UI.Script.Tests;

/// A run's Ui service resolves its run's stack at each call: the editor's Game tabs each have
/// their own screen tier, so two runs' scripts push onto their own stacks and find only their
/// own screens, and a service attached before its stack exists starts working once it does.
class UiRunStackTests
{
	[Test]
	public static void EachRunsServicePushesOntoItsOwnRunsStack()
	{
		let bed = scope UiScriptBed(); // its stack stands for the shared tier: nothing may land there
		let rootA = new RootView();
		let rootB = new RootView();
		bed.Context.AddRootView(rootA);
		bed.Context.AddRootView(rootB);
		let stackA = scope ScreenStack();
		let stackB = scope ScreenStack();
		stackA.Attach(rootA);
		stackB.Attach(rootB);
		defer
		{
			stackA.Clear();
			stackB.Clear();
			bed.Context.RemoveRootView(rootA);
			bed.Context.RemoveRootView(rootB);
			rootA.ReleaseRef();
			rootB.ReleaseRef();
		}

		// Run A's service is attached before its stack exists (the subsystem comes later).
		ScreenStack resolvedA = null;
		let uiA = scope UiScript();
		uiA.Attach(new [&resolvedA]() => resolvedA, new (id) => UiScriptBed.Screen("a"));
		let uiB = scope UiScript();
		uiB.Attach(new [=stackB]() => stackB, new (id) => UiScriptBed.Screen("b"));
		defer UiHandles.Clear();

		let document = Guid.Create();
		Test.Assert(!uiA.Push(document).IsValid, "no stack yet: nothing pushed");
		resolvedA = stackA;
		Test.Assert(uiA.Push(document).IsValid);
		Test.Assert((stackA.Count == 1) && (stackB.Count == 0));
		Test.Assert(uiB.Push(document).IsValid);
		Test.Assert(stackB.Count == 1);
		Test.Assert(bed.Stack.Count == 0, "nothing on the shared tier");

		// Each finds only its own run's screens.
		Test.Assert(uiA.Top.IsValid && uiB.Top.IsValid);
		Test.Assert(uiA.FindLabel("title").IsValid);
		Test.Assert(rootA.FindByName("a") != null);
		Test.Assert(rootA.FindByName("b") == null);
		Test.Assert(rootB.FindByName("b") != null);
	}
}
