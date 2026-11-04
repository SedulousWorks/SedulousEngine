using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Profiler;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// GUIContext: one GUI, of any number of roots (windows, render targets, a panel in the world). It
// holds what is the GUI's rather than a window's: the animation clock (roots may pause or slow
// their own time on it), deferred tree edits, the bindings' scheduler (one flush a frame for every
// root, so a binding in one root reading a value another wrote runs once, in order), the named
// data, the commands and the keymap, the element table weak handles resolve through (so a handle
// survives its node moving between roots) and the element set. It tracks the active root, the one
// last given input: keystrokes, the gamepad and command availability follow its focus path. Every
// root is made in a context (a GUI of one root is a context with one); the host advances the GUI
// once a frame through GUIContext.Update.
//
// SceneRoot: the root of one GUI's widget tree AND its coordinator (eepp's Scene::SceneNode, by
// role). A Node subclass that sits at the top; it owns the event dispatcher and its display scale,
// and reaches its GUIContext's ActionManager, MutationQueue, element table and set.
// GUIContext.Update ticks running actions, then drains deferred tree edits. Drawing is inherited
// from Node.Draw, with the top layer drawn after the tree (DrawFrame).
//
// Each root is scaled on its own (one per window, or per render target: a panel in the world, a
// texture): its tree lays out in logical units, which its display scale (the window's content
// scale times a UI scale) maps to device pixels, through the root's own transform, so drawing and
// hit testing agree and two windows on monitors of different density each keep their own.
//
// Nodes reach the coordinator through Node's virtual ActionManager and MutationQueue, which walk
// up the parent chain; SceneRoot overrides them to return its own.

class GUIContext : RefCounted
{
	private const float cChordTimeout = 1.0f;

	public this()
	{
		BindTextEditingKeys(mKeymap); // a GUI's own bindings come later, so they win a tie
		mKeymap.Bind("f10", "menu.enter-bar");
		mKeymap.Bind("shift-f10", "menu.context");
		// A menu's moves, bindings in its key context.
		mKeymap.Bind("up", cMenuUpCommand, cMenuKeyContext);
		mKeymap.Bind("down", cMenuDownCommand, cMenuKeyContext);
		mKeymap.Bind("left", cMenuLeftCommand, cMenuKeyContext);
		mKeymap.Bind("right", cMenuRightCommand, cMenuKeyContext);
		mKeymap.Bind("return", cMenuActivateCommand, cMenuKeyContext);
		mKeymap.Bind("space", cMenuActivateCommand, cMenuKeyContext);
		// A drag from the keys and the pad: picked up at the focus, dropped with Return or South
		// (the dispatcher's while it drags).
		mKeymap.Bind("ctrl-shift-d", "drag.pick");
		mKeymap.Bind("pad-north", "drag.pick");
		// Back: one command for the keyboard and the pad, which a game rebinds like any.
		mKeymap.Bind("escape", cBackCommand);
		mKeymap.Bind("pad-east", cBackCommand);
	}

	public ~this()
	{
		Localization = null;
		mElements.Close();
	}

	/// Advances every root by `elapsed`, once a frame: what a platform's screen reader asked, the
	/// clock (each root's actions at its own time scale), each root's input repeat and per-frame
	/// hook, the bindings whose values changed, the deferred tree edits, each root's layout, then
	/// what changed to the accessibility bridge.
	public void Update(TimeSpan elapsed)
	{
		RunAccessRequests(); // what a platform asked since: this frame shows it
		let seconds = (float)elapsed.TotalSeconds;
		// The motion's clock steps at most so far: a hitch slows it rather than skipping it. By
		// ticks: TimeSpan.FromSeconds would round to whole milliseconds.
		let step = ((mMaxClockStep > 0.0f) && (seconds > mMaxClockStep))
			? TimeSpan((int64)((double)mMaxClockStep * (double)TimeSpan.TicksPerSecond))
			: elapsed;
		mActionManager.Update(step, scope (target) =>
			{
				let root = target.SceneRoot;
				return (root != null) ? root.EffectiveTimeScale : 1.0f;
			});
		if (!mChord.IsEmpty)
		{
			mChordAge += seconds;
			if (mChordAge > cChordTimeout)
			{
				// A chord not finished in time: what its keys so far bind (its first key alone) runs.
				let root = ActiveRoot;
				if (root != null)
					root.FinishChord();
				mChord.Clear();
			}
		}
		// A root's hook may add or remove roots: walk a copy.
		let roots = scope List<SceneRoot>();
		roots.AddRange(mRoots);
		for (let root in roots)
		{
			root.EventDispatcher.Tick(seconds);
			root.OnUpdate(elapsed);
		}
		mLastBindingCount = mEffects.Flush();
		mMutationQueue.Drain();
		for (let root in mRoots)
			root.UpdateLayout();
		FlushAccessibility(); // each root's changes to the accessibility bridge, last
	}

