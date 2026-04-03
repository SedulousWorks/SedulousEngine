using System;
using Sedulous.Core;

namespace Sedulous.Core.Mathematics;

/// <summary>
/// Represents a 4x4 transformation matrix.
/// </summary>
/// <remarks>
/// This matrix uses the XNA/MonoGame convention:
/// - Storage is row-major in memory ([CRepr] compatible)
/// - Basis vectors (X, Y, Z axes) are stored in columns 1, 2, 3
/// - Translation is stored in row 4 (M41, M42, M43)
/// - Vector transformation uses row-vector convention: result = vector * matrix
///
/// Matrix layout:
///   M11 M12 M13 M14   (X components of basis + padding)
///   M21 M22 M23 M24   (Y components of basis + padding)
///   M31 M32 M33 M34   (Z components of basis + padding)
///   M41 M42 M43 M44   (Translation + 1)
///
/// For shaders:
/// - HLSL with row_major: use matrix directly
/// - HLSL with column_major: transpose before upload
/// - GLSL: transpose before upload (GLSL is column-major)
///
/// For frustum plane extraction, use column-based Gribb/Hartmann method.
/// </remarks>
[CRepr]
struct Matrix : IEquatable<Matrix>, IInterpolatable<Matrix>, IEquatable, IHashable
{
    /// <summary>
    /// Initializes a new instance of the <see cref="Matrix"/> structure.
    /// </summary>
    /// <param name="M11">The value at row 1, column 1 of the matrix.</param>
    /// <param name="M12">The value at row 1, column 2 of the matrix.</param>
    /// <param name="M13">The value at row 1, column 3 of the matrix.</param>
    /// <param name="M14">The value at row 1, column 4 of the matrix.</param>
    /// <param name="M21">The value at row 2, column 1 of the matrix.</param>
    /// <param name="M22">The value at row 2, column 2 of the matrix.</param>
    /// <param name="M23">The value at row 2, column 3 of the matrix.</param>
    /// <param name="M24">The value at row 2, column 4 of the matrix.</param>
    /// <param name="M31">The value at row 3, column 1 of the matrix.</param>
    /// <param name="M32">The value at row 3, column 2 of the matrix.</param>
    /// <param name="M33">The value at row 3, column 3 of the matrix.</param>
    /// <param name="M34">The value at row 3, column 4 of the matrix.</param>
    /// <param name="M41">The value at row 4, column 1 of the matrix.</param>
    /// <param name="M42">The value at row 4, column 2 of the matrix.</param>
    /// <param name="M43">The value at row 4, column 3 of the matrix.</param>
    /// <param name="M44">The value at row 4, column 4 of the matrix.</param>
    public this(
        float M11, float M12, float M13, float M14,
        float M21, float M22, float M23, float M24,
        float M31, float M32, float M33, float M34,
        float M41, float M42, float M43, float M44)
    {
        this.M11 = M11;
        this.M12 = M12;
        this.M13 = M13;
        this.M14 = M14;

        this.M21 = M21;
        this.M22 = M22;
        this.M23 = M23;
        this.M24 = M24;

        this.M31 = M31;
        this.M32 = M32;
        this.M33 = M33;
        this.M34 = M34;

        this.M41 = M41;
        this.M42 = M42;
        this.M43 = M43;
        this.M44 = M44;
    }
    
    /// <summary>
    /// Implicitly converts an instance of the <see cref="System.Numerics.Matrix4x4"/> structure
    /// to an instance of the <see cref="Matrix"/> structure.
    /// </summary>
    /// <param name="value">The value to convert.</param>
    /*public static implicit operator Matrix(System.Numerics.Matrix4x4 value)
    {
        var x = (Matrix*)&value;
        return *x;
    }*/

    /// <summary>
    /// Implicitly converts an instance of the <see cref="Matrix"/> structure
    /// to an instance of the <see cref="System.Numerics.Matrix4x4"/> structure.
    /// </summary>
    /// <param name="value">The value to convert.</param>
    /*public static implicit operator System.Numerics.Matrix4x4(Matrix value)
    {
        var x = (System.Numerics.Matrix4x4*)&value;
        return *x;
    }*/

    /// <summary>
    /// Multiplies a <see cref="Matrix"/> by a scaling factor.
    /// </summary>
    /// <param name="multiplier">The multiplier.</param>
    /// <param name="multiplicand">The multiplicand.</param>
    /// <returns>The resulting <see cref="Matrix"/>.</returns>
    public static Matrix operator *(float multiplier, Matrix multiplicand)
    {
        Matrix result;
        Multiply(multiplicand, multiplier, out result);
        return result;
    }

    /// <summary>
    /// Multiplies a <see cref="Matrix"/> by a scaling factor.
    /// </summary>
    /// <param name="multiplicand">The multiplicand.</param>
    /// <param name="multiplier">The multiplier.</param>
    /// <returns>The resulting <see cref="Matrix"/>.</returns>
    public static Matrix operator *(Matrix multiplicand, float multiplier)
    {
        Matrix result;
        Multiply(multiplicand, multiplier, out result);
        return result;
    }

    /// <summary>
    /// Multiplies a <see cref="Matrix"/> by another matrix.
    /// </summary>
    /// <param name="multiplicand">The multiplicand.</param>
    /// <param name="multiplier">The multiplier.</param>
    /// <returns>The resulting <see cref="Matrix"/>.</returns>
    public static Matrix operator *(Matrix multiplicand, Matrix multiplier)
    {
        Matrix result;
        Multiply(multiplicand, multiplier, out result);
        return result;
    }

    /// <summary>
    /// Divides a <see cref="Matrix"/> by a scaling factor.
    /// </summary>
    /// <param name="dividend">The dividend.</param>
    /// <param name="divisor">The divisor.</param>
    /// <returns>The resulting <see cref="Matrix"/>.</returns>
    public static Matrix operator /(Matrix dividend, float divisor)
    {
        Matrix result;
        Divide(dividend, divisor, out result);
        return result;
    }

    /// <summary>
    /// Divides a <see cref="Matrix"/> by a another matrix.
    /// </summary>
    /// <param name="dividend">The dividend.</param>
    /// <param name="divisor">The divisor.</param>
    /// <returns>The resulting <see cref="Matrix"/>.</returns>
    public static Matrix operator /(Matrix dividend, Matrix divisor)
    {
        Matrix result;
        Divide(dividend, divisor, out result);
        return result;
    }

    /// <summary>
    /// Adds a <see cref="Matrix"/> to another matrix.
    /// </summary>
    /// <param name="addend1">The <see cref="Matrix"/> on the left side of the addition operator.</param>
    /// <param name="addend2">The <see cref="Matrix"/> on the right side of the addition operator.</param>
    /// <returns>The resulting <see cref="Matrix"/>.</returns>
    public static Matrix operator +(Matrix addend1, Matrix addend2)
    {
        Matrix result;
        Add(addend1, addend2, out result);
        return result;
    }

    /// <summary>
    /// Subtracts a <see cref="Matrix"/> from another matrix.
    /// </summary>
    /// <param name="minuend">The <see cref="Matrix"/> on the left side of the subtraction operator.</param>
    /// <param name="subtrahend">The <see cref="Matrix"/> on the right side of the subtraction operator.</param>
    /// <returns>The resulting <see cref="Matrix"/>.</returns>
    public static Matrix operator -(Matrix minuend, Matrix subtrahend)
    {
        Matrix result;
        Subtract(minuend, subtrahend, out result);
        return result;
    }

    /// <summary>
    /// Negates the specified elements of the specified <see cref="Matrix"/>.
    /// </summary>
    /// <param name="matrix">The <see cref="Matrix"/> to negate.</param>
    /// <returns>The negated <see cref="Matrix"/>.</returns>
    public static Matrix operator -(Matrix matrix)
    {
        Matrix result;
        Negate(matrix, out result);
        return result;
    }
    
    /// <summary>
    /// Creates a world matrix with the specified parameters.
    /// </summary>
    /// <param name="position">The object's position.</param>
    /// <param name="forward">The object's forward vector.</param>
    /// <param name="up">The object's up vector.</param>
    /// <returns>The <see cref="Matrix"/> that was created.</returns>
    public static Matrix CreateWorld(Vector3 position, Vector3 forward, Vector3 up)
    {
        var normalizedBackward = Vector3.Normalize(-forward);
        var normalizedRight = Vector3.Normalize(Vector3.Cross(up, normalizedBackward));
        var normalizedUp = Vector3.Cross(normalizedBackward, normalizedRight);

        Matrix result;

        result.M11 = normalizedRight.X;
        result.M12 = normalizedRight.Y;
        result.M13 = normalizedRight.Z;
        result.M14 = 0f;

        result.M21 = normalizedUp.X;
        result.M22 = normalizedUp.Y;
        result.M23 = normalizedUp.Z;
        result.M24 = 0f;

        result.M31 = normalizedBackward.X;
        result.M32 = normalizedBackward.Y;
        result.M33 = normalizedBackward.Z;
        result.M34 = 0f;

        result.M41 = position.X;
        result.M42 = position.Y;
        result.M43 = position.Z;
        result.M44 = 1f;

        return result;
    }

    /// <summary>
	/// Creates a world matrix with the specified parameters.
	/// </summary>
	/// <param name="position">The object's position.</param>
	/// <param name="forward">The object's forward vector.</param>
	/// <param name="up">The object's up vector.</param>
	/// <param name="result">The <see cref="Matrix"/> that was created.</param>
	public static void CreateWorld(in Vector3 position, in Vector3 forward, in Vector3 up, out Matrix result)
	{
	    var normalizedBackward = Vector3.Normalize(-forward);
	    var normalizedRight = Vector3.Normalize(Vector3.Cross(up, normalizedBackward));
	    var normalizedUp = Vector3.Cross(normalizedBackward, normalizedRight);

	    result.M11 = normalizedRight.X;
	    result.M12 = normalizedRight.Y;
	    result.M13 = normalizedRight.Z;
	    result.M14 = 0f;

	    result.M21 = normalizedUp.X;
	    result.M22 = normalizedUp.Y;
	    result.M23 = normalizedUp.Z;
	    result.M24 = 0f;

	    result.M31 = normalizedBackward.X;
	    result.M32 = normalizedBackward.Y;
	    result.M33 = normalizedBackward.Z;
	    result.M34 = 0f;

	    result.M41 = position.X;
	    result.M42 = position.Y;
	    result.M43 = position.Z;
	    result.M44 = 1f;            
	}

