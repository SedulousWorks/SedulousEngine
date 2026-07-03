using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Platform.Input;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
namespace Sedulous.Editor.Pages;

/// Creates editor pages for .animation files.
/// Phase 5.5: metadata + scrubber UI; full skeletal preview deferred.
class AnimationEditorPageFactory : IEditorPageFactory
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
		outExtensions.Add(new .(".animation"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".animation", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation", "No runtime context.", context);

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation", "SceneSubsystem or ISceneRenderer unavailable.", context);

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation", "Path is not inside any mounted scheme.", context);

		Sedulous.Animation.Resources.AnimationClipResource clipRes = null;
		if (context.ResourceSystem.LoadResource<Sedulous.Animation.Resources.AnimationClipResource>(uri) case .Ok(let handle))
			clipRes = handle.Resource;
		if (clipRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation", "Failed to load animation clip.", context);

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "AnimationPreview");
		let page = new AnimationEditorPage(path, uri, clipRes, host, context);
		page.SetContentView(BuildAnimationView(clipRes, host, page, context));
		return page;
	}

	private static View BuildAnimationView(Sedulous.Animation.Resources.AnimationClipResource clipRes, PreviewSceneHost host, AnimationEditorPage page, EditorContext context)
	{
		// Standard resource-page shape: viewport center, details docked
		// right, a thin transport strip below the viewport (room for a
		// real timeline later). Matches MeshEditorPageFactory.
		let root = new SplitView(.Horizontal);
		root.SplitRatio = 0.8f;
		root.MinPaneSize = 200;

		// Left pane: viewport (fills) + transport strip below it.
		let left = new FlexLayout();
		left.Direction = .Vertical;

		let viewportPanel = new Panel();
		viewportPanel.SetStyle(.Background, new ColorDrawable(.(25, 25, 30, 255)));
		viewportPanel.AddView(host.Viewport);
		left.AddView(viewportPanel, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		let transportPanel = new Panel();
		transportPanel.SetStyle(.Background, new ColorDrawable(.(20, 20, 25, 255)));
		let controls = new FlexLayout();
		controls.Direction = .Horizontal;
		controls.Spacing = 6;
		controls.Padding = .(8);
		transportPanel.AddView(controls);

		let playBtn = new Button("Play");
		playBtn.OnClick.Add(new [=page] (btn) => { page.Play(); });
		controls.AddView(playBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(26)) });

		let pauseBtn = new Button("Pause");
		pauseBtn.OnClick.Add(new [=page] (btn) => { page.Pause(); });
		controls.AddView(pauseBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(26)) });

		let stopBtn = new Button("Stop");
		stopBtn.OnClick.Add(new [=page] (btn) => { page.Stop(); });
		controls.AddView(stopBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(26)) });

		let dur = clipRes?.Clip?.Duration ?? 1;
		let scrubber = new Slider(0, dur, 0);
		scrubber.OnValueChanged.Add(new [=page] (s, val) => { page.ScrubTime = val; });
		controls.AddView(scrubber, new FlexLayout.LayoutParams() { Grow = 1, Height = .Fixed(.Px(26)) });

		// Fixed strip, sized to exactly one 26px control row + 8px padding
		// each side - no metadata crammed in here, so it can't overflow.
		left.AddView(transportPanel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(42)) });

		// Right pane: details column (full panel height - no clipping).
		let infoPanel = new FlexLayout();
		infoPanel.Direction = .Vertical;
		infoPanel.Padding = .(8);
		infoPanel.Spacing = 4;

		MeshEditorPageFactory.AddInfoHeader(infoPanel, "Animation");
		MeshEditorPageFactory.AddSeparator(infoPanel);
		MeshEditorPageFactory.AddInfoRow(infoPanel, "Duration", scope $"{dur:F2} s");
		MeshEditorPageFactory.AddInfoRow(infoPanel, "Looping", (clipRes?.Clip?.IsLooping ?? false) ? "Yes" : "No");
		MeshEditorPageFactory.AddInfoRow(infoPanel, "Position Tracks", scope $"{clipRes?.PositionTrackCount ?? 0}");
		MeshEditorPageFactory.AddInfoRow(infoPanel, "Rotation Tracks", scope $"{clipRes?.RotationTrackCount ?? 0}");
		MeshEditorPageFactory.AddInfoRow(infoPanel, "Scale Tracks", scope $"{clipRes?.ScaleTrackCount ?? 0}");

		// === Preview rig section ===
		MeshEditorPageFactory.AddSeparator(infoPanel);
		MeshEditorPageFactory.AddInfoHeader(infoPanel, "Preview Rig");

		// Mesh picker row.
		let meshRow = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };
		let meshLabel = new Label();
		meshLabel.SetText("Mesh:");
		meshLabel.TextColor.Value = .(180, 180, 195, 255);
		meshLabel.FontSize.Value = 11;
		meshRow.AddView(meshLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(64)), Height = .Match });

		let meshPathLabel = new Label();
		meshPathLabel.SetText("(none)");
		meshPathLabel.TextColor.Value = .(220, 220, 230, 255);
		meshPathLabel.FontSize.Value = 11;
		meshRow.AddView(meshPathLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		let pickMeshBtn = new Button("Pick");
		pickMeshBtn.OnClick.Add(new [=context, =page] (btn) =>
		{
			let ctx = page.ContentView?.Context;
			if (ctx == null || context == null) return;
			let dlg = new AssetPickerDialog(context, ".skinnedmesh",
				new [=page] (path, id) => { page.SetMeshUri(path); });
			dlg.Show(ctx);
		});
		meshRow.AddView(pickMeshBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(48)), Height = .Fixed(.Px(22)) });

		let clearMeshBtn = new Button("Clear");
		clearMeshBtn.OnClick.Add(new [=page] (btn) => page.SetMeshUri(""));
		meshRow.AddView(clearMeshBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(50)), Height = .Fixed(.Px(22)) });
		infoPanel.AddView(meshRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });

		// Skeleton picker row.
		let skelRow = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };
		let skelLabel = new Label();
		skelLabel.SetText("Skeleton:");
		skelLabel.TextColor.Value = .(180, 180, 195, 255);
		skelLabel.FontSize.Value = 11;
		skelRow.AddView(skelLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(64)), Height = .Match });

		let skelPathLabel = new Label();
		skelPathLabel.SetText("(none)");
		skelPathLabel.TextColor.Value = .(220, 220, 230, 255);
		skelPathLabel.FontSize.Value = 11;
		skelRow.AddView(skelPathLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		let pickSkelBtn = new Button("Pick");
		pickSkelBtn.OnClick.Add(new [=context, =page] (btn) =>
		{
			let ctx = page.ContentView?.Context;
			if (ctx == null || context == null) return;
			let dlg = new AssetPickerDialog(context, ".skeleton",
				new [=page] (path, id) => { page.SetSkeletonUri(path); });
			dlg.Show(ctx);
		});
		skelRow.AddView(pickSkelBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(48)), Height = .Fixed(.Px(22)) });

		let clearSkelBtn = new Button("Clear");
		clearSkelBtn.OnClick.Add(new [=page] (btn) => page.SetSkeletonUri(""));
		skelRow.AddView(clearSkelBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(50)), Height = .Fixed(.Px(22)) });
		infoPanel.AddView(skelRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });

		page.RegisterStateLabels(meshPathLabel, skelPathLabel);

		root.SetPanes(left, infoPanel);
		return root;
	}
}
