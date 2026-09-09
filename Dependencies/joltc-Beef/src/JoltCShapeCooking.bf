using System;

namespace joltc_Beef;

/// Shape cooking, which joltc itself does not expose.
///
/// joltc builds every shape Jolt can build but serialises none of them, so a cooked shape
/// has no way in or out of the C API. This is the missing seam: a shape's own
/// self-describing binary state, in and out of a byte blob, plus the triangles of a shape
/// for a debug outline.
///
/// The blob format is JOLT'S, and Jolt versions it: a cooked product must be recooked when
/// Jolt is upgraded, which the asset pipeline's builder version handles.
///
/// Everything here needs Jolt's factory and type registry, so JPH_Init comes first.

/// An owned run of bytes, freed with jcb_blob_destroy.
[CRepr] struct jcb_blob;

static
{
	[CLink] public static extern void* jcb_blob_data(jcb_blob* blob);
	[CLink] public static extern uint jcb_blob_size(jcb_blob* blob);
	[CLink] public static extern void jcb_blob_destroy(jcb_blob* blob);

	/// How far a point may sit outside the hull, which trades vertex count for fidelity:
	/// larger is a simpler hull. joltc's create takes the convex RADIUS, a different knob,
	/// and exposes no way to reach this one.
	[CLink] public static extern void jcb_convex_hull_settings_set_hull_tolerance(
		JPH_ConvexHullShapeSettings* settings, float tolerance);

	/// A shape's binary state, which carries its own subtype tag and so is self describing.
	/// Null when the shape cannot be saved.
	[CLink] public static extern jcb_blob* jcb_shape_save(JPH_Shape* shape);

	/// Restores a saved shape. Null when the bytes are not a shape this build can restore,
	/// which a corrupt or foreign blob is: Jolt indexes its construct table with the leading
	/// byte unvalidated, so that byte is checked before anything is read.
	///
	/// THE CALLER OWNS what comes back and destroys it with JPH_Shape_Destroy.
	[CLink] public static extern JPH_Shape* jcb_shape_restore(void* data, uint size);

	/// A shape's triangles as float triples: three vertices, nine floats, per triangle. Null
	/// when the shape has no triangles to give.
	[CLink] public static extern jcb_blob* jcb_shape_triangles(JPH_Shape* shape);
}
