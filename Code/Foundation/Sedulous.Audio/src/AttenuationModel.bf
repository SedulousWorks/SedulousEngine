namespace Sedulous.Audio;

using System;

/// Distance attenuation curve type.
public enum AttenuationCurve
{
	/// Linear falloff: gain = 1 - (d - min) / (max - min)
	Linear,
	/// Inverse distance: gain = min / d (clamped to [0,1])
	InverseDistance,
	/// Logarithmic: gain = 1 - log(d/min) / log(max/min)
	Logarithmic,
	/// Inverse distance squared: gain = (min / d)^2
	InverseDistanceSquared
}

/// Configurable distance attenuation and spatial properties for a sound source.
/// Can be shared across multiple sources as a common configuration.
public struct SoundAttenuator
{
	/// Distance where attenuation begins. Below this, full volume.
	public float MinDistance = 1.0f;

	/// Distance where sound is inaudible.
	public float MaxDistance = 100.0f;

	/// Attenuation curve type.
	public AttenuationCurve Curve = .InverseDistance;

	/// Low-pass filter cutoff at max distance (Hz). 0 = disabled.
	/// At MinDistance: no filtering (22050 Hz).
	/// At MaxDistance: this cutoff frequency.
	/// Between: logarithmically interpolated.
	public float MaxDistanceLowPassHz = 0.0f;

	/// Emission cone inner angle (degrees, 0-360). Full volume inside.
	public float ConeInnerAngle = 360.0f;

	/// Emission cone outer angle (degrees, 0-360). Attenuated between inner/outer.
	public float ConeOuterAngle = 360.0f;

	/// Volume multiplier at the outer cone edge (0-1).
	public float ConeOuterGain = 0.0f;

	/// Doppler effect factor. 0 = disabled, 1 = realistic, >1 = exaggerated.
	public float DopplerFactor = 0.0f;

	/// Calculates gain for a given distance using the configured curve.
	public float CalculateGain(float distance)
	{
		if (distance <= MinDistance)
			return 1.0f;
		if (distance >= MaxDistance)
			return 0.0f;

		switch (Curve)
		{
		case .Linear:
			return 1.0f - (distance - MinDistance) / (MaxDistance - MinDistance);

		case .InverseDistance:
			return Math.Clamp(MinDistance / distance, 0.0f, 1.0f);

		case .Logarithmic:
			let logRatio = Math.Log(distance / MinDistance) / Math.Log(MaxDistance / MinDistance);
			return Math.Clamp(1.0f - logRatio, 0.0f, 1.0f);

		case .InverseDistanceSquared:
			let ratio = MinDistance / distance;
			return Math.Clamp(ratio * ratio, 0.0f, 1.0f);
		}
	}

	/// Calculates cone attenuation gain based on the angle between
	/// the source's forward direction and the direction to the listener.
	/// angleDeg: angle in degrees between source forward and to-listener direction.
	public float CalculateConeGain(float angleDeg)
	{
		let halfInner = ConeInnerAngle * 0.5f;
		let halfOuter = ConeOuterAngle * 0.5f;

		if (ConeInnerAngle >= 360.0f)
			return 1.0f; // omnidirectional

		if (angleDeg <= halfInner)
			return 1.0f;

		if (angleDeg >= halfOuter)
			return ConeOuterGain;

		// Interpolate between inner and outer
		let t = (angleDeg - halfInner) / (halfOuter - halfInner);
		return 1.0f + (ConeOuterGain - 1.0f) * t;
	}

	/// Calculates the low-pass cutoff frequency based on distance.
	/// Returns 22050 if distance low-pass is disabled or at min distance.
	public float CalculateLowPassCutoff(float distance)
	{
		if (MaxDistanceLowPassHz <= 0.0f)
			return 22050.0f;

		if (distance <= MinDistance)
			return 22050.0f;

		if (distance >= MaxDistance)
			return MaxDistanceLowPassHz;

		// Logarithmic interpolation between 22050 and MaxDistanceLowPassHz
		let t = (distance - MinDistance) / (MaxDistance - MinDistance);
		let logHigh = Math.Log(22050.0f);
		let logLow = Math.Log(Math.Max(MaxDistanceLowPassHz, 20.0f));
		return Math.Exp(logHigh + (logLow - logHigh) * t);
	}
}
