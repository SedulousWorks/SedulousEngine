using System;
using System.Collections;
using Sedulous.Core.Logging;

namespace Sedulous.GUI;

// Which element types exist, and which one GUI may create.
//
// ElementTypes is the registry of element types: type knowledge, so process-wide. Any library adds
// its widgets (the GUI's own, a toolkit, a game kit, a viewport) by registering their reflected
// types once at start-up; an element type is a reflected Node type with a creator
// ([GuiReflect(true)]), under its tag (the attribute's, else its type name) that markup names and
// a script's `add` takes. A tag another type already holds is refused, loudly.
//
// ElementSet is what one GUI may create from those: every registered type by default (including
// ones registered later), or only the tags it allows, with aliases of its own. A GUI holds one, so
// two GUIs in one process can offer different elements, e.g. a mod's markup limited to a few.

static class ElementTypes
{
	/// The registered types, in registration order. Their tables are static: nothing here owns
	/// them.
	private static List<GuiTypeInfo> sElements = new .() ~ delete _;

	/// Registers `type` as an element under its tag. False, with an error logged, when it is not a
	/// Node type, has no creator, or its tag is another type's.
	public static bool Register(GuiTypeInfo type)
	{
		let tag = TagOf(type);
		if (!type.Type.IsSubtypeOf(typeof(Node)) || !type.CanCreate)
		{
			GlobalLog(.Error, "GUI: '{}' is not an element type: a reflected Node type with a creator", tag);
			return false;
		}
		for (let element in sElements)
		{
			if (element.Tag != tag)
				continue;
			if (element == type)
				return true; // registered already
			let other = element.Type.GetFullName(.. scope String());
			GlobalLog(.Error, "GUI: the element tag '{}' is taken by another type ({}); not registered", tag, other);
			return false;
		}
		sElements.Add(type);
		return true;
	}

	/// Takes `type` out (a library unloading): markup and scripts can no longer create it.
	public static void Unregister(GuiTypeInfo type)
	{
		sElements.Remove(type);
	}

	/// The element type under `tag`, or null.
	public static GuiTypeInfo Find(StringView tag)
	{
		for (let element in sElements)
		{
			if (element.Tag == tag)
				return element;
		}
		return null;
	}

	/// The tag `type` registers under: its [GuiReflect] tag, else its type name.
	public static StringView TagOf(GuiTypeInfo type) => type.Tag;

	/// Every registered element type, in registration order.
	public static void ForEach(delegate void(StringView tag, GuiTypeInfo type) visit)
	{
		for (let element in sElements)
			visit(element.Tag, element);
	}
}

static
{
	private static bool sGuiElementsRegistered = false;

	/// Registers the GUI's own widgets as element types, once (again: nothing), so markup and
	/// scripts can make them. A library registers its own beside this, at start-up.
	public static void RegisterGuiElements()
	{
		if (sGuiElementsRegistered)
			return;
		sGuiElementsRegistered = true;
		GuiTypeInfo[?] elements = .(
			Label.StaticGuiType, Button.StaticGuiType, CheckBox.StaticGuiType,
			RadioButton.StaticGuiType, Slider.StaticGuiType, ProgressBar.StaticGuiType,
			TextField.StaticGuiType, Panel.StaticGuiType, ScrollView.StaticGuiType,
			Sedulous.GUI.Image.StaticGuiType, ListBox.StaticGuiType, Window.StaticGuiType,
			ComboBox.StaticGuiType, RichText.StaticGuiType, TextArea.StaticGuiType,
			ToggleSwitch.StaticGuiType, Separator.StaticGuiType, Spacer.StaticGuiType,
			NumberField.StaticGuiType, EditableLabel.StaticGuiType, Expander.StaticGuiType,
			Tab.StaticGuiType, TabBar.StaticGuiType, TabPage.StaticGuiType,
			TabView.StaticGuiType, Menu.StaticGuiType, MenuItem.StaticGuiType,
			MenuSeparator.StaticGuiType, MenuBar.StaticGuiType, ScrollBar.StaticGuiType,
			MessageBox.StaticGuiType, Splitter.StaticGuiType, ColorSwatch.StaticGuiType,
			ColorPicker.StaticGuiType, ToastHost.StaticGuiType, ListView.StaticGuiType,
			TreeView.StaticGuiType, TreeItem.StaticGuiType, TableView.StaticGuiType,
			TableItem.StaticGuiType);
		for (let type in elements)
			ElementTypes.Register(type);
	}
}

