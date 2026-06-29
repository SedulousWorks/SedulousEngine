using System;

namespace Sedulous.RuntimeGraphics;

/// Typed per-window payload. The UI layer stashes its own data (RootView,
/// VGContext, VGRenderer, etc.) here without the host knowing the concrete
/// type. Implement this interface and attach via RenderWindow.SetData().
interface IRenderWindowData : IDisposable
{
}
