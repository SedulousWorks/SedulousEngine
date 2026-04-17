namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.VG;
using Sedulous.Fonts;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// Central owner of the view tree, element registry, and mutation queue.
/// One UIContext per UI surface (typically one per window).
public class UIContext
{
	// === Element registry (ViewId → live View) ===
	private Dictionary<int32, View> mRegistry = new .() ~ delete _;

	// === Root of the view tree ===
	private RootView mRoot ~ delete _;

	// === Deferred mutation ===
	public MutationQueue MutationQueue { get; } = new .() ~ delete _;

	// === Phase tracking ===
	public UIPhase Phase { get; private set; } = .Idle;

	// === DPI scale ===
	public float DpiScale { get => mRoot?.DpiScale ?? 1.0f; }

	// === Font service (optional — set by UISubsystem) ===
	public IFontService FontService;

	// === Debug draw settings ===
	public UIDebugDrawSettings DebugSettings;

	// === Input + Focus ===
	public InputManager InputManager { get; private set; }
	public FocusManager FocusManager { get; private set; }

	/// The root view of this UI surface.
	public RootView Root => mRoot;

	public this()
	{
		InputManager = new InputManager(this);
		FocusManager = new FocusManager(this);
		mRoot = new RootView();
		ViewGroup.AttachSubtree(mRoot, this);
	}

	public ~this()
	{
		delete InputManager;
		delete FocusManager;
	}

	// === Registry ===

	public void RegisterElement(View view)
	{
		mRegistry[view.Id.Value] = view;
	}

	public void UnregisterElement(View view)
	{
		mRegistry.Remove(view.Id.Value);
		// Notify managers so they can clear any ViewId references.
		InputManager?.OnElementDeleted(view);
		FocusManager?.OnElementDeleted(view);
	}

	public View GetElementById(ViewId id)
	{
		if (mRegistry.TryGetValue(id.Value, let view))
			return view;
		return null;
	}

	// === Frame lifecycle ===

	/// Call once per frame before layout/draw. Drains the mutation queue.
	public void BeginFrame(float deltaTime)
	{
		Phase = .Draining;
		MutationQueue.Drain();
		Phase = .Idle;
	}

	/// Run the Measure + Layout pass on the tree.
	public void DoLayout()
	{
		Phase = .LayingOut;

		let vp = mRoot.ViewportSize;
		mRoot.Measure(.Exactly(vp.X), .Exactly(vp.Y));
		mRoot.Layout(0, 0, vp.X, vp.Y);

		Phase = .Idle;
	}

	/// Walk the tree and emit draw calls into the given VGContext.
	public void Draw(VGContext vg, float uiScale = 1.0f)
	{
		Phase = .Drawing;

		let drawCtx = scope UIDrawContext(vg, uiScale, FontService, DebugSettings);

		// Apply global DPI scale at the root.
		if (uiScale != 1.0f)
			vg.Scale(uiScale, uiScale);

		mRoot.OnDraw(drawCtx);

		Phase = .Idle;
	}

	/// Set the viewport size (logical units) on the root.
	public void SetViewportSize(float width, float height)
	{
		mRoot.ViewportSize = .(width, height);
		mRoot.InvalidateLayout();
	}
}
