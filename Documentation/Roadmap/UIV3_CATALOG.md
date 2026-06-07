# Sedulous.GUI - Control & Infrastructure Catalog

Companion to `UIV3.md`. Definitive property catalog for the clean-slate
framework. Every property listed here becomes `Property<T>` in
Sedulous.GUI unless marked otherwise.

Legend:
- **P** = becomes `Property<T>` (settable, observable, markup-targetable)
- **E** = `Event<delegate>` (event, markup-targetable via `on-*`)
- **R** = read-only computed (no Property<T>, just a getter)
- **I** = internal/not markup-targetable (ViewId, backing state)
- **C** = constructor parameter

---

## 1. Core View Hierarchy

### View (base)

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Id | ViewId | I | auto | Immutable, auto-allocated |
| Handle | ViewHandle | I | auto | Indirection for safe external refs; Handle.View nulled on delete |
| Name | String? | P | null | CSS `id` equivalent, unique per context |
| StyleClasses | List\<String\> | P | empty | CSS classes. Helpers: AddClass, RemoveClass, HasClass, ToggleClass, SetClasses |
| Visibility | Visibility | P | .Visible | Visible, Hidden, Gone |
| Opacity | float | P | 1.0 | 0-1, composes multiplicatively at draw time |
| Transform | ViewTransform | P | .Identity | Post-layout translation/scale/rotation |
| ClipsContent | bool | P | false | Clip children to bounds |
| IsEnabled | bool | P | true | Interaction enabled |
| IsInteractionEnabled | bool | P | true | Subtree input blocking |
| IsHitTestVisible | bool | P | true | Participates in hit-test |
| IsFocusable | bool | P | false | Can receive keyboard focus |
| IsTabStop | bool | P | false | Participates in Tab navigation |
| TabIndex | int32 | P | 0 | Tab order (0 = tree order) |
| Cursor | CursorType | P | .Default | Mouse cursor |
| TooltipText | String? | P | null | Hover tooltip |
| TooltipPlacement | TooltipPlacement | P | .Bottom | Tooltip position |
| IsTooltipInteractive | bool | P | false | Tooltip stays on hover |
| NextFocusUp | ViewId? | I | null | Directional focus override |
| NextFocusDown | ViewId? | I | null | Directional focus override |
| NextFocusLeft | ViewId? | I | null | Directional focus override |
| NextFocusRight | ViewId? | I | null | Directional focus override |
| WantsArrowKeys | bool | I | false | EditText overrides to true |
| MeasuredSize | Vector2 | R | - | Output of OnMeasure |
| Bounds | RectangleF | R | - | Output of OnLayout |
| Width | float | R | - | Bounds.Width |
| Height | float | R | - | Bounds.Height |
| Parent | View? | R | - | Parent view |
| Context | UIContext? | R | - | Attached context |
| IsAttached | bool | R | - | Context != null |
| IsHovered | bool | R | - | InputManager check |
| IsFocused | bool | R | - | FocusManager check |
| IsFocusWithin | bool | R | - | Descendant has focus |
| IsEffectivelyEnabled | bool | R | - | Walks parent chain |
| EffectiveCursor | CursorType | R | - | Walks parent chain |
| Root | RootView? | R | - | Walks parent chain |

**Virtual methods:** OnMeasure, OnLayout, OnDraw, GetBaseline,
GetControlState, HitTest, OnActivate, OnCancel

**Input virtuals (bubble):** OnMouseDown, OnMouseUp, OnMouseMove,
OnMouseWheel, OnMouseEnter, OnMouseLeave, OnKeyDown, OnKeyUp,
OnTextInput, OnFocusGained, OnFocusLost

**Input virtuals (capture):** OnMouseDownCapture, OnMouseUpCapture,
OnMouseMoveCapture, OnMouseWheelCapture, OnKeyDownCapture,
OnKeyUpCapture, OnTextInputCapture

### ViewGroup : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Padding | Thickness | P | 0 | Space between edges and children |
| ChildCount | int | R | - | Number of logical children |
| ContentBounds | RectangleF | R | - | Bounds after padding |

**Methods:** AddView, RemoveView, RemoveAllViews, InsertView,
GetChildAt, GetVisualChild, CreateDefaultLayoutParams

