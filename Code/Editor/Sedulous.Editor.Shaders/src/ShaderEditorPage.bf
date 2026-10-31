using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Graphics;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Materials.Pipeline;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.Shaders.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Engine.Render;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Shaders;

/// A custom shader's page: its .hlsl on the GUI from its markup (Data/Editor/ShaderPage.xml;
/// Raptor's editor-gui spec, 5.4, layer 6, part 4), on the code pages' base (the source file, the
/// shared HLSL colours, one history, the problems list): checked a moment after each edit (each
/// stage's base variant), its file's errors on their lines and an include's in the list; beside it a
/// sphere drawn with the code being edited, its material laid out by the properties block exactly as
/// a cooked material is, over the asset's grid (its name and entry points, each edit one undo step
/// with the code's). While the code does not compile the preview keeps the last version that did,
/// and says so. Save writes the file and the asset and recooks, which compiles every variant; the
/// preview draws under a name of its own, so a scene keeps the last cooked shader until then.
class ShaderEditorPage : CodeAssetPage
{
	public const String cMarkupPath = "Editor/ShaderPage.xml";

	/// The renderer's; borrowed, null without one (and once the page closed).
	private ShaderSystem mShaders = null;
	private String mShaderLibrary = new .() ~ delete _;
	/// The preview's shader name, private to this page.
	private String mPreviewName = new .() ~ delete _;
	/// Reused by every check; null when DXC cannot load.
	private ShaderCompiler mCompiler = null ~ delete _;
	private PreviewPane mPane = null;
	private EntityHandle mSphere = .Invalid;
	/// Owned: runtime built, never an asset.
	private StaticMesh mPreviewMesh = null;
	/// Owned; the preview entity draws it directly.
	private Material mPreviewMaterial = null;
	/// Borrowed: the markup's.
	private Node mStaleNote = null;
	private String mKind = new .() ~ delete _;
	private int mProperties = 0;
	/// The preview shows a version that compiled.
	private bool mCompiled = false;
	private bool mStale = false;

