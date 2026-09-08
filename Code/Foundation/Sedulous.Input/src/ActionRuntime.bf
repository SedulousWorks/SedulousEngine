using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Input;

/// Per frame evaluation of an input map against polled devices.
///
/// The value model is Godot's: bindings FOLD by largest magnitude per component, digital
/// presses OR, dead zones on a stick are circular, and an edge is exact against a frame
/// counter rather than approximated from the value.
///
/// The set model is layered on top: every enabled set evaluates, a query resolves flat by
/// set priority, and an exclusive push makes one set modal. What makes the modal case
/// behave is HELD SUPPRESSION LATCHING: an action suppressed while physically held stays
/// released until it is physically released, so closing a menu never re-fires a Fire the
/// player has been holding down through it.
class ActionRuntime
{
	/// Where an analog value starts counting as a press.
	public const float cPressPoint = 0.5f;

	/// Per action, flat and parallel to (set, action) in map order.
	private struct ActionState
	{
		/// After processors and after suppression: what a query reports.
		public Float2 Value = .Zero;
		/// The smoothing integrator, BEFORE suppression, so a suppressed ramp does not
		/// silently keep climbing.
		public Float2 Smoothed = .Zero;
		public bool Pressed = false;
		/// Held through a suppression: stays released until a fresh press.
		public bool Latched = false;
		public uint64 PressedFrame = 0;
		public uint64 ReleasedFrame = 0;

		/// The interaction machine, for a Button action whose kind is not None.
		public bool RawHeld = false;
		public float HeldSeconds = 0.0f;
		public float SinceLastTap = 1.0e9f;
		public bool HoldFired = false;

		/// A touch stick's owning contact and where it anchored.
		public uint64 TouchId = 0;
		public Float2 TouchAnchor = .Zero;

		public this() {}
	}

	/// One place an action name was found.
	private struct Candidate
	{
		public int Set;
		public int FlatIndex;
	}

	/// A resolved name and every action carrying it, sorted by set priority.
	private class RefEntry
	{
		public String Name = new .() ~ delete _;
		public List<Candidate> Candidates = new .() ~ delete _;
	}

	private InputMap mMap = new .() ~ delete _;
	private List<ActionState> mStates = new .() ~ delete _;
	private List<bool> mSetEnabled = new .() ~ delete _;
	private List<String> mExclusiveStack = new .() ~ DeleteContainerAndItems!(_);
	private List<RefEntry> mRefs = new .() ~ DeleteContainerAndItems!(_);
	private uint64 mFrame = 0;
	private float mTimeScale = 1.0f;
	private ConsumptionMask mConsumed = .();
	/// Set by an exclusive push or pop, consumed by the next Update.
	private bool mLatchHeldOnce = false;

	/// Installs a COPY of the map and rebuilds every piece of state. Every set starts
	/// enabled.
	///
	/// A copy because the runtime's state is indexed positionally against the map: a caller
	/// that edited the map underneath it would silently reindex everything.
	public void SetMap(InputMap map)
	{
		map.CopyTo(mMap);

		mStates.Clear();
		mSetEnabled.Clear();
		ClearAndDeleteItems!(mExclusiveStack);
		ClearAndDeleteItems!(mRefs);

		int actionTotal = 0;
		for (let set in mMap.Sets)
			actionTotal += set.Actions.Count;

		mStates.Resize(actionTotal);
		for (int i = 0; i < actionTotal; i++)
			mStates[i] = .();

		mSetEnabled.Resize(mMap.Sets.Count);
		for (int i = 0; i < mSetEnabled.Count; i++)
			mSetEnabled[i] = true;
	}

	/// The installed copy. Read only to a caller: editing it desynchronises the state
	/// tables that are indexed against it.
	public InputMap Map => mMap;

	// ---- sets ----

	public void EnableSet(StringView name, bool enabled = true)
	{
		for (int i = 0; i < mMap.Sets.Count; i++)
		{
			if (mMap.Sets[i].Name == name)
				mSetEnabled[i] = enabled;
		}
	}

	public void DisableSet(StringView name) => EnableSet(name, false);

	public bool IsSetEnabled(StringView name)
	{
		for (int i = 0; i < mMap.Sets.Count; i++)
		{
			if (mMap.Sets[i].Name == name)
				return mSetEnabled[i];
		}
		return false;
	}