### RootView : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| ViewportSize | Vector2 | I | - | Physical pixels |
| DpiScale | float | I | 1.0 | Display scale factor |
| LogicalSize | Vector2 | R | - | ViewportSize / DpiScale |
| PopupLayer | PopupLayer | R | - | Always last child |

### Panel : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Background | Drawable? | P | null | Per-instance override |

---

## 2. Layout Containers

### Base LayoutParams

| Name | Type | Default | Notes |
|------|------|---------|-------|
| Width | SizeSpec | .Wrap | Fixed(Unit), Match, Wrap |
| Height | SizeSpec | .Wrap | Fixed(Unit), Match, Wrap |
| Margin | Thickness | 0 | Space around child |

### FlexLayout : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Direction | Orientation | P | .Horizontal | Main axis |
| JustifyContent | Justify | P | .Start | Main-axis distribution |
| AlignItems | Align | P | .Stretch | Cross-axis alignment |
| Spacing | float | P | 0 | Gap between children |

**FlexLayout.LayoutParams extends LayoutParams:**

| Name | Type | Default | Notes |
|------|------|---------|-------|
| Grow | float | 0 | Extra space absorption |
| Shrink | float | 0 | Shrink factor |
| AlignSelf | Align? | null | Cross-axis override |
| Gravity | Gravity | .None | Cross-axis positioning |

### GridLayout : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Columns | List\<TrackSize\> | P | empty | Auto, Fixed(px), Flex(weight) |
| Rows | List\<TrackSize\> | P | empty | Auto, Fixed(px), Flex(weight) |
| ColumnSpacing | float | P | 0 | Horizontal gap |
| RowSpacing | float | P | 0 | Vertical gap |
| AutoFlow | bool | P | true | Auto-place children |

**GridLayout.LayoutParams extends LayoutParams:**

| Name | Type | Default | Notes |
|------|------|---------|-------|
| Row | int32 | -1 | Row index (-1 = auto-flow) |
| Column | int32 | -1 | Column index (-1 = auto-flow) |
| RowSpan | int32 | 1 | Row span |
| ColumnSpan | int32 | 1 | Column span |

### DockLayout : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| LastChildFill | bool | P | false | Last child fills remainder |

**DockLayout.LayoutParams extends LayoutParams:**

| Name | Type | Default | Notes |
|------|------|---------|-------|
| Dock | Dock | .Left | Left, Top, Right, Bottom, Fill |

### FrameLayout : ViewGroup

No additional properties.

**FrameLayout.LayoutParams extends LayoutParams:**

| Name | Type | Default | Notes |
|------|------|---------|-------|
| Gravity | Gravity | .None | Positioning within frame |

### AbsoluteLayout : ViewGroup

No additional properties.

**AbsoluteLayout.LayoutParams extends LayoutParams:**

| Name | Type | Default | Notes |
|------|------|---------|-------|
| X | float | 0 | Explicit X coordinate |
| Y | float | 0 | Explicit Y coordinate |

### FlowLayout : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Orientation | Orientation | P | .Horizontal | Flow direction |
| HSpacing | float | P | 0 | Horizontal gap |
| VSpacing | float | P | 0 | Vertical gap |

No custom LayoutParams.

---

## 3. Controls

### Label : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Text | String | P | "" | Display text |
| HAlign | TextAlignment | P | .Left | Horizontal alignment |
| VAlign | VerticalAlignment | P | .Middle | Vertical alignment |
| WordWrap | bool | P | false | Enable word wrapping |
| Ellipsis | bool | P | false | Truncation ellipsis |
| FontSize | float? | P | null | Override; inherits from style if null |
| TextColor | Color? | P | null | Override; inherits from style if null |

### ButtonBase : View (abstract)

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Background | Drawable? | P | null | Per-instance override |
| Command | ICommand? | P | null | Command binding |
| IsPressed | bool | R | - | Mouse-down state |
| OnClick | void(ButtonBase) | E | - | Click event |

IsFocusable = true, IsTabStop = true.
Overrides GetControlState (Disabled, Pressed, Focused, Hover, Normal).

### Button : ButtonBase

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Text | String | P | C | Display text |
| FontSize | float? | P | null | Override |

Constructor: `this(StringView text)`

### ContentButton : ButtonBase

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Content | View? | P | null | Arbitrary content view |

