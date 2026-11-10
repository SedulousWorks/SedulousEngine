using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.GUI;
using Sedulous.GUI.Gamekit.ScriptSurface;

namespace Sedulous.Integration.GuiScript;

/// A GUI for one script: its root, 400 by 300, installed as the script's
/// `Gui.Root()`, the script compiled against the gamekit's surface (the GUI's, and the screens').
class GuiBed
{
	public SceneRoot Root;
	public GuiFacade Gui = new .() ~ delete _;
	// What the runtime is bound to: it points into the surface, so the surface outlives it.
	public Sedulous.Script.ScriptSurface Surface = new .() ~ delete _;
	public AngelScriptRuntime Vm = new .();
	public String Module = new .() ~ delete _;

	public this(StringView module, StringView source)
	{
		RegisterGuiElements();
		RegisterGamekitElements();
		let context = new GUIContext();
		Root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		Root.Size = .(400.0f, 300.0f);
		Gui.RootNode = Root;
		GamekitScriptSurface.Populate(Surface);
		Vm.Bind(Surface);
		Vm.SetService(Gui);
		Module.Set(module);
		let ok = Vm.Compile(module, scope $"{module}.as", source);
		Dump();
		Test.Assert(ok && Vm.Problems.IsEmpty, "compiled, with nothing to say");
	}

	public ~this()
	{
		// The runtime first: it holds the script's handles and borrows the facade and the surface.
		Vm.DiscardModule(Module);
		delete Vm;
		Vm = null;
		Gui.RootNode = null;
		Root?.ReleaseRef();
	}

	public void Dump()
	{
		for (let p in Vm.Problems)
			Console.WriteLine("  {}", p);
	}

	/// Calls `decl` in the script, which must run.
	public ScriptValue Call(StringView decl)
	{
		var r = ScriptValue.Nil;
		let ok = Vm.Call(Module, decl, default, ref r);
		Dump();
		Test.Assert(ok, scope $"{decl} ran");
		return r;
	}

	/// `decl` must fail with the gone-object error; the error is
	/// cleared, so a later check of the problems sees only what came after.
	public void Refused(StringView decl)
	{
		var r = ScriptValue.Nil;
		Test.Assert(!Vm.Call(Module, decl, default, ref r), scope $"{decl} fails");
		Test.Assert(!Vm.Problems.IsEmpty && Vm.Problems.Back.Contains(ScriptErrors.ObjectGone), scope $"{decl}: the object is gone");
		ClearAndDeleteItems!(Vm.Problems);
	}

	public EventDispatcher D => Root.EventDispatcher;

	/// A press and its release at `at` (the root's space).
	public void Click(Float2 at)
	{
		D.InjectMouseDown(at, .Left);
		D.InjectMouseUp(at, .Left);
	}

	/// The GUI's clock `seconds` on (its update: deferred removals, tweens, bindings).
	public void Update(double seconds = 0.0) => Root.Context.Update(Seconds(seconds));

	public static TimeSpan Seconds(double s) => TimeSpan((int64)(s * (double)TimeSpan.TicksPerSecond));

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	public static bool Near(double a, double b, double epsilon = 1.2e-5) =>
		Math.Abs(a - b) < epsilon * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));
}