	/// Makes a set MODAL: while the stack is non empty only the top set's actions read
	/// active, and everything else reads released with proper release edges.
	///
	/// Every exclusive transition also latches whatever is physically held. A modal
	/// boundary demands a fresh press, so a held Fire neither confirms the menu that just
	/// opened nor fires again when it closes.
	public void PushExclusiveSet(StringView name)
	{
		mExclusiveStack.Add(new String(name));
		mLatchHeldOnce = true;
	}

	public void PopExclusiveSet()
	{
		if (mExclusiveStack.IsEmpty)
			return;

		delete mExclusiveStack.PopBack();
		mLatchHeldOnce = true;
	}

	public int ExclusiveDepth => mExclusiveStack.Count;

	// ---- resolution ----

	/// Resolves a name across ALL sets, caching the candidates sorted by set priority.
	///
	/// FLAT rather than per set: a caller asks for "Jump", not for "Gameplay's Jump". At
	/// query time the highest priority candidate in an enabled set answers, which is what
	/// lets a menu take Cancel while gameplay still declares its own.
	public ActionRef Resolve(StringView name)
	{
		for (int i = 0; i < mRefs.Count; i++)
		{
			if (mRefs[i].Name == name)
				return .((uint32)i);
		}

		let entry = new RefEntry();
		entry.Name.Set(name);

		int flat = 0;
		for (int s = 0; s < mMap.Sets.Count; s++)
		{
			for (int a = 0; a < mMap.Sets[s].Actions.Count; a++, flat++)
			{
				if (mMap.Sets[s].Actions[a].Name == name)
					entry.Candidates.Add(.() { Set = s, FlatIndex = flat });
			}
		}

		// Highest priority first, and STABLE for ties so map order decides them: an
		// insertion sort, because a name lives in two or three sets, not in hundreds.
		for (int i = 1; i < entry.Candidates.Count; i++)
		{
			for (int j = i; j > 0; j--)
			{
				if (mMap.Sets[entry.Candidates[j].Set].Priority
					<= mMap.Sets[entry.Candidates[j - 1].Set].Priority)
					break;

				let swap = entry.Candidates[j - 1];
				entry.Candidates[j - 1] = entry.Candidates[j];
				entry.Candidates[j] = swap;
			}
		}

		mRefs.Add(entry);
		return .((uint32)(mRefs.Count - 1));
	}

	// ---- per frame evaluation ----

	public void Update(IInputSourceProvider devices, float deltaTime)
	{
		mFrame++;
		let exclusiveTop = ExclusiveTopSet();

		int flat = 0;
		for (int s = 0; s < mMap.Sets.Count; s++)
		{
			// A disabled set behaves exactly like an exclusively suppressed one: released,
			// and latching. Two ways to say "not now" that differ only in who said it.
			let suppressed = !mSetEnabled[s] || ((exclusiveTop >= 0) && (s != exclusiveTop));

			for (int a = 0; a < mMap.Sets[s].Actions.Count; a++, flat++)
			{
				EvaluateAction(mMap.Sets[s].Actions[a], ref mStates[flat], devices, deltaTime,
					suppressed, mLatchHeldOnce);
			}
		}

		mLatchHeldOnce = false;
	}

	/// The frame counter an edge is exact against. Starts at zero, so the first Update is
	/// frame one and a state that never fired cannot look like it fired on frame zero.
	public uint64 Frame => mFrame;

	/// The engine time scale, applied to actions whose processors ask for it: their VALUE
	/// multiplies by it, so a rate driving per second gameplay slows with the world.
	///
	/// A pointer rate simply does not set the flag. Slowing time must not slow the mouse.
	public void SetTimeScale(float scale)
	{
		mTimeScale = (scale < 0.0f) ? 0.0f : scale;
	}

	public float TimeScale => mTimeScale;

	public void SetConsumptionMask(ConsumptionMask mask) => mConsumed = mask;
	public ConsumptionMask GetConsumptionMask() => mConsumed;

	public static bool IsPointerSource(BindingSource source)
		=> (source == .MouseButton) || (source == .MouseAxis) || (source == .MouseDelta)
			|| (source == .TouchButton) || (source == .TouchStick);

	public static bool IsKeyboardSource(BindingSource source)
		=> (source == .Key) || (source == .Composite2D);

	public bool IsConsumed(BindingSource source)
		=> (mConsumed.Pointer && IsPointerSource(source))
			|| (mConsumed.Keyboard && IsKeyboardSource(source));

	// ---- queries ----