### RepeatButton : Button

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| RepeatDelay | float | P | 0.4 | Seconds before repeat starts |
| RepeatInterval | float | P | 0.05 | Seconds between repeats |

### ToggleButton : ButtonBase

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| IsChecked | bool | P | false | Toggle state |
| Content | View? | P | null | Arbitrary content |
| OnCheckedChanged | void(ToggleButton, bool) | E | - | State change event |

Styled via `:checked` state: `ToggleButton:checked { background: ... }`.
No separate CheckedBackground property.

### CheckBox : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| IsChecked | bool | P | false | Checked state |
| Text | String | P | "" | Label text |
| FontSize | float? | P | null | Override |
| TextColor | Color? | P | null | Override |
| OnCheckedChanged | void(CheckBox, bool) | E | - | State change event |

IsFocusable = true, IsTabStop = true.

### RadioButton : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| IsChecked | bool | P | false | Selected state |
| Text | String | P | "" | Label text |
| FontSize | float? | P | null | Override |
| TextColor | Color? | P | null | Override |
| OnCheckedChanged | void(RadioButton, bool) | E | - | State change event |

IsFocusable = true, IsTabStop = true.

### RadioGroup : FlexLayout

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| CheckedButton | RadioButton? | R | - | Currently selected |
| OnSelectionChanged | void(RadioGroup, RadioButton) | E | - | Selection event |

Methods: AddRadioButton, CheckAt, ClearCheck.

### ToggleSwitch : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| IsChecked | bool | P | false | On/off state |
| Text | String | P | "" | Label text |
| TrackWidth | float | P | 44 | Switch track width |
| TrackHeight | float | P | 24 | Switch track height |
| KnobSize | float | P | 20 | Knob diameter |
| OnCheckedChanged | void(ToggleSwitch, bool) | E | - | State change event |

IsFocusable = true, IsTabStop = true.

### EditText : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Text | String | P | "" | Editable text |
| Placeholder | String | P | "" | Placeholder text |
| IsReadOnly | bool | P | false | Read-only mode |
| Multiline | bool | P | false | Multi-line mode |
| MaxLength | int32 | P | 0 | Max chars (0 = unlimited) |
| Filter | InputFilter? | P | null | Input filter |
| ShowContextMenuOnRightClick | bool | P | true | Right-click menu |
| CursorPosition | int32 | R | - | Current cursor pos |
| SelectionStart | int32 | R | - | Selection start |
| SelectionEnd | int32 | R | - | Selection end |
| OnTextChanged | void(EditText) | E | - | Text change event |
| OnSubmit | void(EditText) | E | - | Submit event |

Methods: SetPrefix(StringView/View), SetSuffix(StringView/View).
IsFocusable = true, IsTabStop = true. WantsArrowKeys = true.

### PasswordBox : EditText

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| PasswordChar | char32 | P | '*' | Mask character |

### EditableLabel : EditText

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| HAlign | TextAlignment | P | .Left | Text alignment |
| Ellipsis | bool | P | false | Truncation |
| FontSize | float? | P | null | Override |
| TextColor | Color? | P | null | Override |
| DoubleClickToEdit | bool | P | true | Double-click enters edit |
| SlowClickToEdit | bool | P | true | Slow click enters edit |
| ValidateRename | delegate bool(StringView) | I | null | Validation callback |
| IsEditing | bool | R | - | Currently editing |
| OnRenameCommitted | void(EditableLabel, StringView) | E | - | Rename completed |
| OnRenameCancelled | void(EditableLabel) | E | - | Rename cancelled |

Methods: BeginEdit, CommitEdit, CancelEdit.

### NumericField : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Value | double | P | 0 | Current value |
| Min | double | P | -inf | Minimum value |
| Max | double | P | +inf | Maximum value |
| Step | double | P | 1 | Increment step |
| DecimalPlaces | int32 | P | 2 | Display precision |
| ShowSpinButtons | bool | P | true | Show up/down buttons |
| ButtonWidth | float | P | 20 | Spin button width |
| OnValueChanged | void(NumericField, double) | E | - | Value change event |
| OnEditBegan | void(NumericField) | E | - | Edit started |
| OnEditEnded | void(NumericField) | E | - | Edit finished |

