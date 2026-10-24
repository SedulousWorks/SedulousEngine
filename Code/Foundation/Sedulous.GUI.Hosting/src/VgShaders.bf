using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.VFS;

namespace Sedulous.GUI;

// The VG shaders a host draws the GUI with.
//
// VgShaderSet names them (the vertex and fragment shaders every draw needs, and those of the
// gradients, the distance-field text, box shadows, analytic boxes, layers and blurs, each optional:
// a missing one leaves its draws to a fallback, as VG's renderer has it). VgShaderLibrary resolves
// them from an application's data mount through the shared shader host: cooked from
// Shaders/shaders.dpak in a build that ships, compiled from Shaders/ in development (the same
// shaders UIHost resolves: the text is in Data/Shaders, not here). A test hands GuiHost a set of its
// own instead.

/// The modules are borrowed: whoever made them (a VgShaderLibrary, a test) outlives every host
/// that draws with them.
struct VgShaderSet
{
	public IShaderModule Vertex = null;
	public IShaderModule Fragment = null;
	public IShaderModule GradientRadial = null;
	public IShaderModule GradientConic = null;
	public IShaderModule DistanceField = null;
	public IShaderModule BoxShadow = null;
	public IShaderModule BoxVertex = null;
	public IShaderModule BoxFragment = null;
	public IShaderModule Layer = null;
	public IShaderModule BlurVertex = null;
	public IShaderModule BlurFragment = null;

	public this() {}

	/// Whether anything can be drawn: the two every draw needs are there.
	public bool IsUsable => (Vertex != null) && (Fragment != null);
}

/// The VG shaders from an application's data mount. Owns them (its shader host does): it outlives
/// the hosts that draw with them.
class VgShaderLibrary
{
	private ShaderSystemHost mHost = new .() ~ delete _; // owns the modules the set names
	private VgShaderSet mSet = .();

	/// Resolves the set for `device` from `data` (borrowed while the library lives); false when
	/// neither a compiler with sources nor a cooked pack is there, or the two needed are not.
	public bool Load(IDevice device, IFileSystem data)
	{
		if (mHost.Initialize(device, data) case .Err)
			return false;
		mSet.Vertex = mHost.GetVariant("vg", .Vertex, .None);
		mSet.Fragment = mHost.GetVariant("vg", .Fragment, .None);
		mSet.GradientRadial = mHost.GetVariant("vg_grad_radial", .Fragment, .None);
		mSet.GradientConic = mHost.GetVariant("vg_grad_conic", .Fragment, .None);
		mSet.DistanceField = mHost.GetVariant("vg_df", .Fragment, .None);
		mSet.BoxShadow = mHost.GetVariant("vg_shadow", .Fragment, .None);
		mSet.BoxVertex = mHost.GetVariant("vg_box", .Vertex, .None);
		mSet.BoxFragment = mHost.GetVariant("vg_box", .Fragment, .None);
		mSet.Layer = mHost.GetVariant("vg_layer", .Fragment, .None);
		mSet.BlurVertex = mHost.GetVariant("vg_blur", .Vertex, .None);
		mSet.BlurFragment = mHost.GetVariant("vg_blur", .Fragment, .None);
		return mSet.IsUsable;
	}

	public VgShaderSet Set => mSet;
}
