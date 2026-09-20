using System;
using Sedulous.PropertyAnimation;

namespace Sedulous.Editor.PropertyAnimation;

/// One animatable leaf property discovered on a component type: the track seed (component,
/// dotted property path, value kind) that "add track from selection" turns into a track.
class AnimatablePropertyInfo
{
	public String ComponentType = new .() ~ delete _;
	public String PropertyPath = new .() ~ delete _;
	public TrackValueKind Kind = .Float;

	public this() {}

	public this(StringView componentType, StringView propertyPath, TrackValueKind kind)
	{
		ComponentType.Set(componentType);
		PropertyPath.Set(propertyPath);
		Kind = kind;
	}

	public AnimatablePropertyInfo Clone() => new AnimatablePropertyInfo(ComponentType, PropertyPath, Kind);
}
