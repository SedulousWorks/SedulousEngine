using System;
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
