# Sedulous.UI — Usage Manual

## ScrollView and Layout Weights

### The Problem

`ScrollView` measures its content with `Unspecified` height (infinite space)
on the scroll axis. Children that use **weight-based sizing** (`Weight = 1`,
`Height = MatchParent`) collapse to zero height because there is no finite
parent size to distribute proportionally.

This affects `ListView`, `TreeView`, nested `ScrollView`, and any child
relying on `LinearLayout` weight distribution inside a `ScrollView`.

### The Fix

Use **fixed pixel heights** for controls that need a definite size inside a
scroll container. All other children should use `WrapContent` or explicit
heights so they report their natural size.

```
// WRONG — collapses to zero inside ScrollView:
list.AddView(listView, new LinearLayout.LayoutParams() {
    Width = LayoutParams.MatchParent,
    Height = LayoutParams.MatchParent,
    Weight = 1
});

// CORRECT — fixed height works inside ScrollView:
list.AddView(listView, new LinearLayout.LayoutParams() {
    Width = LayoutParams.MatchParent,
    Height = 200
});
```

### Full Pattern: Scrollable Page Layout

```beef
// 1. Root ScrollView fills the window
let scroll = new ScrollView();
scroll.VScrollPolicy = .Auto;
scroll.HScrollPolicy = .Never;
root.AddView(scroll);

// 2. Content layout uses WrapContent height (not weight)
let main = new LinearLayout();
main.Orientation = .Vertical;
main.Spacing = 8;
scroll.AddView(main, new LayoutParams() { Width = LayoutParams.MatchParent });

// 3. Fixed-size sections
main.AddView(header, new LinearLayout.LayoutParams() {
    Width = LayoutParams.MatchParent, Height = 30
});

// 4. Columns use weight for WIDTH (constrained axis), WrapContent for HEIGHT
let columns = new LinearLayout();
columns.Orientation = .Horizontal;
main.AddView(columns, new LinearLayout.LayoutParams() {
    Width = LayoutParams.MatchParent
});

let left = new LinearLayout();
left.Orientation = .Vertical;
columns.AddView(left, new LinearLayout.LayoutParams() {
    Width = LayoutParams.MatchParent, Weight = 1  // width weight OK
});

// 5. ListView/TreeView get fixed pixel heights
left.AddView(listView, new LinearLayout.LayoutParams() {
    Width = LayoutParams.MatchParent, Height = 200
});
left.AddView(treeView, new LinearLayout.LayoutParams() {
    Width = LayoutParams.MatchParent, Height = 180
});
```

**Why this works:** All children have intrinsic heights (fixed or
wrap-content). The content stacks taller than the viewport, enabling
vertical scrolling. Horizontal weight distribution still works because the
horizontal axis is constrained by the ScrollView's width.

### Rule of Thumb

- **Weight** works when the parent has a **definite size** on that axis.
- **ScrollView** makes the scroll axis **indefinite**.
- Use **fixed heights** or **WrapContent** inside ScrollView, never weight.

---

## Tooltips

### Basic Text Tooltip

Set `TooltipText` on any view. The tooltip appears after a 0.5s hover delay
and auto-hides after 5s.

```beef
let btn = new Button();
btn.SetText("Save");
btn.TooltipText = new String("Save the current document");
```

### Tooltip Placement

Control where the tooltip appears relative to the anchor view:

```beef
btn.TooltipPlacement = .Bottom;  // default — below, flips above if clipped
btn.TooltipPlacement = .Top;     // above, flips below if clipped
btn.TooltipPlacement = .Right;   // right side, flips left if clipped
btn.TooltipPlacement = .Left;    // left side, flips right if clipped
```

All placements automatically flip to the opposite side when clipped by the
screen edge, then clamp to screen bounds as a final fallback.

### Rich Tooltip Content (ITooltipProvider)

For tooltips with images, buttons, or custom layouts, implement
`ITooltipProvider` on your view:

```beef
class MyView : View, ITooltipProvider
{
    public View CreateTooltipContent()
    {
        let layout = new LinearLayout();
        layout.Orientation = .Vertical;
        layout.Spacing = 4;

        let img = new ImageView();
        img.Image = myImage;
        layout.AddView(img, new LinearLayout.LayoutParams() {
            Width = 64, Height = 64
        });

        let label = new Label();
        label.SetText("Description text");
        layout.AddView(label);

        return layout;  // ownership transfers to TooltipView
    }
}
```

`ITooltipProvider.CreateTooltipContent()` takes priority over `TooltipText`.
Return `null` to suppress the tooltip.

### Interactive Tooltips

Set `IsTooltipInteractive = true` to keep the tooltip visible when the user
hovers over it. This allows interaction with tooltip content (clicking
buttons, selecting text, etc.):

```beef
view.IsTooltipInteractive = true;
```

Non-interactive tooltips (the default) are hit-test transparent — mouse
events pass through them to the content below.

---

## Context Menu Positioning

Context menus automatically flip when they would clip screen edges:

- **Root menu:** Flips left if clipping right edge, flips up if clipping
  bottom edge.
- **Submenus:** Flip to open leftward if clipping right edge, clamp
  vertically.

```beef
// Show at mouse position — auto-clamps to screen
contextMenu.Show(uiContext, mouseX, mouseY);
```
