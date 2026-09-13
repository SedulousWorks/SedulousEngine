using Sedulous.Scene;

namespace Sedulous.Engine.UI;

/// The pool of screen space canvases.
///
/// The per canvas view tree and its host are the SUBSYSTEM's, not this pool's: building one
/// needs a UI context, which a headless scene consumer never has.
class UICanvasComponentManager : ResourceBindingComponentManager<UICanvasComponent>
{
}
