namespace Sedulous.Editor.Core;

using System;

/// Marks a class as an editor plugin for automatic discovery.
/// The class must implement IEditorPlugin. Discovered via Type.Types scan
/// at startup - no manual registration needed.
[AttributeUsage(.Class, .AlwaysIncludeTarget)]
struct EditorPluginAttribute : Attribute
{
	/// Initialization priority. Lower values initialize first.
	/// Use to control plugin init order when one plugin depends on another's registrations.
	public int32 Priority;

	public this(int32 priority = 0)
	{
		Priority = priority;
	}
}