	public bool IsDown(ActionRef reference)
	{
		if (StateFor(reference) case .Ok(let index))
			return mStates[index].Pressed;
		return false;
	}

	public bool WasPressed(ActionRef reference)
	{
		if (StateFor(reference) case .Ok(let index))
			return mStates[index].PressedFrame == mFrame;
		return false;
	}

	public bool WasReleased(ActionRef reference)
	{
		if (StateFor(reference) case .Ok(let index))
			return mStates[index].ReleasedFrame == mFrame;
		return false;
	}

	public float Value(ActionRef reference)
	{
		if (StateFor(reference) case .Ok(let index))
			return mStates[index].Value.X;
		return 0.0f;
	}

	public Float2 Value2D(ActionRef reference)
	{
		if (StateFor(reference) case .Ok(let index))
			return mStates[index].Value;
		return .Zero;
	}

	/// A signed axis from two actions, for a caller composing one on the spot rather than
	/// declaring it in the map.
	public float Axis(ActionRef negative, ActionRef positive) => Value(positive) - Value(negative);

	/// The same for a vector, CLAMPED to length one so a diagonal is not faster than a
	/// cardinal.
	public Float2 Vector2(ActionRef negX, ActionRef posX, ActionRef negY, ActionRef posY)
	{
		var value = Float2(Value(posX) - Value(negX), Value(posY) - Value(negY));
		let length = Sqrt((value.X * value.X) + (value.Y * value.Y));
		if (length > 1.0f)
		{
			value.X /= length;
			value.Y /= length;
		}
		return value;
	}

	// ---- internals ----

	private int ExclusiveTopSet()
	{
		if (mExclusiveStack.IsEmpty)
			return -1;

		let top = mExclusiveStack[mExclusiveStack.Count - 1];
		for (int i = 0; i < mMap.Sets.Count; i++)
		{
			if (mMap.Sets[i].Name == top)
				return i;
		}
		// A push of a set that is not in the map suppresses nothing rather than everything:
		// a typo should not silently make the game unplayable.
		return -1;
	}

	/// The state index the reference resolves to right now, or Err when nothing answers.
	///
	/// Recomputed per query rather than cached, because enabling a set changes the answer
	/// and a cached one would keep reporting the set that was on when Resolve ran.
	private Result<int> StateFor(ActionRef reference)
	{
		if (!reference.IsValid || (reference.Index >= (uint32)mRefs.Count))
			return .Err;

		for (let candidate in mRefs[reference.Index].Candidates)
		{
			if (mSetEnabled[candidate.Set])
				return .Ok(candidate.FlatIndex);
		}
		return .Err;
	}

	private static float ApplyDeadZone(float value, float deadZone)
	{
		let magnitude = Abs(value);
		if (magnitude <= deadZone)
			return 0.0f;

		// Rescaled rather than clipped, so the value still reaches one at full deflection
		// and the first movement out of the zone is not a jump.
		let rescaled = (magnitude - deadZone) / (1.0f - deadZone);
		return (value < 0.0f) ? -rescaled : rescaled;
	}

	/// CIRCULAR, which is the whole reason a stick gets its own: a per axis zone leaves the
	/// diagonals live inside the corners of a square, so a stick at rest drifts diagonally.
	private static Float2 ApplyCircularDeadZone(Float2 value, float deadZone)
	{
		let length = Sqrt((value.X * value.X) + (value.Y * value.Y));
		if (length <= deadZone)
			return .Zero;

		let rescaled = Min((length - deadZone) / (1.0f - deadZone), 1.0f);
		let factor = rescaled / length;
		return .(value.X * factor, value.Y * factor);
	}

	/// What one binding contributed this frame.
	private struct Contribution
	{
		public Float2 Value = .Zero;
		/// A digital source that is down. Kept apart from the value because a button at
		/// full scale and an axis at full deflection are not the same claim: only the
		/// former is a press regardless of the press point.
		public bool DigitalDown = false;

		public this() {}
	}

