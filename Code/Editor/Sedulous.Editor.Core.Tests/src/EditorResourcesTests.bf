using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.VG.SVG;
using Sedulous.GUI;
using Sedulous.Geometry.Pipeline;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// Types to ask for icons: a category on the base, an icon on one derived type only.
/// AlwaysInclude, so their type data (the base link, the attribute) is there to be asked.
[Category("Visual Effects"), AlwaysInclude]
class IconBase
{
}

[AlwaysInclude]
class IconLight : IconBase
{
}

/// No icon of its own: it takes its base's.
[AlwaysInclude]
class IconSpot : IconBase
{
}

[AlwaysInclude]
class IconBare
{
}

/// A component is a struct: its chain (ValueType, Object) has no icons, so it falls back.
[Category("Physics"), AlwaysInclude]
struct IconBareComponent
{
}

/// The editor's own files and type icons: EditorResources reads text fresh,
/// keeps images and SVGs, and on a change sets the old aside, says which files changed and
/// runs what tracks them again; EditorIcons finds a type's icon up its bases, else a generic
/// one, and its tint from the nearest category it declares.
static class EditorResourcesTests
{
	private const String cSquare = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 16 16\"><rect x=\"2\" y=\"2\" width=\"12\" height=\"12\"/></svg>";
	private const String cCircle = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 16 16\"><circle cx=\"8\" cy=\"8\" r=\"6\"/><circle cx=\"8\" cy=\"8\" r=\"2\"/></svg>";

	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);
	}

	/// Written through a mount, which makes the folders on the way.
	private static void Write(StringView root, StringView relative, StringView text)
	{
		let fs = scope NativeFileSystem(root);
		Test.Assert(fs.Save(relative, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	/// An icon predicate over a fixed set of paths. OWNED by the caller (EditorIcons takes it).
	private static delegate bool(StringView path) Over(List<String> there)
	{
		return new [=there] (path) =>
		{
			for (let p in there)
			{
				if (p == path)
					return true;
			}
			return false;
		};
	}

	[Test]
	public static void TextIsReadFreshAChangedSvgIsSetAsideAndAChangeRunsWhatTracksIt()
	{
		let root = Scratch("scratch_editor_resources", .. scope .());
		Write(root, "Editor/editor.css", "a { color: red; }");
		Write(root, "Editor/Icons/save.svg", cSquare);
		let resources = scope EditorResources(root);

		let text = scope String();
		Test.Assert(resources.LoadText("Editor/editor.css", text));
		Test.Assert(text == "a { color: red; }");
		let square = resources.LoadSvg("Editor/Icons/save.svg");
		Test.Assert(square != null);
		Test.Assert(resources.LoadSvg("Editor/Icons/save.svg") == square, "kept: the GUI borrows it");
		Test.Assert(resources.Exists("Editor/Icons/save.svg"));
		Test.Assert(!resources.Exists("Editor/Icons/none.svg"));

		int runs = 0;
		let reload = scope Effect(new [&]() => { resources.TrackChanges(); runs++; });
		Test.Assert(runs == 1);
		Test.Assert(!resources.Poll(), "nothing changed yet");

		// Different sizes, so the sweep sees the change whatever the clock's resolution.
		Write(root, "Editor/editor.css", "a { color: blue; text-align: center; }");
		Write(root, "Editor/Icons/save.svg", cCircle);
		Test.Assert(resources.Poll());
		Test.Assert(runs == 2);
		Test.Assert(resources.LastChanged.Length == 2);
		text.Clear();
		Test.Assert(resources.LoadText("Editor/editor.css", text));
		Test.Assert(text == "a { color: blue; text-align: center; }");
		let circle = resources.LoadSvg("Editor/Icons/save.svg");
		Test.Assert(circle != null);
		Test.Assert(circle != square, "loaded anew; the old one is still alive for what draws it");
		Test.Assert(circle.Elements.Count == 2, "the circle's two shapes");
		Test.Assert(square.Elements.Count == 1, "the set-aside square is still whole");
	}

	[Test]
	public static void ATypeHasItsOwnIconTintedByTheNearestCategory()
	{
		let there = scope List<String>() { "Editor/Icons/Types/IconLight.svg", "Editor/Icons/Types/IconBase.svg", "Editor/Icons/Types/Component.svg" };
		let icons = scope EditorIcons(Over(there));

		let light = icons.For(typeof(IconLight), "Component");
		Test.Assert(light.Source == "Editor/Icons/Types/IconLight.svg");
		Test.Assert(light.Class == "cat-visualeffects", "its base's category");
		Test.Assert(icons.For(typeof(IconLight), "Component") == light, "asked again, the same answer");
	}

	[Test]
	public static void ATypeWithoutAnIconTakesItsBases()
	{
		let there = scope List<String>() { "Editor/Icons/Types/IconLight.svg", "Editor/Icons/Types/IconBase.svg", "Editor/Icons/Types/Component.svg" };
		let icons = scope EditorIcons(Over(there));

		let spot = icons.For(typeof(IconSpot), "Component");
		Test.Assert(spot.Source == "Editor/Icons/Types/IconBase.svg");
		Test.Assert(spot.Class == "cat-visualeffects");
	}

	[Test]
	public static void ATypeWithNoIconUpItsChainTakesTheGenericOne()
	{
		let there = scope List<String>() { "Editor/Icons/Types/IconLight.svg", "Editor/Icons/Types/IconBase.svg", "Editor/Icons/Types/Component.svg" };
		let icons = scope EditorIcons(Over(there));

		let bare = icons.For(typeof(IconBare), "Component");
		Test.Assert(bare.Source == "Editor/Icons/Types/Component.svg", "the fallback");
		Test.Assert(bare.Class.IsEmpty, "no category: the plain icon colour");
		Test.Assert(icons.For(typeof(IconBare), "Asset").Source.IsEmpty, "no icon anywhere");

		let component = icons.For(typeof(IconBareComponent), "Component");
		Test.Assert(component.Source == "Editor/Icons/Types/Component.svg", "a struct's chain has no icons");
		Test.Assert(component.Class == "cat-physics");
	}

	[Test]
	public static void ACategoryIsAClassOfItsLettersAndDigits()
	{
		Test.Assert(EditorIcons.CategoryClass("Rendering", .. scope .()) == "cat-rendering");
		Test.Assert(EditorIcons.CategoryClass("UI", .. scope .()) == "cat-ui");
		Test.Assert(EditorIcons.CategoryClass("Vector Graphics", .. scope .()) == "cat-vectorgraphics");
		Test.Assert(EditorIcons.CategoryClass("--", .. scope .()).IsEmpty);
	}

	/// The icons in Data/Editor/Icons/Types are named for the engine's own types: a component
	/// and an asset find theirs by name.
	[Test]
	public static void TheEnginesTypesFindTheirIconsInTheEditorsData()
	{
		let dataRoot = FindDataRoot(.. scope .());
		Test.Assert(!dataRoot.IsEmpty);
		let icons = scope EditorIcons(new [=dataRoot] (path) => FileExists(PathJoin(dataRoot, path, .. scope .())));

		let light = icons.For(typeof(LightComponent), "Component");
		Test.Assert(light.Source == "Editor/Icons/Types/LightComponent.svg");
		Test.Assert(light.Class == "cat-rendering");

		let mesh = icons.For(typeof(StaticMeshAsset), "Asset");
		Test.Assert(mesh.Source == "Editor/Icons/Types/StaticMeshAsset.svg");
	}
}
