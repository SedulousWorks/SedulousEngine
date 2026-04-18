namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Maps XML element names to View factories and property setters.
/// Registration-based (not reflection) — explicit and debuggable.
public static class UIRegistry
{
	/// Factory delegate that creates a View instance.
	public typealias ViewFactory = delegate View();

	/// Property setter delegate that sets a property from a string value.
	public typealias PropertySetter = delegate void(View view, StringView value);

	private struct ViewRegistration
	{
		public ViewFactory Factory;
		public Dictionary<String, PropertySetter> Properties;
	}

	private static Dictionary<String, ViewRegistration> sRegistry = new .() ~ Cleanup(ref _);

	private static void Cleanup(ref Dictionary<String, ViewRegistration> registry)
	{
		if(registry == null)
			return;

		for (let kv in registry)
		{
			delete kv.key;
			delete kv.value.Factory;
			if (kv.value.Properties != null)
			{
				for (let pkv in kv.value.Properties)
				{
					delete pkv.key;
					delete pkv.value;
				}
				delete kv.value.Properties;
			}
		}
		delete registry;

		registry = null;
	}

	public static ~this()
	{
		Cleanup(ref sRegistry);
	}

	public static void Clear()
	{
		Cleanup(ref sRegistry);
	}

	/// Register a view type with its XML element name and factory.
	public static void RegisterView(StringView elementName, ViewFactory factory)
	{
		let key = new String(elementName);
		sRegistry[key] = .() { Factory = factory, Properties = new Dictionary<String, PropertySetter>() };
	}

	/// Register a named property setter for a view type.
	public static void RegisterProperty(StringView elementName, StringView propertyName, PropertySetter setter)
	{
		let elemKey = scope String(elementName);
		if (sRegistry.TryGetValue(elemKey, var reg))
		{
			reg.Properties[new String(propertyName)] = setter;
			sRegistry[elemKey] = reg;
		}
	}

	/// Try to create a view for the given element name. Returns null if not registered.
	public static View CreateView(StringView elementName)
	{
		let key = scope String(elementName);
		if (sRegistry.TryGetValue(key, let reg))
			return reg.Factory();
		return null;
	}

	/// Try to set a property on a view from a string value.
	/// Returns true if the property was found and set.
	public static bool SetProperty(StringView elementName, View view, StringView propertyName, StringView value)
	{
		let elemKey = scope String(elementName);
		if (!sRegistry.TryGetValue(elemKey, let reg))
			return false;

		let propKey = scope String(propertyName);
		if (reg.Properties.TryGetValue(propKey, let setter))
		{
			setter(view, value);
			return true;
		}
		return false;
	}

	/// Check if an element name is registered.
	public static bool IsRegistered(StringView elementName)
	{
		let key = scope String(elementName);
		return sRegistry.ContainsKey(key);
	}

	// === Color parsing helper ===

	/// Parse a color from "R,G,B" or "R,G,B,A" (0-255 per channel).
	public static bool ParseColor(StringView val, out Color result)
	{
		result = .White;
		uint8[4] c = .(255, 255, 255, 255);
		int i = 0;
		for (let part in val.Split(','))
		{
			if (i >= 4) break;
			let s = scope String();
			s.Append(part);
			s.Trim();
			if (uint8.Parse(s) case .Ok(let v))
				c[i] = v;
			i++;
		}
		if (i >= 3) { result = Color(c[0], c[1], c[2], c[3]); return true; }
		return false;
	}

	private static bool ParseOrientation(StringView val) => val == "Horizontal";

	private static bool sBuiltinsRegistered = false;

