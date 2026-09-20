using System;

namespace Sedulous.Editor.ViewportTools.Tests;

/// The activation state machine (first added is default and active, ActivateById round trip,
/// gesture end on switch), the availability fallback, routing of the consumed flag, and the
/// registry (explicit, idempotent, never the default).
static class ViewportToolManagerTests
{
	[Test]
	public static void TheFirstToolAddedIsTheDefaultAndStartsActive()
	{
		let manager = scope ViewportToolManager();
		Test.Assert(manager.ActiveTool == null);
		Test.Assert(!manager.Update(.()), "an empty manager consumes nothing");

		let logA = scope ToolLog();
		let a = manager.Add(new TestTool("select", logA));
		Test.Assert(a != null);
		Test.Assert(manager.ActiveTool === a);
		Test.Assert(logA.Activations == 1, "activated on Add, not lazily");

		let logB = scope ToolLog();
		let b = manager.Add(new TestTool("brush", logB));
		Test.Assert(manager.ActiveTool === a, "a later Add never steals activation");
		Test.Assert(logB.Activations == 0);
		Test.Assert(manager.Count == 2);
		Test.Assert(manager.FindById("brush") === b);
		Test.Assert(manager.FindById("nope") == null);
		Test.Assert(manager.ToolAt(1) === b);
		Test.Assert(manager.ToolAt(2) == null);
	}

	[Test]
	public static void ActivateByIdSwitchesWithTheGestureEndGuaranteeAndDefaultReturns()
	{
		let manager = scope ViewportToolManager();
		let logA = scope ToolLog();
		let logB = scope ToolLog();
		manager.Add(new TestTool("select", logA));
		let b = manager.Add(new TestTool("brush", logB));

		Test.Assert(manager.ActivateById("brush"));
		Test.Assert(manager.ActiveTool === b);
		Test.Assert(logA.Deactivations == 1, "the old tool ended its gesture before the new activated");
		Test.Assert(logB.Activations == 1);

		Test.Assert(manager.ActivateById("brush"), "re-activating the active tool is a no-op success");
		Test.Assert(logB.Activations == 1);
		Test.Assert(logB.Deactivations == 0);

		Test.Assert(!manager.ActivateById("unknown"), "unknown id: refused, state unchanged");
		Test.Assert(manager.ActiveTool === b);

		manager.ActivateDefault();
		Test.Assert(manager.ActiveTool.Id == "select");
		Test.Assert(logB.Deactivations == 1);
		Test.Assert(logA.Activations == 2);
	}

	[Test]
	public static void AnUnavailableToolIsRefusedAndALapsingActiveToolFallsBackBeforeItsNextUpdate()
	{
		let manager = scope ViewportToolManager();
		let logA = scope ToolLog();
		let logB = scope ToolLog();
		manager.Add(new TestTool("select", logA));
		let brush = (TestTool)manager.Add(new TestTool("brush", logB));

		brush.Available = false;
		Test.Assert(!manager.ActivateById("brush"), "unavailable: activation refused");

		brush.Available = true;
		Test.Assert(manager.ActivateById("brush"));
		brush.Available = false; // the terrain got deleted mid-session
		manager.Update(.());
		Test.Assert(manager.ActiveTool.Id == "select");
		Test.Assert(logB.Updates == 0, "the dead tool never saw another frame");
		Test.Assert(logB.Deactivations == 1);
		Test.Assert(logA.Updates == 1, "the default took the same frame");
	}

	[Test]
	public static void UpdateReturnsTheActiveToolsConsumedFlag()
	{
		let manager = scope ViewportToolManager();
		let log = scope ToolLog();
		let tool = (TestTool)manager.Add(new TestTool("select", log));
		Test.Assert(!manager.Update(.()));
		tool.Consume = true;
		Test.Assert(manager.Update(.()));
	}

	[Test]
	public static void TheProviderRegistryIsExplicitIdempotentAndNeverTheDefault()
	{
		// The registry is process-global: only relative effects are asserted, so the case
		// stays order-independent.
		let log = scope ToolLog();
		let provider = scope TestProvider(log);
		let before = ViewportToolProviderRegistry.Count;
		ViewportToolProviderRegistry.Register(provider);
		ViewportToolProviderRegistry.Register(provider); // duplicate: ignored
		Test.Assert(ViewportToolProviderRegistry.Count == before + 1);

		let manager = scope ViewportToolManager();
		let defaultLog = scope ToolLog();
		manager.Add(new TestTool("select", defaultLog));
		ViewportToolProviderRegistry.CreateAll(manager, .()); // null members: a bare host

		let provided = manager.FindById("provided");
		Test.Assert(provided != null);
		Test.Assert(manager.ActiveTool.Id == "select", "provider tools never default");
		Test.Assert(log.Activations == 0);
	}
}
