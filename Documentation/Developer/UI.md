# Sedulous UI Framework

A retained-mode UI framework for the Sedulous engine. Build game menus,
HUDs, settings screens, and tool interfaces with themed controls,
CSS-inspired styling, and gamepad support.

---

## Getting Started

### Minimal Setup

```beef
// Create the UI context and root view
let uiContext = new UIContext();
let root = new RootView();
uiContext.AddRootView(root);

// Initialize the UI subsystem (rendering, fonts, input)
let ui = new UISubsystem();
ui.InitializeRendering(uiContext, root, device, swapChainFormat,
    frameCount, shaderPaths, shell, window, fontMount);
ui.LoadFont("default", "fonts/NotoSans-Regular.ttf");

// Apply a theme
let sheet = DarkTheme.Create();
uiContext.StyleSheet = sheet;
sheet.ReleaseRef();

// Add some content
let btn = new Button("Play");
btn.OnClick.Add(new (b) => { StartGame(); });
root.AddView(btn);
```

### Per-Frame Loop

```beef
// Update (input, layout, animation)
ui.Update(deltaTime);

// Render (draws UI over your scene)
ui.Render(encoder, targetView, width, height, frameIndex);
```

That's it. The subsystem handles input routing, layout, and rendering.

---

## Building UI in Code

### Layouts

Layouts are containers that arrange children. The most common is
**FlexLayout**, which works like CSS flexbox:

```beef
// Vertical column of buttons, centered, with spacing
let menu = new FlexLayout();
menu.Direction = .Vertical;
menu.JustifyContent = .Center;
menu.AlignItems = .Center;
menu.Spacing = 8;

menu.AddView(new Button("Resume"));
menu.AddView(new Button("Settings"));
menu.AddView(new Button("Quit"));

root.AddView(menu, new FlexLayout.LayoutParams() { Width = .Match, Height = .Match });
```

Children can grow to fill available space:

```beef
// Sidebar + content area
let row = new FlexLayout() { Direction = .Horizontal };

let sidebar = new Panel();
row.AddView(sidebar, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

let content = new Panel();
row.AddView(content, new FlexLayout.LayoutParams() { Grow = 1 }); // fills remaining
```

**Available layouts:**

| Layout | Use for |
|--------|---------|
| `FlexLayout` | Rows, columns, toolbars, menus. Most common. |
| `FrameLayout` | Overlapping layers (HUD over game, badges on icons). |
| `DockLayout` | Header/footer/sidebar chrome around a fill area. |
| `GridLayout` | Forms, tables, anything with rows and columns. |
| `FlowLayout` | Tag clouds, wrapping icon grids. |
| `AbsoluteLayout` | Explicit pixel positioning. |

### Sizing

Every view has a `SizeSpec` for width and height:

- **`.Wrap`** -- fit to content (default)
- **`.Match`** -- fill the parent
- **`.Fixed(.Px(200))`** -- explicit pixel size

These are set through `LayoutParams`:

```beef
let lp = new FlexLayout.LayoutParams();
lp.Width = .Match;      // fill parent width
lp.Height = .Fixed(.Px(40));  // 40px tall
lp.Margin = .(4, 8);    // 4px vertical, 8px horizontal margin
container.AddView(child, lp);
```

---

## Building UI with Markup (.sml)

For screens that don't need to change structure at runtime, define
them in XML:

**Assets/gui/screens/pause-menu.sml:**
```xml
<Flex direction="vertical" justify="center" align="center" padding="32">

  <Label id="title" text="Game Paused" font-size="28"/>
  <Spacer spacer-height="24"/>

  <Flex direction="vertical" spacing="8" width="260">
    <Button id="resume-btn" text="Resume Game" height="40"/>
    <Button id="settings-btn" text="Settings" height="40"/>
    <Separator/>
    <Button id="quit-btn" text="Quit to Menu" height="40"/>
  </Flex>

</Flex>
```

