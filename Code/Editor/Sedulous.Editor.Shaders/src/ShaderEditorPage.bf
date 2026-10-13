using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
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
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Shaders;

/// A custom shader's page: its linked .hlsl in a code editor, checked as you type (each stage's
/// base variant, a short pause after the last key) with the errors as line markers, a list and a
/// status line; beside it a sphere drawn with the text being edited, its material laid out by the
/// properties block exactly as a cooked material is, and the asset's name and entry points. Save
/// writes the file and the asset and recooks, which compiles every variant. The preview draws
/// under a shader name of the page's own, so a scene keeps the last cooked shader until then.
class ShaderEditorPage : UIEditorPage
{
	/// How long after the last key the text is checked: long enough not to compile on every
	/// keystroke, short enough to read as live.
	private const float cCheckDelay = 0.6f;

	/// Borrowed.
	private EditorContext mContext;
	/// The renderer's; borrowed, null without one.
	private ShaderSystem mShaders = null;
	private String mTitle = new .() ~ delete _;
	private String mShaderLibrary = new .() ~ delete _;
	/// The linked .hlsl's absolute path, and its name as errors carry it.
	private String mSourcePath = new .() ~ delete _;
	private String mFileName = new .() ~ delete _;
	/// The preview's shader name, private to this page.
	private String mPreviewName = new .() ~ delete _;
	/// The edited asset, which Save writes back.
	private ShaderAsset mAsset = null ~ delete _;
	private String mText = new .() ~ delete _;
	private float mCheckDelay = 0.0f;
	/// Reused by every check; null when DXC cannot load.
	private ShaderCompiler mCompiler = null ~ delete _;

	private PreviewViewport mPreview = null;
	private EntityHandle mSphere = .Invalid;
	/// Owned: runtime built, never an asset.
	private StaticMesh mPreviewMesh = null;
	/// Owned; the preview entity draws it directly.
	private Material mPreviewMaterial = null;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageToolbar mToolbar = null;
	private CodeEditView mEditor = null;
	private Label mStatus = null;
	private EditText mErrorView = null;
	private PropertyGrid mGrid = null;

