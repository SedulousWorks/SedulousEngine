using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.VG;

namespace Sedulous.UI;

/// The root of one UI tree: its frame damage, its style generation, and the theme sheet.
///
/// PARTIAL PORT. Damage tracking, the style generation and sheet epoch, the mutation queue,
/// the transition list, the clipboard and font service seams are here. The six managers, the
/// root view list, the frame lifecycle and the draw path stay in the ledger's View.cppm and
/// UIClusterImpl.cpp until those subsystems land.
class UIContext
{
	private UIContextPhase mPhase = .Idle;
	private bool mNeedsRedraw = false;
	private bool mNeedsLayout = false;
	private float mDeltaTime = 0.0f;
	private float mTotalTime = 0.0f;

	private MutationQueue mMutationQueue = new .() ~ delete _;
	/// OWNED.
	private StyleSheet mStyleSheet ~ _?.ReleaseRef();
	private uint32 mSheetEpoch = 1;
	private uint32 mStyleGeneration = 1;
	/// BORROWED: a view de-lists itself when its transitions end or it detaches.
	private List<View> mTransitioning = new .() ~ delete _;

	/// BORROWED, and nullable. The core stays platform agnostic; the application or the shell
	/// bridge supplies these.
	private IClipboard mClipboard = null;
	private IFontService mFontService = null;

	/// OWNED. Only their state is ported so far; see each manager.
	private InputManager mInputManager ~ delete _;
	private FocusManager mFocusManager ~ delete _;
	private ShortcutManager mShortcutManager ~ delete _;
	private AnimationManager mAnimationManager = new .() ~ delete _;
	private DragDropManager mDragDropManager ~ delete _;

	/// BORROWED: the roots are owned by whoever created them.
	private List<RootView> mRootViews = new .() ~ delete _;
	private RootView mActiveInputRoot = null;
	/// BORROWED: every attached view, by id, so a manager can hold an id rather than a
	/// pointer and never dangle.
	private Dictionary<uint32, View> mRegistry = new .() ~ delete _;

	public this()
	{
		mInputManager = new .(this);
		mFocusManager = new .(this);
		mShortcutManager = new .(this);
		mDragDropManager = new .(this);
	}

	public ~this()
	{
		mMutationQueue.Drain();
	}

	public UIContextPhase CurrentPhase => mPhase;

	public InputManager GetInputManager() => mInputManager;
	public FocusManager GetFocusManager() => mFocusManager;
	public ShortcutManager GetShortcuts() => mShortcutManager;
	public AnimationManager Animations => mAnimationManager;
	public DragDropManager DragDrop => mDragDropManager;

	// ---- Frame damage --------------------------------------------------------------------------

	public bool NeedsRedraw => mNeedsRedraw;

	/// Some view's GEOMETRY may have changed since the last layout pass.
	///
	/// Visual only damage, such as a hover tint or a caret blink, leaves this CLEAR, so the
	/// host redraws without re-measuring the whole tree. That is what makes an interaction
	/// frame cheap.
	public bool NeedsLayout => mNeedsLayout;

	public void ClearLayoutDamage() => mNeedsLayout = false;

	public void MarkNeedsRedraw() => mNeedsRedraw = true;

	public void MarkNeedsLayout()
	{
		mNeedsLayout = true;
		// A relayout always redraws.
		mNeedsRedraw = true;
	}

	public float DeltaTime => mDeltaTime;
	public float TotalTime => mTotalTime;

	public MutationQueue MutationQueue => mMutationQueue;

	// ---- Style ---------------------------------------------------------------------------------

	public StyleSheet GetStyleSheet() => mStyleSheet;

	/// Installs the context sheet, meaning the theme, and moves the sheet epoch. CONSUMES the
	/// caller's reference.
	///
	/// The theme is DATA, its motion included: a sheet declares its own `transition` rules and
	/// every shipped theme puts one on View. The engine prepends nothing and keeps no list of
	/// control types.
	public void SetStyleSheet(StyleSheet sheet)
	{
		if (mStyleSheet != null)
			mStyleSheet.ReleaseRef();
		mStyleSheet = sheet;
		BumpSheetEpoch();
	}

	/// Bumped whenever rule OBJECTS may have been replaced, by a context or local sheet swap.
	/// A view's style cache from another epoch is rebuilt WITHOUT being read, its rule
	/// pointers no longer being known to be alive.
	public uint32 SheetEpoch => mSheetEpoch;

