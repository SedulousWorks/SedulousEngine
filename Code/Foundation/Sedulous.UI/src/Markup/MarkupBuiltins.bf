using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// The built-in markup vocabulary: every view a document can name, and what its attributes
/// write.
///
/// Split from the registry itself the way View is split from its layout and styling, because
/// this is a table rather than machinery.
///
/// The COMMON view attributes are not here. id, class, style, visibility, opacity, padding,
/// tooltip, cursor and the rest mean the same on every element and are handled by the loader,
/// as is the whole LayoutStyle vocabulary.
extension MarkupRegistry
{
	/// Registers every built-in view and its markup-settable properties. Run once.
	public static void RegisterBuiltins()
	{
		if (sBuiltinsRegistered)
			return;

		sBuiltinsRegistered = true;

		RegisterLayouts();
		RegisterTextControls();
		RegisterToggleControls();
		RegisterValueControls();
		RegisterContainers();
	}

	// ---- Layouts ------------------------------------------------------------------------------

	private static void RegisterLayouts()
	{
		// Each layout answers to its type name AND a short alias, because markup reads better
		// as <Flex> while a sheet may address either.
		RegisterBoth("Flex", "FlexLayout", new () => new FlexLayout());
		RegisterBoth("Frame", "FrameLayout", new () => new FrameLayout());
		RegisterBoth("Dock", "DockLayout", new () => new DockLayout());
		RegisterBoth("Flow", "FlowLayout", new () => new FlowLayout());
		RegisterBoth("Absolute", "AbsoluteLayout", new () => new AbsoluteLayout());
		RegisterBoth("Grid", "GridLayout", new () => new GridLayout());

		for (let element in StringView[](("Flex"), ("FlexLayout")))
		{
			RegisterProperty(element, "direction", new (v, val) =>
				{
					if (let c = v as FlexLayout)
						c.Direction = (val == "vertical") ? .Vertical : .Horizontal;
				});
			RegisterProperty(element, "justify", new (v, val) =>
				{
					if (let c = v as FlexLayout)
					{
						switch (val)
						{
						case "start": c.JustifyContent = .Start;
						case "end": c.JustifyContent = .End;
						case "center": c.JustifyContent = .Center;
						case "space-between": c.JustifyContent = .SpaceBetween;
						case "space-around": c.JustifyContent = .SpaceAround;
						case "space-evenly": c.JustifyContent = .SpaceEvenly;
						default:
						}
					}
				});
			RegisterProperty(element, "align", new (v, val) =>
				{
					if (let c = v as FlexLayout)
					{
						switch (val)
						{
						case "start": c.AlignItems = .Start;
						case "end": c.AlignItems = .End;
						case "center": c.AlignItems = .Center;
						case "stretch": c.AlignItems = .Stretch;
						case "baseline": c.AlignItems = .Baseline;
						default:
						}
					}
				});
			RegisterProperty(element, "spacing", new (v, val) =>
				{
					if (let c = v as FlexLayout)
					{
						if (ParseFloatValue(val) case .Ok(let f))
							c.Spacing = f;
					}
				});
			RegisterProperty(element, "wrap", new (v, val) =>
				{
					if (let c = v as FlexLayout)
						c.Wrap = (val == "wrap") || (val == "true");
				});
			RegisterProperty(element, "align-content", new (v, val) =>
				{
					if (let c = v as FlexLayout)
					{
						switch (val)
						{
						case "start": c.AlignContent = .Start;
						case "end": c.AlignContent = .End;
						case "center": c.AlignContent = .Center;
						case "space-between": c.AlignContent = .SpaceBetween;
						case "space-around": c.AlignContent = .SpaceAround;
						case "stretch": c.AlignContent = .Stretch;
						default:
						}
					}
				});
			// CSS `gap: <row> [<column>]`, one value meaning both. Row and column are AXES
			// rather than directions: the layout maps them onto its main and cross gaps by
			// its own Direction.
			RegisterProperty(element, "gap", new (v, val) =>
				{
					if (let c = v as FlexLayout)
						ApplyGap(c, val);
				});
			RegisterProperty(element, "row-gap", new (v, val) =>
				{
					if (let c = v as FlexLayout)
					{
						if (ParseFloatValue(val) case .Ok(let f))
							c.RowGap = f;
					}
				});
			RegisterProperty(element, "column-gap", new (v, val) =>
				{
					if (let c = v as FlexLayout)
					{
						if (ParseFloatValue(val) case .Ok(let f))
							c.ColumnGap = f;
					}
				});
		}

		for (let element in StringView[](("Dock"), ("DockLayout")))
		{
			RegisterProperty(element, "last-child-fill", new (v, val) =>
				{
					if (let c = v as DockLayout)
						c.LastChildFill = ParseBool(val);
				});
		}
	}

