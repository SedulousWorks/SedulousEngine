using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Inspection;
using Sedulous.Resources;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Shell.Input;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Particles;

namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .particlefx files.
/// Renders the authoring tree + inspector on the left/top and a live preview
/// viewport with Play/Stop/Restart controls on the right.
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
		let page = new ParticleEditorPage(path, uri, fxRes, host, context);
		page.SetContentView(BuildParticleView(fxRes, host, page, context));
		return page;
	}

	private static View BuildParticleView(Sedulous.Particles.Resources.ParticleEffectResource fxRes,
		PreviewSceneHost host, ParticleEditorPage page, EditorContext context)
	{
		// Outer horizontal split: tree on the left, inspector+viewport on the right.
		let outer = new SplitView(.Horizontal);
		outer.SplitRatio = 0.25f;
		outer.MinPaneSize = 160;

		let treePanel = BuildTreePanel(fxRes, page);

		// Right pane is a vertical split: property grid on top, viewport on bottom.
		let inner = new SplitView(.Vertical);
		inner.SplitRatio = 0.45f;
		inner.MinPaneSize = 120;

		let inspectorPane = BuildInspectorPanel(fxRes, page, context);
		let viewportPane = BuildViewportPanel(host, page);

		inner.SetPanes(inspectorPane, viewportPane);
		outer.SetPanes(treePanel, inner);

		return outer;
	}

	private static View BuildTreePanel(Sedulous.Particles.Resources.ParticleEffectResource fxRes,
		ParticleEditorPage page)
	{
		let panel = new Panel();
		panel.Background = new ColorDrawable(.(28, 28, 33, 255));

		let column = new FlexLayout();
		column.Direction = .Vertical;
		panel.AddView(column);

		// Header strip with a padded label.
		let headerPanel = new Panel();
		headerPanel.Background = new ColorDrawable(.(33, 33, 39, 255));
		let header = new Label();
		header.SetText("Effect");
		header.FontSize = 12;
		header.VAlign = .Middle;
		header.HAlign = .Left;
		headerPanel.AddView(header);
		column.AddView(headerPanel, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});

		let tree = new TreeView();
		tree.ItemHeight = 22;
		let adapter = new ParticleEffectTreeAdapter(fxRes);
		tree.SetAdapter(adapter);

		// Wire single-click selection.
		tree.OnItemClick.Add(new [=adapter, =tree] (info) =>
		{
			adapter.SelectNode(info.NodeId);
			tree.Invalidate();
		});

		// Tree adapter forwards selection to the page so the property grid
		// rebuilds against the picked object.
		adapter.OnObjectSelected.Add(new [=page] (obj) =>
		{
			page.SelectObject(obj);
		});

		// TreeView keeps a raw pointer to the adapter via SetAdapter, so the
		// adapter must outlive the view tree. Stash it on the page for cleanup.
		page.AddOwnedObject(adapter);

		column.AddView(tree, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// Auto-select the effect root so the inspector has something to show.
		if (adapter.RootCount > 0)
			adapter.SelectNode(adapter.GetChildId(-1, 0));

		return panel;
	}

	private static View BuildInspectorPanel(Sedulous.Particles.Resources.ParticleEffectResource fxRes,
		ParticleEditorPage page, EditorContext context)
	{
		let panel = new Panel();
		panel.Background = new ColorDrawable(.(35, 35, 41, 255));

		let column = new FlexLayout();
		column.Direction = .Vertical;
		panel.AddView(column);

		// Header strip: effect summary.
		let header = new FlexLayout();
		header.Direction = .Horizontal;
		header.Padding = .(8, 4, 8, 4);
		header.Spacing = 12;

		let systemCount = fxRes?.Effect?.Systems.Length ?? 0;
		let systemsLabel = new Label();
		systemsLabel.SetText(scope $"Systems: {systemCount}");
		systemsLabel.FontSize = 11;
		systemsLabel.VAlign = .Middle;
		header.AddView(systemsLabel, new FlexLayout.LayoutParams() {
			Grow = 1, Height = .Match
		});

		column.AddView(header, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});

		// Property grid.
		let grid = new PropertyGrid();
		column.AddView(grid, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// On selection change: clear grid, build descriptor, dispatch to
		// DescribeProperties via IInspectable, then hook each editor's
		// OnEditEnd so commits flow through page.MarkDirty +
		// page.RestartIfSpawnTime. Hooking after DescribeProperties keeps
		// PropertyGridDescriptor free of editor-page concerns - it just
		// builds editors; the page subscribes to their commit events.
		page.OnSelectionChanged.Add(new [=grid, =page, =context] (obj) =>
		{
			grid.Clear();
			if (obj == null) return;

			let desc = scope EditorPropertyGridDescriptor(grid,
				context?.DialogService,
				context?.ResourceSystem?.SerializerProvider,
				context?.ResourceSystem,
				context);

			if (let inspectable = obj as IInspectable)
				inspectable.DescribeProperties(desc);

			for (let editor in grid.Properties)
			{
				editor.OnEditEnd.Add(new [=page, =obj] (e) =>
				{
					page.MarkDirty();
					page.RestartIfSpawnTime(obj);
				});
			}
		});

		return panel;
	}

	private static View BuildViewportPanel(PreviewSceneHost host, ParticleEditorPage page)
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

		return root;
	}
}
