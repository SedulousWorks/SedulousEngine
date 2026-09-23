using Sedulous.Core;

namespace Sedulous.Engine.Terrain.Backend.Tests;

/// What one rendered frame measured.
///
/// STRUCTURAL sums rather than a stored image: halves, channel halves, and per band centres,
/// so every assertion names a property and nothing drifts between drivers.
class TerrainProbe
{
	/// The vertical bands the stripe fixtures are read out in.
	public const int Bands = 6;

	public bool Valid = false;
	/// Brighter than the black background.
	public int Filled = 0;

	/// The middle sixteenth of the frame, which is what a cut at the grid's centre opens.
	public double CenterLuma = 0.0;

	public double LeftLuma = 0.0;
	public double RightLuma = 0.0;
	public double TopLuma = 0.0;
	public double BottomLuma = 0.0;
	public double Total = 0.0;

	/// The flat ground either side of a central ridge, measured WELL CLEAR of the bright
	/// ridge stripe itself so a shadow on the ground is what moves them.
	public double LeftGround = 0.0;
	public double RightGround = 0.0;

	public double LeftR = 0.0;
	public double LeftG = 0.0;
	public double LeftB = 0.0;
	public double RightR = 0.0;
	public double RightG = 0.0;
	public double RightB = 0.0;

	/// Band CENTRE channel means: the middle half in y and the middle half of each band in x,
	/// which keeps the readout clear of the boundaries where bands blend and of the terrain's
	/// own rim.
	public double[Bands] BandR = .();
	public double[Bands] BandG = .();
	public double[Bands] BandB = .();
}