	public void BumpSheetEpoch()
	{
		mSheetEpoch++;
		InvalidateStyles();
	}

	/// Bumped by anything that changes which rules MATCH a view: classes, ids, sheets, tree
	/// structure. Every view's computed style cache keys on it.
	public uint32 StyleGeneration => mStyleGeneration;

	public void InvalidateStyles()
	{
		mStyleGeneration++;
	}

	// ---- Transitions ---------------------------------------------------------------------------

	/// A view with a running transition asks to be ticked each frame.
	public void RegisterTransitioning(View view) => mTransitioning.Add(view);

	public void UnregisterTransitioning(View view)
	{
		for (int i = mTransitioning.Count - 1; i >= 0; i--)
		{
			if (mTransitioning[i] == view)
				mTransitioning.RemoveAtFast(i);
		}
	}

	public int TransitioningViewCount => mTransitioning.Count;

	// ---- Root views ----------------------------------------------------------------------------

	public int RootViewCount => mRootViews.Count;
	public RootView GetRootView(int index) => mRootViews[index];

	public RootView ActiveInputRoot => mActiveInputRoot;
	public void SetActiveInputRoot(RootView root) => mActiveInputRoot = root;

	/// The DPI scale of the active input root.
	public float DpiScale => (mActiveInputRoot != null) ? mActiveInputRoot.DpiScale : 1.0f;

	/// BORROWS the root: whoever made it keeps it alive.
	public void AddRootView(RootView root)
	{
		if ((root == null) || mRootViews.Contains(root))
			return;

		mRootViews.Add(root);
		AttachView(root);
		// The first root added becomes the input target until something says otherwise.
		if (mActiveInputRoot == null)
			mActiveInputRoot = root;
	}

	public void RemoveRootView(RootView root)
	{
		if (root == null)
			return;

		for (int i < mRootViews.Count)
		{
			if (mRootViews[i] != root)
				continue;

			DetachView(root);
			mRootViews.RemoveAt(i);
			if (mActiveInputRoot == root)
				mActiveInputRoot = mRootViews.IsEmpty ? null : mRootViews[0];
			return;
		}
	}

	// ---- The view registry ---------------------------------------------------------------------

	public void Register(View view)
	{
		if ((view != null) && view.Id.IsValid)
			mRegistry[view.Id.RawValue] = view;
	}

	/// Forgets a view EVERYWHERE before it goes: the registry, and every manager holding its
	/// id or a pointer to it.
	///
	/// The tooltip manager is not ported, so it holds nothing to sweep and is not called here.
	/// Its sweep belongs in this method and must be added with it.
	public void Unregister(View view)
	{
		if ((view == null) || !view.Id.IsValid)
			return;

		mInputManager.OnViewDeleted(view);
		mFocusManager.OnViewDeleted(view);
		mShortcutManager.RemoveScopedTo(view);
		// A drag holds the source and the current drop target as RAW pointers, so a view
		// leaving mid drag has to be reported before it goes.
		mDragDropManager.OnViewDeleted(view);
		// A running animation holds a raw pointer to its target, so it has to go before the
		// view does: a fade left running over a removed view writes to freed memory.
		mAnimationManager.CancelForView(view);
		mRegistry.Remove(view.Id.RawValue);
	}

	/// BORROWED, and null when nothing is registered under that id, which is what makes an id
	/// safe to hold across a frame where a pointer would not be.
	public View GetViewById(ViewId id)
	{
		if (mRegistry.TryGetValue(id.RawValue, let view))
			return view;
		return null;
	}

	public T GetViewById<T>(ViewId id) where T : View => GetViewById(id) as T;

	// ---- Attach and detach -----------------------------------------------------------------

	/// Attaches a view and its whole subtree to this context.
	public void AttachView(View view)
	{
		// The ancestors changed, and so did the siblings a :first-child or :last-child
		// selector matches.
		InvalidateStyles();
		view.Context = this;
		Register(view);

		if (let group = view as ViewGroup)
		{
			for (int i < group.ChildCount)
				AttachView(group.GetChildAt(i));

			// A visual child that is not also a content child, such as a scroll view's bars.
			for (int i < group.VisualChildCount)
			{
				let visual = group.GetVisualChild(i);
				if ((visual != null) && (visual.Context != this))
					AttachView(visual);
			}
		}
	}

