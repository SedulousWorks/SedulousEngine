using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.GUI;

namespace Sedulous.Editor.Input;

// What the input map page's grid says of a set's rows beyond what its fields say:
// an action by its name and, closed, its kind and its
// bindings in a line; a binding by its source and, closed, its input; a binding's settings shown
// only for the sources that have them (a dead zone for what is analog, the screen area for touch,
// the four keys for a four-key binding), as the old page laid them out; the kinds and the sources by
// the page's own words; an input's row the capture's. The page's describe hook, a pure function of
// the set so its tests need no page. Paths are the fields' own names ("Actions.0.Bindings.1.NegX").

static class InputMapRows
{
	/// The hint of a row whose value is an input a binding listens for (a key, a button, a stick): the
	/// page's capture editor takes it.
	public const String cInputCodeHint = "inputCode";

	/// What the page's grid says of `set`'s row `path` (the field source over the set), in `info`.
	public static void Describe(ActionSet set, StringView path, PropertyInfo info)
	{
		if (path == "Priority")
		{
			info.Description.Set("When two active sets bind the same input, the higher priority takes it");
			return;
		}
		if (path == "Actions")
		{
			info.DisplayName.Set("Actions");
			info.Description.Set("What the game reads while this set is on; Add adds one to this set");
			return;
		}
		StringView rest = default;
		let a = IndexAfter(path, "Actions.", ref rest);
		if ((a < 0) || (a >= set.Actions.Count))
			return;
		let action = set.Actions[a];
		if (rest.IsEmpty)
		{
			// An action: by its name; closed, its kind and its bindings in a line.
			if (action.Name.IsEmpty)
				info.DisplayName.Set("(unnamed)");
			else
				info.DisplayName.Set(action.Name);
			info.Summary.Clear();
			info.Summary.AppendF("{}: ", InputMapEdit.KindTitle(action.Kind));
			BindingsLine(action, info.Summary);
			return;
		}
		if (rest == "Kind")
		{
			info.Description.Set("What the action reports: pressed or not, one axis, or two");
			for (let choice in info.Choices)
				choice.Name.Set(InputMapEdit.KindTitle((ActionKind)choice.Value));
			return;
		}
		if (rest == "Processors")
		{
			info.DisplayName.Set("Processing");
			info.Summary.Clear();
			info.Summary.AppendF("Sensitivity {:F2}{}", action.Processors.Sensitivity, action.Processors.Snap ? ", snaps on reverse" : "");
			return;
		}
		// When it fires: as soon as pressed, after a hold, on a quick tap or on two (the old page's
		// words for the choices); closed, the choice and its time in a line.
		if (rest == "Interaction")
		{
			let kind = action.Interaction.Kind;
			info.DisplayName.Set("Interaction");
			info.Description.Set("When it fires: as soon as pressed, after a hold, on a quick tap, or on two");
			info.Summary.Set(InputMapEdit.InteractionTitle(kind));
			if (kind != .None)
				info.Summary.AppendF(" {} {:F2}s", (kind == .Hold) ? "for" : "within", action.Interaction.Seconds);
			return;
		}
		if (rest == "Interaction.Kind")
		{
			info.DisplayName.Set("Kind");
			for (let choice in info.Choices)
				choice.Name.Set(InputMapEdit.InteractionTitle((InteractionKind)choice.Value));
			return;
		}
		if (rest == "Interaction.Seconds")
		{
			// Hold: held for this long; a tap: released, or pressed again, within it.
			info.DisplayName.Set((action.Interaction.Kind == .Hold) ? "Hold For" : "Within");
			info.Description.Set("Seconds");
			Range(info, 0.0, 10.0, 0.05);
			info.Visible = action.Interaction.Kind != .None;
			return;
		}
		if (rest == "Bindings")
		{
			info.DisplayName.Set("Bindings");
			info.Description.Set("The inputs that drive it; Add binds another");
			return;
		}
		if (rest.StartsWith("Processors."))
		{
			DescribeProcessorField(rest.Substring("Processors.".Length), info);
			return;
		}
		StringView field = default;
		let b = IndexAfter(rest, "Bindings.", ref field);
		if ((b < 0) || (b >= action.Bindings.Count))
			return;
		let binding = action.Bindings[b];
		if (field.IsEmpty)
		{
			// A binding: by its source; closed, its input, and when the action's kind does not take
			// its source (a map the game cannot read), that said on its own row.
			info.DisplayName.Set(InputMapEdit.SourceTitle(binding.Source));
			info.Summary.Clear();
			BindingNames.DescribeBinding(binding, info.Summary);
			if (!InputMapEdit.SourceFitsKind(action.Kind, binding.Source))
				info.Summary.AppendF("  (not taken by a {} action)", InputMapEdit.KindTitle(action.Kind));
			return;
		}
		DescribeBindingField(binding, field, info);
		if (field == "Source")
		{
			// Only the sources this action's kind takes (and the one it has).
			let valid = scope List<BindingSource>();
			BindingNames.ValidSources(action.Kind, valid);
			for (int i = info.Choices.Count - 1; i >= 0; i--)
			{
				let value = (BindingSource)info.Choices[i].Value;
				if (!valid.Contains(value) && (value != binding.Source))
				{
					delete info.Choices[i];
					info.Choices.RemoveAt(i);
				}
			}
		}
	}