	public Sedulous.GUI.ActionManager ActionManager => mActionManager;
	public Sedulous.GUI.MutationQueue MutationQueue => mMutationQueue;
	public Sedulous.GUI.EffectScheduler EffectScheduler => mEffects;
	/// The GUI's named values, which markup and scripts bind to.
	public DataModel Data => mData;
	public CommandSet Commands => mCommands;
	public Command DefineCommand(StringView id) => mCommands.Define(id);
	public Sedulous.GUI.Keymap Keymap => mKeymap;

	/// Where its roots are on the screen, the host's (one that places its windows): a drag goes on
	/// from root to root, and one let go over none ends outside. Borrowed; null: each root alone.
	public IRootPlaces RootPlaces
	{
		get => mRootPlaces;
		set
		{
			mRootPlaces = value;
			for (let root in mRoots)
				root.EventDispatcher.RootPlaces = value;
		}
	}

	/// The fonts its text asks for (a rich text's own faces); borrowed.
	public IFontService FontService
	{
		get => mFontService;
		set => mFontService = value;
	}

	/// What the host knows of the user's preferences (its platform's dark mode, contrast and
	/// reduced-motion settings): sheets read them as prefers-color-scheme, prefers-contrast and
	/// prefers-reduced-motion. A change restyles at the next frame.
	public bool DarkScheme
	{
		get => mDarkScheme;
		set => mDarkScheme = value;
	}

	public Sedulous.GUI.ContrastPreference ContrastPreference
	{
		get => mContrast;
		set => mContrast = value;
	}

	public bool ReducedMotion
	{
		get => mReducedMotion;
		set => mReducedMotion = value;
	}

	/// The most the GUI's clock moves in one update, in seconds (0, the default: no limit). A game
	/// sets it so a hitch (a level loading under a menu) does not skip a screen's entrance or exit:
	/// its motion runs slower for that frame rather than jumping to its end.
	public float MaxClockStep
	{
		get => mMaxClockStep;
		set => mMaxClockStep = Math.Max(0.0f, value);
	}

	/// The resources its text asks for (a rich text's icons); borrowed.
	public IResourceProvider ResourceProvider
	{
		get => mResources;
		set => mResources = value;
	}

	/// The host's picture baker (its renderer's): an SVG skin drawn from a texture baked at the
	/// size it shows, not as paths every frame. None: paths. Borrowed.
	public IPictureBaker PictureBaker
	{
		get => mBaker;
		set => mBaker = value;
	}

	/// The texts its translated properties resolve through, the host's; borrowed. Its changes (a
	/// language, a table, pseudolocalization) re-resolve every translated property and restyle the
	/// roots (`:lang`). Null: a translated property shows its key.
	public Sedulous.I18N.Localization Localization
	{
		get => mLocalization;
		set
		{
			if (value == mLocalization)
				return;
			if (mLocalization != null)
				mLocalization.RemoveOnChanged(mLocalizationToken);
			mLocalization = value;
			mLocalizationToken = 0;
			if (mLocalization != null)
				mLocalizationToken = mLocalization.OnChanged(new () => LanguageChanged());
			LanguageChanged();
		}
	}

	/// Read by what follows the language (a translated property's binding): it reruns when it
	/// changes.
	public void TrackLanguage()
	{
		mLanguageChanged.Track();
	}

	/// A service a library finds through the GUI, by its key (the gamekit's InputPrompts, which the
	/// host gives): borrowed, the host's to keep alive while set; null clears it. What reads one
	/// follows it: a binding that read it runs again when it is set.
	public void SetService(StringView key, void* service)
	{
		for (int i = 0; i < mServices.Count; i++)
		{
			if (mServices[i].Key == key)
			{
				if (service == null)
				{
					delete mServices[i];
					mServices.RemoveAt(i);
				}
				else
					mServices[i].Service = service;
				mServicesChanged.Notify();
				return;
			}
		}
		if (service != null)
		{
			let entry = new ServiceEntry();
			entry.Key.Set(key);
			entry.Service = service;
			mServices.Add(entry);
		}
		mServicesChanged.Notify();
	}

	/// The service under `key`, or null; a read a binding follows.
	public void* GetService(StringView key)
	{
		mServicesChanged.Track();
		for (let entry in mServices)
		{
			if (entry.Key == key)
				return entry.Service;
		}
		return null;
	}

	public Sedulous.GUI.ElementTable ElementTable => mElements;

	/// What this GUI's markup and scripts may create (every registered element by default). Set,
	/// it takes a copy (the caller keeps its own).
	public Sedulous.GUI.ElementSet ElementSet
	{
		get => mElementSet;
		set => mElementSet.Set(value);
	}

