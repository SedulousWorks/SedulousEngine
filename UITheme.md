# Sedulous.UI Theme Image Guide

## Overview

Sedulous.UI supports full image-based skinning via the drawable theming system. Controls check for a theme drawable first; if none is set, they fall back to color-based VG rendering. A fully textured theme replaces all visual regions with 9-slice images packed into a single GPU atlas for zero texture switches during rendering.

## How Theming Works

### Option C Pattern (drawable first, color fallback)

Every control's `OnDraw` follows this pattern:

```beef
if (!ctx.TryDrawDrawable("Button.Background", bounds, GetControlState()))
{
    // Color fallback — only runs if no drawable is set.
    let bg = ctx.Theme?.GetColor("Button.Background") ?? fallback;
    ctx.VG.FillRoundedRect(bounds, radius, bg);
}
```

### Setting Up a Textured Theme

**In code:**
```beef
let images = ThemeImageSet();
images.ButtonNormal = loadedButtonNormalImage;
images.ButtonHover = loadedButtonHoverImage;
images.ButtonSlices = NineSlice(8, 8, 8, 8);
// ... set all images ...

let theme = TexturedTheme.Create(images);
ctx.Theme = theme;
```

**In XML:**
```xml
<Theme name="GameUI">
  <Drawable key="Button.Background" type="StateList">
    <State state="Normal" type="NineSlice" src="button_normal.png" slices="8,8,8,8"/>
    <State state="Hover" type="NineSlice" src="button_hover.png" slices="8,8,8,8"/>
    <State state="Pressed" type="NineSlice" src="button_pressed.png" slices="8,8,8,8"/>
    <State state="Disabled" type="NineSlice" src="button_disabled.png" slices="4,4,4,4"/>
  </Drawable>
</Theme>
```

XML parsing with image loading requires an `ImageLoader` callback:
```beef
let theme = ThemeXmlParser.Parse(xml, scope (path) => {
    return LoadImageAsRGBA8(assetDir, path);
});
```

### 9-Slice Images

Most theme images use 9-slice scaling. The image is divided into a 3x3 grid:
- **Corners** (4): fixed size, never stretched
- **Edges** (4): stretch in one direction
- **Center** (1): stretches both directions

The `NineSlice(left, top, right, bottom)` values define the border widths in pixels from each edge. For a typical button with 8px rounded corners: `NineSlice(8, 8, 8, 8)`.

### Atlas Packing

`TexturedTheme.Create()` automatically packs all provided images into a single atlas texture via `ImageAtlasBuilder`. This means all UI rendering uses one texture bind — optimal GPU batching.

---

## Required Images

### Buttons (4 images)

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `button_normal.png` | Default button state. Rounded rectangle with subtle gradient or bevel. | 48×32 | 8,8,8,8 |
| `button_hover.png` | Highlighted on mouse hover. Slightly brighter than normal. | 48×32 | 8,8,8,8 |
| `button_pressed.png` | Depressed/clicked state. Darker, may have inset bevel. | 48×32 | 8,8,8,8 |
| `button_disabled.png` | Grayed out, desaturated. Low contrast. | 48×32 | 8,8,8,8 |

### Panel / Container (1 image)

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `panel.png` | Container background. Subtle border, slight inset or raised look. | 48×48 | 8,8,8,8 |

### Text Input (2 images)

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `edittext_normal.png` | Text field at rest. Thin border, inset look. | 48×28 | 4,4,4,4 |
| `edittext_focused.png` | Text field with keyboard focus. Accent-colored border, slight glow. | 48×28 | 4,4,4,4 |

### Tabs (2 images)

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `tab_active.png` | Selected/active tab. Connected to content area (no bottom border). | 64×28 | 6,6,6,2 |
| `tab_inactive.png` | Unselected tab. Slightly recessed or darker than active. | 64×28 | 6,6,6,2 |

### Overlays (3 images)

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `dialog.png` | Modal dialog background. Drop shadow, rounded corners. Shadow extends beyond content — use `Expand` thickness. | 64×64 | 12,12,12,12 |
| `tooltip.png` | Tooltip popup. Small, sharp corners or slight rounding. Optional shadow. | 32×24 | 6,6,6,6 |
| `contextmenu.png` | Right-click menu background. Similar to dialog but lighter shadow. | 48×48 | 8,8,8,8 |

### ScrollBar (2 images)

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `scroll_track.png` | Scrollbar track/groove. Subtle inset channel. | 12×32 | 3,6,3,6 |
| `scroll_thumb.png` | Scrollbar thumb/handle. Draggable indicator. | 12×24 | 3,6,3,6 |

### Slider (3 images)

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `slider_track.png` | Slider track background. Thin horizontal groove. | 32×8 | 4,2,4,2 |
| `slider_fill.png` | Slider filled portion (left of thumb). Accent colored. | 32×8 | 4,2,4,2 |
| `slider_thumb.png` | Slider thumb/knob. Circular or rounded, draggable. NOT 9-sliced — drawn as-is. | 16×16 | N/A |