Methods: Increment, Decrement, SetPrefix, SetSuffix, CommitText.
IsFocusable = true, IsTabStop = true. WantsArrowKeys = true.

### Slider : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Value | float | P | 0 | Current value |
| Min | float | P | 0 | Minimum |
| Max | float | P | 1 | Maximum |
| Step | float | P | 0 | Snap step (0 = continuous) |
| Orientation | Orientation | P | .Horizontal | Slider direction |
| OnValueChanged | void(Slider, float) | E | - | Value change event |
| OnDragStarted | void(Slider) | E | - | Thumb drag started |
| OnDragEnded | void(Slider) | E | - | Thumb drag ended |

IsFocusable = true, IsTabStop = true.

### ProgressBar : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Value | float | P | 0 | Progress 0-1 |
| IsIndeterminate | bool | P | false | Indeterminate animation |

### ScrollBar : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Value | float | P | 0 | Scroll position |
| MaxValue | float | P | 0 | Maximum scroll |
| ViewportSize | float | P | 0 | Visible area size |
| IsHorizontal | bool | P | false | Orientation |
| BarThickness | float | P | 10 | Bar width/height |
| OnValueChanged | void(ScrollBar, float) | E | - | Scroll event |

### ScrollView : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| ScrollX | float | P | 0 | Horizontal scroll pos |
| ScrollY | float | P | 0 | Vertical scroll pos |
| VScrollBarPolicy | ScrollBarPolicy | P | .Auto | Vertical bar policy |
| HScrollBarPolicy | ScrollBarPolicy | P | .Auto | Horizontal bar policy |
| ScrollBarMode | ScrollBarMode | P | .Overlay | Bar display mode |
| MomentumEnabled | bool | P | true | Momentum scrolling |
| ScrollBarThickness | float | P | 10 | Bar thickness |
| MaxScrollX | float | R | - | Max horizontal scroll |
| MaxScrollY | float | R | - | Max vertical scroll |
| ContentWidth | float | R | - | Full content width |
| ContentHeight | float | R | - | Full content height |
| ViewportWidth | float | R | - | Visible width |
| ViewportHeight | float | R | - | Visible height |

Methods: ScrollTo, ScrollToTop/Bottom/Left/Right, ScrollBy, ScrollToView.
ClipsContent = true.

### ImageView : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Image | IImageData? | P | null | Image to display |
| ScaleType | ScaleType | P | .None | None, FitCenter, FillBounds, CenterCrop |
| Tint | Color | P | .White | Tint color |

### ColorView : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Color | Color | P | .White | Display color |
| PreferredWidth | float | P | 0 | Desired width |
| PreferredHeight | float | P | 0 | Desired height |

### DrawableView : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Drawable | Drawable? | P | null | Drawable to render |
| OwnsDrawable | bool | I | false | Ownership flag |
| DesiredWidth | float? | P | null | Width override |
| DesiredHeight | float? | P | null | Height override |

### Separator : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Orientation | Orientation | P | .Horizontal | Line direction |
| SeparatorThickness | float | P | 1 | Line thickness |

### Spacer : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| SpacerWidth | float | P | 0 | Fixed width |
| SpacerHeight | float | P | 0 | Fixed height |

### ComboBox : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| SelectedIndex | int32 | P | -1 | Selected item index |
| SelectedText | StringView | R | - | Selected item text |
| ItemCount | int | R | - | Number of items |
| IsOpen | bool | R | - | Dropdown open |
| OnSelectionChanged | void(ComboBox, int) | E | - | Selection event |

Methods: AddItem, RemoveItem, ClearItems, OpenDropdown, CloseDropdown.
IsFocusable = true, IsTabStop = true.

### TabView : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| SelectedIndex | int32 | P | 0 | Active tab index |
| TabHeight | float | P | 28 | Tab header height |
| Placement | TabPlacement | P | .Top | Top, Bottom, Left, Right |
| TabsClosable | bool | P | false | Show close buttons |
| CloseButtonSize | float | P | 12 | Close button size |
| MinTabWidth | float | P | 50 | Minimum tab width |
| TabCount | int | R | - | Number of tabs |
| OnTabChanged | void(TabView, int32) | E | - | Tab switch event |
| OnTabCloseRequested | void(TabView, int32) | E | - | Close request event |

Methods: AddTab, RemoveTab.
ClipsContent = true.

