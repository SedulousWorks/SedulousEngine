namespace Sedulous.Drawing;

/// Style for the end caps of lines
public enum LineCap
{
	/// Flat end, stops at endpoint
	Butt,
	/// Rounded end, extends past endpoint by half thickness
	Round,
	/// Square end, extends past endpoint by half thickness
	Square
}