	// === Roots ===

	public int RootCount => mRoots.Count;
	public SceneRoot GetRootAt(int index) => ((index >= 0) && (index < mRoots.Count)) ? mRoots[index] : null;

	/// The root last given input (keys, the gamepad, a press), or the first: where keystrokes, the
	/// gamepad and command availability go. A host or a script may set it.
	public SceneRoot ActiveRoot
	{
		get => (mActive != null) ? mActive : (mRoots.IsEmpty ? null : mRoots[0]);
		set
		{
			if (value == mActive)
				return;
			mActive = value;
			mActiveChanged.Notify();
		}
	}

	/// `root` took input from the user: it becomes the active root, and the other roots' light
	/// popups (auto ones and tooltips) close, as a press outside them would.
	public void TookInput(SceneRoot root)
	{
		for (let other in mRoots)
		{
			if (other != root)
				other.EventDispatcher.CloseLightPopups();
		}
		ActiveRoot = root;
	}

	// === Commands across roots ===

	/// Runs command `id` along the active root's focus path.
	public bool RunCommand(StringView id)
	{
		let root = ActiveRoot;
		return (root != null) && root.RunCommand(id);
	}

	/// Whether command `id` is available on the active root's focus path (a read a binding
	/// follows: the active root, its focus, the command, the handlers).
	public bool IsCommandAvailable(StringView id)
	{
		mActiveChanged.Track();
		let root = ActiveRoot;
		return (root != null) && root.IsCommandAvailable(id);
	}

	/// How many bindings the last Update ran.
	public uint32 LastBindingCount => mLastBindingCount;

	// === Accessibility ===

	/// The host's bridge to a screen reader (borrowed; null: none). While it listens, each Update
	/// sends every root's nodes that changed (all of them the first time) and the focus.
	public IAccessibilityBridge AccessibilityBridge
	{
		get => mAccessBridge;
		set
		{
			mAccessBridge = value;
			mAccessListening = false; // a new listener starts from the whole tree
		}
	}

	/// Speaks `text` through the bridge (a score, a level loaded: news no node holds).
	public void Announce(StringView text, AnnouncePriority priority = .Polite)
	{
		if ((mAccessBridge != null) && mAccessBridge.IsListening)
			mAccessBridge.Announce(text, priority);
	}

	/// Asks for an action a platform sends (from any thread); it runs in the next Update, on the
	/// GUI's thread, through the paths input takes. A copy is kept (the caller keeps its own).
	public void RequestAccessAction(AccessActionRequest request)
	{
		let copy = new AccessActionRequest();
		copy.Set(request);
		using (mAccessLock.Enter())
			mAccessRequests.Add(copy);
	}

	/// The node an accessibility id names, or null when it is gone (an item's: its view's).
	public Node ResolveAccessId(uint64 id)
	{
		if (IsAccessItemId(id))
		{
			if (mAccessViews.TryGetValue((uint32)((id & ~cAccessItemIdBit) >> 32), let view) && (view.Table != null))
				return view.Table.Resolve(view.Slot, view.Generation);
			return null;
		}
		return mElements.Resolve((uint32)(id & 0xFFFFFFFF), (uint32)(id >> 32));
	}

	private class ServiceEntry
	{
		public String Key = new .() ~ delete _;
		public void* Service = null;
	}

	private Sedulous.GUI.ActionManager mActionManager = new .() ~ delete _;
	private Sedulous.GUI.MutationQueue mMutationQueue = new .() ~ delete _;
	private Sedulous.GUI.EffectScheduler mEffects = new .() ~ delete _;
	private Sedulous.GUI.ElementTable mElements = new .() ~ _.ReleaseRef(); // what weak references to this GUI's nodes resolve through
	private Sedulous.GUI.ElementSet mElementSet = Sedulous.GUI.ElementSet.All() ~ delete _;
	private DataModel mData = new .() ~ _.ReleaseRef(); // shared with the bindings to it
	private CommandSet mCommands = new .() ~ delete _;
	private Sedulous.GUI.Keymap mKeymap = new .() ~ delete _;
	private IFontService mFontService = null;
	private bool mDarkScheme = true; // the user's preferences, for media queries
	private Sedulous.GUI.ContrastPreference mContrast = .NoPreference;
	private bool mReducedMotion = false;
	private IResourceProvider mResources = null;
	private IPictureBaker mBaker = null;
	private Sedulous.I18N.Localization mLocalization = null; // the host's
	private uint32 mLocalizationToken = 0;
	private Observable mLanguageChanged = new .() ~ delete _;
	private List<ServiceEntry> mServices = new .() ~ DeleteContainerAndItems!(_); // what libraries find through the GUI (borrowed)
	private Observable mServicesChanged = new .() ~ delete _;
	private List<Keystroke> mChord = new .() ~ delete _; // a chord typed so far (in the active root)
	private IAccessibilityBridge mAccessBridge = null; // the host's
	private bool mAccessListening = false; // it listened at the last update
	private Monitor mAccessLock = new .() ~ delete _; // guards the requests, which any thread adds
	private Dictionary<uint32, Node.ElementRef> mAccessViews = new .() ~ delete _; // item views by key, for their items' ids
	private uint32 mNextAccessView = 1;
	private List<AccessActionRequest> mAccessRequests = new .() ~ DeleteContainerAndItems!(_);
	private float mChordAge = 0.0f;
	private float mMaxClockStep = 0.0f; // the clock's step at most this (0: unlimited)
	private List<SceneRoot> mRoots = new .() ~ delete _; // not owned: each root registers itself and leaves on destruction
	private SceneRoot mActive = null;
	private Observable mActiveChanged = new .() ~ delete _;
	private uint32 mLastBindingCount = 0;
	private IRootPlaces mRootPlaces = null; // the host's