### Expander : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| IsExpanded | bool | P | false | Expanded state |
| HeaderHeight | float | P | 28 | Header height |
| ContentSpacing | float | P | 4 | Gap below header |
| OnExpandedChanged | void(Expander, bool) | E | - | State change event |

Methods: SetContent, SetHeaderText, Toggle, Expand, Collapse.
IsFocusable = true.

### ListView : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Adapter | IListAdapter? | P | null | Data adapter |
| ItemHeight | float | P | 30 | Default item height |
| LongPressTime | float | P | 0.5 | Long press threshold |
| Selection | SelectionModel | R | - | Selection state |
| ScrollY | float | R | - | Scroll position |
| MaxScrollY | float | R | - | Max scroll |
| Recycler | ViewRecycler | R | - | View recycler |
| OnItemClicked | void(int32, int32, float, float) | E | - | Item click |
| OnItemRightClicked | void(int32, float, float) | E | - | Right-click |
| OnItemLongPress | void(int32) | E | - | Long press |
| OnBackgroundRightClicked | void(float, float) | E | - | Background right-click |
| OnItemKeyDown | void(int32, KeyEventArgs) | E | - | Key on item |

Methods: ScrollBy, ScrollToPosition, GetItemAtY, GetActiveView,
NotifyDataChanged.
IsFocusable = true, IsTabStop = true, ClipsContent = true.

### GridView : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Adapter | IListAdapter? | P | null | Data adapter |
| CellWidth | float | P | 60 | Cell width |
| CellHeight | float | P | 60 | Cell height |
| CellSpacing | float | P | 4 | Gap between cells |
| Selection | SelectionModel | R | - | Selection state |
| ScrollY | float | R | - | Scroll position |
| MaxScrollY | float | R | - | Max scroll |
| OnItemClicked | void(int32, int32, float, float) | E | - | Item click |
| OnItemRightClicked | void(int32, float, float) | E | - | Right-click |

Methods: ScrollBy, ScrollToPosition, GetItemAtPoint.
IsFocusable = true, IsTabStop = true, ClipsContent = true.

### TreeView : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| TreeAdapter | ITreeAdapter? | P | null | Tree data source |
| ItemHeight | float | P | 30 | Item height |
| IndentWidth | float | P | 20 | Indent per depth level |
| ArrowSize | float | P | 12 | Expand arrow size |
| Selection | SelectionModel | R | - | Selection state |
| FlatAdapter | FlattenedTreeAdapter | R | - | Flattened view |
| InternalListView | ListView | R | - | Internal list |
| OnItemClick | void(ItemClickInfo) | E | - | Item click |
| OnItemRightClick | void(int32, float, float) | E | - | Right-click |
| OnItemKeyDown | void(int32, KeyEventArgs) | E | - | Key on item |
| OnItemToggled | void(int32) | E | - | Expand/collapse |

Methods: SetAdapter, ToggleExpand.
ClipsContent = true.

---

## 4. Overlay Controls

### ContextMenu : View

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| ItemCount | int | R | - | Number of items |

Methods: AddItem, AddSeparator, AddSubmenu, Show, Close,
CloseEntireChain.
IsFocusable = true.

### Dialog : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|
| Title | String | P | C | Dialog title |
| Result | DialogResult | P | .None | Close result |
| MinWidth | float | P | 250 | Minimum width |
| MinHeight | float | P | 120 | Minimum height |
| MaxWidth | float | P | 400 | Maximum width |
| MaxHeight | float | P | 300 | Maximum height |
| OnClosed | void(Dialog, DialogResult) | E | - | Close event |

Methods: SetContent, AddButton, Show, Close.
Static: Alert, Confirm.
ClipsContent = true.

### TooltipView : ViewGroup

| Name | Type | Kind | Default | Notes |
|------|------|------|---------|-------|

Internal to TooltipManager. Methods: SetContent, ClearContent.

---

## 5. Toolkit Controls (out of scope for v3)

Toolkit controls (MenuBar, Toolbar, StatusBar, SplitView, BreadcrumbBar,
ColorPicker, HDRColorPicker, DraggableTreeView, VectorFields,
PropertyGrid, Docking) are cataloged in the v2 codebase and will be
ported as a separate phase after the core framework stabilizes.

---

