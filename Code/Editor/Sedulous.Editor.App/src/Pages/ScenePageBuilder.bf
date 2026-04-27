namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Engine.Render;
using Sedulous.UI.Viewport;
using Sedulous.Shell.Input;
using Sedulous.Editor.Core;
using Sedulous.Core.Mathematics;
using Sedulous.Renderer.Passes;
using System.Collections;

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

		// Tree view with drag reorder/reparent
		let hierarchyView = new SceneHierarchyView(page.Scene);
		hierarchyView.ItemHeight = 20;
		container.AddView(hierarchyView, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 0, Weight = 1
		});

		let adapter = new SceneHierarchyAdapter(page.Scene);
		adapter.TreeView = hierarchyView.InternalTreeView;
		hierarchyView.SetAdapter(adapter);
		page.AddOwnedObject(adapter);

		// Wire tree clicks to selection + slow-click rename
		hierarchyView.OnItemClick.Add(new (clickInfo) =>
		{
			let entity = adapter.GetEntityForNode(clickInfo.NodeId);
			if (entity != .Invalid)
			{
				let now = hierarchyView.Context?.TotalTime ?? 0;

				// Slow click: second single-click on same already-selected item
				// after a delay (not a double-click). Threshold: 0.4-1.5s.
				if (clickInfo.ClickCount == 1 &&
					clickInfo.NodeId == adapter.LastClickedNodeId &&
					page.IsSelected(entity))
				{
					let elapsed = now - adapter.LastClickTime;
					if (elapsed > 0.4f && elapsed < 1.5f)
					{
						adapter.StartRename(entity);
						adapter.LastClickedNodeId = -1;
						return;
					}
				}

				adapter.LastClickedNodeId = clickInfo.NodeId;
				adapter.LastClickTime = now;
				page.SelectEntity(entity);
			}
		});

		// Right-click context menu
		hierarchyView.OnItemRightClick.Add(new (nodeId, localX, localY) =>
		{
			let entity = adapter.GetEntityForNode(nodeId);
			if (entity == .Invalid) return;

			page.SelectEntity(entity);
			ShowHierarchyContextMenu(page, adapter, hierarchyView.InternalTreeView, entity, localX, localY);
		});

		// Keyboard shortcuts
		hierarchyView.OnItemKeyDown.Add(new (nodeId, e) =>
		{
			if (e.Key == .Delete)
			{
				let entity = adapter.GetEntityForNode(nodeId);
				if (entity != .Invalid)
				{
					let cmd = new DestroyEntityCommand(page.Scene, entity);
					page.CommandStack.Execute(cmd);
					page.ClearSelection();
					page.MarkDirty();
					e.Handled = true;
				}
			}
			else if (e.Key == .F2)
			{
				let entity = adapter.GetEntityForNode(nodeId);
				if (entity != .Invalid)
				{
					adapter.StartRename(entity);
					e.Handled = true;
				}
			}
		});

		// Rebuild tree and sync TreeView selection when selection changes
		page.OnSelectionChanged.Add(new (p) =>
		{
			adapter.Rebuild();

			// Sync TreeView selection to match page selection
			let selected = p.PrimarySelection;
			if (selected != .Invalid)
			{
				let nodeId = adapter.GetNodeId(selected);
				if (nodeId >= 0)
				{
					let flatAdapter = hierarchyView.InternalTreeView.FlatAdapter;
					if (flatAdapter != null)
					{
						for (int32 i = 0; i < flatAdapter.ItemCount; i++)
						{
							if (flatAdapter.GetNodeId(i) == nodeId)
							{
								hierarchyView.Selection.Select(i);
								break;
							}
						}
					}
				}
			}
			else
			{
				hierarchyView.Selection.ClearSelection();
			}
		});

		// When entity is renamed from hierarchy, refresh inspector
		adapter.OnEntityRenamed.Add(new () =>
		{
			page.OnSelectionChanged(page);
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
		// Container: toolbar on top, viewport below
		let container = new LinearLayout();
		container.Orientation = .Vertical;

		// === Viewport Toolbar ===
		let toolbar = new Toolbar();

		let translateBtn = toolbar.AddToggle("W Translate");
		let rotateBtn = toolbar.AddToggle("E Rotate");
		let scaleBtn = toolbar.AddToggle("R Scale");
		translateBtn.IsChecked = true;

		translateBtn.OnCheckedChanged.Add(new (btn, val) => {
			if (val) { page.GizmoMode = .Translate; rotateBtn.IsChecked = false; scaleBtn.IsChecked = false; }
		});
		rotateBtn.OnCheckedChanged.Add(new (btn, val) => {
			if (val) { page.GizmoMode = .Rotate; translateBtn.IsChecked = false; scaleBtn.IsChecked = false; }
		});
		scaleBtn.OnCheckedChanged.Add(new (btn, val) => {
			if (val) { page.GizmoMode = .Scale; translateBtn.IsChecked = false; rotateBtn.IsChecked = false; }
		});

		toolbar.AddSeparator();

		let worldSpaceBtn = toolbar.AddToggle("World");
		worldSpaceBtn.IsChecked = page.WorldSpace;
		worldSpaceBtn.OnCheckedChanged.Add(new (btn, val) => {
			page.WorldSpace = val;
		});

		container.AddView(toolbar, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.WrapContent
		});

		// === Viewport ===
		let viewportView = new ViewportView();
		viewportView.Initialize(device, vgRenderer);

		container.AddView(viewportView, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 0, Weight = 1
		});

		// Editor camera (independent of scene camera entities)
		let editorCamera = new EditorCamera();
		page.AddOwnedObject(editorCamera);

		// Transform gizmo
		let gizmo = new TransformGizmo();
		page.AddOwnedObject(gizmo);

		// Input handlers (priority order: gizmo first, camera second)
		let gizmoHandler = new GizmoInputHandler(editorCamera, gizmo, page, page.Scene);
		page.AddOwnedObject(gizmoHandler);
		viewportView.AddInputHandler(gizmoHandler);

		let camController = new ViewportCameraController(editorCamera, keyboard);
		page.AddOwnedObject(camController);
		viewportView.AddInputHandler(camController);

		// GPU entity picking pass - added to the scene pipeline
		PickPass pickPass = null;
		if (sceneRenderer != null)
		{
			let pipeline = sceneRenderer.GetPipeline(page.Scene);
			if (pipeline != null)
			{
				pickPass = new PickPass();
				pipeline.AddPass(pickPass);
				// Initialize pick textures with current pipeline dimensions
				pickPass.OnResize(pipeline.OutputWidth, pipeline.OutputHeight);
				gizmoHandler.SetPickPass(pickPass);
			}
		}

		// Wire 3D render callback
		let capturedScene = page.Scene;
		viewportView.OnRender.Add(new (vp, encoder, frameIndex) =>
		{
			if (!vp.IsReady) return;

			// Update fly cam movement
			camController.Update(1.0f / 60.0f);

			// Draw gizmo at selected entity position (before RenderScene so DebugPass picks it up)
			if (sceneRenderer != null)
			{
				let selected = page.PrimarySelection;
				if (selected != .Invalid && capturedScene.IsValid(selected))
				{
					let worldMatrix = capturedScene.GetWorldMatrix(selected);
					gizmo.Position = worldMatrix.Translation;

					// Set gizmo orientation: local space uses entity rotation, world space uses identity
					if (page.WorldSpace)
						gizmo.Orientation = .Identity;
					else
						gizmo.Orientation = capturedScene.GetLocalTransform(selected).Rotation;

					// Scale gizmo to maintain constant screen size
					let camDist = Vector3.Distance(editorCamera.Position, gizmo.Position);
					gizmo.Size = camDist * 0.15f;

					gizmo.Draw(sceneRenderer.RenderContext.DebugDraw, page.GizmoMode);
				}
			}

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

				// Build camera override from editor camera
				let aspect = (vp.RenderHeight > 0) ? (float)vp.RenderWidth / (float)vp.RenderHeight : 1.0f;
				let cameraOverride = editorCamera.GetCameraOverride(aspect);

				sceneRenderer.RenderScene(capturedScene, encoder, vp.ColorTexture, vp.ColorTargetView,
					vp.RenderWidth, vp.RenderHeight, frameIndex, cameraOverride);

				// Poll GPU pick results (readback completed inside Pipeline.Render -> AddPasses)
				if (pickPass != null)
				{
					uint32 entityIndex;
					if (pickPass.TryGetResult(out entityIndex))
						gizmoHandler.OnPickResult(entityIndex);
				}
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

		return container;
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
		page.OnSelectionChanged.Add(new (p) =>
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

			// Entity name editor
			propertyGrid.AddProperty(new StringEditor("Name", name,
				new [=p, =selected] (newName) => {
					p.Scene.SetEntityName(selected, newName);
					p.MarkDirty();
				}));

			// Transform editors (every entity has a transform)
			{
				let transform = p.Scene.GetLocalTransform(selected);
				let capturedEntity = selected;

				let posEditor = new Vector3Editor("Position", transform.Position, category: "Transform");
				posEditor.Setter = new [=p, =capturedEntity] (v) => {
					var t = p.Scene.GetLocalTransform(capturedEntity);
					t.Position = v;
					p.Scene.SetLocalTransform(capturedEntity, t);
				};
				propertyGrid.AddProperty(posEditor);

				// Rotation as euler angles
				let euler = PropertyGridDescriptor.QuaternionToEuler(transform.Rotation);
				let rotEditor = new Vector3Editor("Rotation", euler, min: -360, max: 360, category: "Transform");
				rotEditor.Setter = new [=p, =capturedEntity] (v) => {
					var t = p.Scene.GetLocalTransform(capturedEntity);
					t.Rotation = PropertyGridDescriptor.EulerToQuaternion(v);
					p.Scene.SetLocalTransform(capturedEntity, t);
				};
				propertyGrid.AddProperty(rotEditor);

				let scaleEditor = new Vector3Editor("Scale", transform.Scale, min: 0.001f, max: 10000, category: "Transform");
				scaleEditor.Setter = new [=p, =capturedEntity] (v) => {
					var t = p.Scene.GetLocalTransform(capturedEntity);
					t.Scale = v;
					p.Scene.SetLocalTransform(capturedEntity, t);
				};
				propertyGrid.AddProperty(scaleEditor);
			}

			// Build inspectors for each component via comptime-generated IInspectable
			let components = scope List<Component>();
			p.Scene.GetComponents(selected, components);

			for (let component in components)
			{
				if (let inspectable = component as IInspectable)
				{
					let desc = scope EditorPropertyGridDescriptor(propertyGrid, editorContext?.DialogService, editorContext?.ResourceSystem?.SerializerProvider, editorContext?.ResourceSystem);
					inspectable.DescribeProperties(desc);
				}
			}
		});

		return container;
	}

	// ==================== Hierarchy Context Menu ====================

	private static void ShowHierarchyContextMenu(SceneEditorPage page,
		SceneHierarchyAdapter adapter, TreeView treeView,
		EntityHandle entity, float localX, float localY)
	{
		let ctx = treeView.Context;
		if (ctx == null) return;

		let menu = new ContextMenu();

		// Add child entity submenu
		let addItem = menu.AddSubmenu("Add Child");
		addItem.Submenu.AddItem("Empty", new () =>
		{
			let child = page.Scene.CreateEntity("New Entity");
			page.Scene.SetParent(child, entity);
			page.SelectEntity(child);
			page.MarkDirty();
		});

		menu.AddSeparator();

		// Rename
		menu.AddItem("Rename", new [=adapter, =entity] () =>
		{
			adapter.StartRename(entity);
		});

		// Duplicate (stub)
		menu.AddItem("Duplicate", new () => { }, enabled: false);

		menu.AddSeparator();

		// Delete
		menu.AddItem("Delete", new [=page, =entity] () =>
		{
			let cmd = new DestroyEntityCommand(page.Scene, entity);
			page.CommandStack.Execute(cmd);
			page.ClearSelection();
			page.MarkDirty();
		});

		// Convert local coords to screen coords
		float screenX = localX;
		float screenY = localY;
		View v = treeView /*as View*/;
		while (v != null)
		{
			screenX += v.Bounds.X;
			screenY += v.Bounds.Y;
			v = v.Parent;
		}

		menu.Show(ctx, screenX, screenY);
	}
}
