using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Inspection;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Shell.Input;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;

using internal Sedulous.Editor.App.Pages;

namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .animgraph files.
/// Displays states as nodes in a NodeGraphCanvas, transitions as bezier
/// connections. Side panel shows parameters and selected state/transition
/// properties via PropertyGrid. Bottom panel shows a 3D preview viewport
/// with transport controls and preview asset assignment.
class AnimGraphEditorPageFactory : IEditorPageFactory
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
		outExtensions.Add(new .(".animgraph"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".animgraph", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation Graph", "No runtime context.");

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation Graph", "SceneSubsystem or ISceneRenderer unavailable.");

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation Graph", "Path is not inside any mounted scheme.");

		AnimationGraphResource graphRes = null;
		if (context.ResourceSystem.LoadResource<AnimationGraphResource>(uri) case .Ok(let handle))
			graphRes = handle.Resource;
		if (graphRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Animation Graph", "Failed to load animation graph.");

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "AnimGraphPreview");
		let page = new AnimGraphEditorPage(path, uri, graphRes, host, context);
		page.SetContentView(BuildView(graphRes, page, context));
		page.RebuildGraph();
		page.SpawnPreviewEntity();
		return page;
	}

	private static View BuildView(AnimationGraphResource graphRes,
		AnimGraphEditorPage page, EditorContext context)
	{
		// Top: canvas + inspector (horizontal split)
		// Bottom: preview viewport with transport
		let outer = new SplitView(.Vertical);
		outer.SplitRatio = 0.6f;
		outer.MinPaneSize = 150;

		let topPane = BuildTopPane(graphRes, page, context);
		let bottomPane = BuildViewportPanel(page);

		outer.SetPanes(topPane, bottomPane);
		return outer;
	}

	private static View BuildTopPane(AnimationGraphResource graphRes,
		AnimGraphEditorPage page, EditorContext context)
	{
		let root = new SplitView(.Horizontal);
		root.SplitRatio = 0.7f;
		root.MinPaneSize = 200;

		// Left: node graph canvas
		let canvas = new NodeGraphCanvas();
		canvas.ShowGrid = true;
		canvas.ConnectionValidator = new (src, dst) => true; // States connect freely

		// Wire canvas events
		canvas.OnNodeMoved.Add(new [=page] (idx) => { page.MarkDirty(); });

		canvas.OnConnectionCreated.Add(new [=page] (connIdx) => {
			OnConnectionCreatedHandler(page, connIdx);
		});

		canvas.OnConnectionRemoved.Add(new [=page] (srcNode, srcPort, dstNode, dstPort) => {
			OnConnectionRemovedHandler(page, srcNode, dstNode);
		});

		canvas.OnNodeDeleted.Add(new [=page] (nodeIdx) => {
			OnNodeDeletedHandler(page, nodeIdx);
		});

		canvas.OnSelectionChanged.Add(new [=page] () => {
			OnSelectionChangedHandler(page);
		});

		canvas.OnNodeDoubleClicked.Add(new (idx) => {
			// Could open blend tree sub-editor in the future
		});

		canvas.OnCanvasContextMenu.Add(new [=page] (x, y) => {
			ShowCanvasContextMenu(page, x, y);
		});

		canvas.OnNodeContextMenu.Add(new [=page] (idx) => {
			ShowNodeContextMenu(page, idx);
		});

		page.SetCanvas(canvas);

		// Right: inspector panel
		let inspector = BuildInspectorPanel(page, context);

		root.SetPanes(canvas, inspector);
		return root;
	}

	private static View BuildInspectorPanel(AnimGraphEditorPage page, EditorContext context)
	{
		let panel = new FlexLayout();
		panel.Direction = .Vertical;

		// Header
		let headerLabel = new Label();
		headerLabel.SetText("Inspector");
		headerLabel.FontSize = 12;
		headerLabel.TextColor = .(140, 140, 155, 255);
		panel.AddView(headerLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });

		let sep = new Panel();
		sep.Background = new ColorDrawable(.(60, 65, 80, 255));
		panel.AddView(sep, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });

		// Preview asset assignment section
		let previewLabel = new Label();
		previewLabel.SetText("Preview");
		previewLabel.FontSize = 11;
		previewLabel.TextColor = .(160, 160, 175, 255);
		panel.AddView(previewLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });

		let previewGrid = new PropertyGrid();
		panel.AddView(previewGrid, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(60)) });

		// Skeleton ref picker
		previewGrid.AddProperty(new ResourceRefEditor("Skeleton",
			new [=page] () => {
				let comp = page.GetPreviewGraphComponent();
				return comp != null ? comp.SkeletonRef : ResourceRef();
			},
			new [=page] (newRef) => {
				page.SetPreviewSkeleton(newRef);
			},
			editorContext: context, extensionFilter: ".skeleton"));

		// Skinned mesh ref picker
		previewGrid.AddProperty(new ResourceRefEditor("Mesh",
			new [=page] () => {
				let comp = page.GetPreviewMeshComponent();
				return comp != null ? comp.MeshRef : ResourceRef();
			},
			new [=page] (newRef) => {
				page.SetPreviewMesh(newRef);
			},
			editorContext: context, extensionFilter: ".skinnedmesh"));

		let sep1b = new Panel();
		sep1b.Background = new ColorDrawable(.(60, 65, 80, 255));
		panel.AddView(sep1b, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });

		// Parameters section
		let paramsHeader = new FlexLayout();
		paramsHeader.Direction = .Horizontal;
		let paramsLabel = new Label();
		paramsLabel.SetText("Parameters");
		paramsLabel.FontSize = 11;
		paramsLabel.TextColor = .(160, 160, 175, 255);
		paramsHeader.AddView(paramsLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		let addParamBtn = new Button("+");
		addParamBtn.OnClick.Add(new [=page, =panel] (btn) => {
			ShowAddParameterMenu(page, btn);
		});
		paramsHeader.AddView(addParamBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(24)), Height = .Fixed(.Px(18)) });
		panel.AddView(paramsHeader, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });

		let paramGrid = new PropertyGrid();
		panel.AddView(paramGrid, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(120)) });
		page.AddOwnedObject(new ParamGridRef(paramGrid, page));

		RebuildParameterGrid(paramGrid, page);

		let sep2 = new Panel();
		sep2.Background = new ColorDrawable(.(60, 65, 80, 255));
		panel.AddView(sep2, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });

		// Selection property grid
		let selLabel = new Label();
		selLabel.SetText("Selection");
		selLabel.FontSize = 11;
		selLabel.TextColor = .(160, 160, 175, 255);
		panel.AddView(selLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });

		let propGrid = new PropertyGrid();
		panel.AddView(propGrid, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });
		page.SetPropertyGrid(propGrid);

		// Wire selection changes to rebuild property grid
		page.OnSelectionChanged.Add(new (obj) => {
			propGrid.Clear();
			if (obj == null)
			{
				selLabel.SetText("Selection");
				return;
			}

			if (let state = obj as AnimationGraphState)
			{
				selLabel.SetText(scope $"State: {state.Name}");

				// State properties
				propGrid.AddProperty(new StringEditor("Name", state.Name,
					new [=state] (newName) => { state.Name.Set(newName); }));
				propGrid.AddProperty(new FloatEditor("Speed", state.Speed,
					setter: new [=state] (val) => { state.Speed = (float)val; }));
				propGrid.AddProperty(new BoolEditor("Loop", state.Loop,
					new [=state] (val) => { state.Loop = val; }));

				// Node-specific properties via IInspectable (clip ref, blend tree entries)
				if (let inspectable = state.Node as IInspectable)
				{
					let desc = scope EditorPropertyGridDescriptor(propGrid,
						context?.DialogService,
						context?.ResourceSystem?.SerializerProvider,
						context?.ResourceSystem,
						context);
					inspectable.DescribeProperties(desc);
				}
			}
			else if (let trans = obj as AnimationGraphTransition)
			{
				selLabel.SetText("Transition");
				propGrid.AddProperty(new FloatEditor("Duration", trans.Duration,
					min: 0, max: 5, setter: new [=trans] (val) => { trans.Duration = (float)val; }));
				propGrid.AddProperty(new BoolEditor("Has Exit Time", trans.HasExitTime,
					new [=trans] (val) => { trans.HasExitTime = val; }));
				propGrid.AddProperty(new FloatEditor("Exit Time", trans.ExitTime,
					min: 0, max: 1, setter: new [=trans] (val) => { trans.ExitTime = (float)val; }));
				propGrid.AddProperty(new IntEditor("Priority", trans.Priority,
					setter: new [=trans] (val) => { trans.Priority = (int32)val; }));

				// Conditions
				BuildConditionEditors(propGrid, trans, page);
			}
		});

		return panel;
	}

	// ========== Viewport ==========

	private static View BuildViewportPanel(AnimGraphEditorPage page)
	{
		let root = new FlexLayout();
		root.Direction = .Vertical;

		let host = page.Host;

		// Viewport fills
		let viewportPanel = new Panel();
		viewportPanel.Background = new ColorDrawable(.(25, 25, 30, 255));
		viewportPanel.AddView(host.Viewport);
		root.AddView(viewportPanel, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		// Toolbar: Play / Pause / Reset
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

		let pauseBtn = new Button("Pause");
		pauseBtn.OnClick.Add(new [=page] (btn) => { page.Pause(); });
		toolbar.AddView(pauseBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(24)) });

		let resetBtn = new Button("Reset");
		resetBtn.OnClick.Add(new [=page] (btn) => { page.Reset(); });
		toolbar.AddView(resetBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(70)), Height = .Fixed(.Px(24)) });

		root.AddView(toolbarPanel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(32)) });

		return root;
	}

	// ========== Parameter management ==========

	/// Helper object stored on the page so we can find the param grid later to rebuild it.
	internal class ParamGridRef
	{
		public PropertyGrid Grid;
		public AnimGraphEditorPage Page;
		public this(PropertyGrid grid, AnimGraphEditorPage page) { Grid = grid; Page = page; }
	}

	internal static void RebuildParameterGrid(PropertyGrid paramGrid, AnimGraphEditorPage page)
	{
		paramGrid.Clear();
		if (page.Graph == null) return;

		for (int32 i = 0; i < page.Graph.Parameters.Count; i++)
		{
			let param = page.Graph.Parameters[i];
			PropertyEditor editor = null;

			switch (param.Type)
			{
			case .Float:
				editor = new FloatEditor(param.Name, param.FloatValue,
					setter: new [=param] (val) => { param.FloatValue = (float)val; });
			case .Int:
				editor = new IntEditor(param.Name, param.IntValue,
					setter: new [=param] (val) => { param.IntValue = (int32)val; });
			case .Bool:
				editor = new BoolEditor(param.Name, param.BoolValue,
					new [=param] (val) => { param.BoolValue = val; });
			case .Trigger:
				editor = new BoolEditor(param.Name, false,
					new [=param] (val) => { param.BoolValue = val; });
			}

			if (editor != null)
			{
				editor.OnLabelRenamed = new [=param, =page] (newName) => {
					param.Name.Set(newName);
					page.MarkDirty();
				};
				paramGrid.AddProperty(editor);
			}
		}
	}

	private static void ShowAddParameterMenu(AnimGraphEditorPage page, View anchor)
	{
		let ctx = anchor.Context;
		if (ctx == null) return;

		let menu = new ContextMenu();
		menu.AddItem("Float", new [=page] () => { AddParameter(page, .Float); });
		menu.AddItem("Int", new [=page] () => { AddParameter(page, .Int); });
		menu.AddItem("Bool", new [=page] () => { AddParameter(page, .Bool); });
		menu.AddItem("Trigger", new [=page] () => { AddParameter(page, .Trigger); });

		menu.Show(ctx, anchor.Bounds.X, anchor.Bounds.Y + anchor.Bounds.Height);
	}

	private static void AddParameter(AnimGraphEditorPage page, AnimationParameterType type)
	{
		if (page.Graph == null) return;

		let name = scope String();
		name.AppendF("Param{}", page.Graph.Parameters.Count);
		page.Graph.AddParameter(name, type);
		page.MarkDirty();

		// Rebuild param grid
		for (let obj in page.[Friend]mOwnedObjects)
		{
			if (let pgRef = obj as ParamGridRef)
			{
				RebuildParameterGrid(pgRef.Grid, page);
				break;
			}
		}
	}

	// ========== Condition editing ==========

	private static void BuildConditionEditors(PropertyGrid propGrid, AnimationGraphTransition trans, AnimGraphEditorPage page)
	{
		// Build parameter name list for dropdowns
		let paramCount = (page.Graph != null) ? page.Graph.Parameters.Count : 0;
		StringView[] paramNames = scope StringView[paramCount];
		if (page.Graph != null)
		{
			for (int32 pi = 0; pi < page.Graph.Parameters.Count; pi++)
				paramNames[pi] = page.Graph.Parameters[pi].Name;
		}

		StringView[6] opNames = .("==", "!=", ">", "<", ">=", "<=");

		for (int32 ci = 0; ci < trans.Conditions.Count; ci++)
		{
			let condIdx = ci;
			let cond = trans.Conditions[condIdx];

			// Parameter dropdown
			if (paramNames.Count > 0)
			{
				propGrid.AddProperty(new EnumEditor(scope $"Cond[{ci}] Param", cond.ParameterIndex, paramNames,
					new [=trans, =condIdx] (val) => { trans.Conditions[condIdx].ParameterIndex = val; }));
			}

			// Op dropdown
			propGrid.AddProperty(new EnumEditor(scope $"Cond[{ci}] Op", (int32)cond.Op, opNames,
				new [=trans, =condIdx] (val) => { trans.Conditions[condIdx].Op = (ComparisonOp)val; }));

			// Threshold
			propGrid.AddProperty(new FloatEditor(scope $"Cond[{ci}] Value", cond.Threshold,
				setter: new [=trans, =condIdx] (val) => { trans.Conditions[condIdx].Threshold = (float)val; }));
		}

		// Add condition button
		propGrid.AddProperty(new ButtonEditor("Add Condition",
			new [=trans, =page] () => {
				int32 paramIdx = (page.Graph != null && page.Graph.Parameters.Count > 0) ? 0 : -1;
				trans.Conditions.Add(.(paramIdx, .Greater, 0));
				page.MarkDirty();
				// Refresh by re-selecting
				page.SelectObject(trans);
			}));
	}

	// ========== Event handlers ==========

	private static void OnConnectionCreatedHandler(AnimGraphEditorPage page, int32 connIdx)
	{
		let layer = page.GetActiveLayer();
		if (layer == null) return;

		let conn = page.Canvas.GetConnection(connIdx);
		// Canvas index 0 = Any State (-1), others = state index - 1
		let srcState = (conn.SourceNodeIndex == 0) ? -1 : conn.SourceNodeIndex - 1;
		let dstState = conn.DestNodeIndex - 1;

		let trans = new AnimationGraphTransition();
		trans.SourceStateIndex = (int32)srcState;
		trans.DestStateIndex = (int32)dstState;
		layer.AddTransition(trans);

		page.MarkDirty();
	}

	private static void OnConnectionRemovedHandler(AnimGraphEditorPage page, int32 srcCanvasNode, int32 dstCanvasNode)
	{
		let layer = page.GetActiveLayer();
		if (layer == null) return;

		let srcState = (srcCanvasNode == 0) ? -1 : srcCanvasNode - 1;
		let dstState = dstCanvasNode - 1;

		// Find and remove the matching transition
		for (int i = layer.Transitions.Count - 1; i >= 0; i--)
		{
			let trans = layer.Transitions[i];
			if (trans.SourceStateIndex == srcState && trans.DestStateIndex == dstState)
			{
				layer.Transitions.RemoveAt(i);
				delete trans;
				break;
			}
		}

		page.MarkDirty();
	}

	private static void OnNodeDeletedHandler(AnimGraphEditorPage page, int32 nodeIdx)
	{
		if (nodeIdx == 0) return; // Can't delete Any State

		let layer = page.GetActiveLayer();
		if (layer == null) return;

		let stateIdx = nodeIdx - 1;
		if (stateIdx < 0 || stateIdx >= layer.States.Count) return;

		// Remove transitions referencing this state
		for (int i = layer.Transitions.Count - 1; i >= 0; i--)
		{
			let trans = layer.Transitions[i];
			if (trans.SourceStateIndex == stateIdx || trans.DestStateIndex == stateIdx)
			{
				layer.Transitions.RemoveAt(i);
				delete trans;
			}
		}

		// Remap transition indices
		for (let trans in layer.Transitions)
		{
			if (trans.SourceStateIndex > stateIdx) trans.SourceStateIndex--;
			if (trans.DestStateIndex > stateIdx) trans.DestStateIndex--;
		}

		// Remove state
		let state = layer.States[stateIdx];
		layer.States.RemoveAt(stateIdx);
		delete state;

		// Update default state index
		if (layer.DefaultStateIndex == stateIdx)
			layer.DefaultStateIndex = 0;
		else if (layer.DefaultStateIndex > stateIdx)
			layer.DefaultStateIndex--;

		page.MarkDirty();
	}

	private static void OnSelectionChangedHandler(AnimGraphEditorPage page)
	{
		let layer = page.GetActiveLayer();
		if (layer == null) return;

		// Find first selected node
		let selected = scope List<int32>();
		page.Canvas.GetSelectedNodes(selected);

		if (selected.Count > 0)
		{
			let canvasIdx = selected[0];
			if (canvasIdx == 0)
			{
				page.SelectObject(null); // Any State — no properties
			}
			else
			{
				let stateIdx = canvasIdx - 1;
				if (stateIdx >= 0 && stateIdx < layer.States.Count)
					page.SelectObject(layer.States[stateIdx]);
			}
		}
		else
		{
			// Check for selected connection → transition
			for (int32 i = 0; i < page.Canvas.ConnectionCount; i++)
			{
				let conn = page.Canvas.GetConnection(i);
				if (conn.IsSelected)
				{
					let srcState = (conn.SourceNodeIndex == 0) ? -1 : conn.SourceNodeIndex - 1;
					let dstState = conn.DestNodeIndex - 1;

					for (let trans in layer.Transitions)
					{
						if (trans.SourceStateIndex == srcState && trans.DestStateIndex == dstState)
						{
							page.SelectObject(trans);
							return;
						}
					}
				}
			}
			page.SelectObject(null);
		}
	}

	// ========== Context menus ==========

	private static void ShowCanvasContextMenu(AnimGraphEditorPage page, float canvasX, float canvasY)
	{
		let canvas = page.Canvas;
		let ctx = canvas.Context;
		if (ctx == null) return;

		let menu = new ContextMenu();

		menu.AddItem("Add Clip State", new [=page, =canvasX, =canvasY] () => {
			AddState(page, canvasX, canvasY, .Clip);
		});

		menu.AddItem("Add BlendTree 1D", new [=page, =canvasX, =canvasY] () => {
			AddState(page, canvasX, canvasY, .BlendTree1D);
		});

		menu.AddItem("Add BlendTree 2D", new [=page, =canvasX, =canvasY] () => {
			AddState(page, canvasX, canvasY, .BlendTree2D);
		});

		// Convert canvas coords to screen for menu placement
		let screenPos = canvas.CanvasToScreen(.(canvasX, canvasY));
		float sx = screenPos.X, sy = screenPos.Y;
		View v = canvas;
		while (v != null) { sx += v.Bounds.X; sy += v.Bounds.Y; v = v.Parent; }
		menu.Show(ctx, sx, sy);
	}

	private static void ShowNodeContextMenu(AnimGraphEditorPage page, int32 nodeIdx)
	{
		if (nodeIdx == 0) return; // No context menu for Any State

		let canvas = page.Canvas;
		let ctx = canvas.Context;
		if (ctx == null) return;

		let layer = page.GetActiveLayer();
		if (layer == null) return;

		let stateIdx = nodeIdx - 1;
		if (stateIdx < 0 || stateIdx >= layer.States.Count) return;

		let menu = new ContextMenu();

		// Set as default state
		if (layer.DefaultStateIndex != stateIdx)
		{
			menu.AddItem("Set as Default", new [=page, =layer, =stateIdx] () => {
				layer.DefaultStateIndex = (int32)stateIdx;
				page.RebuildGraph();
				page.MarkDirty();
			});
		}

		menu.AddItem("Delete State", new [=canvas, =nodeIdx] () => {
			canvas.RemoveNode(nodeIdx);
		});

		// Show at mouse position
		let node = canvas.GetNode(nodeIdx);
		if (node != null)
		{
			let screenPos = canvas.CanvasToScreen(node.Position);
			float sx = screenPos.X, sy = screenPos.Y;
			View v = canvas;
			while (v != null) { sx += v.Bounds.X; sy += v.Bounds.Y; v = v.Parent; }
			menu.Show(ctx, sx, sy);
		}
	}

	// ========== State creation ==========

	private static void AddState(AnimGraphEditorPage page, float canvasX, float canvasY,
		AnimationStateNodeType nodeType)
	{
		let layer = page.GetActiveLayer();
		if (layer == null) return;

		IAnimationStateNode stateNode = null;
		StringView typeName = "State";

		switch (nodeType)
		{
		case .Clip:
			stateNode = new ClipStateNode(null);
			typeName = "Clip State";
		case .BlendTree1D:
			stateNode = new BlendTree1D();
			typeName = "BlendTree 1D";
		case .BlendTree2D:
			stateNode = new BlendTree2D();
			typeName = "BlendTree 2D";
		}

		let stateName = scope String();
		stateName.AppendF("New {}", typeName);

		let state = new AnimationGraphState(stateName, stateNode, ownsNode: true);
		layer.AddState(state);

		// Rebuild canvas and position the new node
		page.RebuildGraph();

		// Position the new node at the context menu location
		let newCanvasIdx = (int32)layer.States.Count; // +1 for Any State, -1 for 0-indexed = Count
		let newNode = page.Canvas.GetNode(newCanvasIdx);
		if (newNode != null)
			newNode.Position = .(canvasX, canvasY);

		page.Canvas.SelectNode(newCanvasIdx);
		page.MarkDirty();
	}
}
