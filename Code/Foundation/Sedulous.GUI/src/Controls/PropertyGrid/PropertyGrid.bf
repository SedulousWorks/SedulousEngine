using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Fonts;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A property item in the PropertyGrid.
public class PropertyItem
{
	public String Name ~ delete _;
	public String Category ~ delete _;
	public String DisplayValue ~ delete _;
	public PropertyType Type;
	public delegate Object() Getter ~ delete _;
	public delegate void(Object) Setter ~ delete _;
	public List<String> EnumValues ~ DeleteContainerAndItems!(_);

	/// Cached editor control (owned by this item).
	public UIElement EditorControl ~ delete _;

	/// Back-reference to the owning PropertyGrid (non-owning).
	public PropertyGrid OwnerGrid;

	public this(StringView name, PropertyType type)
	{
		Name = new String(name);
		Category = new String("General");
		DisplayValue = new String();
		Type = type;
	}

	public void SetCategory(StringView category)
	{
		Category.Set(category);
	}

	/// Gets the current value from the getter (may return null).
	public Object GetValue()
	{
		if (Getter != null)
			return Getter();
		return null;
	}

	public void UpdateDisplayValue()
	{
		if (EditorControl != null) { RefreshEditorControl(); return; }

		DisplayValue.Clear();
		if (Getter != null)
		{
			let value = Getter();
			if (value != null)
			{
				value.ToString(DisplayValue);
				// Getter always returns owned values - caller is responsible for cleanup
				delete value;
			}
		}
	}

	/// Virtual factory - return null to use built-in procedural rendering.
	public virtual UIElement CreateEditorControl() => null;

	/// Called by RefreshValues() to push getter data into the editor.
	public virtual void RefreshEditorControl() {}
}

/// Property types for PropertyGrid.
public enum PropertyType
{
	String,
	Int,
	Float,
	Bool,
	Enum,
	Color
}

/// A collapsible category in the PropertyGrid.
public class PropertyCategory
{
	public String Name ~ delete _;
	public bool IsExpanded = true;
	public List<PropertyItem> Properties = new .() ~ delete _;  // Not owned

	public this(StringView name)
	{
		Name = new String(name);
	}
}

/// A control for editing object properties with category grouping.
public class PropertyGrid : Control
{
	/// Fallback ratio for estimating character width when no font metrics available.
	private const float FallbackCharWidthRatio = 0.6f;

	// Properties organized by category
	private List<PropertyItem> mProperties = new .() ~ DeleteContainerAndItems!(_);
	private List<PropertyCategory> mCategories = new .() ~ DeleteContainerAndItems!(_);

	// Non-owning cache of editor controls (rebuilt by RebuildCategories)
	private List<UIElement> mEditorControls = new .() ~ delete _;

	// Layout
	private float mRowHeight = 22;
	private float mNameColumnWidth = 120;
	private float mCategoryHeight = 24;
	private float mVerticalOffset = 0;
	private float mSplitterWidth = 4;

	// Batch update (suspends RebuildCategories during bulk adds)
	private bool mIsBatchUpdate = false;

	// State
	private int mHoveredPropertyIndex = -1;
	private int mHoveredCategoryIndex = -1;
	private bool mIsEditingProperty = false;
	private int mEditingPropertyIndex = -1;
	private String mEditBuffer = new .() ~ delete _;

	// Splitter drag
	private bool mIsDraggingSplitter = false;
	private float mDragStartX = 0;
	private float mDragStartWidth = 0;

	// Scrollbar
	private ScrollBar mVerticalScrollBar ~ delete _;
	private bool mShowScrollBar = false;
	private float mScrollBarThickness = 12;

	// Image support
	private ImageBrush? mGridBackgroundImage;
	private ImageBrush? mCategoryImage;
	private ImageBrush? mCategoryHoverImage;
	private ImageBrush? mPropertyImage;
	private ImageBrush? mPropertyHoverImage;

	// Theme colors (computed from palette)
	private Color mBackgroundColor;
	private Color mBorderColor;
	private Color mSplitterColor;
	private Color mCategoryBackgroundColor;
	private Color mCategoryHoverColor;
	private Color mCategoryTextColor;
	private Color mCategoryIndicatorColor;
	private Color mCategoryBorderColor;
	private Color mPropertyBackgroundColor;
	private Color mPropertyHoverColor;
	private Color mPropertyNameColor;
	private Color mPropertyValueColor;
	private Color mPropertyBorderColor;
	private Color mCursorColor;
	private Color mCheckboxBackgroundColor;
	private Color mCheckboxBorderColor;
	private Color mCheckmarkColor;
	private Color mDropdownArrowColor;

