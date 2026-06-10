namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Maps XML element names to View factories and property setters.
/// Registration-based (not reflection) - explicit and debuggable.
/// Used by MarkupLoader to create views and set attributes from .sml files.
public static class MarkupRegistry
{
	/// Factory delegate that creates a View instance.
	public typealias ViewFactory = delegate View();

	/// Property setter delegate that sets a property from a string value.
	public typealias PropertySetter = delegate void(View view, StringView value);

	/// Layout params setter delegate that sets a layout param from a string value.
	public typealias LayoutParamSetter = delegate void(LayoutParams lp, StringView value);

	private struct ViewRegistration
	{
		public ViewFactory Factory;
		public Dictionary<String, PropertySetter> Properties;
	}

	private struct LayoutRegistration
	{
		public delegate LayoutParams() CreateParams;
		public Dictionary<String, LayoutParamSetter> Properties;
	}

	private static Dictionary<String, ViewRegistration> sViews ~ {
		if (_ != null) { CleanupViews(_); delete _; }
	};

	private static Dictionary<String, LayoutRegistration> sLayouts ~ {
		if (_ != null) { CleanupLayouts(_); delete _; }
	};

	private static void EnsureInit()
	{
		if (sViews == null) sViews = new .();
		if (sLayouts == null) sLayouts = new .();
	}

	private static void CleanupViews(Dictionary<String, ViewRegistration> views)
	{
		for (let kv in views)
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
	}