## 6. Core Infrastructure Inventory

### Phase A: Core (no dependencies)

| Type | File | Purpose |
|------|------|---------|
| ViewId | Core/ViewId.bf | uint32 handle, thread-safe factory, IHashable |
| ViewHandle | Core/ViewHandle.bf | Indirection wrapper (View field, nulled on delete) for safe external references |
| Property\<T\> | Core/Property.bf | Observable value, Changed event, BindTo, BindTwoWay, SetSilent |
| View | Core/View.bf | Base class with Property<T> fields, identity, lifecycle |
| ViewGroup | Core/ViewGroup.bf | Container, child management, padding |
| RootView | Core/RootView.bf | Top-level viewport, PopupLayer host |
| UIContext | Core/UIContext.bf | Central coordinator, ViewId registry, NameRegistry, managers |
| MutationQueue | Core/MutationQueue.bf | Deferred tree mutations |
| ViewTransform | Core/ViewTransform.bf | Post-layout transform struct |
| Thickness | Core/Thickness.bf | Padding/margin struct |
| Visibility | Core/Visibility.bf | Visible/Hidden/Gone enum |
| CursorType | Core/CursorType.bf | Cursor appearance enum |
| Orientation | Core/Orientation.bf | Horizontal/Vertical enum |
| IClipboard | Core/IClipboard.bf | Clipboard interface |
| ICommand | Core/ICommand.bf | CanExecute/Execute interface |

### Phase B: Layout (depends on A)

| Type | File | Purpose |
|------|------|---------|
| BoxConstraints | Layout/BoxConstraints.bf | Min/max constraint struct |
| SizeSpec | Layout/SizeSpec.bf | Fixed/Match/Wrap enum |
| Unit | Layout/Unit.bf | Dp/Pt/Px dimensional enum |
| LayoutParams | Layout/LayoutParams.bf | Base child params |
| Gravity | Layout/Gravity.bf | Alignment flags |
| GravityHelper | Layout/GravityHelper.bf | Gravity application utility |
| FlexLayout | Layout/FlexLayout.bf | CSS Flexbox container |
| GridLayout | Layout/GridLayout.bf | Grid with auto-flow |
| DockLayout | Layout/DockLayout.bf | Edge docking |
| FrameLayout | Layout/FrameLayout.bf | Stack overlay |
| AbsoluteLayout | Layout/AbsoluteLayout.bf | Explicit positioning |
| FlowLayout | Layout/FlowLayout.bf | Wrapping flow |

### Phase C: Drawing (depends on A)

| Type | File | Purpose |
|------|------|---------|
| UIDrawContext | Drawing/UIDrawContext.bf | VG rendering context |
| ControlState | Drawing/ControlState.bf | Bit flags enum |
| Drawable | Drawing/Drawable.bf | Abstract base |
| ColorDrawable | Drawing/ColorDrawable.bf | Solid fill |
| RoundedRectDrawable | Drawing/RoundedRectDrawable.bf | Rounded rect with border |
| GradientDrawable | Drawing/GradientDrawable.bf | Linear gradient |
| ImageDrawable | Drawing/ImageDrawable.bf | Stretched image |
| NineSliceDrawable | Drawing/NineSliceDrawable.bf | 9-slice with expand |
| SVGDrawable | Drawing/SVGDrawable.bf | Vector graphics |
| AtlasImageDrawable | Drawing/AtlasImageDrawable.bf | Atlas sub-region |
| AtlasNineSliceDrawable | Drawing/AtlasNineSliceDrawable.bf | Atlas 9-slice |
| StateListDrawable | Drawing/StateListDrawable.bf | Per-state map (flag-based lookup) |
| LayerDrawable | Drawing/LayerDrawable.bf | Stacked layers |
| InsetDrawable | Drawing/InsetDrawable.bf | Inset wrapper |
| ShapeDrawable | Drawing/ShapeDrawable.bf | Custom draw delegate |

### Phase D: Styling (depends on A, C)

