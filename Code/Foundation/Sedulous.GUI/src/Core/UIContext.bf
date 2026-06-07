namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.VG;

/// Central coordinator for the UI2 framework.
/// Manages ViewId registry, multiple root views, phase tracking, and draw invalidation.
/// Expanded in later phases with InputManager, FocusManager, DragDropManager, etc.
public class UIContext
{
	/// Current phase of the UI context.
	public enum Phase
	{
		Idle,
		Layout,
		Drawing
	}

	// === View registry (ViewId -> live View) ===
	private Dictionary<uint32, View> mRegistry = new .();

	// === Root views (non-owning - callers own their roots) ===
	private List<RootView> mRootViews = new .();

	// === Active input root (set by application based on focused window) ===
	private RootView mActiveInputRoot;

	// === Mutation queue (deferred tree changes, drained each frame) ===
	private MutationQueue mMutationQueue = new .();

	// === Clipboard (set by application, non-owning) ===
	private IClipboard mClipboard;

	// === Font service (set by application/subsystem, non-owning) ===
	private IFontService mFontService;

	// === Input, focus, drag-drop, animation, shortcuts, tooltips (owned) ===
	private InputManager mInputManager;
	private FocusManager mFocusManager;
	private DragDropManager mDragDropManager;
	private AnimationManager mAnimationManager;
	private ShortcutManager mShortcutManager;
	private TooltipManager mTooltipManager;

	// === StyleSheet (ref-counted, shared between contexts) ===
	private StyleSheet mStyleSheet;

	// === Debug settings ===
	public UIDebugDrawSettings DebugSettings;

	// === Phase tracking ===
	private Phase mPhase = .Idle;
	private bool mNeedsRedraw = true;
	private float mDeltaTime;
	private float mTotalTime;

	public this()
	{
		mFocusManager = new FocusManager(this);
		mInputManager = new InputManager(this);
		mDragDropManager = new DragDropManager(this);
		mAnimationManager = new AnimationManager();
		mShortcutManager = new ShortcutManager(this);
		mTooltipManager = new TooltipManager(this);
	}

	// =================================================================
	// Properties
	// =================================================================

	/// Current phase.
	public Phase CurrentPhase => mPhase;

	/// Whether any view needs redrawing since last frame.
	public bool NeedsRedraw => mNeedsRedraw;

	/// Delta time from the last BeginFrame call.
	public float DeltaTime => mDeltaTime;

	/// Total elapsed time since first frame.
	public float TotalTime => mTotalTime;

	/// Number of root views.
	public int RootViewCount => mRootViews.Count;

	/// Get root view at index.
	public RootView GetRootView(int index) => mRootViews[index];

	/// The root view that currently receives input.
	/// Set by the application based on which window has focus.
	public RootView ActiveInputRoot
	{
		get => mActiveInputRoot;
		set => mActiveInputRoot = value;
	}

	/// DPI scale for the active input root.
	public float DpiScale => mActiveInputRoot?.DpiScale ?? 1.0f;

	/// The mutation queue for deferred tree changes.
	public MutationQueue MutationQueue => mMutationQueue;

	/// Clipboard adapter. Set by the application.
	public IClipboard Clipboard
	{
		get => mClipboard;
		set => mClipboard = value;
	}

	/// Font service for text rendering. Set by the application or subsystem.
	public IFontService FontService
	{
		get => mFontService;
		set => mFontService = value;
	}

	/// Input event router (owned by UIContext).
	public InputManager InputManager => mInputManager;

	/// Focus and capture manager (owned by UIContext).
	public FocusManager FocusManager => mFocusManager;

	/// Drag-and-drop manager (owned by UIContext).
	public DragDropManager DragDropManager => mDragDropManager;

	/// Animation manager (owned by UIContext).
	public AnimationManager Animations => mAnimationManager;

	/// Keyboard shortcut manager (owned by UIContext).
	public ShortcutManager Shortcuts => mShortcutManager;

	/// Tooltip manager (owned by UIContext).
	public TooltipManager Tooltips => mTooltipManager;

	/// The active StyleSheet. Ref-counted - can be shared between contexts.
	/// Setting a new StyleSheet AddRefs the new one and ReleaseRefs the old one.
	public StyleSheet StyleSheet
	{
		get => mStyleSheet;
		set
		{
			if (mStyleSheet === value) return;
			value?.AddRef();
			mStyleSheet?.ReleaseRef();
			mStyleSheet = value;
		}
	}

	// =================================================================
	// Root view management
	// =================================================================

	/// Add a root view. UIContext does NOT take ownership.
	/// First root added becomes the active input root.
	public void AddRootView(RootView root)
	{
		if (root == null || mRootViews.Contains(root))
			return;

		mRootViews.Add(root);
		AttachView(root);

		if (mActiveInputRoot == null)
			mActiveInputRoot = root;
	}

	/// Remove a root view. Does not delete it.
	public void RemoveRootView(RootView root)
	{
		if (root == null || !mRootViews.Contains(root))
			return;

		DetachView(root);
		mRootViews.Remove(root);

		if (mActiveInputRoot === root)
			mActiveInputRoot = mRootViews.Count > 0 ? mRootViews[0] : null;
	}

