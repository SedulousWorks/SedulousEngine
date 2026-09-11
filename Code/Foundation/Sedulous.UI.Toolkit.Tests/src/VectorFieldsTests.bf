using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The standalone vector inputs, and the one edit transaction they aggregate across their
/// fields.
class VectorFieldsTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	[Test]
	public static void AVector2FieldRoundTripsAndConfigures()
	{
		let field = new Vector2Field();
		defer field.ReleaseRef();

		Test.Assert(field.ChildCount == 2);

		field.SetValue(.(3.0f, 4.0f));
		Test.Assert(field.Value.X == 3.0f);
		Test.Assert(field.Value.Y == 4.0f);

		field.SetRange(-10.0, 10.0);
		field.SetStep(0.5);
		Test.Assert(field.Step == 0.5);
	}

	[Test]
	public static void TheThreeAndFourComponentFieldsMatchTheirAxisCount()
	{
		let three = new Vector3Field();
		defer three.ReleaseRef();
		Test.Assert(three.ChildCount == 3);
		three.SetValue(.(1.0f, 2.0f, 3.0f));
		Test.Assert(three.Value.Z == 3.0f);

		let four = new Vector4Field();
		defer four.ReleaseRef();
		Test.Assert(four.ChildCount == 4);
		four.SetValue(.(1.0f, 2.0f, 3.0f, 4.0f));
		Test.Assert(four.Value.W == 4.0f);

		four.SetDecimalPlaces(2);
		Test.Assert(four.DecimalPlaces == 2);
	}

	/// Typing into one field reports the WHOLE vector, since that is what a consumer stores.
	[Test]
	public static void AFieldReportsTheWholeVector()
	{
		let field = new Vector3Field();
		defer field.ReleaseRef();

		Float3 observed = .Zero;
		var fired = 0;
		field.OnValueChanged.Add(new [&fired, &observed](value) => { observed = value; fired++; });

		field.SetValue(.(1.0f, 2.0f, 3.0f));
		Test.Assert(fired == 0, "the host writing a value is not an edit");

		let y = field.GetChildAt(1) as NumericField;
		y.SetValue(9.0);
		Test.Assert(fired == 1);
		Test.Assert(observed.X == 1.0f);
		Test.Assert(observed.Y == 9.0f);
		Test.Assert(observed.Z == 3.0f);
	}

	/// The whole row is ONE transaction. With no context the close runs at once rather than
	/// waiting for a queue that does not exist.
	[Test]
	public static void EditsAcrossFieldsAggregateIntoOneTransaction()
	{
		let field = new Vector3Field();
		defer field.ReleaseRef();

		var began = 0;
		var ended = 0;
		field.OnEditBegan.Add(new [&began](sender) => { began++; });
		field.OnEditEnded.Add(new [&ended](sender) => { ended++; });

		let x = field.GetChildAt(0) as NumericField;
		let y = field.GetChildAt(1) as NumericField;

		x.OnFocusGained();
		Test.Assert(began == 1);

		// A focus jump arrives as the incoming begin then the outgoing end, and the row must
		// stay open across it.
		y.OnFocusGained();
		x.OnFocusLost();
		Test.Assert(began == 1, "still one transaction");
		Test.Assert(ended == 0, "the row is still being edited");

		y.OnFocusLost();
		Test.Assert(ended == 1);
	}

	[Test]
	public static void AQuaternionFieldEditsThreeEulerAngles()
	{
		let field = new QuaternionField();
		defer field.ReleaseRef();

		Test.Assert(field.ChildCount == 3);

		field.SetValue(.Identity);
		Test.Assert(Near(field.Value.W, 1.0f));
		Test.Assert(Near(field.Value.X, 0.0f));
		Test.Assert(Near(field.EulerDegrees.X, 0.0f));
	}

	/// A rotation survives the trip out to angles and back, which is what makes the cached
	/// angles safe to edit.
	[Test]
	public static void EulerAnglesRoundTripThroughAQuaternion()
	{
		let euler = Float3(30.0f, 45.0f, 60.0f);
		let quaternion = QuaternionField.FromEulerDegrees(euler);
		let back = QuaternionField.ToEulerDegrees(quaternion);

		Test.Assert(Near(back.X, 30.0f, 0.01f));
		Test.Assert(Near(back.Y, 45.0f, 0.01f));
		Test.Assert(Near(back.Z, 60.0f, 0.01f));
	}

	/// GIMBAL LOCK: the middle axis of the composition is Y, so a yaw of exactly ninety puts
	/// the arcsine on its domain boundary, where a hair over comes back NaN and poisons the
	/// whole rotation.
	[Test]
	public static void AYawAtThePoleStaysFinite()
	{
		let quaternion = QuaternionField.FromEulerDegrees(.(0.0f, 90.0f, 0.0f));
		let back = QuaternionField.ToEulerDegrees(quaternion);

		Test.Assert(Near(back.Y, 90.0f, 0.05f));
		Test.Assert(back.X == back.X, "not a NaN");
		Test.Assert(back.Z == back.Z);
	}

	/// A REGRESSION GATE on the corrected decomposition: the C++ inverts single axis rotations
	/// correctly and every combination of two or more incorrectly, so a test that only tried
	/// one axis at a time would pass over the defect.
	[Test]
	public static void ACompoundRotationRoundTripsOnEveryAxis()
	{
		Float3[3] cases = .(.(30.0f, 45.0f, 60.0f), .(15.0f, 25.0f, 35.0f),
			.(-120.0f, 40.0f, 170.0f));

		for (let euler in cases)
		{
			let back = QuaternionField.ToEulerDegrees(
				QuaternionField.FromEulerDegrees(euler));
			Test.Assert(Near(back.X, euler.X, 0.01f));
			Test.Assert(Near(back.Y, euler.Y, 0.01f));
			Test.Assert(Near(back.Z, euler.Z, 0.01f));
		}
	}
}