| Type | File | Purpose |
|------|------|---------|
| StyleSheet | Styling/StyleSheet.bf | RefCounted rule container |
| StyleRule | Styling/StyleRule.bf | Selector + property-value list |
| StyleSelector | Styling/StyleSelector.bf | Type + Classes + State matching |
| StyleProperty | Styling/StyleProperty.bf | Property enum (~48 entries) |
| StyleValue | Styling/StyleValue.bf | Discriminated union |
| StyleInheritance | Styling/StyleInheritance.bf | Inheritable property set |
| Palette | Styling/Palette.bf | Color derivation utilities |
| ThemePalette | Styling/ThemePalette.bf | Seed color struct |
| ThemeAtlas | Styling/ThemeAtlas.bf | Atlas packer for themes |
| ThemeRegistry | Styling/ThemeRegistry.bf | Extension registry |
| IThemeExtension | Styling/IThemeExtension.bf | Theme injection interface |
| UITypeRegistry | Styling/Parser/UITypeRegistry.bf | String -> Type mapping |
| StyleSheetLoader | Styling/Parser/StyleSheetLoader.bf | .sss entry point |
| Tokenizer | Styling/Parser/Tokenizer.bf | .sss tokenizer |
| Parser | Styling/Parser/Parser.bf | .sss parser |
| Ast | Styling/Parser/Ast.bf | .sss AST nodes |
| Values | Styling/Parser/Values.bf | Value parsers (shared with markup) |
| DrawableFactoryRegistry | Styling/Parser/DrawableFactoryRegistry.bf | Factory lookup |
| ColorFunctions | Styling/Parser/ColorFunctions.bf | lighten/darken/alpha/mix |

### Phase E: Input (depends on A)

| Type | File | Purpose |
|------|------|---------|
| InputManager | Input/InputManager.bf | Event routing, hover, capture |
| FocusManager | Input/FocusManager.bf | Focus, tab nav, directional nav, modal stack |
| ShortcutManager | Input/ShortcutManager.bf | Global/scoped shortcuts |
| Shortcut | Input/Shortcut.bf | Key binding |
| KeyCode | Input/KeyCode.bf | Key enumeration |
| KeyModifiers | Input/KeyModifiers.bf | Modifier flags |
| MouseButton | Input/MouseButton.bf | Button enum |
| MouseEventArgs | Input/MouseEventArgs.bf | Pooled mouse event |
| MouseWheelEventArgs | Input/MouseWheelEventArgs.bf | Pooled wheel event |
| KeyEventArgs | Input/KeyEventArgs.bf | Pooled key event |
| TextInputEventArgs | Input/TextInputEventArgs.bf | Pooled text event |
| IAcceleratorHandler | Input/IAcceleratorHandler.bf | Alt+key interface |
| DragDropManager | DragDrop/DragDropManager.bf | Drag state machine |
| DragData | DragDrop/DragData.bf | Drag payload |
| DragAdorner | DragDrop/DragAdorner.bf | Drag visual |
| DragDropEffects | DragDrop/DragDropEffects.bf | Effect flags |
| IDragSource | DragDrop/IDragSource.bf | Source interface |
| IDropTarget | DragDrop/IDropTarget.bf | Target interface |

### Phase J: Animation (depends on A only)

| Type | File | Purpose |
|------|------|---------|
| Animation | Animation/Animation.bf | Abstract base |
| FloatAnimation | Animation/FloatAnimation.bf | Float interpolation |
| ColorAnimation | Animation/ColorAnimation.bf | Color interpolation |
| Vector2Animation | Animation/Vector2Animation.bf | Vector2 interpolation |
| Storyboard | Animation/Storyboard.bf | Sequential/parallel group |
| AnimationManager | Animation/AnimationManager.bf | Active animation controller |
| ViewAnimator | Animation/ViewAnimator.bf | Static convenience methods |
| Easing | Animation/Easing.bf | Easing function presets |

---

## 7. Data Interfaces

| Type | Purpose |
|------|---------|
| IListAdapter | ItemCount, CreateView, BindView, GetItemViewType, GetItemHeight |
| IListAdapterObserver | OnDataSetChanged, OnItemRangeChanged |
| ListAdapterBase | Abstract base implementing IListAdapter |
| ITreeAdapter | RootCount, GetChildCount, GetChildId, HasChildren, CreateView, BindView |
| ITreeAdapterObserver | OnTreeDataChanged |
| FlattenedTreeAdapter | Flattens ITreeAdapter to IListAdapter for ListView |
| ViewRecycler | Pool-based view recycling by view type |
| SelectionModel | Single/multi/range selection with events |
| HierarchicalState | Capture/restore tree expand + selection + scroll |

