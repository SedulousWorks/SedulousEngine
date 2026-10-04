using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.Engine.UI.Script;

/// `Ui` to a script: the screen tier. The finders search the screen root; Push, Pop,
/// Replace, Clear and Back drive the screen stack; a document is instantiated by what the
/// application supplies. A per run service, like Run; unwired, every handle is null and
/// every stack verb a no-op.
[Scriptable, ScriptService, DisplayName("Ui")]
class UiScript
{
	/// Instantiates a cooked document by id into a live view, or null. TAKES OWNERSHIP of
	/// the delegate; the view comes back with one reference, the caller's.
	public typealias Instantiator = delegate View(Guid document);

	/// The screen stack's resolver: where this service's screens live, asked at each call. A run's
	/// service answers its run's stack (the editor's Game tabs each have their own screen tier),
	/// so the answer can change after it is attached. OWNED.
	public typealias StackResolver = delegate ScreenStack();

	/// BORROWED: the tier's stack, over the screen root, when attached to a fixed one.
	private ScreenStack mFixedStack = null;
	private StackResolver mResolve = null ~ delete _;
	private Instantiator mInstantiate = null ~ delete _;

	/// A fixed stack. TAKES OWNERSHIP of `instantiate`.
	public void Attach(ScreenStack stack, Instantiator instantiate)
	{
		mFixedStack = stack;
		DeleteAndNullify!(mResolve);
		delete mInstantiate;
		mInstantiate = instantiate;
	}

	/// A stack resolved at each call. TAKES OWNERSHIP of both delegates.
	public void Attach(StackResolver resolve, Instantiator instantiate)
	{
		mFixedStack = null;
		delete mResolve;
		mResolve = resolve;
		delete mInstantiate;
		mInstantiate = instantiate;
	}

	/// The stack the calling script's screens live on, or null when unwired.
	private ScreenStack Stack => (mResolve != null) ? mResolve() : mFixedStack;

	private ViewGroup RootGroup
	{
		get
		{
			let stack = Stack;
			return (stack != null) ? stack.Root : null;
		}
	}

	/// The screen tier's root, as a group handle.
	[Scriptable]
	public UiGroup Root => .(RootGroup);
	/// The top screen on the stack, null when empty.
	[Scriptable]
	public UiScreen Top
	{
		get
		{
			let stack = Stack;
			return .((stack != null) ? stack.Top : null);
		}
	}
	[Scriptable]
	public int32 Count
	{
		get
		{
			let stack = Stack;
			return (stack != null) ? (int32)stack.Count : 0;
		}
	}

	[Scriptable]
	public UiView Find(StringView name) => UiFinders.FindByName(RootGroup, name);
	[Scriptable]
	public UiLabel FindLabel(StringView name) => UiFinders.FindLabel(RootGroup, name);
	[Scriptable]
	public UiButton FindButton(StringView name) => UiFinders.FindButton(RootGroup, name);
	[Scriptable]
	public UiProgressBar FindProgressBar(StringView name) => UiFinders.FindProgressBar(RootGroup, name);
	[Scriptable]
	public UiSlider FindSlider(StringView name) => UiFinders.FindSlider(RootGroup, name);
	[Scriptable]
	public UiTextBox FindTextBox(StringView name) => UiFinders.FindTextBox(RootGroup, name);
	[Scriptable]
	public UiImage FindImage(StringView name) => UiFinders.FindImage(RootGroup, name);
	[Scriptable]
	public UiGroup FindGroup(StringView name) => UiFinders.FindGroup(RootGroup, name);

	/// Instantiates the document and pushes it as a screen: the document's own root when
	/// it is one, otherwise wrapped in a fresh screen. Null when nothing could be made.
	[Scriptable]
	public UiScreen Push(Guid document)
	{
		let stack = Stack;
		let screen = MakeScreen(document);
		if ((screen == null) || (stack == null))
		{
			if (screen != null)
				screen.ReleaseRef();
			return .();
		}
		// The stack consumes the reference; the handle takes its own through the table.
		let handle = UiScreen(screen);
		stack.Push(screen);
		return handle;
	}

	[Scriptable]
	public void Pop()
	{
		if (let stack = Stack)
			stack.Pop();
	}

	[Scriptable]
	public UiScreen Replace(Guid document)
	{
		let stack = Stack;
		let screen = MakeScreen(document);
		if ((screen == null) || (stack == null))
		{
			if (screen != null)
				screen.ReleaseRef();
			return .();
		}
		let handle = UiScreen(screen);
		stack.Replace(screen);
		return handle;
	}

	[Scriptable]
	public void Clear()
	{
		if (let stack = Stack)
			stack.Clear();
	}

	/// Pops the top unless it is the last screen; whether it popped.
	[Scriptable]
	public bool Back()
	{
		let stack = Stack;
		return (stack != null) && stack.HandleBack();
	}

	private UIScreen MakeScreen(Guid document)
	{
		if ((mInstantiate == null) || (document == Guid()))
			return null;
		let view = mInstantiate(document);
		if (view == null)
			return null;
		if (let screen = view as UIScreen)
			return screen;
		// Not a screen: one is made around it, taking the view's reference.
		let wrapper = new UIScreen();
		wrapper.AddView(view);
		return wrapper;
	}
}
