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
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .skinnedmesh files.
/// Mirrors MeshEditorPageFactory: a 3D preview viewport rendering the
/// skinned mesh (bind pose) with a default material, alongside a metadata
/// panel (vertex/triangle/submesh counts, bounds, skeleton ref).
class SkinnedMeshEditorPageFactory : IEditorPageFactory
{
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
		outExtensions.Add(new .(".skinnedmesh"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".skinnedmesh", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Skinned Mesh", "No runtime context - render subsystem unavailable.", context);

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Skinned Mesh", "SceneSubsystem or ISceneRenderer not available.", context);

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Skinned Mesh", "Path is not inside any mounted scheme.", context);

		SkinnedMeshResource meshRes = null;
		if (context.ResourceSystem.LoadResource<SkinnedMeshResource>(uri) case .Ok(let handle))
			meshRes = handle.Resource;
		if (meshRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Skinned Mesh", "Failed to load skinned mesh resource.", context);

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "SkinnedMeshPreview");
		let page = new SkinnedMeshEditorPage(path, uri, meshRes, host);
		page.SetContentView(BuildView(meshRes, host));
		return page;
	}

	private static View BuildView(SkinnedMeshResource meshRes, PreviewSceneHost host)
	{
		// Standard resource-page shape: viewport left, details docked right.
		let root = new SplitView(.Horizontal);

		let viewportPanel = new Panel();
		viewportPanel.Background = new ColorDrawable(.(25, 25, 30, 255));
		viewportPanel.AddView(host.Viewport);

		let infoPanel = new FlexLayout();
		infoPanel.Direction = .Vertical;
		infoPanel.Padding = .(8);
		infoPanel.Spacing = 4;

		MeshEditorPageFactory.AddInfoHeader(infoPanel, "Skinned Mesh Properties");
		MeshEditorPageFactory.AddSeparator(infoPanel);

		if (meshRes?.Mesh != null)
		{
			let mesh = meshRes.Mesh;
			let triCount = mesh.IndexCount / 3;
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Vertices", scope $"{mesh.VertexCount}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Triangles", scope $"{triCount}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Submeshes", scope $"{mesh.SubMeshes.Count}");
			let b = mesh.Bounds;
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Bounds Min", scope $"({b.Min.X:F2}, {b.Min.Y:F2}, {b.Min.Z:F2})");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Bounds Max", scope $"({b.Max.X:F2}, {b.Max.Y:F2}, {b.Max.Z:F2})");
			let size = b.Max - b.Min;
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Size", scope $"({size.X:F2}, {size.Y:F2}, {size.Z:F2})");
			let skel = meshRes.SkeletonRef.HasPath ? meshRes.SkeletonRef.Path : "(none)";
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Skeleton", skel);
		}
		else
		{
			let errorLabel = new Label();
			errorLabel.SetText("Failed to load skinned mesh");
			errorLabel.TextColor = .(220, 100, 100, 255);
			infoPanel.AddView(errorLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
		}

		root.SetPanes(viewportPanel, infoPanel);
		root.SplitRatio = 0.75f;
		return root;
	}
}