	// Events
	private EventAccessor<delegate void(PropertyGrid, PropertyItem)> mPropertyChanged = new .() ~ delete _;

	/// Creates a new PropertyGrid.
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;

		mVerticalScrollBar = new ScrollBar(.Vertical);
		mVerticalScrollBar.Thickness = mScrollBarThickness;
		mVerticalScrollBar.SetParent(this);
		mVerticalScrollBar.Scroll.Subscribe(new (sb, value) => {
			mVerticalOffset = value;
			InvalidateLayout();
		});
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "PropertyGrid";

	/// Row height for properties.
	public float RowHeight
	{
		get => mRowHeight;
		set { mRowHeight = value; InvalidateLayout(); }
	}

	/// Name column width.
	public float NameColumnWidth
	{
		get => mNameColumnWidth;
		set { mNameColumnWidth = Math.Max(50, value); InvalidateLayout(); }
	}

	/// Image for the grid background (replaces background fill + border).
	public ImageBrush? GridBackgroundImage
	{
		get => mGridBackgroundImage;
		set => mGridBackgroundImage = value;
	}

	/// Image for category header backgrounds.
	public ImageBrush? CategoryImage
	{
		get => mCategoryImage;
		set => mCategoryImage = value;
	}

	/// Image for hovered category header backgrounds.
	public ImageBrush? CategoryHoverImage
	{
		get => mCategoryHoverImage;
		set => mCategoryHoverImage = value;
	}

	/// Image for property row backgrounds.
	public ImageBrush? PropertyImage
	{
		get => mPropertyImage;
		set => mPropertyImage = value;
	}

	/// Image for hovered property row backgrounds.
	public ImageBrush? PropertyHoverImage
	{
		get => mPropertyHoverImage;
		set => mPropertyHoverImage = value;
	}

	/// Event fired when a property value changes.
	public EventAccessor<delegate void(PropertyGrid, PropertyItem)> PropertyChanged => mPropertyChanged;

	/// Gets the name of the currently hovered category, or null if none.
	public StringView? HoveredCategoryName
	{
		get
		{
			if (mHoveredCategoryIndex >= 0 && mHoveredCategoryIndex < mCategories.Count)
				return mCategories[mHoveredCategoryIndex].Name;
			return null;
		}
	}

	/// Adds a property to the grid.
	public PropertyItem AddProperty(StringView name, PropertyType type, StringView category = "General")
	{
		let prop = new PropertyItem(name, type);
		prop.SetCategory(category);
		mProperties.Add(prop);
		RebuildCategories();
		return prop;
	}

	/// Adds a string property with getter/setter.
	public PropertyItem AddStringProperty(StringView name, StringView category, delegate Object() getter, delegate void(Object) setter)
	{
		let prop = AddProperty(name, .String, category);
		prop.Getter = getter;
		prop.Setter = setter;
		prop.UpdateDisplayValue();
		return prop;
	}

	/// Adds an int property with getter/setter.
	public PropertyItem AddIntProperty(StringView name, StringView category, delegate Object() getter, delegate void(Object) setter)
	{
		let prop = AddProperty(name, .Int, category);
		prop.Getter = getter;
		prop.Setter = setter;
		prop.UpdateDisplayValue();
		return prop;
	}

	/// Adds a float property with getter/setter.
	public PropertyItem AddFloatProperty(StringView name, StringView category, delegate Object() getter, delegate void(Object) setter)
	{
		let prop = AddProperty(name, .Float, category);
		prop.Getter = getter;
		prop.Setter = setter;
		prop.UpdateDisplayValue();
		return prop;
	}

	/// Adds a bool property with getter/setter.
	public PropertyItem AddBoolProperty(StringView name, StringView category, delegate Object() getter, delegate void(Object) setter)
	{
		let prop = AddProperty(name, .Bool, category);
		prop.Getter = getter;
		prop.Setter = setter;
		prop.UpdateDisplayValue();
		return prop;
	}

	/// Adds an enum property with options.
	public PropertyItem AddEnumProperty(StringView name, StringView category, Span<StringView> options, delegate Object() getter, delegate void(Object) setter)
	{
		let prop = AddProperty(name, .Enum, category);
		prop.Getter = getter;
		prop.Setter = setter;
		prop.EnumValues = new .();
		for (let opt in options)
			prop.EnumValues.Add(new String(opt));
		prop.UpdateDisplayValue();
		return prop;
	}

