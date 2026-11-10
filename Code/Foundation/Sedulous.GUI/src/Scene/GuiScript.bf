using System;
using Sedulous.Core;
using Sedulous.Script;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The GUI's script surface. There is no separate UI-script layer: the widgets and their
// [GuiProperty] properties are marked [Scriptable], so the script walker reaches the node tree as
// it reaches the engine, and markup creates the same element types by tag (ElementTypes). A script
// holds a node weakly, through its GUI's element table (Node.TakeScriptWeak): a handle kept past
// its node reads as gone. What lives here is what a handler is given (GuiEvent) and the node verbs
// that take a script's functions. The `Gui` facade, the script service a host installs, is
// Scene/GuiFacade.bf.

/// What a script handler (`node.On(name, fn)`) is given: the event's data, positions in the GUI's
/// own units (`X`, `Y` from the root, `LocalX`, `LocalY` from the node the handler is on). A handler
/// returning true takes the event: it goes no further on its route. Counted, so a script that keeps
/// one keeps it alive; the GUI lets go of its own once the handler returns. Its text is its own
/// copy, as a script may keep the event past the one it was made from.
[Scriptable]
class GuiEvent : RefCounted, IScriptCounted
{
	private String mType = new .() ~ delete _;
	private String mPhase = new .() ~ delete _;
	private String mId = new .() ~ delete _;
	private String mPointer = new .() ~ delete _;
	private String mText = new .() ~ delete _;
	private String mDragType = new .() ~ delete _;
	private String mEffect = new .() ~ delete _;

	/// The name it was listened for: "click", "mousedown", "keydown", ...
	[Scriptable]
	public StringView Type { get => mType; set => mType.Set(value); }
	/// "capture", "target" or "bubble".
	[Scriptable]
	public StringView Phase { get => mPhase; set => mPhase.Set(value); }
	/// The id of the widget it is for (empty: none).
	[Scriptable]
	public StringView Id { get => mId; set => mId.Set(value); }
	/// "mouse" or "touch", for pointer events.
	[Scriptable]
	public StringView Pointer { get => mPointer; set => mPointer.Set(value); }
	[Scriptable]
	public float X = 0.0f;
	[Scriptable]
	public float Y = 0.0f;
	[Scriptable]
	public float LocalX = 0.0f;
	[Scriptable]
	public float LocalY = 0.0f;
	/// 0 left, 1 right, 2 middle, 3 and 4 the extra buttons.
	[Scriptable]
	public int32 Button = 0;
	[Scriptable]
	public int32 ClickCount = 0;
	/// A KeyCode value, for keys.
	[Scriptable]
	public int32 Key = 0;
	/// Shift 1, ctrl 2, alt 4, super 8.
	[Scriptable]
	public int32 Modifiers = 0;
	/// Typed text; a link's id; a named event's detail; the property or @keyframes a
	/// transitionend or animationend is of; a popup's "open" or why it closed.
	[Scriptable]
	public StringView Text { get => mText; set => mText.Set(value); }
	/// The wheel; a gesture's translation since the last event.
	[Scriptable]
	public float DeltaX = 0.0f;
	[Scriptable]
	public float DeltaY = 0.0f;
	// A gesture, X and Y its fingers' middle: totals since it began, and this event's change.
	[Scriptable]
	public float Scale = 1.0f;
	/// Radians, clockwise.
	[Scriptable]
	public float Rotation = 0.0f;
	[Scriptable]
	public float TranslationX = 0.0f;
	[Scriptable]
	public float TranslationY = 0.0f;
	[Scriptable]
	public float ScaleDelta = 1.0f;
	[Scriptable]
	public float RotationDelta = 0.0f;
	/// A drag's payload type (its value as Text, its place as Index).
	[Scriptable]
	public StringView DragType { get => mDragType; set => mDragType.Set(value); }
	/// A drag's effect: "none", "copy", "move" or "link".
	[Scriptable]
	public StringView Effect { get => mEffect; set => mEffect.Set(value); }
	/// The tab for `tabclose`; the row for `activate`, and for a pointer event over a row.
	[Scriptable]
	public int32 Index = -1;
	/// The seconds a transitionend's or animationend's motion ran.
	[Scriptable]
	public float Elapsed = 0.0f;

