using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// The opt-out: a type whose stored shape is not its field list.
///
/// Celsius is what gets stored; Fahrenheit is derived and must not be written, or it would
/// be a second copy of the same fact that a hand-edited file could contradict.
class HandWrittenSample : ISerializable
{
	public float Celsius;
	public float Fahrenheit => (Celsius * 9.0f / 5.0f) + 32.0f;

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		ar.Key("celsius");
		Sedulous.Core.Serialization.Serialize(ar, ref Celsius);
		ar.EndObject();
	}
}