	/// <summary>
	/// Creates a view matrix.
	/// </summary>
	/// <param name="cameraPosition">The camera's position.</param>
	/// <param name="cameraTarget">The camera's target.</param>
	/// <param name="cameraUp">The camera's up vector.</param>
	/// <returns>The view <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateLookAt(Vector3 cameraPosition, Vector3 cameraTarget, Vector3 cameraUp)
	{
	    var zAxis = Vector3.Normalize(cameraPosition - cameraTarget);
	    var xAxis = Vector3.Normalize(Vector3.Cross(cameraUp, zAxis));
	    var yAxis = Vector3.Cross(zAxis, xAxis);

	    Matrix result;

	    result.M11 = xAxis.X;
	    result.M12 = yAxis.X;
	    result.M13 = zAxis.X;
	    result.M14 = 0f;

	    result.M21 = xAxis.Y;
	    result.M22 = yAxis.Y;
	    result.M23 = zAxis.Y;
	    result.M24 = 0f;

	    result.M31 = xAxis.Z;
	    result.M32 = yAxis.Z;
	    result.M33 = zAxis.Z;
	    result.M34 = 0f;

	    result.M41 = -Vector3.Dot(xAxis, cameraPosition);
	    result.M42 = -Vector3.Dot(yAxis, cameraPosition);
	    result.M43 = -Vector3.Dot(zAxis, cameraPosition);
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a view matrix.
	/// </summary>
	/// <param name="cameraPosition">The camera's position.</param>
	/// <param name="cameraTarget">The camera's target.</param>
	/// <param name="cameraUp">The camera's up vector.</param>
	/// <param name="result">The view <see cref="Matrix"/> that was created.</param>
	public static void CreateLookAt(in Vector3 cameraPosition, in Vector3 cameraTarget, in Vector3 cameraUp, out Matrix result)
	{
	    var zAxis = Vector3.Normalize(cameraPosition - cameraTarget);
	    var xAxis = Vector3.Normalize(Vector3.Cross(cameraUp, zAxis));
	    var yAxis = Vector3.Cross(zAxis, xAxis);

	    result.M11 = xAxis.X;
	    result.M12 = yAxis.X;
	    result.M13 = zAxis.X;
	    result.M14 = 0f;

	    result.M21 = xAxis.Y;
	    result.M22 = yAxis.Y;
	    result.M23 = zAxis.Y;
	    result.M24 = 0f;

	    result.M31 = xAxis.Z;
	    result.M32 = yAxis.Z;
	    result.M33 = zAxis.Z;
	    result.M34 = 0f;

	    result.M41 = -Vector3.Dot(xAxis, cameraPosition);
	    result.M42 = -Vector3.Dot(yAxis, cameraPosition);
	    result.M43 = -Vector3.Dot(zAxis, cameraPosition);
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates an orthographic projection matrix.
	/// </summary>
	/// <param name="width">The width of the view volume.</param>
	/// <param name="height">The height of the view volume.</param>
	/// <param name="zNearPlane">The distance from the camera to the near z-plane.</param>
	/// <param name="zFarPlane">The distance from the camera to the far z-plane.</param>
	/// <returns>The projection <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateOrthographic(float width, float height, float zNearPlane, float zFarPlane)
	{
	    Matrix result;

	    result.M11 = 2.0f / width;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 2.0f / height;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1.0f / (zNearPlane - zFarPlane);
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = zNearPlane / (zNearPlane - zFarPlane);
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates an orthographic projection matrix.
	/// </summary>
	/// <param name="width">The width of the view volume.</param>
	/// <param name="height">The height of the view volume.</param>
	/// <param name="zNearPlane">The distance from the camera to the near z-plane.</param>
	/// <param name="zFarPlane">The distance from the camera to the far z-plane.</param>
	/// <param name="result">The projection <see cref="Matrix"/> that was created.</param>
	public static void CreateOrthographic(float width, float height, float zNearPlane, float zFarPlane, out Matrix result)
	{
	    result.M11 = 2.0f / width;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 2.0f / height;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1.0f / (zNearPlane - zFarPlane);
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = zNearPlane / (zNearPlane - zFarPlane);
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates an off-center orthographic projection matrix.
	/// </summary>
	/// <param name="left">The minimum x-value of the view volume.</param>
	/// <param name="right">The maximum x-value of the view volume.</param>
	/// <param name="bottom">The minimum y-value of the view volume.</param>
	/// <param name="top">The maximum y-value of the view volume.</param>
	/// <param name="zNearPlane">The distance from the camera to the near z-plane.</param>
	/// <param name="zFarPlane">The distance from the camera to the far z-plane.</param>
	/// <returns>The projection <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateOrthographicOffCenter(float left, float right, float bottom, float top, float zNearPlane, float zFarPlane)
	{
	    Matrix result;

	    result.M11 = 2.0f / (right - left);
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 2.0f / (top - bottom);
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1.0f / (zNearPlane - zFarPlane);
	    result.M34 = 0f;

	    result.M41 = (left + right) / (left - right);
	    result.M42 = (top + bottom) / (bottom - top);
	    result.M43 = zNearPlane / (zNearPlane - zFarPlane);
	    result.M44 = 1.0f;

	    return result;
	}

	/// <summary>
	/// Creates an off-center orthographic projection matrix.
	/// </summary>
	/// <param name="left">The minimum x-value of the view volume.</param>
	/// <param name="right">The maximum x-value of the view volume.</param>
	/// <param name="bottom">The minimum y-value of the view volume.</param>
	/// <param name="top">The maximum y-value of the view volume.</param>
	/// <param name="zNearPlane">The distance from the camera to the near z-plane.</param>
	/// <param name="zFarPlane">The distance from the camera to the far z-plane.</param>
	/// <param name="result">The projection <see cref="Matrix"/> that was created.</param>
	public static void CreateOrthographicOffCenter(float left, float right, float bottom, float top, float zNearPlane, float zFarPlane, out Matrix result)
	{
	    result.M11 = 2.0f / (right - left);
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 2.0f / (top - bottom);
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1.0f / (zNearPlane - zFarPlane);
	    result.M34 = 0f;

	    result.M41 = (left + right) / (left - right);
	    result.M42 = (top + bottom) / (bottom - top);
	    result.M43 = zNearPlane / (zNearPlane - zFarPlane);
	    result.M44 = 1.0f;
	}

	/// <summary>
	/// Creates a perspective matrix.
	/// </summary>
	/// <param name="width">The width of the view volume at the near plane.</param>
	/// <param name="height">The height of the view volume at the near plane.</param>
	/// <param name="nearPlaneDistance">The distance to the near view plane.</param>
	/// <param name="farPlaneDistance">The distance to the far view plane.</param>
	/// <returns>The <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreatePerspective(float width, float height, float nearPlaneDistance, float farPlaneDistance)
	{
	    Contract.EnsureRange(nearPlaneDistance > 0, nameof(nearPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > 0, nameof(farPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > nearPlaneDistance, nameof(nearPlaneDistance));

	    var negFarRange = float.IsPositiveInfinity(farPlaneDistance) ? -1f : farPlaneDistance / (nearPlaneDistance - farPlaneDistance);

	    Matrix result;

	    result.M11 = 2.0f * nearPlaneDistance / width;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 2.0f * nearPlaneDistance / height;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = negFarRange;
	    result.M34 = -1f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = nearPlaneDistance * negFarRange;
	    result.M44 = 0f;

	    return result;
	}

	/// <summary>
	/// Creates a perspective matrix.
	/// </summary>
	/// <param name="width">The width of the view volume at the near plane.</param>
	/// <param name="height">The height of the view volume at the near plane.</param>
	/// <param name="nearPlaneDistance">The distance to the near view plane.</param>
	/// <param name="farPlaneDistance">The distance to the far view plane.</param>
	/// <param name="result">The <see cref="Matrix"/> that was created.</param>
	public static void CreatePerspective(float width, float height, float nearPlaneDistance, float farPlaneDistance, out Matrix result)
	{
	    Contract.EnsureRange(nearPlaneDistance > 0, nameof(nearPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > 0, nameof(farPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > nearPlaneDistance, nameof(nearPlaneDistance));

	    var negFarRange = float.IsPositiveInfinity(farPlaneDistance) ? -1f : farPlaneDistance / (nearPlaneDistance - farPlaneDistance);

	    result.M11 = 2.0f * nearPlaneDistance / width;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 2.0f * nearPlaneDistance / height;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = negFarRange;
	    result.M34 = -1f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = nearPlaneDistance * negFarRange;
	    result.M44 = 0f;
	}

	/// <summary>
	/// Creates a perspective matrix based on a field of view.
	/// </summary>
	/// <param name="fieldOfView">The field of view in radians.</param>
	/// <param name="aspectRatio">The aspect ratio of the view.</param>
	/// <param name="nearPlaneDistance">The distance to the near view plane.</param>
	/// <param name="farPlaneDistance">The distance to the far view plane.</param>
	/// <returns>The <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreatePerspectiveFieldOfView(float fieldOfView, float aspectRatio, float nearPlaneDistance, float farPlaneDistance)
	{
	    Contract.EnsureRange(fieldOfView > 0 && fieldOfView < Math.PI_f, nameof(fieldOfView));
	    Contract.EnsureRange(nearPlaneDistance > 0, nameof(nearPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > 0, nameof(farPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > nearPlaneDistance, nameof(nearPlaneDistance));

	    var yScale = 1f / (float)Math.Tan(fieldOfView * 0.5f);
	    var xScale = yScale / aspectRatio;
	    var negFarRange = float.IsPositiveInfinity(farPlaneDistance) ? -1f : farPlaneDistance / (nearPlaneDistance - farPlaneDistance);

	    Matrix result;

	    result.M11 = xScale;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = yScale;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = negFarRange;
	    result.M34 = -1f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = nearPlaneDistance * negFarRange;
	    result.M44 = 0f;

	    return result;            
	}

	/// <summary>
	/// Creates a perspective matrix based on a field of view.
	/// </summary>
	/// <param name="fieldOfView">The field of view in radians.</param>
	/// <param name="aspectRatio">The aspect ratio of the view.</param>
	/// <param name="nearPlaneDistance">The distance to the near view plane.</param>
	/// <param name="farPlaneDistance">The distance to the far view plane.</param>
	/// <param name="result">The <see cref="Matrix"/> that was created.</param>
	public static void CreatePerspectiveFieldOfView(float fieldOfView, float aspectRatio, float nearPlaneDistance, float farPlaneDistance, out Matrix result)
	{
	    Contract.EnsureRange(fieldOfView > 0 && fieldOfView < Math.PI_f, nameof(fieldOfView));
	    Contract.EnsureRange(nearPlaneDistance > 0, nameof(nearPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > 0, nameof(farPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > nearPlaneDistance, nameof(nearPlaneDistance));

	    var yScale = 1f / (float)Math.Tan(fieldOfView * 0.5f);
	    var xScale = yScale / aspectRatio;
	    var negFarRange = float.IsPositiveInfinity(farPlaneDistance) ? -1f : farPlaneDistance / (nearPlaneDistance - farPlaneDistance);

	    result.M11 = xScale;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = yScale;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = negFarRange;
	    result.M34 = -1f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = nearPlaneDistance * negFarRange;
	    result.M44 = 0f;
	}

	/// <summary>
	/// Creates a customized perspective matrix.
	/// </summary>
	/// <param name="left">The minimum x-value of the view volume at the near view plane.</param>
	/// <param name="right">The maximum x-value of the view volume at the near view plane.</param>
	/// <param name="bottom">The minimum y-value of the view volume at the near view plane.</param>
	/// <param name="top">The maximum y-value of the view volume at the near view plane.</param>
	/// <param name="nearPlaneDistance">The distance to the near view plane.</param>
	/// <param name="farPlaneDistance">The distance to the far view plane.</param>
	/// <returns>The <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreatePerspectiveOffCenter(float left, float right, float bottom, float top, float nearPlaneDistance, float farPlaneDistance)
	{
	    Contract.EnsureRange(nearPlaneDistance > 0, nameof(nearPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > 0, nameof(farPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > nearPlaneDistance, nameof(nearPlaneDistance));

	    var negFarRange = float.IsPositiveInfinity(farPlaneDistance) ? -1f : farPlaneDistance / (nearPlaneDistance - farPlaneDistance);

	    Matrix result;

	    result.M11 = 2.0f * nearPlaneDistance / (right - left);
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 2.0f * nearPlaneDistance / (top - bottom);
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = (left + right) / (right - left);
	    result.M32 = (top + bottom) / (top - bottom);
	    result.M33 = negFarRange;
	    result.M34 = -1f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = nearPlaneDistance * negFarRange;
	    result.M44 = 0f;

	    return result;
	}

	/// <summary>
	/// Creates a customized perspective matrix.
	/// </summary>
	/// <param name="left">The minimum x-value of the view volume at the near view plane.</param>
	/// <param name="right">The maximum x-value of the view volume at the near view plane.</param>
	/// <param name="bottom">The minimum y-value of the view volume at the near view plane.</param>
	/// <param name="top">The maximum y-value of the view volume at the near view plane.</param>
	/// <param name="nearPlaneDistance">The distance to the near view plane.</param>
	/// <param name="farPlaneDistance">The distance to the far view plane.</param>
	/// <param name="result">The <see cref="Matrix"/> that was created.</param>
	public static void CreatePerspectiveOffCenter(float left, float right, float bottom, float top, float nearPlaneDistance, float farPlaneDistance, out Matrix result)
	{
	    Contract.EnsureRange(nearPlaneDistance > 0, nameof(nearPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > 0, nameof(farPlaneDistance));
	    Contract.EnsureRange(farPlaneDistance > nearPlaneDistance, nameof(nearPlaneDistance));

	    var negFarRange = float.IsPositiveInfinity(farPlaneDistance) ? -1f : farPlaneDistance / (nearPlaneDistance - farPlaneDistance);

	    result.M11 = 2.0f * nearPlaneDistance / (right - left);
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 2.0f * nearPlaneDistance / (top - bottom);
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = (left + right) / (right - left);
	    result.M32 = (top + bottom) / (top - bottom);
	    result.M33 = negFarRange;
	    result.M34 = -1f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = nearPlaneDistance * negFarRange;
	    result.M44 = 0f;
	}

	/// <summary>
	/// Creates a translation matrix.
	/// </summary>
	/// <param name="x">The amount to translate along the x-axis.</param>
	/// <param name="y">The amount to translate along the y-axis.</param>
	/// <param name="z">The amount to translate along the z-axis.</param>
	/// <returns>The translation <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateTranslation(float x, float y, float z)
	{
	    Matrix result;

	    result.M11 = 1f;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 1f;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1f;
	    result.M34 = 0f;

	    result.M41 = x;
	    result.M42 = y;
	    result.M43 = z;
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a translation matrix.
	/// </summary>
	/// <param name="x">The amount to translate along the x-axis.</param>
	/// <param name="y">The amount to translate along the y-axis.</param>
	/// <param name="z">The amount to translate along the z-axis.</param>
	/// <param name="result">The translation <see cref="Matrix"/> that was created.</param>
	public static void CreateTranslation(float x, float y, float z, out Matrix result)
	{
	    result.M11 = 1f;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 1f;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1f;
	    result.M34 = 0f;

	    result.M41 = x;
	    result.M42 = y;
	    result.M43 = z;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates a translation matrix.
	/// </summary>
	/// <param name="position">A vector describing the amount to translate along each axis.</param>
	/// <returns>The translation <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateTranslation(Vector3 position)
	{
	    Matrix result;
	    
	    result.M11 = 1f;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 1f;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1f;
	    result.M34 = 0f;

	    result.M41 = position.X;
	    result.M42 = position.Y;
	    result.M43 = position.Z;
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a translation matrix.
	/// </summary>
	/// <param name="position">A vector describing the amount to translate along each axis.</param>
	/// <param name="result">The translation <see cref="Matrix"/> that was created.</param>
	public static void CreateTranslation(in Vector3 position, out Matrix result)
	{
	    result.M11 = 1f;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 1f;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1f;
	    result.M34 = 0f;

	    result.M41 = position.X;
	    result.M42 = position.Y;
	    result.M43 = position.Z;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates a matrix that represents a rotation over the x-axis.
	/// </summary>
	/// <param name="radians">The number of radians to rotate.</param>
	/// <returns>The rotation <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateRotationX(float radians)
	{
	    var cos = (float)Math.Cos(radians);
	    var sin = (float)Math.Sin(radians);

	    Matrix result;

	    result.M11 = 1f;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = cos;
	    result.M23 = sin;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = -sin;
	    result.M33 = cos;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a matrix that represents a rotation over the x-axis.
	/// </summary>
	/// <param name="radians">The number of radians to rotate.</param>
	/// <param name="result">The rotation <see cref="Matrix"/> that was created.</param>
	public static void CreateRotationX(float radians, out Matrix result)
	{
	    var cos = (float)Math.Cos(radians);
	    var sin = (float)Math.Sin(radians);
	    
	    result.M11 = 1f;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = cos;
	    result.M23 = sin;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = -sin;
	    result.M33 = cos;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates a matrix that represents a rotation over the y-axis.
	/// </summary>
	/// <param name="radians">The number of radians to rotate.</param>
	/// <returns>The rotation <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateRotationY(float radians)
	{
	    var cos = (float)Math.Cos(radians);
	    var sin = (float)Math.Sin(radians);

	    Matrix result;

	    result.M11 = cos;
	    result.M12 = 0f;
	    result.M13 = -sin;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 1f;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = sin;
	    result.M32 = 0f;
	    result.M33 = cos;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a matrix that represents a rotation over the y-axis.
	/// </summary>
	/// <param name="radians">The number of radians to rotate.</param>
	/// <param name="result">The rotation <see cref="Matrix"/> that was created.</param>
	public static void CreateRotationY(float radians, out Matrix result)
	{
	    var cos = (float)Math.Cos(radians);
	    var sin = (float)Math.Sin(radians);

	    result.M11 = cos;
	    result.M12 = 0f;
	    result.M13 = -sin;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = 1f;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = sin;
	    result.M32 = 0f;
	    result.M33 = cos;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates a matrix that represents a rotation over the z-axis.
	/// </summary>
	/// <param name="radians">The number of radians to rotate.</param>
	/// <returns>The rotation <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateRotationZ(float radians)
	{
	    var cos = (float)Math.Cos(radians);
	    var sin = (float)Math.Sin(radians);

	    Matrix result;

	    result.M11 = cos;
	    result.M12 = sin;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = -sin;
	    result.M22 = cos;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1f;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a matrix that represents a rotation over the z-axis.
	/// </summary>
	/// <param name="radians">The number of radians to rotate.</param>
	/// <param name="result">The rotation <see cref="Matrix"/> that was created.</param>
	public static void CreateRotationZ(float radians, out Matrix result)
	{
	    var cos = (float)Math.Cos(radians);
	    var sin = (float)Math.Sin(radians);
	    
	    result.M11 = cos;
	    result.M12 = sin;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = -sin;
	    result.M22 = cos;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = 1f;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates a matrix that represents a rotation around the specified axis.
	/// </summary>
	/// <param name="axis">The axis around which to rotate.</param>
	/// <param name="angle">The angle to rotate, specified in radians.</param>
	/// <returns>The <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateFromAxisAngle(Vector3 axis, float angle)
	{
	    var c = Math.Cos(angle);
	    var s = Math.Sin(angle);
	    var C = 1 - c;

	    var xx = axis.X * axis.X;
	    var xy = axis.X * axis.Y;
	    var xz = axis.X * axis.Z;
	    var yy = axis.Y * axis.Y;
	    var yz = axis.Y * axis.Z;
	    var zz = axis.Z * axis.Z;

	    Matrix result;

	    result.M11 = (float)(xx * C + c);
	    result.M12 = (float)(xy * C + (axis.Z * s));
	    result.M13 = (float)(xz * C - (axis.Y * s));
	    result.M14 = 0f;

	    result.M21 = (float)(xy * C - (axis.Z * s));
	    result.M22 = (float)(yy * C + c);
	    result.M23 = (float)(yz * C + (axis.X * s));
	    result.M24 = 0f;

	    result.M31 = (float)(xz * C + (axis.Y * s));
	    result.M32 = (float)(yz * C + (axis.X * s));
	    result.M33 = (float)(zz * C + c);
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a matrix that represents a rotation around the specified axis.
	/// </summary>
	/// <param name="axis">The axis around which to rotate.</param>
	/// <param name="angle">The angle to rotate, specified in radians.</param>
	/// <param name="result">The <see cref="Matrix"/> that was created.</param>
	public static void CreateFromAxisAngle(in Vector3 axis, float angle, out Matrix result)
	{
	    var c = Math.Cos(angle);
	    var s = Math.Sin(angle);
	    var C = 1 - c;

	    var xx = axis.X * axis.X;
	    var xy = axis.X * axis.Y;
	    var xz = axis.X * axis.Z;
	    var yy = axis.Y * axis.Y;
	    var yz = axis.Y * axis.Z;
	    var zz = axis.Z * axis.Z;

	    result.M11 = (float)(xx * C + c);
	    result.M12 = (float)(xy * C + (axis.Z * s));
	    result.M13 = (float)(xz * C - (axis.Y * s));
	    result.M14 = 0f;

	    result.M21 = (float)(xy * C - (axis.Z * s));
	    result.M22 = (float)(yy * C + c);
	    result.M23 = (float)(yz * C + (axis.X * s));
	    result.M24 = 0f;

	    result.M31 = (float)(xz * C + (axis.Y * s));
	    result.M32 = (float)(yz * C + (axis.X * s));
	    result.M33 = (float)(zz * C + c);
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates a scaling matrix.
	/// </summary>
	/// <param name="scale">The scaling factor.</param>
	/// <returns>The scaling <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateScale(float scale)
	{
	    Matrix result;

	    result.M11 = scale;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = scale;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = scale;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a scaling matrix.
	/// </summary>
	/// <param name="scale">The scaling factor.</param>
	/// <param name="result">The scaling <see cref="Matrix"/> that was created.</param>
	public static void CreateScale(float scale, out Matrix result)
	{
	    result.M11 = scale;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = scale;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = scale;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates a scaling matrix.
	/// </summary>
	/// <param name="scaleX">The scaling factor along the x-axis.</param>
	/// <param name="scaleY">The scaling factor along the y-axis.</param>
	/// <param name="scaleZ">The scaling factor along the z-axis.</param>
	/// <returns>The scaling <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateScale(float scaleX, float scaleY, float scaleZ)
	{
	    Matrix result;

	    result.M11 = scaleX;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = scaleY;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = scaleZ;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a scaling matrix.
	/// </summary>
	/// <param name="scaleX">The scaling factor along the x-axis.</param>
	/// <param name="scaleY">The scaling factor along the y-axis.</param>
	/// <param name="scaleZ">The scaling factor along the z-axis.</param>
	/// <param name="result">The scaling <see cref="Matrix"/> that was created.</param>
	public static void CreateScale(float scaleX, float scaleY, float scaleZ, out Matrix result)
	{
	    result.M11 = scaleX;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = scaleY;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = scaleZ;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates a scaling matrix.
	/// </summary>
	/// <param name="scale">A vector describing the scaling factor along each axis.</param>
	/// <returns>The scaling <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateScale(Vector3 scale)
	{
	    Matrix result;

	    result.M11 = scale.X;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = scale.Y;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = scale.Z;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;

	    return result;
	}

	/// <summary>
	/// Creates a scaling matrix.
	/// </summary>
	/// <param name="scale">A vector describing the scaling factor along each axis.</param>
	/// <param name="result">The scaling <see cref="Matrix"/> that was created.</param>
	public static void CreateScale(in Vector3 scale, out Matrix result)
	{
	    result.M11 = scale.X;
	    result.M12 = 0f;
	    result.M13 = 0f;
	    result.M14 = 0f;

	    result.M21 = 0f;
	    result.M22 = scale.Y;
	    result.M23 = 0f;
	    result.M24 = 0f;

	    result.M31 = 0f;
	    result.M32 = 0f;
	    result.M33 = scale.Z;
	    result.M34 = 0f;

	    result.M41 = 0f;
	    result.M42 = 0f;
	    result.M43 = 0f;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Creates a rotation matrix from the specified quaternion.
	/// </summary>
	/// <param name="quaternion">A quaternion describing the rotation.</param>
	/// <returns>The rotation <see cref="Matrix"/> that was created.</returns>
	public static Matrix CreateFromQuaternion(Quaternion quaternion)
	{
	    Matrix result;
	    CreateFromQuaternion(quaternion, out result);
	    return result;
	}

	/// <summary>
	/// Creates a rotation matrix from the specified quaternion.
	/// </summary>
	/// <param name="quaternion">A quaternion describing the rotation.</param>
	/// <param name="result">The rotation <see cref="Matrix"/> that was created.</param>
	public static void CreateFromQuaternion(in Quaternion quaternion, out Matrix result)
	{
	    var xx = quaternion.X * quaternion.X;
	    var yy = quaternion.Y * quaternion.Y;
	    var zz = quaternion.Z * quaternion.Z;

	    var xy = quaternion.X * quaternion.Y;
	    var wz = quaternion.Z * quaternion.W;
	    var xz = quaternion.Z * quaternion.X;
	    var wy = quaternion.Y * quaternion.W;
	    var yz = quaternion.Y * quaternion.Z;
	    var wx = quaternion.X * quaternion.W;

	    result.M11 = 1.0f - 2.0f * (yy + zz);
	    result.M12 = 2.0f * (xy + wz);
	    result.M13 = 2.0f * (xz - wy);
	    result.M14 = 0.0f;
	    result.M21 = 2.0f * (xy - wz);
	    result.M22 = 1.0f - 2.0f * (zz + xx);
	    result.M23 = 2.0f * (yz + wx);
	    result.M24 = 0.0f;
	    result.M31 = 2.0f * (xz + wy);
	    result.M32 = 2.0f * (yz - wx);
	    result.M33 = 1.0f - 2.0f * (yy + xx);
	    result.M34 = 0.0f;
	    result.M41 = 0.0f;
	    result.M42 = 0.0f;
	    result.M43 = 0.0f;
	    result.M44 = 1.0f;
	}

	/// <summary>
	/// Creates a new rotation matrix from the specified yaw, pitch, and roll values.
	/// </summary>
	/// <param name="yaw">The yaw rotation value in radians.</param>
	/// <param name="pitch">The pitch rotation value in radians.</param>
	/// <param name="roll">The roll rotation value in radians.</param>
	/// <returns>The rotation <see cref="Matrix"/> which was created.</returns>
	public static Matrix CreateFromYawPitchRoll(float yaw, float pitch, float roll)
	{
	    Matrix result;
	    CreateFromYawPitchRoll(yaw, pitch, roll, out result);
	    return result;
	}

	/// <summary>
	/// Creates a new rotation matrix from the specified yaw, pitch, and roll values.
	/// </summary>
	/// <param name="yaw">The yaw rotation value in radians.</param>
	/// <param name="pitch">The pitch rotation value in radians.</param>
	/// <param name="roll">The roll rotation value in radians.</param>
	/// <param name="result">The rotation <see cref="Matrix"/> which was created.</param>
	public static void CreateFromYawPitchRoll(float yaw, float pitch, float roll, out Matrix result)
	{
	    Quaternion.CreateFromYawPitchRoll(yaw, pitch, roll, var quaternion);
	    CreateFromQuaternion(quaternion, out result);
	}

	/// <summary>
	/// Creates a new transformation matrix from the specified translation, rotation, and scaling values.
	/// </summary>
	/// <param name="translation">A vector representing the translation.</param>
	/// <param name="rotation">A quaternion representing the rotation.</param>
	/// <param name="scale">A vector representing the scaling factor.</param>
	/// <returns>The transformation <see cref="Matrix"/> which was created.</returns>
	public static Matrix CreateFromTranslationRotationScale(Vector3 translation, Quaternion rotation, Vector3 scale)
	{
	    Matrix result;
	    CreateFromTranslationRotationScale(translation, rotation, scale, out result);
	    return result;
	}

	/// <summary>
	/// Creates a new transformation matrix from the specified translation, rotation, and scaling values.
	/// </summary>
	/// <param name="translation">A vector representing the translation.</param>
	/// <param name="rotation">A quaternion representing the rotation.</param>
	/// <param name="scale">A vector representing the scaling factor.</param>
	/// <param name="result">The transformation <see cref="Matrix"/> which was created.</param>
	public static void CreateFromTranslationRotationScale(in Vector3 translation, in Quaternion rotation, in Vector3 scale, out Matrix result)
	{
	    var xx = rotation.X * rotation.X;
	    var yy = rotation.Y * rotation.Y;
	    var zz = rotation.Z * rotation.Z;
	    var xy = rotation.X * rotation.Y;
	    var zw = rotation.Z * rotation.W;
	    var zx = rotation.Z * rotation.X;
	    var yw = rotation.Y * rotation.W;
	    var yz = rotation.Y * rotation.Z;
	    var xw = rotation.X * rotation.W;

	    result.M11 = scale.X * (1f - (2f * (yy + zz)));
	    result.M12 = scale.X * (2f * (xy + zw));
	    result.M13 = scale.X * (2f * (zx - yw));
	    result.M14 = 0f;
	    result.M21 = scale.Y * (2f * (xy - zw));
	    result.M22 = scale.Y * (1f - (2f * (zz + xx)));
	    result.M23 = scale.Y * (2f * (yz + xw));
	    result.M24 = 0f;
	    result.M31 = scale.Z * (2f * (zx + yw));
	    result.M32 = scale.Z * (2f * (yz - xw));
	    result.M33 = scale.Z * (1f - (2f * (yy + xx)));
	    result.M34 = 0f;
	    result.M41 = translation.X;
	    result.M42 = translation.Y;
	    result.M43 = translation.Z;
	    result.M44 = 1f;
	}

	/// <summary>
	/// Adds a matrix to another matrix.
	/// </summary>
	/// <param name="m1">The <see cref="Matrix"/> on the left side of the addition operator.</param>
	/// <param name="m2">The <see cref="Matrix"/> on the right side of the addition operator.</param>
	/// <param name="result">The resulting <see cref="Matrix"/>.</param>
	public static void Add(in Matrix m1, in Matrix m2, out Matrix result)
	{
	    result.M11 = m1.M11 + m2.M11;
	    result.M12 = m1.M12 + m2.M12;
	    result.M13 = m1.M13 + m2.M13;
	    result.M14 = m1.M14 + m2.M14;

	    result.M21 = m1.M21 + m2.M21;
	    result.M22 = m1.M22 + m2.M22;
	    result.M23 = m1.M23 + m2.M23;
	    result.M24 = m1.M24 + m2.M24;

	    result.M31 = m1.M31 + m2.M31;
	    result.M32 = m1.M32 + m2.M32;
	    result.M33 = m1.M33 + m2.M33;
	    result.M34 = m1.M34 + m2.M34;

	    result.M41 = m1.M41 + m2.M41;
	    result.M42 = m1.M42 + m2.M42;
	    result.M43 = m1.M43 + m2.M43;
	    result.M44 = m1.M44 + m2.M44;
	}

	/// <summary>
	/// Adds a matrix to another matrix.
	/// </summary>
	/// <param name="m1">The <see cref="Matrix"/> on the left side of the addition operator.</param>
	/// <param name="m2">The <see cref="Matrix"/> on the right side of the addition operator.</param>
	/// <returns>The resulting <see cref="Matrix"/>.</returns>
	public static Matrix Add(Matrix m1, Matrix m2)
	{
	    Matrix result;
	    
	    result.M11 = m1.M11 + m2.M11;
	    result.M12 = m1.M12 + m2.M12;
	    result.M13 = m1.M13 + m2.M13;
	    result.M14 = m1.M14 + m2.M14;

	    result.M21 = m1.M21 + m2.M21;
	    result.M22 = m1.M22 + m2.M22;
	    result.M23 = m1.M23 + m2.M23;
	    result.M24 = m1.M24 + m2.M24;

	    result.M31 = m1.M31 + m2.M31;
	    result.M32 = m1.M32 + m2.M32;
	    result.M33 = m1.M33 + m2.M33;
	    result.M34 = m1.M34 + m2.M34;

	    result.M41 = m1.M41 + m2.M41;
	    result.M42 = m1.M42 + m2.M42;
	    result.M43 = m1.M43 + m2.M43;
	    result.M44 = m1.M44 + m2.M44;

	    return result;
	}

	/// <summary>
	/// Subtracts a matrix from another matrix.
	/// </summary>
	/// <param name="m1">The <see cref="Matrix"/> on the left side of the subtraction operator.</param>
	/// <param name="m2">The <see cref="Matrix"/> on the right side of the subtraction operator.</param>
	/// <param name="result">The resulting <see cref="Matrix"/>.</param>
	public static void Subtract(in Matrix m1, in Matrix m2, out Matrix result)
	{
	    result.M11 = m1.M11 - m2.M11;
	    result.M12 = m1.M12 - m2.M12;
	    result.M13 = m1.M13 - m2.M13;
	    result.M14 = m1.M14 - m2.M14;

	    result.M21 = m1.M21 - m2.M21;
	    result.M22 = m1.M22 - m2.M22;
	    result.M23 = m1.M23 - m2.M23;
	    result.M24 = m1.M24 - m2.M24;

	    result.M31 = m1.M31 - m2.M31;
	    result.M32 = m1.M32 - m2.M32;
	    result.M33 = m1.M33 - m2.M33;
	    result.M34 = m1.M34 - m2.M34;

	    result.M41 = m1.M41 - m2.M41;
	    result.M42 = m1.M42 - m2.M42;
	    result.M43 = m1.M43 - m2.M43;
	    result.M44 = m1.M44 - m2.M44;
	}

	/// <summary>
	/// Subtracts a matrix from another matrix.
	/// </summary>
	/// <param name="m1">The <see cref="Matrix"/> on the left side of the subtraction operator.</param>
	/// <param name="m2">The <see cref="Matrix"/> on the right side of the subtraction operator.</param>
	/// <returns>The resulting <see cref="Matrix"/>.</returns>
	public static Matrix Subtract(Matrix m1, Matrix m2)
	{
	    Matrix result;

	    result.M11 = m1.M11 - m2.M11;
	    result.M12 = m1.M12 - m2.M12;
	    result.M13 = m1.M13 - m2.M13;
	    result.M14 = m1.M14 - m2.M14;

	    result.M21 = m1.M21 - m2.M21;
	    result.M22 = m1.M22 - m2.M22;
	    result.M23 = m1.M23 - m2.M23;
	    result.M24 = m1.M24 - m2.M24;

	    result.M31 = m1.M31 - m2.M31;
	    result.M32 = m1.M32 - m2.M32;
	    result.M33 = m1.M33 - m2.M33;
	    result.M34 = m1.M34 - m2.M34;

	    result.M41 = m1.M41 - m2.M41;
	    result.M42 = m1.M42 - m2.M42;
	    result.M43 = m1.M43 - m2.M43;
	    result.M44 = m1.M44 - m2.M44;

	    return result;
	}

	/// <summary>
	/// Multiplies a matrix by a scaling factor.
	/// </summary>
	/// <param name="multiplicand">The multiplicand.</param>
	/// <param name="multiplier">The multiplier.</param>
	/// <param name="result">The resulting <see cref="Matrix"/>.</param>
	public static void Multiply(in Matrix multiplicand, float multiplier, out Matrix result)
	{
	    result.M11 = multiplicand.M11 * multiplier;
	    result.M12 = multiplicand.M12 * multiplier;
	    result.M13 = multiplicand.M13 * multiplier;
	    result.M14 = multiplicand.M14 * multiplier;

	    result.M21 = multiplicand.M21 * multiplier;
	    result.M22 = multiplicand.M22 * multiplier;
	    result.M23 = multiplicand.M23 * multiplier;
	    result.M24 = multiplicand.M24 * multiplier;

	    result.M31 = multiplicand.M31 * multiplier;
	    result.M32 = multiplicand.M32 * multiplier;
	    result.M33 = multiplicand.M33 * multiplier;
	    result.M34 = multiplicand.M34 * multiplier;

	    result.M41 = multiplicand.M41 * multiplier;
	    result.M42 = multiplicand.M42 * multiplier;
	    result.M43 = multiplicand.M43 * multiplier;
	    result.M44 = multiplicand.M44 * multiplier;
	}

	/// <summary>
	/// Multiplies a matrix by a scaling factor.
	/// </summary>
	/// <param name="multiplicand">The multiplicand.</param>
	/// <param name="multiplier">The multiplier.</param>
	/// <returns>The resulting <see cref="Matrix"/>.</returns>
	public static Matrix Multiply(Matrix multiplicand, float multiplier)
	{
	    Matrix result;
	    
	    result.M11 = multiplicand.M11 * multiplier;
	    result.M12 = multiplicand.M12 * multiplier;
	    result.M13 = multiplicand.M13 * multiplier;
	    result.M14 = multiplicand.M14 * multiplier;

	    result.M21 = multiplicand.M21 * multiplier;
	    result.M22 = multiplicand.M22 * multiplier;
	    result.M23 = multiplicand.M23 * multiplier;
	    result.M24 = multiplicand.M24 * multiplier;

	    result.M31 = multiplicand.M31 * multiplier;
	    result.M32 = multiplicand.M32 * multiplier;
	    result.M33 = multiplicand.M33 * multiplier;
	    result.M34 = multiplicand.M34 * multiplier;

	    result.M41 = multiplicand.M41 * multiplier;
	    result.M42 = multiplicand.M42 * multiplier;
	    result.M43 = multiplicand.M43 * multiplier;
	    result.M44 = multiplicand.M44 * multiplier;

	    return result;
	}

	/// <summary>
	/// Multiplies a matrix by another matrix.
	/// </summary>
	/// <param name="multiplicand">The multiplicand.</param>
	/// <param name="multiplier">The multiplier.</param>
	/// <param name="result">The resulting <see cref="Matrix"/>.</param>
	public static void Multiply(in Matrix multiplicand, in Matrix multiplier, out Matrix result)
	{
	    Matrix temp;

	    temp.M11 = multiplicand.M11 * multiplier.M11 + multiplicand.M12 * multiplier.M21 + multiplicand.M13 * multiplier.M31 + multiplicand.M14 * multiplier.M41;
	    temp.M12 = multiplicand.M11 * multiplier.M12 + multiplicand.M12 * multiplier.M22 + multiplicand.M13 * multiplier.M32 + multiplicand.M14 * multiplier.M42;
	    temp.M13 = multiplicand.M11 * multiplier.M13 + multiplicand.M12 * multiplier.M23 + multiplicand.M13 * multiplier.M33 + multiplicand.M14 * multiplier.M43;
	    temp.M14 = multiplicand.M11 * multiplier.M14 + multiplicand.M12 * multiplier.M24 + multiplicand.M13 * multiplier.M34 + multiplicand.M14 * multiplier.M44;

	    temp.M21 = multiplicand.M21 * multiplier.M11 + multiplicand.M22 * multiplier.M21 + multiplicand.M23 * multiplier.M31 + multiplicand.M24 * multiplier.M41;
	    temp.M22 = multiplicand.M21 * multiplier.M12 + multiplicand.M22 * multiplier.M22 + multiplicand.M23 * multiplier.M32 + multiplicand.M24 * multiplier.M42;
	    temp.M23 = multiplicand.M21 * multiplier.M13 + multiplicand.M22 * multiplier.M23 + multiplicand.M23 * multiplier.M33 + multiplicand.M24 * multiplier.M43;
	    temp.M24 = multiplicand.M21 * multiplier.M14 + multiplicand.M22 * multiplier.M24 + multiplicand.M23 * multiplier.M34 + multiplicand.M24 * multiplier.M44;

	    temp.M31 = multiplicand.M31 * multiplier.M11 + multiplicand.M32 * multiplier.M21 + multiplicand.M33 * multiplier.M31 + multiplicand.M34 * multiplier.M41;
	    temp.M32 = multiplicand.M31 * multiplier.M12 + multiplicand.M32 * multiplier.M22 + multiplicand.M33 * multiplier.M32 + multiplicand.M34 * multiplier.M42;
	    temp.M33 = multiplicand.M31 * multiplier.M13 + multiplicand.M32 * multiplier.M23 + multiplicand.M33 * multiplier.M33 + multiplicand.M34 * multiplier.M43;
	    temp.M34 = multiplicand.M31 * multiplier.M14 + multiplicand.M32 * multiplier.M24 + multiplicand.M33 * multiplier.M34 + multiplicand.M34 * multiplier.M44;

	    temp.M41 = multiplicand.M41 * multiplier.M11 + multiplicand.M42 * multiplier.M21 + multiplicand.M43 * multiplier.M31 + multiplicand.M44 * multiplier.M41;
	    temp.M42 = multiplicand.M41 * multiplier.M12 + multiplicand.M42 * multiplier.M22 + multiplicand.M43 * multiplier.M32 + multiplicand.M44 * multiplier.M42;
	    temp.M43 = multiplicand.M41 * multiplier.M13 + multiplicand.M42 * multiplier.M23 + multiplicand.M43 * multiplier.M33 + multiplicand.M44 * multiplier.M43;
	    temp.M44 = multiplicand.M41 * multiplier.M14 + multiplicand.M42 * multiplier.M24 + multiplicand.M43 * multiplier.M34 + multiplicand.M44 * multiplier.M44;

	    result = temp;
	}

	/// <summary>
	/// Multiplies a matrix by another matrix.
	/// </summary>
	/// <param name="multiplicand">The multiplicand.</param>
	/// <param name="multiplier">The multiplier.</param>
	/// <returns>The resulting <see cref="Matrix"/>.</returns>
	public static Matrix Multiply(Matrix multiplicand, Matrix multiplier)
	{
	    Matrix result;

	    result.M11 = multiplicand.M11 * multiplier.M11 + multiplicand.M12 * multiplier.M21 + multiplicand.M13 * multiplier.M31 + multiplicand.M14 * multiplier.M41;
	    result.M12 = multiplicand.M11 * multiplier.M12 + multiplicand.M12 * multiplier.M22 + multiplicand.M13 * multiplier.M32 + multiplicand.M14 * multiplier.M42;
	    result.M13 = multiplicand.M11 * multiplier.M13 + multiplicand.M12 * multiplier.M23 + multiplicand.M13 * multiplier.M33 + multiplicand.M14 * multiplier.M43;
	    result.M14 = multiplicand.M11 * multiplier.M14 + multiplicand.M12 * multiplier.M24 + multiplicand.M13 * multiplier.M34 + multiplicand.M14 * multiplier.M44;

	    result.M21 = multiplicand.M21 * multiplier.M11 + multiplicand.M22 * multiplier.M21 + multiplicand.M23 * multiplier.M31 + multiplicand.M24 * multiplier.M41;
	    result.M22 = multiplicand.M21 * multiplier.M12 + multiplicand.M22 * multiplier.M22 + multiplicand.M23 * multiplier.M32 + multiplicand.M24 * multiplier.M42;
	    result.M23 = multiplicand.M21 * multiplier.M13 + multiplicand.M22 * multiplier.M23 + multiplicand.M23 * multiplier.M33 + multiplicand.M24 * multiplier.M43;
	    result.M24 = multiplicand.M21 * multiplier.M14 + multiplicand.M22 * multiplier.M24 + multiplicand.M23 * multiplier.M34 + multiplicand.M24 * multiplier.M44;

	    result.M31 = multiplicand.M31 * multiplier.M11 + multiplicand.M32 * multiplier.M21 + multiplicand.M33 * multiplier.M31 + multiplicand.M34 * multiplier.M41;
	    result.M32 = multiplicand.M31 * multiplier.M12 + multiplicand.M32 * multiplier.M22 + multiplicand.M33 * multiplier.M32 + multiplicand.M34 * multiplier.M42;
	    result.M33 = multiplicand.M31 * multiplier.M13 + multiplicand.M32 * multiplier.M23 + multiplicand.M33 * multiplier.M33 + multiplicand.M34 * multiplier.M43;
	    result.M34 = multiplicand.M31 * multiplier.M14 + multiplicand.M32 * multiplier.M24 + multiplicand.M33 * multiplier.M34 + multiplicand.M34 * multiplier.M44;

	    result.M41 = multiplicand.M41 * multiplier.M11 + multiplicand.M42 * multiplier.M21 + multiplicand.M43 * multiplier.M31 + multiplicand.M44 * multiplier.M41;
	    result.M42 = multiplicand.M41 * multiplier.M12 + multiplicand.M42 * multiplier.M22 + multiplicand.M43 * multiplier.M32 + multiplicand.M44 * multiplier.M42;
	    result.M43 = multiplicand.M41 * multiplier.M13 + multiplicand.M42 * multiplier.M23 + multiplicand.M43 * multiplier.M33 + multiplicand.M44 * multiplier.M43;
	    result.M44 = multiplicand.M41 * multiplier.M14 + multiplicand.M42 * multiplier.M24 + multiplicand.M43 * multiplier.M34 + multiplicand.M44 * multiplier.M44;

	    return result;
	}

	/// <summary>
	/// Divides a matrix by a scaling factor.
	/// </summary>
	/// <param name="dividend">The dividend.</param>
	/// <param name="divisor">The divisor.</param>
	/// <param name="result">The resulting <see cref="Matrix"/>.</param>
	public static void Divide(in Matrix dividend, float divisor, out Matrix result)
	{
	    result.M11 = dividend.M11 / divisor;
	    result.M12 = dividend.M12 / divisor;
	    result.M13 = dividend.M13 / divisor;
	    result.M14 = dividend.M14 / divisor;

	    result.M21 = dividend.M21 / divisor;
	    result.M22 = dividend.M22 / divisor;
	    result.M23 = dividend.M23 / divisor;
	    result.M24 = dividend.M24 / divisor;

	    result.M31 = dividend.M31 / divisor;
	    result.M32 = dividend.M32 / divisor;
	    result.M33 = dividend.M33 / divisor;
	    result.M34 = dividend.M34 / divisor;

	    result.M41 = dividend.M41 / divisor;
	    result.M42 = dividend.M42 / divisor;
	    result.M43 = dividend.M43 / divisor;
	    result.M44 = dividend.M44 / divisor;
	}

	/// <summary>
	/// Divides a matrix by a scaling factor.
	/// </summary>
	/// <param name="dividend">The dividend.</param>
	/// <param name="divisor">The divisor.</param>
	/// <returns>The resulting <see cref="Matrix"/>.</returns>
	public static Matrix Divide(Matrix dividend, float divisor)
	{
	    Matrix result;
	    
	    result.M11 = dividend.M11 / divisor;
	    result.M12 = dividend.M12 / divisor;
	    result.M13 = dividend.M13 / divisor;
	    result.M14 = dividend.M14 / divisor;

	    result.M21 = dividend.M21 / divisor;
	    result.M22 = dividend.M22 / divisor;
	    result.M23 = dividend.M23 / divisor;
	    result.M24 = dividend.M24 / divisor;

	    result.M31 = dividend.M31 / divisor;
	    result.M32 = dividend.M32 / divisor;
	    result.M33 = dividend.M33 / divisor;
	    result.M34 = dividend.M34 / divisor;

	    result.M41 = dividend.M41 / divisor;
	    result.M42 = dividend.M42 / divisor;
	    result.M43 = dividend.M43 / divisor;
	    result.M44 = dividend.M44 / divisor;

	    return result;
	}

	/// <summary>
	/// Divides a matrix by another matrix.
	/// </summary>
	/// <param name="dividend">The dividend.</param>
	/// <param name="divisor">The divisor.</param>
	/// <param name="result">The resulting <see cref="Matrix"/>.</param>
	public static void Divide(in Matrix dividend, in Matrix divisor, out Matrix result)
	{
	    result.M11 = dividend.M11 / divisor.M11;
	    result.M12 = dividend.M12 / divisor.M12;
	    result.M13 = dividend.M13 / divisor.M13;
	    result.M14 = dividend.M14 / divisor.M14;

	    result.M21 = dividend.M21 / divisor.M21;
	    result.M22 = dividend.M22 / divisor.M22;
	    result.M23 = dividend.M23 / divisor.M23;
	    result.M24 = dividend.M24 / divisor.M24;

	    result.M31 = dividend.M31 / divisor.M31;
	    result.M32 = dividend.M32 / divisor.M32;
	    result.M33 = dividend.M33 / divisor.M33;
	    result.M34 = dividend.M34 / divisor.M34;

	    result.M41 = dividend.M41 / divisor.M41;
	    result.M42 = dividend.M42 / divisor.M42;
	    result.M43 = dividend.M43 / divisor.M43;
	    result.M44 = dividend.M44 / divisor.M44;
	}

	/// <summary>
	/// Divides a matrix by another matrix.
	/// </summary>
	/// <param name="dividend">The dividend.</param>
	/// <param name="divisor">The divisor.</param>
	/// <returns>The resulting <see cref="Matrix"/>.</returns>
	public static Matrix Divide(Matrix dividend, Matrix divisor)
	{
	    Matrix result;
	    
	    result.M11 = dividend.M11 / divisor.M11;
	    result.M12 = dividend.M12 / divisor.M12;
	    result.M13 = dividend.M13 / divisor.M13;
	    result.M14 = dividend.M14 / divisor.M14;

	    result.M21 = dividend.M21 / divisor.M21;
	    result.M22 = dividend.M22 / divisor.M22;
	    result.M23 = dividend.M23 / divisor.M23;
	    result.M24 = dividend.M24 / divisor.M24;

	    result.M31 = dividend.M31 / divisor.M31;
	    result.M32 = dividend.M32 / divisor.M32;
	    result.M33 = dividend.M33 / divisor.M33;
	    result.M34 = dividend.M34 / divisor.M34;

	    result.M41 = dividend.M41 / divisor.M41;
	    result.M42 = dividend.M42 / divisor.M42;
	    result.M43 = dividend.M43 / divisor.M43;
	    result.M44 = dividend.M44 / divisor.M44;

	    return result;
	}

	/// <summary>
	/// Transposes the specified matrix.
	/// </summary>
	/// <param name="matrix">The <see cref="Matrix"/> to transpose.</param>
	/// <param name="result">The transposed <see cref="Matrix"/>.</param>
	public static void Transpose(in Matrix matrix, out Matrix result)
	{
	    Matrix temp;

	    temp.M11 = matrix.M11;
	    temp.M12 = matrix.M21;
	    temp.M13 = matrix.M31;
	    temp.M14 = matrix.M41;

	    temp.M21 = matrix.M12;
	    temp.M22 = matrix.M22;
	    temp.M23 = matrix.M32;
	    temp.M24 = matrix.M42;

	    temp.M31 = matrix.M13;
	    temp.M32 = matrix.M23;
	    temp.M33 = matrix.M33;
	    temp.M34 = matrix.M43;

	    temp.M41 = matrix.M14;
	    temp.M42 = matrix.M24;
	    temp.M43 = matrix.M34;
	    temp.M44 = matrix.M44;

	    result = temp;
	}

	/// <summary>
	/// Transposes the specified matrix.
	/// </summary>
	/// <param name="matrix">The <see cref="Matrix"/> to transpose.</param>
	/// <returns>The transposed <see cref="Matrix"/>.</returns>
	public static Matrix Transpose(Matrix matrix)
	{
	    Matrix result;

	    result.M11 = matrix.M11;
	    result.M12 = matrix.M21;
	    result.M13 = matrix.M31;
	    result.M14 = matrix.M41;

	    result.M21 = matrix.M12;
	    result.M22 = matrix.M22;
	    result.M23 = matrix.M32;
	    result.M24 = matrix.M42;

	    result.M31 = matrix.M13;
	    result.M32 = matrix.M23;
	    result.M33 = matrix.M33;
	    result.M34 = matrix.M43;

	    result.M41 = matrix.M14;
	    result.M42 = matrix.M24;
	    result.M43 = matrix.M34;
	    result.M44 = matrix.M44;

	    return result;
	}

	/// <summary>
	/// Linearly interpolates between the specified matrices.
	/// </summary>
	/// <param name="matrix1">The first <see cref="Matrix"/> to interpolate.</param>
	/// <param name="matrix2">The second <see cref="Matrix"/> to interpolate.</param>
	/// <param name="amount">A value from 0.0 to 1.0 indicating the interpolation factor.</param>
	/// <param name="result">The interpolated <see cref="Matrix"/>.</param>
	public static void Lerp(in Matrix matrix1, in Matrix matrix2, float amount, out Matrix result)
	{
	    result.M11 = matrix1.M11 + (matrix2.M11 - matrix1.M11) * amount;
	    result.M12 = matrix1.M12 + (matrix2.M12 - matrix1.M12) * amount;
	    result.M13 = matrix1.M13 + (matrix2.M13 - matrix1.M13) * amount;
	    result.M14 = matrix1.M14 + (matrix2.M14 - matrix1.M14) * amount;

	    result.M21 = matrix1.M21 + (matrix2.M21 - matrix1.M21) * amount;
	    result.M22 = matrix1.M22 + (matrix2.M22 - matrix1.M22) * amount;
	    result.M23 = matrix1.M23 + (matrix2.M23 - matrix1.M23) * amount;
	    result.M24 = matrix1.M24 + (matrix2.M24 - matrix1.M24) * amount;

	    result.M31 = matrix1.M31 + (matrix2.M31 - matrix1.M31) * amount;
	    result.M32 = matrix1.M32 + (matrix2.M32 - matrix1.M32) * amount;
	    result.M33 = matrix1.M33 + (matrix2.M33 - matrix1.M33) * amount;
	    result.M34 = matrix1.M34 + (matrix2.M34 - matrix1.M34) * amount;

	    result.M41 = matrix1.M41 + (matrix2.M41 - matrix1.M41) * amount;
	    result.M42 = matrix1.M42 + (matrix2.M42 - matrix1.M42) * amount;
	    result.M43 = matrix1.M43 + (matrix2.M43 - matrix1.M43) * amount;
	    result.M44 = matrix1.M44 + (matrix2.M44 - matrix1.M44) * amount;
	}

	/// <summary>
	/// Linearly interpolates between the specified matrices.
	/// </summary>
	/// <param name="matrix1">The first <see cref="Matrix"/> to interpolate.</param>
	/// <param name="matrix2">The second <see cref="Matrix"/> to interpolate.</param>
	/// <param name="amount">A value from 0.0 to 1.0 indicating the interpolation factor.</param>
	/// <returns>The interpolated <see cref="Matrix"/>.</returns>
	public static Matrix Lerp(Matrix matrix1, Matrix matrix2, float amount)
	{
	    Matrix result;
	    
	    result.M11 = matrix1.M11 + (matrix2.M11 - matrix1.M11) * amount;
	    result.M12 = matrix1.M12 + (matrix2.M12 - matrix1.M12) * amount;
	    result.M13 = matrix1.M13 + (matrix2.M13 - matrix1.M13) * amount;
	    result.M14 = matrix1.M14 + (matrix2.M14 - matrix1.M14) * amount;

	    result.M21 = matrix1.M21 + (matrix2.M21 - matrix1.M21) * amount;
	    result.M22 = matrix1.M22 + (matrix2.M22 - matrix1.M22) * amount;
	    result.M23 = matrix1.M23 + (matrix2.M23 - matrix1.M23) * amount;
	    result.M24 = matrix1.M24 + (matrix2.M24 - matrix1.M24) * amount;

	    result.M31 = matrix1.M31 + (matrix2.M31 - matrix1.M31) * amount;
	    result.M32 = matrix1.M32 + (matrix2.M32 - matrix1.M32) * amount;
	    result.M33 = matrix1.M33 + (matrix2.M33 - matrix1.M33) * amount;
	    result.M34 = matrix1.M34 + (matrix2.M34 - matrix1.M34) * amount;

	    result.M41 = matrix1.M41 + (matrix2.M41 - matrix1.M41) * amount;
	    result.M42 = matrix1.M42 + (matrix2.M42 - matrix1.M42) * amount;
	    result.M43 = matrix1.M43 + (matrix2.M43 - matrix1.M43) * amount;
	    result.M44 = matrix1.M44 + (matrix2.M44 - matrix1.M44) * amount;

	    return result;
	}

	/// <summary>
	/// Calculates the inverse of the specified matrix.
	/// </summary>
	/// <param name="matrix">The <see cref="Matrix"/> to invert.</param>
	/// <param name="result">The invertex <see cref="Matrix"/>.</param>
	public static void Invert(in Matrix matrix, out Matrix result)
	{
	    var s0 = matrix.M11 * matrix.M22 - matrix.M21 * matrix.M12;
	    var s1 = matrix.M11 * matrix.M23 - matrix.M21 * matrix.M13;
	    var s2 = matrix.M11 * matrix.M24 - matrix.M21 * matrix.M14;
	    var s3 = matrix.M12 * matrix.M23 - matrix.M22 * matrix.M13;
	    var s4 = matrix.M12 * matrix.M24 - matrix.M22 * matrix.M14;
	    var s5 = matrix.M13 * matrix.M24 - matrix.M23 * matrix.M14;

	    var c5 = matrix.M33 * matrix.M44 - matrix.M43 * matrix.M34;
	    var c4 = matrix.M32 * matrix.M44 - matrix.M42 * matrix.M34;
	    var c3 = matrix.M32 * matrix.M43 - matrix.M42 * matrix.M33;
	    var c2 = matrix.M31 * matrix.M44 - matrix.M41 * matrix.M34;
	    var c1 = matrix.M31 * matrix.M43 - matrix.M41 * matrix.M33;
	    var c0 = matrix.M31 * matrix.M42 - matrix.M41 * matrix.M32;

	    var det = (s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0);
	    if (det == 0)
	        Runtime.DivideByZeroError();

	    var invdet = 1.0f / det;

	    Matrix temp;

	    temp.M11 = (matrix.M22 * c5 - matrix.M23 * c4 + matrix.M24 * c3) * invdet;
	    temp.M12 = (-matrix.M12 * c5 + matrix.M13 * c4 - matrix.M14 * c3) * invdet;
	    temp.M13 = (matrix.M42 * s5 - matrix.M43 * s4 + matrix.M44 * s3) * invdet;
	    temp.M14 = (-matrix.M32 * s5 + matrix.M33 * s4 - matrix.M34 * s3) * invdet;

	    temp.M21 = (-matrix.M21 * c5 + matrix.M23 * c2 - matrix.M24 * c1) * invdet;
	    temp.M22 = (matrix.M11 * c5 - matrix.M13 * c2 + matrix.M14 * c1) * invdet;
	    temp.M23 = (-matrix.M41 * s5 + matrix.M43 * s2 - matrix.M44 * s1) * invdet;
	    temp.M24 = (matrix.M31 * s5 - matrix.M33 * s2 + matrix.M34 * s1) * invdet;

	    temp.M31 = (matrix.M21 * c4 - matrix.M22 * c2 + matrix.M24 * c0) * invdet;
	    temp.M32 = (-matrix.M11 * c4 + matrix.M12 * c2 - matrix.M14 * c0) * invdet;
	    temp.M33 = (matrix.M41 * s4 - matrix.M42 * s2 + matrix.M44 * s0) * invdet;
	    temp.M34 = (-matrix.M31 * s4 + matrix.M32 * s2 - matrix.M34 * s0) * invdet;

	    temp.M41  = (-matrix.M21 * c3 + matrix.M22 * c1 - matrix.M23 * c0) * invdet;
	    temp.M42 = (matrix.M11 * c3 - matrix.M12 * c1 + matrix.M13 * c0) * invdet;
	    temp.M43 = (-matrix.M41 * s3 + matrix.M42 * s1 - matrix.M43 * s0) * invdet;
	    temp.M44 = (matrix.M31 * s3 - matrix.M32 * s1 + matrix.M33 * s0) * invdet;

	    result = temp;
	}

	/// <summary>
	/// Calculates the inverse of the specified matrix.
	/// </summary>
	/// <param name="matrix">The <see cref="Matrix"/> to invert.</param>
	/// <returns>The inverted <see cref="Matrix"/>.</returns>
	public static Matrix Invert(Matrix matrix)
	{
	    var s0 = matrix.M11 * matrix.M22 - matrix.M21 * matrix.M12;
	    var s1 = matrix.M11 * matrix.M23 - matrix.M21 * matrix.M13;
	    var s2 = matrix.M11 * matrix.M24 - matrix.M21 * matrix.M14;
	    var s3 = matrix.M12 * matrix.M23 - matrix.M22 * matrix.M13;
	    var s4 = matrix.M12 * matrix.M24 - matrix.M22 * matrix.M14;
	    var s5 = matrix.M13 * matrix.M24 - matrix.M23 * matrix.M14;

	    var c5 = matrix.M33 * matrix.M44 - matrix.M43 * matrix.M34;
	    var c4 = matrix.M32 * matrix.M44 - matrix.M42 * matrix.M34;
	    var c3 = matrix.M32 * matrix.M43 - matrix.M42 * matrix.M33;
	    var c2 = matrix.M31 * matrix.M44 - matrix.M41 * matrix.M34;
	    var c1 = matrix.M31 * matrix.M43 - matrix.M41 * matrix.M33;
	    var c0 = matrix.M31 * matrix.M42 - matrix.M41 * matrix.M32;

	    var det = (s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0);
	    if (det == 0)
	        Runtime.DivideByZeroError();

	    var invdet = 1.0f / det;

	    Matrix result;

	    result.M11 = (matrix.M22 * c5 - matrix.M23 * c4 + matrix.M24 * c3) * invdet;
	    result.M12 = (-matrix.M12 * c5 + matrix.M13 * c4 - matrix.M14 * c3) * invdet;
	    result.M13 = (matrix.M42 * s5 - matrix.M43 * s4 + matrix.M44 * s3) * invdet;
	    result.M14 = (-matrix.M32 * s5 + matrix.M33 * s4 - matrix.M34 * s3) * invdet;

	    result.M21 = (-matrix.M21 * c5 + matrix.M23 * c2 - matrix.M24 * c1) * invdet;
	    result.M22 = (matrix.M11 * c5 - matrix.M13 * c2 + matrix.M14 * c1) * invdet;
	    result.M23 = (-matrix.M41 * s5 + matrix.M43 * s2 - matrix.M44 * s1) * invdet;
	    result.M24 = (matrix.M31 * s5 - matrix.M33 * s2 + matrix.M34 * s1) * invdet;

	    result.M31 = (matrix.M21 * c4 - matrix.M22 * c2 + matrix.M24 * c0) * invdet;
	    result.M32 = (-matrix.M11 * c4 + matrix.M12 * c2 - matrix.M14 * c0) * invdet;
	    result.M33 = (matrix.M41 * s4 - matrix.M42 * s2 + matrix.M44 * s0) * invdet;
	    result.M34 = (-matrix.M31 * s4 + matrix.M32 * s2 - matrix.M34 * s0) * invdet;

	    result.M41 = (-matrix.M21 * c3 + matrix.M22 * c1 - matrix.M23 * c0) * invdet;
	    result.M42 = (matrix.M11 * c3 - matrix.M12 * c1 + matrix.M13 * c0) * invdet;
	    result.M43 = (-matrix.M41 * s3 + matrix.M42 * s1 - matrix.M43 * s0) * invdet;
	    result.M44 = (matrix.M31 * s3 - matrix.M32 * s1 + matrix.M33 * s0) * invdet;

	    return result;
	}

	/// <summary>
	/// Attempts to calculate the inverse of the specified matrix.
	/// </summary>
	/// <param name="matrix">The <see cref="Matrix"/> to invert.</param>
	/// <param name="result">The inverted <see cref="Matrix"/>.</param>
	/// <returns><see langword="true"/> if the matrix was inverted; otherwise, <see langword="false"/>.</returns>
	public static bool TryInvert(Matrix matrix, out Matrix result)
	{
	    var s0 = matrix.M11 * matrix.M22 - matrix.M21 * matrix.M12;
	    var s1 = matrix.M11 * matrix.M23 - matrix.M21 * matrix.M13;
	    var s2 = matrix.M11 * matrix.M24 - matrix.M21 * matrix.M14;
	    var s3 = matrix.M12 * matrix.M23 - matrix.M22 * matrix.M13;
	    var s4 = matrix.M12 * matrix.M24 - matrix.M22 * matrix.M14;
	    var s5 = matrix.M13 * matrix.M24 - matrix.M23 * matrix.M14;

	    var c5 = matrix.M33 * matrix.M44 - matrix.M43 * matrix.M34;
	    var c4 = matrix.M32 * matrix.M44 - matrix.M42 * matrix.M34;
	    var c3 = matrix.M32 * matrix.M43 - matrix.M42 * matrix.M33;
	    var c2 = matrix.M31 * matrix.M44 - matrix.M41 * matrix.M34;
	    var c1 = matrix.M31 * matrix.M43 - matrix.M41 * matrix.M33;
	    var c0 = matrix.M31 * matrix.M42 - matrix.M41 * matrix.M32;

	    var det = (s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0);
	    if (det == 0)
	    {
	        result = Matrix.Identity;
	        return false;
	    }

	    var invdet = 1.0f / det;

	    result.M11 = (matrix.M22 * c5 - matrix.M23 * c4 + matrix.M24 * c3) * invdet;
	    result.M12 = (-matrix.M12 * c5 + matrix.M13 * c4 - matrix.M14 * c3) * invdet;
	    result.M13 = (matrix.M42 * s5 - matrix.M43 * s4 + matrix.M44 * s3) * invdet;
	    result.M14 = (-matrix.M32 * s5 + matrix.M33 * s4 - matrix.M34 * s3) * invdet;

	    result.M21 = (-matrix.M21 * c5 + matrix.M23 * c2 - matrix.M24 * c1) * invdet;
	    result.M22 = (matrix.M11 * c5 - matrix.M13 * c2 + matrix.M14 * c1) * invdet;
	    result.M23 = (-matrix.M41 * s5 + matrix.M43 * s2 - matrix.M44 * s1) * invdet;
	    result.M24 = (matrix.M31 * s5 - matrix.M33 * s2 + matrix.M34 * s1) * invdet;

	    result.M31 = (matrix.M21 * c4 - matrix.M22 * c2 + matrix.M24 * c0) * invdet;
	    result.M32 = (-matrix.M11 * c4 + matrix.M12 * c2 - matrix.M14 * c0) * invdet;
	    result.M33 = (matrix.M41 * s4 - matrix.M42 * s2 + matrix.M44 * s0) * invdet;
	    result.M34 = (-matrix.M31 * s4 + matrix.M32 * s2 - matrix.M34 * s0) * invdet;

	    result.M41  = (-matrix.M21 * c3 + matrix.M22 * c1 - matrix.M23 * c0) * invdet;
	    result.M42 = (matrix.M11 * c3 - matrix.M12 * c1 + matrix.M13 * c0) * invdet;
	    result.M43 = (-matrix.M41 * s3 + matrix.M42 * s1 - matrix.M43 * s0) * invdet;
	    result.M44 = (matrix.M31 * s3 - matrix.M32 * s1 + matrix.M33 * s0) * invdet;            

	    return true;
	}

	/// <summary>
	/// Attempts to calculate the inverse of the specified matrix.
	/// </summary>
	/// <param name="matrix">The <see cref="Matrix"/> to invert.</param>
	/// <param name="result">The inverted <see cref="Matrix"/>.</param>
	/// <returns><see langword="true"/> if the matrix was inverted; otherwise, <see langword="false"/>.</returns>
	public static bool TryInvertRef(in Matrix matrix, out Matrix result)
	{
	    var s0 = matrix.M11 * matrix.M22 - matrix.M21 * matrix.M12;
	    var s1 = matrix.M11 * matrix.M23 - matrix.M21 * matrix.M13;
	    var s2 = matrix.M11 * matrix.M24 - matrix.M21 * matrix.M14;
	    var s3 = matrix.M12 * matrix.M23 - matrix.M22 * matrix.M13;
	    var s4 = matrix.M12 * matrix.M24 - matrix.M22 * matrix.M14;
	    var s5 = matrix.M13 * matrix.M24 - matrix.M23 * matrix.M14;

	    var c5 = matrix.M33 * matrix.M44 - matrix.M43 * matrix.M34;
	    var c4 = matrix.M32 * matrix.M44 - matrix.M42 * matrix.M34;
	    var c3 = matrix.M32 * matrix.M43 - matrix.M42 * matrix.M33;
	    var c2 = matrix.M31 * matrix.M44 - matrix.M41 * matrix.M34;
	    var c1 = matrix.M31 * matrix.M43 - matrix.M41 * matrix.M33;
	    var c0 = matrix.M31 * matrix.M42 - matrix.M41 * matrix.M32;

	    var det = (s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0);
	    if (det == 0)
	    {
	        result = Matrix.Identity;
	        return false;
	    }

	    var invdet = 1.0f / det;

	    Matrix temp;

	    temp.M11 = (matrix.M22 * c5 - matrix.M23 * c4 + matrix.M24 * c3) * invdet;
	    temp.M12 = (-matrix.M12 * c5 + matrix.M13 * c4 - matrix.M14 * c3) * invdet;
	    temp.M13 = (matrix.M42 * s5 - matrix.M43 * s4 + matrix.M44 * s3) * invdet;
	    temp.M14 = (-matrix.M32 * s5 + matrix.M33 * s4 - matrix.M34 * s3) * invdet;

	    temp.M21 = (-matrix.M21 * c5 + matrix.M23 * c2 - matrix.M24 * c1) * invdet;
	    temp.M22 = (matrix.M11 * c5 - matrix.M13 * c2 + matrix.M14 * c1) * invdet;
	    temp.M23 = (-matrix.M41 * s5 + matrix.M43 * s2 - matrix.M44 * s1) * invdet;
	    temp.M24 = (matrix.M31 * s5 - matrix.M33 * s2 + matrix.M34 * s1) * invdet;

	    temp.M31 = (matrix.M21 * c4 - matrix.M22 * c2 + matrix.M24 * c0) * invdet;
	    temp.M32 = (-matrix.M11 * c4 + matrix.M12 * c2 - matrix.M14 * c0) * invdet;
	    temp.M33 = (matrix.M41 * s4 - matrix.M42 * s2 + matrix.M44 * s0) * invdet;
	    temp.M34 = (-matrix.M31 * s4 + matrix.M32 * s2 - matrix.M34 * s0) * invdet;

	    temp.M41 = (-matrix.M21 * c3 + matrix.M22 * c1 - matrix.M23 * c0) * invdet;
	    temp.M42 = (matrix.M11 * c3 - matrix.M12 * c1 + matrix.M13 * c0) * invdet;
	    temp.M43 = (-matrix.M41 * s3 + matrix.M42 * s1 - matrix.M43 * s0) * invdet;
	    temp.M44 = (matrix.M31 * s3 - matrix.M32 * s1 + matrix.M33 * s0) * invdet;

	    result = temp;

	    return true;
	}

	/// <summary>
	/// Negates the specified matrix's elements.
	/// </summary>
	/// <param name="matrix">The <see cref="Matrix"/> to negate.</param>
	/// <param name="result">The negated <see cref="Matrix"/>.</param>
	public static void Negate(in Matrix matrix, out Matrix result)
	{
	    result.M11 = -matrix.M11;
	    result.M12 = -matrix.M12;
	    result.M13 = -matrix.M13;
	    result.M14 = -matrix.M14;

	    result.M21 = -matrix.M21;
	    result.M22 = -matrix.M22;
	    result.M23 = -matrix.M23;
	    result.M24 = -matrix.M24;

	    result.M31 = -matrix.M31;
	    result.M32 = -matrix.M32;
	    result.M33 = -matrix.M33;
	    result.M34 = -matrix.M34;

	    result.M41 = -matrix.M41;
	    result.M42 = -matrix.M42;
	    result.M43 = -matrix.M43;
	    result.M44 = -matrix.M44;
	}

    /// <summary>
    /// Negates the specified matrix's elements.
    /// </summary>
    /// <param name="matrix">The <see cref="Matrix"/> to negate.</param>
    /// <returns>The negated <see cref="Matrix"/>.</returns>
    public static Matrix Negate(Matrix matrix)
    {
        Matrix result;

        result.M11 = -matrix.M11;
        result.M12 = -matrix.M12;
        result.M13 = -matrix.M13;
        result.M14 = -matrix.M14;

        result.M21 = -matrix.M21;
        result.M22 = -matrix.M22;
        result.M23 = -matrix.M23;
        result.M24 = -matrix.M24;

        result.M31 = -matrix.M31;
        result.M32 = -matrix.M32;
        result.M33 = -matrix.M33;
        result.M34 = -matrix.M34;

        result.M41 = -matrix.M41;
        result.M42 = -matrix.M42;
        result.M43 = -matrix.M43;
        result.M44 = -matrix.M44;

        return result;
    }

    /// <inheritdoc/>
    public override void ToString(String str) =>
        str.Append( scope $"{{ {{M11:{M11} M12:{M12} M13:{M13} M14:{M14}}} {{M21:{M21} M22:{M22} M23:{M23} M24:{M24}}} {{M31:{M31} M32:{M32} M33:{M33} M34:{M34}}} {{M41:{M41} M42:{M42} M43:{M43} M44:{M44}}} }}");

    /// <summary>
    /// Calculates the matrix's determinant.
    /// </summary>
    /// <returns>The matrix's determinant.</returns>
    public float Determinant()
    {
        var s0 = M11 * M22 - M21 * M12;
        var s1 = M11 * M23 - M21 * M13;
        var s2 = M11 * M24 - M21 * M14;
        var s3 = M12 * M23 - M22 * M13;
        var s4 = M12 * M24 - M22 * M14;
        var s5 = M13 * M24 - M23 * M14;

        var c5 = M33 * M44 - M43 * M34;
        var c4 = M32 * M44 - M42 * M34;
        var c3 = M32 * M43 - M42 * M33;
        var c2 = M31 * M44 - M41 * M34;
        var c1 = M31 * M43 - M41 * M33;
        var c0 = M31 * M42 - M41 * M32;

        return (s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0);
    }

    /// <summary>
    /// Interpolates between this value and the specified value.
    /// </summary>
    /// <param name="target">The target value.</param>
    /// <param name="t">A value between 0.0 and 1.0 representing the interpolation factor.</param>
    /// <returns>The interpolated value.</returns>
    public Matrix Interpolate(Matrix target, float t)
    {
        Matrix.Lerp(this, target, t, var result);
        return result;
    }

    /// <summary>
    /// Decomposes the matrix into scale, rotation, and translation components.
    /// </summary>
    /// <param name="scale">The scale component of the transformation matrix.</param>
    /// <param name="rotation">The rotation component of the transformation matrix.</param>
    /// <param name="translation">The translation component of the transformation matrix.</param>
    /// <returns><see langword="true"/> if the matrix can be decomposed; otherwise, <see langword="false"/>.</returns>
    public bool Decompose(out Vector3 scale, out Quaternion rotation, out Vector3 translation)
    {
        translation.X = M41;
        translation.Y = M42;
        translation.Z = M43;

        var xSign = (Math.Sign(M11 * M12 * M13 * M14) < 0) ? -1 : 1;
        var ySign = (Math.Sign(M21 * M22 * M23 * M24) < 0) ? -1 : 1;
        var zSign = (Math.Sign(M31 * M32 * M33 * M34) < 0) ? -1 : 1;

        scale.X = xSign * (float)Math.Sqrt(M11 * M11 + M12 * M12 + M13 * M13);
        if (scale.X == 0)
        {
            scale = Vector3.One;
            rotation = Quaternion.Identity;
            return false;
        }

        scale.Y = ySign * (float)Math.Sqrt(M21 * M21 + M22 * M22 + M23 * M23);
        if (scale.Y == 0)
        {
            scale = Vector3.One;
            rotation = Quaternion.Identity;
            return false;
        }

        scale.Z = zSign * (float)Math.Sqrt(M31 * M31 + M32 * M32 + M33 * M33);
        if (scale.Z == 0)
        {
            scale = Vector3.One;
            rotation = Quaternion.Identity;
            return false;
        }

        var rotationMatrix = Matrix(
            M11 / scale.X, M12 / scale.X, M13 / scale.X, 0,
            M21 / scale.Y, M22 / scale.Y, M23 / scale.Y, 0,
            M31 / scale.Z, M32 / scale.Z, M33 / scale.Z, 0,
            0, 0, 0, 1);

        rotation = Quaternion.CreateFromRotationMatrix(rotationMatrix);
        return true;
    }

    /// <summary>
    /// Gets the identity matrix.
    /// </summary>
    public static Matrix Identity { get; } = Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);

    /// <summary>
    /// Gets the matrix's right vector.
    /// </summary>
    public Vector3 Right 
    { 
        get { return Vector3(M11, M12, M13); }
        set mut
        {
            M11 = value.X;
            M12 = value.Y;
            M13 = value.Z;
        }
    }

    /// <summary>
    /// Gets the matrix's left vector.
    /// </summary>
    public Vector3 Left
    {
        get { return Vector3(-M11, -M12, -M13); }
        set mut
        {
            M11 = -value.X;
            M12 = -value.Y;
            M13 = -value.Z;
        }
    }

    /// <summary>
    /// Gets the matrix's up vector.
    /// </summary>
    public Vector3 Up 
    { 
        get { return Vector3(M21, M22, M23); }
        set mut
        {
            M21 = value.X;
            M22 = value.Y;
            M23 = value.Z;
        }
    }

    /// <summary>
    /// Gets the matrix's down vector.
    /// </summary>
    public Vector3 Down 
    { 
        get { return Vector3(-M21, -M22, -M23); }
        set mut
        {
            M21 = -value.X;
            M22 = -value.Y;
            M23 = -value.Z;
        }
    }

    /// <summary>
    /// Gets the matrix's backwards vector.
    /// </summary>
    public Vector3 Backward 
    { 
        get { return Vector3(M31, M32, M33); }
        set mut
        {
            M31 = value.X;
            M32 = value.Y;
            M33 = value.Z;
        }
    }

    /// <summary>
    /// Gets the matrix's forwards vector.
    /// </summary>
    public Vector3 Forward
    { 
        get { return Vector3(-M31, -M32, -M33); }
        set mut
        {
            M31 = -value.X;
            M32 = -value.Y;
            M33 = -value.Z;
        }
    }

    /// <summary>
    /// Gets the matrix's translation vector.
    /// </summary>
    public Vector3 Translation 
    { 
        get { return Vector3(M41, M42, M43); }
        set mut
        {
            M41 = value.X;
            M42 = value.Y;
            M43 = value.Z;
        }
    }

    /// <summary>
    /// Gets the value at row 1, column 1 of the matrix.
    /// </summary>
    public float M11;

    /// <summary>
    /// Gets the value at row 1, column 2 of the matrix.
    /// </summary>
    public float M12;

    /// <summary>
    /// Gets the value at row 1, column 3 of the matrix.
    /// </summary>
    public float M13;

    /// <summary>
    /// Gets the value at row 1, column 4 of the matrix.
    /// </summary>
    public float M14;

    /// <summary>
    /// Gets the value at row 2, column 1 of the matrix.
    /// </summary>
    public float M21;

    /// <summary>
    /// Gets the value at row 2, column 2 of the matrix.
    /// </summary>
    public float M22;

    /// <summary>
    /// Gets the value at row 2, column 3 of the matrix.
    /// </summary>
    public float M23;

    /// <summary>
    /// Gets the value at row 2, column 4 of the matrix.
    /// </summary>
    public float M24;

    /// <summary>
    /// Gets the value at row 3, column 1 of the matrix.
    /// </summary>
    public float M31;

    /// <summary>
    /// Gets the value at row 3, column 1 of the matrix.
    /// </summary>
    public float M32;

    /// <summary>
    /// Gets the value at row 3, column 1 of the matrix.
    /// </summary>
    public float M33;

    /// <summary>
    /// Gets the value at row 3, column 1 of the matrix.
    /// </summary>
    public float M34;

    /// <summary>
    /// Gets the value at row 4, column 1 of the matrix.
    /// </summary>
    public float M41;

    /// <summary>
    /// Gets the value at row 4, column 2 of the matrix.
    /// </summary>
    public float M42;

    /// <summary>
    /// Gets the value at row 4, column 3 of the matrix.
    /// </summary>
    public float M43;

    /// <summary>
    /// Gets the value at row 4, column 4 of the matrix.
    /// </summary>
    public float M44;
}