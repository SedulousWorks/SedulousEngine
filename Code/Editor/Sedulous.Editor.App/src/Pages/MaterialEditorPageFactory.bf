using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Shell.Input;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .material files.
/// Renders a unit sphere with the material applied, alongside an info panel.
class MaterialEditorPageFactory : IEditorPageFactory
{
	const String SPHERE_URI = "builtin://primitives/sphere.mesh";

	private IDevice mDevice;
	private VGRenderer mVGRenderer;
	private IKeyboard mKeyboard;

	public this(IDevice device, VGRenderer vgRenderer, IKeyboard keyboard)
	{
		mDevice = device;
		mVGRenderer = vgRenderer;
		mKeyboard = keyboard;
	}

	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".material"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".material", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "No runtime context.");

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "SceneSubsystem or ISceneRenderer unavailable.");

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "Path is not inside any mounted scheme.");

		Sedulous.Materials.Resources.MaterialResource matRes = null;
		if (context.ResourceSystem.LoadResource<Sedulous.Materials.Resources.MaterialResource>(uri) case .Ok(let handle))
			matRes = handle.Resource;
		if (matRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "Failed to load material resource.");

		Sedulous.Geometry.Resources.StaticMeshResource sphereRes = null;
		if (context.ResourceSystem.LoadResource<Sedulous.Geometry.Resources.StaticMeshResource>(SPHERE_URI) case .Ok(let sphereHandle))
			sphereRes = sphereHandle.Resource;
		if (sphereRes == null)
		{
			matRes.ReleaseRef();
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "Failed to load builtin sphere mesh.");
		}

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "MaterialPreview");
		let page = new MaterialEditorPage(path, uri, matRes, sphereRes, SPHERE_URI, host);
		page.SetContentView(BuildMaterialView(matRes, host));
		return page;
	}

	private static View BuildMaterialView(Sedulous.Materials.Resources.MaterialResource matRes, PreviewSceneHost host)
	{
		let root = new SplitView(.Horizontal);

		let viewportPanel = new Panel();
		viewportPanel.Background = new ColorDrawable(.(25, 25, 30, 255));
		viewportPanel.AddView(host.Viewport);

		let infoPanel = new FlexLayout();
		infoPanel.Direction = .Vertical;
		infoPanel.Padding = .(8);
		infoPanel.Spacing = 4;

		MeshEditorPageFactory.AddInfoHeader(infoPanel, "Material");
		MeshEditorPageFactory.AddSeparator(infoPanel);

		if (matRes?.Material != null)
		{
			let mat = matRes.Material;
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Shader", scope $"{mat.ShaderName}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Blend Mode", scope $"{mat.PipelineConfig.BlendMode}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Cull Mode", scope $"{mat.PipelineConfig.CullMode}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Property Count", scope $"{mat.PropertyCount}");
		}
		else
		{
			let err = new Label();
			err.SetText("Material data unavailable");
			err.TextColor = .(220, 100, 100, 255);
			infoPanel.AddView(err, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
		}

		let note = new Label();
		note.SetText("(Property editing coming in a follow-up.)");
		note.TextColor = .(140, 140, 155, 255);
		note.FontSize = 11;
		infoPanel.AddView(note, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(18)) });

		root.SetPanes(viewportPanel, infoPanel);
		root.SplitRatio = 0.6f;
		return root;
	}
}
