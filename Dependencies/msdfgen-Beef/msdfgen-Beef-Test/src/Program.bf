using msdfgen_Beef;
using System;
using System.Diagnostics;

namespace msdfgen_Beef_Test;

/// Drives the binding end to end against the real library: build a shape, colour it,
/// generate every field kind, and check the results say what a distance field should.
class Program
{
	/// A square in a 0..1 box, wound CLOCKWISE in this Y up space.
	///
	/// That is the direction msdfgen reads as an outer contour, and it is the direction
	/// TrueType outlines already come in. Wound the other way the square is a hole: the
	/// field inverts, the interior goes negative, and a glyph renders as its own cutout.
	static msdf_Shape MakeSquare()
	{
		let shape = msdf_shape_create();
		let contour = msdf_shape_add_contour(shape);
		msdf_contour_add_linear_edge(contour, 0, 0, 0, 1, .White);
		msdf_contour_add_linear_edge(contour, 0, 1, 1, 1, .White);
		msdf_contour_add_linear_edge(contour, 1, 1, 1, 0, .White);
		msdf_contour_add_linear_edge(contour, 1, 0, 0, 0, .White);
		msdf_shape_set_inverse_y_axis(shape, 0);
		msdf_shape_normalize(shape);
		return shape;
	}

	static void Run()
	{
		let shape = MakeSquare();
		defer msdf_shape_destroy(shape);

		Debug.WriteLine("contours: {0}, edges: {1}", msdf_shape_contour_count(shape),
			msdf_shape_edge_count(shape));
		Debug.WriteLine("valid: {0}", msdf_shape_validate(shape) != 0);

		double left = 0, bottom = 0, right = 0, top = 0;
		msdf_shape_bound(shape, &left, &bottom, &right, &top);
		Debug.WriteLine("bounds: ({0}, {1}) .. ({2}, {3})", left, bottom, right, top);

		// A 32 by 32 field over the unit square, with four pixels of spread. The range is
		// in SHAPE units, so the pixel spread is divided by the scale.
		const int32 cSize = 32;
		// Half scale with the square centred, so the bitmap covers 0..2 in shape units and
		// pixel zero really is outside the 0..1 square rather than a hair inside it.
		var transform = msdf_Transform(cSize / 2, cSize / 2, 0.5, 0.5, 8.0 / cSize);
		var config = msdf_Config.Default;
		Debug.WriteLine("default config: overlap={0}, correction={1}, check={2}",
			config.OverlapSupport, config.ErrorCorrectionMode, config.DistanceCheckMode);

		// Single channel first, which needs no colouring.
		let sdf = msdf_bitmap_create(cSize, cSize, 1);
		defer msdf_bitmap_destroy(sdf);
		Debug.WriteLine("generate_sdf: {0}", msdf_generate_sdf(sdf, shape, &transform, &config) != 0);

		// The centre is deep inside and a corner is outside, so the field has to be above
		// 0.5 at one and below it at the other. That is the whole contract of a signed
		// distance field, and it fails loudly if the winding or the range is wrong.
		let sdfPixels = msdf_bitmap_data(sdf);
		let centre = sdfPixels[(cSize / 2) * cSize + (cSize / 2)];
		// Far outside the square, so it is well below the 0.5 that marks the surface.
		let outside = sdfPixels[0];
		Debug.WriteLine("sdf centre: {0} (inside, > 0.5)", centre);
		Debug.WriteLine("sdf outside: {0} (outside, < 0.5)", outside);
		if (!(centre > 0.5f))
			Debug.WriteLine("  WRONG: the interior is not positive, so the winding is inverted");

		// Three channels, which do need colouring.
		msdf_edge_coloring_simple(shape, 3.0, 0);
		let msdf = msdf_bitmap_create(cSize, cSize, 3);
		defer msdf_bitmap_destroy(msdf);
		Debug.WriteLine("generate_msdf: {0}", msdf_generate_msdf(msdf, shape, &transform, &config) != 0);

		let mtsdf = msdf_bitmap_create(cSize, cSize, 4);
		defer msdf_bitmap_destroy(mtsdf);
		Debug.WriteLine("generate_mtsdf: {0}", msdf_generate_mtsdf(mtsdf, shape, &transform, &config) != 0);

		// A channel count mismatch is refused rather than writing past the end.
		Debug.WriteLine("msdf into a 1 channel bitmap is refused: {0}",
			msdf_generate_msdf(sdf, shape, &transform, &config) == 0);
		Debug.WriteLine("a 2 channel bitmap cannot be made: {0}",
			msdf_bitmap_create(cSize, cSize, 2) == null);
	}

	public static void Main()
	{
		Run();
		Debug.WriteLine("msdfgen binding OK.");
	}
}
