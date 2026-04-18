namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.VG;
using Sedulous.Fonts;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// Central owner of the element registry, services, and mutation queue.
/// Supports multiple root views for multi-window scenarios.
/// Each window gets a RootView; the application switches ActiveInputRoot
/// based on which window has focus.
public class UIContext
{
	// === Element registry (ViewId -> live View) ===
	private Dictionary<int32, View> mRegistry = new .() ~ delete _;

	// === Root views (non-owning — callers own their roots) ===
	private List<RootView> mRootViews = new .() ~ delete _;

	// === Active input root (set by application based on focused window) ===
	private RootView mActiveInputRoot;

	// === Deferred mutation ===
	public MutationQueue MutationQueue { get; } = new .() ~ delete _;

	// === Phase tracking ===
	public UIPhase Phase { get; private set; } = .Idle;

	// === Font service (optional — set by UISubsystem) ===
	public IFontService FontService;

	// === Clipboard (optional — set by UISubsystem via adapter) ===
	public IClipboard Clipboard;

	// === Total elapsed time (for cursor blink, undo coalescing) ===
	public float TotalTime { get; private set; }

	// === Theme ===
	private Theme mTheme ~ delete _;

	public Theme Theme
	{
		get => mTheme;
		set
		{
			if (mTheme != value)
			{
				delete mTheme;
				mTheme = value;
				for (let root in mRootViews)
					root.InvalidateLayout();
			}
		}
	}

	// === Debug draw settings ===
	public UIDebugDrawSettings DebugSettings;

	// === Input + Focus ===
	public InputManager InputManager { get; private set; }
	public FocusManager FocusManager { get; private set; }

	// === Animation ===
	public AnimationManager Animations { get; private set; }

	// === Drag and Drop ===
	public DragDropManager DragDropManager { get; private set; }

	// === Overlays ===
	public TooltipManager TooltipManager { get; private set; }

	// =================================================================
	// Root view access
	// =================================================================

	/// Number of root views.
	public int RootViewCount => mRootViews.Count;

	/// Get root view at index.
	public RootView GetRootView(int index) => mRootViews[index];

	/// The root view that currently receives input.
	/// Set by the application before dispatching input events.
	public RootView ActiveInputRoot
	{
		get => mActiveInputRoot;
		set { mActiveInputRoot = value; }
	}

	/// PopupLayer for the active input root.
	public PopupLayer ActivePopupLayer => mActiveInputRoot?.PopupLayer;

	/// PopupLayer alias — controls use Context.PopupLayer.
	public PopupLayer PopupLayer => mActiveInputRoot?.PopupLayer;

	/// DPI scale for the active input root.
	public float DpiScale => mActiveInputRoot?.DpiScale ?? 1.0f;

	/// Logical width of the active input root.
	public float LogicalWidth => mActiveInputRoot != null ? mActiveInputRoot.ViewportSize.X / DpiScale : 0;

	/// Logical height of the active input root.
	public float LogicalHeight => mActiveInputRoot != null ? mActiveInputRoot.ViewportSize.Y / DpiScale : 0;

	// =================================================================
	// Constructor / Destructor
	// =================================================================

	public this()
	{
		InputManager = new InputManager(this);
		FocusManager = new FocusManager(this);
		TooltipManager = new TooltipManager(this);
		Animations = new AnimationManager();
		DragDropManager = new DragDropManager(this);
	}

	public ~this()
	{
		delete DragDropManager;
		delete Animations;
		delete TooltipManager;
		delete InputManager;
		delete FocusManager;
	}

	// =================================================================
	// Root view management
	// =================================================================

	/// Add a root view. UIContext does NOT take ownership.
	public void AddRootView(RootView root)
	{
		if (root == null || mRootViews.Contains(root))
			return;

		mRootViews.Add(root);
		ViewGroup.AttachSubtree(root, this);

		if (mActiveInputRoot == null)
			mActiveInputRoot = root;
	}

	/// Remove a root view. Does not delete it.
	public void RemoveRootView(RootView root)
	{
		if (root == null || !mRootViews.Contains(root))
			return;

		ViewGroup.DetachSubtree(root);
		mRootViews.Remove(root);

		if (mActiveInputRoot === root)
			mActiveInputRoot = mRootViews.Count > 0 ? mRootViews[0] : null;
	}

	// =================================================================
	// Element registry
	// =================================================================

	public void RegisterElement(View view)
	{
		mRegistry[view.Id.Value] = view;
	}

	public void UnregisterElement(View view)
	{
		mRegistry.Remove(view.Id.Value);
		// Notify managers so they can clear any dangling references.
		InputManager?.OnElementDeleted(view);
		FocusManager?.OnElementDeleted(view);
		Animations?.CancelForView(view);
		DragDropManager?.OnElementDeleted(view);
		// Track for diagnostics.
		MutationQueue.NotifyDeleted(view.Id);
	}

	public View GetElementById(ViewId id)
	{
		if (mRegistry.TryGetValue(id.Value, let view))
			return view;
		return null;
	}

	// =================================================================
	// Frame lifecycle
	// =================================================================

	/// Call once per frame before layout/draw. Drains the mutation queue
	/// and ticks global managers (animations, tooltips).
	public void BeginFrame(float deltaTime)
	{
		TotalTime += deltaTime;

		Phase = .Draining;
		MutationQueue.Drain();
		Phase = .Idle;

		TooltipManager?.Update(deltaTime);
		Animations?.Update(deltaTime);
	}

	/// Measure + Layout a single root view.
	public void UpdateRootView(RootView root)
	{
		if (root == null) return;

		Phase = .LayingOut;

		let vp = root.ViewportSize;
		root.Measure(.Exactly(vp.X), .Exactly(vp.Y));
		root.Layout(0, 0, vp.X, vp.Y);

		Phase = .Idle;
	}

	/// Draw a single root view into the given VGContext.
	public void DrawRootView(RootView root, VGContext vg)
	{
		if (root == null) return;

		Phase = .Drawing;

		let drawCtx = scope UIDrawContext(vg, root.DpiScale, FontService, Theme, DebugSettings);

		if (root.DpiScale != 1.0f)
			vg.Scale(root.DpiScale, root.DpiScale);

		root.OnDraw(drawCtx);

		Phase = .Idle;
	}

	/// Hit-test within the active input root.
	public View HitTest(Vector2 screenPoint)
	{
		return mActiveInputRoot?.HitTest(screenPoint);
	}
}