	/// `shaderLibrary`: the engine's Shaders/ folder, the include path a check compiles with.
	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance, StringView shaderLibrary)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		mShaderLibrary.Set(shaderLibrary);
		InstanceId = instance.Id;
		if (let render = host.Context.GetSubsystem<RenderSubsystem>())
			mShaders = render.Shaders;
		// A name of the page's own: the preview never replaces the cooked shader a scene draws.
		mPreviewName.AppendF("editor.preview.{}", instance.Id);

		let object = instance.ReadObject();
		mAsset = (object != null) ? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as ShaderAsset : null;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
		{
			GlobalLog(.Error, "Editor: shader '{}' failed to read - the page opens empty", mTitle);
			mAsset = new ShaderAsset();
		}
		mFileName.Set(mAsset.FileName.Value);
		if ((mContext.Project != null) && !mFileName.IsEmpty)
		{
			PathJoin(mContext.Project.SourcesRoot(.. scope .()), mFileName, mSourcePath);
			if (System.IO.File.ReadAllText(mSourcePath, mText) case .Err)
				GlobalLog(.Error, "Editor: shader '{}': cannot read {} - the page opens empty", mTitle, mSourcePath);
		}
		else
			GlobalLog(.Error, "Editor: shader '{}' has no linked .hlsl - the page opens empty", mTitle);

		// Left: the code, its status line and its error list.
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 4.0f;
		mEditor = new CodeEditView();
		mEditor.AllowBreakpoints = false; // a shader has no debugger
		mEditor.SetLexer(CodeLexerRegistry.Create("hlsl"));
		mEditor.SetText(mText);
		mEditor.OnTextChanged.Add(new [=this]() =>
			{
				mEditor.GetText(mText..Clear());
				MarkDirty();
				mCheckDelay = cCheckDelay;
			});
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Width = SizeSpec.Match();
		column.AddView(mEditor, growMatch);
		mStatus = new Label("");
		mStatus.FontSize.Value = 12.0f;
		var statusStyle = LayoutStyle();
		statusStyle.Width = SizeSpec.Match();
		statusStyle.Margin = Thickness(6, 2); // off the pane edge
		column.AddView(mStatus, statusStyle);
		// A fixed height, as the script page's: a share of the column would grow with the panel
		// and take the code's room.
		mErrorView = new EditText();
		mErrorView.Multiline.Value = true;
		mErrorView.IsReadOnly.Value = true;
		var errorStyle = LayoutStyle();
		errorStyle.Width = SizeSpec.Match();
		errorStyle.Height = SizeSpec.Fixed(Unit.Dp(96));
		column.AddView(mErrorView, errorStyle);

		// Right: the preview over the asset's fields.
		mPreview = new PreviewViewport(host, uiHost, "shader.preview");
		// The scene's clock runs only while it simulates, and Time() reads it: a surface that
		// scrolls or a Vertex() that moves would stand still otherwise.
		if (mPreview.Scene != null)
			mPreview.Scene.SetSimulationEnabled(true);
		mPreview.Camera.Position = .(0.0f, 0.9f, 2.6f);
		mPreview.Camera.LookAt(.(0.0f, 0.0f, 0.0f));
		BuildPreviewScene();

		mGrid = new PropertyGrid();
		AddField("Name", mAsset.Name);
		AddField("Vertex Entry Point", mAsset.VertexEntryPoint);
		AddField("Fragment Entry Point", mAsset.FragmentEntryPoint);

		let right = new FlexLayout();
		right.Direction = .Vertical;
		right.Spacing = 4.0f;
		var previewStyle = LayoutStyle();
		previewStyle.Width = SizeSpec.Match();
		previewStyle.FlexGrow = 1.0f;
		right.AddView(mPreview.View, previewStyle);
		var gridStyle = LayoutStyle();
		gridStyle.Width = SizeSpec.Match();
		gridStyle.Height = SizeSpec.Fixed(Unit.Dp(120));
		right.AddView(mGrid, gridStyle);

		let split = new SplitView();
		split.SplitRatio = 0.6f;
		split.SetPanes(column, right);
		mToolbar = new PageToolbar(this, mContext.Actions, .Save);
		mContent = PageToolbar.Frame(mToolbar, split);

		Check(); // the page opens with the shader's state, and its preview
	}

	public ~this()
	{
		ClearPreviewOverrides();
		RemovePreviewShader();
		delete mPreview;
		delete mPreviewMaterial;
		delete mPreviewMesh;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public ShaderAsset Asset => mAsset;
	public StringView Text => mText;
	public StringView StatusText => mStatus.Text.Value;
	public StringView ErrorText => mErrorView.Text;
	public CodeEditView Editor => mEditor;
	public Material PreviewMaterial => mPreviewMaterial;
	public StringView PreviewShaderName => mPreviewName;

	/// A string field of the asset; a change marks the page dirty and rechecks, an entry point
	/// changing what compiles.
	private void AddField(StringView label, String field)
	{
		let editor = new StringEditor(label, field, new [=this, =field](value) =>
			{
				if (field == value)
					return;
				field.Set(value);
				MarkDirty();
				mCheckDelay = cCheckDelay;
			}, "Shader");
		mGrid.AddProperty(editor);
	}

	public override Result<void, ErrorCode> Save()
	{
		if ((mContext.Project == null) || mSourcePath.IsEmpty)
			return .Err(.InvalidArgument);
		if (WriteFile(mSourcePath, Span<uint8>((uint8*)mText.Ptr, mText.Length)) case .Err(let writeError))
		{
			mContext.Notify(.Error, "Shader not saved - its file cannot be written");
			return .Err(writeError);
		}
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);
		// The asset carries the name and entry points; writing it also marks it for the cook.
		if (instance.WriteObject(mAsset) case .Err(let assetError))
			return .Err(assetError);
		ClearDirty();
		// The cook compiles every variant; a failure keeps the last good shader in the scenes.
		mContext.RequestCook(false);
		Check();
		if (mErrorView.Text.IsEmpty)
			mContext.Notify(.Success, "Shader saved - recooking every variant");
		else
			mContext.Notify(.Warning, "Shader saved with errors - the last good is kept");
		return .Ok;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mToolbar != null)
			mToolbar.Refresh();
		if (mPreview != null)
			mPreview.Update(dt);
		if (mCheckDelay > 0.0f)
		{
			mCheckDelay -= dt;
			if (mCheckDelay <= 0.0f)
				Check();
		}
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPreview != null)
			mPreview.RenderFrame(ref frame);
	}

	public override void OnClose()
	{
		if (mPreview != null)
			mPreview.Shutdown();
		RemovePreviewShader();
		// The editor's shutdown closes every page and then deletes the shader system before the
		// pages: once closed, the page does not reach the system again (the destructor's removal
		// would run on a deleted system).
		mShaders = null;
	}

	private void BuildPreviewScene()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
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

	/// Checks the text, puts the errors on the page, and on success redraws the preview.
	public void Check()
	{
		if (mCompiler == null)
		{
			mCompiler = new ShaderCompiler();
			if (mCompiler.Initialize() case .Err)
				DeleteAndNullify!(mCompiler);
		}
		var options = ShaderCheckOptions();
		options.VertexEntryPoint = mAsset.VertexEntryPoint;
		options.FragmentEntryPoint = mAsset.FragmentEntryPoint;
		options.ShaderLibrary = mShaderLibrary;
		options.Depth = .BaseVariants;
		options.Compiler = mCompiler;
		let check = scope ShaderCheck();
		check.Run(mText, mFileName, options);

		// This file's errors on their lines; an included file's only in the list.
		let diagnostics = new List<CodeDiagnostic>();
		let detail = scope String();
		for (let error in check.Errors)
		{
			if ((error.File == mFileName) && (error.Line > 0))
				diagnostics.Add(new CodeDiagnostic(true, (int32)error.Line - 1, error.Message));
			if (!detail.IsEmpty)
				detail.Append('\n');
			error.Format(detail);
		}
		mEditor.Document.SetDiagnostics(diagnostics);
		mEditor.Invalidate();
		mErrorView.SetText(detail);
		if (check.IsOk)
		{
			let kind = (check.Surface == .Lit) ? "Lit surface shader" : ((check.Surface == .Unlit) ? "Unlit surface shader" : "Low-level shader");
			mStatus.SetText(scope $"{kind}: compiles ({check.Block.Properties.Count} properties). Save checks every variant.");
			UpdatePreview(check);
			return;
		}
		// The preview keeps the last text that compiled.
		mStatus.SetText((check.Errors.Count == 1) ? "1 error" : scope $"{check.Errors.Count} errors");
	}

	private void UpdatePreview(ShaderCheck check)
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
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
		let scene = (mPreview != null) ? mPreview.Scene : null;
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

/// Opens a shader asset in the shader page.
class ShaderEditorPageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private String mShaderLibrary = new .() ~ delete _;

	/// `shaderLibrary`: the engine's Shaders/ folder under the data root.
	public this(IApplicationHost host, UIHost uiHost, StringView shaderLibrary)
	{
		mHost = host;
		mUiHost = uiHost;
		mShaderLibrary.Set(shaderLibrary);
	}

	public Type PrimaryType => typeof(ShaderAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new ShaderEditorPage(context, mHost, mUiHost, instance, mShaderLibrary);
}

/// The editor executable's entry point for the shader page.
static class ShaderEditor
{
	/// `shaderLibrary`: the engine's Shaders/ folder under the data root.
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost, StringView shaderLibrary)
	{
		context.Pages.Register(new ShaderEditorPageFactory(host, uiHost, shaderLibrary));
	}
}
