using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;
using Sedulous.Engine.UI.Script;

namespace Sedulous.Engine.UI.Script.Tests;

/// A context, a root, a stack, and the Ui facade over them with a document instantiator
/// the test fills: what the application wires, without one. Transitions default to None,
/// so structural changes run inline on an idle context.
class UiScriptBed
{
	public UIContext Context = new .();
	public RootView Root = new .();
	public ScreenStack Stack = new .();
	public UiScript Ui = new .();
	/// The document the instantiator answers, by id; a test builds it.
	public delegate View() Document = null ~ delete _;

	public this()
	{
		Root.ViewportSize = .(800.0f, 600.0f);
		Context.AddRootView(Root);
		Stack.Attach(Root);
		Ui.Attach(Stack, new (id) => (Document != null) ? Document() : null);
	}

	public ~this()
	{
		delete Ui;
		delete Stack;
		// The table's references go before the bed's last one, so the root is freed here,
		// under the context it registered with, and not by a later sweep.
		UiHandles.Clear();
		Root.ReleaseRef();
		delete Context;
	}

	/// A screen holding a named label, button, bar and text box, plus a nested group with
	/// a second label of the SAME name deeper down.
	public static UIScreen Screen(StringView name = "screen")
	{
		let screen = new UIScreen();
		screen.Name.Set(name);
		let label = new Label();
		label.Name.Set("title");
		label.SetText("Hello");
		screen.AddView(label);
		let button = new Button("Retry");
		button.Name.Set("retry");
		screen.AddView(button);
		let bar = new ProgressBar();
		bar.Name.Set("health");
		bar.Value.Value = 0.5f;
		screen.AddView(bar);
		let edit = new EditText();
		edit.Name.Set("name");
		edit.SetText("Ada");
		screen.AddView(edit);
		let panel = new ViewGroup();
		panel.Name.Set("panel");
		let inner = new Label();
		inner.Name.Set("title");
		inner.SetText("Inner");
		panel.AddView(inner);
		let deep = new Label();
		deep.Name.Set("deep");
		deep.SetText("Deep");
		panel.AddView(deep);
		screen.AddView(panel);
		return screen;
	}
}