### CheckBox (2 images)

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `checkbox_unchecked.png` | Empty checkbox. Square with border. NOT 9-sliced. | 16×16 | N/A |
| `checkbox_checked.png` | Checked checkbox. Square with checkmark inside. NOT 9-sliced. | 16×16 | N/A |

### ProgressBar (2 images)

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `progress_track.png` | Progress bar background track. | 32×12 | 4,4,4,4 |
| `progress_fill.png` | Progress bar fill. Accent colored, stretches with progress value. | 32×12 | 4,4,4,4 |

### Toolkit Controls

| File | Description | Suggested Size | 9-Slice |
|------|-------------|----------------|---------|
| `toolbar_bg.png` | Toolbar background strip. | 48×32 | 4,4,4,4 |
| `toolbar_btn_hover.png` | Toolbar button hover highlight. | 32×24 | 4,4,4,4 |
| `toolbar_toggle_on.png` | Toolbar toggle checked/active state. | 32×24 | 4,4,4,4 |
| `statusbar_bg.png` | Status bar background strip. | 48×24 | 4,4,4,4 |
| `menubar_bg.png` | Menu bar background strip. | 48×28 | 4,4,4,4 |
| `menubar_item_hover.png` | Menu bar item hover highlight. | 32×24 | 4,4,4,4 |
| `splitview_divider.png` | SplitView divider (normal state). | 8×32 | 2,4,2,4 |
| `splitview_divider_hover.png` | SplitView divider (hover/drag state). | 8×32 | 2,4,2,4 |
| `splitview_grip.png` | SplitView grip indicator dots. | 6×20 | 2,4,2,4 |
| `colorpicker_bg.png` | ColorPicker container background. | 48×48 | 6,6,6,6 |
| `propertygrid_bg.png` | PropertyGrid container background. | 48×48 | 4,4,4,4 |
| `dock_manager_bg.png` | DockManager area background. | 48×48 | 4,4,4,4 |
| `dock_panel_header.png` | DockablePanel title bar. | 48×24 | 4,4,4,4 |
| `dock_panel_content.png` | DockablePanel content area. | 48×48 | 4,4,4,4 |
| `dock_tabbar.png` | DockTabGroup tab strip background. | 48×24 | 4,4,4,4 |
| `dock_tab_content.png` | DockTabGroup content area. | 48×48 | 4,4,4,4 |
| `dock_tab_active.png` | DockTabGroup selected tab. | 48×24 | 4,4,4,4 |
| `dock_tab_inactive.png` | DockTabGroup unselected tab. | 48×24 | 4,4,4,4 |
| `dock_tab_inactive_hover.png` | DockTabGroup unselected tab on hover. | 48×24 | 4,4,4,4 |
| `dock_split_divider.png` | DockSplit divider (normal). | 6×32 | 2,4,2,4 |
| `dock_split_divider_hover.png` | DockSplit divider (hover/drag). | 6×32 | 2,4,2,4 |
| `floating_window_bg.png` | FloatingWindow virtual mode background. | 48×48 | 6,6,6,6 |

---

## Full Drawable Key Reference

### Backgrounds (queried via `TryDrawDrawable`)

| Key | Control | States | Description |
|-----|---------|--------|-------------|
| `Button.Background` | Button, RepeatButton | Normal, Hover, Pressed, Disabled | Button surface |
| `CheckBox.Box` | CheckBox | Normal, Hover, Disabled | Checkbox square |
| `CheckBox.Checkmark` | CheckBox | — | Checkmark icon (when checked) |
| `RadioButton.Circle` | RadioButton | Normal, Hover, Disabled | Radio circle |
| `RadioButton.Dot` | RadioButton | — | Inner dot (when selected) |
| `ToggleButton.Background` | ToggleButton | Normal, Hover, Pressed, Disabled | Unchecked background |
| `ToggleButton.CheckedBackground` | ToggleButton | Normal, Hover, Pressed, Disabled | Checked background |
| `ToggleSwitch.Track` | ToggleSwitch | Normal (off), Pressed (on) | Switch track |
| `ToggleSwitch.Knob` | ToggleSwitch | Normal, Hover | Switch knob |
| `Slider.Track` | Slider | — | Track background |
| `Slider.Fill` | Slider | — | Value fill |
| `Slider.Thumb` | Slider | Normal, Hover | Draggable thumb |
| `ProgressBar.Track` | ProgressBar | — | Track background |
| `ProgressBar.Fill` | ProgressBar | — | Progress fill |
| `ScrollBar.Track` | ScrollBar | — | Track background |
| `ScrollBar.Thumb` | ScrollBar | — | Thumb |
| `EditText.Background` | EditText, PasswordBox, NumericField | Normal, Focused | Input background |
| `ComboBox.Background` | ComboBox | Normal, Hover | Dropdown background |
| `Panel.Background` | Panel | — | Container background |
| `TabView.StripBackground` | TabView | — | Tab header strip |
| `TabView.ContentBackground` | TabView | — | Content area |
| `TabView.ActiveTab` | TabView | — | Selected tab header |
| `TabView.InactiveTab` | TabView | Hover | Unselected tab header |
| `Expander.Header` | Expander | Normal, Hover | Collapsible header |
| `ContextMenu.Background` | ContextMenu | — | Popup background |
| `Dialog.Background` | Dialog | — | Modal background |
| `Tooltip.Background` | TooltipView | — | Tooltip background |
| `Modal.Backdrop` | ModalBackdrop | — | Semi-transparent overlay |

