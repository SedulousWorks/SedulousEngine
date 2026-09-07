/*
 * msdfgen C API
 * C interface for the msdfgen multi-channel signed distance field generator.
 *
 * msdfgen is C++. This wraps the msdfgen-core surface a font atlas baker needs -
 * building a shape from contours and edges, colouring its edges, and generating a
 * distance field into a float bitmap - so a language with a C FFI can drive it.
 *
 * SCOPE: msdfgen-core only. The ext/ half (FreeType, TinyXML, PNG, SVG) is not built
 * and not wrapped: a caller already has its own font loading and image IO, and pulling
 * those in would drag their dependencies along with them.
 */

#ifndef MSDFGEN_C_H
#define MSDFGEN_C_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) && !defined(MSDFGEN_C_STATIC)
    #ifdef MSDFGEN_C_EXPORTS
        #define MSDFGEN_C_API __declspec(dllexport)
    #else
        #define MSDFGEN_C_API __declspec(dllimport)
    #endif
#else
    #define MSDFGEN_C_API
#endif

/* Opaque handles. A contour handle is owned by the shape that created it and dies with
 * it; it must not outlive that shape.
 *
 * WINDING DECIDES INSIDE FROM OUTSIDE. In a Y-up space an outer contour is CLOCKWISE and a
 * hole is counter-clockwise, which is the direction TrueType outlines already come in.
 * Wound the other way a shape becomes its own cutout: the field inverts and the interior
 * goes negative. Nothing reports it; msdf_contour_winding checks, and
 * msdf_shape_orient_contours fixes input whose winding cannot be trusted. */
typedef struct msdf_Shape msdf_Shape;
typedef struct msdf_Contour msdf_Contour;
typedef struct msdf_Bitmap msdf_Bitmap;

/* Which channel(s) an edge contributes to. WHITE means all three, which is what an edge
 * starts as before colouring assigns it. */
typedef enum msdf_EdgeColor {
    MSDF_EDGE_BLACK = 0,
    MSDF_EDGE_RED = 1,
    MSDF_EDGE_GREEN = 2,
    MSDF_EDGE_YELLOW = 3,
    MSDF_EDGE_BLUE = 4,
    MSDF_EDGE_MAGENTA = 5,
    MSDF_EDGE_CYAN = 6,
    MSDF_EDGE_WHITE = 7
} msdf_EdgeColor;

/* The error correction pass over a generated MSDF. */
typedef enum msdf_ErrorCorrectionMode {
    MSDF_ERROR_CORRECTION_DISABLED = 0,
    /* Corrects every discontinuity, whether or not it damages an edge. */
    MSDF_ERROR_CORRECTION_INDISCRIMINATE = 1,
    /* Corrects artifacts only where doing so leaves edges and corners intact. */
    MSDF_ERROR_CORRECTION_EDGE_PRIORITY = 2,
    /* Corrects artifacts at edges and nowhere else. */
    MSDF_ERROR_CORRECTION_EDGE_ONLY = 3
} msdf_ErrorCorrectionMode;

/* Whether the corrector computes the true shape distance at a suspected artifact.
 * Checking is much slower and much more certain. */
typedef enum msdf_DistanceCheckMode {
    MSDF_DISTANCE_CHECK_NEVER = 0,
    MSDF_DISTANCE_CHECK_AT_EDGE = 1,
    MSDF_DISTANCE_CHECK_ALWAYS = 2
} msdf_DistanceCheckMode;

/* How shape coordinates map to pixels, and how shape distances map to the [0,1] the
 * field stores.
 *
 * The RANGE is in SHAPE units, not pixels: a caller that wants N pixels of spread
 * divides N by the scale it is projecting with. Getting that wrong is the usual cause of
 * a field that looks flat or clips. */
typedef struct msdf_Transform {
    double scaleX, scaleY;
    double translateX, translateY;
    double rangeLower, rangeUpper;
} msdf_Transform;

/* Generator configuration. Zero-initialising this gives overlap support off and error
 * correction disabled, so use msdf_config_default to get msdfgen's own defaults. */
typedef struct msdf_Config {
    /* Handles contours that overlap with the same winding. Costs time; turn it off only
     * when the shapes are known not to have any. */
    int overlapSupport;
    msdf_ErrorCorrectionMode errorCorrectionMode;
    msdf_DistanceCheckMode distanceCheckMode;
    double minDeviationRatio;
    double minImproveRatio;
} msdf_Config;

/* msdfgen's own defaults: overlap support on, edge-priority correction, distance checked
 * at edges. */
MSDFGEN_C_API msdf_Config msdf_config_default(void);

/* --- Shape ---------------------------------------------------------------------- */

MSDFGEN_C_API msdf_Shape *msdf_shape_create(void);
MSDFGEN_C_API void msdf_shape_destroy(msdf_Shape *shape);

/* Appends a contour and returns it. Owned by the shape. */
MSDFGEN_C_API msdf_Contour *msdf_shape_add_contour(msdf_Shape *shape);

/* Whether the shape's Y axis points down. Font outlines are Y-up, so this stays 0 for
 * them; setting it flips what msdfgen reads as inside and outside. */
MSDFGEN_C_API void msdf_shape_set_inverse_y_axis(msdf_Shape *shape, int inverseYAxis);
MSDFGEN_C_API int msdf_shape_get_inverse_y_axis(const msdf_Shape *shape);