	private static void CleanupLayouts(Dictionary<String, LayoutRegistration> layouts)
	{
		for (let kv in layouts)
		{
			delete kv.key;
			delete kv.value.CreateParams;
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
	}

	// === View registration ===

	/// Register a view type with its XML element name and factory.
	public static void RegisterView(StringView elementName, ViewFactory factory)
	{
		EnsureInit();
		sViews[new String(elementName)] = .() { Factory = factory, Properties = new .() };
	}

	/// Register a named property setter for a view type.
	public static void RegisterProperty(StringView elementName, StringView propertyName, PropertySetter setter)
	{
		EnsureInit();
		let elemKey = scope String(elementName);
		if (sViews.TryGetValue(elemKey, var reg))
		{
			reg.Properties[new String(propertyName)] = setter;
			sViews[elemKey] = reg;
		}
	}

	/// Register a layout container's LayoutParams factory and param setters.
	public static void RegisterLayout(StringView elementName, delegate LayoutParams() createParams)
	{
		EnsureInit();
		sLayouts[new String(elementName)] = .() { CreateParams = createParams, Properties = new .() };
	}

	/// Register a layout param setter for a container type.
	public static void RegisterLayoutParam(StringView elementName, StringView paramName, LayoutParamSetter setter)
	{
		EnsureInit();
		let elemKey = scope String(elementName);
		if (sLayouts.TryGetValue(elemKey, var reg))
		{
			reg.Properties[new String(paramName)] = setter;
			sLayouts[elemKey] = reg;
		}
	}

	// === Lookup ===

	/// Create a view for the given element name. Returns null if not registered.
	public static View CreateView(StringView elementName)
	{
		EnsureInit();
		let key = scope String(elementName);
		if (sViews.TryGetValue(key, let reg))
			return reg.Factory();
		return null;
	}

	/// Try to set a property on a view from a string value.
	/// Returns true if the property was found and set.
	public static bool SetProperty(StringView elementName, View view, StringView propertyName, StringView value)
	{
		EnsureInit();
		let elemKey = scope String(elementName);
		if (!sViews.TryGetValue(elemKey, let reg))
			return false;

		let propKey = scope String(propertyName);
		if (reg.Properties.TryGetValue(propKey, let setter))
		{
			setter(view, value);
			return true;
		}
		return false;
	}

	/// Create default LayoutParams for a container. Returns null if not a registered layout.
	public static LayoutParams CreateLayoutParams(StringView containerName)
	{
		EnsureInit();
		let key = scope String(containerName);
		if (sLayouts.TryGetValue(key, let reg))
			return reg.CreateParams();
		return null;
	}

	/// Try to set a layout param from a string value.
	/// Returns true if the param was found and set.
	public static bool SetLayoutParam(StringView containerName, LayoutParams lp, StringView paramName, StringView value)
	{
		EnsureInit();
		let key = scope String(containerName);
		if (!sLayouts.TryGetValue(key, let reg))
			return false;

		let paramKey = scope String(paramName);
		if (reg.Properties.TryGetValue(paramKey, let setter))
		{
			setter(lp, value);
			return true;
		}
		return false;
	}

	/// Check if an element name is registered.
	public static bool IsRegistered(StringView elementName)
	{
		EnsureInit();
		let key = scope String(elementName);
		return sViews.ContainsKey(key);
	}

	/// Check if a layout container is registered.
	public static bool IsLayoutRegistered(StringView elementName)
	{
		EnsureInit();
		let key = scope String(elementName);
		return sLayouts.ContainsKey(key);
	}

	// === Value parsing helpers ===

	/// Parse a SizeSpec from markup: "wrap", "match", "240", "240px", "16dp".
	public static SizeSpec ParseSizeSpec(StringView value)
	{
		if (value == "wrap") return .Wrap;
		if (value == "match") return .Match;
		// Try with unit suffix first
		let trimmed = scope String(value);
		trimmed.Trim();
		if (trimmed.EndsWith("px"))
		{
			let numStr = trimmed.Substring(0, trimmed.Length - 2);
			if (float.Parse(numStr) case .Ok(let v))
				return .Fixed(.Px(v));
		}
		else if (trimmed.EndsWith("dp"))
		{
			let numStr = trimmed.Substring(0, trimmed.Length - 2);
			if (float.Parse(numStr) case .Ok(let v))
				return .Fixed(.Dp(v));
		}
		else if (trimmed.EndsWith("pt"))
		{
			let numStr = trimmed.Substring(0, trimmed.Length - 2);
			if (float.Parse(numStr) case .Ok(let v))
				return .Fixed(.Pt(v));
		}
		// Unitless number = dp
		if (float.Parse(value) case .Ok(let v))
			return .Fixed(.Dp(v));
		return .Wrap;
	}

	/// Parse a Gravity value: "Center", "Fill", "TopLeft", "Bottom|Right", etc.
	public static Gravity ParseGravity(StringView value)
	{
		Gravity result = .None;
		for (let part in value.Split('|'))
		{
			let s = scope String();
			s.Append(part);
			s.Trim();

			if (s == "Left") result |= .Left;
			else if (s == "Right") result |= .Right;
			else if (s == "CenterH") result |= .CenterH;
			else if (s == "FillH") result |= .FillH;
			else if (s == "Top") result |= .Top;
			else if (s == "Bottom") result |= .Bottom;
			else if (s == "CenterV") result |= .CenterV;
			else if (s == "FillV") result |= .FillV;
			else if (s == "Center") result |= .Center;
			else if (s == "Fill") result |= .Fill;
			else if (s == "TopLeft") result |= .TopLeft;
			else if (s == "TopRight") result |= .TopRight;
			else if (s == "BottomLeft") result |= .BottomLeft;
			else if (s == "BottomRight") result |= .BottomRight;
		}
		return result;
	}

	/// Parse a Thickness: "8" (all), "8 12" (vert horiz), "1 2 3 4" (top right bottom left).
	public static Thickness ParseThickness(StringView value)
	{
		float[4] values = default;
		int count = 0;
		for (let part in value.Split(' '))
		{
			if (count >= 4) break;
			let s = scope String();
			s.Append(part);
			s.Trim();
			if (s.IsEmpty) continue;
			if (float.Parse(s) case .Ok(let f))
				values[count++] = f;
		}
		return StyleValueParser.ParseThickness(&values, count);
	}

	private static bool sBuiltinsRegistered = false;

	/// Register all built-in view types with their markup-settable properties.
	/// Safe to call multiple times.
	public static void RegisterBuiltins()
	{
		if (sBuiltinsRegistered) return;
		sBuiltinsRegistered = true;

		// === Common View properties are handled inline by MarkupLoader ===
		// (id, class, visibility, is-enabled, opacity, padding, tooltip, cursor, etc.)

		// === Layouts ===

		RegisterView("Flex", new () => new FlexLayout());
		RegisterView("FlexLayout", new () => new FlexLayout());
		RegisterProperty("Flex", "direction", new (v, val) => {
			if (let c = v as FlexLayout) c.Direction = (val == "vertical") ? .Vertical : .Horizontal;
		});
		RegisterProperty("Flex", "justify", new (v, val) => {
			if (let c = v as FlexLayout)
			{
				if (val == "start") c.JustifyContent = .Start;
				else if (val == "end") c.JustifyContent = .End;
				else if (val == "center") c.JustifyContent = .Center;
				else if (val == "space-between") c.JustifyContent = .SpaceBetween;
				else if (val == "space-around") c.JustifyContent = .SpaceAround;
				else if (val == "space-evenly") c.JustifyContent = .SpaceEvenly;
			}
		});
		RegisterProperty("Flex", "align", new (v, val) => {
			if (let c = v as FlexLayout)
			{
				if (val == "start") c.AlignItems = .Start;
				else if (val == "end") c.AlignItems = .End;
				else if (val == "center") c.AlignItems = .Center;
				else if (val == "stretch") c.AlignItems = .Stretch;
				else if (val == "baseline") c.AlignItems = .Baseline;
			}
		});
		RegisterProperty("Flex", "spacing", new (v, val) => {
			if (let c = v as FlexLayout) if (float.Parse(val) case .Ok(let f)) c.Spacing = f;
		});
		// Copy Flex properties to FlexLayout alias
		RegisterProperty("FlexLayout", "direction", new (v, val) => {
			if (let c = v as FlexLayout) c.Direction = (val == "vertical") ? .Vertical : .Horizontal;
		});
		RegisterProperty("FlexLayout", "justify", new (v, val) => {
			if (let c = v as FlexLayout)
			{
				if (val == "start") c.JustifyContent = .Start;
				else if (val == "end") c.JustifyContent = .End;
				else if (val == "center") c.JustifyContent = .Center;
				else if (val == "space-between") c.JustifyContent = .SpaceBetween;
				else if (val == "space-around") c.JustifyContent = .SpaceAround;
				else if (val == "space-evenly") c.JustifyContent = .SpaceEvenly;
			}
		});
		RegisterProperty("FlexLayout", "align", new (v, val) => {
			if (let c = v as FlexLayout)
			{
				if (val == "start") c.AlignItems = .Start;
				else if (val == "end") c.AlignItems = .End;
				else if (val == "center") c.AlignItems = .Center;
				else if (val == "stretch") c.AlignItems = .Stretch;
				else if (val == "baseline") c.AlignItems = .Baseline;
			}
		});
		RegisterProperty("FlexLayout", "spacing", new (v, val) => {
			if (let c = v as FlexLayout) if (float.Parse(val) case .Ok(let f)) c.Spacing = f;
		});

		// Flex layout params
		RegisterLayout("Flex", new () => new FlexLayout.LayoutParams());
		RegisterLayoutParam("Flex", "grow", new (lp, val) => {
			if (let flp = lp as FlexLayout.LayoutParams) if (float.Parse(val) case .Ok(let f)) flp.Grow = f;
		});
		RegisterLayoutParam("Flex", "shrink", new (lp, val) => {
			if (let flp = lp as FlexLayout.LayoutParams) if (float.Parse(val) case .Ok(let f)) flp.Shrink = f;
		});
		RegisterLayout("FlexLayout", new () => new FlexLayout.LayoutParams());
		RegisterLayoutParam("FlexLayout", "grow", new (lp, val) => {
			if (let flp = lp as FlexLayout.LayoutParams) if (float.Parse(val) case .Ok(let f)) flp.Grow = f;
		});
		RegisterLayoutParam("FlexLayout", "shrink", new (lp, val) => {
			if (let flp = lp as FlexLayout.LayoutParams) if (float.Parse(val) case .Ok(let f)) flp.Shrink = f;
		});

		RegisterView("Frame", new () => new FrameLayout());
		RegisterView("FrameLayout", new () => new FrameLayout());
		RegisterLayout("Frame", new () => new FrameLayout.LayoutParams());
		RegisterLayoutParam("Frame", "gravity", new (lp, val) => {
			if (let flp = lp as FrameLayout.LayoutParams) flp.Gravity = ParseGravity(val);
		});
		RegisterLayout("FrameLayout", new () => new FrameLayout.LayoutParams());
		RegisterLayoutParam("FrameLayout", "gravity", new (lp, val) => {
			if (let flp = lp as FrameLayout.LayoutParams) flp.Gravity = ParseGravity(val);
		});

		RegisterView("Dock", new () => new DockLayout());
		RegisterView("DockLayout", new () => new DockLayout());
		RegisterProperty("Dock", "last-child-fill", new (v, val) => {
			if (let c = v as DockLayout) c.LastChildFill = (val == "true");
		});
		RegisterProperty("DockLayout", "last-child-fill", new (v, val) => {
			if (let c = v as DockLayout) c.LastChildFill = (val == "true");
		});
		RegisterLayout("Dock", new () => new DockLayout.LayoutParams());
		RegisterLayoutParam("Dock", "dock", new (lp, val) => {
			if (let dlp = lp as DockLayout.LayoutParams)
			{
				if (val == "left") dlp.Dock = .Left;
				else if (val == "top") dlp.Dock = .Top;
				else if (val == "right") dlp.Dock = .Right;
				else if (val == "bottom") dlp.Dock = .Bottom;
				else if (val == "fill") dlp.Dock = .Fill;
			}
		});
		RegisterLayout("DockLayout", new () => new DockLayout.LayoutParams());
		RegisterLayoutParam("DockLayout", "dock", new (lp, val) => {
			if (let dlp = lp as DockLayout.LayoutParams)
			{
				if (val == "left") dlp.Dock = .Left;
				else if (val == "top") dlp.Dock = .Top;
				else if (val == "right") dlp.Dock = .Right;
				else if (val == "bottom") dlp.Dock = .Bottom;
				else if (val == "fill") dlp.Dock = .Fill;
			}
		});

		RegisterView("Flow", new () => new FlowLayout());
		RegisterView("FlowLayout", new () => new FlowLayout());

		RegisterView("Absolute", new () => new AbsoluteLayout());
		RegisterView("AbsoluteLayout", new () => new AbsoluteLayout());

		RegisterView("Grid", new () => new GridLayout());
		RegisterView("GridLayout", new () => new GridLayout());

		// === Controls ===

		RegisterView("Panel", new () => new Panel());
		RegisterView("ScrollView", new () => new ScrollView());

		RegisterView("Label", new () => new Label());
		RegisterProperty("Label", "text", new (v, val) => {
			if (let c = v as Label) c.Text.Value = new String(val);
		});
		RegisterProperty("Label", "font-size", new (v, val) => {
			if (let c = v as Label) if (float.Parse(val) case .Ok(let f)) c.FontSize.Value = f;
		});
		RegisterProperty("Label", "font-family", new (v, val) => {
			if (let c = v as Label) c.FontFamily.Value = new String(val);
		});
		RegisterProperty("Label", "word-wrap", new (v, val) => {
			if (let c = v as Label) c.WordWrap.Value = (val == "true");
		});
		RegisterProperty("Label", "ellipsis", new (v, val) => {
			if (let c = v as Label) c.Ellipsis.Value = (val == "true");
		});

		RegisterView("Button", new () => new Button(""));
		RegisterProperty("Button", "text", new (v, val) => {
			if (let c = v as Button) c.SetText(val);
		});
		RegisterProperty("Button", "font-size", new (v, val) => {
			if (let c = v as Button) if (float.Parse(val) case .Ok(let f)) c.FontSize.Value = f;
		});
		RegisterProperty("Button", "font-family", new (v, val) => {
			if (let c = v as Button) c.FontFamily.Value = new String(val);
		});

		RegisterView("CheckBox", new () => new CheckBox());
		RegisterProperty("CheckBox", "text", new (v, val) => {
			if (let c = v as CheckBox) c.Text.Value = new String(val);
		});
		RegisterProperty("CheckBox", "is-checked", new (v, val) => {
			if (let c = v as CheckBox) c.IsChecked.Value = (val == "true");
		});

		RegisterView("RadioButton", new () => new RadioButton());
		RegisterProperty("RadioButton", "text", new (v, val) => {
			if (let c = v as RadioButton) c.Text.Value = new String(val);
		});

		RegisterView("RadioGroup", new () => new RadioGroup());

		RegisterView("ToggleSwitch", new () => new ToggleSwitch());
		RegisterProperty("ToggleSwitch", "text", new (v, val) => {
			if (let c = v as ToggleSwitch) c.Text.Value = new String(val);
		});
		RegisterProperty("ToggleSwitch", "is-checked", new (v, val) => {
			if (let c = v as ToggleSwitch) c.IsChecked.Value = (val == "true");
		});

		RegisterView("ToggleButton", new () => new ToggleButton());
		RegisterProperty("ToggleButton", "is-checked", new (v, val) => {
			if (let c = v as ToggleButton) c.IsChecked.Value = (val == "true");
		});

		RegisterView("Slider", new () => new Slider());
		RegisterProperty("Slider", "min", new (v, val) => {
			if (let c = v as Slider) if (float.Parse(val) case .Ok(let f)) c.Min.Value = f;
		});
		RegisterProperty("Slider", "max", new (v, val) => {
			if (let c = v as Slider) if (float.Parse(val) case .Ok(let f)) c.Max.Value = f;
		});
		RegisterProperty("Slider", "value", new (v, val) => {
			if (let c = v as Slider) if (float.Parse(val) case .Ok(let f)) c.Value.Value = f;
		});
		RegisterProperty("Slider", "step", new (v, val) => {
			if (let c = v as Slider) if (float.Parse(val) case .Ok(let f)) c.Step.Value = f;
		});

		RegisterView("ProgressBar", new () => new ProgressBar());
		RegisterProperty("ProgressBar", "value", new (v, val) => {
			if (let c = v as ProgressBar) if (float.Parse(val) case .Ok(let f)) c.Value.Value = f;
		});

		RegisterView("EditText", new () => new EditText());
		RegisterProperty("EditText", "text", new (v, val) => {
			if (let c = v as EditText) c.SetText(val);
		});
		RegisterProperty("EditText", "placeholder", new (v, val) => {
			if (let c = v as EditText) c.SetPlaceholder(val);
		});
		RegisterProperty("EditText", "is-read-only", new (v, val) => {
			if (let c = v as EditText) c.IsReadOnly.Value = (val == "true");
		});
		RegisterProperty("EditText", "multiline", new (v, val) => {
			if (let c = v as EditText) c.Multiline.Value = (val == "true");
		});
		RegisterProperty("EditText", "max-length", new (v, val) => {
			if (let c = v as EditText) if (int32.Parse(val) case .Ok(let n)) c.MaxLength.Value = n;
		});

		RegisterView("PasswordBox", new () => new PasswordBox());
		RegisterProperty("PasswordBox", "placeholder", new (v, val) => {
			if (let c = v as PasswordBox) c.SetPlaceholder(val);
		});

		RegisterView("NumericField", new () => new NumericField());
		RegisterProperty("NumericField", "value", new (v, val) => {
			if (let c = v as NumericField) if (double.Parse(val) case .Ok(let d)) c.Value = d;
		});
		RegisterProperty("NumericField", "min", new (v, val) => {
			if (let c = v as NumericField) if (double.Parse(val) case .Ok(let d)) c.Min = d;
		});
		RegisterProperty("NumericField", "max", new (v, val) => {
			if (let c = v as NumericField) if (double.Parse(val) case .Ok(let d)) c.Max = d;
		});
		RegisterProperty("NumericField", "step", new (v, val) => {
			if (let c = v as NumericField) if (double.Parse(val) case .Ok(let d)) c.Step = d;
		});
		RegisterProperty("NumericField", "show-spin-buttons", new (v, val) => {
			if (let c = v as NumericField) c.ShowSpinButtons.Value = (val == "true");
		});

		RegisterView("Expander", new () => new Expander());
		RegisterProperty("Expander", "header-text", new (v, val) => {
			if (let c = v as Expander) c.SetHeaderText(val);
		});
		RegisterProperty("Expander", "is-expanded", new (v, val) => {
			if (let c = v as Expander) c.IsExpanded = (val == "true");
		});

		RegisterView("TabView", new () => new TabView());

		RegisterView("ComboBox", new () => new ComboBox());
		RegisterView("Spacer", new () => new Spacer());
		RegisterProperty("Spacer", "spacer-width", new (v, val) => {
			if (let c = v as Spacer) if (float.Parse(val) case .Ok(let f)) c.SpacerWidth.Value = f;
		});
		RegisterProperty("Spacer", "spacer-height", new (v, val) => {
			if (let c = v as Spacer) if (float.Parse(val) case .Ok(let f)) c.SpacerHeight.Value = f;
		});

		RegisterView("Separator", new () => new Separator());
		RegisterProperty("Separator", "orientation", new (v, val) => {
			if (let c = v as Separator) c.Orientation.Value = (val == "horizontal") ? .Horizontal : .Vertical;
		});

		RegisterView("ColorView", new () => new ColorView());
		RegisterView("ImageView", new () => new ImageView());
		RegisterView("DrawableView", new () => new DrawableView());
		RegisterView("ListView", new () => new ListView());
		RegisterView("TreeView", new () => new TreeView());
		RegisterView("GridView", new () => new GridView());
	}
}
