using Sedulous.Core;

namespace Sedulous.PropertyAnimation;

/// One sampled property value.
///
/// A PLAIN VALUE rather than a boxed one: every kind a track animates fits in four floats,
/// so a sample costs nothing to make and nothing to free. Sampling happens per track per
/// frame, and a boxed value would allocate for anything wider than a machine word.
struct PropertyValue
{
	public TrackValueKind Kind = .Float;
	/// The channels, as many as the kind uses. A rotation stores its four components here.
	public Float4 Channels = .(0, 0, 0, 0);
	/// False for a target that could not be read at all, which is what tells a merge to fall
	/// back to nought rather than to a value that was never there.
	public bool HasValue = false;

	public this() {}

	public float Scalar => Channels.X;
	public Float3 Vector => .(Channels.X, Channels.Y, Channels.Z);
	public Color Color => .(Channels.X, Channels.Y, Channels.Z, Channels.W);
	public Quaternion Rotation => .(Channels.X, Channels.Y, Channels.Z, Channels.W);

	public static PropertyValue FromFloat(float value) =>
		.() { Kind = .Float, Channels = .(value, 0, 0, 0), HasValue = true };

	public static PropertyValue FromFloat3(Float3 value) =>
		.() { Kind = .Float3, Channels = .(value.X, value.Y, value.Z, 0), HasValue = true };

	public static PropertyValue FromColor(Color value) =>
		.() { Kind = .Color, Channels = .(value.R, value.G, value.B, value.A), HasValue = true };

	public static PropertyValue FromQuaternion(Quaternion value) =>
		.() { Kind = .Quat, Channels = .(value.X, value.Y, value.Z, value.W), HasValue = true };

	/// Nothing at all, which is what an unresolved binding or an unreadable target answers.
	public static PropertyValue Empty => .();
}
