# Image-Based Styling for Game UI

## Overview
Add nine-slice image background support to the GUI styling system so controls can render
with textured backgrounds (ornate frames, parchment panels, etc.) instead of flat colors.

## Infrastructure (Phase 1 - Current)

- [x] Create `ImageBrush` struct in `Sedulous.Drawing` (Texture, NineSlice, Tint)
- [x] Add `BackgroundImage` field to `StateStyle`
- [x] Add `BackgroundImage` field + `GetBackgroundImage(state)` method to `ControlStyle`
- [x] Add auto-tint modulation in `GetBackgroundImage()` (lighten on hover, darken on press, fade on disable)
- [x] Add `DrawImageBrush()` convenience method to `DrawContext`
- [x] Add `BackgroundImage` property + `GetStateBackgroundImage()` method to `Control`
- [x] Modify `Control.RenderBackground()` to draw image when present (replaces color fill + border)
- [x] Modify `Button.RenderOverride()` to support image backgrounds

## Controls with Automatic Support (via RenderBackground)

These call `RenderBackground(ctx)` and get image support for free:

- [x] ContentControl (base class for Button, ToggleButton, etc.)
- [x] Decorator (Border wraps this)
- [x] Container (Panel, StackPanel, etc.)
- [x] TextBox
- [x] PasswordBox
- [x] NumericUpDown
- [x] ComboBox
- [x] Label
- [x] TextBlock
- [x] Breadcrumb
- [x] Menu
- [x] ToolBar
- [x] StatusBar
- [x] TabControl
- [x] ScrollViewer
- [x] Expander
- [x] ItemsControl (ListBox base)

## Controls Needing Manual Image Support (Deferred)

These have custom `RenderOverride()` that doesn't call `RenderBackground()`.
Each needs its own image integration:

### High Priority (common in game UI)
- [x] ProgressBar - TrackImage + FillImage properties
- [x] Slider - TrackImage + ThumbImage properties (with state tint modulation on thumb)
- [x] ScrollBar - TrackImage + ThumbImage properties (with state tint modulation on thumb)
- [x] Dialog - BackgroundImage support (replaces frame + title bar + border)
- [x] Popup - BackgroundImage support (replaces background + border, shadow preserved)
- [x] Tooltip - BackgroundImage support (replaces background + border)

### Medium Priority
- [x] CheckBox - indicator box image (checked/unchecked/indeterminate states)
- [x] RadioButton - indicator circle image (selected/unselected states)
- [x] ToggleSwitch - track image + knob image (on/off states)
- [x] ListBoxItem - selected/hover row background image
- [x] TreeViewItem - selected/hover row background image + expander arrow image
- [x] TileViewItem - tile background image
- [x] TabItem (TabControl tabs) - active/inactive tab image
- [x] ComboBox dropdown arrow - arrow image instead of drawn triangle

### Lower Priority (less visible in game UI)
- [x] MenuItem - hover/selected row image (HighlightImage)
- [x] MenuBarItem - hover image (HighlightImage)
- [x] MenuSeparator - divider image (DividerImage)
- [x] ToolBarButton - button image per-state (ButtonImage)
- [x] ToolBarToggleButton - toggle image per-state (ButtonImage)
- [x] ToolBarSeparator - divider image (DividerImage)
- [x] Splitter - grip image (GripImage)
- [x] GroupBox - frame image (FrameImage)
- [x] BreadcrumbItem - segment image (SegmentImage)
- [x] StatusBarItem - item background image (ItemBackgroundImage)
- [x] Separator - line image (LineImage)
- [x] RepeatButton - works via base Button (already has image support)

### Docking System (Deferred - tooling-specific)
- [x] DockablePanel - panel frame image (FrameImage)
- [x] DockablePanelHeader - title bar image (TitleBarImage)
- [x] DockTabGroup - tab strip image (TabStripImage)
- [x] DockTab - tab image (active/inactive) (ActiveTabImage/InactiveTabImage)
- [x] FloatingWindow - window frame image (FrameImage)
- [x] DockTarget/DockSplit - overlay images (DockTarget.OverlayImage, DockZoneIndicator.ButtonImage/ButtonHoverImage, DockSplit needs no changes)