### Icons (queried via `TryDrawDrawable`)

| Key | Control | Description |
|-----|---------|-------------|
| `CheckBox.Checkmark` | CheckBox | Checkmark icon |
| `Expander.ArrowExpanded` | Expander | Down chevron (expanded state) |
| `Expander.ArrowCollapsed` | Expander | Right chevron (collapsed state) |
| `ComboBox.Arrow` | ComboBox | Dropdown arrow |
| `NumericField.UpArrow` | NumericField | Spin increment arrow |
| `NumericField.DownArrow` | NumericField | Spin decrement arrow |
| `NumericField.UpButton` | NumericField | Up button background (Normal, Hover, Pressed) |
| `NumericField.DownButton` | NumericField | Down button background (Normal, Hover, Pressed) |
| `TabView.CloseIcon` | TabView | Tab close X button |
| `DockablePanel.CloseIcon` | DockablePanel | Panel close X button |
| `ContextMenu.ItemHover` | ContextMenu | Item hover highlight background |
| `ContextMenu.SubmenuArrow` | ContextMenu | Submenu right arrow (SVG icon by default) |

### Toolkit Controls

| Key | Control | States | Description |
|-----|---------|--------|-------------|
| `Toolbar.Background` | Toolbar | — | Toolbar bar |
| `ToolbarButton.Background` | ToolbarButton | Hover | Button hover |
| `ToolbarToggle.CheckedBackground` | ToolbarToggle | — | Checked toggle |
| `StatusBar.Background` | StatusBar | — | Status bar |
| `MenuBar.Background` | MenuBar | — | Menu bar |
| `MenuBar.ItemBackground` | MenuBar | Hover | Menu item hover |
| `SplitView.Divider` | SplitView | Normal, Hover | Draggable divider |
| `SplitView.Grip` | SplitView | Normal, Hover | Grip dot pattern |
| `ColorPicker.Background` | ColorPicker | — | Picker container |
| `PropertyGrid.Background` | PropertyGrid | — | Grid container |
| `DockManager.Background` | DockManager | — | Dock area background |
| `DockablePanel.Header` | DockablePanel | — | Panel title bar |
| `DockablePanel.ContentBackground` | DockablePanel | — | Panel content area |
| `DockTabGroup.TabBar` | DockTabGroup | — | Tab strip |
| `DockTabGroup.ContentBackground` | DockTabGroup | — | Content area |
| `DockTabGroup.ActiveTab` | DockTabGroup | — | Selected tab |
| `DockTabGroup.InactiveTab` | DockTabGroup | Hover | Unselected tab |
| `DockSplit.Divider` | DockSplit | Normal, Hover | Split divider |
| `FloatingWindow.Background` | FloatingWindow | — | Virtual window background |

### SVG Icons (built-in via ThemeIcons)

The framework includes built-in SVG icon definitions in `ThemeIcons`:
- `ThemeIcons.Checkmark` — checkmark path
- `ThemeIcons.ArrowDown` / `ArrowUp` — dropdown/spin arrows
- `ThemeIcons.ChevronRight` / `ChevronDown` — expand/collapse
- `ThemeIcons.Close` — X close icon
- `ThemeIcons.Plus` / `Minus` — add/remove
- `ThemeIcons.RadioDot` — filled circle

These can be registered as SVGDrawables:
```beef
theme.SetDrawable("ComboBox.Arrow", SVGDrawable.FromString(ThemeIcons.ArrowDown));
```

## Image Guidelines

- **Format:** PNG, RGBA8 (32-bit with alpha)
- **Background:** Transparent where the control shouldn't fill (e.g., rounded corners)
- **Shadows:** If including drop shadows, use the `Expand` parameter on NineSliceDrawable so the shadow extends beyond the control bounds
- **Consistency:** All images should share the same visual language — same corner radius style, same shadow depth, same border treatment
- **States:** Hover should be subtly brighter. Pressed should feel inset/darker. Disabled should be desaturated and low-contrast.
- **DPI:** Images are stretched via 9-slice, so they work at any DPI. Provide images at 1x resolution; they scale cleanly.
