namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Shell.Input;
using Sedulous.Editor.Core;
using Sedulous.Core.Mathematics;

/// Builds the internal layout for a SceneEditorPage:
/// Hierarchy (left) | Viewport (center) | Inspector (right)
static class ScenePageBuilder
{
	public static View Build(SceneEditorPage page, EditorContext editorContext,
		IDevice device, VGRenderer vgRenderer, ISceneRenderer sceneRenderer = null,
		IKeyboard keyboard = null)
	{
		let split = new SplitView(.Horizontal);

		let hierarchy = BuildHierarchy(page);
		let centerAndRight = BuildCenterAndRight(page, editorContext, device, vgRenderer, sceneRenderer, keyboard);

		split.SetPanes(hierarchy, centerAndRight);
		split.SplitRatio = 0.2f;

		return split;
	}

	private static View BuildHierarchy(SceneEditorPage page)
	{
		let container = new LinearLayout();
		container.Orientation = .Vertical;

		// Toolbar
		let toolbar = new LinearLayout();
		toolbar.Orientation = .Horizontal;
		toolbar.Spacing = 4;
		toolbar.Padding = .(4, 2, 4, 2);
		container.AddView(toolbar, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.WrapContent
		});

		let addBtn = new Button();
		addBtn.SetText("+");
		addBtn.OnClick.Add(new /*[page]*/ (btn) =>
		{
			let entity = page.Scene.CreateEntity("New Entity");
			page.SelectEntity(entity);
			page.MarkDirty();
		});
		toolbar.AddView(addBtn, new LinearLayout.LayoutParams() { Height = 24 });

		let deleteBtn = new Button();
		deleteBtn.SetText("-");
		deleteBtn.OnClick.Add(new /*[page]*/ (btn) =>
		{
			let selected = page.PrimarySelection;
			if (selected != .Invalid)
			{
				let cmd = new DestroyEntityCommand(page.Scene, selected);
				page.CommandStack.Execute(cmd);
				page.ClearSelection();
				page.MarkDirty();
			}
		});
		toolbar.AddView(deleteBtn, new LinearLayout.LayoutParams() { Height = 24 });

		// Separator
		let sep = new Panel();
		sep.Background = new ColorDrawable(.(60, 65, 80, 255));
		container.AddView(sep, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 1
		});

		// Tree view
		let treeView = new TreeView();
		treeView.ItemHeight = 20;
		container.AddView(treeView, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 0, Weight = 1
		});

		let adapter = new SceneHierarchyAdapter(page.Scene);
		treeView.SetAdapter(adapter);
		page.AddOwnedObject(adapter);

		// Wire tree clicks to selection
		treeView.OnItemClick.Add(new (clickInfo) =>
		{
			let entity = adapter.GetEntityForNode(clickInfo.NodeId);
			if (entity != .Invalid)
				page.SelectEntity(entity);
		});

		// Rebuild tree when selection or scene changes
		page.OnSelectionChanged.Add(new (p) =>
		{
			adapter.Rebuild();
		});

		return container;
	}

	private static View BuildCenterAndRight(SceneEditorPage page, EditorContext editorContext,
		IDevice device, VGRenderer vgRenderer, ISceneRenderer sceneRenderer, IKeyboard keyboard)
	{
		let split = new SplitView(.Horizontal);

		let viewport = BuildViewport(page, device, vgRenderer, sceneRenderer, keyboard);
		let inspector = BuildInspector(page, editorContext);

		split.SetPanes(viewport, inspector);
		split.SplitRatio = 0.7f;

		return split;
	}

	private static View BuildViewport(SceneEditorPage page, IDevice device,
		VGRenderer vgRenderer, ISceneRenderer sceneRenderer, IKeyboard keyboard)
	{
		let viewportView = new ViewportView();
		viewportView.Initialize(device, vgRenderer);

		// Camera controller (orbit/fly)
		let camController = new ViewportCameraController(page.Scene, keyboard);
		camController.Attach(viewportView);
		page.AddOwnedObject(camController);

		// Wire 3D render callback
		viewportView.OnRender.Add(new [=sceneRenderer, =camController] (vp, encoder, frameIndex) =>
		{
			if (!vp.IsReady) return;

			// Update fly cam movement
			camController.Update(1.0f / 60.0f);

			encoder.TransitionTexture(vp.ColorTexture, .Undefined, .RenderTarget);

			if (sceneRenderer != null)
			{
				// Clear + render via engine pipeline
				ColorAttachment[1] clearAttachments = .(.()
				{
					View = vp.ColorTargetView,
					LoadOp = .Clear,
					StoreOp = .Store,
					ClearValue = .(0, 0, 0, 1)
				});
				RenderPassDesc clearDesc = .() { ColorAttachments = .(clearAttachments) };
				let clearPass = encoder.BeginRenderPass(clearDesc);
				clearPass?.End();

				sceneRenderer.RenderScene(encoder, vp.ColorTexture, vp.ColorTargetView,
					vp.RenderWidth, vp.RenderHeight, frameIndex);
			}
			else
			{
				// Fallback: just clear
				ColorAttachment[1] colorAttachments = .(.()
				{
					View = vp.ColorTargetView,
					LoadOp = .Clear,
					StoreOp = .Store,
					ClearValue = .(0.15f, 0.15f, 0.18f, 1)
				});
				RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
				let renderPass = encoder.BeginRenderPass(passDesc);
				renderPass?.End();

				encoder.TransitionTexture(vp.ColorTexture, .RenderTarget, .ShaderRead);
			}
		});

		return viewportView;
	}

	private static View BuildInspector(SceneEditorPage page, EditorContext editorContext)
	{
		let container = new LinearLayout();
		container.Orientation = .Vertical;
		container.Padding = .(4);

		let headerLabel = new Label();
		headerLabel.SetText("Inspector");
		headerLabel.FontSize = 13;
		headerLabel.TextColor = .(128, 128, 140, 255);
		container.AddView(headerLabel, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 24
		});

		let sep = new Panel();
		sep.Background = new ColorDrawable(.(60, 65, 80, 255));
		container.AddView(sep, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 1
		});

		let propertyGrid = new PropertyGrid();
		container.AddView(propertyGrid, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 0, Weight = 1
		});

		// Wire selection changes to inspector rebuild
		page.OnSelectionChanged.Add(new /*[page, editorContext, headerLabel, propertyGrid]*/ (p) =>
		{
			propertyGrid.Clear();

			let selected = p.PrimarySelection;
			if (selected == .Invalid || !p.Scene.IsValid(selected))
			{
				headerLabel.SetText("Inspector");
				return;
			}

			let name = scope String();
			name.Set(p.Scene.GetEntityName(selected));
			headerLabel.SetText(scope $"Inspector - {name}");

			// TODO: Get components, build inspectors (reflection or custom)
			// For now just show entity name
			propertyGrid.AddProperty(new StringEditor("Name", name));
		});

		return container;
	}
}