### Data Controls (Deferred - tooling-specific)
- [x] DataGrid - grid background image (GridBackgroundImage, RowSelectionImage, RowHoverImage)
- [x] DataGridHeader - header row image (DataGrid.HeaderImage)
- [x] DataGridCell - header cell image (DataGridColumn.HeaderCellImage)
- [x] PropertyGrid - grid background image (GridBackgroundImage)
- [x] PropertyGridCategory - category header image (CategoryImage, CategoryHoverImage)
- [x] PropertyGridProperty - property row image (PropertyImage, PropertyHoverImage)

## Future Enhancements (Not Planned)

- [ ] Gradient brush support (linear/radial gradients as backgrounds)
- [ ] Border-only images (separate from background - e.g., glow border overlay)
- [ ] Fill images for ProgressBar (partial rendering of nine-slice)
- [ ] Animated image backgrounds (sprite sheet cycling)
- [ ] Image-based cursor themes
- [ ] Font/text shadow effects
- [ ] Control template system (full custom rendering via callbacks)

---

## Complete Image Asset Reference

Every `ImageBrush` property across all controls. This is the full list of images
needed to skin the entire UI with textures. All are optional - controls fall back
to color-based rendering when no image is set.

Auto-tint means the control applies `Palette.Lighten`/`Darken` on hover/press
automatically, so a single texture works for multiple states.

### Universal (via Control base class)

These controls accept `BackgroundImage` (set per-instance or via theme `ControlStyle`).
When set, it replaces both the background fill AND the border (the nine-slice IS the frame).
Auto-tint modulation is applied per state (hover: lighten 15%, pressed: darken 15%,
disabled: desaturate + 50% alpha). Per-state images can also be set via `ControlStyle`
to use distinct textures instead of auto-tint.

| Control            | Property            | Replaces                          |
|--------------------|---------------------|-----------------------------------|
| Button             | `BackgroundImage`   | Button background + border        |
| RepeatButton       | `BackgroundImage`   | (Inherits from Button)            |
| ToggleButton       | `BackgroundImage`   | Toggle background + border        |
| ContentControl     | `BackgroundImage`   | Content background + border       |
| Decorator / Border | `BackgroundImage`   | Border background + border        |
| Container          | `BackgroundImage`   | Panel/StackPanel background       |
| TextBox            | `BackgroundImage`   | Input field background + border   |
| PasswordBox        | `BackgroundImage`   | Input field background + border   |
| NumericUpDown      | `BackgroundImage`   | Spinner background + border       |
| ComboBox           | `BackgroundImage`   | Dropdown background + border      |
| Label              | `BackgroundImage`   | Label background                  |
| TextBlock          | `BackgroundImage`   | Text background                   |
| Breadcrumb         | `BackgroundImage`   | Breadcrumb trail background       |
| Menu               | `BackgroundImage`   | Menu bar background               |
| ToolBar            | `BackgroundImage`   | Toolbar background                |
| StatusBar          | `BackgroundImage`   | Status bar background             |
| TabControl         | `BackgroundImage`   | Tab control background            |
| ScrollViewer       | `BackgroundImage`   | Scroll area background            |
| Expander           | `BackgroundImage`   | Expander background               |
| ItemsControl       | `BackgroundImage`   | ListBox background                |
| Dialog             | `BackgroundImage`   | Dialog frame + title bar + border |
| Popup              | `BackgroundImage`   | Popup background + border         |
| Tooltip            | `BackgroundImage`   | Tooltip background + border       |

### ProgressBar

| Property      | Replaces                              | Notes                    |
|---------------|---------------------------------------|--------------------------|
| `TrackImage`  | Track background fill + border        |                          |
| `FillImage`   | Fill bar color                        | Stretched to fill amount |

### Slider

