using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// Transient notifications stacked in the bottom right corner, newest nearest the corner.
///
/// The host FILLS the viewport and is itself input transparent, so only the cards are hittable
/// and it can be laid over a whole screen root without swallowing the game's input.
///
/// A card's buttons only MARK their toast closing; the view leaves on the next Update. That is
/// the mutation queue rule reached without the queue: a click handler must not remove the view
/// whose event is being dispatched.
///
/// There is no self ticking. The owning app calls Update once per frame, because the host has
/// no clock of its own and inventing one would age toasts while the game is paused.
///
/// DELIBERATELY DUPLICATED with the game kit's toast host, which is the same behaviour under a
/// different namespace. The game kit builds on the UI proper and never on the toolkit, and the
/// toolkit never reaches into the game kit, so neither can be the other's dependency. The two
/// differ in ONE character: this one closes with a multiplication sign and the game kit's with a
/// letter x. Keep any behaviour change in step across both.
class ToastHost : ViewGroup
{
	private struct Entry
	{
		public uint64 Id = 0;
		public float Age = 0.0f;
		public float Duration = 0.0f;
		public bool Closing = false;
		/// BORROWED: the child list owns the card.
		public View Card = null;
		/// OWNED.
		public delegate void() OnAction = null;

		public this() {}
	}

	public float ToastWidth = 340.0f;
	public float CornerMargin = 12.0f;
	public float Spacing = 8.0f;

	private List<Entry> mEntries = new .() ~ ReleaseEntries!(_);
	private uint64 mNextId = 1;

	public this()
	{
		IsHitTestVisible = false; // only the cards take input
	}

	private static mixin ReleaseEntries(var entries)
	{
		for (let entry in entries)
			delete entry.OnAction;
		delete entries;
	}

	/// Live, not yet removed, toasts.
	public int ToastCount => mEntries.Count;

	public bool Contains(uint64 id)
	{
		for (let entry in mEntries)
		{
			if (entry.Id == id)
				return true;
		}
		return false;
	}

	/// Adds a toast and returns its id, which Dismiss and Contains take. CONSUMES the request's
	/// action delegate; its strings are copied here and not retained.
	public uint64 Show(ToastRequest request)
	{
		let id = mNextId++;

		let card = new ToastCard();
		// Severity resolves THROUGH THE THEME, the semantic status properties mapping onto the
		// palette, so a game's own palette recolours its toasts. AccentFor is only the fallback
		// for a tree with no sheet at all.
		card.Accent = ResolveStyleColor(SeverityProperty(request.Severity),
			AccentFor(request.Severity));

		let message = new Label();
		message.SetText(request.Message);
		message.FontSize.Value = 12.0f;
		message.VAlign.Value = .Middle;

		LayoutStyle messageStyle = .();
		messageStyle.FlexGrow = 1.0f;
		messageStyle.Height = SizeSpec.Match();
		card.AddView(message, messageStyle);

		if (!request.ActionLabel.IsEmpty)
		{
			let action = new Button(request.ActionLabel);
			action.OnClick.Add(new [=](button) =>
				{
					InvokeAction(id);
					MarkClosing(id);
				});
			card.AddView(action);
		}

		let close = new Button("\u{00D7}");
		close.OnClick.Add(new [=](button) => { MarkClosing(id); });
		card.AddView(close);

		AddView(card);

		Entry entry = .();
		entry.Id = id;
		entry.Duration = request.DurationSeconds;
		entry.Card = card;
		entry.OnAction = request.OnAction;
		mEntries.Add(entry);

		Invalidate();
		return id;
	}

	/// Marks a toast for removal; its card leaves on the next Update.
	public void Dismiss(uint64 id) => MarkClosing(id);

	/// Per frame: ages timed toasts and removes the expired and closed ones, which happens here
	/// rather than inside an event so it is never mid dispatch.
	public void Update(float deltaTime)
	{
		var changed = false;

		for (int i < mEntries.Count)
		{
			var entry = ref mEntries[i];
			if (entry.Closing || (entry.Duration <= 0.0f))
				continue;

			entry.Age += deltaTime;
			if (entry.Age >= entry.Duration)
				entry.Closing = true;
		}

		for (int i = mEntries.Count - 1; i >= 0; i--)
		{
			if (!mEntries[i].Closing)
				continue;

			RemoveView(mEntries[i].Card);
			delete mEntries[i].OnAction;
			mEntries.RemoveAt(i);
			changed = true;
		}

		if (changed)
			Invalidate();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// Cards are a FIXED width and free height: a notification that grew with the window
		// would reflow its own text every resize.
		let cardConstraints = BoxConstraints(ToastWidth, ToastWidth, 0.0f, 200.0f);
		for (let entry in mEntries)
			entry.Card.Measure(cardConstraints);

		MeasuredSize = .(constraints.MaxWidth, constraints.MaxHeight);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		// Newest nearest the bottom right corner, stacking upward.
		var y = height - CornerMargin;
		for (int i = mEntries.Count - 1; i >= 0; i--)
		{
			let card = mEntries[i].Card;
			let cardHeight = card.MeasuredSize.Y;
			y -= cardHeight;
			card.Layout(width - CornerMargin - ToastWidth, y, ToastWidth, cardHeight);
			y -= Spacing;
		}
	}

	private void MarkClosing(uint64 id)
	{
		for (int i < mEntries.Count)
		{
			if (mEntries[i].Id != id)
				continue;

			mEntries[i].Closing = true;
			return;
		}
	}

	private void InvokeAction(uint64 id)
	{
		for (let entry in mEntries)
		{
			if (entry.Id != id)
				continue;

			if (entry.OnAction != null)
				entry.OnAction();
			return;
		}
	}

	private static StyleProperty SeverityProperty(ToastSeverity severity)
	{
		switch (severity)
		{
		case .Success: return .SuccessColor;
		case .Warning: return .WarningColor;
		case .Error: return .ErrorColor;
		case .Info: return .AccentColor;
		}
	}

	private static Color AccentFor(ToastSeverity severity)
	{
		switch (severity)
		{
		case .Success: return .(0.30f, 0.75f, 0.40f, 1.0f);
		case .Warning: return .(0.95f, 0.70f, 0.25f, 1.0f);
		case .Error: return .(0.90f, 0.30f, 0.30f, 1.0f);
		case .Info: return .(0.35f, 0.55f, 0.95f, 1.0f);
		}
	}
}