	/// The leading index of `path` after `prefix` ("Actions.2.Bindings" after "Actions.": 2), and
	/// what follows it in `rest` ("Bindings"); -1 when it does not begin so.
	public static int IndexAfter(StringView path, StringView prefix, ref StringView rest)
	{
		if (!path.StartsWith(prefix))
			return -1;
		let tail = path.Substring(prefix.Length);
		int digits = 0;
		while ((digits < tail.Length) && tail[digits].IsDigit)
			digits++;
		if (digits == 0)
			return -1;
		rest = ((digits < tail.Length) && (tail[digits] == '.')) ? tail.Substring(digits + 1) : default;
		if (int.Parse(tail.Substring(0, digits)) case .Ok(let index))
			return index;
		return -1;
	}

	/// An action's bindings in a line ("W, Space"), appended.
	public static void BindingsLine(InputAction action, String outLine)
	{
		if (action.Bindings.IsEmpty)
		{
			outLine.Append("no binding yet");
			return;
		}
		for (int i < action.Bindings.Count)
		{
			if (i > 0)
				outLine.Append(", ");
			BindingNames.DescribeBinding(action.Bindings[i], outLine);
		}
	}

	// A binding's setting: whether its source has it, and how it is named and bounded.
	private static void DescribeBindingField(Binding binding, StringView field, PropertyInfo info)
	{
		let source = binding.Source;
		let composite = source == .Composite2D;
		let deadZone = (source == .MouseAxis) || (source == .GamepadAxis) || (source == .GamepadStick) || (source == .TouchStick);
		let invert = (source == .MouseAxis) || (source == .MouseDelta) || (source == .GamepadAxis) || (source == .GamepadStick) ||
			(source == .TouchStick) || composite;
		let gamepad = (source == .GamepadButton) || (source == .GamepadAxis) || (source == .GamepadStick);
		let touch = (source == .TouchButton) || (source == .TouchStick);
		if (field == "Source")
		{
			info.DisplayName.Set("Source");
			for (let choice in info.Choices)
				choice.Name.Set(InputMapEdit.SourceTitle((BindingSource)choice.Value));
		}
		else if (field == "Code")
		{
			info.DisplayName.Set("Input");
			info.Hint.Set(cInputCodeHint);
			info.Visible = !composite;
		}
		else if ((field == "NegX") || (field == "PosX") || (field == "NegY") || (field == "PosY"))
		{
			info.DisplayName.Set((field == "NegX") ? "Left" : ((field == "PosX") ? "Right" : ((field == "NegY") ? "Down" : "Up")));
			info.Hint.Set(cInputCodeHint);
			info.Visible = composite;
		}
		else if (field == "Modifiers")
		{
			info.Visible = false; // a chord's modifiers: not authored on this page
		}
		else if (field == "Device")
		{
			// A choice, as the old page had it: Any, or a pad by its number from 1 (the device its
			// index from 0, -1 for any).
			info.DisplayName.Set("Gamepad");
			info.Description.Set("Which connected gamepad: any, or one by its number");
			info.Kind = .Enum;
			ClearAndDeleteItems!(info.Choices);
			info.AddChoice("Any", -1);
			for (int64 pad < 4)
				info.AddChoice(scope String()..AppendF("{}", pad + 1), pad);
			info.Visible = gamepad;
		}
		else if (field == "DeadZone")
		{
			info.Description.Set("Movement smaller than this reads as none");
			Range(info, 0.0, 1.0, 0.01);
			info.Hint.Set("slider");
			info.Visible = deadZone;
		}
		else if (field == "Scale")
		{
			info.DisplayName.Set("Scale");
			info.Description.Set("Multiplies what the input reports (negative flips it)");
			Range(info, -100.0, 100.0, 0.05);
			info.Visible = source != .TouchButton;
		}
		else if (field == "Invert")
		{
			info.DisplayName.Set("Invert");
			info.Description.Set("Flip the direction");
			info.Visible = invert;
		}
		else if (field == "Normalize")
		{
			info.DisplayName.Set("Normalize");
			info.Description.Set("Diagonals as long as straight moves");
			info.Visible = composite;
		}
		else if ((field == "RegionX") || (field == "RegionY") || (field == "RegionW") || (field == "RegionH"))
		{
			info.DisplayName.Set((field == "RegionX") ? "Area X" : ((field == "RegionY") ? "Area Y" : ((field == "RegionW") ? "Area Width" : "Area Height")));
			info.Description.Set("A fraction of the screen, 0 to 1");
			Range(info, 0.0, 1.0, 0.01);
			info.Visible = touch;
		}
		else if (field == "StickRadius")
		{
			info.DisplayName.Set("Radius");
			// Normalised as the regions are: the runtime divides the touch's offset from its anchor, a
			// fraction of the screen, by it (ActionRuntime).
			info.Description.Set("How far the stick deflects for a full reading: a fraction of the screen, 0 to 1");
			Range(info, 0.0, 1.0, 0.01);
			info.Visible = source == .TouchStick;
		}
	}

	// An action's processing, named and bounded as the old page had it.
	private static void DescribeProcessorField(StringView field, PropertyInfo info)
	{
		if (field == "Sensitivity")
		{
			info.Description.Set("Above 0, a key-driven axis ramps toward its value at this rate a second");
			Range(info, 0.0, 100.0, 0.05);
		}
		else if (field == "Gravity")
		{
			info.Description.Set("Above 0, the rate a second it returns to rest once released");
			Range(info, 0.0, 100.0, 0.05);
		}
		else if (field == "ResponseExponent")
		{
			info.DisplayName.Set("Curve");
			info.Description.Set("Shapes an analog input: the value to this power (1 is straight)");
			Range(info, 0.1, 5.0, 0.05);
		}
		else if (field == "Snap")
		{
			info.DisplayName.Set("Snap on Reverse");
			info.Description.Set("Jump to zero first when the direction flips");
		}
		else if (field == "TimeScale")
		{
			info.DisplayName.Set("Scale with Time");
			info.Description.Set("Multiply by the game's time scale, once there is one");
		}
	}

	private static void Range(PropertyInfo info, double min, double max, double step)
	{
		info.HasRange = true;
		info.Min = min;
		info.Max = max;
		info.Step = step;
	}
}
