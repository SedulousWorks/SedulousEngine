using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// What an InspectorSection builds its rows into: the scene inspector, or a page that shows a
/// settings block's values the same way (a render profile's page), so the two cannot drift.
interface IInspectorOwner
{
	EditorContext Editor { get; }
	PropertyGrid Grid { get; }
	/// The UI context a row's dialog opens against; null until the grid is attached.
	UIContext DialogContext { get; }

	/// Adds an editor to the grid, which OWNS it, with the refresher that re-reads its value
	/// while it is not being edited. CONSUMES the refresher.
	void AddEditor(PropertyEditor editor, delegate void() refresher);
	/// A refresher with no editor of its own; CONSUMED.
	void AddRefresher(delegate void() refresher);
	/// Takes ownership of something a row's closures hold, for the life of the grid contents.
	void Keep(Object owned);
	/// The asset's name, "(none)" for nil and "(missing)" for an id the project lacks.
	void AssetNameFor(Guid target, String outName);
	/// Asks for the rows to be rebuilt on the next refresh: a list grew, a behavior was added.
	void RequestRebuild();
}
