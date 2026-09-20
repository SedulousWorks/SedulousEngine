using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Navigation;

/// Registers the navigation editor's section types; the composition root calls it before the
/// app constructs, since an unregistered section would load untyped and read as defaults.
[SerializableRegistry]
static class NavigationEditorSerializables
{
}