**Loading and wiring events:**
```beef
// Load from file (needs a resource provider for file access)
let mount = new FileSystemMount("Assets/gui");
let provider = new VfsResourceProvider(mount);
let menu = MarkupLoader.LoadFromFile("screens/pause-menu.sml", provider, context);

// Or load from an inline string
let menu = MarkupLoader.LoadFromString(xmlSource, context);

// Wire button events by name
if (let btn = menu.FindByName<Button>("resume-btn"))
    btn.OnClick.Add(new (b) => { ResumeGame(); });
if (let btn = menu.FindByName<Button>("quit-btn"))
    btn.OnClick.Add(new (b) => { QuitToMenu(); });

root.AddView(menu);
```

### .sml Attributes

**On any element:**

| Attribute | Example | Purpose |
|-----------|---------|---------|
| `id` | `id="health-bar"` | Name for `FindByName()` |
| `class` | `class="primary large"` | Style classes (space-separated) |
| `width` / `height` | `width="200"`, `height="match"` | Sizing: number, `match`, or `wrap` |
| `margin` | `margin="4 8"` | Outer spacing (CSS shorthand) |
| `padding` | `padding="12"` | Inner spacing |
| `visibility` | `visibility="gone"` | `visible`, `hidden`, or `gone` |
| `is-enabled` | `is-enabled="false"` | Disable interaction |
| `opacity` | `opacity="0.5"` | Transparency |
| `tooltip` | `tooltip="Click to fire"` | Hover text |

**Layout-specific (on children):**

| Attribute | Container | Example |
|-----------|-----------|---------|
| `grow` | Flex | `grow="1"` -- absorb extra space |
| `shrink` | Flex | `shrink="0"` -- don't shrink |
| `gravity` | Frame | `gravity="Center"` or `gravity="TopLeft"` |
| `dock` | Dock | `dock="top"`, `dock="left"`, `dock="fill"` |
| `row`, `column` | Grid | `row="0" column="1"` |

**Short element names:** `Flex`, `Frame`, `Dock`, `Grid`, `Flow`, `Absolute`.

---

## Theming and Styling

### Using a Built-in Theme

```beef
let sheet = DarkTheme.Create();     // or LightTheme, RoundedDarkTheme
uiContext.StyleSheet = sheet;
sheet.ReleaseRef();
```

### Loading a .sss Theme File

`.sss` is a CSS-flavored format for defining themes:

```sss
@palette my-game {
    primary:    #e67e22;
    background: #1a1a2e;
    surface:    #16213e;
    border:     #0f3460;
    text:       #eee;
    text-dim:   #888;
}

/* Global defaults */
View {
    text-color: $text;
    font-size: 14;
}

/* Buttons with state-aware background */
ButtonBase {
    background: state-list(
        normal=rounded-rect($surface, radius=4, border=$border, border-width=1),
        hover=rounded-rect($surface, radius=4, border=$primary, border-width=1),
        pressed=rounded-rect($primary, radius=4)
    );
    text-color: $text;
    padding: 8 16;
}

/* Slider sub-parts */
Slider::track {
    background: rounded-rect($border, radius=2);
    height: 4;
}
Slider::fill {
    background: rounded-rect($primary, radius=2);
}
Slider::thumb {
    background: rounded-rect($text, radius=8, border=$border, border-width=1);
    width: 16;
}
```

**Loading:**
```beef
let loader = scope StyleSheetLoader();
loader.ResourceProvider = vfsProvider;  // for @import, @icon, @image
let sheet = loader.Load(sssSource);
uiContext.StyleSheet = sheet;
sheet.ReleaseRef();
```

### How Styling Works

The style system is CSS-inspired. A `StyleSheet` contains rules, each
with a selector and properties. When a control draws itself, it asks
the stylesheet for property values. The most specific matching rule wins.

**Selectors match by:**
- **Type** -- `Button { ... }` matches all Buttons (and subclasses)
- **Class** -- `.primary { ... }` matches views with `AddClass("primary")`
- **State** -- `Button:hover { ... }` matches when hovered
- **Pseudo-element** -- `Slider::thumb { ... }` targets the thumb part

**Specificity** (higher wins): each class = 10, type = 1, state = 1,
pseudo-element = 1.

