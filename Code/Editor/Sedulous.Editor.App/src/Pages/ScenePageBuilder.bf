namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Renderer.Debug;
using Sedulous.Engine.Render;
using Sedulous.UI.Viewport;
using Sedulous.Shell.Input;
using Sedulous.Editor.Core;
using Sedulous.Core.Mathematics;
using Sedulous.Renderer.Passes;
using System.Collections;
using Sedulous.Inspection;
using Sedulous.Resources;
using Sedulous.Engine;
using Sedulous.Engine.Core.Resources;

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
		let container = new FlexLayout();
		container.Direction = .Vertical;

		// Toolbar
		let toolbar = new FlexLayout();
		toolbar.Direction = .Horizontal;
		toolbar.Spacing = 4;
		toolbar.Padding = .(4, 2, 4, 2);
		container.AddView(toolbar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		let addBtn = new Button("+");
		addBtn.OnClick.Add(new /*[page]*/ (btn) =>
		{
			let entity = page.Scene.CreateEntity("New Entity");
			page.SelectEntity(entity);
			page.MarkDirty();
		});
		toolbar.AddView(addBtn, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(24)) });

		let deleteBtn = new Button("-");
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
		toolbar.AddView(deleteBtn, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(24)) });

		// Separator
		let sep = new Panel();
		sep.SetStyle(.Background, new ColorDrawable(.(60, 65, 80, 255)));
		container.AddView(sep, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(1))
		});

		// Tree view with drag reorder/reparent
		let hierarchyView = new SceneHierarchyView(page.Scene);
		hierarchyView.ItemHeight = 20;
		container.AddView(hierarchyView, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
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

		// Asset drop handler (e.g., .prefab from asset browser)
		hierarchyView.OnAssetDropped.Add(new [=page, =adapter] (assetData, parentEntity) =>
		{
			OnAssetDroppedIntoHierarchy(page, adapter, assetData, parentEntity);
		});

		return container;
	}

	private static View BuildCenterAndRight(SceneEditorPage page, EditorContext editorContext,
		IDevice device, VGRenderer vgRenderer, ISceneRenderer sceneRenderer, IKeyboard keyboard)
	{
		let split = new SplitView(.Horizontal);

		let viewport = BuildViewport(page, editorContext, device, vgRenderer, sceneRenderer, keyboard);
		let inspector = BuildInspector(page, editorContext);

		split.SetPanes(viewport, inspector);
		split.SplitRatio = 0.7f;

		return split;
	}

	private static View BuildViewport(SceneEditorPage page, EditorContext editorContext,
		IDevice device, VGRenderer vgRenderer, ISceneRenderer sceneRenderer, IKeyboard keyboard)
	{
		// Container: toolbar on top, viewport below
		let container = new FlexLayout();
		container.Direction = .Vertical;

		// === Viewport Toolbar ===
		let toolbar = new Toolbar();

		let translateBtn = toolbar.AddToggle("W");
		if (EditorIcons.TranslateIcon != null)
			translateBtn.SetIcon(new (ctx, rect) => { EditorIcons.TranslateIcon.Draw(ctx, rect); });
		let rotateBtn = toolbar.AddToggle("E");
		if (EditorIcons.RotateIcon != null)
			rotateBtn.SetIcon(new (ctx, rect) => { EditorIcons.RotateIcon.Draw(ctx, rect); });
		let scaleBtn = toolbar.AddToggle("R");
		if (EditorIcons.ScaleIcon != null)
			scaleBtn.SetIcon(new (ctx, rect) => { EditorIcons.ScaleIcon.Draw(ctx, rect); });
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
		worldSpaceBtn.SetIcon(new (ctx, rect) => {
			let icon = page.WorldSpace ? EditorIcons.WorldSpaceIcon : EditorIcons.LocalSpaceIcon;
			if (icon != null) icon.Draw(ctx, rect);
		});
		worldSpaceBtn.IsChecked = page.WorldSpace;
		worldSpaceBtn.OnCheckedChanged.Add(new (btn, val) => {
			page.WorldSpace = val;
			btn.SetText(val ? "World" : "Local");
		});

		toolbar.AddSeparator();

		let gridBtn = toolbar.AddToggle("Grid");
		if (EditorIcons.GridIcon != null)
			gridBtn.SetIcon(new (ctx, rect) => { EditorIcons.GridIcon.Draw(ctx, rect); });
		gridBtn.IsChecked = page.ShowGrid;
		gridBtn.OnCheckedChanged.Add(new (btn, val) => { page.ShowGrid = val; });

		container.AddView(toolbar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// === Viewport ===
		// Wrap the viewport + camera-preview overlay in a FrameLayout so the
		// preview can anchor over the top-right corner of the viewport.
		let viewportStack = new FrameLayout();
		container.AddView(viewportStack, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		let viewportView = new ViewportView();
		viewportView.Initialize(device, vgRenderer);
		viewportStack.AddView(viewportView, new FrameLayout.LayoutParams() {
			Width = .Match, Height = .Match
		});

		// Camera preview overlay - hidden until a camera-bearing entity is
		// selected, with a Pin toggle to stay visible after deselection. Runs
		// through its own ISceneRenderer pipeline (keyed on the panel) so it
		// doesn't thrash the main viewport's SceneDepth.
		CameraPreviewPanel previewPanel = null;
		if (sceneRenderer != null)
		{
			previewPanel = new CameraPreviewPanel(device, vgRenderer, sceneRenderer, page.Scene);
			viewportStack.AddView(previewPanel, new FrameLayout.LayoutParams()
			{
				Width = .Fixed(.Px(280)),
				Height = .Fixed(.Px(180)),
				Margin = .(0, 12, 12, 0),
				Gravity = .TopRight,
			});

			let capturedPanel = previewPanel;
			capturedPanel.OnRequestClose.Add(new () => {
				capturedPanel.SetCamera(.Invalid, null);
			});

			let capturedScene2 = page.Scene;
			page.OnSelectionChanged.Add(new (changedPage) => {
				let sel = changedPage.PrimarySelection;
				if (sel == .Invalid || !capturedScene2.IsValid(sel))
				{
					capturedPanel.HandleSelectionChanged(.Invalid, null);
					return;
				}
				CameraComponent cam = null;
				let comps = scope System.Collections.List<Component>();
				capturedScene2.GetComponents(sel, comps);
				for (let c in comps)
				{
					if (let cc = c as CameraComponent)
					{
						cam = cc;
						break;
					}
				}
				capturedPanel.HandleSelectionChanged(sel, cam);
			});
		}

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

			// Draw gizmos into the pipeline's per-scene DebugDraw (not the global one)
			// so they only appear in this viewport.
			if (sceneRenderer != null)
			{
				let pipeline = sceneRenderer.GetPipeline(capturedScene);
				let pipelineDbg = (pipeline != null) ? pipeline.DebugDraw : sceneRenderer.RenderContext.DebugDraw;

				// World-XZ debug grid (toggled via the viewport toolbar)
				if (page.ShowGrid)
					DrawSceneGrid(pipelineDbg);

				// Transform gizmo for selected entity
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

					gizmo.Draw(pipelineDbg, page.GizmoMode, editorCamera.Position);
				}

				// Component gizmo renderers (light wireframes, camera frustums, etc.)
				let aspect = (vp.RenderHeight > 0) ? (float)vp.RenderWidth / (float)vp.RenderHeight : 1.0f;
				let camOverride = editorCamera.GetCameraOverride(aspect);
				GizmoContext gizmoCtx = .()
				{
					DebugDraw = pipelineDbg,
					Scene = capturedScene,
					ViewProjectionMatrix = camOverride.ViewMatrix * camOverride.ProjectionMatrix,
					CameraPosition = editorCamera.Position,
					ViewportWidth = vp.RenderWidth,
					ViewportHeight = vp.RenderHeight
				};

				for (let entity in capturedScene.Entities)
				{
					if (!capturedScene.IsValid(entity)) continue;

					let components = scope List<Component>();
					capturedScene.GetComponents(entity, components);

					for (let comp in components)
					{
						let renderer = editorContext.GetGizmoRenderer(comp.GetType());
						if (renderer != null)
						{
							if (renderer.DrawWhenUnselected || entity == selected)
								renderer.Draw(comp, gizmoCtx);
						}
					}
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
		let container = new FlexLayout();
		container.Direction = .Vertical;
		container.Padding = .(4);

		let headerLabel = new Label();
		headerLabel.SetText("Inspector");
		headerLabel.FontSize.Value = 13;
		headerLabel.TextColor.Value = .(128, 128, 140, 255);
		container.AddView(headerLabel, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});

		let sep = new Panel();
		sep.SetStyle(.Background, new ColorDrawable(.(60, 65, 80, 255)));
		container.AddView(sep, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(1))
		});

		let propertyGrid = new PropertyGrid();
		container.AddView(propertyGrid, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// "Add Component" button - below property grid, visible when entity is selected
		let addCompBtn = new Button("Add Component");
		addCompBtn.Visibility = .Gone;
		container.AddView(addCompBtn, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(28))
		});

		// Wire selection changes to inspector rebuild
		page.OnSelectionChanged.Add(new (p) =>
		{
			propertyGrid.Clear();

			let selected = p.PrimarySelection;
			if (selected == .Invalid || !p.Scene.IsValid(selected))
			{
				headerLabel.SetText("Scene Settings");
				addCompBtn.Visibility = .Gone;

				// Show inspectable scene modules when no entity is selected
				for (let module in p.Scene.Modules)
				{
					if (let inspectable = module as IInspectable)
					{
						let desc = scope EditorPropertyGridDescriptor(propertyGrid, editorContext?.DialogService, editorContext?.ResourceSystem?.SerializerProvider, editorContext?.ResourceSystem, editorContext);
						inspectable.DescribeProperties(desc);
					}
				}

				return;
			}

			addCompBtn.Visibility = .Visible;

			let name = scope String();
			name.Set(p.Scene.GetEntityName(selected));
			headerLabel.SetText(scope $"Inspector - {name}");

			// Entity name editor
			propertyGrid.AddProperty(new StringEditor("Name", name,
				new [=p, =selected] (newName) => {
					p.Scene.SetEntityName(selected, newName);
					p.MarkDirty();
				}));

			// Check if this entity is a prefab instance (for override tracking)
			let tagMgr = p.Scene.GetModule<PrefabInstanceTagManager>();
			let isPrefabInstance = tagMgr != null && tagMgr.GetForEntity(selected) != null;

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
				if (isPrefabInstance)
					posEditor.OnEditEnd.Add(new [=p, =capturedEntity] (e) => {
						p.Scene.LocalModifications.SetPropertyModified(capturedEntity, "Transform", "Position");
					});
				propertyGrid.AddProperty(posEditor);

				// Rotation as euler angles
				let euler = PropertyGridDescriptor.QuaternionToEuler(transform.Rotation);
				let rotEditor = new Vector3Editor("Rotation", euler, min: -360, max: 360, category: "Transform");
				rotEditor.Setter = new [=p, =capturedEntity] (v) => {
					var t = p.Scene.GetLocalTransform(capturedEntity);
					t.Rotation = PropertyGridDescriptor.EulerToQuaternion(v);
					p.Scene.SetLocalTransform(capturedEntity, t);
				};
				if (isPrefabInstance)
					rotEditor.OnEditEnd.Add(new [=p, =capturedEntity] (e) => {
						p.Scene.LocalModifications.SetPropertyModified(capturedEntity, "Transform", "Rotation");
					});
				propertyGrid.AddProperty(rotEditor);

				let scaleEditor = new Vector3Editor("Scale", transform.Scale, min: 0.001f, max: 10000, category: "Transform");
				scaleEditor.Setter = new [=p, =capturedEntity] (v) => {
					var t = p.Scene.GetLocalTransform(capturedEntity);
					t.Scale = v;
					p.Scene.SetLocalTransform(capturedEntity, t);
				};
				if (isPrefabInstance)
					scaleEditor.OnEditEnd.Add(new [=p, =capturedEntity] (e) => {
						p.Scene.LocalModifications.SetPropertyModified(capturedEntity, "Transform", "Scale");
					});
				propertyGrid.AddProperty(scaleEditor);
			}

			// Build inspectors for each component via comptime-generated IInspectable
			let components = scope List<Component>();
			p.Scene.GetComponents(selected, components);

			for (let component in components)
			{
				if (let inspectable = component as IInspectable)
				{
					let editorCountBefore = propertyGrid.PropertyCount;

					let desc = scope EditorPropertyGridDescriptor(propertyGrid, editorContext?.DialogService, editorContext?.ResourceSystem?.SerializerProvider, editorContext?.ResourceSystem, editorContext);
					inspectable.DescribeProperties(desc);

					// For prefab instance entities, track property edits in LocalModifications
					if (isPrefabInstance)
					{
						// Find the component's manager to get the serialization type ID
						StringView compTypeId = default;
						for (let module in p.Scene.Modules)
						{
							if (let cmBase = module as ComponentManagerBase)
							{
								if (cmBase.GetComponent(selected) === component && module.IsSerializable)
								{
									compTypeId = module.SerializationTypeId;
									break;
								}
							}
						}

						if (compTypeId.Length > 0)
						{
							let capturedTypeId = new String(compTypeId);
							let capturedScene = p.Scene;
							let capturedEntity = selected;
							p.AddOwnedObject(capturedTypeId);

							// Subscribe only the editors just added by this component
							let props = propertyGrid.Properties;
							for (int ei = editorCountBefore; ei < props.Length; ei++)
							{
								props[ei].OnEditEnd.Add(new [=capturedScene, =capturedEntity, =capturedTypeId] (e) => {
									capturedScene.LocalModifications.SetPropertyModified(
										capturedEntity, capturedTypeId, e.Name);
								});
							}
						}
					}
				}
			}

		});

		// Wire "Add Component" button click
		addCompBtn.OnClick.Add(new (btn) => {
			let ctx = btn.Context;
			if (ctx == null) return;

			let selected = page.PrimarySelection;
			if (selected == .Invalid) return;

			let menu = new ContextMenu();

			// List all component managers on the scene that this entity doesn't have yet
			for (let module in page.Scene.Modules)
			{
				if (let manager = module as ComponentManagerBase)
				{
					if (manager.HasComponent(selected))
						continue; // Already has this component

					let displayName = scope String();
					manager.GetComponentDisplayName(displayName);
					menu.AddItem(displayName, new [=page, =selected, =manager] () => {
						manager.CreateComponentOnEntity(selected);
						// Refresh inspector
						page.OnSelectionChanged(page);
					});
				}
			}

			// Show at button position
			float screenX = 0, screenY = btn.Height;
			View v = btn;
			while (v != null) { screenX += v.Bounds.X; screenY += v.Bounds.Y; v = v.Parent; }
			menu.Show(ctx, screenX, screenY);
		});

		return container;
	}

	// ==================== Asset Drop ====================

	private static void OnAssetDroppedIntoHierarchy(SceneEditorPage page,
		SceneHierarchyAdapter adapter, AssetDragData assetData, EntityHandle parentEntity)
	{
		// Only handle .prefab files for now
		if (assetData.Extension != ".prefab")
			return;

		let context = page.EditorContext;
		if (context?.ResourceSystem == null || context?.RuntimeContext == null) return;

		let resSys = context.ResourceSystem;
		let provider = resSys.SerializerProvider;
		if (provider == null) return;

		let sceneSub = context.RuntimeContext.GetSubsystem<SceneSubsystem>();
		if (sceneSub == null) return;

		var prefabRef = ResourceRef(assetData.ResourceId, assetData.UriPath);
		defer prefabRef.Dispose();

		let result = PrefabSpawner.Spawn(
			page.Scene, prefabRef, assetData.ResourceId,
			parentEntity,
			sceneSub.TypeRegistry, provider, resSys);

		if (result case .Ok(let spawnResult))
		{
			delete spawnResult.GuidMap;
			adapter.Rebuild();
			page.SelectEntity(spawnResult.RootEntity);
			page.MarkDirty();
		}
		else
		{
			context?.Logger?.LogError("Failed to spawn prefab from asset drop: {}", assetData.UriPath);
		}
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

	/// World-XZ floor grid anchored at the world origin. Mirrors the model
	/// viewer's grid: depth-tested (geometry occludes), no camera follow.
	/// The two lines passing through the origin are colored to match the
	/// gizmo (X axis red at Z=0, Z axis blue at X=0). Drawn through the
	/// per-pipeline DebugDraw so it only appears in this viewport.
	private static void DrawSceneGrid(DebugDraw debugDraw)
	{
		const float gridSize = 50.0f; // half-extent in metres
		const float gridStep = 1.0f;
		let gridColor = Color(80, 80, 80);
		let xAxisColor = Color(180, 60, 60);  // Z=0 line - runs along X
		let zAxisColor = Color(60, 80, 180);  // X=0 line - runs along Z

		var x = -gridSize;
		while (x <= gridSize)
		{
			let c = (Math.Abs(x) < 0.001f) ? zAxisColor : gridColor;
			debugDraw.DrawLine(Vector3(x, 0, -gridSize), Vector3(x, 0, gridSize), c);
			x += gridStep;
		}
		var z = -gridSize;
		while (z <= gridSize)
		{
			let c = (Math.Abs(z) < 0.001f) ? xAxisColor : gridColor;
			debugDraw.DrawLine(Vector3(-gridSize, 0, z), Vector3(gridSize, 0, z), c);
			z += gridStep;
		}
	}
}
