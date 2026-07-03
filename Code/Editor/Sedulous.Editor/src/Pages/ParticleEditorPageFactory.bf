using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Inspection;
using Sedulous.Resources;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Platform.Input;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Particles;
using Sedulous.Particles.Resources;

namespace Sedulous.Editor.Pages;

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
			return MeshEditorPageFactory.BuildErrorPage(path, "Particle Effect", "No runtime context.", context);

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Particle Effect", "SceneSubsystem or ISceneRenderer unavailable.", context);

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Particle Effect", "Path is not inside any mounted scheme.", context);

		Sedulous.Particles.Resources.ParticleEffectResource fxRes = null;
		if (context.ResourceSystem.LoadResource<Sedulous.Particles.Resources.ParticleEffectResource>(uri) case .Ok(let handle))
			fxRes = handle.Resource;
		if (fxRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Particle Effect", "Failed to load particle effect.", context);

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "ParticlePreview");
		let page = new ParticleEditorPage(path, uri, fxRes, host, context);
		page.SetContentView(BuildParticleView(fxRes, host, page, context));
		return page;
	}

	private static View BuildParticleView(Sedulous.Particles.Resources.ParticleEffectResource fxRes,
		PreviewSceneHost host, ParticleEditorPage page, EditorContext context)
	{
		// Standard resource-page shape (matches the scene editor): tree on
		// the left, then viewport center + inspector docked right. The
		// Play/Stop/Restart toolbar lives on the viewport pane.
		let outer = new SplitView(.Horizontal);
		outer.SplitRatio = 0.2f;
		outer.MinPaneSize = 160;

		let treePanel = BuildTreePanel(fxRes, page);

		// Right of the tree: viewport (center) + inspector (right).
		let inner = new SplitView(.Horizontal);
		inner.SplitRatio = 0.7f;
		inner.MinPaneSize = 200;

		let viewportPane = BuildViewportPanel(host, page);
		let inspectorPane = BuildInspectorPanel(fxRes, page, context);

		inner.SetPanes(viewportPane, inspectorPane);
		outer.SetPanes(treePanel, inner);

		return outer;
	}

	private static View BuildTreePanel(Sedulous.Particles.Resources.ParticleEffectResource fxRes,
		ParticleEditorPage page)
	{
		let panel = new Panel();
		panel.SetStyle(.Background, new ColorDrawable(.(28, 28, 33, 255)));

		let column = new FlexLayout();
		column.Direction = .Vertical;
		panel.AddView(column);

		// Header strip with a padded label.
		let headerPanel = new Panel();
		headerPanel.SetStyle(.Background, new ColorDrawable(.(33, 33, 39, 255)));
		let header = new Label();
		header.SetText("Effect");
		header.FontSize.Value = 12;
		header.VAlign.Value = .Middle;
		header.HAlign.Value = .Left;
		headerPanel.AddView(header);
		column.AddView(headerPanel, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});

		let tree = new ParticleTreeView(page);
		tree.ItemHeight = 22;
		let adapter = new ParticleEffectTreeAdapter(fxRes);
		tree.SetAdapter(adapter);

		// Wire single-click selection.
		tree.OnItemClick.Add(new [=adapter, =tree] (info) =>
		{
			adapter.SelectNode(info.NodeId);
			tree.Invalidate();
		});

		// Right-click on a tree node -> structural-mutation context menu.
		tree.OnItemRightClick.Add(new [=adapter, =tree, =page] (nodeId, localX, localY) =>
		{
			ShowTreeContextMenu(page, adapter, tree.InternalTreeView, nodeId, localX, localY);
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
		page.SetTreeAdapter(adapter);

		column.AddView(tree, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// Auto-select the effect root so the inspector has something to
		// show, and expand it: there's only ever one effect root, so a
		// collapsed root is just an extra click with no benefit. Node IDs
		// are stable across adapter rebuilds (root is always id 1), so the
		// FlattenedTreeAdapter keeps this expanded through later rebuilds.
		if (adapter.RootCount > 0)
		{
			let rootId = adapter.GetChildId(-1, 0);
			adapter.SelectNode(rootId);
			tree.InternalTreeView.FlatAdapter?.Expand(rootId);
		}

		return panel;
	}

	private static View BuildInspectorPanel(Sedulous.Particles.Resources.ParticleEffectResource fxRes,
		ParticleEditorPage page, EditorContext context)
	{
		let panel = new Panel();
		panel.SetStyle(.Background, new ColorDrawable(.(35, 35, 41, 255)));

		let column = new FlexLayout();
		column.Direction = .Vertical;
		panel.AddView(column);

		// Header strip: effect summary. (No page-level preview-texture row -
		// texture is per-system on the asset; pick a System in the tree and
		// set its Texture in the inspector below.)
		let header = new FlexLayout();
		header.Direction = .Horizontal;
		header.Padding = .(8, 4, 8, 4);
		header.Spacing = 12;

		let systemCount = fxRes?.Effect?.Systems.Length ?? 0;
		let systemsLabel = new Label();
		systemsLabel.SetText(scope $"Systems: {systemCount}");
		systemsLabel.FontSize.Value = 11;
		systemsLabel.VAlign.Value = .Middle;
		header.AddView(systemsLabel, new FlexLayout.LayoutParams() {
			Grow = 1, Height = .Match
		});

		column.AddView(header, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});

		// Main property grid (rebuilds on tree selection).
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

		// Viewport fills; transport toolbar sits below it (matches the
		// animation page - scrubber/transport at the bottom of the viewport).
		let viewportPanel = new Panel();
		viewportPanel.SetStyle(.Background, new ColorDrawable(.(25, 25, 30, 255)));
		viewportPanel.AddView(host.Viewport);
		root.AddView(viewportPanel, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		// Toolbar: Play / Stop / Restart.
		let toolbarPanel = new Panel();
		toolbarPanel.SetStyle(.Background, new ColorDrawable(.(28, 28, 33, 255)));
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

		return root;
	}

	// ==================== Tree context menu ====================

	/// Build and show the per-node structural-mutation menu.
	///
	/// Mutations clear inspector selection first (so the property grid drops
	/// any pointers it captured into the soon-to-be-deleted object), then
	/// rebuild the tree and re-select either the new node (Add) or the moved
	/// node (Move Up/Down). Removals leave selection cleared. Every mutation
	/// marks the page dirty and restarts the live preview - structural
	/// changes always need a sim restart so half-built behavior chains don't
	/// spawn malformed particles.
	private static void ShowTreeContextMenu(ParticleEditorPage page,
		ParticleEffectTreeAdapter adapter, TreeView tree,
		int32 nodeId, float localX, float localY)
	{
		let ctx = tree.Context;
		if (ctx == null) return;

		let menu = new ContextMenu();
		let kind = adapter.GetNodeKind(nodeId);

		switch (kind)
		{
		case .Root:
			menu.AddItem("Add System", new [=page, =adapter] () =>
				AddSystem(page, adapter));

		case .System:
			BuildAddInitializerSubmenu(menu, page, adapter, nodeId);
			BuildAddBehaviorSubmenu(menu, page, adapter, nodeId);
			AddMoveMenuItems(menu, page, adapter, nodeId);
			menu.AddSeparator();
			menu.AddItem("Delete System", new [=page, =adapter, =nodeId] () =>
				DeleteSystem(page, adapter, nodeId));

		case .Emitter:
			// Every system has exactly one emitter; nothing to add or remove.
			// Suppress the menu by not adding any items - ContextMenu with
			// zero items just won't show meaningfully, so guard here.
			delete menu;
			return;

		case .InitializersFolder:
			BuildAddInitializerSubmenu(menu, page, adapter, nodeId);

		case .Initializer:
			AddMoveMenuItems(menu, page, adapter, nodeId);
			menu.AddSeparator();
			menu.AddItem("Delete", new [=page, =adapter, =nodeId] () =>
				DeleteInitializer(page, adapter, nodeId));

		case .BehaviorsFolder:
			BuildAddBehaviorSubmenu(menu, page, adapter, nodeId);

		case .Behavior:
			AddMoveMenuItems(menu, page, adapter, nodeId);
			menu.AddSeparator();
			menu.AddItem("Delete", new [=page, =adapter, =nodeId] () =>
				DeleteBehavior(page, adapter, nodeId));
		}

		if (menu.ItemCount == 0)
		{
			delete menu;
			return;
		}

		// Local -> screen coordinate translation, same as ScenePageBuilder.
		float screenX = localX;
		float screenY = localY;
		View v = tree;
		while (v != null)
		{
			screenX += v.Bounds.X;
			screenY += v.Bounds.Y;
			v = v.Parent;
		}
		menu.Show(ctx, screenX, screenY);
	}

	private static void BuildAddInitializerSubmenu(ContextMenu menu,
		ParticleEditorPage page, ParticleEffectTreeAdapter adapter, int32 nodeId)
	{
		let owner = (adapter.GetNodeKind(nodeId) == .System)
			? adapter.GetNodeTarget(nodeId) as ParticleSystem
			: adapter.GetOwningSystem(nodeId);
		if (owner == null) return;

		let sub = menu.AddSubmenu("Add Initializer");
		let ids = scope List<StringView>();
		ParticleTypeRegistry.GetInitializerTypeIds(ids);
		for (let id in ids)
		{
			let typeId = new String(id);
			sub.Submenu.AddOwnedObject(typeId);
			sub.Submenu.AddItem(typeId, new [=page, =adapter, =owner, =typeId] () =>
			{
				let init = ParticleTypeRegistry.CreateInitializer(typeId);
				if (init == null) return;
				page.SelectObject(null);
				owner.AddInitializer(init);
				adapter.Rebuild();
				ReSelect(page, adapter, init);
				MutatedStructure(page);
			});
		}
	}

	private static void BuildAddBehaviorSubmenu(ContextMenu menu,
		ParticleEditorPage page, ParticleEffectTreeAdapter adapter, int32 nodeId)
	{
		let owner = (adapter.GetNodeKind(nodeId) == .System)
			? adapter.GetNodeTarget(nodeId) as ParticleSystem
			: adapter.GetOwningSystem(nodeId);
		if (owner == null) return;

		let sub = menu.AddSubmenu("Add Behavior");
		let ids = scope List<StringView>();
		ParticleTypeRegistry.GetBehaviorTypeIds(ids);
		for (let id in ids)
		{
			let typeId = new String(id);
			sub.Submenu.AddOwnedObject(typeId);
			sub.Submenu.AddItem(typeId, new [=page, =adapter, =owner, =typeId] () =>
			{
				let beh = ParticleTypeRegistry.CreateBehavior(typeId);
				if (beh == null) return;
				page.SelectObject(null);
				owner.AddBehavior(beh);
				adapter.Rebuild();
				ReSelect(page, adapter, beh);
				MutatedStructure(page);
			});
		}
	}

	private static void AddMoveMenuItems(ContextMenu menu,
		ParticleEditorPage page, ParticleEffectTreeAdapter adapter, int32 nodeId)
	{
		let kind = adapter.GetNodeKind(nodeId);
		let idx = adapter.GetDataIndex(nodeId);
		if (idx < 0) return;
		let target = adapter.GetNodeTarget(nodeId);

		int32 siblingCount = -1;
		switch (kind)
		{
		case .System:
			siblingCount = page.EffectResource?.Effect?.SystemCount ?? 0;
		case .Initializer:
			let owner = adapter.GetOwningSystem(nodeId);
			siblingCount = owner != null ? (int32)owner.Initializers.Length : 0;
		case .Behavior:
			let owner = adapter.GetOwningSystem(nodeId);
			siblingCount = owner != null ? (int32)owner.Behaviors.Length : 0;
		default:
			return;
		}

		let canUp = idx > 0;
		let canDown = idx < siblingCount - 1;
		if (!canUp && !canDown) return;

		menu.AddItem("Move Up", new [=page, =adapter, =nodeId, =target] () =>
			MoveNode(page, adapter, nodeId, target, delta: -1), enabled: canUp);
		menu.AddItem("Move Down", new [=page, =adapter, =nodeId, =target] () =>
			MoveNode(page, adapter, nodeId, target, delta: 1), enabled: canDown);
	}

	// ==================== Mutations ====================

	private static void AddSystem(ParticleEditorPage page, ParticleEffectTreeAdapter adapter)
	{
		let effect = page.EffectResource?.Effect;
		if (effect == null) return;

		page.SelectObject(null);
		let sys = BuildMinimalSystem();
		effect.AddSystem(sys);
		adapter.Rebuild();
		ReSelect(page, adapter, sys);
		MutatedStructure(page);
	}

	/// A new system gets the bare minimum needed to render visibly: a
	/// constant-lifetime initializer, point emission, zero-velocity start.
	/// Velocity integration + age advance are built into ParticleSystem.Update,
	/// so no behavior is required. Users add forces / curves / shape from
	/// the context menu.
	private static ParticleSystem BuildMinimalSystem()
	{
		let sys = new ParticleSystem(200);
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(1.0f, 1.0f) });
		sys.AddInitializer(new PositionInitializer());
		sys.AddInitializer(new VelocityInitializer());
		return sys;
	}

	private static void DeleteSystem(ParticleEditorPage page,
		ParticleEffectTreeAdapter adapter, int32 nodeId)
	{
		let effect = page.EffectResource?.Effect;
		if (effect == null) return;
		let idx = adapter.GetDataIndex(nodeId);
		if (idx < 0) return;
		page.SelectObject(null);
		effect.RemoveSystem(idx);
		adapter.Rebuild();
		MutatedStructure(page);
	}

	private static void DeleteInitializer(ParticleEditorPage page,
		ParticleEffectTreeAdapter adapter, int32 nodeId)
	{
		let owner = adapter.GetOwningSystem(nodeId);
		let idx = adapter.GetDataIndex(nodeId);
		if (owner == null || idx < 0) return;
		page.SelectObject(null);
		owner.RemoveInitializer(idx);
		adapter.Rebuild();
		MutatedStructure(page);
	}

	private static void DeleteBehavior(ParticleEditorPage page,
		ParticleEffectTreeAdapter adapter, int32 nodeId)
	{
		let owner = adapter.GetOwningSystem(nodeId);
		let idx = adapter.GetDataIndex(nodeId);
		if (owner == null || idx < 0) return;
		page.SelectObject(null);
		owner.RemoveBehavior(idx);
		adapter.Rebuild();
		MutatedStructure(page);
	}

	private static void MoveNode(ParticleEditorPage page,
		ParticleEffectTreeAdapter adapter, int32 nodeId, Object target, int32 delta)
	{
		let kind = adapter.GetNodeKind(nodeId);
		let idx = adapter.GetDataIndex(nodeId);
		if (idx < 0) return;
		let to = idx + delta;

		page.SelectObject(null);
		switch (kind)
		{
		case .System:
			let effect = page.EffectResource?.Effect;
			if (effect == null) return;
			effect.MoveSystem(idx, to);
		case .Initializer:
			let owner = adapter.GetOwningSystem(nodeId);
			if (owner == null) return;
			owner.MoveInitializer(idx, to);
		case .Behavior:
			let owner = adapter.GetOwningSystem(nodeId);
			if (owner == null) return;
			owner.MoveBehavior(idx, to);
		default:
			return;
		}
		adapter.Rebuild();
		ReSelect(page, adapter, target);
		MutatedStructure(page);
	}

	private static void ReSelect(ParticleEditorPage page,
		ParticleEffectTreeAdapter adapter, Object target)
	{
		let newId = adapter.FindNodeForTarget(target);
		if (newId >= 0)
			adapter.SelectNode(newId);
	}

	private static void MutatedStructure(ParticleEditorPage page)
	{
		page.MarkDirty();
		page.Restart();
	}
}