**Pseudo-elements** let you style the internal parts of composite
controls without those parts being separate views:

```sss
/* Style the checkbox indicator differently when checked */
CheckBox::box {
    background: rounded-rect($surface, radius=2, border=$border, border-width=1);
    width: 18;
}
CheckBox::box:checked {
    background: rounded-rect($primary, radius=2);
}
CheckBox::checkmark {
    background: svg(checkmark);
}
```

**All pseudo-elements by control:**

| Control | Parts |
|---------|-------|
| Slider | `::track`, `::fill`, `::thumb` |
| ProgressBar | `::track`, `::fill` |
| ScrollBar | `::track`, `::thumb` |
| ToggleSwitch | `::track` (+ `:checked`), `::knob` |
| CheckBox | `::box` (+ `:checked`), `::checkmark` |
| RadioButton | `::box` (+ `:checked`), `::mark` |
| TabView | `::strip`, `::content`, `::tab` (+ `:checked`/`:hover`), `::close-button` |
| Expander | `::header` (+ `:hover`), `::chevron` (+ `:checked` = expanded) |
| NumericField | `::spin-up`, `::spin-down`, `::arrow-up`, `::arrow-down` |
| ComboBox | `::arrow` |
| TreeView | `::chevron` (+ `:checked` = expanded) |

### Style Classes

Add classes to views for targeted styling:

```beef
let btn = new Button("Fire!");
btn.AddClass("danger");  // matches .danger { ... } rules
```

```sss
.danger {
    background: state-colors(#c0392b);
    text-color: white;
}
```

### Per-Instance Overrides

Two paths for overriding the stylesheet on a single view: typed
properties on the control, and inline styles via `SetStyle`.

**Typed properties** — `Property<T>` fields on the control. `null`
means "defer to the cascade":

```beef
label.FontSize.Value = 24;
label.TextColor.Value = .(255, 0, 0, 255);
label.FontFamily.Value = new String("Roboto");
```

These exist on `Label`, `Button`, `CheckBox`, `EditableLabel`,
and `RadioButton`. The Property setters mark the visual dirty so
re-layout happens automatically.

**Inline styles** — `SetStyle(prop, value)` writes to the view's
internal inline `StyleSheet`. Any property goes through this path,
not just the ones with a typed field:

```beef
panel.SetStyle(.Background, new ColorDrawable(.Red));    // consumes ref
panel.SetStyle(.Padding, Thickness(14, 8));
label.SetStyle(.FontSize, 22f);
label.SetStyle(.FontFamily, "JungleAdventurer");
slider.SetPartStyle("thumb", .Background, drawable);     // pseudo-element

label.GetInlineStyle(.FontSize);    // round-trip
label.HasInlineStyle(.FontSize);
label.ClearInlineStyle(.FontSize);
label.ClearInlineStyles();           // wipe every inline override
```

The Drawable overload consumes the caller's ref by default
(`consumeRef: true`); pass `consumeRef: false` to AddRef instead
when the drawable is shared.

Inline values beat every rule match — they're effectively
"specificity infinity" in the cascade.

### LocalStyleSheet

Any view can hold a `LocalStyleSheet` (a `RefCounted` `StyleSheet`)
that applies to the view and its descendants. The resolution cascade
walks the ancestor chain consulting each `LocalStyleSheet` before
falling through to the context sheet. Use this to scope a theming
change to a Dialog, a pause menu, or any subtree without mutating
the global theme.

```beef
let scoped = new StyleSheet();
scoped.ForType(typeof(Label))
    .Set(.FontSize, 14f)
    .Set(.TextColor, Color(210, 215, 225, 255));
scoped.ForAll().Set(.FontFamily, "JungleAdventurer");  // every view inherits

pauseRoot.LocalStyleSheet = scoped;
scoped.ReleaseRef();   // setter AddRef'd; release the creator's ref
```

The setter mirrors `UIContext.StyleSheet` exactly — AddRefs the new
value, Releases the previous, no-ops on an identical assignment.
Multiple views can safely share one `LocalStyleSheet`.

