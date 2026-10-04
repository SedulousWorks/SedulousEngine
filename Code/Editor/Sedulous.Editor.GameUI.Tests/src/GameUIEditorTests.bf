using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.UI;
using Sedulous.UI.Resource;
using Sedulous.VFS;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.GameUI.Tests;

/// The game UI editor's registration and the markup probe its editors show.
class GameUIEditorTests
{
	[Test]
	public static void RegisteringRoutesBothAssetsToTheirPages()
	{
		let context = scope EditorContext();
		GameUIEditor.Register(context, null, null);
		let document = context.Pages.FindFactory(typeof(UIDocumentAsset));
		Test.Assert((document != null) && (document.PrimaryType == typeof(UIDocumentAsset)));
		let theme = context.Pages.FindFactory(typeof(UIThemeAsset));
		Test.Assert((theme != null) && (theme.PrimaryType == typeof(UIThemeAsset)));
	}

	[Test]
	public static void TheProbeReportsOneErrorOnTheFailingLine()
	{
		let diagnostics = scope List<CodeDiagnostic>();
		defer { ClearAndDeleteItems!(diagnostics); }
		Test.Assert(MarkupDiagnostics.Probe("<Panel>\n  <Label text=\"a\"/>\n</Panel>", diagnostics));
		Test.Assert(diagnostics.IsEmpty);
		Test.Assert(!MarkupDiagnostics.Probe("<Panel>\n  <Label text=\"a\">\n</Panel>", diagnostics));
		Test.Assert(diagnostics.Count == 1);
		Test.Assert(diagnostics[0].IsError && (diagnostics[0].Line >= 1) && !diagnostics[0].Message.IsEmpty);

		// Through an editor, the margin takes it.
		let editor = new CodeEditView();
		defer editor.ReleaseRef();
		editor.SetText("<a><b></a>");
		Test.Assert(!MarkupDiagnostics.Apply("<a><b></a>", editor));
		Test.Assert(editor.Document.DiagnosticCount == 1);
		Test.Assert(MarkupDiagnostics.Apply("<a/>", editor));
		Test.Assert(editor.Document.DiagnosticCount == 0);
		Test.Assert(UIThemeEditorPage.cStockPreviewMarkup.StartsWith("<Panel"));
	}

	[Test]
	public static void LinkedSourceReadsEmptyWithoutAProject()
	{
		let context = scope EditorContext();
		let text = scope String("stale");
		LinkedSource.Read(context, "UI/missing.sml", text);
		Test.Assert(text.IsEmpty);
	}

	/// The theme page previews a stylesheet before it is cooked: its @icon names a vector image
	/// the preview reads through the resource manager, so svg(name) draws there as it will in
	/// the game.
	[Test]
	public static void TheThemePreviewReadsAnIconsVectorImageThroughTheResources()
	{
		UIResources.RegisterAll();
		let dir = "scratch_theme_preview_db";
		RemoveDirectoryRecursive(dir);
		CreateDirectory(dir);
		defer RemoveDirectoryRecursive(dir);
		{
			let mount = scope NativeFileSystem(dir);
			SerializerFactory serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			defer delete serializers;
			let db = scope ContentDatabase(mount, serializers, "rasset");
			let instance = db.RootGroup.CreateInstance("heart", "Sedulous.UI.Resource.UIVectorImageResource");
			let source = scope UIVectorImageResource();
			source.Svg.Set("<svg viewBox=\"0 0 24 24\"><circle cx=\"12\" cy=\"12\" r=\"9\" fill=\"#E53935\"/></svg>");
			Test.Assert(instance.WriteObject(source) case .Ok);

			let factory = scope UIVectorImageFactory();
			let manager = scope ResourceManager(db);
			manager.AddFactory(factory);
			let resources = scope ThemePreviewResources(manager, null);

			let reference = scope String()..Append('{');
			instance.Id.ToString(reference);
			reference.Append('}');
			let svg = scope String();
			Test.Assert(resources.LoadText(reference, svg));
			Test.Assert(svg == source.Svg);
			Test.Assert(!resources.LoadText("{6dd1ae0e-fbe8-4c9b-8c9e-d10b727f4d84}", svg), "no such asset");
			Test.Assert(!resources.LoadText("icons/heart.svg", svg), "not an id");
			Test.Assert(resources.LoadImage("{6dd1ae0e-fbe8-4c9b-8c9e-d10b727f4d84}") == null, "no image source");

			// Through the loader, the icon becomes a drawable the preview's views resolve.
			let loader = scope StyleSheetLoader();
			loader.ResourceProvider = resources;
			let sheet = loader.Load(scope $"@icon heart \"{reference}\";\n.heart {{ background: svg(heart); }}\n");
			Test.Assert(sheet != null);
			let context = scope UIContext();
			let root = new RootView();
			context.AddRootView(root);
			root.SetLocalStyleSheet(sheet); // consumes the reference
			let panel = new Panel();
			panel.AddClass("heart");
			root.AddView(panel);
			Test.Assert(panel.ResolveStyleDrawable(.Background) is SVGDrawable);
			context.RemoveRootView(root);
			root.ReleaseRef();
		}
	}
}
