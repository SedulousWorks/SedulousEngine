using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// Button prompts. A `prompt` element names an action (and, if it likes, its set) of the game's
// InputMap and shows the control that does it for the input kind in use: a pad's button while a
// pad plays, a key or a mouse button under the keyboard or the pointer, else any binding the action
// has, else nothing. It reads the map the game runs, after the player's rebinding, through the
// host's InputPrompts (an ActionRuntime: its map and its enabled sets, the highest priority first),
// labels the binding with Sedulous.Input's BindingNames, and follows the input kind and the
// bindings as they change. Every reference names an action's first binding whatever the device;
// this one asks the device.
//
// No glyph table in code: a prompt shows its binding to the sheet as attributes, `binding` (the
// label's words, lower case, joined by dashes: `pad-south`, `space`, `mouse-left`) and `kind`
// (`pad`, `keyboard`, `pointer`), so a game's sheet draws its own glyphs
// (`prompt[binding="pad-south"] { background-image: url(...) }`), the text label its fallback.

static
{
	/// The key a GUI's InputPrompts is found under (GUIContext.GetService).
	public const String cInputPromptsService = "gamekit.input-prompts";

	/// A binding as a sheet names it: its label's words, lower case, joined by dashes ("Pad South":
	/// `pad-south`), appended to `outText`.
	public static void BindingToken(Sedulous.Input.Binding binding, String outText)
	{
		let label = scope String();
		Sedulous.Input.BindingNames.DescribeBinding(binding, label);
		for (let c in label.RawChars)
			outText.Append((c == ' ') ? '-' : (((c >= 'A') && (c <= 'Z')) ? (char8)((uint8)c - (uint8)'A' + (uint8)'a') : c));
	}
}

/// What a GUI's prompts read the game's bindings through: the host's ActionRuntime (its map after
/// the player's rebinding, its enabled sets). The host installs it on the GUI and tells it when the
/// bindings change (a rebinding saved). The runtime is borrowed.
class InputPrompts
{
	private Sedulous.Input.ActionRuntime mRuntime = null;
	private Observable mChanged = new .() ~ delete _;

	public void SetRuntime(Sedulous.Input.ActionRuntime runtime)
	{
		mRuntime = runtime;
		mChanged.Notify();
	}

	/// The runtime's map or enabled sets changed: every prompt reads them again.
	public void NotifyBindingsChanged()
	{
		mChanged.Notify();
	}

	/// Makes it the one `gui`'s prompts read (null: none). It must outlive that.
	public void Install(GUIContext gui)
	{
		gui.SetService(cInputPromptsService, Internal.UnsafeCastToPtr(this));
	}

	public static void Uninstall(GUIContext gui)
	{
		gui.SetService(cInputPromptsService, null);
	}

	/// The binding to show for `action`, in `set`, for input of `kind`: Sedulous.Input's
	/// ShownBinding.For, the one a script's `Input.Describe` names too. A read a binding follows.
	public Sedulous.Input.Binding? Find(StringView action, StringView set, Sedulous.GUI.InputKind kind)
	{
		mChanged.Track();
		if (mRuntime == null)
			return null;
		return Sedulous.Input.ShownBinding.For(mRuntime, action, set, ToInputKind(kind));
	}

	/// The GUI's input kind as Sedulous.Input names it (the reverse of GUI.Shell's bridge, which
	/// passes the tracker's kind to the GUI).
	public static Sedulous.Input.InputKind ToInputKind(Sedulous.GUI.InputKind kind)
	{
		switch (kind)
		{
		case .Keyboard: return .Keyboard;
		case .Pad: return .Pad;
		case .Pointer: break;
		}
		return .Pointer;
	}
}

/// Shows the control that does an action, for the input kind in use.
[GuiReflect(true), Scriptable]
class Prompt : Label
{
	private String mAction = new .() ~ delete _;
	private String mSet = new .() ~ delete _;
	private String mBinding = new .() ~ delete _;
	private String mKind = new .() ~ delete _;
	private Observable mInputs = new .() ~ delete _; // its action or set changed

	public this()
	{
		Tag = "prompt";
		Bind(new () => { Refresh(); }); // the GUI it is in, its action, the input kind, the bindings
	}

	/// The action it shows the binding of (markup's and a sheet's `action`).
	[GuiProperty("action"), Scriptable]
	public StringView ActionName
	{
		get => mAction;
		set
		{
			mAction.Set(value);
			mInputs.Notify();
		}
	}

	/// The set it reads the action in (empty: the highest-priority enabled set that has it).
	[GuiProperty("set"), Scriptable]
	public StringView Set
	{
		get => mSet;
		set
		{
			mSet.Set(value);
			mInputs.Notify();
		}
	}

	/// The binding shown, as a sheet names it (`pad-south`): empty when none is shown. What a
	/// sheet's [binding=...] reads (glyphs are the sheet's).
	[GuiProperty("binding"), Scriptable]
	public StringView BindingName
	{
		get => mBinding;
	}

	/// The kind of the binding shown (`pad`, `keyboard`, `pointer`): empty when none is shown. What
	/// a sheet's [kind=...] reads.
	[GuiProperty("kind"), Scriptable]
	public StringView BindingKind
	{
		get => mKind;
	}

	private void Refresh()
	{
		mInputs.Track();
		let root = ObserveSceneRoot();
		Sedulous.Input.Binding? binding = null;
		if (root != null)
		{
			let kind = root.EventDispatcher.ObserveInputKind();
			let service = root.Context.GetService(cInputPromptsService);
			if (service != null)
			{
				let prompts = (InputPrompts)Internal.UnsafeCastToObject(service);
				binding = prompts.Find(mAction, mSet, kind);
			}
		}
		Observer.Untracked(scope [&] () =>
			{
				let token = scope String();
				let kindName = scope String();
				let label = scope String();
				if (binding.HasValue)
				{
					BindingToken(binding.Value, token);
					kindName.Append(Sedulous.Input.ShownBinding.KindOf(binding.Value).Name);
					Sedulous.Input.BindingNames.DescribeBinding(binding.Value, label);
				}
				Text = label;
				if ((token != mBinding) || (kindName != mKind))
				{
					mBinding.Set(token);
					mKind.Set(kindName);
					MarkStyleDirty(false); // a sheet's [binding=...] and [kind=...] read it
				}
			});
	}
}