### Inline styles in markup

`.sml` accepts a generic `style="..."` attribute on any view tag.
The body parses with the same lexer / parser as `.sss` declarations:

```xml
<Label text="Big" style="font-size: 22; text-color: #ffdc64; font-family: Roboto;"/>
<Button text="Buy" style="background: state-rounded(rgb(40, 120, 60), radius=6);"/>
<Panel style="background: rounded-rect(rgb(35, 38, 48), radius=12, border-width=2, border=rgb(80, 90, 110));"/>
```

Drawable values are owned by the view's inline sheet, so they're
released when the view dies. Theme variables (`$name`) and `@`-rules
are not supported inline.

The five controls with typed Properties also accept dedicated
markup attributes for ergonomics:

```xml
<Label font-size="22" font-family="Roboto" text="Hello"/>
<Button font-size="14" font-family="JungleAdventurer" text="Play"/>
```

### Cascade resolution

`view.ResolveStyle(prop)` walks four sources in order:

1. Inline sheet on this view (specificity infinity).
2. Ancestor chain (self → root) consulting each `LocalStyleSheet`.
   "Not found" falls through to the next ancestor.
3. Context `StyleSheet`.
4. For inheritable properties (`TextColor`, `FontSize`,
   `FontFamily`), recurse the whole algorithm at `Parent`.

The same orchestrator handles pseudo-element queries via
`ResolvePartStyle(part, prop, state)`.

### ForAll() rule

A `ForAll()` rule has an empty selector (specificity 0) and matches
every view. Useful on a `LocalStyleSheet` to set one property for an
entire subtree regardless of type:

```beef
local.ForAll().Set(.FontFamily, "Roboto");  // every descendant inherits
```

Compare with `sheet.ForType(typeof(View))` — same effect on the
match side, but specificity 1, so it loses to any other typed rule
on the same sheet. Use `ForAll()` when you want the lowest-priority
"default for everything."

### .sss Reference

**Color values:**
```sss
#e67e22                     /* hex */
rgb(230, 126, 34)           /* RGB */
rgba(230, 126, 34, 0.8)     /* RGBA */
$primary                    /* palette variable */
lighten($surface, 0.15)     /* lighter */
darken($primary, 0.1)       /* darker */
alpha(white, 0.5)           /* transparency */
mix(#fff, #000, 0.5)        /* blend */
```

**Drawable factories:**
```sss
color(#fff)                                    /* solid fill */
rounded-rect(#fff, radius=6)                   /* rounded rectangle */
rounded-rect(#fff, radius=6, border=#000, border-width=1)
gradient(top-to-bottom, #fff, #000)            /* linear gradient */
state-list(normal=..., hover=..., pressed=...) /* per-state drawables */
state-colors(#444)                             /* auto-generates hover/pressed/disabled */
state-rounded(#444, radius=4)                  /* same, rounded */
svg(icon-name)                                 /* SVG icon */
svg(icon-name, tint=#fff)                      /* SVG with tint */
nine-slice(image-name, 8 8 8 8)                /* 9-slice image */
layer(drawable1, drawable2)                    /* stacked drawables */
inset(drawable, 4 4 4 4)                       /* inset wrapper */
```

**Directives:**
```sss
@palette name { var: value; }             /* define color variables */
@palette child extends parent { ... }     /* extend a palette */
@icon name "path/to/icon.svg";            /* register SVG from file */
@image name "path/to/texture.png";        /* register image from file */
@import "shared-base.sss";               /* include another stylesheet */
```

**Properties:**
```sss
/* Drawables */
background: ...;
checked-background: ...;

/* Colors (text-color, font-size, font-family inherit through parent chain) */
text-color: #fff;
placeholder-color: #888;
border-color: #444;
cursor-color: $primary;
selection-color: rgba(60, 120, 200, 0.4);
accent-color: $primary;

/* Dimensions */
font-size: 14;
corner-radius: 4;
border-width: 1;
spacing: 8;
opacity: 0.5;
width: 16;       /* for pseudo-elements */
height: 4;       /* for pseudo-elements */

/* Spacing */
padding: 8 12;   /* top/bottom 8, left/right 12 */
margin: 4;

/* Strings (font-family accepts bare ident or quoted string) */
font-family: Roboto;
font-family: "Attack Of Monster";

/* Text */
word-wrap: true;
```

