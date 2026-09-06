using System;
namespace SPIRV_Cross
{
	[CRepr]
	public struct SpvId : IEquatable<SpvId>
	{
	    public this(uint32 value) => this.Value = value;

	    public readonly uint32 Value;

	    public bool Equals(SpvId other) => Value == other.Value;

	    public int GetHashCode() => Value.GetHashCode();

	    public override void ToString(String outStr) => Value.ToString(outStr);

	    public static implicit operator uint32(SpvId from) => from.Value;

	    public static implicit operator SpvId(uint32 from) => SpvId(from);

	    public static bool operator ==(SpvId left, SpvId right) => left.Equals(right);

	    public static bool operator !=(SpvId left, SpvId right) => !left.Equals(right);
	}
}