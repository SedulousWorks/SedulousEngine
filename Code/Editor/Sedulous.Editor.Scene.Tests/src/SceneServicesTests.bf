using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Composition;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// The scene editor's services, registered without a page: the export's seams set (a scene's text
/// source transcoded to the binary wire, its references scanned), and an import that is not a
/// model passing the model-prefab listener by.
class SceneServicesTests
{
	/// A headless host: the import listener only keeps it.
	class StubHost : IApplicationHost
	{
		public SubsystemManager Subsystems { get; } = new .() ~ delete _;

		public IShell Shell => null;
		public GraphicsDevice Graphics => null;
		public RenderWindow MainRenderWindow => null;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) => null;
		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) {}
	}

	[Test]
	public static void TheExportsSeamsSetASceneTextSourceStagedAsTheBinaryWireItsReferencesScanned()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_scene_services_project", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		let context = scope EditorContext();
		let host = scope StubHost();
		Test.Assert(context.SceneStreamStager == null);
		Test.Assert(context.SceneRefScanner == null);
		SceneServices.Register(context, host);
		Test.Assert(context.SceneStreamStager != null);
		Test.Assert(context.SceneRefScanner != null);

		let level = project.SourceDb.RootGroup.CreateInstance("Level", typeof(SceneDocument).GetFullName(.. scope .()));
		Test.Assert(level != null);
		{
			let authored = scope Sedulous.Scene.Scene("authored");
			EngineSceneComposition.AddAllSceneManagers(authored);
			authored.CreateEntity("Crate");
			Test.Assert(SceneStorage.SaveScene(authored, level) case .Ok);
		}
		let text = scope List<uint8>();
		{
			let stream = level.ReadData(SceneExportSupport.cSceneStream);
			Test.Assert(stream != null);
			defer delete stream;
			text.Resize((int)stream.Size());
			stream.Read(Span<uint8>(text.Ptr, text.Count));
		}
		let wire = scope List<uint8>();
		Test.Assert(context.SceneStreamStager(level, wire));
		Test.Assert(!wire.IsEmpty);
		var verbatim = wire.Count == text.Count;
		for (int i = 0; verbatim && (i < wire.Count); i++)
			verbatim = wire[i] == text[i];
		Test.Assert(!verbatim, "transcoded, not the source as it is");

		let resources = scope List<Guid>();
		let prefabs = scope List<Guid>();
		Test.Assert(context.SceneRefScanner(level, project.SourceDb, resources, prefabs));
		Test.Assert(prefabs.IsEmpty);

		// Not a model's import: the prefab listener lets it by, saying nothing.
		int notices = 0;
		context.OnNotice = new [&notices](kind, message) => { notices++; };
		context.NotifyImported(level, null);
		Test.Assert(notices == 0, "nothing said");
		Test.Assert(project.SourceDb.RootGroup.GetInstance("Level") == level);
	}
}