	/// Detaches a view and its whole subtree.
	public void DetachView(View view)
	{
		InvalidateStyles();
		Unregister(view);

		if (view.IsTransitionRegistered)
			UnregisterTransitioning(view);
		view.ClearTransitions();
		view.Context = null;

		if (let group = view as ViewGroup)
		{
			for (int i < group.ChildCount)
				DetachView(group.GetChildAt(i));

			for (int i < group.VisualChildCount)
			{
				let visual = group.GetVisualChild(i);
				if ((visual != null) && (visual.Context != null))
					DetachView(visual);
			}
		}
	}

	// ---- Injected seams ------------------------------------------------------------------------

	public IClipboard Clipboard => mClipboard;
	public void SetClipboard(IClipboard clipboard) => mClipboard = clipboard;

	public IFontService FontService => mFontService;
	public void SetFontService(IFontService fontService) => mFontService = fontService;

	/// Whether the FOCUSED view wants platform text input.
	///
	/// The shell bridge reads this as focus moves, to start and stop the window's IME. It is
	/// also a redraw producer: a focused text field has a caret to blink.
	public bool WantsTextInput()
	{
		let focused = mFocusManager.FocusedView;
		return (focused != null) && focused.WantsTextInput();
	}

	// ---- Frame lifecycle -----------------------------------------------------------------------

	/// Opens a frame: drains the deferred tree changes, advances the clocks, and ticks the
	/// running style transitions.
	public void BeginFrame(float deltaTime)
	{
		mDeltaTime = deltaTime;
		mTotalTime += deltaTime;
		mMutationQueue.Drain();

		// Each listed view advances its own clocks and marks its own damage, visual or layout
		// by the property's kind. A view with nothing left running takes itself off the list,
		// so this is walked BACKWARD to let entries drop out mid iteration.
		for (int i = mTransitioning.Count - 1; i >= 0; i--)
		{
			if (!mTransitioning[i].AdvanceTransitions(deltaTime))
				mTransitioning.RemoveAtFast(i);
		}

		// Continuous damage producers, marked BEFORE the host samples the damage state,
		// because the redraw gate hands out no free frames. A focused text input needs its
		// caret blink serviced whether or not anything else moved.
		if ((mAnimationManager.ActiveCount > 0) || WantsTextInput())
			MarkNeedsRedraw();

		// Ticked under a NON idle phase on purpose: an onComplete callback may mutate the view
		// tree, a screen transition removing its screen on finish being the usual case, and
		// under Idle that would run inline. An inline RemoveView reaches CancelForView, which
		// re-enters the very loop being walked.
		mPhase = .Animating;
		mAnimationManager.Update(deltaTime);
		mPhase = .Idle;

		// SEAM: Raptor also updates the tooltip manager here. It lands with Overlay.
	}

	/// Measures and arranges one root against its own viewport.
	///
	/// Layout runs in LOGICAL units: the physical viewport is divided by the DPI scale here,
	/// and the scale is reapplied once at draw, so nothing in between has to know about it.
	public void UpdateRootView(RootView root)
	{
		if (root == null)
			return;

		mPhase = .Layout;
		let logical = root.LogicalSize;
		root.Measure(BoxConstraints.Tight(logical.X, logical.Y));
		root.Layout(0, 0, logical.X, logical.Y);
		mPhase = .Idle;
	}

	/// Draws a root's tree into a vector graphics context.
	///
	/// The context's CURRENT font service is pushed into the VG on EVERY draw rather than
	/// trusted from construction time: a service swapped afterwards, such as one binding a
	/// cooked font, would otherwise leave the VG resolving atlases against the stale one, and
	/// text would go silently invisible.
	public void DrawRootView(RootView root, VGContext vg)
	{
		if (root == null)
			return;

		vg.SetFontService(mFontService); // the one source of truth, re-asserted per draw
		mPhase = .Drawing;

		let ctx = scope UIDrawContext(vg, root.DpiScale, mFontService);
		if (root.DpiScale != 1.0f)
			vg.Scale(root.DpiScale, root.DpiScale);
		root.OnDraw(ctx);

		mPhase = .Idle;
		mNeedsRedraw = false;
	}
}