/// What one GUI may create: every registered element type, or only the tags it allows, under
/// aliases of its own. A class: it owns its lists; Set copies another deeply.
class ElementSet
{
	private class AliasEntry
	{
		public String Alias = new .() ~ delete _;
		public String Tag = new .() ~ delete _;
	}

	private bool mAll = true;
	private List<String> mAllowed = new .() ~ DeleteContainerAndItems!(_);
	private List<AliasEntry> mAliases = new .() ~ DeleteContainerAndItems!(_);

	/// Every registered element type, now and later. The caller owns what comes back.
	public static ElementSet All() => new ElementSet();

	/// Only the tags allowed with Allow (none yet). The caller owns what comes back.
	public static ElementSet None()
	{
		let set = new ElementSet();
		set.mAll = false;
		return set;
	}

	/// Makes this a copy of `other`.
	public void Set(ElementSet other)
	{
		if (other === this)
			return;
		mAll = other.mAll;
		ClearAndDeleteItems!(mAllowed);
		for (let tag in other.mAllowed)
			mAllowed.Add(new String(tag));
		ClearAndDeleteItems!(mAliases);
		for (let alias in other.mAliases)
			Alias(alias.Alias, alias.Tag);
	}

	/// Allows `tag` (a registered element's tag) in a set made with None().
	public void Allow(StringView tag)
	{
		mAllowed.Add(new String(tag));
	}

	/// `alias` creates what `tag` does (in markup and `add`), allowed where `tag` is.
	public void Alias(StringView alias, StringView tag)
	{
		let entry = new AliasEntry();
		entry.Alias.Set(alias);
		entry.Tag.Set(tag);
		mAliases.Add(entry);
	}

	/// The element type `tag` names in this set (through an alias), or null when the set does not
	/// allow it or no such element is registered.
	public GuiTypeInfo Resolve(StringView tag)
	{
		StringView name = tag;
		for (let alias in mAliases)
		{
			if (alias.Alias == name)
				name = alias.Tag;
		}
		if (!mAll)
		{
			bool allowed = false;
			for (let entry in mAllowed)
				allowed = allowed || (entry == name);
			if (!allowed)
				return null;
		}
		return ElementTypes.Find(name);
	}

	/// A new element of what `tag` names; null when the set does not allow it. The node comes with
	/// one reference, the caller's.
	public Node Create(StringView tag)
	{
		let type = Resolve(tag);
		if (type == null)
			return null;
		let made = type.Create();
		if (let node = made as Node)
			return node;
		delete made;
		return null;
	}
}

/// A native weak reference to an element of type T: resolves to the element while it lives in its
/// GUI, and to null once it is destroyed (or its GUI is), through the element table the script
/// handles use too. For callbacks, tools and bindings that must not keep a widget alive nor outlive
/// it. Empty for an element in no GUI. It holds a reference to the table (not to the element).
class Element<T> where T : Node
{
	private ElementTable mTable ~ _?.ReleaseRef();
	private uint32 mSlot = 0;
	private uint32 mGeneration = 0;

	public this() { }

	public this(T element)
	{
		let elementRef = element.TakeElementRef();
		if (elementRef.Table != null)
		{
			mTable = elementRef.Table;
			mTable.AddRef();
			mSlot = elementRef.Slot;
			mGeneration = elementRef.Generation;
		}
	}

	public T Get() => (mTable != null) ? (mTable.Resolve(mSlot, mGeneration) as T) : null;

	public bool IsValid => Get() != null;
}