	/// Whether a key is down AND its required modifiers are satisfied.
	///
	/// Each modifier GROUP is satisfied by any of its bits: a binding asking for Shift
	/// means either shift, not both at once. Raptor requires every bit of the mask, which
	/// makes a Shift binding unreachable, since nobody holds both shifts to fire one
	/// action. A specific side still works, because naming one bit leaves one bit to match.
	private static bool KeyDown(IKeyboard keyboard, uint32 code, uint32 modifiers)
	{
		if (keyboard == null)
			return false;
		if (!keyboard.IsKeyDown((KeyCode)code))
			return false;
		if (modifiers == 0)
			return true;

		let held = (uint32)keyboard.Modifiers;
		const uint32[4] cGroups = .(
			(uint32)KeyModifiers.Shift, (uint32)KeyModifiers.Ctrl,
			(uint32)KeyModifiers.Alt, (uint32)KeyModifiers.Gui);

		var remaining = modifiers;
		for (let group in cGroups)
		{
			let wanted = modifiers & group;
			if (wanted == 0)
				continue;
			if ((held & wanted) == 0)
				return false;
			remaining &= ~group;
		}

		// The locks, and anything else outside the paired groups, are single bits: there
		// is no "either" to take, so every one of them must be held.
		return (held & remaining) == remaining;
	}

	private static Contribution EvaluateBinding(Binding binding, IInputSourceProvider devices)
	{
		var result = Contribution();
		let sign = binding.Invert ? -1.0f : 1.0f;

		switch (binding.Source)
		{
		case .Key:
			if (KeyDown(devices.Keyboard, binding.Code, binding.Modifiers))
			{
				result.Value.X = binding.Scale * sign;
				result.DigitalDown = true;
			}

		case .MouseButton:
			let mouse = devices.Mouse;
			if ((mouse != null) && mouse.IsButtonDown((Sedulous.Shell.MouseButton)binding.Code))
			{
				result.Value.X = binding.Scale * sign;
				result.DigitalDown = true;
			}

		case .MouseAxis:
			if (let mouse = devices.Mouse)
			{
				float value = 0.0f;
				switch ((MouseAxisCode)binding.Code)
				{
				case .DeltaX: value = mouse.DeltaX;
				case .DeltaY: value = mouse.DeltaY;
				case .Wheel: value = mouse.ScrollY;
				default:
				}
				result.Value.X = value * binding.Scale * sign;
			}

		case .MouseDelta:
			if (let mouse = devices.Mouse)
			{
				// X is NOT inverted: Invert on a 2D source flips Y, which is the axis
				// people actually disagree about.
				result.Value.X = mouse.DeltaX * binding.Scale;
				result.Value.Y = mouse.DeltaY * binding.Scale * sign;
			}

		case .GamepadButton:
			ForEachPad(devices, binding.Device, scope [&](pad) =>
			{
				if (!pad.IsButtonDown((GamepadButton)binding.Code))
					return;
				result.Value.X = binding.Scale * sign;
				result.DigitalDown = true;
			});

		case .GamepadAxis:
			ForEachPad(devices, binding.Device, scope [&](pad) =>
			{
				let value = ApplyDeadZone(pad.Axis((GamepadAxis)binding.Code), binding.DeadZone)
					* binding.Scale * sign;
				// Largest magnitude across pads wins, so two players on one action do not
				// cancel each other out.
				if (Abs(value) > Abs(result.Value.X))
					result.Value.X = value;
			});

		case .GamepadStick:
			let left = (StickCode)binding.Code == .Left;
			let axisX = left ? GamepadAxis.LeftX : GamepadAxis.RightX;
			let axisY = left ? GamepadAxis.LeftY : GamepadAxis.RightY;
			ForEachPad(devices, binding.Device, scope [&](pad) =>
			{
				var value = ApplyCircularDeadZone(.(pad.Axis(axisX), pad.Axis(axisY)),
					binding.DeadZone);
				value.X *= binding.Scale;
				value.Y *= binding.Scale * sign;

				// Compared by LENGTH rather than per component, because the two components
				// of a stick are one reading and splitting them would build a direction no
				// pad reported.
				if (((value.X * value.X) + (value.Y * value.Y))
					> ((result.Value.X * result.Value.X) + (result.Value.Y * result.Value.Y)))
					result.Value = value;
			});

		case .Composite2D:
			let keyboard = devices.Keyboard;
			let x = (KeyDown(keyboard, binding.PosX, 0) ? 1.0f : 0.0f)
				- (KeyDown(keyboard, binding.NegX, 0) ? 1.0f : 0.0f);
			let y = (KeyDown(keyboard, binding.PosY, 0) ? 1.0f : 0.0f)
				- (KeyDown(keyboard, binding.NegY, 0) ? 1.0f : 0.0f);
			result.Value = .(x * binding.Scale, y * binding.Scale * sign);

			if (binding.Normalize)
			{
				let length = Sqrt((result.Value.X * result.Value.X)
					+ (result.Value.Y * result.Value.Y));
				if (length > 1.0f)
				{
					result.Value.X /= length;
					result.Value.Y /= length;
				}
			}
			result.DigitalDown = (x != 0.0f) || (y != 0.0f);

		case .TouchButton, .TouchStick:
			// STATEFUL: a touch stick has to remember its own contact, so both touch
			// sources are evaluated by the caller, which has the action's state to hand.
		}

		return result;
	}