	/// Constructible: a type a script can make is one it can be handed.
	[Scriptable]
	public this()
	{
	}
}

/// What GuiScript.bf keeps out of the public surface: an event as a handler sees it, and a
/// script's result as a binding's value.
internal static class GuiScriptDetail
{
	private static StringView[4] sEffectNames = .("none", "copy", "move", "link");

	/// An event as a script handler sees it, listened for as `name`: positions in the GUI's units
	/// (from device pixels through the root's display scale). The caller holds its one reference.
	public static GuiEvent EventOf(Event e, StringView name)
	{
		let result = new GuiEvent();
		result.Type = name;
		if (let target = e.Target as UIWidget)
			result.Id = target.Id;
		result.Phase = (e.Phase == .Capture) ? "capture" : ((e.Phase == .Target) ? "target" : "bubble");
		switch (e.Type)
		{
		case .MouseDown, .MouseUp, .MouseMove, .MouseClick, .MouseEnter, .MouseLeave, .PointerCancel, .ContextMenu:
			if (let mouse = e as MouseEvent)
			{
				// Over an item view's row: which (a context menu for it).
				for (var n = e.Target; n != null; n = n.Parent)
				{
					if (let row = n as ItemRow)
					{
						result.Index = row.ItemIndex;
						break;
					}
				}
				Place(result, e, mouse.Position);
				result.Pointer = (mouse.Pointer == .Touch) ? "touch" : "mouse";
				result.Button = (int32)mouse.Button;
				result.ClickCount = (int32)mouse.ClickCount;
				result.Modifiers = (int32)mouse.Modifiers;
			}
		case .MouseWheel:
			if (let wheel = e as WheelEvent)
			{
				Place(result, e, wheel.Position);
				result.DeltaX = wheel.Delta.X;
				result.DeltaY = wheel.Delta.Y;
			}
		case .GestureStart, .GestureChange, .GestureEnd, .GestureCancel:
			if (let gesture = e as GestureEvent)
			{
				Place(result, e, gesture.Focus);
				result.Pointer = (gesture.Pointer == .Touch) ? "touch" : "mouse";
				result.Scale = gesture.Scale;
				result.Rotation = gesture.Rotation;
				result.TranslationX = gesture.Translation.X;
				result.TranslationY = gesture.Translation.Y;
				result.ScaleDelta = gesture.ScaleDelta;
				result.RotationDelta = gesture.RotationDelta;
				result.DeltaX = gesture.TranslationDelta.X;
				result.DeltaY = gesture.TranslationDelta.Y;
			}
		case .KeyDown, .KeyUp:
			if (let key = e as KeyEvent)
			{
				result.Key = (int32)key.KeyCode;
				result.Modifiers = (int32)key.Modifiers;
			}
		case .TextInput:
			if (let input = e as TextInputEvent)
				result.Text = input.Text;
		case .Link:
			if (let link = e as LinkEvent)
				result.Text = link.Link; // the link's id
		case .Composition:
			if (let composition = e as CompositionEvent)
				result.Text = composition.Text;
		case .Toggle: // "open", or why it closed
			if (let toggle = e as ToggleEvent)
				result.Text = toggle.Open ? StringView("open") : PopupCloseReasonName(toggle.Reason);
		case .TabClose:
			if (let tab = e as TabEvent)
				result.Index = tab.Index;
		case .DragStart, .DragEnd, .DragEnter, .DragOver, .DragLeave, .Drop, .DragQuery:
			if (let drag = e as DragEvent)
			{
				Place(result, e, drag.Position); // the root's space: as a pointer's
				result.Effect = sEffectNames[(int)drag.Effect];
				if (drag.Payload != null)
				{
					result.DragType = drag.Payload.Type;
					result.Text = IsText(drag.Payload.Value) ? TextOf(drag.Payload.Value) : (StringView)drag.Payload.Label;
				}
				result.Index = drag.Place;
				result.Modifiers = (int32)drag.Modifiers;
			}
		case .ItemActivate:
			if (let item = e as ItemEvent)
				result.Index = item.Item;
		case .Named:
			if (let named = e as NamedEvent)
				result.Text = named.Detail;
		case .TransitionEnd, .AnimationEnd:
			if (let motion = e as MotionEndEvent)
			{
				result.Text = motion.Name;
				result.Elapsed = motion.Elapsed;
			}
		default:
		}
		return result;
	}

