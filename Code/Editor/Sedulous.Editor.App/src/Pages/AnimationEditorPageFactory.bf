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
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation", "No runtime context.");

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation", "SceneSubsystem or ISceneRenderer unavailable.");

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation", "Path is not inside any mounted scheme.");

		Sedulous.Animation.Resources.AnimationClipResource clipRes = null;
		if (context.ResourceSystem.LoadResource<Sedulous.Animation.Resources.AnimationClipResource>(uri) case .Ok(let handle))
			clipRes = handle.Resource;
		if (clipRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation", "Failed to load animation clip.");

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "AnimationPreview");
		let page = new AnimationEditorPage(path, clipRes, host);
		page.SetContentView(BuildAnimationView(clipRes, host, page));
		return page;
	}

	private static View BuildAnimationView(Sedulous.Animation.Resources.AnimationClipResource clipRes, PreviewSceneHost host, AnimationEditorPage page)
	{
		let root = new FlexLayout();
		root.Direction = .Vertical;

		// Viewport on top (currently empty - clip preview is metadata-only this phase).
		let viewportPanel = new Panel();
		viewportPanel.Background = new ColorDrawable(.(25, 25, 30, 255));
		viewportPanel.AddView(host.Viewport);
		root.AddView(viewportPanel, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		// Bottom: controls + metadata strip.
		let bottomPanel = new Panel();
		bottomPanel.Background = new ColorDrawable(.(20, 20, 25, 255));
		let bottom = new FlexLayout();
		bottom.Direction = .Vertical;
		bottom.Padding = .(8);
		bottom.Spacing = 6;
		bottomPanel.AddView(bottom);

		// Controls row.
		let controls = new FlexLayout();
		controls.Direction = .Horizontal;
		controls.Spacing = 6;

		let playBtn = new Button("Play");
		playBtn.OnClick.Add(new [=page] (btn) => { page.Play(); });
		controls.AddView(playBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(26)) });

		let pauseBtn = new Button("Pause");
		pauseBtn.OnClick.Add(new [=page] (btn) => { page.Pause(); });
		controls.AddView(pauseBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(26)) });

		let stopBtn = new Button("Stop");
		stopBtn.OnClick.Add(new [=page] (btn) => { page.Stop(); });
		controls.AddView(stopBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(26)) });

		// Scrubber.
		let dur = clipRes?.Clip?.Duration ?? 1;
		let scrubber = new Slider(0, dur, 0);
		scrubber.OnValueChanged.Add(new [=page] (s, val) => { page.ScrubTime = val; });
		controls.AddView(scrubber, new FlexLayout.LayoutParams() { Grow = 1, Height = .Fixed(.Px(26)) });

		bottom.AddView(controls, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(30)) });

		// Metadata rows.
		MeshEditorPageFactory.AddInfoRow(bottom, "Duration", scope $"{dur:F2} s");
		MeshEditorPageFactory.AddInfoRow(bottom, "Looping", (clipRes?.Clip?.IsLooping ?? false) ? "Yes" : "No");
		MeshEditorPageFactory.AddInfoRow(bottom, "Position Tracks", scope $"{clipRes?.PositionTrackCount ?? 0}");
		MeshEditorPageFactory.AddInfoRow(bottom, "Rotation Tracks", scope $"{clipRes?.RotationTrackCount ?? 0}");
		MeshEditorPageFactory.AddInfoRow(bottom, "Scale Tracks", scope $"{clipRes?.ScaleTrackCount ?? 0}");

		root.AddView(bottomPanel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(160)) });
		return root;
	}
}
