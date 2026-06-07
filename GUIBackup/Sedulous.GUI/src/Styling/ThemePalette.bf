namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// Seed colors for a theme. Controls and theme builders use these
/// to derive consistent state variants (hover, pressed, disabled, etc.).
public struct ThemePalette
{
	public Color Primary = .(60, 120, 215, 255);
	public Color PrimaryAccent = .(80, 150, 240, 255);

	public Color Background = .(30, 30, 35, 255);
	public Color Surface = .(42, 44, 54, 255);
	public Color SurfaceBright = .(55, 58, 70, 255);

	public Color Border = .(65, 70, 85, 255);

	public Color Text = .(220, 225, 235, 255);
	public Color TextDim = .(140, 150, 170, 255);

	public Color Error = .(210, 60, 60, 255);
	public Color Success = .(60, 180, 80, 255);
	public Color Warning = .(220, 180, 50, 255);

	public static ThemePalette Dark => .();

	public static ThemePalette Light => .()
	{
		Primary = .(40, 100, 200, 255),
		PrimaryAccent = .(60, 130, 220, 255),
		Background = .(240, 240, 245, 255),
		Surface = .(255, 255, 255, 255),
		SurfaceBright = .(248, 248, 252, 255),
		Border = .(200, 205, 215, 255),
		Text = .(30, 30, 40, 255),
		TextDim = .(100, 105, 120, 255),
		Error = .(200, 50, 50, 255),
		Success = .(50, 160, 70, 255),
		Warning = .(200, 160, 40, 255)
	};
}
