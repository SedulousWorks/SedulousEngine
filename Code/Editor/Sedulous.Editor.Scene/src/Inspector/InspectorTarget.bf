using System;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// What an inspector section edits: a component on an entity, or a system's settings block.
/// The generated rows read through Address and write through the undoable verbs here, so
/// one generated body serves both.
abstract class InspectorTarget
{
	protected SceneEditContext mEdit;

	public this(SceneEditContext edit)
	{
		mEdit = edit;
	}

	public SceneEditContext Edit => mEdit;

	/// The type the rows were generated for.
	public abstract Type TargetType { get; }

	/// The LIVE instance, re-resolved on every call; null when it is gone.
	public abstract void* Address { get; }

	/// CONSUMES `value`, which must be of the field's exact type.
	public abstract void SetProperty(StringView field, Variant value);
	public abstract void SetPropertyRaw(StringView field, int64 raw);
	public abstract void SetEntityRef(StringView field, Guid target);

	/// An in place edit that does not fit a property command, as one undo step: the instance
	/// is snapshotted, mutated, restored, and the mutated form re-applied through the
	/// undoable path.
	public abstract void Mutate(delegate void(void* instance) mutate);
}
