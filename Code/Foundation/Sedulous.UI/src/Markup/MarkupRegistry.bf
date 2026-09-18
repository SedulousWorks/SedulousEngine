using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.UI;

/// What a markup element name means: which view to build, and what its attributes write.
///
/// The loader resolves everything through here, so a control becomes usable in markup by
/// registering rather than by the loader knowing about it.
///
/// The layout vocabulary is deliberately NOT per element: width, margin, dock and the rest
/// write a view's LayoutStyle and mean the same on every element, whatever its parent.
static class MarkupRegistry
{
	/// Builds a view. OWNERSHIP of the result transfers to the caller.
	public typealias ViewFactory = delegate View();
	/// Writes one attribute onto a view.
	public typealias PropertySetter = delegate void(View, StringView);

	/// The separator between an element and a property in a key. A unit separator, because it
	/// cannot appear in either half.
	private const char8 KeySeparator = '\x1F';

	private static Dictionary<String, ViewFactory> sViewFactories = new .() ~ ClearRegistry!(_);
	private static Dictionary<String, PropertySetter> sViewProps = new .() ~ ClearRegistry!(_);
	private static bool sBuiltinsRegistered = false;

	/// Serialises FIRST TIME registration, because the cook reaches it from job workers: two
	/// asset builders cooking two UI documents both call MarkupLoader.Initialize, and a plain
	/// flag lets both through to rehash the dictionaries under each other.
	///
	/// Held by the once guarded entry points only, never by Register itself, so nothing nests.
	/// ANY extension registering into this registry must hold it, which is why it is public:
	/// Gamekit's <screen> writes these same maps.
	private static Monitor sLock = new .() ~ delete _;

	public static Monitor RegistrationLock => sLock;

	/// Deletes the owned keys and delegates, then the dictionary.
	private static mixin ClearRegistry(var map)
	{
		for (let pair in map)
		{
			delete pair.key;
			delete pair.value;
		}
		delete map;
	}

	// ---- Registration -------------------------------------------------------------------------

	/// CONSUMES the factory delegate. Registering a name twice replaces the first.
	public static void RegisterView(StringView elementName, ViewFactory factory)
	{
		if (sViewFactories.TryGetAlt(elementName, let key, let existing))
		{
			delete existing;
			sViewFactories[key] = factory;
			return;
		}
		sViewFactories[new String(elementName)] = factory;
	}

	/// CONSUMES the setter delegate.
	public static void RegisterProperty(StringView elementName, StringView propertyName,
		PropertySetter setter)
	{
		let key = Key(elementName, propertyName, .. scope String());
		if (sViewProps.TryGetAlt(key, let existingKey, let existing))
		{
			delete existing;
			sViewProps[existingKey] = setter;
			return;
		}
		sViewProps[new String(key)] = setter;
	}

	/// Forgets every registration, the built-in guard included. For tests, which must not leak
	/// state into one another.
	public static void Clear()
	{
		using (sLock.Enter())
		{
			ClearLocked();
		}
	}

	private static void ClearLocked()
	{
		for (let pair in sViewFactories)
		{
			delete pair.key;
			delete pair.value;
		}
		sViewFactories.Clear();

		for (let pair in sViewProps)
		{
			delete pair.key;
			delete pair.value;
		}
		sViewProps.Clear();

		sBuiltinsRegistered = false;
	}

	// ---- Lookup -------------------------------------------------------------------------------

	/// A new view for an element name, or null when nothing is registered under it.
	/// OWNERSHIP transfers.
	public static View CreateView(StringView elementName)
	{
		if (sViewFactories.TryGetValueAlt(elementName, let factory))
			return factory();

		return null;
	}

	/// Writes an attribute, answering whether anything was registered to receive it.
	public static bool SetProperty(StringView elementName, View view, StringView propertyName,
		StringView value)
	{
		let key = Key(elementName, propertyName, .. scope String());
		if (sViewProps.TryGetValueAlt(key, let setter))
		{
			setter(view, value);
			return true;
		}
		return false;
	}

	public static bool IsRegistered(StringView elementName) =>
		sViewFactories.ContainsKeyAlt(elementName);

