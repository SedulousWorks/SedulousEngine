using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scripting;
using Sedulous.Scripting.Null;

namespace Sedulous.Scripting.Tests;

/// What the walk puts on the surface, and what it keeps off.
static class ScriptSurfaceWalkerTests
{
	private const String cFixture = "Sedulous.Scripting.Tests.Fixture";

	private static ScriptFieldInfo Field(ScriptTypeInfo t, StringView name)
	{
		for (let f in t.Fields)
			if (f.Name == name)
				return f;
		return null;
	}

	private static ScriptMethodInfo Method(ScriptTypeInfo t, StringView scriptName)
	{
		for (let m in t.Methods)
			if (m.ScriptName == scriptName)
				return m;
		return null;
	}

	[Test]
	public static void TheClosureIsTheSurfaceAndUnmarkedTypesAreNot()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		// Vec2, Thing, Mode, Cooker, the static block, WidgetComponent, its manager, the system.
		Test.Assert(FixtureSurface.TypeCount == 8, scope $"found {FixtureSurface.TypeCount}");
		Test.Assert(s.Types.Count == FixtureSurface.TypeCount);
		Test.Assert(s.Find(scope $"{cFixture}.Unmarked") == null);
		Test.Assert(s.Find("Sedulous.Scripting.Tests.FixtureSurface") == null, "the root itself is off");

