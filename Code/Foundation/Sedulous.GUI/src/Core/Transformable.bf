using System;
using Sedulous.Core;

namespace Sedulous.GUI;

/// 2D position, rotation and scale with a lazily recomputed combined Transform2D (and its
/// inverse). The math base of Node. Ported from eepp's Math::Transformable; rotation is RADIANS
/// (eepp used degrees), and the setters are virtual so Node can hook invalidation.
class Transformable
{
	protected Float2 mPosition = .(0.0f, 0.0f);
	protected Float2 mScale = .(1.0f, 1.0f);
	protected Float2 mScaleOrigin = .(0.0f, 0.0f);
	protected Float2 mRotationOrigin = .(0.0f, 0.0f);
	protected float mRotation = 0.0f; // radians

	protected Transform2D mTransform = .();
	protected Transform2D mInverse = .();
	protected bool mTransformDirty = true;
	protected bool mInverseDirty = true;
	protected Transform2D mExtra = .();
	protected Float2 mExtraOrigin = .();

	public virtual Float2 Position
	{
		get => mPosition;
		set
		{
			mPosition = value;
			MarkDirty();
		}
	}

	/// Radians.
	public virtual float Rotation
	{
		get => mRotation;
		set
		{
			mRotation = value;
			MarkDirty();
		}
	}

	public virtual Float2 Scale
	{
		get => mScale;
		set
		{
			mScale = value;
			MarkDirty();
		}
	}

	public virtual Float2 ScaleOrigin
	{
		get => mScaleOrigin;
		set
		{
			mScaleOrigin = value;
			MarkDirty();
		}
	}

	public virtual Float2 RotationOrigin
	{
		get => mRotationOrigin;
		set
		{
			mRotationOrigin = value;
			MarkDirty();
		}
	}

	public void SetScale(float x, float y) => Scale = .(x, y);

	/// A further transform about `origin` (local units), after the position, scale and rotation:
	/// CSS's `transform` with its `transform-origin`.
	public void SetExtraTransform(Transform2D transform, Float2 origin)
	{
		mExtra = transform;
		mExtraOrigin = origin;
		MarkDirty();
	}

	public Transform2D ExtraTransform => mExtra;

	// Relative moves.
	public void Move(Float2 offset) => Position = mPosition + offset;
	public void Rotate(float radians) => Rotation = mRotation + radians;
	public void ScaleBy(Float2 factor) => Scale = mScale * factor;

	public Transform2D Transform
	{
		get
		{
			if (mTransformDirty)
			{
				// Post-multiply order (eepp): T(pos) * [scale about origin] * [rotate about origin].
				var t = Transform2D();
				t.Translate(mPosition);
				if (!((mScale.X == 1.0f) && (mScale.Y == 1.0f)))
				{
					t.Translate(mScaleOrigin);
					t.Scale(mScale);
					t.Translate(-mScaleOrigin);
				}
				if (mRotation != 0.0f)
				{
					t.Translate(mRotationOrigin);
					t.Rotate(mRotation);
					t.Translate(-mRotationOrigin);
				}
				if (!mExtra.IsIdentity)
				{
					t.Translate(mExtraOrigin);
					t.Combine(mExtra);
					t.Translate(-mExtraOrigin);
				}
				mTransform = t;
				mTransformDirty = false;
				mInverseDirty = true;
			}
			return mTransform;
		}
	}

	public Transform2D InverseTransform
	{
		get
		{
			if (mInverseDirty || mTransformDirty)
			{
				mInverse = Transform.GetInverse();
				mInverseDirty = false;
			}
			return mInverse;
		}
	}

	protected void MarkDirty()
	{
		mTransformDirty = true;
		mInverseDirty = true;
	}
}