	public static int ElementCount => sViewFactories.Count;

	// ---- The layout vocabulary ------------------------------------------------------------

	/// The attributes that write a view's LayoutStyle.
	///
	/// ONE table feeds the loader, an editor's completion list and the tests, so they cannot
	/// drift apart.
	public static readonly StringView[] LayoutAttributeNames = new StringView[](
		"width", "height", "margin", "flex-grow", "flex-shrink", "align-self", "gravity", "dock",
		"left", "top", "right", "bottom", "position", "z-index", "min-width", "min-height",
		"max-width", "max-height", "flex-basis", "grid-row", "grid-column", "grid-row-span",
		"grid-column-span") ~ delete _;

	/// Applies one layout attribute, answering false when the name is not one of them, so the
	/// caller can try the element's own properties. A value that will not parse leaves the
	/// field as it was rather than zeroing it.
	public static bool ApplyLayoutAttribute(ref LayoutStyle layout, StringView name, StringView value)
	{
		switch (name)
		{
		case "width":
			layout.Width = ParseSizeSpec(value);
		case "height":
			layout.Height = ParseSizeSpec(value);
		case "margin":
			layout.Margin = ParseThickness(value);
		case "flex-grow":
			if (ParseFloatValue(value) case .Ok(let f))
				layout.FlexGrow = f;
		case "flex-shrink":
			if (ParseFloatValue(value) case .Ok(let f))
				layout.FlexShrink = f;
		case "align-self":
			layout.AlignSelf = ParseAlign(value);
		case "flex-basis":
			if (StyleValueParser.ParseLengthText(value) != null)
				layout.FlexBasis = StyleValueParser.ParseLengthText(value).Value;
		case "gravity":
			layout.Gravity = ParseGravity(value);
		case "dock":
			if (ParseDock(value) != null)
				layout.Dock = ParseDock(value).Value;
		case "left":
			if (ParseFloatValue(value) case .Ok(let f))
				layout.Left = f;
		case "top":
			if (ParseFloatValue(value) case .Ok(let f))
				layout.Top = f;
		case "right":
			if (ParseFloatValue(value) case .Ok(let f))
				layout.Right = f;
		case "bottom":
			if (ParseFloatValue(value) case .Ok(let f))
				layout.Bottom = f;
		case "position":
			if (value == "absolute")
				layout.Position = Position.Absolute;
			else if (value == "static")
				layout.Position = Position.Static;
		case "z-index":
			if (ParseIntValue(value) case .Ok(let i))
				layout.ZIndex = i;
		case "min-width", "min-height", "max-width", "max-height":
			ApplyLengthLimit(ref layout, name, value);
		case "grid-row":
			if (ParseIntValue(value) case .Ok(let i))
				layout.GridRow = i;
		case "grid-column":
			if (ParseIntValue(value) case .Ok(let i))
				layout.GridColumn = i;
		case "grid-row-span":
			if (ParseIntValue(value) case .Ok(let i))
				layout.GridRowSpan = i;
		case "grid-column-span":
			if (ParseIntValue(value) case .Ok(let i))
				layout.GridColumnSpan = i;
		default:
			return false;
		}

		return true;
	}

	private static void ApplyLengthLimit(ref LayoutStyle layout, StringView name, StringView value)
	{
		let length = StyleValueParser.ParseLengthText(value);
		if (length == null)
			return;

		switch (name)
		{
		case "min-width": layout.MinWidth = length.Value;
		case "min-height": layout.MinHeight = length.Value;
		case "max-width": layout.MaxWidth = length.Value;
		default: layout.MaxHeight = length.Value;
		}
	}

	// ---- Vocabularies, for editor completion ------------------------------------------------

	public static void CollectElementNames(List<String> outNames)
	{
		ClearAndDeleteItems!(outNames);
		for (let name in sViewFactories.Keys)
			outNames.Add(new String(name));
	}

	/// What can be written on an element: its own registered properties, plus the layout
	/// vocabulary, which is the same everywhere.
	public static void CollectAttributeNames(StringView elementName, List<String> outNames)
	{
		ClearAndDeleteItems!(outNames);

		for (let key in sViewProps.Keys)
		{
			if (SplitKey(key, let element, let property) && (element == elementName))
				PushUnique(outNames, property);
		}

		for (let name in LayoutAttributeNames)
			PushUnique(outNames, name);
	}

