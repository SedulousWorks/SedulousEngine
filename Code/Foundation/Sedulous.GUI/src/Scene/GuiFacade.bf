using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// The `Gui` facade: game code's way into the GUI its host gave it, a service the run offers
// (RunServices.Get<GuiFacade>). It finds the root it reads at each call, so a host whose games'
// roots differ by what is running them (an editor's game per tab) gives it a function in place of
// a root.
//
// A value is set by its kind: SetNumber, SetText, SetBool and SetNode, beside GetNumber, GetText
// and GetBool.

/// `Gui`: the game's GUI, its data, its commands and keys, its localized text.
[Scriptable, ServiceFacade("Gui")]
class GuiFacade
{
	/// BORROWED: the root the game builds under, when it does not resolve one per call.
	private SceneRoot mRoot;
	private delegate SceneRoot() mResolve ~ delete _;
	// What the text getters give, valid until the next one (the boundary copies it).
	private String mText = new .() ~ delete _;

	/// The game builds under `root` (borrowed: the host keeps it, and clears it here before it goes).
	public this(SceneRoot root = null)
	{
		mRoot = root;
	}

	/// The root is `resolve`'s answer at each call (null: none). OWNERSHIP of `resolve` transfers.
	public this(delegate SceneRoot() resolve)
	{
		mResolve = resolve;
	}

	/// The root it answers with: `resolve`'s when it has one, else the one set. A host clears it
	/// (null) before its root goes, so a call then finds no GUI.
	public SceneRoot RootNode
	{
		get => (mResolve != null) ? mResolve() : mRoot;
		set => mRoot = value;
	}

	private GUIContext Context => RootNode?.Context;

	/// The game's root, or null when its host gave it none.
	[Scriptable]
	public Node Root() => RootNode;

	// ---- Data ----

	/// The GUI's data value `name` as a number (0 when unset or not a number). A read a binding
	/// follows.
	[Scriptable]
	public double GetNumber(StringView name)
	{
		let data = Context?.Data;
		if (data == null)
			return 0.0;
		var value = ConvertVariant(data.Get(name), typeof(double));
		defer value.Dispose();
		return value.HasValue ? value.Get<double>() : 0.0;
	}

	/// The value as text (empty when unset). A read a binding follows.
	[Scriptable]
	public StringView GetText(StringView name)
	{
		mText.Clear();
		if (let data = Context?.Data)
			FormatVariant(data.Get(name), mText);
		return mText;
	}

	/// The value as a boolean (false when unset or not one). A read a binding follows.
	[Scriptable]
	public bool GetBool(StringView name)
	{
		let data = Context?.Data;
		if (data == null)
			return false;
		var value = ConvertVariant(data.Get(name), typeof(bool));
		defer value.Dispose();
		return value.HasValue && value.Get<bool>();
	}

	/// Sets the GUI's data value `name` (whatever is bound to it follows).
	[Scriptable]
	public void SetNumber(StringView name, double value)
	{
		if (let data = Context?.Data)
			data.Set(name, System.Variant.Create(value));
	}

	[Scriptable]
	public void SetText(StringView name, StringView value)
	{
		if (let data = Context?.Data)
		{
			var text = System.Variant.Create(value);
			data.Set(name, text);
			text.Dispose();
		}
	}

	[Scriptable]
	public void SetBool(StringView name, bool value)
	{
		if (let data = Context?.Data)
			data.Set(name, System.Variant.Create(value));
	}

	/// Sets `name` to a node, held weakly: the value reads as no node once the node is gone. Null
	/// clears it.
	[Scriptable]
	public void SetNode(StringView name, Node node)
	{
		let data = Context?.Data;
		if (data == null)
			return;
		if (node == null)
		{
			data.Set(name, default);
			return;
		}
		var value = System.Variant.Create(node.TakeElementRef());
		data.Set(name, value);
		value.Dispose();
	}

	/// What drives the GUI now: "pointer", "keyboard" or "pad" (the root hears `inputkind` when it
	/// changes). A read a binding follows.
	[Scriptable]
	public StringView InputKind()
	{
		let dispatcher = RootNode?.EventDispatcher;
		return (dispatcher != null) ? InputKindName(dispatcher.ObserveInputKind()) : "pointer";
	}

	/// Moves data value `name` to `to` over `seconds` (GUIContext.AnimateData), running; null when
	/// the host gave no GUI. `Tween` to a script.
	[Scriptable, ScriptName("Tween"), ScriptReturnsReference]
	public Tween TweenData(StringView name, double to, float seconds, StringView easing) => Context?.AnimateData(name, to, seconds, easing);

