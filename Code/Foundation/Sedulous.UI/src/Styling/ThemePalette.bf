using Sedulous.Core;

namespace Sedulous.UI;

/// The seed colours of a theme.
///
/// Controls and theme builders DERIVE their state variants from these, so a whole theme
/// follows from a handful of colours rather than every control naming its own.
///
/// The default member values ARE the dark palette, so Dark simply returns a default.
struct ThemePalette
{
	/// Written as bytes over 255 to match how the colours were picked and how Raptor states
	/// them, rather than as opaque fractions.
	private static Color Rgb(float r, float g, float b) =>
		.(r / 255.0f, g / 255.0f, b / 255.0f, 1.0f);

	/// The primary brand colour.
	public Color Primary = Rgb(60, 120, 215);
	/// A brighter accent for interactive elements.
	public Color PrimaryAccent = Rgb(80, 150, 240);

	/// The window or root background.
	public Color Background = Rgb(30, 30, 35);
	/// A panel or card surface.
	public Color Surface = Rgb(42, 44, 54);
	/// A brighter surface, for something raised above the rest.
	public Color SurfaceBright = Rgb(55, 58, 70);

	public Color Border = Rgb(65, 70, 85);

	public Color Text = Rgb(220, 225, 235);
	/// Dimmed, for secondary text.
	public Color TextDim = Rgb(140, 150, 170);

	public Color Error = Rgb(210, 60, 60);
	public Color Success = Rgb(60, 180, 80);
	public Color Warning = Rgb(220, 180, 50);

	public this() {}

	public static ThemePalette Dark() => .();

	/// A warm graphite and orange dark palette: warm neutral charcoal surfaces under an orange
	/// accent. A deliberate alternative to the cool blue grey default, and what the editor
	/// uses.
	public static ThemePalette GraphiteOrange()
	{
		ThemePalette palette = .();
		palette.Primary = Rgb(230, 122, 46);
		palette.PrimaryAccent = Rgb(245, 143, 66);
		palette.Background = Rgb(25, 24, 23);
		palette.Surface = Rgb(38, 37, 33);
		palette.SurfaceBright = Rgb(51, 49, 43);
		palette.Border = Rgb(69, 66, 59);
		palette.Text = Rgb(237, 232, 223);
		palette.TextDim = Rgb(154, 147, 138);
		palette.Error = Rgb(216, 82, 74);
		palette.Success = Rgb(99, 184, 110);
		// Gold, kept distinct from the orange accent so a warning does not read as emphasis.
		palette.Warning = Rgb(230, 184, 60);
		return palette;
	}

	public static ThemePalette Light()
	{
		ThemePalette palette = .();
		palette.Primary = Rgb(40, 100, 200);
		palette.PrimaryAccent = Rgb(60, 130, 220);
		palette.Background = Rgb(240, 240, 245);
		palette.Surface = Rgb(255, 255, 255);
		palette.SurfaceBright = Rgb(248, 248, 252);
		palette.Border = Rgb(200, 205, 215);
		palette.Text = Rgb(30, 30, 40);
		palette.TextDim = Rgb(100, 105, 120);
		palette.Error = Rgb(200, 50, 50);
		palette.Success = Rgb(50, 160, 70);
		palette.Warning = Rgb(200, 160, 40);
		return palette;
	}
}
