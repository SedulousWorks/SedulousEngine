using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Drives size from curves sampled at normalised lifetime: Size sets both axes, or, with
/// SeparateAxes, X while SizeY sets Y. An absolute size, not a multiplier.
///
/// Describes ITSELF rather than carrying [Serializable], for its legacy reader: the generated
/// body cannot tell the old layout, one curve of Float2 keys, from the new.
[DisplayName("Size over Lifetime")]
[Scriptable(.AllPublic)]
class SizeOverLifetimeBehavior : ParticleBehavior, ISerializable
{
	public ParticleCurveFloat Size = .();
	public bool SeparateAxes = false;
	/// Y's own curve, read only with SeparateAxes.
	public ParticleCurveFloat SizeY = .();

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Size, .Float2);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		if (!Size.IsActive)
			return;

		let sizes = streams.Sizes;
		if (sizes == null)
			return;

		let separate = SeparateAxes && SizeY.IsActive;
		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let t = streams.GetLifeRatio(i);
			let x = Size.Evaluate(t);
			sizes[i] = .(x, separate ? SizeY.Evaluate(t) : x);
		}
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		// LEGACY (removed once the samples are re-saved): one curve of Float2 keys, X and Y at
		// shared times, loose in the module's object. Only text can be old: a binary reader
		// says it has every key.
		if ((ar.Mode == .Read) && !ar.HasKey("size"))
			ReadLegacyCurve(ar);
		else
		{
			ar.Key("size");
			Size.Serialize(ar);
			SerializeValue(ar, "separateAxes", ref SeparateAxes);
			ar.Key("sizeY");
			SizeY.Serialize(ar);
		}
		ar.EndObject();
	}

	/// Every sample's X equals its Y, so X becomes Size, and a Y that differs anywhere makes
	/// the axes separate. Each key cubic, its tangents as stored, as it played.
	private void ReadLegacyCurve(ISerializer ar)
	{
		int32 count = 0;
		SerializeValue(ar, "keyCount", ref count);
		Size = .();
		SizeY = .();
		SeparateAxes = false;
		for (int32 i = 0; i < Clamp(count, 0, (int32)ParticleCurve.MaxKeys); i++)
		{
			var time = 0.0f;
			var value = Float2();
			var tangentIn = Float2();
			var tangentOut = Float2();
			SerializeValue(ar, "time", ref time);
			SerializeValue(ar, "value", ref value);
			SerializeValue(ar, "tangentIn", ref tangentIn);
			SerializeValue(ar, "tangentOut", ref tangentOut);
			Size.AddKey(time, value.X, tangentIn.X, tangentOut.X);
			SizeY.AddKey(time, value.Y, tangentIn.Y, tangentOut.Y);
			SeparateAxes = SeparateAxes || (value.X != value.Y) || (tangentIn.X != tangentIn.Y)
				|| (tangentOut.X != tangentOut.Y);
		}
		if (!SeparateAxes)
			SizeY = .();
	}
}