	// =================================================================
	// View registry
	// =================================================================

	/// Registers a view. Called when a view is attached to a context-connected tree.
	public void Register(View view)
	{
		if (view != null && view.Id.IsValid)
			mRegistry[view.Id.RawValue] = view;
	}

	/// Unregisters a view. Called when a view is detached or destroyed.
	/// Notifies InputManager and FocusManager to clear any references.
	public void Unregister(View view)
	{
		if (view != null && view.Id.IsValid)
		{
			mInputManager?.OnViewDeleted(view);
			mFocusManager?.OnViewDeleted(view);
			mDragDropManager?.OnViewDeleted(view);
			mTooltipManager?.OnViewDeleted(view);
			mAnimationManager?.CancelForView(view);
			mShortcutManager?.RemoveScopedTo(view);
			mRegistry.Remove(view.Id.RawValue);
		}
	}

	/// Looks up a view by ViewId. Returns null if deleted or not registered.
	public View GetViewById(ViewId id)
	{
		if (mRegistry.TryGetValue(id.RawValue, let view))
			return view;
		return null;
	}

	/// Typed lookup.
	public T GetViewById<T>(ViewId id) where T : View
	{
		return GetViewById(id) as T;
	}

	// =================================================================
	// Frame lifecycle
	// =================================================================

	/// Marks that at least one view needs redrawing.
	public void MarkNeedsRedraw()
	{
		mNeedsRedraw = true;
	}

	/// Called once per frame before layout/draw.
	/// Drains the mutation queue first so deferred changes take effect before layout.
	public void BeginFrame(float deltaTime)
	{
		mDeltaTime = deltaTime;
		mTotalTime += deltaTime;

		// Drain deferred mutations (tree changes, deletions) before layout pass.
		mMutationQueue.Drain();

		// Tick tooltips and animations.
		mTooltipManager.Update(deltaTime);
		mAnimationManager.Update(deltaTime);
	}

	/// Measures and layouts a single root view.
	public void UpdateRootView(RootView root)
	{
		if (root == null)
			return;

		mPhase = .Layout;

		let dpi = Math.Max(root.DpiScale, 0.01f);
		let logicalW = root.ViewportSize.X / dpi;
		let logicalH = root.ViewportSize.Y / dpi;
		let constraints = BoxConstraints.Tight(logicalW, logicalH);
		root.Measure(constraints);
		root.Layout(0, 0, logicalW, logicalH);

		mPhase = .Idle;
	}

	/// Draws a single root view. Creates UIDrawContext internally.
	public void DrawRootView(RootView root, VGContext vg)
	{
		if (root == null)
			return;

		mPhase = .Drawing;

		let ctx = scope UIDrawContext(vg, root.DpiScale, mFontService, DebugSettings);

		if (root.DpiScale != 1.0f)
			vg.Scale(root.DpiScale, root.DpiScale);

		root.OnDraw(ctx);

		mPhase = .Idle;
		mNeedsRedraw = false;
	}

	// =================================================================
	// Subtree attach/detach (registers/unregisters all views in subtree)
	// =================================================================

	/// Sets context on a view and all descendants, registering each.
	/// Called by AddRootView and ViewGroup.AddView.
	public void AttachView(View view)
	{
		view.Context = this;
		Register(view);

		if (let group = view as ViewGroup)
		{
			for (int i = 0; i < group.ChildCount; i++)
				AttachView(group.GetChildAt(i));

			// Also recurse into VisualChildren (e.g., Dialog's internal layout)
			// that aren't in the regular child list.
			for (int i = 0; i < group.VisualChildCount; i++)
			{
				let vc = group.GetVisualChild(i);
				if (vc.Context != this)
					AttachView(vc);
			}
		}
	}

	/// Clears context on a view and all descendants, unregistering each.
	/// Called by RemoveRootView and ViewGroup.RemoveView.
	public void DetachView(View view)
	{
		Unregister(view);
		view.Context = null;

		if (let group = view as ViewGroup)
		{
			for (int i = 0; i < group.ChildCount; i++)
				DetachView(group.GetChildAt(i));

			// Also recurse into VisualChildren that aren't regular children.
			for (int i = 0; i < group.VisualChildCount; i++)
			{
				let vc = group.GetVisualChild(i);
				if (vc.Context != null)
					DetachView(vc);
			}
		}
	}

	// =================================================================
	// Destructor
	// =================================================================

	public ~this()
	{
		// Drain any remaining mutations before teardown.
		if (mMutationQueue != null)
		{
			mMutationQueue.Drain();
			delete mMutationQueue;
		}

		// Release StyleSheet ref (may delete if last ref).
		if (mStyleSheet != null)
		{
			mStyleSheet.ReleaseRef();
			mStyleSheet = null;
		}

		delete mTooltipManager;
		delete mShortcutManager;
		delete mAnimationManager;
		delete mDragDropManager;
		delete mInputManager;
		delete mFocusManager;

		// Registry and root list are non-owning - just delete the containers.
		delete mRegistry;
		delete mRootViews;
	}
}