	private static void ForEachPad(IInputSourceProvider devices, int32 wanted,
		delegate void(IGamepad) body)
	{
		let count = devices.GamepadCount;
		for (int32 i = 0; i < count; i++)
		{
			let pad = devices.GetGamepad(i);
			if ((pad == null) || !pad.Connected)
				continue;
			// Negative means any pad, which is what a single player game wants and what a
			// binding defaults to.
			if ((wanted >= 0) && (pad.Index != wanted))
				continue;
			body(pad);
		}
	}

	/// The touch sources, which carry per action state and so cannot live in the stateless
	/// helper above.
	private static Contribution EvaluateTouchBinding(Binding binding, IInputSourceProvider devices,
		ref ActionState state)
	{
		var result = Contribution();
		let touch = devices.Touch;
		if (touch == null)
		{
			// No touch device: drop the anchor, so plugging one in later does not resume a
			// stick from a contact that ended long ago.
			state.TouchId = 0;
			return result;
		}

		bool InRegion(float x, float y)
			=> (x >= binding.RegionX) && (x <= (binding.RegionX + binding.RegionW))
				&& (y >= binding.RegionY) && (y <= (binding.RegionY + binding.RegionH));

		let count = touch.TouchCount;

		if (binding.Source == .TouchButton)
		{
			for (int32 i = 0; i < count; i++)
			{
				if (touch.GetTouchPoint(i, var point) && InRegion(point.X, point.Y))
				{
					result.Value.X = binding.Scale;
					result.DigitalDown = true;
					break;
				}
			}
			return result;
		}

		// TouchStick: a FLOATING stick, anchored where its owning contact started rather
		// than where any art sits. That is what makes one usable without looking at it.
		if (state.TouchId != 0)
		{
			var owning = TouchPoint();
			var alive = false;
			for (int32 i = 0; i < count; i++)
			{
				if (touch.GetTouchPoint(i, var point) && (point.Id == state.TouchId))
				{
					owning = point;
					alive = true;
					break;
				}
			}

			if (!alive)
			{
				state.TouchId = 0;
			}
			else
			{
				let radius = (binding.StickRadius > 0.0f) ? binding.StickRadius : 0.15f;
				var value = Float2((owning.X - state.TouchAnchor.X) / radius,
					(owning.Y - state.TouchAnchor.Y) / radius);

				let length = Sqrt((value.X * value.X) + (value.Y * value.Y));
				if (length > 1.0f)
				{
					value.X /= length;
					value.Y /= length;
				}
				value = ApplyCircularDeadZone(value, binding.DeadZone);

				result.Value.X = value.X * binding.Scale;
				result.Value.Y = value.Y * binding.Scale * (binding.Invert ? -1.0f : 1.0f);
				result.DigitalDown = length > binding.DeadZone;
			}
		}

		if (state.TouchId == 0)
		{
			for (int32 i = 0; i < count; i++)
			{
				if (touch.GetTouchPoint(i, var point) && InRegion(point.X, point.Y))
				{
					state.TouchId = point.Id;
					state.TouchAnchor = .(point.X, point.Y);
					// The value stays zero this frame: the anchor IS the position.
					break;
				}
			}
		}

		return result;
	}

	private static float ApplyResponse(float value, float exponent)
	{
		if ((exponent == 1.0f) || (value == 0.0f))
			return value;

		let curved = Pow(Abs(value), exponent);
		return (value < 0.0f) ? -curved : curved;
	}

	private static float MoveToward(float current, float target, float maxDelta)
	{
		let difference = target - current;
		if (Abs(difference) <= maxDelta)
			return target;
		return current + ((difference > 0.0f) ? maxDelta : -maxDelta);
	}

