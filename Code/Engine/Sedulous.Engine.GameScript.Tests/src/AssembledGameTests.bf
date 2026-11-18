using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameScript.Tests;

/// A stand-in language whose classes are built ahead into an assembly: its runtime has no
/// compiler (a compile is refused) and loads a module from bytes alone. What it saw is kept here.
class AssembledRuntime : ScriptRuntime
{
	public const String cLanguage = "assembled";

	private class AssembledGame : ScriptObject
	{
	}

	public static List<uint8> sLoaded = new .() ~ delete _;
	public static List<String> sCalls = new .() ~ DeleteContainerAndItems!(_);
	public static bool sCompiled = false;

	private List<ScriptObject> mLive = new .() ~ DeleteContainerAndItems!(_);

	public static void Register() => ScriptBackends.Register(cLanguage, => Create);

	private static ScriptRuntime Create() => new AssembledRuntime();

	public static void Reset()
	{
		sLoaded.Clear();
		ClearAndDeleteItems!(sCalls);
		sCompiled = false;
	}

	public override StringView Name => cLanguage;

	public override bool CompileModule(StringView moduleName, Span<ScriptSection> sections, bool runInitializers = true)
	{
		sCompiled = true;
		Problem("this language compiles nothing at run time");
		return false;
	}

	public override bool LoadModuleImage(StringView moduleName, Span<ScriptSection> sections, Span<uint8> image, Span<uint8> symbols)
	{
		sLoaded.AddRange(image);
		return true;
	}

	public override bool ModuleInUse(StringView moduleName) => false;

	public override ScriptObject Instantiate(StringView moduleName, StringView className)
	{
		if ((className != "Game") || sLoaded.IsEmpty)
			return null;
		let made = new AssembledGame();
		made.Runtime = this;
		made.ClassName.Set(className);
		mLive.Add(made);
		return made;
	}

	public override void Release(ScriptObject scriptObject)
	{
		if (mLive.Remove(scriptObject))
			delete scriptObject;
	}

	public override bool HasMethod(ScriptObject scriptObject, StringView name, int arity) => true;

	public override bool Invoke(ScriptObject scriptObject, StringView name, Span<ScriptValue> args, ref ScriptValue result)
	{
		sCalls.Add(new String(name));
		return true;
	}
}

/// A Game class built into an assembly starts from the assembly, loaded as any class built into
/// one is, not from its source: its language has no compiler at run time. It is then made by
/// name and launched, updated and exited as any Game is.
static class AssembledGameTests
{
	[Test]
	public static void AGameBuiltIntoAnAssemblyStartsFromItNotFromItsSource()
	{
		AssembledRuntime.Register();
		AssembledRuntime.Reset();
		let assembly = scope ScriptAssembly();
		assembly.Language.Set(AssembledRuntime.cLanguage);
		assembly.Image.Add(0x4D);
		assembly.Image.Add(0x5A);
		let game = scope ScriptClass();
		game.Language.Set(AssembledRuntime.cLanguage);
		game.ClassName.Set("Game");
		game.SourceName.Set("Game.asm");
		game.Source.Set("(the source, never compiled)");
		game.Assembly = assembly;
		{
			let run = scope GameRun("scratch_game_assembled");
			Test.Assert(run.Instance.StartScript(game), "launched");
			Test.Assert(!AssembledRuntime.sCompiled, "its source never compiled");
			Test.Assert((AssembledRuntime.sLoaded.Count == 2) && (AssembledRuntime.sLoaded[0] == 0x4D) && (AssembledRuntime.sLoaded[1] == 0x5A));
			run.Instance.TickScript(0.1f, 1.0f);
			run.Instance.StopScript();
		}
		let calls = AssembledRuntime.sCalls;
		Test.Assert(calls.Count >= 3, scope $"{calls.Count} calls");
		Test.Assert(calls[0] == "launch");
		Test.Assert(calls[1] == "update");
		Test.Assert(calls.Back == "exit");
	}
}