	private static void ApplyGap(FlexLayout layout, StringView value)
	{
		var split = 0;
		while ((split < value.Length) && (value[split] != ' '))
			split++;

		if (!(ParseFloatValue(value.Substring(0, split)) case .Ok(let row)))
			return;

		layout.RowGap = row;
		layout.ColumnGap = row;

		if (split >= value.Length)
			return;

		if (ParseFloatValue(value.Substring(split + 1)) case .Ok(let column))
			layout.ColumnGap = column;
	}

	// ---- Text ---------------------------------------------------------------------------------

	private static void RegisterTextControls()
	{
		RegisterView("Label", new () => new Label());
		RegisterProperty("Label", "text", new (v, val) =>
			{
				if (let c = v as Label)
					c.SetText(val);
			});
		RegisterProperty("Label", "font-size", new (v, val) =>
			{
				if (let c = v as Label)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.FontSize.Value = f;
				}
			});
		RegisterProperty("Label", "font-family", new (v, val) =>
			{
				if (let c = v as Label)
					c.FontFamily.Value.Set(val);
			});
		RegisterProperty("Label", "word-wrap", new (v, val) =>
			{
				if (let c = v as Label)
					c.WordWrap.Value = ParseBool(val);
			});
		RegisterProperty("Label", "ellipsis", new (v, val) =>
			{
				if (let c = v as Label)
					c.Ellipsis.Value = ParseBool(val);
			});