/* Merges adjacent collinear edges and splits any contour that is a single edge. Must be
 * called before colouring or generating: a shape that has not been normalised can colour
 * inconsistently. */
MSDFGEN_C_API void msdf_shape_normalize(msdf_Shape *shape);

/* Whether the contours are closed and consistent. */
MSDFGEN_C_API int msdf_shape_validate(const msdf_Shape *shape);

/* Makes the outer contours wind one way and the holes the other, for input whose winding
 * cannot be trusted. */
MSDFGEN_C_API void msdf_shape_orient_contours(msdf_Shape *shape);

/* The bounding box, in shape units. */
MSDFGEN_C_API void msdf_shape_bound(const msdf_Shape *shape, double *left, double *bottom,
                                    double *right, double *top);

MSDFGEN_C_API int msdf_shape_edge_count(const msdf_Shape *shape);
MSDFGEN_C_API int msdf_shape_contour_count(const msdf_Shape *shape);

/* --- Contour -------------------------------------------------------------------- */

/* A straight edge from (x0,y0) to (x1,y1). */
MSDFGEN_C_API void msdf_contour_add_linear_edge(msdf_Contour *contour, double x0, double y0,
                                                double x1, double y1, msdf_EdgeColor color);

/* A quadratic Bezier, with one control point. */
MSDFGEN_C_API void msdf_contour_add_quadratic_edge(msdf_Contour *contour, double x0, double y0,
                                                   double cx, double cy, double x1, double y1,
                                                   msdf_EdgeColor color);

/* A cubic Bezier, with two control points. */
MSDFGEN_C_API void msdf_contour_add_cubic_edge(msdf_Contour *contour, double x0, double y0,
                                               double c1x, double c1y, double c2x, double c2y,
                                               double x1, double y1, msdf_EdgeColor color);

MSDFGEN_C_API int msdf_contour_edge_count(const msdf_Contour *contour);

/* +1 or -1 depending on which way the contour turns; 0 for an empty one. */
MSDFGEN_C_API int msdf_contour_winding(const msdf_Contour *contour);

MSDFGEN_C_API void msdf_contour_reverse(msdf_Contour *contour);

/* --- Edge colouring -------------------------------------------------------------- */

/* Assigns each edge a channel so that a corner is where two channels disagree, which is
 * what lets three channels reconstruct a sharp corner that one cannot.
 *
 * MUST be called before generating an MSDF or MTSDF; the single-channel generators
 * ignore colour. The angle threshold decides what counts as a corner: 3.0 radians is
 * msdfgen's usual choice. */
MSDFGEN_C_API void msdf_edge_coloring_simple(msdf_Shape *shape, double angleThreshold,
                                             unsigned long long seed);

/* Better on shapes with many corners close together, at more cost. */
MSDFGEN_C_API void msdf_edge_coloring_ink_trap(msdf_Shape *shape, double angleThreshold,
                                               unsigned long long seed);

/* The most careful of the three, and the slowest. */
MSDFGEN_C_API void msdf_edge_coloring_by_distance(msdf_Shape *shape, double angleThreshold,
                                                  unsigned long long seed);

/* --- Bitmap --------------------------------------------------------------------- */

/* A float bitmap of `channels` channels. Channel counts are fixed by what the generators
 * take: 1 for SDF and PSDF, 3 for MSDF, 4 for MTSDF. Returns NULL for any other count. */
MSDFGEN_C_API msdf_Bitmap *msdf_bitmap_create(int width, int height, int channels);
MSDFGEN_C_API void msdf_bitmap_destroy(msdf_Bitmap *bitmap);

MSDFGEN_C_API int msdf_bitmap_width(const msdf_Bitmap *bitmap);
MSDFGEN_C_API int msdf_bitmap_height(const msdf_Bitmap *bitmap);
MSDFGEN_C_API int msdf_bitmap_channels(const msdf_Bitmap *bitmap);

/* The pixels, row major, `channels` floats each, ROW 0 IS THE BOTTOM: msdfgen's bitmaps
 * are Y-up. A top-down atlas has to flip while copying out. */
MSDFGEN_C_API float *msdf_bitmap_data(msdf_Bitmap *bitmap);

/* --- Generation ------------------------------------------------------------------ */

/* Each requires the bitmap's channel count to match, and returns 0 without touching it
 * if it does not. `config` may be NULL for msdfgen's defaults. */

MSDFGEN_C_API int msdf_generate_sdf(msdf_Bitmap *output, const msdf_Shape *shape,
                                    const msdf_Transform *transform, const msdf_Config *config);

MSDFGEN_C_API int msdf_generate_psdf(msdf_Bitmap *output, const msdf_Shape *shape,
                                     const msdf_Transform *transform, const msdf_Config *config);

/* Edge colours must be assigned first. */
MSDFGEN_C_API int msdf_generate_msdf(msdf_Bitmap *output, const msdf_Shape *shape,
                                     const msdf_Transform *transform, const msdf_Config *config);

/* MSDF plus the true distance in the alpha channel. Edge colours must be assigned first. */
MSDFGEN_C_API int msdf_generate_mtsdf(msdf_Bitmap *output, const msdf_Shape *shape,
                                      const msdf_Transform *transform, const msdf_Config *config);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* MSDFGEN_C_H */
