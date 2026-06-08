namespace Sedulous.UI;

using System;
using System.Collections;

/// Maps short string names to Beef types. Used by the .sss parser for
/// element selectors and by the .sml loader for element resolution.
/// Built-in controls auto-register. User controls register via
/// UITypeRegistry.Register("MyControl", typeof(MyControl)).
//[StaticInitPriority(2000)]
public static class UITypeRegistry
{
	private static Dictionary<String, Type> sTypes ~  { if (_ != null) DeleteDictionaryAndKeys!(_); };

	private static void EnsureInit()
	{
		if (sTypes == null)
			sTypes = new .();
	}

	/// Register a type with a name. Overwrites if name already exists.
	public static void Register(StringView name, Type type)
	{
		EnsureInit();
		for (let kv in sTypes)
		{
			if (StringView(kv.key) == name)
			{
				sTypes[kv.key] = type;
				return;
			}
		}
		sTypes[new String(name)] = type;
	}

	/// Look up a type by name. Returns null if not found.
	public static Type Resolve(StringView name)
	{
		EnsureInit();
		for (let kv in sTypes)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}
		return null;
	}

	/// Returns the number of registered types.
	public static int Count { get { EnsureInit(); return sTypes.Count; } }

	/// Register all built-in GUI types.
	public static void RegisterBuiltins()
	{
		// Core
		Register("View", typeof(View));
		Register("ViewGroup", typeof(ViewGroup));
		Register("RootView", typeof(RootView));

		// Layouts + aliases
		Register("FlexLayout", typeof(FlexLayout));
		Register("Flex", typeof(FlexLayout));
		Register("GridLayout", typeof(GridLayout));
		Register("Grid", typeof(GridLayout));
		Register("DockLayout", typeof(DockLayout));
		Register("Dock", typeof(DockLayout));
		Register("FrameLayout", typeof(FrameLayout));
		Register("Frame", typeof(FrameLayout));
		Register("AbsoluteLayout", typeof(AbsoluteLayout));
		Register("Absolute", typeof(AbsoluteLayout));
		Register("FlowLayout", typeof(FlowLayout));
		Register("Flow", typeof(FlowLayout));

		// Controls
		Register("Panel", typeof(Panel));
		Register("Label", typeof(Label));
		Register("Button", typeof(Button));
		Register("ButtonBase", typeof(ButtonBase));
		Register("ContentButton", typeof(ContentButton));
		Register("RepeatButton", typeof(RepeatButton));
		Register("ToggleButton", typeof(ToggleButton));
		Register("CheckBox", typeof(CheckBox));
		Register("RadioButton", typeof(RadioButton));
		Register("RadioGroup", typeof(RadioGroup));
		Register("ToggleSwitch", typeof(ToggleSwitch));
		Register("EditText", typeof(EditText));
		Register("PasswordBox", typeof(PasswordBox));
		Register("NumericField", typeof(NumericField));
		Register("EditableLabel", typeof(EditableLabel));
		Register("Slider", typeof(Slider));
		Register("ProgressBar", typeof(ProgressBar));
		Register("ScrollBar", typeof(ScrollBar));
		Register("ScrollView", typeof(ScrollView));
		Register("ImageView", typeof(ImageView));
		Register("ColorView", typeof(ColorView));
		Register("DrawableView", typeof(DrawableView));
		Register("Separator", typeof(Separator));
		Register("Spacer", typeof(Spacer));
		Register("ComboBox", typeof(ComboBox));
		Register("TabView", typeof(TabView));
		Register("Expander", typeof(Expander));
		Register("ListView", typeof(ListView));
		Register("GridView", typeof(GridView));
		Register("TreeView", typeof(TreeView));

		// Overlay
		Register("ContextMenu", typeof(ContextMenu));
		Register("Dialog", typeof(Dialog));
		Register("TooltipView", typeof(TooltipView));
	}
}