	/// The same, not yet running: a step for a group.
	[Scriptable, ScriptReturnsReference]
	public Tween CreateTween(StringView name, double to, float seconds, StringView easing) => Context?.CreateDataTween(name, to, seconds, easing);

	// ---- Localized text ----

	/// The GUI's text for `key`: the key itself when no table has it, or with no localization.
	/// `Tr` to a script.
	[Scriptable, ScriptName("Tr")]
	public StringView Translate(StringView key)
	{
		let localization = Context?.Localization;
		return (localization != null) ? localization.Text(key) : key;
	}

	/// The key's plural form for `count`, its `{0}` the count. `TrCount` to a script.
	[Scriptable, ScriptName("TrCount")]
	public StringView TranslateCount(StringView key, int32 count)
	{
		let localization = Context?.Localization;
		if (localization == null)
			return key;
		mText.Clear();
		localization.FormatPlural(key, count, mText, (int64)count);
		return mText;
	}

	/// The GUI's language ("en", "ar-EG"); empty with no localization.
	[Scriptable]
	public StringView Language()
	{
		let localization = Context?.Localization;
		return (localization != null) ? localization.Language : default;
	}

	// ---- Commands and keys ----

	/// Defines command `id` with its label (the id when empty).
	[Scriptable]
	public void DefineCommand(StringView id, StringView label)
	{
		if (let context = Context)
			context.DefineCommand(id).Label = label.IsEmpty ? id : label;
	}

	[Scriptable]
	public void SetCommandEnabled(StringView id, bool enabled)
	{
		if (let context = Context)
			context.DefineCommand(id).Enabled = enabled;
	}

	[Scriptable]
	public void SetCommandChecked(StringView id, bool @checked)
	{
		if (let context = Context)
			context.DefineCommand(id).Checked = @checked;
	}

	/// Why it is disabled, which a control bound to it shows while it is (a tool bar's tooltip).
	[Scriptable]
	public void SetCommandDisabledReason(StringView id, StringView reason)
	{
		if (let context = Context)
			context.DefineCommand(id).DisabledReason = reason;
	}

	[Scriptable]
	public bool IsCommandChecked(StringView id) => Context?.Commands.Find(id)?.Checked ?? false;

	/// Runs `id` along the focus path; true when a handler ran.
	[Scriptable]
	public bool RunCommand(StringView id) => RootNode?.RunCommand(id) ?? false;

	/// Binds `keys` ("ctrl-s", "pad-east", a chord) to `command` where `context` holds (empty:
	/// everywhere); false when they do not parse.
	[Scriptable]
	public bool BindKey(StringView keys, StringView command, StringView context) => Context?.Keymap.Bind(keys, command, context) ?? false;

	/// The next key or pad button, before anything else sees it (a rebinding screen): `handler`
	/// is called with its binding name ("ctrl-s", "pad-north"), or empty when Escape cancelled.
	/// OWNERSHIP of `handler` transfers: the capture holds it until it answers, and deletes it
	/// uncalled when there is no GUI.
	public void CaptureKey(delegate void(StringView keys) handler)
	{
		let dispatcher = RootNode?.EventDispatcher;
		if ((dispatcher == null) || (handler == null))
		{
			delete handler;
			return;
		}
		// Both answers share the handler; whichever comes deletes it, and the other never does.
		let shared = new GuiFacadeDetail.KeyCapture(handler);
		dispatcher.CaptureNextKey(new [=shared] (stroke) =>
			{
				let name = scope String();
				KeystrokeName(stroke, name);
				shared.Deliver(name);
			} ~ shared.ReleaseRef(),
			new [=shared] () => { shared.Deliver(default); } ~ shared.ReleaseRef());
	}

	/// A binding's keys as a menu shows them ("ctrl-s": "Ctrl+S"); empty when they do not parse.
	[Scriptable]
	public StringView KeyText(StringView keys)
	{
		mText.Clear();
		let stroke = ParseKeystroke(keys);
		if (stroke.HasValue)
			KeystrokeText(stroke.Value, mText);
		return mText;
	}
}

static class GuiFacadeDetail
{
	/// A key capture's handler, shared by its two answers (a key, or Escape's cancel): each holds a
	/// reference, and the handler goes with the last.
	public class KeyCapture : RefCounted
	{
		private delegate void(StringView keys) mHandler ~ delete _;

		public this(delegate void(StringView keys) handler)
		{
			mHandler = handler;
			AddRef(); // one for each answer
		}

		public void Deliver(StringView keys)
		{
			mHandler(keys);
		}
	}
}