---

## Controls Quick Reference

### Buttons

```beef
// Simple button
let btn = new Button("Play");
btn.OnClick.Add(new (b) => { StartGame(); });

// Toggle
let mute = new ToggleButton();
mute.IsChecked.Value = false;

// Repeat (fires while held, e.g. for a fire button)
let fire = new RepeatButton();
fire.RepeatInterval = 0.05f;
fire.OnClick.Add(new (b) => { FireBullet(); });
```

### Text Input

```beef
// Single-line text field
let name = new EditText();
name.Placeholder.Value = "Enter name";
name.OnSubmit.Add(new (e) => { AcceptName(e.Text); });

// Numeric with spin buttons
let hp = new NumericField();
hp.Min = 0; hp.Max = 999; hp.Step = 1;
hp.Value = 100;

// Slider
let volume = new Slider(0, 1, 0.8f);
volume.Step.Value = 0.05f;
volume.OnValueChanged.Add(new (s, val) => { SetVolume(val); });
```

### Selection

```beef
// Checkbox
let fullscreen = new CheckBox("Fullscreen");
fullscreen.OnCheckedChanged.Add(new (c, on) => { ToggleFullscreen(on); });

// Radio buttons (mutual exclusion via RadioGroup)
let group = new RadioGroup();
let easy = new RadioButton("Easy");
let hard = new RadioButton("Hard");
group.Add(easy);
group.Add(hard);

// Dropdown
let res = new ComboBox();
res.AddItem("1280x720");
res.AddItem("1920x1080");
res.SelectedIndex = 0;

// Toggle switch
let vsync = new ToggleSwitch("V-Sync");
```

### Containers

```beef
// Scrollable area
let scroll = new ScrollView();
scroll.VScrollBarPolicy.Value = .Auto;
scroll.SetContent(longContent);

// Tabs
let tabs = new TabView();
tabs.AddTab("Video", videoPanel);
tabs.AddTab("Audio", audioPanel);
tabs.AddTab("Controls", controlsPanel);

// Collapsible section
let advanced = new Expander("Advanced");
advanced.SetContent(advancedOptions);
advanced.IsExpanded = false;
```

### Data Lists

```beef
// Virtualized list (only visible items are created)
let list = new ListView();
list.SetAdapter(myAdapter);
list.ItemHeight.Value = 28;
list.OnItemClicked.Add(new (pos, clicks, x, y) => { SelectItem(pos); });
```

Adapters provide data:
```beef
public class InventoryAdapter : IListAdapter
{
    public int Count => mItems.Count;

    public View CreateView(int position)
    {
        return new Label();  // reusable view template
    }

    public void BindView(View view, int position)
    {
        (view as Label).Text.Value = mItems[position].Name;
    }
}
```

### Display

```beef
let hp = new ProgressBar();
hp.Value.Value = 0.75f;  // 75%

let icon = new ImageView();
icon.Image = loadedImage;
icon.ScaleType.Value = .FitCenter;

let swatch = new ColorView();
swatch.Color.Value = .(255, 0, 0, 255);
```

---

## Handling Input

### Mouse Events

Override `OnMouseDown`, `OnMouseUp`, `OnMouseMove` on any View:

```beef
public override void OnMouseDown(MouseEventArgs e)
{
    if (e.Button == .Left)
    {
        DoSomething(e.X, e.Y);
        e.Handled = true;  // stops bubble propagation
    }
}
```

Events propagate in three phases:
1. **Capture** (root to target) -- `OnMouseDownCapture` on ancestors
2. **Target** -- `OnMouseDown` on the hit view
3. **Bubble** (target to root) -- `OnMouseDown` on ancestors

Set `e.Handled = true` at any phase to stop propagation.

### Keyboard Events

