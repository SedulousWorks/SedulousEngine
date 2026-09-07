using System;
using Sedulous.Model;
using Sedulous.Model.IO;

namespace Sedulous.Model.IO.Tests;

/// A loader that records what it was asked and claims whichever extensions it is told to.
class FakeLoader : IModelLoader
{
	public String Handles = new .() ~ delete _;
	public String LastPath = new .() ~ delete _;
	public int32 Loads;
	public ModelLoadResult Answer = .Ok;

	public this(StringView handles) { Handles.Set(handles); }

	public bool SupportsExtension(StringView @extension) => Handles == @extension;

	public ModelLoadResult Load(StringView path, Sedulous.Model.Model model)
	{
		Loads++;
		LastPath.Set(path);
		return Answer;
	}
}

/// Dispatch by extension, which is what lets a caller load a model without naming a
/// format and lets a new format touch nothing that already exists.
class ModelLoaderRegistryTests
{
	private static void Reset() => ModelLoaderRegistry.Clear();

	[Test]
	public static void ALoaderIsChosenByExtension()
	{
		Reset(); defer Reset();

		let gltf = scope FakeLoader(".gltf");
		let fbx = scope FakeLoader(".fbx");
		ModelLoaderRegistry.Register(gltf);
		ModelLoaderRegistry.Register(fbx);

		Test.Assert(ModelLoaderRegistry.HasLoaders);
		Test.Assert(ModelLoaderRegistry.LoaderCount == 2);

		let model = scope Sedulous.Model.Model();
		Test.Assert(ModelLoaderRegistry.Load("assets/hero.fbx", model) == .Ok);

		Test.Assert(fbx.Loads == 1, "the fbx loader took it");
		Test.Assert(gltf.Loads == 0, "and the other was not consulted for the load");
		Test.Assert(fbx.LastPath == "assets/hero.fbx", "the whole path is passed through");
	}

	/// An extension nothing claims is reported as unsupported rather than silently doing
	/// nothing, so a caller can tell "no loader" from "loaded an empty model".
	[Test]
	public static void AnUnknownExtensionIsReportedAsUnsupported()
	{
		Reset(); defer Reset();
		ModelLoaderRegistry.Register(scope FakeLoader(".gltf"));

		let model = scope Sedulous.Model.Model();
		Test.Assert(ModelLoaderRegistry.Load("thing.obj", model) == .UnsupportedFormat);
		Test.Assert(ModelLoaderRegistry.Load("noextension", model) == .UnsupportedFormat);
	}

	/// With no loaders at all it is still unsupported, not a crash: a headless tool that
	/// never registered one still gets an answer.
	[Test]
	public static void AnEmptyRegistryAnswersRatherThanTrapping()
	{
		Reset(); defer Reset();

		Test.Assert(!ModelLoaderRegistry.HasLoaders);
		let model = scope Sedulous.Model.Model();
		Test.Assert(ModelLoaderRegistry.Load("thing.gltf", model) == .UnsupportedFormat);
	}

	/// A loader's own failure comes back as its own result, not flattened into
	/// "unsupported": a corrupt file and an unknown format are different problems.
	[Test]
	public static void ALoadersFailureIsReportedAsItsOwn()
	{
		Reset(); defer Reset();

		let loader = scope FakeLoader(".gltf");
		loader.Answer = .ParseError;
		ModelLoaderRegistry.Register(loader);

		let model = scope Sedulous.Model.Model();
		Test.Assert(ModelLoaderRegistry.Load("broken.gltf", model) == .ParseError);
		Test.Assert(loader.Loads == 1, "it was reached, and it failed");
	}

	/// Registering the same loader twice does not get it consulted twice, which is what
	/// happens when a module is brought up more than once.
	[Test]
	public static void RegisteringTwiceRegistersOnce()
	{
		Reset(); defer Reset();

		let loader = scope FakeLoader(".gltf");
		ModelLoaderRegistry.Register(loader);
		ModelLoaderRegistry.Register(loader);
		ModelLoaderRegistry.Register(loader);

		Test.Assert(ModelLoaderRegistry.LoaderCount == 1);
		ModelLoaderRegistry.Register(null);
		Test.Assert(ModelLoaderRegistry.LoaderCount == 1, "and null is ignored");
	}

	/// A loader can be taken back out. It lives in the library that registered it, so a
	/// host closing that library must remove it first or the next load calls into unmapped
	/// memory.
	[Test]
	public static void ALoaderCanBeUnregistered()
	{
		Reset(); defer Reset();

		let loader = scope FakeLoader(".gltf");
		ModelLoaderRegistry.Register(loader);
		Test.Assert(ModelLoaderRegistry.Unregister(loader));
		Test.Assert(!ModelLoaderRegistry.HasLoaders);

		let model = scope Sedulous.Model.Model();
		Test.Assert(ModelLoaderRegistry.Load("thing.gltf", model) == .UnsupportedFormat);

		Test.Assert(!ModelLoaderRegistry.Unregister(loader), "removing it again says so");
	}

	/// The FIRST loader claiming an extension wins, so registration order decides and a
	/// later loader is a fallback rather than an override.
	[Test]
	public static void TheFirstClaimingLoaderWins()
	{
		Reset(); defer Reset();

		let first = scope FakeLoader(".gltf");
		let second = scope FakeLoader(".gltf");
		ModelLoaderRegistry.Register(first);
		ModelLoaderRegistry.Register(second);

		let model = scope Sedulous.Model.Model();
		ModelLoaderRegistry.Load("thing.gltf", model);

		Test.Assert(first.Loads == 1);
		Test.Assert(second.Loads == 0);
	}

	/// The extension is taken from the last dot in the FILE NAME. A dot in a directory
	/// name must not be mistaken for an extension on a file that has none.
	[Test]
	public static void TheExtensionComesFromTheFileNameOnly()
	{
		let found = scope String();

		ModelLoaderRegistry.GetExtension("model.gltf", found);
		Test.Assert(found == ".gltf");

		found.Clear();
		ModelLoaderRegistry.GetExtension("a/b/c/model.fbx", found);
		Test.Assert(found == ".fbx");

		// Two dots: the LAST one is the extension.
		found.Clear();
		ModelLoaderRegistry.GetExtension("archive.tar.gz", found);
		Test.Assert(found == ".gz");

		// A dotted directory and a file with no extension of its own.
		found.Clear();
		ModelLoaderRegistry.GetExtension("v1.2/model", found);
		Test.Assert(found.IsEmpty, scope $"got '{found}'");

		found.Clear();
		ModelLoaderRegistry.GetExtension("also\\v1.2\\model", found);
		Test.Assert(found.IsEmpty, "the backslash counts as a separator too");

		found.Clear();
		ModelLoaderRegistry.GetExtension("", found);
		Test.Assert(found.IsEmpty);

		// A dotfile is all extension, which is what the last dot rule says.
		found.Clear();
		ModelLoaderRegistry.GetExtension(".gltf", found);
		Test.Assert(found == ".gltf");
	}
}
