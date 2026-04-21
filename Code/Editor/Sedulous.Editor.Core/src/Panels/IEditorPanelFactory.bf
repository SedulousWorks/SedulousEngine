namespace Sedulous.Editor.Core;

using System;

/// Creates global editor panels. Plugins register these.
interface IEditorPanelFactory
{
	StringView PanelId { get; }
	IEditorPanel CreatePanel(EditorContext context);
}