	/// `shaderLibrary`: the engine's Shaders/ folder, the include path a check compiles with.
	public this(EditorContext context, AssetPageServices services, Instance instance, StringView shaderLibrary)
		: base(context, services, instance, typeof(ShaderAsset), cMarkupPath)
	{
		mShaderLibrary.Set(shaderLibrary);
		if (Services.Host != null)
		{
			if (let render = Services.Host.Context.GetSubsystem<RenderSubsystem>())
				mShaders = render.Shaders;
		}
		// A name of the page's own: the preview never replaces the cooked shader a scene draws.
		mPreviewName.AppendF("editor.preview.{}", instance.Id);
		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "shader.preview");
			mPane.OnFrame = new [=this] () => { FramePreview(); };
			if (let preview = mPane.Viewport)
			{
				// The scene's clock runs only while it simulates, and Time() reads it: a surface that
				// scrolls or a Vertex() that moves would stand still otherwise.
				if (preview.Scene != null)
					preview.Scene.SetSimulationEnabled(true);
				preview.Camera.Position = .(0.0f, 0.9f, 2.6f);
				preview.Camera.LookAt(.(0.0f, 0.0f, 0.0f));
			}
		}
		mStaleNote = Find<Node>("shader-stale");
		BuildPreviewScene();
		OpenCode("hlsl"); // checked at once: the page opens with the shader's state and its preview
	}

	public ~this()
	{
		ClearPreviewOverrides();
		RemovePreviewShader();
		DeleteAndNullify!(mPane); // its preview scene before the mesh and the material it drew with
		delete mPreviewMaterial;
		delete mPreviewMesh;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mPane != null)
			mPane.Update(dt);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPane != null)
			mPane.Render(ref frame);
	}

	public override void OnClose()
	{
		if (mPane != null)
			mPane.Close();
		RemovePreviewShader();
		// The editor's shutdown closes every page and then deletes the shader system before the
		// pages: once closed, the page does not reach the system again (the destructor's removal
		// would run on a deleted system).
		mShaders = null;
	}

	// === For tests ===

	/// What the last check said the shader is ("Lit surface shader", "Low-level shader"), empty
	/// while it does not compile.
	public StringView Kind => mKind;
	/// The properties block's count, as the last check that compiled read it.
	public int PropertyCount => mProperties;
	/// Whether the preview shows an older version than the code (the code does not compile).
	public bool PreviewStale => mStale;
	public PreviewPane Pane => mPane;
	public Material PreviewMaterial => mPreviewMaterial;
	public StringView PreviewShaderName => mPreviewName;

	protected override void CheckCode(StringView text, List<CodeProblem> outProblems)
	{
		if (mCompiler == null)
		{
			mCompiler = new ShaderCompiler();
			if (mCompiler.Initialize() case .Err)
				DeleteAndNullify!(mCompiler);
		}
		var options = ShaderCheckOptions();
		if (let asset = ObjectAs<ShaderAsset>())
		{
			options.VertexEntryPoint = asset.VertexEntryPoint;
			options.FragmentEntryPoint = asset.FragmentEntryPoint;
		}
		options.ShaderLibrary = mShaderLibrary;
		options.Depth = .BaseVariants;
		options.Compiler = mCompiler;
		let check = scope ShaderCheck();
		check.Run(text, SourceFileName, options);

		// This file's errors on their lines; an include's named by its file.
		for (let d in check.Errors)
		{
			let own = d.File == SourceFileName;
			outProblems.Add(new CodeProblem(.Error, d.Message, own ? "" : (StringView)d.File, (d.Line > 0) ? d.Line - 1 : 0,
				(d.Column > 0) ? d.Column - 1 : 0, (d.Line > 0) && (d.Column > 0)));
		}
		if (check.IsOk)
		{
			mKind.Set((check.Surface == .Lit) ? "Lit surface shader" : ((check.Surface == .Unlit) ? "Unlit surface shader" : "Low-level shader"));
			mProperties = check.Block.Properties.Count;
			mCompiled = true;
			UpdatePreview(check);
		}
		else
			mKind.Clear();
		// The preview keeps the last code that compiled, and says so while the code is not it.
		mStale = !check.IsOk && mCompiled;
		if (mStaleNote != null)
			mStaleNote.Displayed = mStale;
		if (mPane != null)
		{
			if (mCompiled)
				mPane.Show();
			else
				mPane.ShowEmpty("Nothing to preview yet", "It shows once the code compiles.");
		}
	}

	/// An entry point changes what compiles.
	protected override void OnObjectChanged()
	{
		CheckNow();
	}

	private void FramePreview()
	{
		if ((mPane != null) && (mPane.Viewport != null))
			mPane.Viewport.Frame(.(0.0f, 0.0f, 0.0f), 1.0f);
	}

	private Sedulous.Scene.Scene PreviewScene => ((mPane != null) && (mPane.Viewport != null)) ? mPane.Viewport.Scene : null;

	private void BuildPreviewScene()
	{
		let scene = PreviewScene;
		if (scene == null)
			return;
		mSphere = scene.CreateEntity("PreviewSphere");
		mPreviewMesh = Primitives.Sphere(1.0f, 48, 24);
		if (let meshes = scene.GetSystem<MeshComponentManager>())
		{
			let mc = meshes.Add(mSphere);
			mc.Mesh.SetDirect(mPreviewMesh); // runtime built, not an asset
		}
		let sun = scene.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f) * Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
		scene.SetLocalTransform(sun, t);
		if (let lights = scene.GetSystem<LightComponentManager>())
		{
			let light = lights.Add(sun);
			light.CastsShadows = false; // a lone sphere has nothing to shadow
		}
	}

	private void UpdatePreview(ShaderCheck check)
	{
		let scene = PreviewScene;
		if ((mShaders == null) || (scene == null) || !mSphere.IsAssigned)
			return;
		// The main program as the cook would ship it (a surface shader's forward program), under
		// the page's own name, with its entries and lattices.
		let main = check.Programs[0];
		mShaders.RegisterSource(mPreviewName, .Vertex, main.Text, main.VertexEntryPoint, main.VertexMask);
		mShaders.RegisterSource(mPreviewName, .Fragment, main.Text, main.FragmentEntryPoint, main.FragmentMask);
		mShaders.InvalidateShader(mPreviewName);

		// A material laid out by the block as a cooked material on this shader is, at its
		// defaults.
		let shader = scope ShaderSource();
		shader.Name.Set(mPreviewName);
		shader.SetProperties(check.Block);
		let authored = scope MaterialSource();
		authored.Name.Set("preview");
		let laidOut = scope MaterialSource();
		MaterialShaderLayout.LayOut(authored, shader, laidOut);
		let material = laidOut.ToMaterial(mPreviewName);
		if (let meshes = scene.GetSystem<MeshComponentManager>())
		{
			if (let mc = meshes.Get(mSphere))
			{
				mc.Materials.Clear();
				mc.MaterialCache.Clear();
				mc.SetMaterial(material);
			}
		}
		delete mPreviewMaterial;
		mPreviewMaterial = material;
	}

	/// The preview entity draws the page's mesh and material directly; detached before they go.
	private void ClearPreviewOverrides()
	{
		let scene = PreviewScene;
		if ((scene == null) || !mSphere.IsAssigned)
			return;
		if (let meshes = scene.GetSystem<MeshComponentManager>())
		{
			if (let mc = meshes.Get(mSphere))
			{
				mc.Mesh.SetDirect(null);
				mc.Materials.Clear();
				mc.MaterialCache.Clear();
			}
		}
	}

	private void RemovePreviewShader()
	{
		if ((mShaders != null) && !mPreviewName.IsEmpty)
		{
			mShaders.RemoveSource(mPreviewName);
			mShaders.InvalidateShader(mPreviewName);
		}
	}
}

/// Opens a shader asset in the shader page; a page asks for its services when it is made.
class ShaderEditorPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;
	private String mShaderLibrary = new .() ~ delete _;

	/// `services` is borrowed and outlives it; `shaderLibrary`: the engine's Shaders/ folder under
	/// the data root.
	public this(AssetPageServicesSource services, StringView shaderLibrary)
	{
		mServices = services;
		mShaderLibrary.Set(shaderLibrary);
	}

	public Type PrimaryType => typeof(ShaderAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new ShaderEditorPage(context, mServices.Make(), instance, mShaderLibrary);
}

/// The shader page's registration (from the editor's assembly). Its colours are the shared HLSL
/// definition's (Data/Editor/Code/hlsl.xml).
static class ShaderEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made; `shaderLibrary`: the engine's Shaders/ folder under the data
	/// root.
	public static void Register(EditorContext context, AssetPageServicesSource services, StringView shaderLibrary)
	{
		context.Pages.Register(new ShaderEditorPageFactory(services, shaderLibrary));
	}
}
