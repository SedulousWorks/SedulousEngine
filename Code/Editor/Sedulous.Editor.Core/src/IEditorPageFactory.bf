using System;
using Sedulous.Content;

namespace Sedulous.Editor.Core;

/// Creates pages for one primary object type and, through nearest type dispatch, its
/// subclasses unless a more specific factory is registered.
interface IEditorPageFactory
{
	/// The primary object type this factory's pages edit.
	Type PrimaryType { get; }

	/// A page editing `instance`, OWNED by the caller. Null on failure, an unreadable object
	/// say.
	EditorPage CreatePage(EditorContext context, Instance instance);
}
