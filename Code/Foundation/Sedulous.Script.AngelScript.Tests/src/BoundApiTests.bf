using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// DescribeBoundApi answers what this backend bound, in AngelScript's own spelling, not
/// what the surface lists: a static as `Type::Name`, a property as the type it reads, an
/// entity verb on Entity, a service as a global handle, and a method once per arity.
static class BoundApiTests
{
	private static ScriptApiType Find(List<ScriptApiType> types, StringView scriptName)
	{
		for (let t in types)
			if (t.ScriptName == scriptName)
				return t;
		return null;
	}

	private static bool HasSignature(ScriptApiType type, StringView signature)
	{
		for (let m in type.Members)
			if (m.Signature == signature)
				return true;
		return false;
	}

	private static void Print(ScriptApiType type)
	{
		Console.WriteLine("  {}{}", type.IsNamespace ? "namespace " : "", type.ScriptName.IsEmpty ? "<global>" : type.ScriptName);
		for (let m in type.Members)
			Console.WriteLine("    {}", m.Signature);
	}

	[Test]
	public static void TheBoundApiIsSpelledTheWayAScriptWritesIt()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		let api = scope List<ScriptApiType>();
		defer { ClearAndDeleteItems(api); }
		vm.DescribeBoundApi(api);

		let thing = Find(api, "Thing");
		Test.Assert((thing != null) && (thing.TypeFullName == "Sedulous.Script.Fixture.Thing") && !thing.IsNamespace);
		Print(thing);
		// A method per arity, spelled with its parameters; overloads by type both present.
		Test.Assert(HasSignature(thing, "void Thing.Move(const Vec2 &in to)"));
		Test.Assert(HasSignature(thing, "void Thing.Move(const Vec2 &in to, float speed)"));
		Test.Assert(HasSignature(thing, "void Thing.Move(const Vec2 &in to, float speed, bool teleport)"));
		Test.Assert(HasSignature(thing, "int64 Thing.Twice(int64 x)"));
		Test.Assert(HasSignature(thing, "float Thing.Twice(float x)"));
		// The renamed overload under its script name.
		Test.Assert((thing.Find("GoTo") != null) && HasSignature(thing, "void Thing.GoTo(const Vec2 &in at)"));
		// A static as the namespace spelling; a factory as one.
		let make = thing.Find("Make");
		Test.Assert((make != null) && make.IsStatic && (make.Signature == "Thing@ Thing::Make()"), make.Signature);
		// Properties with their read type, and a read only one marked.
		Test.Assert(HasSignature(thing, "int64 Thing.Count"), "a field");
		Test.Assert(HasSignature(thing, "float Thing.Speed"));
		Test.Assert(HasSignature(thing, "bool Thing.Ready (read only)"));
		Test.Assert(thing.Find("Speed").Kind == .Property);
		// A Ref<T> crosses as its Guid.
		Test.Assert(HasSignature(thing, "Guid Thing.Buddy"));
		// A list as the array it is.
		Test.Assert(HasSignature(thing, "float Thing.Sum(array<float>@ values)"));
		Test.Assert(HasSignature(thing, "array<Vec2>@ Thing.Points"));

		// A value type with a constructor and statics.
		let vec2 = Find(api, "Vec2");
		Test.Assert((vec2 != null) && HasSignature(vec2, "Vec2(float x, float y)") && HasSignature(vec2, "float Vec2::Dot(const Vec2 &in a, const Vec2 &in b)"));
		Test.Assert(HasSignature(vec2, "Vec2 Vec2::Zero (read only)"));

		// An enum's constants.
		let mode = Find(api, "Mode");
		Test.Assert((mode != null) && (mode.Find("Auto") != null) && (mode.Find("Auto").Kind == .Constant));
		Test.Assert(mode.Find("Auto").Signature.StartsWith("Mode::Auto = "));

		// The entity side of an entity-first verb, on Entity.
		let entity = Find(api, "Entity");
		Test.Assert((entity != null) && HasSignature(entity, "void Poke() const"), "Poke on Entity");
		Test.Assert(entity.Find("Nudge") == null, "a verb that did not ask is not on Entity");

		// A component constructed from its entity.
		let widget = Find(api, "WidgetComponent");
		Test.Assert((widget != null) && HasSignature(widget, "WidgetComponent(const Entity &in entity)"));

		// The global namespace: the language's coroutine verbs and the static block's function.
		let global = Find(api, "");
		Print(global);
		Test.Assert((global != null) && global.IsNamespace);
		Test.Assert(HasSignature(global, "void yield()") && HasSignature(global, "void wait(float seconds)"));
		Test.Assert(HasSignature(global, "float Lerp(float a, float b, float t)"), "the static block's function");

		// Everything named is bound: no type appears that the language refused. The inline
		// kinds are the language's own, on the surface or not.
		for (let t in api)
		{
			if (t.IsNamespace || (t.ScriptName == "Entity") || (t.ScriptName == "Guid"))
				continue;
			Test.Assert(s.Find(t.TypeFullName) != null, t.ScriptName);
		}
	}
}
