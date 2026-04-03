using System;

namespace Sedulous.Core.Mathematics;

/// <summary>
/// Represents a line proceeding from a point in space.
/// </summary>
struct Ray : IEquatable<Ray>, IInterpolatable<Ray>, IEquatable, IHashable
{
    /// <summary>
    /// Initializes a new instance of the <see cref="Ray"/> structure.
    /// </summary>
    /// <param name="position">The ray's position in space.</param>
    /// <param name="direction">The ray's direction vector.</param>
    public this(Vector3 position, Vector3 direction)
    {
        this.Position = position;
        this.Direction = direction;
    }

    /// <summary>
    /// Determines whether this <see cref="Ray"/> intersects a specified <see cref="Plane"/>.
    /// </summary>
    /// <param name="plane">The <see cref="Plane"/> to evaluate.</param>
    /// <returns>The distance along the ray at which it intersects the plane, or <see langword="null"/> if there is no intersection.</returns>
    public float? Intersects(Plane plane)
    {
        var normalDotDirection = plane.Normal.X * Direction.X + plane.Normal.Y * Direction.Y + plane.Normal.Z * Direction.Z;
        if (MathUtil.IsApproximatelyZero(normalDotDirection))
            return null;

        var normalDotPosition = plane.Normal.X * Position.X + plane.Normal.Y * Position.Y + plane.Normal.Z * Position.Z;
        var distance = -(normalDotPosition + plane.D) / normalDotDirection;
        if (MathUtil.IsApproximatelyZero(distance))
            return 0f;

        if (distance < 0)
            return null;

        return distance;
    }

    /// <summary>
    /// Determines whether this <see cref="Ray"/> intersects a specified <see cref="Plane"/>.
    /// </summary>
    /// <param name="plane">The <see cref="Plane"/> to evaluate.</param>
    /// <param name="result">The distance along the ray at which it intersects the plane, or <see langword="null"/> if there is no intersection.</param>
    public void Intersects(in Plane plane, out float? result)
    {
        var normalDotDirection = plane.Normal.X * Direction.X + plane.Normal.Y * Direction.Y + plane.Normal.Z * Direction.Z;
        if (MathUtil.IsApproximatelyZero(normalDotDirection))
        {
            result = null;
        }
        else
        {
            var normalDotPosition = plane.Normal.X * Position.X + plane.Normal.Y * Position.Y + plane.Normal.Z * Position.Z;
            var distance = -(normalDotPosition + plane.D) / normalDotDirection;
            if (MathUtil.IsApproximatelyZero(distance))
            {
                result = 0f;
            }
            else
            {
                if (distance < 0)
                {
                    result = null;
                }
                else
                {
                    result = distance;
                }
            }
        }
    }

    /// <summary>
    /// Determines whether this <see cref="Ray"/> intersects a specified <see cref="BoundingFrustum"/>.
    /// </summary>
    /// <param name="frustum">The <see cref="BoundingFrustum"/> to evaluate.</param>
    /// <returns>The distance along the ray at which it intersects the frustum, or <see langword="null"/> if there is no intersection.</returns>
    public float? Intersects(BoundingFrustum frustum)
    {
        frustum.Intersects(this, var result);
        return result;
    }

    /// <summary>
    /// Determines whether this <see cref="Ray"/> intersects a specified <see cref="BoundingFrustum"/>.
    /// </summary>
    /// <param name="frustum">The <see cref="BoundingFrustum"/> to evaluate.</param>
    /// <param name="result">The distance along the ray at which it intersects the frustum, or <see langword="null"/> if there is no intersection.</param>
    public void Intersects(in BoundingFrustum frustum, out float? result)
    {
        frustum.Intersects(this, out result);
    }

    /// <summary>
    /// Determines whether this <see cref="Ray"/> intersects a specified <see cref="BoundingSphere"/>.
    /// </summary>
    /// <param name="sphere">The <see cref="BoundingSphere"/> to evaluate.</param>
    /// <returns>The distance along the ray at which it intersects the sphere, or <see langword="null"/> if there is no intersection.</returns>
    public float? Intersects(BoundingSphere sphere)
    {
        Intersects(sphere, var result);
        return result;
    }