| Property      | Replaces                              | Notes                         |
|---------------|---------------------------------------|-------------------------------|
| `TrackImage`  | Track groove fill + border            |                               |
| `ThumbImage`  | Thumb circle/rectangle                | Auto-tint per drag/hover state|

### ScrollBar

| Property      | Replaces                              | Notes                         |
|---------------|---------------------------------------|-------------------------------|
| `TrackImage`  | Scrollbar track background            |                               |
| `ThumbImage`  | Scrollbar thumb rectangle             | Auto-tint per drag/hover state|

### CheckBox

| Property              | Replaces                         | Notes                           |
|-----------------------|----------------------------------|---------------------------------|
| `UncheckedImage`      | Unchecked indicator box          | Auto-tint per hover/press state |
| `CheckedImage`        | Checked indicator box + checkmark| Auto-tint per hover/press state |
| `IndeterminateImage`  | Indeterminate indicator box + dash| Auto-tint per hover/press state|

### RadioButton

| Property           | Replaces                            | Notes                           |
|--------------------|-------------------------------------|---------------------------------|
| `UnselectedImage`  | Unselected radio circle             | Auto-tint per hover/press state |
| `SelectedImage`    | Selected radio circle + dot         | Auto-tint per hover/press state |

### ToggleSwitch

| Property      | Replaces                              | Notes                    |
|---------------|---------------------------------------|--------------------------|
| `TrackImage`  | Switch track rounded rectangle        |                          |
| `KnobImage`   | Switch knob circle                    | Auto-tint per state      |

### ListBoxItem

| Property          | Replaces                          | Notes               |
|-------------------|-----------------------------------|----------------------|
| `SelectionImage`  | Selected row background color     |                      |
| `HoverImage`      | Hovered row background color      |                      |

### TreeViewItem

| Property               | Replaces                          | Notes               |
|------------------------|-----------------------------------|----------------------|
| `SelectionImage`       | Selected row background color     |                      |
| `HoverImage`           | Hovered row background color      |                      |
| `ExpandedArrowImage`   | Expanded triangle (▼)             |                      |
| `CollapsedArrowImage`  | Collapsed triangle (►)            |                      |

### TileViewItem

| Property          | Replaces                          | Notes               |
|-------------------|-----------------------------------|----------------------|
| `SelectionImage`  | Selected tile background + border |                      |
| `HoverImage`      | Hovered tile background + border  |                      |

### TabItem

| Property           | Replaces                          | Notes                         |
|--------------------|-----------------------------------|-------------------------------|
| `ActiveTabImage`   | Selected tab background           |                               |
| `InactiveTabImage` | Unselected tab background         | Auto-tint lighten on hover    |

### ComboBox (additional)

| Property      | Replaces                              | Notes                    |
|---------------|---------------------------------------|--------------------------|
| `ArrowImage`  | Dropdown arrow triangle               | Auto-tint per state      |

### MenuItem

| Property          | Replaces                              | Notes               |
|-------------------|---------------------------------------|----------------------|
| `HighlightImage`  | Highlighted/pressed row background    |                      |

### MenuBarItem

| Property          | Replaces                              | Notes               |
|-------------------|---------------------------------------|----------------------|
| `HighlightImage`  | Selected/hovered/open background      |                      |

### MenuSeparator

| Property        | Replaces                              | Notes               |
|-----------------|---------------------------------------|----------------------|
| `DividerImage`  | Horizontal divider line               |                      |

### ToolBarButton

| Property        | Replaces                              | Notes                    |
|-----------------|---------------------------------------|--------------------------|
| `ButtonImage`   | Button background                     | Auto-tint per state      |

### ToolBarToggleButton

| Property        | Replaces                              | Notes                         |
|-----------------|---------------------------------------|-------------------------------|
| `ButtonImage`   | Toggle button background              | Auto-tint per state + checked |

### ToolBarSeparator

| Property        | Replaces                              | Notes               |
|-----------------|---------------------------------------|----------------------|
| `DividerImage`  | Vertical divider line                 |                      |

### Splitter

