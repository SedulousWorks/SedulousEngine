using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.Tests;

/// Calling the emitted thunks through the frame: every role, every direction a value
/// crosses, and the failures a frame reports.
static class ScriptThunkTests
{
	private const String cFixture = "Sedulous.Script.Fixture";

	private static ScriptMethodInfo Method(ScriptSurface s, StringView type, StringView name, int arity = -1)
	{
		let t = s.Find(type);
		for (let m in t.Methods)
		{
			if ((m.ScriptName == name) && ((arity < 0) || (m.Params.Count == arity)))
				return m;
		}
		return null;
	}

	private static ScriptFieldInfo Field(ScriptSurface s, StringView type, StringView name)
	{
		let t = s.Find(type);
		for (let f in t.Fields)
			if (f.Name == name)
				return f;
		return null;
	}

	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void EveryFixtureMemberIsCallable()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		for (let t in s.Types)
		{
			for (let m in t.Methods)
				Test.Assert(m.IsCallable, scope $"{t.FullName}.{m.Name}: {m.Unsupported}");
			for (let f in t.Fields)
				Test.Assert(f.Get != null, scope $"{t.FullName}.{f.Name}: {f.Unsupported}");
		}
	}

	[Test]
	public static void AGlobalAndAStaticTakeArgumentsAndAnswer()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let ctx = scope ScratchCallContext();

		let lerp = Method(s, cFixture, "Lerp");
		var args = ScriptValue[3](.FromFloat(0), .FromFloat(10), .FromFloat(0.25));
		var frame = ScriptCallFrame(ctx, args);
		lerp.Invoke(ref frame);
		Test.Assert(!frame.Failed);
		Test.Assert((frame.Result.Kind == .Float) && Near((float)frame.Result.AsFloat, 2.5f));

		// A struct that is not an inline kind crosses by pointer.
		var a = Vec2(1, 2);
		var b = Vec2(3, 4);
		let dot = Method(s, scope $"{cFixture}.Vec2", "Dot");
		var dotArgs = ScriptValue[2](.FromStruct(&a, typeof(Vec2)), .FromStruct(&b, typeof(Vec2)));
		frame = ScriptCallFrame(ctx, dotArgs);
		dot.Invoke(ref frame);
		Test.Assert(Near((float)frame.Result.AsFloat, 11.0f));
	}

	[Test]
	public static void AConstructorAndAStructResultLandInContextStorage()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let ctx = scope ScratchCallContext();

		let ctor = Method(s, scope $"{cFixture}.Vec2", "this");
		var args = ScriptValue[2](.FromFloat(5), .FromFloat(6));
		var frame = ScriptCallFrame(ctx, args);
		ctor.Invoke(ref frame);
		Test.Assert(frame.Result.Kind == .Struct);
		Test.Assert(frame.Result.StructType == typeof(Vec2));
		let storage = (Vec2*)frame.Result.AsStruct;
		let v = *storage;
		Test.Assert(Near(v.X, 5) && Near(v.Y, 6));

		// A field on that storage, read and written through Self.
		let x = Field(s, scope $"{cFixture}.Vec2", "X");
		frame = ScriptCallFrame(ctx, default);
		frame.Self = .FromStruct(storage, typeof(Vec2));
		x.Get(ref frame);
		Test.Assert(Near((float)frame.Result.AsFloat, 5));
		var setArgs = ScriptValue[1](.FromFloat(9));
		frame.Args = setArgs;
		x.Set(ref frame);
		Test.Assert(Near(v.X, 5), "the copy taken before is untouched");
		Test.Assert(Near((*(Vec2*)frame.Self.AsStruct).X, 9), "the storage was written");

		// A read only static field has no setter.
		let zero = Field(s, scope $"{cFixture}.Vec2", "Zero");
		Test.Assert((zero.Get != null) && (zero.Set == null));
	}

	[Test]
	public static void AClassIsReachedThroughSelf()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let ctx = scope ScratchCallContext();
		let thing = scope $"{cFixture}.Thing";

		// The factory hands the object over.
		var frame = ScriptCallFrame(ctx, default);
		Method(s, thing, "Make").Invoke(ref frame);
		Test.Assert(frame.Result.Kind == .Object);
		let made = frame.Result.AsObject as Thing;
		Test.Assert(made != null);
		defer delete made;

		frame = ScriptCallFrame(ctx, default);
		frame.Self = .FromObject(made);
		Method(s, thing, "Go", 0).Invoke(ref frame);
		Test.Assert(made.Goes == 1);

		// A field, a writable property, a read only property.
		var one = ScriptValue[1](.FromInt(42));
		frame.Args = one;
		Field(s, thing, "Count").Set(ref frame);
		Test.Assert(made.Count == 42);
		Field(s, thing, "Count").Get(ref frame);
		Test.Assert(frame.Result.AsInt == 42);
		one[0] = .FromFloat(2.5);
		Field(s, thing, "Speed").Set(ref frame);
		Test.Assert(Near(made.Speed, 2.5f));
		Field(s, thing, "Ready").Get(ref frame);
		Test.Assert(frame.Result.AsBool);
		Test.Assert(Field(s, thing, "Ready").Set == null);

		// An enum crosses as its integer, a string as a view.
		one[0] = .FromInt((int64)Mode.Auto);
		Method(s, thing, "SetMode").Invoke(ref frame);
		Test.Assert(made.LastMode == .Auto);
		Method(s, thing, "GetMode").Invoke(ref frame);
		Test.Assert(frame.Result.AsInt == (int64)Mode.Auto);
		Method(s, thing, "Label").Invoke(ref frame);
		Test.Assert(frame.Result.AsString == "thing");

		// A struct result from an instance method.
		Method(s, thing, "Bounds").Invoke(ref frame);
		Test.Assert(Near((*(Vec2*)frame.Result.AsStruct).Y, 4));

		// The wrong self fails, and says so.
		frame.Self = .FromObject(scope Object());
		Method(s, thing, "Go", 0).Invoke(ref frame);
		Test.Assert(frame.Failed && frame.Error.Contains("Thing"));
		Test.Assert(frame.Result.IsNil);
	}

	[Test]
	public static void DefaultsFillMissingArgumentsAndRefsWriteBack()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let ctx = scope ScratchCallContext();
		let thing = scope $"{cFixture}.Thing";
		let made = scope Thing();

		// Move(to, speed = 1.5f, teleport = false), called with one argument.
		var to = Vec2(7, 8);
		var one = ScriptValue[1](.FromStruct(&to, typeof(Vec2)));
		var frame = ScriptCallFrame(ctx, one);
		frame.Self = .FromObject(made);
		Method(s, thing, "Move").Invoke(ref frame);
		Test.Assert(!frame.Failed);
		Test.Assert(Near(made.LastTarget.X, 7) && Near(made.LastSpeed, 1.5f) && !made.LastTeleport);

		// And with all three.
		var three = ScriptValue[3](.FromStruct(&to, typeof(Vec2)), .FromFloat(3), .FromBool(true));
		frame.Args = three;
		Method(s, thing, "Move").Invoke(ref frame);
		Test.Assert(Near(made.LastSpeed, 3) && made.LastTeleport);

		// The renamed overload.
		frame.Args = one;
		Method(s, thing, "GoTo").Invoke(ref frame);
		Test.Assert(Near(made.LastTarget.X, 7));

		// TryGet(index, ref outValue): the callee's write reaches the caller's storage.
		var slot = Vec2(0, 0);
		var refArgs = ScriptValue[2](.FromInt(3), .FromStruct(&slot, typeof(Vec2)));
		frame.Args = refArgs;
		Method(s, thing, "TryGet").Invoke(ref frame);
		Test.Assert(frame.Result.AsBool);
		Test.Assert(Near(slot.X, 3) && Near(slot.Y, 3));
	}

	[Test]
	public static void SceneRolesResolveThroughTheContextScene()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let ctx = scope ScratchCallContext();
		let component = scope $"{cFixture}.WidgetComponent";
		let system = scope $"{cFixture}.FixtureSystem";

		// No scene: a scene bound member fails rather than crashing.
		var frame = ScriptCallFrame(ctx, default);
		Field(s, system, "Ticks").Get(ref frame);
		Test.Assert(frame.Failed && frame.Error.Contains("FixtureSystem"));

		let scene = scope Scene();
		let widgets = scene.AddSystem<WidgetComponentManager>();
		let fixtureSystem = scene.AddSystem<FixtureSystem>();
		ctx.Scene = scene;

		frame = ScriptCallFrame(ctx, default);
		Field(s, system, "Ticks").Get(ref frame);
		Test.Assert(!frame.Failed && (frame.Result.AsInt == 7));
		fixtureSystem.TickCount = 8;
		Field(s, system, "Ticks").Get(ref frame);
		Test.Assert(frame.Result.AsInt == 8);

		// A component: Self is the entity; no component is a failure, not a crash.
		let bare = scene.CreateEntity("bare");
		frame.Self = .FromEntity(bare);
		Field(s, component, "Size").Get(ref frame);
		Test.Assert(frame.Failed && frame.Error.Contains("WidgetComponent"));

		let entity = scene.CreateEntity("widget");
		widgets.Add(entity).Size = 2.0f;
		frame = ScriptCallFrame(ctx, default);
		frame.Self = .FromEntity(entity);
		Field(s, component, "Size").Get(ref frame);
		Test.Assert(!frame.Failed && Near((float)frame.Result.AsFloat, 2.0f));
		var one = ScriptValue[1](.FromFloat(5));
		frame.Args = one;
		Field(s, component, "Size").Set(ref frame);
		Test.Assert(Near(widgets.Get(entity).Size, 5.0f), "written into the pool");

		// The manager's verb: no Self needed, the entity is an argument.
		var entityArg = ScriptValue[1](.FromEntity(entity));
		frame = ScriptCallFrame(ctx, entityArg);
		Method(s, scope $"{cFixture}.WidgetComponentManager", "Poke").Invoke(ref frame);
		Test.Assert(!frame.Failed);
	}

	/// A thunk trusts nothing in the frame: too few arguments, the wrong kind, the wrong
	/// struct or a null one all fail with a message, before anything is read.
	[Test]
	public static void ThunksCheckTheArgumentsBeforeReadingThem()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let ctx = scope ScratchCallContext();
		let thing = scope $"{cFixture}.Thing";
		let made = scope Thing();

		// Too few.
		var frame = ScriptCallFrame(ctx, default);
		frame.Self = .FromObject(made);
		Method(s, thing, "SetMode").Invoke(ref frame);
		Test.Assert(frame.Failed && frame.Error.Contains("at least 1"));

		// Wrong kind.
		var text = ScriptValue[1](.FromString("x"));
		frame = ScriptCallFrame(ctx, text);
		frame.Self = .FromObject(made);
		Method(s, thing, "SetMode").Invoke(ref frame);
		Test.Assert(frame.Failed && frame.Error.Contains("argument 0") && frame.Error.Contains("Int"));

		// A number promotes into a float slot; a float does not into an integer slot.
		var one = ScriptValue[1](.FromInt(3));
		frame = ScriptCallFrame(ctx, one);
		frame.Self = .FromObject(made);
		Field(s, thing, "Speed").Set(ref frame);
		Test.Assert(!frame.Failed && (made.Speed == 3.0f));
		one[0] = .FromFloat(2.5);
		Field(s, thing, "Count").Set(ref frame);
		Test.Assert(frame.Failed);

		// The wrong struct, and a null struct pointer, for a ref parameter.
		var wrong = Guid();
		var refArgs = ScriptValue[2](.FromInt(1), .FromStruct(&wrong, typeof(Guid)));
		frame = ScriptCallFrame(ctx, refArgs);
		frame.Self = .FromObject(made);
		Method(s, thing, "TryGet").Invoke(ref frame);
		Test.Assert(frame.Failed && frame.Error.Contains("Vec2"));
		refArgs[1] = .FromStruct(null, typeof(Vec2));
		Method(s, thing, "TryGet").Invoke(ref frame);
		Test.Assert(frame.Failed, "a null pointer never reaches the write back");

		// A field setter with nothing to set.
		frame = ScriptCallFrame(ctx, default);
		frame.Self = .FromObject(made);
		Field(s, thing, "Count").Set(ref frame);
		Test.Assert(frame.Failed);
	}

	/// A Ref<T> field crosses as its Guid. On a component the manager rebinds it; on a
	/// plain class there is nothing to bind through, so the identity lands unbound.
	[Test]
	public static void ResourceReferencesCrossAsGuids()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let ctx = scope ScratchCallContext();
		let made = scope Thing();
		let id = Guid.Create();

		var one = ScriptValue[1](.FromGuid(id));
		var frame = ScriptCallFrame(ctx, one);
		frame.Self = .FromObject(made);
		Field(s, scope $"{cFixture}.Thing", "Buddy").Set(ref frame);
		Test.Assert(!frame.Failed && (made.Buddy.Id == id) && (made.Buddy.Get == null));
		Field(s, scope $"{cFixture}.Thing", "Buddy").Get(ref frame);
		Test.Assert((frame.Result.Kind == .Guid) && (frame.Result.AsGuid == id));

		// On a component, through the pool.
		let scene = scope Scene();
		let widgets = scene.AddSystem<WidgetComponentManager>();
		let entity = scene.CreateEntity("w");
		widgets.Add(entity);
		ctx.Scene = scene;
		frame = ScriptCallFrame(ctx, one);
		frame.Self = .FromEntity(entity);
		Field(s, scope $"{cFixture}.WidgetComponent", "Skin").Set(ref frame);
		Test.Assert(!frame.Failed && (widgets.Get(entity).Skin.Id == id));
	}

	/// An entity value names its scene: a component resolves there whatever scene is
	/// ambient, a manager refuses an entity from another scene, and a scene answers the
	/// system a script asks for.
	[Test]
	public static void EntitiesAndSystemsAreSceneBound()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let ctx = scope ScratchCallContext();
		let component = scope $"{cFixture}.WidgetComponent";

		let a = scope Scene("a");
		let b = scope Scene("b");
		a.AddSystem<WidgetComponentManager>();
		let widgetsB = b.AddSystem<WidgetComponentManager>();
		let systemB = b.AddSystem<FixtureSystem>();
		let inB = b.CreateEntity("in b");
		widgetsB.Add(inB).Size = 7;
		let inA = a.CreateEntity("in a");

		// The ambient scene is A; the entity says B; B is where it resolves.
		ctx.Scene = a;
		var frame = ScriptCallFrame(ctx, default);
		frame.Self = .FromEntity(inB, b);
		Field(s, component, "Size").Get(ref frame);
		Test.Assert(!frame.Failed && (frame.Result.AsFloat == 7), scope String(frame.Error));

		// A manager held as an object works in its own scene, and refuses another's entity.
		let manager = s.Find(scope $"{cFixture}.WidgetComponentManager");
		var arg = ScriptValue[1](.FromEntity(inB, b));
		frame = ScriptCallFrame(ctx, arg);
		frame.Self = .FromObject(widgetsB);
		Method(s, scope $"{cFixture}.WidgetComponentManager", "Poke").Invoke(ref frame);
		Test.Assert(!frame.Failed);
		arg[0] = .FromEntity(inA, a);
		Method(s, scope $"{cFixture}.WidgetComponentManager", "Poke").Invoke(ref frame);
		Test.Assert(frame.Failed && frame.Error.Contains("another scene"));
		// An entity naming no scene is taken to be in it.
		arg[0] = .FromEntity(inB);
		Method(s, scope $"{cFixture}.WidgetComponentManager", "Poke").Invoke(ref frame);
		Test.Assert(!frame.Failed);

		// The resolver: the scene's instance, from a Scene self.
		let system = s.Find(scope $"{cFixture}.FixtureSystem");
		Test.Assert((system.FromScene != null) && (manager.FromScene != null));
		Test.Assert(s.Find(scope $"{cFixture}.Thing").FromScene == null, "a plain class has none");
		frame = ScriptCallFrame(ctx, default);
		frame.Self = .FromObject(b);
		system.FromScene(ref frame);
		Test.Assert(!frame.Failed && (frame.Result.AsObject === systemB));
		frame.Self = .FromObject(scope Object());
		system.FromScene(ref frame);
		Test.Assert(frame.Failed);

		// And a system held as an object is used as is, not the ambient scene's.
		frame = ScriptCallFrame(ctx, default);
		frame.Self = .FromObject(systemB);
		Field(s, scope $"{cFixture}.FixtureSystem", "Ticks").Get(ref frame);
		Test.Assert(!frame.Failed && (frame.Result.AsInt == systemB.TickCount));
	}
}
