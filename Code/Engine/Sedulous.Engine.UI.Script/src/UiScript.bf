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

	/// BORROWED: the tier's stack, over the screen root.
	private ScreenStack mStack = null;
	private Instantiator mInstantiate = null ~ delete _;

	public void Attach(ScreenStack stack, Instantiator instantiate)
	{
		mStack = stack;
		delete mInstantiate;
		mInstantiate = instantiate;
	}

	private ViewGroup RootGroup => (mStack != null) ? mStack.Root : null;

	/// The screen tier's root, as a group handle.
	[Scriptable]
	public UiGroup Root => .(RootGroup);
	/// The top screen on the stack, null when empty.
	[Scriptable]
	public UiScreen Top => .((mStack != null) ? mStack.Top : null);
	[Scriptable]
	public int32 Count => (mStack != null) ? (int32)mStack.Count : 0;

	[Scriptable]
	public UiView Find(StringView name) => UiFinders.FindByName(RootGroup, name);
	[Scriptable]
	public UiLabel FindLabel(StringView name) => UiFinders.FindLabel(RootGroup, name);
	[Scriptable]
	public UiButton FindButton(StringView name) => UiFinders.FindButton(RootGroup, name);
	[Scriptable]
	public UiProgressBar FindProgressBar(StringView name) => UiFinders.FindProgressBar(RootGroup, name);
	[Scriptable]
	public UiTextBox FindTextBox(StringView name) => UiFinders.FindTextBox(RootGroup, name);
	[Scriptable]
	public UiGroup FindGroup(StringView name) => UiFinders.FindGroup(RootGroup, name);

	/// Instantiates the document and pushes it as a screen: the document's own root when
	/// it is one, otherwise wrapped in a fresh screen. Null when nothing could be made.
	[Scriptable]
	public UiScreen Push(Guid document)
	{
		let screen = MakeScreen(document);
		if ((screen == null) || (mStack == null))
		{
			if (screen != null)
				screen.ReleaseRef();
			return .();
		}
		// The stack consumes the reference; the handle takes its own through the table.
		let handle = UiScreen(screen);
		mStack.Push(screen);
		return handle;
	}

	[Scriptable]
	public void Pop()
	{
		if (mStack != null)
			mStack.Pop();
	}

	[Scriptable]
	public UiScreen Replace(Guid document)
	{
		let screen = MakeScreen(document);
		if ((screen == null) || (mStack == null))
		{
			if (screen != null)
				screen.ReleaseRef();
			return .();
		}
		let handle = UiScreen(screen);
		mStack.Replace(screen);
		return handle;
	}

	[Scriptable]
	public void Clear()
	{
		if (mStack != null)
			mStack.Clear();
	}

	/// Pops the top unless it is the last screen; whether it popped.
	[Scriptable]
	public bool Back() => (mStack != null) && mStack.HandleBack();

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