		// Stable order: sorted by full name, so a dump diffs.
		for (int i = 1; i < s.Types.Count; i++)
			Test.Assert(s.Types[i - 1].FullName.CompareTo(s.Types[i].FullName) < 0);
	}

	[Test]
	public static void AllPublicTakesTheDataAndOnlyTheMarkedMethods()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let v = s.Find(scope $"{cFixture}.Vec2");
		Test.Assert(v != null);
		Test.Assert(v.Kind == .Struct);
		Test.Assert(v.AllPublic);
		Test.Assert(v.Domain == ScriptDomains.Runtime);
		Test.Assert(v.Name == "Vec2");
		Test.Assert(v.Namespace == cFixture);
		Test.Assert(v.DisplayName == "Vector 2");
		Test.Assert(v.Description == "A two component vector.");

		let x = Field(v, "X");
		Test.Assert((x != null) && (x.TypeName == "float") && !x.IsStatic && !x.IsProperty && x.CanWrite);
		let y = Field(v, "Y");
		Test.Assert((y != null) && y.HasRange && (y.RangeMin == 0) && (y.RangeMax == 1) && (y.RangeStep == 0.1f));
		let zero = Field(v, "Zero");
		Test.Assert((zero != null) && zero.IsStatic && !zero.CanWrite, "a static readonly is on, read only");
		Test.Assert(Field(v, "Scratch") == null, "[Hidden] wins over AllPublic");

		let length = Field(v, "Length");
		Test.Assert((length != null) && length.IsProperty && !length.CanWrite);
		let scale = Field(v, "Scale");
		Test.Assert((scale != null) && scale.IsProperty && scale.CanWrite);

		let ctor = Method(v, "this");
		Test.Assert((ctor != null) && ctor.IsConstructor && (ctor.Params.Count == 2));
		Test.Assert((ctor.Params[0].Name == "x") && (ctor.Params[0].TypeName == "float"));
		let dot = Method(v, "Dot");
		Test.Assert((dot != null) && dot.IsStatic && (dot.ReturnTypeName == "float"));
		Test.Assert(dot.Params[1].TypeName == scope $"{cFixture}.Vec2");
		Test.Assert(Method(v, "Normalized") == null, "AllPublic is data only; an unmarked method stays off");
	}

	[Test]
	public static void MarkedOnlyTakesExactlyTheMarks()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let t = s.Find(scope $"{cFixture}.Thing");
		Test.Assert((t != null) && (t.Kind == .Class) && !t.AllPublic && (t.Role == .Plain));

		Test.Assert(Field(t, "Count") != null);
		Test.Assert(Field(t, "NotExposed") == null);
		let speed = Field(t, "Speed");
		Test.Assert((speed != null) && speed.IsProperty && speed.CanWrite && (speed.Description == "How fast."));
		let ready = Field(t, "Ready");
		Test.Assert((ready != null) && ready.IsProperty && !ready.CanWrite && (ready.TypeName == "bool"));

		// The overload set: Go stays Go, Go(Vec2) is GoTo to the script and Go underneath.
		let go = Method(t, "Go");
		Test.Assert((go != null) && (go.Params.Count == 0));
		let goTo = Method(t, "GoTo");
		Test.Assert((goTo != null) && (goTo.Name == "Go") && (goTo.Params.Count == 1));

		let tryGet = Method(t, "TryGet");
		Test.Assert(tryGet != null);
		Test.Assert(!tryGet.Params[0].IsByRef && tryGet.Params[1].IsByRef, "ref is recorded");
		Test.Assert(tryGet.Params[1].TypeName == scope $"{cFixture}.Vec2", "and the type is the pointee");

		let move = Method(t, "Move");
		Test.Assert((move != null) && (move.Params.Count == 3));
		Test.Assert(!move.Params[0].HasDefault);
		Test.Assert(move.Params[1].HasDefault && (move.Params[1].Default == "1.5f"), "the default as written");
		Test.Assert(move.Params[2].Default == "false");

		let make = Method(t, "Make");
		Test.Assert((make != null) && make.IsStatic && (make.ReturnTypeName == scope $"{cFixture}.Thing"));
		Test.Assert(Method(t, "Internal") == null);
	}

	[Test]
	public static void EnumsCarryTheirCases()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let m = s.Find(scope $"{cFixture}.Mode");
		Test.Assert((m != null) && (m.Kind == .Enum));
		Test.Assert(m.EnumValues.Count == 3);
		Test.Assert((m.EnumValues[0].Name == "Off") && (m.EnumValues[0].Value == 0));
		Test.Assert((m.EnumValues[1].Name == "On") && (m.EnumValues[1].Value == 5));
		Test.Assert((m.EnumValues[2].Name == "Auto") && (m.EnumValues[2].Value == 6));
	}

	[Test]
	public static void AStaticBlockIsAGlobalNamedForItsNamespace()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let g = s.Find(cFixture);
		Test.Assert((g != null) && (g.Kind == .Global));
		Test.Assert(g.Name.IsEmpty && (g.Namespace == cFixture));
		Test.Assert(g.Methods.Count == 1, "only the marked one");
		let lerp = g.Methods[0];
		Test.Assert((lerp.Name == "Lerp") && lerp.IsStatic && (lerp.Params.Count == 3));
		Test.Assert(lerp.Params[2].Name == "t");
	}

	[Test]
	public static void TheDomainIsReadAndDefaultsToRuntime()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		Test.Assert(s.Find(scope $"{cFixture}.Cooker").Domain == ScriptDomains.Pipeline);
		Test.Assert(s.Find(scope $"{cFixture}.Thing").Domain == ScriptDomains.Runtime);

		let domains = scope List<String>();
		defer { ClearAndDeleteItems(domains); }
		s.CollectDomains(domains);
		Test.Assert(domains.Count == 2);
	}

	[Test]
	public static void SceneRolesAreRecognisedFromTheBases()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);

		let component = s.Find(scope $"{cFixture}.WidgetComponent");
		Test.Assert((component != null) && (component.Role == .Component));
		Test.Assert(component.ComponentTypeId == "fixture_widget");
		Test.Assert(component.ManagerTypeName == scope $"{cFixture}.WidgetComponentManager", "found through ComponentManager<T>");
		Test.Assert((Field(component, "Size") != null) && (Field(component, "RuntimeOnly") == null));

		let manager = s.Find(scope $"{cFixture}.WidgetComponentManager");
		Test.Assert((manager != null) && (manager.Role == .ComponentManager));
		Test.Assert(Method(manager, "Poke").Params[0].TypeName == "Sedulous.Scene.EntityHandle");

		let system = s.Find(scope $"{cFixture}.FixtureSystem");
		Test.Assert((system != null) && (system.Role == .SceneSystem));
		Test.Assert(Field(system, "Ticks").IsProperty);
	}

	[Test]
	public static void TheNullRuntimeDescribesWhatItBound()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = scope NullScriptRuntime();
		vm.Bind(s);
		Test.Assert(vm.Surface === s);

		let text = scope String();
		vm.Describe(text);
		Test.Assert(text.StartsWith("script surface: 8 types, "), scope String(text.Substring(0, 80)));
		Test.Assert(text.Contains(" 0 blocked, domains: Runtime Pipeline"));
		Test.Assert(text.Contains("== domain Pipeline =="));
		Test.Assert(text.Contains("struct Vec2 [all public] \"Vector 2\""));
		Test.Assert(text.Contains("    Y: float [0..1 step 0.1]"));
		Test.Assert(text.Contains("    static Zero: Vec2 (read only)"));
		Test.Assert(text.Contains("    Length: float { get; }"));
		Test.Assert(text.Contains("    new(x: float, y: float)"));
		Test.Assert(text.Contains("    static Dot(a: Vec2, b: Vec2) -> float"));
		Test.Assert(text.Contains("    GoTo(at: Vec2) [was Go]"));
		Test.Assert(text.Contains("    TryGet(index: int, ref outValue: Vec2) -> bool"));
		Test.Assert(text.Contains("    Move(to: Vec2, speed: float = 1.5f, teleport: bool = false)"));
		Test.Assert(text.Contains("global functions\n    Lerp(a: float, b: float, t: float) -> float"));
		Test.Assert(text.Contains("struct WidgetComponent [Component] id=fixture_widget manager=WidgetComponentManager"));
		Test.Assert(text.Contains("    On = 5"));
		Test.Assert(!text.Contains("Scratch") && !text.Contains("Unmarked") && !text.Contains("NotExposed"));
	}

	[Test]
	public static void ShortNamesKeepGenericsAndArrays()
	{
		Test.Assert(NullScriptRuntime.Short("System.Collections.List<Sedulous.Scene.EntityHandle>", .. scope .()) == "List<EntityHandle>");
		Test.Assert(NullScriptRuntime.Short("Sedulous.Core.Float3[]", .. scope .()) == "Float3[]");
		Test.Assert(NullScriptRuntime.Short("System.Collections.Dictionary<System.String, int>", .. scope .()) == "Dictionary<String, int>");
		Test.Assert(NullScriptRuntime.Short("float", .. scope .()) == "float");
	}
}
