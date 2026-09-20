using System;
using Sedulous.Content;

namespace Sedulous.Editor.Core;

/// File > New <label>: creates a fresh source instance in the project database. Registered
/// by the per subsystem editor modules; the shell builds its menu from them.
class AssetCreator
{
	public typealias Create = delegate Instance(EditorContext context, Group group);

	public String Label = new .() ~ delete _;
	/// Creators sharing a category land in a submenu of that name ("Primitives"); empty is
	/// a top level "New <label>" item.
	public String Category = new .() ~ delete _;
	/// `group` is the browser group the creator was invoked FROM; null is no context, the
	/// File menu, and the creator picks its own default group.
	public Create Run ~ delete _;
	/// Only a document like creation, a scene, becomes the project's default scene when it
	/// is unset; a data asset never should.
	public bool SetsDefaultScene = false;

	public this(StringView label, StringView category, Create run, bool setsDefaultScene = false)
	{
		Label.Set(label);
		Category.Set(category);
		Run = run;
		SetsDefaultScene = setsDefaultScene;
	}
}