---

## 8. Text Editing Infrastructure

| Type | Purpose |
|------|---------|
| TextEditingBehavior | Composition-based editing: cursor, selection, clipboard, undo |
| ITextEditHost | Interface for views hosting text editing |
| UndoStack | Undo/redo with coalescing |
| InputFilter | Digits/hex/custom character filtering |

---

## 9. StyleProperty Enum (full listing)

### Drawable properties
Background, TrackDrawable, ThumbDrawable,
FillDrawable, KnobDrawable, TrackOnDrawable, BoxDrawable,
StripDrawable, ContentDrawable, ActiveTabDrawable, HoverTabDrawable,
MenuItemHoverDrawable, HeaderDrawable, HeaderHoverDrawable,
SpinUpDrawable, SpinDownDrawable

### Icon properties
CheckmarkIcon, RadioMarkIcon, CloseIcon, ChevronExpandedIcon,
ChevronCollapsedIcon, ArrowDownIcon, ArrowUpIcon

### Color properties
TextColor, TextDimColor, PlaceholderColor, BorderColor, CursorColor,
SelectionColor, CheckColor, ArrowColor, AccentColor,
ActiveTabTextColor, InactiveTabTextColor, HoverTabTextColor,
CloseButtonColor, CloseButtonHoverColor

### Float properties
FontSize, CornerRadius, BorderWidth, Spacing, ThumbSize, TrackHeight,
BoxSize, Opacity, HeaderHeight, CloseButtonSize

### Thickness properties
Padding, Margin

### Bool properties
WordWrap

---

## 10. Testing Strategy

### Unit tests (per phase, must pass before proceeding)

| Phase | Test scope |
|---|---|
| A: Core | ViewId uniqueness/thread-safety, ViewHandle null-on-delete (verify handle.View == null immediately after delete, before frame end), Property<T> change notification/binding/loop-guard/SetSilent, View lifecycle (attach/detach/destroy), ViewGroup child management, MutationQueue ordering, UIContext registry lookup (returns null for deleted views), NameRegistry, ControlState flag combinations |
| B: Layout | BoxConstraints arithmetic (Deflate, Constrain, Loosen, Tighten), SizeSpec/Unit resolution, each container's measure+layout algorithm (Flex justify/align/grow/shrink, Grid auto-flow/spanning/tracks, Dock edge consumption, Frame gravity, Absolute positioning, Flow wrapping), LayoutParams defaults |
| C: Drawing | Drawable intrinsic size, StateListDrawable flag-based fallback lookup, LayerDrawable composition, InsetDrawable padding, NineSlice slice regions |
| D: Styling | StyleSelector matching (type, class, multi-class, state, compound state flags), specificity calculation, cascade resolution order, style inheritance (TextColor, FontSize, FontFamily, Cursor, TextAlign), StyleValue discriminated union accessors, Palette color derivation, .sss tokenizer, .sss parser round-trip, drawable factory invocation, @palette/@icon/@import directives, palette extends |
| E: Markup | MarkupLoader parses .sml to View tree, attribute routing (child props vs LayoutParams), value parsing (Color, Unit, Thickness, SizeSpec), one-way data binding updates, DataTemplate factory, Include resolution |
| F: Input | Three-phase event propagation (capture stops before target, bubble stops after), FocusManager tab order (TabIndex sorting), directional focus spatial picker, focus stack push/pop, mouse capture bypasses phases, ShortcutManager dispatch (scoped vs global), event args pooling + EventPhase field, ViewHandle deletion safety across all managers |
| G: Animation | FloatAnimation interpolation + easing, ColorAnimation lerp, Storyboard sequential/parallel, AnimationManager add/cancel/complete lifecycle, repeat + auto-reverse |
| C1-C8 | Each control: Property<T> change notification, GetControlState flag composition, MarkupSetters table completeness (every property reachable by name), .sss theme rule coverage |

### Integration tests (GUISandbox, starting from C1)

Every control added to the framework must be demonstrated in
GUISandbox with at least:
- Visual rendering with dark and light themes
- Interactive behavior (click, hover, focus, state changes)
- Theme switching
- Markup loading (.sml screen — markup infrastructure is available from Phase E onward, before any controls are built)
