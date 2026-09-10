using System;
using System.Collections;

namespace Sedulous.UI;

/// Maps short names to view types.
///
/// The style sheet parser resolves element selectors through this, and the markup loader
/// resolves element names. A control registers itself with
/// `UITypeRegistry.Register("MyControl", typeof(MyControl))`.
///
static class UITypeRegistry
{
	private static Dictionary<String, Type> sTypes = new .() ~ DeleteDictionaryAndKeys!(_);
	private static bool sBuiltinsRegistered = false;

	/// Registers a type under a name, replacing any previous registration.
	public static void Register(StringView name, Type type)
	{
		if (sTypes.TryGetAlt(name, let existingKey, ?))
		{
			sTypes[existingKey] = type;
			return;
		}
		sTypes[new String(name)] = type;
	}

	/// Registers every built-in view, layout and control, so a sheet's element selectors and a
	/// markup document's element names resolve without the host naming them one by one.
	///
	/// Run once; the map is global. The layouts carry SHORT aliases as well as their type
	/// names, because markup reads better as <Flex> than <FlexLayout> and a sheet may address
	/// either.
	public static void RegisterBuiltins()
	{
		if (sBuiltinsRegistered)
			return;

		sBuiltinsRegistered = true;

		Register("View", typeof(View));
		Register("ViewGroup", typeof(ViewGroup));
		Register("RootView", typeof(RootView));

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

		Register("Panel", typeof(Panel));
		Register("Label", typeof(Label));
		Register("Button", typeof(Button));
		Register("IconButton", typeof(IconButton));
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

		Register("ContextMenu", typeof(ContextMenu));
		Register("TooltipView", typeof(TooltipView));
		// Dialog is not ported yet; it registers here when it lands.
	}

	/// The type registered under a name, or null.
	public static Type Resolve(StringView name)
	{
		if (sTypes.TryGetValueAlt(name, let type))
			return type;
		return null;
	}

	public static int Count => sTypes.Count;

	/// Forgets every registration. For tests, which must not leak state into one another.
	public static void Clear()
	{
		for (let key in sTypes.Keys)
			delete key;
		sTypes.Clear();
		// The guard goes with them, or a cleared registry could never be repopulated.
		sBuiltinsRegistered = false;
	}
}