	/// The positions of `world` (device pixels): from the root of the node the handler is on, and
	/// from that node.
	private static void Place(GuiEvent result, Event e, Float2 world)
	{
		let current = e.CurrentTarget;
		if (current == null)
			return;
		let inRoot = current.RootNode.ConvertToNodeSpace(world);
		let local = current.ConvertToNodeSpace(world);
		result.X = inRoot.X;
		result.Y = inRoot.Y;
		result.LocalX = local.X;
		result.LocalY = local.Y;
	}

	/// A script's result as a value a binding sets a property from: text as its own copy, a number,
	/// a boolean or a colour; empty for anything else (nil, a handle). The caller disposes it.
	public static System.Variant VariantOf(ScriptValue value)
	{
		switch (value.Kind)
		{
		case .Bool: return System.Variant.Create(value.AsBool);
		case .Int: return System.Variant.Create(value.AsInt);
		case .Float: return System.Variant.Create(value.AsFloat);
		case .String: return TextVariant(value.AsString);
		case .Color: return System.Variant.Create(value.AsColor);
		default: return default;
		}
	}

	/// Calls a script's handler or expression with `args`: false when it is dead or the call
	/// failed, `result` then untouched.
	public static bool Call(ScriptDelegate handler, Span<ScriptValue> args, ref ScriptValue result)
	{
		return handler.IsAlive && handler.Invoke(args, ref result);
	}
}

// The node verbs that take a script's functions, the popup verbs and the tree as handles, on Node
// beside the reflection.
extension Node
{
	/// The parent, or null for a root or a detached node: `Parent` to a script.
	[Scriptable, ScriptName("Parent")]
	public Node ParentElement() => Parent;

	/// The child at `index` (null past the end): `ChildAt` to a script.
	[Scriptable, ScriptName("ChildAt")]
	public Node ChildElement(int32 index) => (index >= 0) ? GetChildAt(index) : null;

	/// Calls `handler` on each event named `eventName` (click, mousedown, mouseup, mouseenter,
	/// mouseleave, mousemove, wheel, keydown, keyup, textinput, focus, blur, and the rest of the
	/// core's), or of a name a library sends (SendNamedEvent: a screen's `screenenter`). The
	/// handler is given the event's data, and takes the event by returning true. A token for Off
	/// (0 for an empty name). OWNERSHIP of `handler` transfers: the listener holds it (and with it
	/// the script function), the script holds the node only weakly, so neither keeps the other
	/// alive.
	[Scriptable, ScriptCallback("bool EventHandler(GuiEvent@ e)")]
	public int32 On(StringView eventName, ScriptDelegate handler)
	{
		if ((handler == null) || eventName.IsEmpty)
		{
			delete handler;
			return 0;
		}
		// A name the core does not know is one a library sends (a gamekit screen's `screenenter`).
		EventType type;
		let named = !EventTypeNamed(eventName, out type);
		if (named)
			type = .Named;
		let name = new String(eventName);
		return (int32)AddEventListener(type, new [=handler, =named, =name] (e) =>
			{
				if (named && (((NamedEvent)e).Name != name))
					return;
				let scriptEvent = GuiScriptDetail.EventOf(e, name);
				defer scriptEvent.ReleaseRef();
				var args = ScriptValue[1](.FromCounted(scriptEvent));
				var result = ScriptValue.Nil;
				if (GuiScriptDetail.Call(handler, args, ref result) && (result.Kind == .Bool) && result.AsBool)
					e.Handled = true;
			} ~ { delete handler; delete name; });
	}

