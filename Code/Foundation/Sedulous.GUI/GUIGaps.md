# Sedulous.GUI Gaps Analysis

Comparison of Sedulous.UI vs Sedulous.GUI to identify gaps and areas for improvement.

## Summary

**Sedulous.GUI** is the newer, more feature-rich framework with ~128 files and many advanced controls.
**Sedulous.UI** is the older framework with ~68 files but has some features Sedulous.GUI lacks.

---

## Things Sedulous.UI Does Better

### 1. Animation Types
Sedulous.UI has additional animation types that Sedulous.GUI is missing:
- **Vector2Animation** - Animate 2D positions/offsets
- **RectangleAnimation** - Animate rectangular bounds

*Sedulous.GUI only has: FloatAnimation, ColorAnimation, ThicknessAnimation*

### 2. Double-Click Detection
Sedulous.UI has **system-level double-click detection** in InputManager:
- Tracks click count (1, 2, 3+)
- Configurable timing (500ms) and distance (4px) thresholds
- `ClickCount` property on MouseButtonEventArgs
- ListBox, TreeView, TileView all expose `ItemDoubleClick` events

*Sedulous.GUI only has double-click handling in TextBox/PasswordBox for word selection, not as a general input feature.*

### 3. Popup Control
Sedulous.UI has a dedicated **Popup** class with:
- Anchor element support
- PopupPlacement (Bottom, Top, Left, Right, Center, Absolute, Mouse)
- PopupBehavior flags (Modal, CloseOnClickOutside, CloseOnEscape)
- HorizontalOffset/VerticalOffset
- Open/Close events

*Sedulous.GUI has PopupLayer for internal popup management but no standalone Popup control for user consumption.*

### 4. Style System
Sedulous.UI has a more formal **Style** class with:
- Per-control-type style registration
- Named color/float/thickness properties
- StateStyle for per-state overrides

*Sedulous.GUI uses Palette with computed state colors but lacks a formal Style registry pattern.*

---

## Things Sedulous.GUI Has That Sedulous.UI Lacks

### Controls
| Control | Description |
|---------|-------------|
| **DataGrid** | Full tabular data display with sortable/resizable columns, extended selection |
| **DataGridColumn** | Column definitions (Text, CheckBox variants) |
| **PropertyGrid** | Object property inspector for editor UIs |
| **PasswordBox** | Masked password input |
| **Hyperlink** | Clickable link control |
| **ToggleSwitch** | Modern toggle switch (vs ToggleButton) |
| **NumericUpDown** | Numeric spinner with up/down buttons |
| **RepeatButton** | Button that fires repeatedly while held |
| **Flyout** | Light-dismiss popup overlay |
| **Menu / MenuBarItem** | Full menu bar (not just ContextMenu) |
| **ToolBar / ToolBarButton** | Toolbar with buttons, toggles, separators |
| **Breadcrumb / BreadcrumbItem** | Navigation breadcrumb |
| **GroupBox** | Labeled content grouping |
| **Expander** | Collapsible content container |
| **TabControl / TabItem** | Tabbed interface |
| **StatusBar / StatusBarItem** | Application status bar |

### Layouts
| Layout | Description |
|--------|-------------|
| **UniformGrid** | Grid with equal-sized cells |

### Animation
| Feature | Description |
|---------|-------------|
| **Storyboard** | Animation sequencing with timing offsets |

### Architecture
| Feature | Description |
|---------|-------------|
| **ICommand / RelayCommand** | Command pattern for MVVM-style action binding |
| **UndoStack** | Undo/Redo history management |
| **TextEditingBehavior** | Reusable text editing logic |
| **TooltipService** | Centralized tooltip management as a service |
| **ModalManager** | Modal dialog stacking and focus confinement |
| **Palette** | Color palette with computed state variations (Hover, Pressed, Disabled) |

---

## Recommendations

### High Priority (Core Functionality)

1. **Add Vector2Animation and RectangleAnimation**
   - Common for position/bounds animations
   - Easy to implement following existing animation patterns

2. **Add System-Level Double-Click Detection**
   - Add `ClickCount` to MouseButtonEventArgs
   - Track timing/distance in InputManager
   - Add `ItemDoubleClick` events to ListBox, TreeView, TileView, DataGrid

3. **Add Standalone Popup Control**
   - Wrap PopupLayer functionality in a user-friendly Popup class
   - Support placement modes and behavior flags

### Medium Priority (Polish)

4. **Add Style Registry Pattern**
   - Allow registering default styles per control type
   - Enable style inheritance and overrides

5. **Port ItemDoubleClick Events**
   - ListBox, TreeView, TileView should expose ItemDoubleClick
   - Useful for "activate" actions on list items

### Low Priority (Nice to Have)

6. **Consider Porting Missing Controls from Sedulous.UI**
   - If any Sedulous.UI controls are more mature, consider merging improvements

---

## Feature Parity Checklist

### Input System
- [x] Mouse move/enter/leave
- [x] Mouse buttons (down/up/click)
- [x] Mouse wheel
- [ ] Double-click detection with ClickCount
- [x] Keyboard input
- [x] Text input
- [x] Focus management
- [x] Tab navigation
- [x] Drag and drop
- [x] Mouse capture

### Animation System
- [x] FloatAnimation
- [x] ColorAnimation
- [x] ThicknessAnimation
- [ ] Vector2Animation
- [ ] RectangleAnimation
- [x] Storyboard
- [x] Easing functions
- [x] Auto-reverse
- [x] Repeat behavior

### Theming
- [x] Theme interface
- [x] Dark/Light/Game themes
- [x] Palette with state colors
- [ ] Formal Style registry

### Popups
- [x] ContextMenu
- [x] Tooltip / TooltipService
- [x] PopupLayer (internal)
- [ ] Popup control (user-facing)
- [x] Flyout
- [x] Dialog / MessageBox

---

## Notes

- Sedulous.GUI is clearly the more actively developed framework
- Most gaps are minor or edge cases
- The command pattern (ICommand) is valuable for editor applications
- Double-click detection would improve UX significantly
- Vector2/Rectangle animations are useful for position-based effects