	/// Public method for custom property items to notify value changes.
	public void NotifyPropertyChanged(PropertyItem item)
	{
		mPropertyChanged.[Friend]Invoke(this, item);
	}

	/// Adds a pre-constructed PropertyItem (transfers ownership).
	public void AddItem(PropertyItem item)
	{
		item.OwnerGrid = this;
		let ctrl = item.CreateEditorControl();
		if (ctrl != null)
		{
			item.EditorControl = ctrl;
			ctrl.SetParent(this);
			if (Context != null)
				ctrl.OnAttachedToContext(Context);
		}
		mProperties.Add(item);
		RebuildCategories();
	}

	/// Clears all properties.
	public void Clear()
	{
		for (let prop in mProperties)
			if (prop.EditorControl != null && Context != null)
				prop.EditorControl.OnDetachedFromContext();
		mEditorControls.Clear();
		DeleteContainerAndItems!(mProperties);
		mProperties = new .();
		DeleteContainerAndItems!(mCategories);
		mCategories = new .();
		mHoveredPropertyIndex = -1;
		mHoveredCategoryIndex = -1;
		InvalidateLayout();
	}

	/// Suspends category rebuilds during bulk property additions.
	public void BeginUpdate()
	{
		mIsBatchUpdate = true;
	}

	/// Resumes category rebuilds and performs a single rebuild.
	public void EndUpdate()
	{
		mIsBatchUpdate = false;
		RebuildCategories();
	}

	/// Refreshes all property values from their getters.
	public void RefreshValues()
	{
		for (let prop in mProperties)
			prop.UpdateDisplayValue();
	}

	/// Rebuilds the category structure.
	private void RebuildCategories()
	{
		if (mIsBatchUpdate)
			return;

		DeleteContainerAndItems!(mCategories);
		mCategories = new .();

		Dictionary<String, PropertyCategory> categoryMap = scope .();

		for (let prop in mProperties)
		{
			if (!categoryMap.TryGetValue(prop.Category, var category))
			{
				category = new PropertyCategory(prop.Category);
				mCategories.Add(category);
				categoryMap[prop.Category] = category;
			}
			category.Properties.Add(prop);
		}

		// Rebuild editor control cache
		mEditorControls.Clear();
		for (let prop in mProperties)
			if (prop.EditorControl != null)
				mEditorControls.Add(prop.EditorControl);

		InvalidateLayout();
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mVerticalScrollBar.OnAttachedToContext(context);
		for (let ctrl in mEditorControls)
			ctrl.OnAttachedToContext(context);
	}

	/// Gets current theme colors for rendering (called each frame to support theme changes).
	private void GetThemeColors(
		out Color backgroundColor, out Color borderColor, out Color splitterColor,
		out Color categoryBgColor, out Color categoryHoverColor, out Color categoryTextColor,
		out Color categoryIndicatorColor, out Color categoryBorderColor,
		out Color propertyBgColor, out Color propertyHoverColor, out Color propertyNameColor,
		out Color propertyValueColor, out Color propertyBorderColor, out Color cursorColor,
		out Color checkboxBgColor, out Color checkboxBorderColor, out Color checkmarkColor,
		out Color dropdownArrowColor)
	{
		let theme = Context?.Theme;
		let palette = theme?.Palette ?? Palette();

		// Get theme styles
		let gridStyle = theme?.GetControlStyle("PropertyGrid") ?? ControlStyle();
		let categoryStyle = theme?.GetControlStyle("PropertyGridCategory") ?? ControlStyle();
		let propertyStyle = theme?.GetControlStyle("PropertyGridProperty") ?? ControlStyle();

		// Fallback colors
		let defaultBgColor = Color(35, 35, 35, 255);
		let defaultTextColor = Color(220, 220, 220, 255);
		let defaultBorderColor = Color(60, 60, 60, 255);
		let defaultSuccessColor = Color(100, 180, 100, 255);

		// Main background and border from theme style
		backgroundColor = gridStyle.Background.A > 0 ? gridStyle.Background : defaultBgColor;
		borderColor = gridStyle.BorderColor.A > 0 ? gridStyle.BorderColor : defaultBorderColor;
		splitterColor = Palette.Lighten(backgroundColor, 0.05f);

		// Category colors from theme style
		categoryBgColor = categoryStyle.Background.A > 0 ? categoryStyle.Background : Palette.Lighten(backgroundColor, 0.1f);
		categoryHoverColor = categoryStyle.Hover.Background ?? Palette.ComputeHover(categoryBgColor);
		let categoryFg = categoryStyle.Foreground.A > 0 ? categoryStyle.Foreground : (palette.Text.A > 0 ? palette.Text : defaultTextColor);
		categoryTextColor = categoryFg;
		categoryIndicatorColor = Palette.Darken(categoryFg, 0.15f);
		categoryBorderColor = categoryStyle.BorderColor.A > 0 ? categoryStyle.BorderColor : Palette.Lighten(backgroundColor, 0.08f);

		// Property colors from theme style
		propertyBgColor = propertyStyle.Background.A > 0 ? propertyStyle.Background : Palette.Darken(categoryBgColor, 0.05f);
		propertyHoverColor = propertyStyle.Hover.Background ?? Palette.ComputeHover(propertyBgColor);
		let propertyFg = propertyStyle.Foreground.A > 0 ? propertyStyle.Foreground : (palette.Text.A > 0 ? palette.Text : defaultTextColor);
		propertyNameColor = Palette.Darken(propertyFg, 0.15f);
		propertyValueColor = propertyFg;
		propertyBorderColor = propertyStyle.BorderColor.A > 0 ? propertyStyle.BorderColor : categoryBgColor;
		cursorColor = propertyFg;

		// Checkbox colors
		checkboxBgColor = Palette.Darken(propertyBgColor, 0.03f);
		checkboxBorderColor = borderColor;
		checkmarkColor = palette.Success.A > 0 ? palette.Success : defaultSuccessColor;

		// Dropdown arrow
		dropdownArrowColor = Palette.Darken(propertyFg, 0.25f);
	}