```beef
public override void OnKeyDown(KeyEventArgs e)
{
    if (e.Key == .Space) { Jump(); e.Handled = true; }
}
```

### Focus and Gamepad Navigation

The framework handles Tab navigation and gamepad input automatically.
All focusable controls (buttons, checkboxes, text fields, etc.) work
out of the box with:

- **Tab / Shift+Tab** -- cycle through focusable controls
- **Arrow keys** -- move focus directionally (spatial nearest-neighbor)
- **Enter** -- activate focused control (click button, toggle checkbox, etc.)
- **Escape** -- cancel (close popup, etc.)
- **Gamepad D-pad** -- directional focus movement
- **Gamepad A** -- activate, **B** -- cancel

For explicit focus wiring between specific controls:
```beef
settingsBtn.NextFocusDown = quitBtn.Id;
quitBtn.NextFocusUp = settingsBtn.Id;
```

Controls that consume arrow keys internally (EditText, Slider, TabView,
ListView, etc.) handle them first. Unhandled arrows fall through to
focus navigation.

---

## Popups, Menus, and Dialogs

### Context Menu

```beef
public override void OnMouseDown(MouseEventArgs e)
{
    if (e.Button == .Right)
    {
        let menu = new ContextMenu();
        menu.AddItem("Attack", new () => { Attack(); });
        menu.AddItem("Defend", new () => { Defend(); });
        menu.AddSeparator();
        let sub = menu.AddSubmenu("Items");
        sub.Submenu.AddItem("Potion", new () => { UsePotion(); });
        sub.Submenu.AddItem("Bomb", new () => { UseBomb(); });
        menu.Show(Context, e.X, e.Y);
        e.Handled = true;
    }
}
```

### Modal Dialog

```beef
let dlg = Dialog.Confirm("Quit Game", "Are you sure you want to quit?");
dlg.OnClosed.Add(new (result) => {
    if (result == .OK) QuitGame();
});
dlg.Show(context);
```

### Tooltips

```beef
// Simple text tooltip (automatic on hover)
button.TooltipText = "Fires your weapon";

// Custom content: implement ITooltipProvider on your view
```

---

## Drag and Drop

Make a view draggable by implementing `IDragSource`:

```beef
public class InventorySlot : View, IDragSource
{
    public DragData CreateDragData() => new DragData("inventory-item");
    public View CreateDragVisual(DragData data) => new Label(mItem.Name);
    public void OnDragStarted(DragData data) { }
    public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
    {
        if (effect == .Move) RemoveItem();
    }
}
```

Accept drops by implementing `IDropTarget`:

```beef
public class EquipmentSlot : View, IDropTarget
{
    public DragDropEffects CanAcceptDrop(DragData data, float x, float y)
        => (data.Format == "inventory-item") ? .Move : .None;

    public DragDropEffects OnDrop(DragData data, float x, float y)
    {
        EquipItem(data);
        return .Move;
    }

    public void OnDragEnter(DragData data, float x, float y) { ShowHighlight(); }
    public void OnDragLeave(DragData data) { HideHighlight(); }
    public void OnDragOver(DragData data, float x, float y) { }
}
```

---

## Creating Custom Views

### Simple Custom View

```beef
public class HealthBar : View
{
    public float Health = 1.0f;

    protected override void OnMeasure(BoxConstraints constraints)
    {
        MeasuredSize = .(constraints.ConstrainWidth(200),
                         constraints.ConstrainHeight(20));
    }

    public override void OnDraw(UIDrawContext ctx)
    {
        // Background
        ctx.VG.FillRect(.(0, 0, Width, Height), .(40, 40, 40, 255));

        // Fill
        let fillW = Width * Math.Clamp(Health, 0, 1);
        let color = (Health > 0.5f) ? Color(80, 200, 80, 255) : Color(200, 80, 80, 255);
        ctx.VG.FillRect(.(0, 0, fillW, Height), color);
    }
}
```

### Custom Container

