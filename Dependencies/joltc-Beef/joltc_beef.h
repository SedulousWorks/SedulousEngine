/* Shape cooking for joltc-Beef.
 *
 * joltc exposes every shape Jolt can build but NOT the serialisation of one, so a cooked
 * shape has no way in or out of the C API. This adds the missing seam: a shape's own
 * self-describing binary state, in and out of a byte blob, plus the triangles of a restored
 * shape for a debug outline.
 *
 * The blob format is Jolt's, and Jolt versions it: a cooked product must be recooked when
 * Jolt is upgraded, which the asset pipeline's builder version handles.
 *
 * Everything here needs Jolt's factory and type registry to exist, so JPH_Init must have
 * been called first.
 */

#ifndef JOLTC_BEEF_H_
#define JOLTC_BEEF_H_

#include "joltc.h"

#ifdef __cplusplus
extern "C" {
#endif

/* An owned run of bytes. The caller frees it with jcb_blob_destroy. */
typedef struct jcb_blob jcb_blob;

JPH_CAPI const void* jcb_blob_data(const jcb_blob* blob);
JPH_CAPI size_t      jcb_blob_size(const jcb_blob* blob);
JPH_CAPI void        jcb_blob_destroy(jcb_blob* blob);

/* How far a point may sit outside the hull, which trades vertex count for fidelity: larger
   is a simpler hull. joltc's create takes the convex RADIUS, a different knob, and exposes
   no way to reach this one. */
JPH_CAPI void jcb_convex_hull_settings_set_hull_tolerance(JPH_ConvexHullShapeSettings* settings,
                                                          float tolerance);

/* A shape's binary state, which carries its own subtype tag and so is self-describing.
   NULL when the shape cannot be saved.

   LEAF SHAPES ONLY. Jolt's SaveBinaryState writes a shape's own data and its subtype tag,
   and NOT its children or its materials, so a compound or a scaled shape saved through here
   restores as a broken one. Both engines cook only hulls and meshes, which are leaves, so
   this is a bound on what the seam is for rather than a fault in it. */
JPH_CAPI jcb_blob* jcb_shape_save(const JPH_Shape* shape);

/* Restores a saved shape. NULL when the bytes are not a shape this build can restore.
   THE CALLER OWNS what comes back and destroys it with JPH_Shape_Destroy. */
JPH_CAPI JPH_Shape* jcb_shape_restore(const void* data, size_t size);

/* A shape's triangles as float triples: three vertices, nine floats, per triangle. NULL
   when the shape has no triangles to give. */
JPH_CAPI jcb_blob* jcb_shape_triangles(const JPH_Shape* shape);

#ifdef __cplusplus
}
#endif

#endif /* JOLTC_BEEF_H_ */