	// A root made in this context: it hands the root's dispatcher the places.
	private void AddRoot(SceneRoot root)
	{
		mRoots.Add(root);
		root.EventDispatcher.RootPlaces = mRootPlaces;
	}

	// A root goes: the others' drags forget it.
	private void RemoveRoot(SceneRoot root)
	{
		mRoots.Remove(root);
		for (let other in mRoots)
			other.EventDispatcher.ForgetRoot(root.EventDispatcher);
		if (mActive == root)
			ActiveRoot = null;
	}

	private void LanguageChanged()
	{
		mLanguageChanged.Notify(); // translated properties resolve again
		for (let root in mRoots)
			root.DirectionChanged(); // :lang may match otherwise, and the language's direction may differ
	}
}

[Scriptable]
class SceneRoot : Node
{
	/// A root of `context`'s GUI, beside its other roots (a GUI of one root is a context with
	/// one). It takes a reference to the context of its own (the caller keeps and releases the one
	/// it holds).
	public this(Sedulous.GUI.GUIContext context)
	{
		context.AddRef();
		mContext = context;
		mEventDispatcher = new .(this);
		mContext.[Friend]AddRoot(this);
		mEventDispatcher.SetKeystrokeRouter(new (stroke) => RouteKeystroke(stroke));
		mEventDispatcher.SetOnInput(new () => mContext.TookInput(this));
		// F10 (bound in every GUI): the first node in this tree that takes it, a menu bar.
		OnCommand("menu.enter-bar", new (command) => { EnterFromKeyboardIn(this); });
		// Shift+F10 (bound in every GUI): the focused node's context menu.
		OnCommand("menu.context", new (command) => { mEventDispatcher.InjectContextMenu(); });
		// Ctrl+Shift+D or the pad's North (bound in every GUI): a drag picked up at the focus.
		OnCommand("drag.pick", new (command) => { mEventDispatcher.PickDrag(); });
	}

	public ~this()
	{
		mContext.[Friend]RemoveRoot(this);
		delete mEventDispatcher;
		mEventDispatcher = null;
		mContext.ReleaseRef(); // the GUI this root was part of (it outlives the rest of the root)
	}

	public Sedulous.GUI.GUIContext Context => mContext;
	public override Sedulous.GUI.GUIContext GUIContext => mContext;

	/// Runs this root's layout pass: every container that requested a layout, parents first,
	/// again while a layout requests more (a child's new size can move its parent), at most a few
	/// rounds. A host runs it after styling and before drawing; Update runs it too.
	public new void UpdateLayout()
	{
		using (ProfileScope("GUI.Layout"))
		{
			let watch = scope Stopwatch(true);
			mLastLayoutCount = base.UpdateLayout();
			mEventDispatcher.PlacePopups(); // the top layer follows what moved
			mFrameStats.LayoutMs += watch.Elapsed.TotalMilliseconds; // the GUI's Update lays out too
			mFrameStats.LaidOut += mLastLayoutCount;
		}
	}

	/// How many containers the last layout pass laid out (none in a frame where nothing moved).
	public uint32 LastLayoutCount => mLastLayoutCount;