```beef
public class HorizontalStack : ViewGroup
{
    public float Spacing = 4;

    protected override void OnMeasure(BoxConstraints constraints)
    {
        float totalW = 0, maxH = 0;
        for (int i = 0; i < ChildCount; i++)
        {
            let child = GetChildAt(i);
            child.Measure(constraints.Loosen());
            totalW += child.MeasuredSize.X;
            maxH = Math.Max(maxH, child.MeasuredSize.Y);
        }
        totalW += Spacing * Math.Max(0, ChildCount - 1);
        MeasuredSize = .(constraints.ConstrainWidth(totalW),
                         constraints.ConstrainHeight(maxH));
    }

    protected override void OnLayout(float left, float top, float width, float height)
    {
        float x = 0;
        for (int i = 0; i < ChildCount; i++)
        {
            let child = GetChildAt(i);
            child.Layout(x, 0, child.MeasuredSize.X, height);
            x += child.MeasuredSize.X + Spacing;
        }
    }

    public override void OnDraw(UIDrawContext ctx)
    {
        DrawChildren(ctx);
    }
}
```

### Using the Styled Drawing System

When your custom control should respond to themes:

```beef
public override void OnDraw(UIDrawContext ctx)
{
    let bg = ResolveStyleDrawable(.Background);
    if (bg != null)
        bg.Draw(ctx, .(0, 0, Width, Height), GetControlState());

    let textColor = ResolveStyleColor(.TextColor, .(255, 255, 255, 255));
    let fontSize = ResolveStyleFloat(.FontSize, 14);
    // ...
}
```

For sub-parts, use pseudo-element resolution:

```beef
// In your control's OnDraw:
let trackBg = ResolvePartDrawable("track", .Background, GetControlState());
let thumbBg = ResolvePartDrawable("thumb", .Background, GetControlState());
let thumbSize = ResolvePartFloat("thumb", .Width, GetControlState(), 16);
```

Then style it in .sss:
```sss
MyControl::track { background: rounded-rect($border, radius=2); height: 4; }
MyControl::thumb { background: rounded-rect($text, radius=8); width: 16; }
```

---

## Programmatic Themes

For themes that can't be expressed in .sss (e.g., using generated images
or atlas textures), build themes in code:

```beef
public static StyleSheet CreateGameTheme()
{
    let sheet = new StyleSheet();
    let p = ThemePalette.Dark;

    // Global text defaults (inheritable)
    sheet.ForType(typeof(View))
        .Set(.TextColor, p.Text)
        .Set(.FontSize, 16.0f);

    // Buttons with auto-generated state variants
    let btnBg = Palette.CreateStateRounded(p.SurfaceBright, 4);
    sheet.OwnDrawable(btnBg);
    sheet.ForType(typeof(ButtonBase))
        .Set(.Background, btnBg)
        .Set(.Padding, Thickness(12, 8));

    // Slider parts
    sheet.ForTypePseudo(typeof(Slider), "track")
        .Set(.Background, sheet.OwnColor(p.Border))
        .Set(.Height, 4.0f);
    sheet.ForTypePseudo(typeof(Slider), "thumb")
        .Set(.Background, sheet.OwnColor(p.Text))
        .Set(.Width, 16.0f);

    return sheet;
}
```

`Palette.CreateStateColors(baseColor)` auto-generates hover (lighter),
pressed (darker), and disabled (grayed) variants.
`Palette.CreateStateRounded(baseColor, radius)` does the same with
rounded rectangles.

### Theme Extensions

Register extensions to inject rules for your own controls into any theme:

```beef
public class MyGameThemeExtension : IThemeExtension
{
    public void Apply(StyleSheet sheet, ThemePalette p)
    {
        sheet.ForType(typeof(HealthBar))
            .Set(.Background, sheet.OwnColor(.(40, 40, 40, 255)))
            .Set(.AccentColor, p.Success);
    }
}

// Register before creating themes
ThemeRegistry.RegisterExtension(new MyGameThemeExtension());
```

---

## Resource Loading

The framework uses `IResourceProvider` to load .sml files, .sss imports,
SVG icons, and images:

