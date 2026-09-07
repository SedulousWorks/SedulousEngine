using System;

namespace msdfgen_Beef;

/*
 * msdfgen - multi-channel signed distance field generator.
 *
 * Source: https://github.com/Chlumsky/msdfgen
 * Version: 1.12.0
 * License: MIT (msdfgen/LICENSE.txt)
 *
 * msdfgen is C++ and ships no C API at this version, so msdfgen-c/ wraps the core surface
 * a font atlas baker needs and this binds that wrapper. The same arrangement as
 * recastnavigation-Beef and joltc-Beef.
 *
 * SCOPE: msdfgen-core. The ext/ half (FreeType, TinyXML, PNG, SVG) is neither built nor
 * wrapped: a caller has its own font loading and image IO, and pulling those in would
 * bring three dependencies with them. So a caller supplies the outline itself, as
 * contours of edges.
 */

/// A shape: contours of edges, in whatever units the outline came in. OWNS its contours.
typealias msdf_Shape = void*;
/// A contour inside a shape. Owned by that shape and invalid once it is destroyed.
///
/// WINDING DECIDES INSIDE FROM OUTSIDE. In a Y up space an outer contour is CLOCKWISE and
/// a hole is counter clockwise, which is the direction TrueType outlines already come in.
/// Wound the other way a shape becomes its own cutout: the field inverts, the interior
/// goes negative, and a glyph renders as a hole in a filled cell. Nothing reports this;
/// msdf_contour_winding is how to check, and msdf_shape_orient_contours is how to fix
/// input whose winding cannot be trusted.
typealias msdf_Contour = void*;
/// A float bitmap of a channel count fixed when it was created.
typealias msdf_Bitmap = void*;

/// Which channels an edge contributes to.
///
/// Three channels are what let a distance field reconstruct a sharp corner: at a corner
/// two channels disagree, and the median of the three picks the right side. WHITE is all
/// three, which is what an edge starts as before colouring.
enum msdf_EdgeColor : int32
{
	Black = 0,
	Red = 1,
	Green = 2,
	Yellow = 3,
	Blue = 4,
	Magenta = 5,
	Cyan = 6,
	White = 7
}

/// The error correction pass over a generated MSDF.
enum msdf_ErrorCorrectionMode : int32
{
	Disabled = 0,
	/// Corrects every discontinuity, whether or not it damages an edge.
	Indiscriminate = 1,
	/// Corrects artifacts only where doing so leaves edges and corners intact.
	EdgePriority = 2,
	/// Corrects artifacts at edges and nowhere else.
	EdgeOnly = 3
}

/// Whether the corrector computes the true shape distance at a suspected artifact.
/// Checking is much slower and much more certain.
enum msdf_DistanceCheckMode : int32
{
	Never = 0,
	AtEdge = 1,
	Always = 2
}

/// How shape coordinates map to pixels, and how shape distances map to the [0, 1] the
/// field stores.
///
/// The RANGE is in SHAPE units, not pixels. A caller wanting N pixels of spread divides N
/// by the scale it is projecting with; passing pixels straight in is the usual cause of a
/// field that looks flat or clips at the glyph edge.
[CRepr]
struct msdf_Transform
{
	public double ScaleX;
	public double ScaleY;
	public double TranslateX;
	public double TranslateY;
	public double RangeLower;
	public double RangeUpper;

	/// A symmetric range about zero, which is what a glyph field wants.
	public this(double scaleX, double scaleY, double translateX, double translateY, double range)
	{
		ScaleX = scaleX; ScaleY = scaleY;
		TranslateX = translateX; TranslateY = translateY;
		RangeLower = -range * 0.5;
		RangeUpper = range * 0.5;
	}
}

/// Generator configuration.
///
/// A default constructed one is NOT msdfgen's defaults: it is zeroed, which means no
/// overlap support and no error correction. Use Default for the library's own.
[CRepr]
struct msdf_Config
{
	/// Handles contours that overlap with the same winding. Costs time; turn it off only
	/// for shapes known not to have any.
	public int32 OverlapSupport;
	public msdf_ErrorCorrectionMode ErrorCorrectionMode;
	public msdf_DistanceCheckMode DistanceCheckMode;
	public double MinDeviationRatio;
	public double MinImproveRatio;

	/// msdfgen's own defaults, read from the library rather than restated here: they are
	/// its numbers to change, not ours.
	public static msdf_Config Default => msdf_config_default();
}

