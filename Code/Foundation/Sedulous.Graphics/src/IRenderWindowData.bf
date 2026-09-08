namespace Sedulous.Graphics;

/// A typed payload a consumer hangs off a RenderWindow.
///
/// The UI layer stashes its root view and renderer here without the host knowing the
/// type. The window OWNS whatever is set, and deletes it.
interface IRenderWindowData
{
}
