namespace Sedulous.Editor.Core;

using System;
using Sedulous.UI;

/// Global dockable panel (Console, Asset Browser, plugin panels).
/// Unlike page content, panels persist across page switches.
interface IEditorPanel : IDisposable
{
	StringView PanelId { get; }
	StringView Title { get; }
	View ContentView { get; }
	void OnActivated();
	void OnDeactivated();
	void Update(float deltaTime);
}