	/// Opens `content` (a node) as a popup below this node: closed by a press outside it or Escape,
	/// focus going into it and back, and back where it stood once closed, to open again. Whether it
	/// opened. `Popup` to a script.
	[Scriptable, ScriptName("Popup")]
	public bool OpenPopupScript(Node content)
	{
		let dispatcher = EventDispatcher;
		if ((content == null) || (content == this) || (dispatcher == null))
			return false;
		content.Displayed = true;
		let options = new PopupOptions();
		options.Anchor = this;
		options.Placement.Side = .Below;
		options.Placement.Align = .Start;
		options.Placement.Gap = 0.0f;
		options.Placement.Shrink = true;
		options.TakesFocus = true;
		options.FitContent = true;
		options.ReturnHome = true; // a script's popup: back where it stood, to open again
		dispatcher.OpenPopup(this, content, options);
		return dispatcher.IsPopupOpen(content);
	}

	/// Closes this node where it is open as a popup (a script's popup, menu or window); false when
	/// it is not one. `ClosePopup` to a script.
	[Scriptable, ScriptName("ClosePopup")]
	public bool ClosePopupScript()
	{
		let dispatcher = EventDispatcher;
		return (dispatcher != null) && dispatcher.IsPopupOpen(this) && dispatcher.ClosePopup(this);
	}

	/// Binds `property` to the text `expression` returns, run again whenever what it read changed
	/// (the GUI's data, widget properties). False when no such property. OWNERSHIP of `expression`
	/// transfers: the node holds it, as it holds an event handler; a failed call sets nothing.
	/// `Bind` to a script.
	[Scriptable, ScriptName("Bind"), ScriptCallback("string TextExpression()")]
	public bool BindScript(StringView property, ScriptDelegate expression) => BindScriptExpression(property, expression);

	/// Bind for an expression of a number. `BindNumber` to a script.
	[Scriptable, ScriptName("BindNumber"), ScriptCallback("double NumberExpression()")]
	public bool BindNumberScript(StringView property, ScriptDelegate expression) => BindScriptExpression(property, expression);

	/// Bind for an expression of a boolean. `BindBool` to a script.
	[Scriptable, ScriptName("BindBool"), ScriptCallback("bool BoolExpression()")]
	public bool BindBoolScript(StringView property, ScriptDelegate expression) => BindScriptExpression(property, expression);

	/// Binds `property` to this GUI's data value `key` (BindData with its root's model); false
	/// outside a GUI or with no such property. `BindData` to a script.
	[Scriptable, ScriptName("BindData")]
	public bool BindSceneData(StringView property, StringView key)
	{
		let root = SceneRoot;
		return (root != null) && BindData(property, root.Context.Data, key);
	}

	/// Handles command `id` with a script function, in the bubble phase; the function returning
	/// true lets the command go on up the focus path. A token for Off (0 for no handler). OWNERSHIP
	/// of `handler` transfers. `OnCommand` to a script.
	[Scriptable, ScriptName("OnCommand"), ScriptCallback("bool CommandHandler()")]
	public int32 OnCommandScript(StringView id, ScriptDelegate handler)
	{
		if (handler == null)
			return 0;
		return (int32)OnCommand(id, new [=handler] (command) =>
			{
				var result = ScriptValue.Nil;
				let ran = GuiScriptDetail.Call(handler, default, ref result);
				command.Propagate = ran && (result.Kind == .Bool) && result.AsBool;
			} ~ { delete handler; });
	}

	/// What the three Binds share: the expression's result, whatever its shape, as the value.
	private bool BindScriptExpression(StringView property, ScriptDelegate expression)
	{
		if (expression == null)
			return false;
		return BindProperty(property, new [=expression] () =>
			{
				var result = ScriptValue.Nil;
				if (!GuiScriptDetail.Call(expression, default, ref result))
					return default;
				return GuiScriptDetail.VariantOf(result);
			} ~ { delete expression; });
	}
}
