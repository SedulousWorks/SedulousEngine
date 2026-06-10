# Input

Sedulous provides two layers of input: raw device access via `IShell.InputManager` and a higher-level action/binding system via `Sedulous.Engine.Input`.

## Raw Input (Shell Layer)

Direct device state queries through `Shell.InputManager`:

### Keyboard

```beef
let keyboard = Shell.InputManager.Keyboard;

// Continuous state (held down)
if (keyboard.IsKeyDown(.W))
    MoveForward(deltaTime);

// Single-frame press/release (true for one frame only)
if (keyboard.IsKeyPressed(.Space))
    Jump();

if (keyboard.IsKeyReleased(.Escape))
    PauseGame();
```

### Mouse

```beef
let mouse = Shell.InputManager.Mouse;

// Position (window-local)
let x = mouse.X;
let y = mouse.Y;

// Global position (desktop coordinates)
let globalX = mouse.GlobalX;
let globalY = mouse.GlobalY;

// Buttons
if (mouse.IsButtonDown(.Left))
    Shoot();

// Relative movement (for FPS camera)
let deltaX = mouse.DeltaX;
let deltaY = mouse.DeltaY;

// Scroll wheel
let scroll = mouse.ScrollDelta;
```

### Mouse Capture

For FPS-style camera control, capture the mouse to hide the cursor and get raw deltas:

```beef
if (keyboard.IsKeyPressed(.Tab))
{
    mCaptured = !mCaptured;
    mouse.SetRelativeMode(mCaptured);
}
```

## Input Action System (Engine Layer)

The action system decouples game logic from specific keys/buttons. Define named actions with multiple bindings, then query actions instead of raw keys. This makes input remappable and supports multiple input devices.

### Setup

Register `InputSubsystem` in `OnConfigure`:

```beef
using Sedulous.Engine.Input;

protected override void OnConfigure(Context context)
{
    context.RegisterSubsystem(new InputSubsystem(Shell.InputManager));
}
```

### Input Contexts

Group related actions into contexts. Different game states use different contexts:

```beef
let inputSub = Context.GetSubsystem<InputSubsystem>();

// Create a gameplay context
let gameplay = inputSub.CreateContext("Gameplay", priority: 0);

// Create a menu context (higher priority, blocks gameplay input)
let menu = inputSub.CreateContext("Menu", priority: 10);
menu.BlocksInput = true;
menu.Enabled = false;  // Disabled until menu opens
```

### Defining Actions

Actions are named and can have multiple bindings (keyboard, mouse, gamepad):

```beef
// Button action: Jump
let jump = gameplay.RegisterAction("Jump");
jump.AddBinding(new KeyBinding(.Space));
jump.AddBinding(new GamepadButtonBinding(.A));

// Axis action: MoveForward (W/S keys as 1.0/-1.0)
let moveForward = gameplay.RegisterAction("MoveForward");
moveForward.AddBinding(new KeyBinding(.W, value: 1.0f));
moveForward.AddBinding(new KeyBinding(.S, value: -1.0f));
moveForward.AddBinding(new GamepadAxisBinding(.LeftY));

// 2D composite: Move (WASD -> Vector2)
let move = gameplay.RegisterAction("Move");
move.AddBinding(new CompositeBinding(
    up: new KeyBinding(.W),
    down: new KeyBinding(.S),
    left: new KeyBinding(.A),
    right: new KeyBinding(.D)
));
move.AddBinding(new GamepadStickBinding(.Left));

// Mouse axis
let look = gameplay.RegisterAction("Look");
look.AddBinding(new MouseAxisBinding(.DeltaX, .DeltaY));

// Mouse button
let fire = gameplay.RegisterAction("Fire");
fire.AddBinding(new MouseButtonBinding(.Left));
fire.AddBinding(new GamepadButtonBinding(.RightTrigger));
```

### Querying Actions

```beef
let jump = gameplay.GetAction("Jump");

// Digital (button-like)
if (jump.WasPressed)
    PerformJump();

if (jump.IsActive)
    HoldJump();

if (jump.WasReleased)
    EndJump();

// Analog (axis-like)
let move = gameplay.GetAction("Move");
let moveDir = move.Vector2Value;  // Normalized 2D direction
ApplyMovement(moveDir * speed * deltaTime);

let forward = gameplay.GetAction("MoveForward");
let forwardAmount = forward.Value;  // -1.0 to 1.0
```

### Action Callbacks

For fire-and-forget events, register callbacks instead of polling:

```beef
gameplay.OnAction("Jump", new (action) => {
    PerformJump();
});
```

### Switching Contexts

Enable/disable contexts for game state transitions:

```beef
// Open pause menu
gameplay.Enabled = false;
menu.Enabled = true;

// Resume game
menu.Enabled = false;
gameplay.Enabled = true;
```

When `BlocksInput` is true on a context, lower-priority contexts don't receive input.

### Available Binding Types

| Binding | Input | Value Type |
|---------|-------|------------|
| `KeyBinding` | Keyboard key | Digital (0/1) or custom float |
| `MouseButtonBinding` | Mouse button | Digital |
| `MouseAxisBinding` | Mouse movement | Analog (delta X/Y) |
| `GamepadButtonBinding` | Gamepad button | Digital |
| `GamepadAxisBinding` | Gamepad trigger/stick axis | Analog (-1 to 1) |
| `GamepadStickBinding` | Gamepad stick | Vector2 |
| `CompositeBinding` | 4 digital bindings -> Vector2 | Normalized 2D |

## Viewport Input Handlers

In the editor, viewport input is routed through `IViewportInputHandler` chains. Handlers are processed in priority order -- the first handler to set `e.Handled = true` stops propagation. This pattern layers gizmo manipulation over camera orbit over entity selection.

## Next Steps

- [Audio](05_Audio.md) -- playing sounds and music
