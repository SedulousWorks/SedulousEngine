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

/// Creates editor pages for .particlefx files.
/// Renders a live particle simulation with Play/Stop/Restart controls.
class ParticleEditorPageFactory : IEditorPageFactory
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
		outExtensions.Add(new .(".particlefx"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".particlefx", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Particle Effect", "No runtime context.");

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Particle Effect", "SceneSubsystem or ISceneRenderer unavailable.");

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Particle Effect", "Path is not inside any mounted scheme.");

		Sedulous.Particles.Resources.ParticleEffectResource fxRes = null;
		if (context.ResourceSystem.LoadResource<Sedulous.Particles.Resources.ParticleEffectResource>(uri) case .Ok(let handle))
			fxRes = handle.Resource;
		if (fxRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Particle Effect", "Failed to load particle effect.");

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "ParticlePreview");
		let page = new ParticleEditorPage(path, uri, fxRes, host);
		page.SetContentView(BuildParticleView(fxRes, host, page));
		return page;
	}

	private static View BuildParticleView(Sedulous.Particles.Resources.ParticleEffectResource fxRes, PreviewSceneHost host, ParticleEditorPage page)
	{
		let root = new FlexLayout();
		root.Direction = .Vertical;

		// Toolbar: Play / Stop / Restart.
		let toolbarPanel = new Panel();
		toolbarPanel.Background = new ColorDrawable(.(28, 28, 33, 255));
		let toolbar = new FlexLayout();
		toolbar.Direction = .Horizontal;
		toolbar.Padding = .(6, 4, 6, 4);
		toolbar.Spacing = 6;
		toolbarPanel.AddView(toolbar);

		let playBtn = new Button("Play");
		playBtn.OnClick.Add(new [=page] (btn) => { page.Play(); });
		toolbar.AddView(playBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(24)) });

		let stopBtn = new Button("Stop");
		stopBtn.OnClick.Add(new [=page] (btn) => { page.Stop(); });
		toolbar.AddView(stopBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(24)) });

		let restartBtn = new Button("Restart");
		restartBtn.OnClick.Add(new [=page] (btn) => { page.Restart(); });
		toolbar.AddView(restartBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(80)), Height = .Fixed(.Px(24)) });

		root.AddView(toolbarPanel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(32)) });

		// Viewport.
		let viewportPanel = new Panel();
		viewportPanel.Background = new ColorDrawable(.(25, 25, 30, 255));
		viewportPanel.AddView(host.Viewport);
		root.AddView(viewportPanel, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		// Info strip at bottom.
		let infoPanel = new Panel();
		infoPanel.Background = new ColorDrawable(.(20, 20, 25, 255));
		let info = new FlexLayout();
		info.Direction = .Vertical;
		info.Padding = .(8);
		info.Spacing = 4;
		infoPanel.AddView(info);

		let systemCount = fxRes?.Effect?.Systems.Length ?? 0;
		MeshEditorPageFactory.AddInfoRow(info, "Systems", scope $"{systemCount}");

		root.AddView(infoPanel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(40)) });

		return root;
	}
}