	public override void OnDetachedFromContext()
	{
		for (let ctrl in mEditorControls)
			ctrl.OnDetachedFromContext();
		mVerticalScrollBar.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Font Service ===

	private IFontService GetFontService()
	{
		if (Context != null)
		{
			if (Context.GetService<IFontService>() case .Ok(let service))
				return service;
		}
		return null;
	}

	private CachedFont GetCachedFont(float fontSize)
	{
		let fontService = GetFontService();
		if (fontService == null)
			return null;
		return fontService.GetFont(fontSize);
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		mVerticalScrollBar.Measure(constraints);
		float totalHeight = CalculateTotalHeight();
		return .(200, totalHeight);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		float totalHeight = CalculateTotalHeight();
		float viewportHeight = contentBounds.Height;

		mShowScrollBar = totalHeight > viewportHeight;

		if (mShowScrollBar)
		{
			mVerticalScrollBar.Arrange(.(
				contentBounds.Right - mScrollBarThickness,
				contentBounds.Y,
				mScrollBarThickness,
				contentBounds.Height
			));
			// Maximum should be total content size, not scrollable range
			mVerticalScrollBar.Maximum = totalHeight;
			mVerticalScrollBar.ViewportSize = viewportHeight;
			mVerticalScrollBar.Value = mVerticalOffset;
		}

		mVerticalOffset = Math.Clamp(mVerticalOffset, 0, Math.Max(0, totalHeight - viewportHeight));

		ArrangeEditorControls(contentBounds);
	}

	/// Positions editor controls at their value column rects.
	private void ArrangeEditorControls(RectangleF contentBounds)
	{
		if (mEditorControls.Count == 0) return;

		float contentWidth = contentBounds.Width;
		if (mShowScrollBar) contentWidth -= mScrollBarThickness;

		float y = contentBounds.Y - mVerticalOffset;

		for (let cat in mCategories)
		{
			y += mCategoryHeight;

			if (cat.IsExpanded)
			{
				for (let prop in cat.Properties)
				{
					if (prop.EditorControl != null)
					{
						let valueBounds = RectangleF(
							contentBounds.X + mNameColumnWidth + 2,
							y + 1,
							contentWidth - mNameColumnWidth - 4,
							mRowHeight - 2
						);
						prop.EditorControl.Measure(SizeConstraints.Exact(valueBounds.Width, valueBounds.Height));
						prop.EditorControl.Arrange(valueBounds);
					}
					y += mRowHeight;
				}
			}
			else
			{
				for (let prop in cat.Properties)
				{
					if (prop.EditorControl != null)
						prop.EditorControl.Arrange(.(0, 0, 0, 0));
				}
			}
		}
	}

	private float CalculateTotalHeight()
	{
		float height = 0;
		for (let cat in mCategories)
		{
			height += mCategoryHeight;  // Category header
			if (cat.IsExpanded)
				height += cat.Properties.Count * mRowHeight;
		}
		return height;
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		// Get current theme colors
		GetThemeColors(
			out mBackgroundColor, out mBorderColor, out mSplitterColor,
			out mCategoryBackgroundColor, out mCategoryHoverColor, out mCategoryTextColor,
			out mCategoryIndicatorColor, out mCategoryBorderColor,
			out mPropertyBackgroundColor, out mPropertyHoverColor, out mPropertyNameColor,
			out mPropertyValueColor, out mPropertyBorderColor, out mCursorColor,
			out mCheckboxBackgroundColor, out mCheckboxBorderColor, out mCheckmarkColor,
			out mDropdownArrowColor);

		let bounds = ArrangedBounds;
		float contentWidth = bounds.Width;
		if (mShowScrollBar) contentWidth -= mScrollBarThickness;

		// Background
		if (mGridBackgroundImage.HasValue && mGridBackgroundImage.Value.IsValid)
			ctx.DrawImageBrush(mGridBackgroundImage.Value, bounds);
		else
			ctx.FillRect(bounds, mBackgroundColor);

		// Clip content
		let contentBounds = RectangleF(bounds.X, bounds.Y, contentWidth, bounds.Height);
		ctx.PushClipRect(contentBounds);

		float y = bounds.Y - mVerticalOffset;
		int globalPropertyIndex = 0;

		for (int catIdx = 0; catIdx < mCategories.Count; catIdx++)
		{
			let cat = mCategories[catIdx];

			// Category header
			let catBounds = RectangleF(bounds.X, y, contentWidth, mCategoryHeight);
			if (catBounds.Bottom > bounds.Y && catBounds.Y < bounds.Bottom)
				RenderCategory(ctx, catBounds, cat, catIdx == mHoveredCategoryIndex);
			y += mCategoryHeight;

			// Properties
			if (cat.IsExpanded)
			{
				for (int i = 0; i < cat.Properties.Count; i++)
				{
					let prop = cat.Properties[i];
					let propBounds = RectangleF(bounds.X, y, contentWidth, mRowHeight);

					if (propBounds.Bottom > bounds.Y && propBounds.Y < bounds.Bottom)
					{
						let isHovered = globalPropertyIndex == mHoveredPropertyIndex;
						let isEditing = globalPropertyIndex == mEditingPropertyIndex;
						RenderProperty(ctx, propBounds, prop, isHovered, isEditing);
					}

					y += mRowHeight;
					globalPropertyIndex++;
				}
			}
			else
			{
				globalPropertyIndex += cat.Properties.Count;
			}
		}

		ctx.PopClip();

		// Splitter line
		let splitterX = bounds.X + mNameColumnWidth;
		ctx.DrawLine(.(splitterX, bounds.Y), .(splitterX, bounds.Bottom), mSplitterColor, 1);

		// Scrollbar
		if (mShowScrollBar)
			mVerticalScrollBar.Render(ctx);

		// Border (skip when using grid background image)
		if (!mGridBackgroundImage.HasValue || !mGridBackgroundImage.Value.IsValid)
			ctx.DrawRect(bounds, mBorderColor, 1);
	}

	private void RenderCategory(DrawContext ctx, RectangleF bounds, PropertyCategory category, bool isHovered)
	{
		// Background
		let hoverImg = isHovered ? mCategoryHoverImage : (ImageBrush?)null;
		let normalImg = mCategoryImage;
		let catImage = hoverImg.HasValue && hoverImg.Value.IsValid ? hoverImg : normalImg;
		if (catImage.HasValue && catImage.Value.IsValid)
		{
			var img = catImage.Value;
			if (isHovered && (!mCategoryHoverImage.HasValue || !mCategoryHoverImage.Value.IsValid))
				img.Tint = Palette.Lighten(img.Tint, 0.10f);
			ctx.DrawImageBrush(img, bounds);
		}
		else
		{
			let bgColor = isHovered ? mCategoryHoverColor : mCategoryBackgroundColor;
			ctx.FillRect(bounds, bgColor);
		}

		// Clip text to name column width so it doesn't extend past splitter
		let textClipBounds = RectangleF(bounds.X, bounds.Y, mNameColumnWidth, bounds.Height);
		ctx.PushClipRect(textClipBounds);

		// Expand/collapse indicator
		let indicator = category.IsExpanded ? "▼" : "►";
		ctx.DrawText(indicator, 10, .(bounds.X + 6, bounds.Y + (mCategoryHeight - 10) / 2), mCategoryIndicatorColor);

		// Category name
		ctx.DrawText(category.Name, 12, .(bounds.X + 20, bounds.Y + (mCategoryHeight - 12) / 2), mCategoryTextColor);

		ctx.PopClip();

		// Bottom border
		ctx.DrawLine(.(bounds.X, bounds.Bottom - 1), .(bounds.Right, bounds.Bottom - 1), mCategoryBorderColor, 1);
	}

	private void RenderProperty(DrawContext ctx, RectangleF bounds, PropertyItem prop, bool isHovered, bool isEditing)
	{
		// Background
		let hoverImg = isHovered ? mPropertyHoverImage : (ImageBrush?)null;
		let normalImg = mPropertyImage;
		let propImage = hoverImg.HasValue && hoverImg.Value.IsValid ? hoverImg : normalImg;
		if (propImage.HasValue && propImage.Value.IsValid)
		{
			var img = propImage.Value;
			if (isHovered && (!mPropertyHoverImage.HasValue || !mPropertyHoverImage.Value.IsValid))
				img.Tint = Palette.Lighten(img.Tint, 0.10f);
			ctx.DrawImageBrush(img, bounds);
		}
		else
		{
			let bgColor = isHovered ? mPropertyHoverColor : mPropertyBackgroundColor;
			ctx.FillRect(bounds, bgColor);
		}

		// Property name
		let nameBounds = RectangleF(bounds.X, bounds.Y, mNameColumnWidth, mRowHeight);
		ctx.PushClipRect(nameBounds);
		ctx.DrawText(prop.Name, 12, .(bounds.X + 8, bounds.Y + (mRowHeight - 12) / 2), mPropertyNameColor);
		ctx.PopClip();

		if (prop.EditorControl != null)
		{
			// Custom editor renders at its arranged position
			prop.EditorControl.Render(ctx);
		}
		else
		{
			// Property value (built-in procedural rendering)
			let valueBounds = RectangleF(bounds.X + mNameColumnWidth + 4, bounds.Y, bounds.Width - mNameColumnWidth - 4, mRowHeight);
			RenderPropertyValue(ctx, valueBounds, prop, isEditing);
		}

		// Bottom border
		ctx.DrawLine(.(bounds.X, bounds.Bottom - 1), .(bounds.Right, bounds.Bottom - 1), mPropertyBorderColor, 1);
	}

	private void RenderPropertyValue(DrawContext ctx, RectangleF bounds, PropertyItem prop, bool isEditing)
	{
		switch (prop.Type)
		{
		case .Bool:
			RenderBoolValue(ctx, bounds, prop);
		case .Enum:
			RenderEnumValue(ctx, bounds, prop);
		default:
			RenderTextValue(ctx, bounds, prop, isEditing);
		}
	}

	private void RenderTextValue(DrawContext ctx, RectangleF bounds, PropertyItem prop, bool isEditing)
	{
		let text = isEditing ? mEditBuffer : prop.DisplayValue;
		let fontSize = 12.0f;
		ctx.DrawText(text, fontSize, .(bounds.X, bounds.Y + (mRowHeight - fontSize) / 2), mPropertyValueColor);

		if (isEditing)
		{
			// Cursor position using font measurement
			let cachedFont = GetCachedFont(fontSize);
			let textWidth = cachedFont?.Font.MeasureString(text) ?? (text.Length * fontSize * FallbackCharWidthRatio);
			let cursorX = bounds.X + textWidth;
			ctx.DrawLine(.(cursorX, bounds.Y + 3), .(cursorX, bounds.Bottom - 3), mCursorColor, 1);
		}
	}

	private void RenderBoolValue(DrawContext ctx, RectangleF bounds, PropertyItem prop)
	{
		bool isChecked = false;
		let value = prop.GetValue();
		if (let b = value as bool?)
			isChecked = b;
		// Delete boxed value
		if (value != null && !(value is String))
			delete value;

		// Checkbox
		let checkSize = 14.0f;
		let checkX = bounds.X;
		let checkY = bounds.Y + (mRowHeight - checkSize) / 2;
		let checkBounds = RectangleF(checkX, checkY, checkSize, checkSize);

		ctx.FillRect(checkBounds, mCheckboxBackgroundColor);
		ctx.DrawRect(checkBounds, mCheckboxBorderColor, 1);

		if (isChecked)
		{
			let cx = checkBounds.X + checkBounds.Width / 2;
			let cy = checkBounds.Y + checkBounds.Height / 2;
			ctx.DrawLine(.(cx - 4, cy), .(cx - 1, cy + 3), mCheckmarkColor, 2);
			ctx.DrawLine(.(cx - 1, cy + 3), .(cx + 4, cy - 3), mCheckmarkColor, 2);
		}
	}

	private void RenderEnumValue(DrawContext ctx, RectangleF bounds, PropertyItem prop)
	{
		// Current value with dropdown indicator
		let text = prop.DisplayValue;
		ctx.DrawText(text, 12, .(bounds.X, bounds.Y + (mRowHeight - 12) / 2), mPropertyValueColor);

		// Dropdown arrow
		ctx.DrawText("▼", 8, .(bounds.Right - 16, bounds.Y + (mRowHeight - 8) / 2), mDropdownArrowColor);
	}

	// === Input ===

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		let point = Vector2(e.ScreenX, e.ScreenY);
		let bounds = ArrangedBounds;

		if (mIsDraggingSplitter)
		{
			let delta = point.X - mDragStartX;
			// Clamp splitter to stay within bounds (min 50px name column, min 50px value column)
			let maxWidth = bounds.Width - mScrollBarThickness - 50;
			mNameColumnWidth = Math.Clamp(mDragStartWidth + delta, 50, maxWidth);
			InvalidateLayout();
			return;
		}

		// Check splitter hover
		let splitterX = bounds.X + mNameColumnWidth;
		if (Math.Abs(point.X - splitterX) < mSplitterWidth)
		{
			// TODO: Change cursor to resize
			mHoveredPropertyIndex = -1;
			mHoveredCategoryIndex = -1;
			return;
		}

		// Find hovered item
		mHoveredPropertyIndex = -1;
		mHoveredCategoryIndex = -1;

		float y = bounds.Y - mVerticalOffset;
		int globalPropertyIndex = 0;

		for (int catIdx = 0; catIdx < mCategories.Count; catIdx++)
		{
			let cat = mCategories[catIdx];

			// Category header
			if (point.Y >= y && point.Y < y + mCategoryHeight)
			{
				mHoveredCategoryIndex = catIdx;
				return;
			}
			y += mCategoryHeight;

			// Properties
			if (cat.IsExpanded)
			{
				for (int i = 0; i < cat.Properties.Count; i++)
				{
					if (point.Y >= y && point.Y < y + mRowHeight)
					{
						mHoveredPropertyIndex = globalPropertyIndex;
						return;
					}
					y += mRowHeight;
					globalPropertyIndex++;
				}
			}
			else
			{
				globalPropertyIndex += cat.Properties.Count;
			}
		}
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		mHoveredPropertyIndex = -1;
		mHoveredCategoryIndex = -1;
	}

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button != .Left)
			return;

		let point = Vector2(e.ScreenX, e.ScreenY);
		let bounds = ArrangedBounds;

		// Check splitter click
		let splitterX = bounds.X + mNameColumnWidth;
		if (Math.Abs(point.X - splitterX) < mSplitterWidth)
		{
			mIsDraggingSplitter = true;
			mDragStartX = point.X;
			mDragStartWidth = mNameColumnWidth;
			if (Context != null)
				Context.FocusManager?.SetCapture(this);
			e.Handled = true;
			return;
		}

		// Category click
		if (mHoveredCategoryIndex >= 0)
		{
			let cat = mCategories[mHoveredCategoryIndex];
			cat.IsExpanded = !cat.IsExpanded;
			InvalidateLayout();
			e.Handled = true;
			return;
		}

		// Property click (skip properties with custom editors)
		if (mHoveredPropertyIndex >= 0)
		{
			let prop = GetPropertyByGlobalIndex(mHoveredPropertyIndex);
			if (prop != null && prop.EditorControl == null)
			{
				HandlePropertyClick(prop, point);
			}
			e.Handled = true;
		}
	}

	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		base.OnMouseUp(e);

		if (mIsDraggingSplitter)
		{
			mIsDraggingSplitter = false;
			if (Context != null)
				Context.FocusManager?.ReleaseCapture();
		}
	}

	protected override void OnMouseWheel(MouseWheelEventArgs e)
	{
		base.OnMouseWheel(e);

		let scrollAmount = mRowHeight * 3;
		mVerticalOffset -= e.DeltaY * scrollAmount;

		float totalHeight = CalculateTotalHeight();
		float viewportHeight = ArrangedBounds.Height;
		mVerticalOffset = Math.Clamp(mVerticalOffset, 0, Math.Max(0, totalHeight - viewportHeight));

		InvalidateLayout();
		e.Handled = true;
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (mIsEditingProperty)
		{
			switch (e.Key)
			{
			case .Return:
				CommitEdit();
				e.Handled = true;
			case .Escape:
				CancelEdit();
				e.Handled = true;
			case .Backspace:
				if (mEditBuffer.Length > 0)
					mEditBuffer.RemoveFromEnd(1);
				e.Handled = true;
			default:
			}
		}
	}

	protected override void OnTextInput(TextInputEventArgs e)
	{
		base.OnTextInput(e);

		if (mIsEditingProperty && e.Character != '\0')
		{
			mEditBuffer.Append(e.Character);
			e.Handled = true;
		}
	}

	private PropertyItem GetPropertyByGlobalIndex(int globalIndex)
	{
		int idx = 0;
		for (let cat in mCategories)
		{
			if (!cat.IsExpanded)
			{
				idx += cat.Properties.Count;
				continue;
			}
			for (let prop in cat.Properties)
			{
				if (idx == globalIndex)
					return prop;
				idx++;
			}
		}
		return null;
	}

	private void HandlePropertyClick(PropertyItem prop, Vector2 point)
	{
		let bounds = ArrangedBounds;
		let valueX = bounds.X + mNameColumnWidth;

		// Only handle clicks in value area
		if (point.X < valueX)
			return;

		switch (prop.Type)
		{
		case .Bool:
			// Toggle bool
			bool current = false;
			let boolValue = prop.GetValue();
			if (let b = boolValue as bool?)
				current = b;
			// Delete boxed value from getter
			if (boolValue != null && !(boolValue is String))
				delete boolValue;
			if (prop.Setter != null)
			{
				let newValue = new box !current;
				prop.Setter(newValue);
				delete newValue;
			}
			prop.UpdateDisplayValue();
			mPropertyChanged.[Friend]Invoke(this, prop);

		case .Enum:
			// Cycle to next enum value
			if (prop.EnumValues != null && prop.EnumValues.Count > 0)
			{
				int currentIdx = -1;
				for (int i = 0; i < prop.EnumValues.Count; i++)
				{
					if (prop.DisplayValue == prop.EnumValues[i])
					{
						currentIdx = i;
						break;
					}
				}
				int nextIdx = (currentIdx + 1) % prop.EnumValues.Count;
				if (prop.Setter != null)
					prop.Setter(prop.EnumValues[nextIdx]);
				prop.UpdateDisplayValue();
				mPropertyChanged.[Friend]Invoke(this, prop);
			}

		default:
			// Start text editing
			mIsEditingProperty = true;
			mEditingPropertyIndex = mHoveredPropertyIndex;
			mEditBuffer.Set(prop.DisplayValue);
			Context?.FocusManager?.SetFocus(this);
		}
	}

	private void CommitEdit()
	{
		if (!mIsEditingProperty) return;

		let prop = GetPropertyByGlobalIndex(mEditingPropertyIndex);
		if (prop != null && prop.Setter != null)
		{
			// Parse and set value based on type
			switch (prop.Type)
			{
			case .Int:
				if (int.Parse(mEditBuffer) case .Ok(let val))
				{
					let boxed = new box val;
					prop.Setter(boxed);
					delete boxed;
				}
			case .Float:
				if (float.Parse(mEditBuffer) case .Ok(let val))
				{
					let boxed = new box val;
					prop.Setter(boxed);
					delete boxed;
				}
			case .String:
				let str = new String(mEditBuffer);
				prop.Setter(str);
				delete str;
			default:
			}

			prop.UpdateDisplayValue();
			mPropertyChanged.[Friend]Invoke(this, prop);
		}

		mIsEditingProperty = false;
		mEditingPropertyIndex = -1;
	}

	private void CancelEdit()
	{
		mIsEditingProperty = false;
		mEditingPropertyIndex = -1;
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;
		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		if (mShowScrollBar)
		{
			let hit = mVerticalScrollBar.HitTest(point);
			if (hit != null) return hit;
		}

		// Delegate to editor controls
		for (let ctrl in mEditorControls)
		{
			let hit = ctrl.HitTest(point);
			if (hit != null) return hit;
		}

		return this;
	}

	// === Visual Children ===

	public override int VisualChildCount => 1 + mEditorControls.Count;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0) return mVerticalScrollBar;
		let i = index - 1;
		if (i < mEditorControls.Count) return mEditorControls[i];
		return null;
	}
}
