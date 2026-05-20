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

/// Creates editor pages for .skeleton files.
/// Opens a 3D viewport debug-drawing the bone hierarchy from bind pose.
class SkeletonEditorPageFactory : IEditorPageFactory
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
		outExtensions.Add(new .(".skeleton"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".skeleton", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Skeleton", "No runtime context.", context);

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Skeleton", "SceneSubsystem or ISceneRenderer unavailable.", context);

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Skeleton", "Path is not inside any mounted scheme.", context);

		Sedulous.Animation.Resources.SkeletonResource skelRes = null;
		if (context.ResourceSystem.LoadResource<Sedulous.Animation.Resources.SkeletonResource>(uri) case .Ok(let handle))
			skelRes = handle.Resource;
		if (skelRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Skeleton", "Failed to load skeleton resource.", context);

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "SkeletonPreview");
		let page = new SkeletonEditorPage(path, skelRes, host);
		page.SetContentView(BuildSkeletonView(skelRes, host));
		return page;
	}

	private static View BuildSkeletonView(Sedulous.Animation.Resources.SkeletonResource skelRes, PreviewSceneHost host)
	{
		let root = new SplitView(.Horizontal);

		let viewportPanel = new Panel();
		viewportPanel.Background = new ColorDrawable(.(25, 25, 30, 255));
		viewportPanel.AddView(host.Viewport);

		let infoPanel = new FlexLayout();
		infoPanel.Direction = .Vertical;
		infoPanel.Padding = .(8);
		infoPanel.Spacing = 4;

		MeshEditorPageFactory.AddInfoHeader(infoPanel, "Skeleton Properties");
		MeshEditorPageFactory.AddSeparator(infoPanel);

		if (skelRes?.Skeleton != null)
		{
			let skeleton = skelRes.Skeleton;
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Bones", scope $"{skeleton.BoneCount}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Roots", scope $"{skeleton.RootBones.Count}");

			// Compact bone list (first ~30 entries).
			let listLabel = new Label();
			listLabel.SetText("Bones:");
			listLabel.TextColor = .(180, 180, 195, 255);
			infoPanel.AddView(listLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });

			let maxList = Math.Min(30, skeleton.BoneCount);
			for (int i = 0; i < maxList; i++)
			{
				let bone = skeleton.Bones[i];
				if (bone == null) continue;
				let row = new Label();
				row.SetText(scope $"  [{i}] {bone.Name}");
				row.TextColor = .(200, 200, 210, 255);
				row.FontSize = 11;
				infoPanel.AddView(row, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(16)) });
			}
			if (skeleton.BoneCount > maxList)
			{
				let more = new Label();
				more.SetText(scope $"  ... +{skeleton.BoneCount - maxList} more");
				more.TextColor = .(140, 140, 155, 255);
				more.FontSize = 11;
				infoPanel.AddView(more, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(16)) });
			}
		}

		root.SetPanes(viewportPanel, infoPanel);
		root.SplitRatio = 0.7f;
		return root;
	}
}
