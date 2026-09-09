using System;
using Sedulous.Core;
using Sedulous.PropertyAnimation;

namespace Sedulous.PropertyAnimation.Tests;

/// Resolving a property path, and reading and writing through it.
class PropertyBindingTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void ALeafPathIsOneLink()
	{
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Position", binding);

		Test.Assert(binding.IsResolved);
		Test.Assert(binding.Chain.Length == 1);
	}

	[Test]
	public static void ANestedPathIsOneLinkPerSegment()
	{
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Light.Tint", binding);

		Test.Assert(binding.IsResolved);
		Test.Assert(binding.Chain.Length == 2);
	}

	[Test]
	public static void AMissingSegmentDoesNotResolve()
	{
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Missing", binding);
		Test.Assert(!binding.IsResolved);
	}

	[Test]
	public static void AnEmptyPathDoesNotResolve()
	{
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "", binding);
		Test.Assert(!binding.IsResolved);
	}

	/// A LEAF VALUE ends the path even though it has components of its own: a vector's parts
	/// are not separately animated, the whole vector is.
	[Test]
	public static void AValuePathCannotBeWalkedIntoFurther()
	{
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Position.X", binding);
		Test.Assert(!binding.IsResolved);
	}

	[Test]
	public static void AMissingSegmentAfterAGoodOneDoesNotResolve()
	{
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Light.Missing", binding);
		Test.Assert(!binding.IsResolved);
	}

	/// A resolve that fails leaves NOTHING behind, so a binding reused across paths never
	/// carries a half walked chain into its next use.
	[Test]
	public static void AFailedResolveClearsWhatItHadWalked()
	{
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Light.Tint", binding);
		Test.Assert(binding.Chain.Length == 2);

		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Light.Missing", binding);
		Test.Assert(binding.Chain.Length == 0);
	}

	[Test]
	public static void AWriteReachesALeafProperty()
	{
		let component = scope AnimComponent();
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Position", binding);

		Test.Assert(PropertyBindingResolver.Write(binding, component,
			PropertyValue.FromFloat3(.(1.0f, 2.0f, 3.0f))) case .Ok);
		Test.Assert(Near(component.Position.X, 1.0f));
		Test.Assert(Near(component.Position.Y, 2.0f));
		Test.Assert(Near(component.Position.Z, 3.0f));
	}

	[Test]
	public static void AWriteReachesANestedProperty()
	{
		let component = scope AnimComponent();
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Light.Tint", binding);

		Test.Assert(PropertyBindingResolver.Write(binding, component,
			PropertyValue.FromColor(.(0.5f, 0.25f, 0.125f, 1.0f))) case .Ok);
		Test.Assert(Near(component.Light.Tint.R, 0.5f));
		Test.Assert(Near(component.Light.Tint.G, 0.25f));
		Test.Assert(Near(component.Light.Tint.B, 0.125f));
	}

	/// The nested address is re-derived on EVERY write rather than cached, so a second one
	/// lands just as squarely as the first.
	[Test]
	public static void ASecondWriteWalksTheAddressAgain()
	{
		let component = scope AnimComponent();
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Light.Tint", binding);

		Test.Assert(PropertyBindingResolver.Write(binding, component,
			PropertyValue.FromColor(.(0.5f, 0.0f, 0.0f, 1.0f))) case .Ok);
		Test.Assert(PropertyBindingResolver.Write(binding, component,
			PropertyValue.FromColor(.(0.9f, 0.0f, 0.0f, 1.0f))) case .Ok);
		Test.Assert(Near(component.Light.Tint.R, 0.9f));
	}

	[Test]
	public static void AWriteThroughAnUnresolvedBindingFailsCleanly()
	{
		let component = scope AnimComponent();
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Nope", binding);

		Test.Assert(PropertyBindingResolver.Write(binding, component,
			PropertyValue.FromFloat(1.0f)) case .Err);
	}

	/// A value of the wrong kind is REFUSED rather than written: the alternative is the wrong
	/// bytes landing in the field.
	[Test]
	public static void AWriteOfTheWrongKindIsRefused()
	{
		let component = scope AnimComponent();
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Position", binding);

		Test.Assert(PropertyBindingResolver.Write(binding, component,
			PropertyValue.FromFloat(1.0f)) case .Err);
		Test.Assert(Near(component.Position.X, 0.0f));
	}

	[Test]
	public static void AWriteWithNoInstanceFailsCleanly()
	{
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Position", binding);

		Test.Assert(PropertyBindingResolver.Write(binding, null,
			PropertyValue.FromFloat3(.(1.0f, 2.0f, 3.0f))) case .Err);
	}

	[Test]
	public static void AReadAnswersTheLiveValue()
	{
		let component = scope AnimComponent();
		component.Position = .(7.0f, 8.0f, 9.0f);
		component.Light.Tint = .(0.2f, 0.3f, 0.4f, 1.0f);
		component.Intensity = 2.5f;

		let position = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Position", position);
		let tint = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Light.Tint", tint);
		let intensity = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Intensity", intensity);

		Test.Assert(Near(PropertyBindingResolver.Read(position, component).Vector.X, 7.0f));
		Test.Assert(Near(PropertyBindingResolver.Read(tint, component).Color.G, 0.3f));
		Test.Assert(Near(PropertyBindingResolver.Read(intensity, component).Scalar, 2.5f));
	}

	/// A snapshot taken before a transient write RESTORES exactly, which is what an in scene
	/// preview relies on.
	[Test]
	public static void ASnapshotRestoresWhatWasThere()
	{
		let component = scope AnimComponent();
		component.Position = .(7.0f, 8.0f, 9.0f);

		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Position", binding);

		let snapshot = PropertyBindingResolver.Read(binding, component);
		Test.Assert(snapshot.HasValue);

		Test.Assert(PropertyBindingResolver.Write(binding, component,
			PropertyValue.FromFloat3(.(-1.0f, -1.0f, -1.0f))) case .Ok);
		Test.Assert(Near(component.Position.X, -1.0f));

		Test.Assert(PropertyBindingResolver.Write(binding, component, snapshot) case .Ok);
		Test.Assert(Near(component.Position.X, 7.0f));
		Test.Assert(Near(component.Position.Z, 9.0f));
	}

	[Test]
	public static void AReadThroughAnUnresolvedBindingIsEmpty()
	{
		let component = scope AnimComponent();
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Nope", binding);

		Test.Assert(!PropertyBindingResolver.Read(binding, component).HasValue);
	}

	/// A leaf whose type is not one a track animates reads as nothing rather than as
	/// whichever kind happens to be first.
	[Test]
	public static void AReadOfAnUnanimatableLeafIsEmpty()
	{
		let component = scope AnimComponent();
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Light", binding);

		Test.Assert(binding.IsResolved);
		Test.Assert(!PropertyBindingResolver.Read(binding, component).HasValue);
	}

	[Test]
	public static void ARotationRoundTripsThroughItsBinding()
	{
		let component = scope AnimComponent();
		let binding = scope PropertyBinding();
		PropertyBindingResolver.Resolve(typeof(AnimComponent), "Rotation", binding);

		let turn = Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), 1.0f);
		Test.Assert(PropertyBindingResolver.Write(binding, component,
			PropertyValue.FromQuaternion(turn)) case .Ok);

		let read = PropertyBindingResolver.Read(binding, component).Rotation;
		Test.Assert(Near(read.Y, turn.Y));
		Test.Assert(Near(read.W, turn.W));
	}
}
