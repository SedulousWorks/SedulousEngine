using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// DrawContext: the renderer seam eepp's UI lacked. eepp widgets/drawables draw straight through
// global Primitives / GlobalBatchRenderer / GLi; here every draw call routes through a VGContext
// instead. A thin wrapper adding clip / transform / opacity stacking and the DPI scale; the font
// service is not wired in here.

class DrawContext
{
	/// What IsVisible and GetVisibleBounds grow a rect or the clip by.
	private const float cVisibleMargin = 32.0f;

	private VGContext mVG;
	private float mDpiScale;
	private IPictureBaker mBaker = null;
	private uint32 mNodesDrawn = 0;
	private uint32 mNodesCulled = 0;
	private bool mCulling = true;
	private uint32 mFrame = 0;
	private List<Rect> mRedraws = null;
	private List<Rect> mDamage = null; // what the frame changed

	/// Borrows `context`, which must outlive it.
	public this(VGContext context, float dpiScale = 1.0f)
	{
		mVG = context;
		mDpiScale = dpiScale;
	}

	/// The underlying vector-graphics context (the actual draw surface).
	public VGContext VG => mVG;
	public float DpiScale => mDpiScale;

	/// The host's baker (a root's DrawFrame sets its GUI's): vector pictures drawn as baked
	/// textures; null draws them as paths. Borrowed.
	public IPictureBaker PictureBaker
	{
		get => mBaker;
		set => mBaker = value;
	}

	// Clip stack (device/local rect).
	public void PushClip(Rect rect) => mVG.PushClipRect(rect.ToRectangle());
	public void PopClip() => mVG.PopClip();

	// Opacity stack (multiplies down the subtree).
	public void PushOpacity(float opacity) => mVG.PushOpacity(opacity);
	public void PopOpacity() => mVG.PopOpacity();

	// Save/restore the whole VG state (transform + clip + opacity + blend).
	public void Save() => mVG.PushState();
	public void Restore() => mVG.PopState();

	/// Device pixels per local unit under the current transform (its area scale's root), for
	/// sizes VG takes in device pixels: a blur's sigma.
	public float DeviceScale
	{
		get
		{
			let m = mVG.GetTransform();
			return Sqrt(Abs(m.M[0][0] * m.M[1][1] - m.M[0][1] * m.M[1][0]));
		}
	}

	/// Concatenate a local transform onto the current one (child-local applied first).
	public void ConcatTransform(Transform2D transform)
	{
		mVG.SetTransform(transform.ToMatrix() * mVG.GetTransform());
	}

	// What a draw did: the nodes it drew and the ones it culled.

	/// Whether a rect in the current space can put anything under the clip, with a margin for
	/// what no ink box measures (text effects an ancestor sets, glyphs past their advance,
	/// anti-aliasing). True with culling off.
	public bool IsVisible(Rect local)
	{
		if (!mCulling)
			return true;
		return mVG.IsRectVisible(.(local.X - cVisibleMargin, local.Y - cVisibleMargin, local.Width + 2.0f * cVisibleMargin,
			local.Height + 2.0f * cVisibleMargin));
	}

	/// What of the current local space can show: the clip mapped back, grown by the margin
	/// IsVisible allows. False when everything can show (no clip, or culling off): a node with
	/// many children then draws them all.
	public bool GetVisibleBounds(out Rect outBounds)
	{
		outBounds = .();
		Rectangle clip = .();
		if (!mCulling || !mVG.GetLocalClipBounds(out clip))
			return false;
		outBounds = .(clip.X - cVisibleMargin, clip.Y - cVisibleMargin, clip.Width + 2.0f * cVisibleMargin,
			clip.Height + 2.0f * cVisibleMargin);
		return true;
	}

	/// Off, every node draws, whatever the clip (the culling test's reference).
	public bool Culling
	{
		get => mCulling;
		set => mCulling = value;
	}

	/// The host's frame being drawn (SceneRoot.DrawFrame numbers them; 0 for a draw outside
	/// one): each node drawn notes it, so an animation knows whether its node showed.
	public uint32 Frame
	{
		get => mFrame;
		set => mFrame = value;
	}

	/// Where a node drawn that invalidated itself since its last draw notes its bounds in the
	/// world (the debug overlay's redraw flash); none by default. Borrowed.
	public void SetRedrawRecorder(List<Rect> recorder) => mRedraws = recorder;
	public bool RecordsRedraws => mRedraws != null;

	public void RecordRedraw(Rect world)
	{
		if (mRedraws != null)
			mRedraws.Add(world);
	}

	/// Where the frame notes what it changed (damage, in device pixels); none by default.
	/// Borrowed.
	public void SetDamageRecorder(List<Rect> recorder) => mDamage = recorder;

	public void RecordDamage(Rect device)
	{
		if (mDamage != null)
			mDamage.Add(device);
	}

	public bool RecordsDamage => mDamage != null;

	/// `local` in device pixels under the current transform: the bounds of its corners.
	public Rect DeviceRect(Rect local)
	{
		let m = mVG.GetTransform();
		Float2[4] corners = .(
			TransformPoint2D(.(local.X, local.Y), m),
			TransformPoint2D(.(local.Right, local.Y), m),
			TransformPoint2D(.(local.X, local.Bottom), m),
			TransformPoint2D(.(local.Right, local.Bottom), m));
		var mn = corners[0];
		var mx = corners[0];
		for (let c in corners)
		{
			mn = .(Min(mn.X, c.X), Min(mn.Y, c.Y));
			mx = .(Max(mx.X, c.X), Max(mx.Y, c.Y));
		}
		return .(mn.X, mn.Y, mx.X - mn.X, mx.Y - mn.Y);
	}

	public void CountDrawn() { mNodesDrawn++; }
	public void CountCulled() { mNodesCulled++; }
	public uint32 NodesDrawn => mNodesDrawn;
	public uint32 NodesCulled => mNodesCulled;
}
