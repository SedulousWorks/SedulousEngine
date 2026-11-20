using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Script.Tests;

/// A stand-in language whose classes are built ahead into their project's assembly: it compiles
/// nothing, and loads a module from a built image alone. What it was handed is kept for the test.
class ImageRuntime : ScriptRuntime
{
	public const String cLanguage = "imaged";

	private class ImageObject : ScriptObject
	{
	}

	public int Compiles = 0;
	public List<String> Modules = new .() ~ DeleteContainerAndItems!(_);
	public List<uint8> LastImage = new .() ~ delete _;
	public List<uint8> LastSymbols = new .() ~ delete _;
	/// The first section's name the last load was handed: the class's own file.
	public String LastSection = new .() ~ delete _;
	private List<ScriptObject> mLive = new .() ~ DeleteContainerAndItems!(_);

	public static void Register() => ScriptBackends.Register(cLanguage, => Create);

	private static ScriptRuntime Create() => new ImageRuntime();

	public override StringView Name => cLanguage;

	public override bool CompileModule(StringView moduleName, Span<ScriptSection> sections, bool runInitializers = true)
	{
		Compiles++;
		Problem("this language compiles nothing at run time");
		return false;
	}

	public override bool LoadModuleImage(StringView moduleName, Span<ScriptSection> sections, Span<uint8> image, Span<uint8> symbols)
	{
		if (image.IsEmpty)
			return false;
		Modules.Add(new String(moduleName));
		LastImage.Clear();
		LastImage.AddRange(image);
		LastSymbols.Clear();
		LastSymbols.AddRange(symbols);
		LastSection.Clear();
		if (!sections.IsEmpty)
			LastSection.Set(sections[0].Name);
		return true;
	}

	public override bool ModuleInUse(StringView moduleName) => false;

	public override ScriptObject Instantiate(StringView moduleName, StringView className)
	{
		for (let module in Modules)
		{
			if (module != moduleName)
				continue;
			let made = new ImageObject();
			made.Runtime = this;
			made.ClassName.Set(className);
			mLive.Add(made);
			return made;
		}
		return null;
	}

	public override void Release(ScriptObject scriptObject)
	{
		if (mLive.Remove(scriptObject))
			delete scriptObject;
	}
}

/// A class built into its project's assembly loads the assembly's image, with its symbols, in
/// place of compiling its source: its language has no compiler at run time. The host compiled
/// every class from source.
static class ScriptAssemblyLoadTests
{
	[Test]
	public static void AClassBuiltIntoAnAssemblyLoadsTheImageNotItsSource()
	{
		ImageRuntime.Register();
		let assembly = scope ScriptAssembly();
		assembly.Language.Set(ImageRuntime.cLanguage);
		assembly.Image.Add(0x4D);
		assembly.Image.Add(0x5A);
		assembly.Symbols.Add(0x42);
		let mover = scope ScriptClass();
		mover.Language.Set(ImageRuntime.cLanguage);
		mover.ClassName.Set("Mover");
		mover.Kind = .Entity;
		mover.SourceName.Set("Game/Mover.si");
		mover.Source.Set("class Mover (the source, never compiled)");
		mover.Assembly = assembly;

		let host = scope ScriptRunHost();
		let instance = host.Instantiate(mover, .Entity);
		Test.Assert(instance != null, "made from the loaded image");
		let runtime = host.Runtime as ImageRuntime;
		Test.Assert(runtime != null);
		Test.Assert(runtime.Compiles == 0, "its source never compiled");
		Test.Assert(runtime.Modules.Count == 1);
		Test.Assert((runtime.LastImage.Count == 2) && (runtime.LastImage[0] == 0x4D) && (runtime.LastImage[1] == 0x5A));
		Test.Assert((runtime.LastSymbols.Count == 1) && (runtime.LastSymbols[0] == 0x42), "its symbols beside it");
		Test.Assert(runtime.LastSection == "Game/Mover.si", "its own file named for its errors");
		runtime.Release(instance);

		// The same image is already loaded. Another file of its project changes the image, not the
		// class's source, and the class loads again for it.
		Test.Assert(host.EnsureClassLoaded(mover));
		Test.Assert(runtime.Modules.Count == 1, "loaded once");
		assembly.Image.Add(0x90);
		Test.Assert(host.EnsureClassLoaded(mover));
		Test.Assert(runtime.Modules.Count == 2, "a changed image loads again");
		Test.Assert(runtime.LastImage.Count == 3);
		assembly.Symbols.Add(0x43);
		Test.Assert(host.EnsureClassLoaded(mover));
		Test.Assert(runtime.Modules.Count == 3, "and so do changed symbols");

		// A class built into no assembly compiles its source, which this language refuses.
		let loose = scope ScriptClass();
		loose.Language.Set(ImageRuntime.cLanguage);
		loose.ClassName.Set("Loose");
		loose.SourceName.Set("Loose.si");
		loose.Source.Set("class Loose");
		Test.Assert(!host.EnsureClassLoaded(loose));
		Test.Assert(runtime.Compiles == 1, "compiled, as any class with no assembly is");
		Test.Assert(runtime.Modules.Count == 3);
	}
}