	/// Whether this root has anything to show that it has not drawn: something invalidated, an
	/// animation running on a node it shows, a layout or a binding waiting, a direction held. An
	/// action on a node out of view still runs (the GUI's Update ticks it either way); it asks for
	/// no frame until what it does shows. A host skips a frame that needs none: an idle GUI costs
	/// nothing. The reasons it found go to the frame stats, and the frame's style and layout are
	/// done: they become the last frame's, which a draw then completes (a host asks once a frame,
	/// after styling and laying out).
	public bool NeedsFrame()
	{
		var why = mFrameStats.Reasons;
		// A bake landed since this root last drew: what drew as paths while it waited draws from
		// it now.
		let baker = mContext.PictureBaker;
		if ((baker != null) && (baker.Generation != mBakeGeneration))
			Invalidate();
		why.Redraw = NeedsRedraw;
		why.Layout = IsLayoutDirty || HasLayoutDirtyDescendant;
		why.Pending = mContext.EffectScheduler.HasPending;
		why.HeldDirection = mEventDispatcher.IsHoldingDirection;
		Node animated = null;
		if (!mPaused)
		{
			mContext.ActionManager.AnyAction(scope [&] (action, target) =>
				{
					if ((target.SceneRoot != this) || !target.IsTreeVisible || !action.AsksForFrames)
						return false;
					// Out of view at the last frame (culled, or under something culled), an animation
					// that cannot bring it into view changes nothing that shows.
					if (target.WasOutOfView && !action.CanMoveTarget)
						return false;
					animated = target;
					return true;
				});
		}
		why.Animation = animated != null;
		mFrameStats.AnimatedNode.Clear();
		if (animated != null)
			animated.DebugName(mFrameStats.AnimatedNode);
		why.Overlay = mDebugOverlay.RedrawFlash && !mFlashes.IsEmpty;
		mFrameStats.Reasons = why;
		let needed = why.Any;
		PublishFrame();
		return needed;
	}

	/// Draws the tree as Draw does, timing it and counting what it made: the host's frame. A frame
	/// drawn through Draw alone goes uncounted.
	public void DrawFrame(DrawContext ctx)
	{
		using (ProfileScope("GUI.Draw"))
		{
			if (!mFramePublished)
				PublishFrame(); // a host that draws every frame without asking
			let watch = scope Stopwatch(true);
			let before = ctx.VG.GetBatch();
			let vertices = before.Vertices.Count + before.BoxVertices.Count;
			let commands = before.Commands.Count;
			let drawn = ctx.NodesDrawn;
			let culled = ctx.NodesCulled;
			ctx.Frame = (uint32)(mFramesDrawn + 1); // the nodes drawn note it (FramesDrawn is set after)
			ctx.PictureBaker = mContext.PictureBaker;
			mBakeGeneration = (mContext.PictureBaker != null) ? mContext.PictureBaker.Generation : 0;
			mFrameRedraws.Clear();
			if (mDebugOverlay.RedrawFlash)
				ctx.SetRedrawRecorder(mFrameRedraws);
			// Damage: what changed since the last frame, its nodes' old areas noted as they
			// changed, their new ones as they draw.
			Swap!(mLastDamage, mPendingDamage);
			mPendingDamage.Clear();
			ctx.SetDamageRecorder(mLastDamage);
			// The window bounds the drawing, so what lies outside it is culled; only the drawing:
			// navigation and hit testing still reach a node past it. The clip is pushed outside the
			// root's own transform, so it is the root's size in the device pixels it draws to (its
			// layout size times its display scale), not its layout size: on a scaled display the
			// latter cut the drawing to a corner (1/1.75 of it at 175%).
			let sized = (Size.X > 0.0f) && (Size.Y > 0.0f);
			if (sized)
				ctx.PushClip(.(Position.X, Position.Y, Size.X * mDisplayScale, Size.Y * mDisplayScale));
			Draw(ctx);
			if (sized)
				ctx.PopClip();
			ctx.SetRedrawRecorder(null);
			ctx.SetDamageRecorder(null);
			mLastDamageBounds = .();
			for (int i = 0; i < mLastDamage.Count; i++)
				mLastDamageBounds = (i == 0) ? mLastDamage[i] : Rect.Union(mLastDamageBounds, mLastDamage[i]);
			let batch = ctx.VG.GetBatch(); // flushed: its last command counts
			mLastFrame.DrawMs = watch.Elapsed.TotalMilliseconds;
			mLastFrame.NodesDrawn = ctx.NodesDrawn - drawn;
			mLastFrame.NodesCulled = ctx.NodesCulled - culled;
			mLastFrame.Vertices = (uint32)(batch.Vertices.Count + batch.BoxVertices.Count - vertices);
			mLastFrame.Commands = (uint32)(batch.Commands.Count - commands);
			mLastFrame.FramesDrawn = ++mFramesDrawn;
			mFramePublished = false;
		}
	}

	/// What the last frame drew changed, in device pixels: each node's area where it is new,
	/// changed, moved or gone, and the bounds of them all. A host that can present part of a frame
	/// (or redraw a HUD over its scene) redraws this much; empty when nothing changed.
	public List<Rect> LastDamage => mLastDamage;
	public Rect LastDamageBounds => mLastDamageBounds;

