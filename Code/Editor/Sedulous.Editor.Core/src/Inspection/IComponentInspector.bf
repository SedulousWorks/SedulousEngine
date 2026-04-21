namespace Sedulous.Editor.Core;

using System;
using Sedulous.Scenes;
using Sedulous.UI.Toolkit;

/// Custom inspector for a specific component type.
/// Plugins register these to override the default reflection-based inspector.
interface IComponentInspector : IDisposable
{
	/// The component type this inspector handles.
	Type ComponentType { get; }

	/// Build the inspector UI into the provided PropertyGrid.
	void BuildInspector(Component component, PropertyGrid grid, InspectorContext ctx);

	/// Clean up before the inspector is rebuilt or removed.
	void TeardownInspector();
}
