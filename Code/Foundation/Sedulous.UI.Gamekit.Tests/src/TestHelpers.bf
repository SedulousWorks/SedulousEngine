using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.UI.Gamekit.Tests;

/// A context, a root and a screen stack, torn down in the order the references need.
///
/// The stack goes FIRST so it releases its screens while the tree that also holds them is
/// still alive, then the root, whose destructor releases the children, and only then the
/// context those children unregister from on the way out.
class GamekitBed
{
	public UIContext Context = new .();
	public RootView Root = new .();
	public ScreenStack Stack = new .();

	public this()
	{
		Root.ViewportSize = .(800.0f, 600.0f);
		Context.AddRootView(Root);
		Stack.Attach(Root);
	}

	public ~this()
	{
		delete Stack;
		Root.ReleaseRef();
		delete Context;
	}
}

/// A context and a root, for the widgets that need somewhere to be attached but no stack.
class WidgetBed
{
	public UIContext Context = new .();
	public RootView Root = new .();

	public this()
	{
		Root.ViewportSize = .(800.0f, 600.0f);
		Context.AddRootView(Root);
	}

	public ~this()
	{
		Root.ReleaseRef();
		delete Context;
	}
}

/// A screen that counts its lifecycle callbacks, which is the only way to observe hooks that
/// are deliberately no ops on the base class.
class CountingScreen : UIScreen
{
	public int32 Enter = 0;
	public int32 Exit = 0;
	public int32 Shown = 0;
	public int32 Hidden = 0;

	/// BORROWED: the child list owns it.
	public Button FocusTarget = null;

	public override void OnEnter() { Enter++; }
	public override void OnExit() { Exit++; }
	public override void OnShown() { Shown++; }
	public override void OnHidden() { Hidden++; }

	public void AddButton(StringView name)
	{
		FocusTarget = new Button("Go");
		FocusTarget.Name.Set(name);
		AddView(FocusTarget);
	}
}
