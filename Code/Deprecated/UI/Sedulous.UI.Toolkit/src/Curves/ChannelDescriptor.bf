using System;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// What a caller tells [[CurveCanvas]] about one of its channels.
///
/// The canvas is MODEL AGNOSTIC: it draws and edits N curves without knowing whether they are a
/// particle's colour over life, an audio envelope or a tuning curve. Everything it needs to know
/// is here.
///
/// Every field defaults to something workable, so a descriptor that names only a colour is
/// valid. Two of the pairs use the "min is not below max" convention to mean UNSET rather than
/// carrying a separate flag: a zero initialised descriptor then has no clamp and no nominal
/// range, which is what a caller who did not think about them wants.
struct ChannelDescriptor
{
	/// The short label a legend shows: "X", "R", "Gain". BORROWED on the way in; the canvas
	/// copies it, and hands back a view into its own copy.
	public StringView Name = default;
	/// The colour of this channel's line and its key markers.
	public Color StrokeColor = .(0, 0, 0, 0);
	/// What a key added to this channel implicitly is worth, which happens under linked time
	/// when a click on one channel has to put a key on all of them.
	public float DefaultValue = 0.0f;
	/// Rendered and hit tested only when false. Inverted so a zero initialised channel shows.
	public bool Hidden = false;
	/// Still drawn, but refuses edits.
	public bool Locked = false;
	/// Inclusive clamps applied on edit. Disabled while MinValue is not below MaxValue.
	public float MinValue = 0.0f;
	public float MaxValue = 0.0f;
	/// The value range worth framing. Honoured while DisplayMin is below DisplayMax, and then
	/// the canvas frames at least this much even if the keys need less.
	public float DisplayMin = 0.0f;
	public float DisplayMax = 0.0f;
	public CurveInterpolation Interpolation = .Hermite;
	/// A longer explanation, kept for a hover tooltip. Not drawn by the canvas itself.
	public StringView Description = default;

	public this() {}

	public this(StringView name, Color strokeColor)
	{
		Name = name;
		StrokeColor = strokeColor;
	}
}