		RegisterView("Button", new () => new Button(""));
		RegisterProperty("Button", "text", new (v, val) =>
			{
				if (let c = v as Button)
					c.SetText(val);
			});
		RegisterProperty("Button", "font-size", new (v, val) =>
			{
				if (let c = v as Button)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.FontSize.Value = f;
				}
			});
		RegisterProperty("Button", "font-family", new (v, val) =>
			{
				if (let c = v as Button)
					c.FontFamily.Value.Set(val);
			});

		// The icon itself comes from code or a theme part; markup only sizes it.
		RegisterView("IconButton", new () => new IconButton(null));
		RegisterProperty("IconButton", "size", new (v, val) =>
			{
				if (let c = v as IconButton)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.Size = f;
				}
			});

		RegisterView("EditText", new () => new EditText());
		RegisterProperty("EditText", "text", new (v, val) =>
			{
				if (let c = v as EditText)
					c.SetText(val);
			});
		RegisterProperty("EditText", "placeholder", new (v, val) =>
			{
				if (let c = v as EditText)
					c.SetPlaceholder(val);
			});
		RegisterProperty("EditText", "is-read-only", new (v, val) =>
			{
				if (let c = v as EditText)
					c.IsReadOnly.Value = ParseBool(val);
			});
		RegisterProperty("EditText", "multiline", new (v, val) =>
			{
				if (let c = v as EditText)
					c.Multiline.Value = ParseBool(val);
			});
		RegisterProperty("EditText", "max-length", new (v, val) =>
			{
				if (let c = v as EditText)
				{
					if (ParseIntValue(val) case .Ok(let n))
						c.MaxLength.Value = n;
				}
			});

		RegisterView("PasswordBox", new () => new PasswordBox());
		RegisterProperty("PasswordBox", "placeholder", new (v, val) =>
			{
				if (let c = v as PasswordBox)
					c.SetPlaceholder(val);
			});
	}

	// ---- Toggles ------------------------------------------------------------------------------

	private static void RegisterToggleControls()
	{
		RegisterView("CheckBox", new () => new CheckBox());
		RegisterProperty("CheckBox", "text", new (v, val) =>
			{
				if (let c = v as CheckBox)
					c.SetText(val);
			});
		RegisterProperty("CheckBox", "is-checked", new (v, val) =>
			{
				if (let c = v as CheckBox)
					c.IsChecked.Value = ParseBool(val);
			});

		RegisterView("RadioButton", new () => new RadioButton());
		RegisterProperty("RadioButton", "text", new (v, val) =>
			{
				if (let c = v as RadioButton)
					c.SetText(val);
			});

		RegisterView("RadioGroup", new () => new RadioGroup());

		RegisterView("ToggleSwitch", new () => new ToggleSwitch());
		RegisterProperty("ToggleSwitch", "text", new (v, val) =>
			{
				if (let c = v as ToggleSwitch)
					c.SetText(val);
			});
		RegisterProperty("ToggleSwitch", "is-checked", new (v, val) =>
			{
				if (let c = v as ToggleSwitch)
					c.IsChecked.Value = ParseBool(val);
			});

		RegisterView("ToggleButton", new () => new ToggleButton());
		RegisterProperty("ToggleButton", "is-checked", new (v, val) =>
			{
				if (let c = v as ToggleButton)
					c.IsChecked.Value = ParseBool(val);
			});
	}

	// ---- Values -------------------------------------------------------------------------------

	private static void RegisterValueControls()
	{
		RegisterView("Slider", new () => new Slider());
		RegisterProperty("Slider", "min", new (v, val) =>
			{
				if (let c = v as Slider)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.Min.Value = f;
				}
			});
		RegisterProperty("Slider", "max", new (v, val) =>
			{
				if (let c = v as Slider)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.Max.Value = f;
				}
			});
		RegisterProperty("Slider", "value", new (v, val) =>
			{
				if (let c = v as Slider)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.Value.Value = f;
				}
			});
		RegisterProperty("Slider", "step", new (v, val) =>
			{
				if (let c = v as Slider)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.Step.Value = f;
				}
			});

		RegisterView("ProgressBar", new () => new ProgressBar());
		RegisterProperty("ProgressBar", "value", new (v, val) =>
			{
				if (let c = v as ProgressBar)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.Value.Value = f;
				}
			});

		// The numeric field takes doubles, so these do NOT go through the float helper.
		RegisterView("NumericField", new () => new NumericField());
		RegisterProperty("NumericField", "value", new (v, val) =>
			{
				if (let c = v as NumericField)
				{
					if (double.Parse(val) case .Ok(let d))
						c.SetValue(d);
				}
			});
		RegisterProperty("NumericField", "min", new (v, val) =>
			{
				if (let c = v as NumericField)
				{
					if (double.Parse(val) case .Ok(let d))
						c.SetMin(d);
				}
			});
		RegisterProperty("NumericField", "max", new (v, val) =>
			{
				if (let c = v as NumericField)
				{
					if (double.Parse(val) case .Ok(let d))
						c.SetMax(d);
				}
			});
		RegisterProperty("NumericField", "step", new (v, val) =>
			{
				if (let c = v as NumericField)
				{
					if (double.Parse(val) case .Ok(let d))
						c.SetStep(d);
				}
			});
		RegisterProperty("NumericField", "show-spin-buttons", new (v, val) =>
			{
				if (let c = v as NumericField)
					c.ShowSpinButtons.Value = ParseBool(val);
			});

		RegisterView("Spacer", new () => new Spacer());
		// spacer-width rather than width, because width is the LAYOUT attribute and means
		// something else: this is the room the spacer asks for.
		RegisterProperty("Spacer", "spacer-width", new (v, val) =>
			{
				if (let c = v as Spacer)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.SpacerWidth.Value = f;
				}
			});
		RegisterProperty("Spacer", "spacer-height", new (v, val) =>
			{
				if (let c = v as Spacer)
				{
					if (ParseFloatValue(val) case .Ok(let f))
						c.SpacerHeight.Value = f;
				}
			});

		RegisterView("Separator", new () => new Separator());
		RegisterProperty("Separator", "orientation", new (v, val) =>
			{
				if (let c = v as Separator)
					c.Orientation.Value = (val == "horizontal") ? .Horizontal : .Vertical;
			});
	}

	// ---- Containers ---------------------------------------------------------------------------

	private static void RegisterContainers()
	{
		RegisterView("Panel", new () => new Panel());
		RegisterView("ScrollView", new () => new ScrollView());
		RegisterView("TabView", new () => new TabView());
		RegisterView("ComboBox", new () => new ComboBox());
		RegisterView("ColorView", new () => new ColorView());
		RegisterView("ImageView", new () => new ImageView());
		RegisterView("DrawableView", new () => new DrawableView());
		RegisterView("ListView", new () => new ListView());
		RegisterView("TreeView", new () => new TreeView());
		RegisterView("GridView", new () => new GridView());

		RegisterView("Expander", new () => new Expander());
		RegisterProperty("Expander", "header-text", new (v, val) =>
			{
				if (let c = v as Expander)
					c.SetHeaderText(val);
			});
		RegisterProperty("Expander", "is-expanded", new (v, val) =>
			{
				if (let c = v as Expander)
					c.SetIsExpanded(ParseBool(val));
			});
	}

	// ---- Internals ----------------------------------------------------------------------------

	/// Registers one factory under a short alias and its type name.
	///
	/// CONSUMES the factory, and makes a second for the alias: a delegate cannot be shared
	/// between two owning slots.
	private static void RegisterBoth(StringView alias, StringView typeName, ViewFactory factory)
	{
		RegisterView(typeName, factory);
		// The alias gets its own delegate calling the same registration.
		RegisterView(alias, new [=typeName]() => CreateView(typeName));
	}

	/// Markup's boolean: only the literal `true` is true, so a typo reads as false rather than
	/// as something unintended.
	private static bool ParseBool(StringView value) => value == "true";
}