| Property      | Replaces                              | Notes                       |
|---------------|---------------------------------------|-----------------------------|
| `GripImage`   | Splitter background + grip dots       | Auto-tint on hover/drag     |

### GroupBox

| Property      | Replaces                              | Notes                            |
|---------------|---------------------------------------|----------------------------------|
| `FrameImage`  | Border lines around group             | Header + content render on top   |

### BreadcrumbItem

| Property        | Replaces                              | Notes                    |
|-----------------|---------------------------------------|--------------------------|
| `SegmentImage`  | Breadcrumb segment background         | Auto-tint on hover       |

### StatusBarItem

| Property               | Replaces                          | Notes                         |
|------------------------|-----------------------------------|-------------------------------|
| `ItemBackgroundImage`  | Item background                   | Auto-tint on hover (clickable)|

### Separator

| Property      | Replaces                              | Notes               |
|---------------|---------------------------------------|----------------------|
| `LineImage`   | Horizontal/vertical divider line      |                      |

### DockablePanel

| Property         | Replaces                              | Notes                              |
|------------------|---------------------------------------|------------------------------------|
| `FrameImage`     | Entire panel (title bar + content bg) | Title text + buttons render on top |
| `TitleBarImage`  | Title bar background + bottom border  | Used when FrameImage not set       |

### DockTabGroup

| Property           | Replaces                          | Notes                         |
|--------------------|-----------------------------------|-------------------------------|
| `TabStripImage`    | Tab strip background + border     |                               |
| `ActiveTabImage`   | Selected tab background + accent  |                               |
| `InactiveTabImage` | Unselected tab background         | Auto-tint lighten on hover    |

### FloatingWindow

| Property      | Replaces                              | Notes                    |
|---------------|---------------------------------------|--------------------------|
| `FrameImage`  | Window background + border            | Shadow always drawn      |

### DockTarget

| Property        | Replaces                              | Notes               |
|-----------------|---------------------------------------|----------------------|
| `OverlayImage`  | Semi-transparent highlight + border   |                      |

### DockZoneIndicator

| Property           | Replaces                          | Notes               |
|--------------------|-----------------------------------|----------------------|
| `ButtonImage`      | Compass button background (normal)|                      |
| `ButtonHoverImage` | Compass button background (hover) |                      |

### DataGrid

| Property              | Replaces                          | Notes               |
|-----------------------|-----------------------------------|----------------------|
| `GridBackgroundImage` | Grid background fill + border     |                      |
| `HeaderImage`         | Header row background + border    |                      |
| `RowSelectionImage`   | Selected row background color     |                      |
| `RowHoverImage`       | Hovered row background color      |                      |

### DataGridColumn

| Property          | Replaces                              | Notes                    |
|-------------------|---------------------------------------|--------------------------|
| `HeaderCellImage` | Column header cell background         | Auto-tint on hover       |

### PropertyGrid

| Property              | Replaces                          | Notes                         |
|-----------------------|-----------------------------------|-------------------------------|
| `GridBackgroundImage` | Grid background fill + border     |                               |
| `CategoryImage`       | Category header background        |                               |
| `CategoryHoverImage`  | Category header hover background  | Falls back to CategoryImage   |
| `PropertyImage`       | Property row background           |                               |
| `PropertyHoverImage`  | Property row hover background     | Falls back to PropertyImage   |

### Summary: Total Image Assets

For a **complete game UI skin**, you need up to **57 unique image properties** across
all controls. In practice, many can share the same texture (e.g., all "selection"
images can use one highlight texture, all "hover" images another).

**Minimum viable skin** (covers the most visible controls):
- 1 button background (auto-tint handles states)
- 1 panel/container background
- 1 dialog/popup frame
- 1 input field (TextBox/ComboBox) background
- 1 selection highlight
- 1 hover highlight
- 1 progress bar track + 1 fill
- 1 slider track + 1 thumb
- 1 tab (active) + 1 tab (inactive)
- 1 checkbox unchecked + 1 checked
- 1 radio unselected + 1 selected

That's roughly **15 textures** for a complete-looking game UI theme.