	public override void AddDamage(Rect device)
	{
		mPendingDamage.Add(device);
	}

	/// The frame in progress, which the phases add to.
	public override Sedulous.GUI.FrameStats FrameStats => mFrameStats;
	/// The last frame: its style, layout and reasons (as NeedsFrame closed it), and its draw (none
	/// when it was skipped).
	public Sedulous.GUI.FrameStats LastFrameStats => mLastFrame;
	public override uint32 LastDrawnFrame => (uint32)mFramesDrawn;

	// === This root's time on the GUI's clock ===

	/// Its animations' time scale (1: real time; 0.5: half speed). A paused root's stand still.
	public float TimeScale
	{
		get => mTimeScale;
		set => mTimeScale = Math.Max(0.0f, value);
	}

	public bool Paused
	{
		get => mPaused;
		set => mPaused = value;
	}

	public float EffectiveTimeScale => mPaused ? 0.0f : mTimeScale;

	public override Sedulous.GUI.EffectScheduler EffectScheduler => mContext.EffectScheduler;
	public override Sedulous.GUI.ActionManager ActionManager => mContext.ActionManager;
	public override Sedulous.GUI.MutationQueue MutationQueue => mContext.MutationQueue;
	public override Sedulous.GUI.EventDispatcher EventDispatcher => mEventDispatcher;
	public override IFontService FontService => mContext.FontService;
	public override IResourceProvider ResourceProvider => mContext.ResourceProvider;
	public override Sedulous.GUI.ElementTable ElementTable => mContext.ElementTable;
	public override Sedulous.GUI.ElementSet ElementSet => mContext.ElementSet;

	// === Commands, along this root's focus path ===

	/// Runs command `id` along this root's focus path (the root alone when nothing here is
	/// focused): capture handlers from the root down, then bubble handlers from the focused widget
	/// up, the first bubble handler stopping it unless it sets Propagate. False when it is disabled
	/// or nothing handled it.
	public bool RunCommand(StringView id)
	{
		let command = mContext.Commands.Find(id);
		if ((command != null) && !Observer.Untracked<bool>(scope () => command.Enabled))
			return false;
		// Back closes the topmost auto popup before anything under it hears it: the top layer is
		// on top whether or not it holds the focus (a combo box's list).
		if ((id == cBackCommand) && mEventDispatcher.CloseTopAutoPopup(.Escape))
			return true;
		// Focused first, up to this root or a modal popup (below it is inert); held for the walk, as
		// a handler may end nodes on it (a dock float its own move empties).
		let path = scope List<Node>();
		defer
		{
			for (let n in path)
				n.ReleaseRef();
		}
		for (var n = CommandStart(); n != null; n = n.Parent)
		{
			n.AddRef();
			path.Add(n);
			if (n.RouteStop)
				break;
		}
		bool ran = false;
		var e = CommandEvent();
		e.Id = id;
		e.Phase = .Capture;
		e.Propagate = false;
		e.Stop = false;
		for (int i = path.Count - 1; i >= 0; i--)
		{
			ran |= path[i].RunCommandHandlers(ref e);
			if (e.Stop)
				return true; // taken on the way down (a modal wrapper, a mode that owns the key)
		}
		e.Phase = .Bubble;
		for (let n in path)
		{
			e.Propagate = false;
			if (n.RunCommandHandlers(ref e))
			{
				ran = true;
				if (!e.Propagate)
					break;
			}
		}
		return ran;
	}

	/// Whether command `id` is enabled and a handler for it is on this root's focus path: a read a
	/// binding follows (focus, the command's state, the handlers).
	public bool IsCommandAvailable(StringView id)
	{
		mContext.Commands.TrackChanges();
		mEventDispatcher.ObserveFocus();
		let command = mContext.Commands.Find(id);
		if ((command != null) && !command.Enabled)
			return false;
		if ((id == cBackCommand) && mEventDispatcher.HasTopAutoPopup)
			return true;
		for (var n = CommandStart(); n != null; n = n.Parent)
		{
			if (n.HandlesCommand(id))
				return true;
			if (n.RouteStop)
				break;
		}
		return false;
	}

	/// The key contexts in force at `from` (root first, one layer per node up from it that
	/// declares one, up to this root or a modal popup), added to `outStack`: what the keymap
	/// matches against there. The caller owns the layers added.
	public void KeyContextsAt(Node from, List<KeyContextLayer> outStack)
	{
		let path = scope List<Node>();
		for (var n = from; n != null; n = n.Parent)
		{
			path.Add(n);
			if (n.RouteStop)
				break;
		}
		let layer = scope KeyContextLayer();
		for (int i = path.Count - 1; i >= 0; i--)
		{
			if (path[i].KeyContext.Length != 0)
			{
				layer.Declare(path[i].KeyContext);
				let copy = new KeyContextLayer();
				copy.Set(layer);
				outStack.Add(copy);
			}
		}
	}