    /// <summary>
    /// Determines whether this <see cref="Ray"/> intersects a specified <see cref="BoundingSphere"/>.
    /// </summary>
    /// <param name="sphere">The <see cref="BoundingSphere"/> to evaluate.</param>
    /// <param name="result">The distance along the ray at which it intersects the sphere, or <see langword="null"/> if there is no intersection.</param>
    public void Intersects(BoundingSphere sphere, out float? result)
    {
        var radiusSquared = sphere.Radius * sphere.Radius;

        var offset = sphere.Center - Position;
        var offsetLengthSquared = offset.LengthSquared();
        if (offsetLengthSquared < radiusSquared)
        {
            result = 0.0f;
            return;
        }

        Vector3.Dot(Direction, offset, var distanceToCenter);
        if (distanceToCenter < 0)
        {
            result = null;
            return;
        }

        var distanceToCenterSquared = distanceToCenter * distanceToCenter;
        var distanceToSphere = radiusSquared + distanceToCenterSquared - offsetLengthSquared;

        result = (distanceToSphere < 0) ? null : distanceToCenter - (float?)Math.Sqrt(distanceToSphere);
    }

    /// <summary>
    /// Determines whether this <see cref="Ray"/> intersects a specified <see cref="BoundingBox"/>.
    /// </summary>
    /// <param name="box">The <see cref="BoundingBox"/> to evaluate.</param>
    /// <returns>The distance along the ray at which it intersects the sphere, or <see langword="null"/> if there is no intersection.</returns>
    public float? Intersects(BoundingBox @box)
    {
        Intersects(@box, var result);
        return result;
    }

    /// <summary>
    /// Determines whether this <see cref="Ray"/> intersects a specified <see cref="BoundingBox"/>.
    /// </summary>
    /// <param name="box">The <see cref="BoundingBox"/> to evaluate.</param>
    /// <param name="result">The distance along the ray at which it intersects the bounding box, or <see langword="null"/> if there is no intersection.</param>
    public void Intersects(in BoundingBox @box, out float? result)
    {
        var min = default(float?);
        var max = default(float?);

        if (MathUtil.IsApproximatelyZero(Direction.X))
        {
            if (Position.X < @box.Min.X || Position.X > @box.Max.X)
            {
                result = null;
                return;
            }
        }
        else
        {
            min = (@box.Min.X - Position.X) / Direction.X;
            max = (@box.Max.X - Position.X) / Direction.X;

            if (min > max)
            {
                var temp = min;
                min = max;
                max = temp;
            }
        }

        if (MathUtil.IsApproximatelyZero(Direction.Y))
        {
            if (Position.Y < @box.Min.Y || Position.Y > @box.Max.Y)
            {
                result = null;
                return;
            }
        }
        else
        {
            var minY = (@box.Min.Y - Position.Y) / Direction.Y;
            var maxY = (@box.Max.Y - Position.Y) / Direction.Y;

            if (minY > maxY)
            {
                var temp = minY;
                minY = maxY;
                maxY = temp;
            }

            if (min == null || minY > min)
                min = minY;

            if (max == null || maxY > max)
                max = maxY;
        }

        if (MathUtil.IsApproximatelyZero(Direction.Z))
        {
            if (Position.Z < @box.Min.Z || Position.Z > @box.Max.Z)
            {
                result = null;
                return;
            }
        }
        else
        {
            var minZ = (@box.Min.Z - Position.Z) / Direction.Z;
            var maxZ = (@box.Max.Z - Position.Z) / Direction.Z;

            if (minZ > maxZ)
            {
                var temp = minZ;
                minZ = maxZ;
                maxZ = temp;
            }

            if (min == null || minZ > min)
                min = minZ;

            if (max == null || maxZ > max)
                max = maxZ;
        }

        if (min != null && min < 0 && max > 0)
        {
            result = 0;
            return;
        }

        if (min < 0)
        {
            result = null;
            return;
        }

        result = min;
    }

    /// <inheritdoc/>
    public override void ToString(String str) => str.Append( scope $"{{Position:{Position} Direction:{Direction}}}");

    /// <inheritdoc/>
    public Ray Interpolate(Ray target, float t)
    {
        Ray result;

        result.Position = this.Position.Interpolate(target.Position, t);
        result.Direction = this.Direction.Interpolate(target.Direction, t);

        return result;
    }

    /// <summary>
    /// The ray's position in space.
    /// </summary>
    public Vector3 Position;

    /// <summary>
    /// The ray's direction vector.
    /// </summary>
    public Vector3 Direction;
}