static
{
	// ---- shape -----------------------------------------------------------------------

	[CLink] public static extern msdf_Config msdf_config_default();

	[CLink] public static extern msdf_Shape msdf_shape_create();
	[CLink] public static extern void msdf_shape_destroy(msdf_Shape shape);

	/// Appends a contour and returns it. Owned by the shape.
	[CLink] public static extern msdf_Contour msdf_shape_add_contour(msdf_Shape shape);

	/// Whether the shape's Y axis points DOWN. Font outlines are Y up, so this stays false
	/// for them; setting it swaps what msdfgen reads as inside and outside, which fills the
	/// whole cell.
	[CLink] public static extern void msdf_shape_set_inverse_y_axis(msdf_Shape shape, int32 inverseYAxis);
	[CLink] public static extern int32 msdf_shape_get_inverse_y_axis(msdf_Shape shape);

	/// Merges adjacent collinear edges and splits a contour that is a single edge. MUST run
	/// before colouring or generating: an unnormalised shape colours inconsistently.
	[CLink] public static extern void msdf_shape_normalize(msdf_Shape shape);

	/// Whether the contours are closed and consistent.
	[CLink] public static extern int32 msdf_shape_validate(msdf_Shape shape);

	/// Makes outer contours wind one way and holes the other, for input whose winding
	/// cannot be trusted.
	[CLink] public static extern void msdf_shape_orient_contours(msdf_Shape shape);

	/// The bounding box, in shape units.
	[CLink] public static extern void msdf_shape_bound(msdf_Shape shape, double* left,
		double* bottom, double* right, double* top);

	[CLink] public static extern int32 msdf_shape_edge_count(msdf_Shape shape);
	[CLink] public static extern int32 msdf_shape_contour_count(msdf_Shape shape);

	// ---- contour ---------------------------------------------------------------------

	[CLink] public static extern void msdf_contour_add_linear_edge(msdf_Contour contour,
		double x0, double y0, double x1, double y1, msdf_EdgeColor color);

	[CLink] public static extern void msdf_contour_add_quadratic_edge(msdf_Contour contour,
		double x0, double y0, double cx, double cy, double x1, double y1, msdf_EdgeColor color);

	[CLink] public static extern void msdf_contour_add_cubic_edge(msdf_Contour contour,
		double x0, double y0, double c1x, double c1y, double c2x, double c2y,
		double x1, double y1, msdf_EdgeColor color);

	[CLink] public static extern int32 msdf_contour_edge_count(msdf_Contour contour);

	/// Plus or minus one depending on which way the contour turns; zero for an empty one.
	/// A hole must wind the opposite way to the outline that contains it.
	[CLink] public static extern int32 msdf_contour_winding(msdf_Contour contour);

	[CLink] public static extern void msdf_contour_reverse(msdf_Contour contour);

	// ---- edge colouring --------------------------------------------------------------

	/// Assigns each edge a channel so a corner is where two channels disagree.
	///
	/// MUST run before generating an MSDF or MTSDF; the single channel generators ignore
	/// colour entirely. The angle threshold decides what counts as a corner, and 3.0
	/// radians is msdfgen's usual choice.
	[CLink] public static extern void msdf_edge_coloring_simple(msdf_Shape shape,
		double angleThreshold, uint64 seed);

	/// Better where many corners sit close together, at more cost.
	[CLink] public static extern void msdf_edge_coloring_ink_trap(msdf_Shape shape,
		double angleThreshold, uint64 seed);

	/// The most careful of the three, and the slowest.
	[CLink] public static extern void msdf_edge_coloring_by_distance(msdf_Shape shape,
		double angleThreshold, uint64 seed);

	// ---- bitmap ----------------------------------------------------------------------

	/// A float bitmap. The channel count is fixed by what the generators take: 1 for SDF
	/// and PSDF, 3 for MSDF, 4 for MTSDF. Any other count returns null rather than
	/// allocating something no generator will accept.
	[CLink] public static extern msdf_Bitmap msdf_bitmap_create(int32 width, int32 height, int32 channels);
	[CLink] public static extern void msdf_bitmap_destroy(msdf_Bitmap bitmap);

	[CLink] public static extern int32 msdf_bitmap_width(msdf_Bitmap bitmap);
	[CLink] public static extern int32 msdf_bitmap_height(msdf_Bitmap bitmap);
	[CLink] public static extern int32 msdf_bitmap_channels(msdf_Bitmap bitmap);

	/// The pixels, row major, one float per channel. ROW ZERO IS THE BOTTOM: msdfgen's
	/// bitmaps are Y up, so a top down atlas flips while copying out.
	[CLink] public static extern float* msdf_bitmap_data(msdf_Bitmap bitmap);

	// ---- generation ------------------------------------------------------------------

	// Each returns zero, having touched nothing, when the bitmap's channel count does not
	// match. `config` may be null for msdfgen's defaults.

	[CLink] public static extern int32 msdf_generate_sdf(msdf_Bitmap output, msdf_Shape shape,
		msdf_Transform* transform, msdf_Config* config);

	[CLink] public static extern int32 msdf_generate_psdf(msdf_Bitmap output, msdf_Shape shape,
		msdf_Transform* transform, msdf_Config* config);

	/// Edge colours must be assigned first.
	[CLink] public static extern int32 msdf_generate_msdf(msdf_Bitmap output, msdf_Shape shape,
		msdf_Transform* transform, msdf_Config* config);

	/// MSDF with the true distance in alpha. Edge colours must be assigned first.
	[CLink] public static extern int32 msdf_generate_mtsdf(msdf_Bitmap output, msdf_Shape shape,
		msdf_Transform* transform, msdf_Config* config);
}