	private void EvaluateAction(InputAction action, ref ActionState state,
		IInputSourceProvider devices, float deltaTime, bool suppressed, bool latchHeld)
	{
		// Fold: largest magnitude per component, digital presses OR'd. A key and a stick
		// can drive one action at once without the quieter one dragging the value down.
		var target = Float2.Zero;
		var digitalDown = false;

		for (let binding in action.Bindings)
		{
			if (IsConsumed(binding.Source))
				continue;

			let contribution = ((binding.Source == .TouchButton) || (binding.Source == .TouchStick))
				? EvaluateTouchBinding(binding, devices, ref state)
				: EvaluateBinding(binding, devices);

			if (Abs(contribution.Value.X) > Abs(target.X))
				target.X = contribution.Value.X;
			if (Abs(contribution.Value.Y) > Abs(target.Y))
				target.Y = contribution.Value.Y;
			digitalDown = digitalDown || contribution.DigitalDown;
		}

		let processors = action.Processors;
		target.X = ApplyResponse(target.X, processors.ResponseExponent);
		target.Y = ApplyResponse(target.Y, processors.ResponseExponent);

		// Smoothing is what gives a keyboard the feel of a stick. Never on a Button: a
		// press has no ramp, and one would only delay the edge.
		if ((processors.Sensitivity > 0.0f) && (action.Kind != .Button))
		{
			float Smooth(float current, float wanted)
			{
				var from = current;
				// Snap: zero first on a reversal, so a flip is immediate instead of having
				// to travel back through the middle.
				if (processors.Snap && (wanted != 0.0f) && (from != 0.0f)
					&& ((wanted > 0.0f) != (from > 0.0f)))
					from = 0.0f;

				// Recentring falls back to the ramp rate when no gravity is stated, so an
				// asymmetric feel is something you ask for rather than something you get.
				let rate = ((wanted == 0.0f) && (processors.Gravity > 0.0f))
					? processors.Gravity : processors.Sensitivity;
				return MoveToward(from, wanted, rate * deltaTime);
			}

			state.Smoothed.X = Smooth(state.Smoothed.X, target.X);
			state.Smoothed.Y = Smooth(state.Smoothed.Y, target.Y);
		}
		else
		{
			state.Smoothed = target;
		}

		let strength = Max(Abs(state.Smoothed.X), Abs(state.Smoothed.Y));
		let physicallyPressed = digitalDown || (strength > cPressPoint);

		// A press that lives through a suppression window must not fire when the window
		// ends, and an exclusive transition latches everything held for the same reason.
		if ((suppressed || latchHeld) && physicallyPressed)
			state.Latched = true;
		if (!physicallyPressed)
			state.Latched = false;

		let effective = physicallyPressed && !suppressed && !state.Latched;

		var reportedValue = state.Smoothed;
		if (processors.TimeScale)
		{
			reportedValue.X *= mTimeScale;
			reportedValue.Y *= mTimeScale;
		}
		state.Value = (suppressed || state.Latched) ? Float2.Zero : reportedValue;

		// An interaction reshapes the effective press into the reported one: Hold delays
		// it, Tap and DoubleTap turn it into a single frame pulse. None passes through.
		var reported = effective;
		switch (action.Interaction.Kind)
		{
		case .None:

		case .Hold:
			if (effective)
			{
				state.HeldSeconds += deltaTime;
				// HoldFired latches: once the threshold is crossed the press STAYS
				// reported, rather than pulsing on the one frame that crossed it.
				reported = state.HoldFired || (state.HeldSeconds >= action.Interaction.Seconds);
				state.HoldFired = reported;
			}
			else
			{
				state.HeldSeconds = 0.0f;
				state.HoldFired = false;
				reported = false;
			}

		case .Tap:
			reported = false;
			if (effective)
			{
				state.HeldSeconds += deltaTime;
			}
			else
			{
				// The pulse is at RELEASE, and only if the press was short enough. A tap
				// cannot be recognised while it is still going on.
				if (state.RawHeld && (state.HeldSeconds <= action.Interaction.Seconds))
					reported = true;
				state.HeldSeconds = 0.0f;
			}

		case .DoubleTap:
			state.SinceLastTap += deltaTime;
			reported = false;
			if (effective && !state.RawHeld)
			{
				if (state.SinceLastTap <= action.Interaction.Seconds)
				{
					reported = true;
					// Consumed, so a third press starts a new pair rather than firing again.
					state.SinceLastTap = 1.0e9f;
				}
				else
				{
					state.SinceLastTap = 0.0f;
				}
			}
		}

		state.RawHeld = effective;

		if (reported && !state.Pressed)
			state.PressedFrame = mFrame;
		if (!reported && state.Pressed)
			state.ReleasedFrame = mFrame;
		state.Pressed = reported;
	}
}
