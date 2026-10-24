using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.Gamekit.Tests;

/// What the gamekit tests share.
static class GamekitFixtures
{
	/// A root of a GUI of its own, held by the caller: it releases it, and the GUI goes with it.
	public static SceneRoot NewScene()
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		return root;
	}

	/// `styles` styling by `css`.
	public static void UseSheet(StyleManager styles, StringView css)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		styles.StyleSheet = sheet;
	}

	public static TimeSpan Seconds(double s) => TimeSpan((int64)(s * (double)TimeSpan.TicksPerSecond));

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	public static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));
}

/// A root (400 x 300) holding a stack of its size. The root, the stack and their tree go with it.
class Bed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public ScreenStack Stack ~ _.ReleaseRef();

	public this()
	{
		Root = GamekitFixtures.NewScene();
		Root.Size = .(400.0f, 300.0f);
		Stack = new ScreenStack();
		Stack.Size = .(400.0f, 300.0f);
		Root.AddChild(Stack);
	}

	public EventDispatcher D => Root.EventDispatcher;

	public void Layout()
	{
		Root.UpdateLayout();
	}

	public void Frame()
	{
		Root.Context.Update(TimeSpan(0));
	}

	public void Escape()
	{
		D.InjectKeyDown((uint32)KeyCode.Escape);
	}

	/// A screen with a button `id` 80 x 30 at (`x`, 10), held by the caller (it releases it).
	public Screen MakeScreen(StringView id, float x = 10.0f)
	{
		let screen = new Screen();
		let button = new Button();
		button.Id = id;
		button.Position = .(x, 10.0f);
		button.Size = .(80.0f, 30.0f);
		screen.AddChild(button);
		button.ReleaseRef(); // the screen's keeps it
		return screen;
	}

	/// The focused widget's id ("" with none).
	public StringView Focused
	{
		get
		{
			let focus = D.FocusNode as UIWidget;
			return (focus != null) ? focus.Id : "";
		}
	}
}

/// A stack under a sheet: screens enter from transparent and leave to it, over 0.4 s.
class StyledBed : Bed
{
	public StyleManager Styles = new .() ~ delete _;

	public this() : base()
	{
		GamekitFixtures.UseSheet(Styles, "screen { opacity: 1; transition: opacity 0.4s linear; }" +
			"screen:entering { opacity: 0; } screen:leaving { opacity: 0; }");
		Styles.ApplyTree(Root);
	}

	/// One frame as a host runs it: the GUI's update, then the style pass.
	public void Frame(double seconds)
	{
		Root.Context.Update(GamekitFixtures.Seconds(seconds));
		Styles.ApplyTree(Root);
	}
}

/// Records the named events a node is told, as "name" or "name:detail".
class Log
{
	public List<String> Heard = new .() ~ DeleteContainerAndItems!(_);

	public void Watch(Node node, StringView name)
	{
		node.AddNamedListener(name, new (e) =>
			{
				let named = (NamedEvent)e;
				let line = new String(named.Name);
				if (named.Detail.Length != 0)
				{
					line.Append(":");
					line.Append(named.Detail);
				}
				Heard.Add(line);
			});
	}

	public void Watch(Node node, StringView first, StringView second)
	{
		Watch(node, first);
		Watch(node, second);
	}

	public void Watch(Node node, StringView first, StringView second, StringView third)
	{
		Watch(node, first);
		Watch(node, second);
		Watch(node, third);
	}
}

/// Documents by path, for PushDocument.
class Documents : IResourceProvider
{
	public override ImageData LoadImage(StringView path) => null;

	public override bool LoadText(StringView path, String outText)
	{
		if (path != "pause.xml")
			return false;
		outText.Append("<Screen pauses=\"true\" covers=\"true\"><Button id=\"resume\"/><Label id=\"who\" text=\"{{name}}\"/></Screen>");
		return true;
	}

	public override SVGDocument LoadSvg(StringView path) => null;
}