	/// A chord cut short: what its keys so far are whole for runs (a binding of its first key
	/// alone, which waited to see if the chord went on), and the chord ends.
	public void FinishChord()
	{
		let chord = mContext.[Friend]mChord;
		let command = scope String();
		let stack = scope List<KeyContextLayer>();
		defer { ClearAndDeleteItems!(stack); }
		KeyContextsAt(CommandStart(), stack);
		let whole = !chord.IsEmpty && mContext.Keymap.MatchWhole((Span<Keystroke>)chord, (Span<KeyContextLayer>)stack, command);
		chord.Clear();
		if (whole)
			RunCommand(command);
	}

	/// A keystroke no widget used: matched against the GUI's keymap in this root's focus-path
	/// contexts (a chord waits for its next keystroke); a match runs its command. True when it was
	/// taken (a match, or the start of a chord).
	public bool RouteKeystroke(Keystroke stroke)
	{
		let stack = scope List<KeyContextLayer>(); // root first
		defer { ClearAndDeleteItems!(stack); }
		KeyContextsAt(CommandStart(), stack);
		let chord = mContext.[Friend]mChord;
		chord.Add(stroke);
		mContext.[Friend]mChordAge = 0.0f;
		let command = scope String();
		var match = mContext.Keymap.Match((Span<Keystroke>)chord, (Span<KeyContextLayer>)stack, command);
		if ((match == .None) && (chord.Count > 1))
		{
			// A chord broken off: what came before runs as whole if it is (its first key's own
			// binding), then the keystroke alone.
			chord.PopBack();
			FinishChord();
			chord.Add(stroke);
			match = mContext.Keymap.Match((Span<Keystroke>)chord, (Span<KeyContextLayer>)stack, command);
		}
		if (match == .Pending)
			return true;
		chord.Clear();
		if ((match == .None) || (command.Length == 0))
			return false; // no binding, or unbound here: as if none
		// Nothing on the focus path handles it (a menu's keys on a bar button with no menu open):
		// as if unbound, so the key goes on to navigation. One disabled is still taken.
		var handled = (command == cBackCommand) && mEventDispatcher.HasTopAutoPopup;
		for (var n = CommandStart(); (n != null) && !handled; n = n.Parent)
		{
			handled = n.HandlesCommand(command);
			if (n.RouteStop)
				break;
		}
		if (!handled)
			return false;
		RunCommand(command);
		return true;
	}

	/// Device pixels per logical unit: the window's content scale times a UI scale. The tree lays
	/// out, styles and handles input in logical units; the root's transform maps them to device
	/// pixels (input in device pixels hit-tests through it). The size follows: the viewport's
	/// device pixels over the scale.
	public float DisplayScale
	{
		get => mDisplayScale;
		set
		{
			let was = mDisplayScale;
			mDisplayScale = Math.Max(value, 0.01f);
			mScale = .(mDisplayScale, mDisplayScale); // the transform's own, not a change a node invalidates for
			MarkDirty();
			if (mDisplayScale != was)
			{
				RequestLayoutTree(); // every edge rounds to the new grid
				Invalidate(); // the same scale again changes nothing (no damage)
			}
			ApplyViewport();
		}
	}

	/// What the debug overlay shows over this GUI's tree (nothing by default).
	public Sedulous.GUI.DebugOverlay DebugOverlay
	{
		get => mDebugOverlay;
		set
		{
			if (value == mDebugOverlay)
				return;
			mDebugOverlay = value;
			Invalidate();
		}
	}

	/// The font the overlay names nodes and numbers tab stops in (none: it draws no text).
	/// Borrowed.
	public CachedFont DebugFont
	{
		get => mDebugFont;
		set => mDebugFont = value;
	}

	/// The redraw flashes still fading (the debug overlay's), in this root's space.
	public int RedrawFlashCount => mFlashes.Count;

	/// The device pixels this root covers (its window's or target's); its size is them in logical
	/// units.
	public Float2 ViewportSize
	{
		get => mViewport;
		set
		{
			mViewport = value;
			ApplyViewport();
		}
	}

	/// What this root's media queries see: its logical size, and its density (96 dpi at 1x).
	public Sedulous.GUI.MediaContext MediaContext
	{
		get
		{
			var context = Sedulous.GUI.MediaContext(Size.X, Size.Y, 96.0f * mDisplayScale);
			context.DarkScheme = mContext.DarkScheme;
			context.Contrast = mContext.ContrastPreference;
			context.ReducedMotion = mContext.ReducedMotion;
			context.Input = mEventDispatcher.InputKind; // `@media (input: pad)`
			return context;
		}
	}