```beef
// File-system backed provider
let mount = new FileSystemMount("Assets/gui");
let provider = new VfsResourceProvider(mount);

// Load a stylesheet that uses @import and @icon
let loader = scope StyleSheetLoader();
loader.ResourceProvider = provider;
let sheet = loader.Load(sssSource);

// Load markup
let view = MarkupLoader.LoadFromFile("screens/menu.sml", provider, context);
```

---

## Common Patterns

### Game Pause Menu

```beef
void ShowPauseMenu()
{
    let menu = MarkupLoader.LoadFromFile("screens/pause-menu.sml", mProvider, mContext);
    mRoot.AddView(menu, new FlexLayout.LayoutParams() { Width = .Match, Height = .Match });

    if (let btn = menu.FindByName<Button>("resume-btn"))
        btn.OnClick.Add(new [&] (b) => { HidePauseMenu(); });
    if (let btn = menu.FindByName<Button>("quit-btn"))
        btn.OnClick.Add(new [&] (b) => { QuitToMainMenu(); });
}
```

### HUD Overlay

```beef
// FrameLayout lets HUD elements overlap the viewport
let hud = new FrameLayout();

// Health bar in top-left
let hp = new HealthBar();
hud.AddView(hp, new FrameLayout.LayoutParams()
    { Gravity = .TopLeft, Width = .Fixed(.Px(200)), Height = .Fixed(.Px(20)), Margin = .(8) });

// Score in top-right
let score = new Label("Score: 0");
score.HAlign.Value = .Right;
hud.AddView(score, new FrameLayout.LayoutParams() { Gravity = .TopRight, Margin = .(8) });

// Minimap in bottom-right
let minimap = new ImageView();
hud.AddView(minimap, new FrameLayout.LayoutParams()
    { Gravity = .BottomRight, Width = .Fixed(.Px(150)), Height = .Fixed(.Px(150)), Margin = .(8) });
```

### Settings Screen

```beef
let settings = new FlexLayout() { Direction = .Vertical, Spacing = 12 };
settings.Padding = .(16);

// Volume slider with label
let volRow = new FlexLayout() { Direction = .Horizontal, Spacing = 8 };
volRow.AddView(new Label("Volume"));
let vol = new Slider(0, 1, 0.8f);
vol.Step.Value = 0.05f;
vol.OnValueChanged.Add(new (s, v) => { SetVolume(v); });
volRow.AddView(vol, new FlexLayout.LayoutParams() { Grow = 1 });
settings.AddView(volRow, new FlexLayout.LayoutParams() { Width = .Match });

// Resolution dropdown
let resRow = new FlexLayout() { Direction = .Horizontal, Spacing = 8 };
resRow.AddView(new Label("Resolution"));
let res = new ComboBox();
res.AddItem("1280x720");
res.AddItem("1920x1080");
res.SelectedIndex = 1;
resRow.AddView(res, new FlexLayout.LayoutParams() { Grow = 1 });
settings.AddView(resRow, new FlexLayout.LayoutParams() { Width = .Match });

// Fullscreen toggle
let fs = new CheckBox("Fullscreen");
fs.IsChecked.Value = true;
settings.AddView(fs);
```

---

## Toolkit Controls

The `Sedulous.UI.Toolkit` library adds editor-grade controls on top of
the core framework:

- **MenuBar** -- Horizontal menu bar with dropdown menus
- **Toolbar** -- Button strip with toggles and separators
- **StatusBar** -- Bottom status bar with text sections
- **SplitView** -- Resizable split pane
- **BreadcrumbBar** -- Path navigation
- **ColorPicker / HDRColorPicker** -- Color selection with hex input
- **PropertyGrid** -- Typed property editor (bool, float, int, string,
  range, enum, color, vector3)
- **DockManager** -- VS Code-style docking with tab groups and
  floating windows
- **NodeGraphCanvas** -- Node-based visual editor
- **DraggableTreeView** -- TreeView with drag-to-reorder
- **VectorFields** -- Vector2/3/4/Quaternion field groups

Toolkit controls are themed via `ToolkitThemeExtension`:
```beef
ThemeRegistry.RegisterExtension(new ToolkitThemeExtension());
```