	private static void PushUnique(List<String> outNames, StringView name)
	{
		for (let existing in outNames)
		{
			if (existing == name)
				return;
		}
		outNames.Add(new String(name));
	}

	// ---- Value parsing ------------------------------------------------------------------------

	/// A size from markup: `wrap`, `match`, or a length such as 240, 16dp, 50%, 2em or a calc.
	/// Anything else wraps, which is the harmless reading.
	public static SizeSpec ParseSizeSpec(StringView value)
	{
		if (value == "wrap")
			return SizeSpec.Wrap();
		if (value == "match")
			return SizeSpec.Match();

		let length = StyleValueParser.ParseLengthText(value);
		if (length != null)
			return SizeSpec.Fixed(length.Value);

		return SizeSpec.Wrap();
	}

	/// Null when the value names no alignment, which leaves the field undeclared rather than
	/// forcing a default.
	public static Align? ParseAlign(StringView value)
	{
		switch (value)
		{
		case "start": return Align.Start;
		case "end": return Align.End;
		case "center": return Align.Center;
		case "stretch": return Align.Stretch;
		case "baseline": return Align.Baseline;
		default: return null;
		}
	}

	public static Dock? ParseDock(StringView value)
	{
		switch (value)
		{
		case "left": return Dock.Left;
		case "top": return Dock.Top;
		case "right": return Dock.Right;
		case "bottom": return Dock.Bottom;
		case "fill": return Dock.Fill;
		default: return null;
		}
	}

	/// Gravity is a SET, so the values are combined with a bar: `Bottom|Right`. The compound
	/// names are shorthands for the same thing.
	public static Gravity ParseGravity(StringView value)
	{
		var result = Gravity.None;

		for (let part in value.Split('|'))
		{
			var name = part;
			name.Trim();

			switch (name)
			{
			case "Left": result |= .Left;
			case "Right": result |= .Right;
			case "CenterH": result |= .CenterH;
			case "FillH": result |= .FillH;
			case "Top": result |= .Top;
			case "Bottom": result |= .Bottom;
			case "CenterV": result |= .CenterV;
			case "FillV": result |= .FillV;
			case "Center": result |= .Center;
			case "Fill": result |= .Fill;
			case "TopLeft": result |= .TopLeft;
			case "TopRight": result |= .TopRight;
			case "BottomLeft": result |= .BottomLeft;
			case "BottomRight": result |= .BottomRight;
			default:
			}
		}

		return result;
	}

	/// One value for all sides, two for vertical then horizontal, four for top, right, bottom,
	/// left. The CSS shorthand, and the same expansion the style sheets use.
	public static Thickness ParseThickness(StringView value)
	{
		float[4] values = .();
		var count = 0;

		for (let part in value.Split(' '))
		{
			if (count >= 4)
				break;

			var text = part;
			text.Trim();
			if (text.IsEmpty)
				continue;

			if (ParseFloatValue(text) case .Ok(let f))
				values[count++] = f;
		}

		return StyleValueParser.ParseThickness(Span<float>(&values[0], count));
	}

	// ---- Internals ----------------------------------------------------------------------------

	private static void Key(StringView element, StringView property, String outKey)
	{
		outKey.Append(element);
		outKey.Append(KeySeparator);
		outKey.Append(property);
	}

	private static bool SplitKey(StringView key, out StringView element, out StringView property)
	{
		element = default;
		property = default;

		let separator = key.IndexOf(KeySeparator);
		if (separator < 0)
			return false;

		element = key.Substring(0, separator);
		property = key.Substring(separator + 1);
		return true;
	}

	/// A float, or an error when the whole value is not one.
	private static Result<float> ParseFloatValue(StringView value)
	{
		if (double.Parse(value) case .Ok(let d))
			return .Ok((float)d);

		return .Err;
	}

	private static Result<int32> ParseIntValue(StringView value)
	{
		if (int32.Parse(value) case .Ok(let i))
			return .Ok(i);

		return .Err;
	}
}
