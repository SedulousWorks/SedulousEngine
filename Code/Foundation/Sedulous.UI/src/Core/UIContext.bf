using System;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// The root of one UI tree: its frame damage, its style generation, and the theme sheet.
///
/// PARTIAL PORT. Damage tracking, the style generation and sheet epoch, the mutation queue,
/// the transition list, the clipboard and font service seams are here. The six managers, the
/// root view list, the frame lifecycle and the draw path stay in the ledger's View.cppm and
/// UIClusterImpl.cpp until those subsystems land.
class UIContext
{
	private UIContextPhase mPhase = .Idle;
	private bool mNeedsRedraw = false;
	private bool mNeedsLayout = false;
	private float mDeltaTime = 0.0f;
	private float mTotalTime = 0.0f;

	private MutationQueue mMutationQueue = new .() ~ delete _;
	/// OWNED.
	private StyleSheet mStyleSheet ~ _?.ReleaseRef();
	private uint32 mSheetEpoch = 1;
	private uint32 mStyleGeneration = 1;
	/// BORROWED: a view de-lists itself when its transitions end or it detaches.
	private List<View> mTransitioning = new .() ~ delete _;

	/// BORROWED, and nullable. The core stays platform agnostic; the application or the shell
	/// bridge supplies these.
	private IClipboard mClipboard = null;
	private IFontService mFontService = null;

	public this() {}

	public ~this()
	{
		mMutationQueue.Drain();
	}

	public UIContextPhase CurrentPhase => mPhase;

	// ---- Frame damage --------------------------------------------------------------------------

	public bool NeedsRedraw => mNeedsRedraw;

	/// Some view's GEOMETRY may have changed since the last layout pass.
	///
	/// Visual only damage, such as a hover tint or a caret blink, leaves this CLEAR, so the
	/// host redraws without re-measuring the whole tree. That is what makes an interaction
	/// frame cheap.
	public bool NeedsLayout => mNeedsLayout;

	public void ClearLayoutDamage() => mNeedsLayout = false;

	public void MarkNeedsRedraw() => mNeedsRedraw = true;

	public void MarkNeedsLayout()
	{
		mNeedsLayout = true;
		// A relayout always redraws.
		mNeedsRedraw = true;
	}

	public float DeltaTime => mDeltaTime;
	public float TotalTime => mTotalTime;

	public MutationQueue MutationQueue => mMutationQueue;

	// ---- Style ---------------------------------------------------------------------------------

	public StyleSheet GetStyleSheet() => mStyleSheet;

	/// Installs the context sheet, meaning the theme, and moves the sheet epoch. CONSUMES the
	/// caller's reference.
	///
	/// The theme is DATA, its motion included: a sheet declares its own `transition` rules and
	/// every shipped theme puts one on View. The engine prepends nothing and keeps no list of
	/// control types.
	public void SetStyleSheet(StyleSheet sheet)
	{
		if (mStyleSheet != null)
			mStyleSheet.ReleaseRef();
		mStyleSheet = sheet;
		BumpSheetEpoch();
	}

	/// Bumped whenever rule OBJECTS may have been replaced, by a context or local sheet swap.
	/// A view's style cache from another epoch is rebuilt WITHOUT being read, its rule
	/// pointers no longer being known to be alive.
	public uint32 SheetEpoch => mSheetEpoch;

	public void BumpSheetEpoch()
	{
		mSheetEpoch++;
		InvalidateStyles();
	}

	/// Bumped by anything that changes which rules MATCH a view: classes, ids, sheets, tree
	/// structure. Every view's computed style cache keys on it.
	public uint32 StyleGeneration => mStyleGeneration;

	public void InvalidateStyles()
	{
		mStyleGeneration++;
	}

	// ---- Transitions ---------------------------------------------------------------------------

	/// A view with a running transition asks to be ticked each frame.
	public void RegisterTransitioning(View view) => mTransitioning.Add(view);

	public void UnregisterTransitioning(View view)
	{
		for (int i = mTransitioning.Count - 1; i >= 0; i--)
		{
			if (mTransitioning[i] == view)
				mTransitioning.RemoveAtFast(i);
		}
	}

	public int TransitioningViewCount => mTransitioning.Count;

	// ---- Injected seams ------------------------------------------------------------------------

	public IClipboard Clipboard => mClipboard;
	public void SetClipboard(IClipboard clipboard) => mClipboard = clipboard;

	public IFontService FontService => mFontService;
	public void SetFontService(IFontService fontService) => mFontService = fontService;
}
