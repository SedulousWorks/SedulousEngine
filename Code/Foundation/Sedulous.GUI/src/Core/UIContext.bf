namespace Sedulous.GUI;

using System;
using System.Collections;

/// Central coordinator for a GUI context. Manages the view registry,
/// name registry, mutation queue, and frame lifecycle. Manager slots
/// (Input, Focus, DragDrop, etc.) are added in later phases.
public class UIContext
{
	/// Current frame phase — prevents unsafe operations during layout/draw.
	public enum Phase
	{
		Idle,
		Layout,
		Drawing
	}

	// -- Registry --

	/// ViewId -> ViewHandle mapping. All live views are registered here.
	private Dictionary<uint32, ViewHandle> mViewRegistry = new .() ~ delete _;

	/// Name -> ViewHandle mapping for named views (CSS id equivalent).
	private Dictionary<String, ViewHandle> mNameRegistry = new .() ~ DeleteDictionaryAndKeys!(_);

	// -- Roots --

	private List<RootView> mRootViews = new .() ~ delete _;

	// -- Lifecycle --

	private MutationQueue mMutationQueue = new .() ~ delete _;
	private Phase mPhase = .Idle;
	private bool mNeedsRedraw;
	private float mDeltaTime;
	private float mTotalTime;

	// -- Public accessors --

	public Phase CurrentPhase => mPhase;
	public float DeltaTime => mDeltaTime;
	public float TotalTime => mTotalTime;
	public bool NeedsRedraw => mNeedsRedraw;

	// -- View registry --

	/// Registers a view and its entire subtree with this context.
	public void AttachView(View view)
	{
		Register(view);
		view.[Friend]mContext = this;

		if (let group = view as ViewGroup)
		{
			for (int i = 0; i < group.ChildCount; i++)
				AttachView(group.GetChildAt(i));
		}
	}

	/// Unregisters a view and its entire subtree from this context.
	public void DetachView(View view)
	{
		if (let group = view as ViewGroup)
		{
			for (int i = 0; i < group.ChildCount; i++)
				DetachView(group.GetChildAt(i));
		}

		view.[Friend]mContext = null;
		Unregister(view);
	}

	/// Registers a single view (not its children).
	private void Register(View view)
	{
		mViewRegistry[view.Id.RawValue] = view.Handle;

		// Register name if set.
		let name = view.Name.Value;
		if (name != null && name.Length > 0)
			RegisterName(view);
	}

	/// Unregisters a single view (not its children).
	private void Unregister(View view)
	{
		mViewRegistry.Remove(view.Id.RawValue);

		let name = view.Name.Value;
		if (name != null && name.Length > 0)
			UnregisterName(view);
	}

	/// Registers a view's name in the name registry.
	internal void RegisterName(View view)
	{
		let name = view.Name.Value;
		if (name == null || name.Length == 0)
			return;

		mNameRegistry[new String(name)] = view.Handle;
	}

	/// Removes a view's name from the name registry.
	internal void UnregisterName(View view)
	{
		let name = view.Name.Value;
		if (name == null || name.Length == 0)
			return;

		for (let kv in mNameRegistry)
		{
			if (kv.value === view.Handle)
			{
				let key = kv.key;
				mNameRegistry.Remove(kv.key);
				delete key;
				break;
			}
		}
	}

	// -- Lookup --

	/// Looks up a view by its ViewId. Returns null if not found or deleted.
	public View GetViewById(ViewId id)
	{
		if (!id.IsValid)
			return null;

		if (mViewRegistry.TryGetValue(id.RawValue, let handle))
			return handle.View;

		return null;
	}

	/// Looks up a view by its ViewId and casts to T. Returns null if not
	/// found, deleted, or wrong type.
	public T GetViewById<T>(ViewId id) where T : View
	{
		return GetViewById(id) as T;
	}

	/// Finds a view by name. Returns null if not found or deleted.
	public View FindByName(StringView name)
	{
		for (let kv in mNameRegistry)
		{
			if (StringView(kv.key) == name)
				return kv.value.View;
		}
		return null;
	}

	/// Finds a view by name and casts to T.
	public T FindByName<T>(StringView name) where T : View
	{
		return FindByName(name) as T;
	}

	// -- Root views --

	public void AddRootView(RootView root)
	{
		mRootViews.Add(root);
		AttachView(root);
	}

	public void RemoveRootView(RootView root)
	{
		DetachView(root);
		mRootViews.Remove(root);
	}

	public int RootViewCount => mRootViews.Count;

	public RootView GetRootView(int index) => mRootViews[index];

	// -- Invalidation --

	/// Marks the context as needing a redraw.
	public void MarkNeedsRedraw()
	{
		mNeedsRedraw = true;
	}

	/// Marks the context as needing a layout pass.
	public void MarkNeedsLayout()
	{
		mNeedsRedraw = true;
		// TODO: track layout-dirty flag separately when layout optimization is added.
	}

	// -- Mutation queue --

	/// Queue an action for deferred execution at frame end.
	public void QueueMutation(delegate void() action)
	{
		mMutationQueue.QueueAction(action);
	}

	// -- Frame lifecycle --

	/// Begin a new frame. Call before layout/update.
	public void BeginFrame(float deltaTime)
	{
		mDeltaTime = deltaTime;
		mTotalTime += deltaTime;
		mPhase = .Layout;
		mNeedsRedraw = false;
	}

	/// End the current frame. Drains the mutation queue, then purges
	/// invalidated view handles.
	public void EndFrame()
	{
		mPhase = .Idle;
		mMutationQueue.Drain();
		ViewHandleRegistry.PurgeInvalidated();
	}

	/// Set the phase to Drawing. Called by the rendering layer between
	/// layout and draw.
	public void BeginDraw()
	{
		mPhase = .Drawing;
	}

	/// Reset the phase after drawing.
	public void EndDraw()
	{
		mPhase = .Idle;
	}
}