	/// Per-frame hook for subclasses (layout, timers, ...).
	public virtual void OnUpdate(TimeSpan elapsed)
	{
	}

	protected override float TopPixelScale => mDisplayScale;

	// A node with no `lang` above it speaks the GUI's language (its Localization's).
	protected override void ContextLanguage(String outText)
	{
		let loc = mContext.Localization;
		if (loc != null)
			outText.Append(loc.Language);
	}

	protected override bool ContextRightToLeft
	{
		get
		{
			let loc = mContext.Localization;
			return (loc != null) && loc.IsRightToLeft();
		}
	}

	protected override void OnDrawAbove(DrawContext ctx)
	{
		mEventDispatcher.DrawPopups(ctx); // the top layer, after the tree
		if (mDebugOverlay.AnyLayout)
			DrawLayoutOverlay(ctx, mDebugOverlay);
		if (mDebugOverlay.RedrawFlash)
			DrawRedrawFlashes(ctx);
		if (mDebugOverlay.AnyInput)
			DrawInputOverlay(ctx);
	}

	private class RedrawFlash
	{
		/// In this root's space.
		public Rect Box;
		public Stopwatch Age = new .(true) ~ delete _;
	}

	// `node`'s border box in this root's space.
	private Rect InRootSpace(Node node) => (Transform.GetInverse() * node.WorldTransform).TransformRect(node.LocalBounds);

	private Sedulous.GUI.GUIContext mContext; // the GUI this root is part of (a reference held, let go last)
	private bool mAccessTreeSent = false; // its whole tree went to the bridge
	private uint64 mAccessFocus = 0; // the focus the bridge was last told
	private Sedulous.GUI.EventDispatcher mEventDispatcher; // pointer, hover and focus: this root's own
	private float mDisplayScale = 1.0f;
	private Sedulous.GUI.DebugOverlay mDebugOverlay = .();
	private List<Rect> mFrameRedraws = new .() ~ delete _; // the nodes this frame drew that invalidated themselves (world)
	private List<Rect> mPendingDamage = new .() ~ delete _; // old areas noted since the last frame (device pixels)
	private List<Rect> mLastDamage = new .() ~ delete _; // the last frame's damage
	private Rect mLastDamageBounds = .();
	private List<RedrawFlash> mFlashes = new .() ~ DeleteContainerAndItems!(_); // fading
	private CachedFont mDebugFont = null; // the overlay's text (the host's)
	private Sedulous.GUI.FrameStats mFrameStats = new .() ~ delete _; // in progress
	private Sedulous.GUI.FrameStats mLastFrame = new .() ~ delete _;
	private uint64 mFramesDrawn = 0;
	private uint64 mBakeGeneration = 0; // the picture baker's, as of the last frame drawn
	private bool mFramePublished = false;
	private float mTimeScale = 1.0f;
	private bool mPaused = false;
	private uint32 mLastLayoutCount = 0;
	private Float2 mViewport = .(0.0f, 0.0f);

	// The frame's style and layout are done: the last frame starts from them, undrawn.
	private void PublishFrame()
	{
		// Copied into, not replaced: what LastFrameStats handed out stays the last frame's.
		mLastFrame.Set(mFrameStats);
		mLastFrame.FramesDrawn = mFramesDrawn;
		mFrameStats.Reset();
		mFramePublished = true;
	}

	// The focused node when it is in this tree, else this root.
	private Node FocusInThisTree()
	{
		let focus = mEventDispatcher.FocusNode;
		for (var n = focus; n != null; n = n.Parent)
		{
			if (n == this)
				return focus;
		}
		return this;
	}

	// The first visible, enabled node from `node` down (pre-order) that takes the keyboard's entry.
	private static bool EnterFromKeyboardIn(Node node)
	{
		if (!node.Visible || !node.IsTreeEnabled)
			return false;
		if ((node != node.RootNode) && node.EnterFromKeyboard())
			return true;
		for (int i = 0; i < node.ChildCount; i++)
		{
			if (EnterFromKeyboardIn(node.GetChildAt(i)))
				return true;
		}
		return false;
	}

	// Where a command or a keystroke starts: the focus here, else the root; below a modal popup,
	// the modal popup (what is under it is inert, its bindings too).
	private Node CommandStart()
	{
		let start = FocusInThisTree();
		return mEventDispatcher.IsInputLive(start) ? start : mEventDispatcher.FocusScopeRoot;
	}

	private void ApplyViewport()
	{
		if ((mViewport.X > 0.0f) || (mViewport.Y > 0.0f))
			Size = .(mViewport.X / mDisplayScale, mViewport.Y / mDisplayScale);
	}
}
