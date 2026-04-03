using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Event arguments for drag and drop operations.
public class DragEventArgs : InputEventArgs
{
	/// The drag data being transferred.
	public DragData Data;

	/// Position of the drag (screen coordinates).
	public Vector2 Position;

	/// Allowed effects from the drag source.
	public DragDropEffects AllowedEffects;

	/// The effect to use for this operation.
	/// Set by drop target in OnDragEnter/OnDragOver to indicate acceptance.
	public DragDropEffects Effect = .None;

	/// Creates empty drag event args.
	public this()
	{
	}

	/// Creates drag event args with data and position.
	public this(DragData data, Vector2 position, DragDropEffects allowedEffects)
	{
		Data = data;
		Position = position;
		AllowedEffects = allowedEffects;
	}

	/// Gets local position relative to a target element.
	public Vector2 GetLocalPosition(UIElement target)
	{
		if (target == null)
			return Position;
		return .(Position.X - target.ArrangedBounds.X, Position.Y - target.ArrangedBounds.Y);
	}

	/// Checks if a specific effect is allowed.
	public bool IsEffectAllowed(DragDropEffects effect)
	{
		return (AllowedEffects & effect) != .None;
	}

	public override void Reset()
	{
		base.Reset();
		Data = null;
		Position = .Zero;
		AllowedEffects = .None;
		Effect = .None;
	}
}