	/// Register all built-in view types with their XML-settable properties.
	/// Safe to call multiple times — no-op after the first call.
	public static void RegisterBuiltins()
	{
		if (sBuiltinsRegistered) return;
		sBuiltinsRegistered = true;

		// === LinearLayout ===
		RegisterView("LinearLayout", new () => new LinearLayout());
		RegisterProperty("LinearLayout", "orientation", new (v, val) => {
			if (let c = v as LinearLayout) c.Orientation = ParseOrientation(val) ? .Horizontal : .Vertical;
		});
		RegisterProperty("LinearLayout", "spacing", new (v, val) => {
			if (let c = v as LinearLayout) if (float.Parse(val) case .Ok(let f)) c.Spacing = f;
		});
		RegisterProperty("LinearLayout", "baselineAligned", new (v, val) => {
			if (let c = v as LinearLayout) c.BaselineAligned = (val == "true");
		});

		// === FrameLayout ===
		RegisterView("FrameLayout", new () => new FrameLayout());

		// === FlowLayout ===
		RegisterView("FlowLayout", new () => new FlowLayout());
		RegisterProperty("FlowLayout", "orientation", new (v, val) => {
			if (let c = v as FlowLayout) c.Orientation = ParseOrientation(val) ? .Horizontal : .Vertical;
		});
		RegisterProperty("FlowLayout", "hSpacing", new (v, val) => {
			if (let c = v as FlowLayout) if (float.Parse(val) case .Ok(let f)) c.HSpacing = f;
		});
		RegisterProperty("FlowLayout", "vSpacing", new (v, val) => {
			if (let c = v as FlowLayout) if (float.Parse(val) case .Ok(let f)) c.VSpacing = f;
		});

		// === GridLayout ===
		RegisterView("GridLayout", new () => new GridLayout());
		RegisterProperty("GridLayout", "hSpacing", new (v, val) => {
			if (let c = v as GridLayout) if (float.Parse(val) case .Ok(let f)) c.HSpacing = f;
		});
		RegisterProperty("GridLayout", "vSpacing", new (v, val) => {
			if (let c = v as GridLayout) if (float.Parse(val) case .Ok(let f)) c.VSpacing = f;
		});

		// === AbsoluteLayout ===
		RegisterView("AbsoluteLayout", new () => new AbsoluteLayout());

		// === Label ===
		RegisterView("Label", new () => new Label());
		RegisterProperty("Label", "text", new (v, val) => {
			if (let c = v as Label) c.SetText(val);
		});
		RegisterProperty("Label", "textColor", new (v, val) => {
			if (let c = v as Label) if (ParseColor(val, let col)) c.TextColor = col;
		});
		RegisterProperty("Label", "fontSize", new (v, val) => {
			if (let c = v as Label) if (float.Parse(val) case .Ok(let f)) c.FontSize = f;
		});
		RegisterProperty("Label", "hAlign", new (v, val) => {
			if (let c = v as Label)
			{
				if (val == "Left") c.HAlign = .Left;
				else if (val == "Center") c.HAlign = .Center;
				else if (val == "Right") c.HAlign = .Right;
			}
		});
		RegisterProperty("Label", "vAlign", new (v, val) => {
			if (let c = v as Label)
			{
				if (val == "Top") c.VAlign = .Top;
				else if (val == "Middle") c.VAlign = .Middle;
				else if (val == "Bottom") c.VAlign = .Bottom;
				else if (val == "Baseline") c.VAlign = .Baseline;
			}
		});

		// === Button ===
		RegisterView("Button", new () => new Button());
		RegisterProperty("Button", "text", new (v, val) => {
			if (let c = v as Button) c.SetText(val);
		});
		RegisterProperty("Button", "textColor", new (v, val) => {
			if (let c = v as Button) if (ParseColor(val, let col)) c.TextColor = col;
		});
		RegisterProperty("Button", "fontSize", new (v, val) => {
			if (let c = v as Button) if (float.Parse(val) case .Ok(let f)) c.FontSize = f;
		});

		// === Panel ===
		RegisterView("Panel", new () => new Panel());

		// === ScrollView ===
		RegisterView("ScrollView", new () => new ScrollView());

		// === ListView ===
		RegisterView("ListView", new () => new ListView());

		// === TreeView ===
		RegisterView("TreeView", new () => new TreeView());

		// === ColorView ===
		RegisterView("ColorView", new () => new ColorView());
		RegisterProperty("ColorView", "color", new (v, val) => {
			if (let c = v as ColorView) if (ParseColor(val, let col)) c.Color = col;
		});
		RegisterProperty("ColorView", "preferredWidth", new (v, val) => {
			if (let c = v as ColorView) if (float.Parse(val) case .Ok(let f)) c.PreferredWidth = f;
		});
		RegisterProperty("ColorView", "preferredHeight", new (v, val) => {
			if (let c = v as ColorView) if (float.Parse(val) case .Ok(let f)) c.PreferredHeight = f;
		});

		// === ImageView ===
		RegisterView("ImageView", new () => new ImageView());

		// === Spacer ===
		RegisterView("Spacer", new () => new Spacer());
		RegisterProperty("Spacer", "spacerWidth", new (v, val) => {
			if (let c = v as Spacer) if (float.Parse(val) case .Ok(let f)) c.SpacerWidth = f;
		});
		RegisterProperty("Spacer", "spacerHeight", new (v, val) => {
			if (let c = v as Spacer) if (float.Parse(val) case .Ok(let f)) c.SpacerHeight = f;
		});

		// === Separator ===
		RegisterView("Separator", new () => new Separator());
		RegisterProperty("Separator", "orientation", new (v, val) => {
			if (let c = v as Separator) c.Orientation = ParseOrientation(val) ? .Horizontal : .Vertical;
		});
		RegisterProperty("Separator", "separatorThickness", new (v, val) => {
			if (let c = v as Separator) if (float.Parse(val) case .Ok(let f)) c.SeparatorThickness = f;
		});
		RegisterProperty("Separator", "color", new (v, val) => {
			if (let c = v as Separator) if (ParseColor(val, let col)) c.Color = col;
		});

		// === CheckBox ===
		RegisterView("CheckBox", new () => new CheckBox());
		RegisterProperty("CheckBox", "text", new (v, val) => {
			if (let c = v as CheckBox) c.SetText(val);
		});
		RegisterProperty("CheckBox", "isChecked", new (v, val) => {
			if (let c = v as CheckBox) c.IsChecked = (val == "true");
		});

		// === RadioButton ===
		RegisterView("RadioButton", new () => new RadioButton());
		RegisterProperty("RadioButton", "text", new (v, val) => {
			if (let c = v as RadioButton) c.SetText(val);
		});

		// === RadioGroup ===
		RegisterView("RadioGroup", new () => new RadioGroup());

		// === ToggleButton ===
		RegisterView("ToggleButton", new () => new ToggleButton());
		RegisterProperty("ToggleButton", "text", new (v, val) => {
			if (let c = v as ToggleButton) c.SetText(val);
		});

		// === ToggleSwitch ===
		RegisterView("ToggleSwitch", new () => new ToggleSwitch());
		RegisterProperty("ToggleSwitch", "text", new (v, val) => {
			if (let c = v as ToggleSwitch) c.SetText(val);
		});

		// === RepeatButton ===
		RegisterView("RepeatButton", new () => new RepeatButton());
		RegisterProperty("RepeatButton", "text", new (v, val) => {
			if (let c = v as RepeatButton) c.SetText(val);
		});

		// === ProgressBar ===
		RegisterView("ProgressBar", new () => new ProgressBar());
		RegisterProperty("ProgressBar", "progress", new (v, val) => {
			if (let c = v as ProgressBar) if (float.Parse(val) case .Ok(let f)) c.Progress = f;
		});

		// === Slider ===
		RegisterView("Slider", new () => new Slider());
		RegisterProperty("Slider", "min", new (v, val) => {
			if (let c = v as Slider) if (float.Parse(val) case .Ok(let f)) c.Min = f;
		});
		RegisterProperty("Slider", "max", new (v, val) => {
			if (let c = v as Slider) if (float.Parse(val) case .Ok(let f)) c.Max = f;
		});
		RegisterProperty("Slider", "step", new (v, val) => {
			if (let c = v as Slider) if (float.Parse(val) case .Ok(let f)) c.Step = f;
		});

		// === TabView ===
		RegisterView("TabView", new () => new TabView());

		// === ComboBox ===
		RegisterView("ComboBox", new () => new ComboBox());

		// === EditText ===
		RegisterView("EditText", new () => new EditText());
		RegisterProperty("EditText", "text", new (v, val) => {
			if (let c = v as EditText) c.SetText(val);
		});
		RegisterProperty("EditText", "placeholder", new (v, val) => {
			if (let c = v as EditText) c.SetPlaceholder(val);
		});
		RegisterProperty("EditText", "readOnly", new (v, val) => {
			if (let c = v as EditText) c.IsReadOnly = (val == "true");
		});
		RegisterProperty("EditText", "maxLength", new (v, val) => {
			if (let c = v as EditText) if (int32.Parse(val) case .Ok(let n)) c.MaxLength = n;
		});
		RegisterProperty("EditText", "multiline", new (v, val) => {
			if (let c = v as EditText) c.Multiline = (val == "true");
		});

		// === PasswordBox ===
		RegisterView("PasswordBox", new () => new PasswordBox());
		RegisterProperty("PasswordBox", "placeholder", new (v, val) => {
			if (let c = v as PasswordBox) c.SetPlaceholder(val);
		});
	}
}
