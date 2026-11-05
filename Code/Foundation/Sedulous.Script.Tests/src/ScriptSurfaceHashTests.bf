using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Script.Tests;

/// The hash a script product's recipe carries: it moves when a runtime type joins, leaves or
/// changes its members, not with the order the types were added in, and not for a type of another
/// domain (which no player has), so every host that cooks agrees on it.
static class ScriptSurfaceHashTests
{
	private static void AddRuntime(ScriptSurface surface, StringView name)
	{
		let t = surface.AddType(name, .Class, ScriptDomains.Runtime);
		t.AddField("speed", "float");
	}

	/// A plugin's types join a surface tagged with the plugin and leave with it, the revision
	/// moving each time; one already there (a leak, or another plugin's of the name) refuses the
	/// lot, nothing moved.
	[Test]
	public static void APluginsTypesJoinTaggedLeaveWithItAndALeakRefusesThem()
	{
		let surface = scope ScriptSurface();
		AddRuntime(surface, "Game.Mover");
		let before = surface.RuntimeHash();
		let revision = surface.Revision;
		{
			let published = scope ScriptSurface();
			AddRuntime(published, "Plug.Spin");
			AddRuntime(published, "Plug.Wobble");
			let why = scope String();
			Test.Assert(surface.AddPluginTypes("plug", published, why), why);
			Test.Assert(published.Types.IsEmpty, "moved, not copied");
		}
		Test.Assert((surface.Find("Plug.Spin") != null) && (surface.Find("Plug.Spin").Plugin == "plug"));
		Test.Assert(surface.Find("Game.Mover").Plugin.IsEmpty, "the engine's");
		Test.Assert((surface.Revision != revision) && (surface.RuntimeHash() != before));
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		surface.PluginTypes("plug", names);
		Test.Assert(names.Count == 2);

		{
			let again = scope ScriptSurface();
			AddRuntime(again, "Plug.Other");
			AddRuntime(again, "Plug.Spin");
			let why = scope String();
			Test.Assert(!surface.AddPluginTypes("plug2", again, why));
			Test.Assert(why.Contains("Plug.Spin") && why.Contains("plugin 'plug''s"), why);
			Test.Assert(surface.Find("Plug.Other") == null, "nothing moved");
		}

		Test.Assert(surface.RemovePluginTypes("plug") == 2);
		Test.Assert((surface.Find("Plug.Spin") == null) && (surface.RuntimeHash() == before), "as it was");
		Test.Assert(surface.Types.Count == 1);
	}

	[Test]
	public static void TheHashFollowsTheRuntimeTypesInAnyOrder()
	{
		let one = scope ScriptSurface();
		AddRuntime(one, "Game.Mover");
		let alone = one.RuntimeHash();
		AddRuntime(one, "Game.Jumper");
		let both = one.RuntimeHash();
		Test.Assert(alone != both, "a type joined");

		let other = scope ScriptSurface();
		AddRuntime(other, "Game.Jumper");
		AddRuntime(other, "Game.Mover");
		Test.Assert(other.RuntimeHash() == both, "whatever the order");

		let tool = other.AddType("Game.Tool", .Class, "Editor");
		tool.AddField("width", "float");
		Test.Assert(other.RuntimeHash() == both, "another domain's type is not the player's");

		other.Types[0].AddField("height", "float");
		Test.Assert(other.RuntimeHash() != both, "a member joined");
	}
}
