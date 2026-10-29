using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

// What a section in the inspector shows besides its reflected rows, a component's or, while the
// scene is selected, a settings block's (Raptor's editor-gui spec, 5.3, layer 4, parts 3 and 4):
// notices that hold while something is so (a rigid body with no collider), actions (a zone's Bake)
// and sections of their own (a script component's behaviours, the physics block's collision
// groups). The inspector asks the section's type for them, so it names no type: a domain registers
// its type's extras (SceneEditor.Register registers the built-in ones), and the inspector adds
// what a provider gives under the section's header, a notice shown only while its message is not
// empty.

/// What a provider fills, for the entities the inspector shows (each has the component; none for a
/// settings block's).
abstract class InspectorExtras
{
	public abstract SceneEditContext Edit { get; }
	/// Null in a host with no editor context.
	public abstract EditorContext Context { get; }
	public abstract Span<Guid> Entities { get; }
	/// A notice under the header: `message` (taken) asked again as the inspector shows its values
	/// (a notice is current), shown while it says something.
	public abstract void AddNotice(StringView name, delegate void(String outMessage) message);
	/// An action under the header: a button `label` that runs `run` (taken).
	public abstract void AddAction(StringView name, StringView label, StringView description, delegate void() run);
	/// Rows of a source of its own under the header (a script component's behaviours, which
	/// reflection does not show), both taken; `refresh` (may be null) runs as the inspector shows
	/// its values.
	public abstract void AddSection(IPropertySource source, delegate void() refresh);
}

/// Fills a component's extras.
typealias InspectorExtrasProvider = delegate void(InspectorExtras extras);

/// The extras each component type has, by its type: the editor's one registry.
static class InspectorExtrasRegistry
{
	private class Entry
	{
		public Type Type;
		public InspectorExtrasProvider Provider ~ delete _;
	}

	private static List<Entry> sEntries = new .() ~ DeleteContainerAndItems!(_);

	/// `type`'s extras are what `provider` (taken) adds.
	public static void Register(Type type, InspectorExtrasProvider provider)
	{
		let entry = new Entry();
		entry.Type = type;
		entry.Provider = provider;
		sEntries.Add(entry);
	}

	/// Every provider of `type`'s extras, in their registration's order.
	public static void ForEach(Type type, delegate void(InspectorExtrasProvider provider) visit)
	{
		for (let entry in sEntries)
		{
			if (entry.Type == type)
				visit(entry.Provider);
		}
	}
}
