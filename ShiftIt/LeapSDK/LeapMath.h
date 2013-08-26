/******************************************************************************\
* Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               *
* Leap Motion proprietary and confidential. Not for distribution.              *
* Use subject to the terms of the Leap Motion SDK Agreement available at       *
* https://developer.leapmotion.com/sdk_agreement, or another agreement         *
* between Leap Motion and you, your company or other organization.             *
\******************************************************************************/

#if !defined(__LeapMath_h__)
#define __LeapMath_h__

#include <cmath>
#include <iostream>
#include <sstream>
#include <float.h>

namespace Leap {

/**
 * The constant pi as a single precision floating point number.
 * @since 1.0
 */
static const float PI          = 3.1415926536f;
/**
 * The constant ratio to convert an angle measure from degrees to radians.
 * Multiply a value in degrees by this constant to convert to radians.
 * @since 1.0
 */
static const float DEG_TO_RAD  = 0.0174532925f;
/**
 * The constant ratio to convert an angle measure from radians to degrees.
 * Multiply a value in radians by this constant to convert to degrees.
 * @since 1.0
 */
static const float RAD_TO_DEG  = 57.295779513f;

/**
 * The Vector struct represents a three-component mathematical vector or point
 * such as a direction or position in three-dimensional space.
 *
 * The Leap Motion software employs a right-handed Cartesian coordinate system.
 * Values given are in units of real-world millimeters. The origin is centered
 * at the center of the Leap Motion Controller. The x- and z-axes lie in the horizontal
 * plane, with the x-axis running parallel to the long edge of the device.
 * The y-axis is vertical, with positive values increasing upwards (in contrast
 * to the downward orientation of most computer graphics coordinate systems).
 * The z-axis has positive values increasing away from the computer screen.
 *
 * \image html images/Leap_Axes.png
 * @since 1.0
 */
struct Vector {
  /**
   * Creates a new Vector with all components set to zero.
   * @since 1.0
   */
  Vector() :
    x(0), y(0), z(0) {}

  /**
   * Creates a new Vector with the specified component values.
   *
   * \include Vector_Constructor_1.txt
   * @since 1.0
   */
  Vector(float _x, float _y, float _z) :
    x(_x), y(_y), z(_z) {}

  /**
   * Copies the specified Vector.
   *
   * \include Vector_Constructor_2.txt
   * @since 1.0
   */
  Vector(const Vector& vector) :
    x(vector.x), y(vector.y), z(vector.z) {}

  /**
   * The zero vector: (0, 0, 0)
   *
   * \include Vector_Zero.txt
   * @since 1.0
   */
  static const Vector& zero() {
    static Vector s_zero(0, 0, 0);
    return s_zero;
  }

  /**
   * The x-axis unit vector: (1, 0, 0)
   *
   * \include Vector_XAxis.txt
   * @since 1.0
   */
  static const Vector& xAxis() {
    static Vector s_xAxis(1, 0, 0);
    return s_xAxis;
  }
  /**
   * The y-axis unit vector: (0, 1, 0)
   *
   * \include Vector_YAxis.txt
   * @since 1.0
   */
  static const Vector& yAxis() {
    static Vector s_yAxis(0, 1, 0);
    return s_yAxis;
  }
  /**
   * The z-axis unit vector: (0, 0, 1)
   *
   * \include Vector_ZAxis.txt
   * @since 1.0
   */
  static const Vector& zAxis() {
    static Vector s_zAxis(0, 0, 1);
    return s_zAxis;
  }

  /**
   * The unit vector pointing left along the negative x-axis: (-1, 0, 0)
   *
   * \include Vector_Left.txt
   * @since 1.0
   */
  static const Vector& left() {
    static Vector s_left(-1, 0, 0);
    return s_left;
  }
  /**
   * The unit vector pointing right along the positive x-axis: (1, 0, 0)
   *
   * \include Vector_Right.txt
   * @since 1.0
   */
  static const Vector& right() {
    return xAxis();
  }
  /**
   * The unit vector pointing down along the negative y-axis: (0, -1, 0)
   *
   * \include Vector_Down.txt
   * @since 1.0
   */
  static const Vector& down() {
    static Vector s_down(0, -1, 0);
    return s_down;
  }
  /**
   * The unit vector pointing up along the positive y-axis: (0, 1, 0)
   *
   * \include Vector_Up.txt
   * @since 1.0
   */
  static const Vector& up() {
    return yAxis();
  }
  /**
   * The unit vector pointing forward along the negative z-axis: (0, 0, -1)
   *
   * \include Vector_Forward.txt
   * @since 1.0
   */
  static const Vector& forward() {
    static Vector s_forward(0, 0, -1);
    return s_forward;
  }
  /**
   * The unit vector pointing backward along the positive z-axis: (0, 0, 1)
   *
   * \include Vector_Backward.txt
   * @since 1.0
   */
  static const Vector& backward() {
    return zAxis();
  }

  /**
   * The magnitude, or length, of this vector.
   *
   * The magnitude is the L2 norm, or Euclidean distance between the origin and
   * the point represented by the (x, y, z) components of this Vector object.
   *
   * \include Vector_Magnitude.txt
   *
   * @returns The length of this vector.
   * @since 1.0
   */
  float magnitude() const {
    return std::sqrt(x*x + y*y + z*z);
  }

  /**
   * The square of the magnitude, or length, of this vector.
   *
   * \include Vector_Magnitude_Squared.txt
   *
   * @returns The square of the length of this vector.
   * @since 1.0
   */
  float magnitudeSquared() const {
    return x*x + y*y + z*z;
  }

  /**
   * The distance between the point represented by this Vector
   * object and a point represented by the specified Vector object.
   *
   * \include Vector_DistanceTo.txt
   *
   * @param other A Vector object.
   * @returns The distance from this point to the specified point.
   * @since 1.0
   */
  float distanceTo(const Vector& other) const {
    return std::sqrt((x - other.x)*(x - other.x) +
                     (y - other.y)*(y - other.y) +
                     (z - other.z)*(z - other.z));
  }

  /**
   * The angle between this vector and the specified vector in radians.
   *
   * The angle is measured in the plane formed by the two vectors. The
   * angle returned is always the smaller of the two conjugate angles.
   * Thus <tt>A.angleTo(B) == B.angleTo(A)</tt> and is always a positive
   * value less than or equal to pi radians (180 degrees).
   *
   * If either vector has zero length, then this function returns zero.
   *
   * \image html images/Math_AngleTo.png
   *
   * \include Vector_AngleTo.txt
   *
   * @param other A Vector object.
   * @returns The angle between this vector and the specified vector in radians.
   * @since 1.0
   */
  float angleTo(const Vector& other) const {
    float denom = this->magnitudeSquared() * other.magnitudeSquared();
    if (denom <= 0.0f) {
      return 0.0f;
    }
    return std::acos(this->dot(other) / std::sqrt(denom));
  }

  /**
   * The pitch angle in radians.
   *
   * Pitch is the angle between the negative z-axis and the projection of
   * the vector onto the y-z plane. In other words, pitch represents rotation
   * around the x-axis.
   * If the vector points upward, the returned angle is between 0 and pi radians
   * (180 degrees); if it points downward, the angle is between 0 and -pi radians.
   *
   * \image html images/Math_Pitch_Angle.png
   *
   * \include Vector_Pitch.txt
   *
   * @returns The angle of this vector above or below the horizon (x-z plane).
   * @since 1.0
   */
  float pitch() const {
    return std::atan2(y, -z);
  }

  /**
   * The yaw angle in radians.
   *
   * Yaw is the angle between the negative z-axis and the projection of
   * the vector onto the x-z plane. In other words, yaw represents rotation
   * around the y-axis. If the vector points to the right of the negative z-axis,
   * then the returned angle is between 0 and pi radians (180 degrees);
   * if it points to the left, the angle is between 0 and -pi radians.
   *
   * \image html images/Math_Yaw_Angle.png
   *
   * \include Vector_Yaw.txt
   *
   * @returns The angle of this vector to the right or left of the negative z-axis.
   * @since 1.0
   */
  float yaw() const {
    return std::atan2(x, -z);
  }

  /**
   * The roll angle in radians.
   *
   * Roll is the angle between the y-axis and the projection of
   * the vector onto the x-y plane. In other words, roll represents rotation
   * around the z-axis. If the vector points to the left of the y-axis,
   * then the returned angle is between 0 and pi radians (180 degrees);
   * if it points to the right, the angle is between 0 and -pi radians.
   *
   * \image html images/Math_Roll_Angle.png
   *
   * Use this function to get roll angle of the plane to which this vector is a
   * normal. For example, if this vector represents the normal to the palm,
   * then this function returns the tilt or roll of the palm plane compared
   * to the horizontal (x-z) plane.
   *
   * \include Vector_Roll.txt
   *
   * @returns The angle of this vector to the right or left of the y-axis.
   * @since 1.0
   */
  float roll() const {
    return std::atan2(x, -y);
  }

  /**
   * The dot product of this vector with another vector.
   *
   * The dot product is the magnitude of the projection of this vector
   * onto the specified vector.
   *
   * \image html images/Math_Dot.png
   *
   * \include Vector_Dot.txt
   *
   * @param other A Vector object.
   * @returns The dot product of this vector and the specified vector.
   * @since 1.0
   */
  float dot(const Vector& other) const {
    return (x * other.x) + (y * other.y) + (z * other.z);
  }

  /**
   * The cross product of this vector and the specified vector.
   *
   * The cross product is a vector orthogonal to both original vectors.
   * It has a magnitude equal to the area of a parallelogram having the
   * two vectors as sides. The direction of the returned vector is
   * determined by the right-hand rule. Thus <tt>A.cross(B) == -B.cross(A).</tt>
   *
   * \image html images/Math_Cross.png
   *
   * \include Vector_Cross.txt
   *
   * @param other A Vector object.
   * @returns The cross product of this vector and the specified vector.
   * @since 1.0
   */
  Vector cross(const Vector& other) const {
    return Vector((y * other.z) - (z * other.y),
                  (z * other.x) - (x * other.z),
                  (x * other.y) - (y * other.x));
  }

  /**
   * A normalized copy of this vector.
   *
   * A normalized vector has the same direction as the original vector,
   * but with a length of one.
   *
   * \include Vector_Normalized.txt
   *
   * @returns A Vector object with a length of one, pointing in the same
   * direction as this Vector object.
   * @since 1.0
   */
  Vector normalized() const {
    float denom = this->magnitudeSquared();
    if (denom <= 0.0f) {
      return Vector::zero();
    }
    denom = 1.0f / std::sqrt(denom);
    return Vector(x * denom, y * denom, z * denom);
  }

  /**
   * A copy of this vector pointing in the opposite direction.
   *
   * \include Vector_Negate.txt
   *
   * @returns A Vector object with all components negated.
   * @since 1.0
   */
  Vector operator-() const {
    return Vector(-x, -y, -z);
  }

  /**
   * Add vectors component-wise.
   *
   * \include Vector_Plus.txt
   * @since 1.0
   */
  Vector operator+(const Vector& other) const {
    return Vector(x + other.x, y + other.y, z + other.z);
  }

  /**
   * Subtract vectors component-wise.
   *
   * \include Vector_Minus.txt
   * @since 1.0
   */
  Vector operator-(const Vector& other) const {
    return Vector(x - other.x, y - other.y, z - other.z);
  }

  /**
   * Multiply vector by a scalar.
   *
   * \include Vector_Times.txt
   * @since 1.0
   */
  Vector operator*(float scalar) const {
    return Vector(x * scalar, y * scalar, z * scalar);
  }

  /**
   * Divide vector by a scalar.
   *
   * \include Vector_Divide.txt
   * @since 1.0
   */
  Vector operator/(float scalar) const {
    return Vector(x / scalar, y / scalar, z / scalar);
  }

#if !defined(SWIG)
  /**
   * Multiply vector by a scalar on the left-hand side (C++ only).
   *
   * \include Vector_Left_Times.txt
   * @since 1.0
   */
  friend Vector operator*(float scalar, const Vector& vector) {
    return Vector(vector.x * scalar, vector.y * scalar, vector.z * scalar);
  }
#endif

  /**
   * Add vectors component-wise and assign the sum.
   * @since 1.0
   */
  Vector& operator+=(const Vector& other) {
    x += other.x;
    y += other.y;
    z += other.z;
    return *this;
  }

  /**
   * Subtract vectors component-wise and assign the difference.
   * @since 1.0
   */
  Vector& operator-=(const Vector& other) {
    x -= other.x;
    y -= other.y;
    z -= other.z;
    return *this;
  }

  /**
   * Multiply vector by a scalar and assign the product.
   * @since 1.0
   */
  Vector& operator*=(float scalar) {
    x *= scalar;
    y *= scalar;
    z *= scalar;
    return *this;
  }

  /**
   * Divide vector by a scalar and assign the quotient.
   * @since 1.0
   */
  Vector& operator/=(float scalar) {
    x /= scalar;
    y /= scalar;
    z /= scalar;
    return *this;
  }

  /**
   * Returns a string containing this vector in a human readable format: (x, y, z).
   * @since 1.0
   */
  std::string toString() const {
    std::stringstream result;
    result << "(" << x << ", " << y << ", " << z << ")";
    return result.str();
  }
  /**
   * Writes the vector to the output stream using a human readable format: (x, y, z).
   * @since 1.0
   */
  friend std::ostream& operator<<(std::ostream& out, const Vector& vector) {
    return out << vector.toString();
  }

  /**
   * Compare Vector equality component-wise.
   *
   * \include Vector_Equals.txt
   * @since 1.0
   */
  bool operator==(const Vector& other) const {
    return x == other.x && y == other.y && z == other.z;
  }
  /**
   * Compare Vector inequality component-wise.
   *
   * \include Vector_NotEqual.txt
   * @since 1.0
   */
  bool operator!=(const Vector& other) const {
    return x != other.x || y != other.y || z != other.z;
  }

  /**
   * Returns true if all of the vector's components are finite.  If any
   * component is NaN or infinite, then this returns false.
   *
   * \include Vector_IsValid.txt
   * @since 1.0
   */
  bool isValid() const {
    return (x <= FLT_MAX && x >= -FLT_MAX) &&
           (y <= FLT_MAX && y >= -FLT_MAX) &&
           (z <= FLT_MAX && z >= -FLT_MAX);
  }

  /**
   * Index vector components numerically.
   * Index 0 is x, index 1 is y, and index 2 is z.
   * @returns The x, y, or z component of this Vector, if the specified index
   * value is at least 0 and at most 2; otherwise, returns zero.
   *
   * \include Vector_Index.txt
   * @since 1.0
   */
  float operator[](unsigned int index) const {
    return index < 3 ? (&x)[index] : 0.0f;
  }

  /**
   * Cast the vector to a float array.
   *
   * \include Vector_ToFloatPointer.txt
   * @since 1.0
   */
  const float* toFloatPointer() const {
    return &x; /* Note: Assumes x, y, z are aligned in memory. */
  }

  /**
   * Convert a Leap::Vector to another 3-component Vector type.
   *
   * The specified type must define a constructor that takes the x, y, and z
   * components as separate parameters.
   * @since 1.0
   */
  template<typename Vector3Type>
  const Vector3Type toVector3() const {
    return Vector3Type(x, y, z);
  }

  /**
   * Convert a Leap::Vector to another 4-component Vector type.
   *
   * The specified type must define a constructor that takes the x, y, z, and w
   * components as separate parameters. (The homogeneous coordinate, w, is set
   * to zero by default, but you should typically set it to one for vectors
   * representing a position.)
   * @since 1.0
   */
  template<typename Vector4Type>
  const Vector4Type toVector4(float w=0.0f) const {
    return Vector4Type(x, y, z, w);
  }

  /**
   * The horizontal component.
   * @since 1.0
   */
  float x;
  /**
   * The vertical component.
   * @since 1.0
   */
  float y;
  /**
   * The depth component.
   * @since 1.0
   */
  float z;
};


/**
 * The FloatArray struct is used to allow the returning of native float arrays
 * without requiring dynamic memory allocation.  It represents a matrix
 * with a size up to 4x4.
 * @since 1.0
 */
struct FloatArray {
  /**
   * Access the elements of the float array exactly like a native array.
   * @since 1.0
   */
  float& operator[] (unsigned int index) {
    return m_array[index];
  }

  /**
   * Use the Float Array anywhere a float pointer can be used.
   * @since 1.0
   */
  operator float* () {
    return m_array;
  }

  /**
   * Use the Float Array anywhere a const float pointer can be used.
   * @since 1.0
   */
  operator const float* () const {
    return m_array;
  }

  /**
   * An array containing up to 16 entries of the matrix.
   * @since 1.0
   */
  float m_array[16];
};

/**
 * The Matrix struct represents a transformation matrix.
 *
 * To use this struct to transform a Vector, construct a matrix containing the
 * desired transformation and then use the Matrix::transformPoint() or
 * Matrix::transformDirection() functions to apply the transform.
 *
 * Transforms can be combined by multiplying two or more transform matrices using
 * the * operator.
 * @since 1.0
 */
struct Matrix
{
  /**
   * Constructs an identity transformation matrix.
   * @since 1.0
   */
  Matrix() :
    xBasis(1, 0, 0),
    yBasis(0, 1, 0),
    zBasis(0, 0, 1),
    origin(0, 0, 0) {
  }

  /**
   * Constructs a copy of the specified Matrix object.
   * @since 1.0
   */
  Matrix(const Matrix& other) :
    xBasis(other.xBasis),
    yBasis(other.yBasis),
    zBasis(other.zBasis),
    origin(other.origin) {
  }

  /**
   * Constructs a transformation matrix from the specified basis vectors.
   *
   * @param _xBasis A Vector specifying rotation and scale factors for the x-axis.
   * @param _yBasis A Vector specifying rotation and scale factors for the y-axis.
   * @param _zBasis A Vector specifying rotation and scale factors for the z-axis.
   * @since 1.0
   */
  Matrix(const Vector& _xBasis, const Vector& _yBasis, const Vector& _zBasis) :
    xBasis(_xBasis),
    yBasis(_yBasis),
    zBasis(_zBasis),
    origin(0, 0, 0) {
  }

  /**
   * Constructs a transformation matrix from the specified basis and translation vectors.
   *
   * @param _xBasis A Vector specifying rotation and scale factors for the x-axis.
   * @param _yBasis A Vector specifying rotation and scale factors for the y-axis.
   * @param _zBasis A Vector specifying rotation and scale factors for the z-axis.
   * @param _origin A Vector specifying translation factors on all three axes.
   * @since 1.0
   */
  Matrix(const Vector& _xBasis, const Vector& _yBasis, const Vector& _zBasis, const Vector& _origin) :
    xBasis(_xBasis),
    yBasis(_yBasis),
    zBasis(_zBasis),
    origin(_origin) {
  }

  /**
   * Constructs a transformation matrix specifying a rotation around the specified vector.
   *
   * @param axis A Vector specifying the axis of rotation.
   * @param angleRadians The amount of rotation in radians.
   * @since 1.0
   */
  Matrix(const Vector& axis, float angleRadians) :
    origin(0, 0, 0) {
    setRotation(axis, angleRadians);
  }

  /**
   * Constructs a transformation matrix specifying a rotation around the specified vector
   * and a translation by the specified vector.
   *
   * @param axis A Vector specifying the axis of rotation.
   * @param angleRadians The angle of rotation in radians.
   * @param translation A Vector representing the translation part of the transform.
   * @since 1.0
   */
  Matrix(const Vector& axis, float angleRadians, const Vector& translation)
    : origin(translation) {
    setRotation(axis, angleRadians);
  }

  /**
   * Returns the identity matrix specifying no translation, rotation, and scale.
   *
   * @returns The identity matrix.
   * @since 1.0
   */
  static const Matrix& identity() {
    static Matrix s_identity;
    return s_identity;
  }

  /**
   * Sets this transformation matrix to represent a rotation around the specified vector.
   *
   * This function erases any previous rotation and scale transforms applied
   * to this matrix, but does not affect translation.
   *
   * @param axis A Vector specifying the axis of rotation.
   * @param angleRadians The amount of rotation in radians.
   * @since 1.0
   */
  void setRotation(const Vector& axis, float angleRadians) {
    const Vector n = axis.normalized();
    const float s = std::sin(angleRadians);
    const float c = std::cos(angleRadians);
    const float C = (1-c);

    xBasis = Vector(n[0]*n[0]*C + c,      n[0]*n[1]*C - n[2]*s, n[0]*n[2]*C + n[1]*s);
    yBasis = Vector(n[1]*n[0]*C + n[2]*s, n[1]*n[1]*C + c,      n[1]*n[2]*C - n[0]*s);
    zBasis = Vector(n[2]*n[0]*C - n[1]*s, n[2]*n[1]*C + n[0]*s, n[2]*n[2]*C + c     );
  }

  /**
   * Transforms a vector with this matrix by transforming its rotation,
   * scale, and translation.
   *
   * Translation is applied after rotation and scale.
   *
   * @param in The Vector to transform.
   * @returns A new Vector representing the transformed original.
   * @since 1.0
   */
  Vector transformPoint(const Vector& in) const {
    return xBasis*in.x + yBasis*in.y + zBasis*in.z + origin;
  }

  /**
   * Transforms a vector with this matrix by transforming its rotation and
   * scale only.
   *
   * @param in The Vector to transform.
   * @returns A new Vector representing the transformed original.
   * @since 1.0
   */
  Vector transformDirection(const Vector& in) const {
    return xBasis*in.x + yBasis*in.y + zBasis*in.z;
  }

  /**
   * Performs a matrix inverse if the matrix consists entirely of rigid
   * transformations (translations and rotations).  If the matrix is not rigid,
   * this operation will not represent an inverse.
   *
   * Note that all matricies that are directly returned by the API are rigid.
   *
   * @returns The rigid inverse of the matrix.
   * @since 1.0
   */
  Matrix rigidInverse() const {
    Matrix rotInverse = Matrix(Vector(xBasis[0], yBasis[0], zBasis[0]),
                               Vector(xBasis[1], yBasis[1], zBasis[1]),
                               Vector(xBasis[2], yBasis[2], zBasis[2]));
    rotInverse.origin = rotInverse.transformDirection( -origin );
    return rotInverse;
  }

  /**
   * Multiply transform matrices.
   *
   * Combines two transformations into a single equivalent transformation.
   *
   * @param other A Matrix to multiply on the right hand side.
   * @returns A new Matrix representing the transformation equivalent to
   * applying the other transformation followed by this transformation.
   * @since 1.0
   */
  Matrix operator*(const Matrix& other) const {
    return Matrix(transformDirection(other.xBasis),
                  transformDirection(other.yBasis),
                  transformDirection(other.zBasis),
                  transformPoint(other.origin));
  }

  /**
   * Multiply transform matrices and assign the product.
   * @since 1.0
   */
  Matrix& operator*=(const Matrix& other) {
    return (*this) = (*this) * other;
  }

  /**
   * Compare Matrix equality component-wise.
   * @since 1.0
   */
  bool operator==(const Matrix& other) const {
    return xBasis == other.xBasis &&
           yBasis == other.yBasis &&
           zBasis == other.zBasis &&
           origin == other.origin;
  }
  /**
   * Compare Matrix inequality component-wise.
   * @since 1.0
   */
  bool operator!=(const Matrix& other) const {
    return xBasis != other.xBasis ||
           yBasis != other.yBasis ||
           zBasis != other.zBasis ||
           origin != other.origin;
  }

  /**
   * Convert a Leap::Matrix object to another 3x3 matrix type.
   *
   * The new type must define a constructor function that takes each matrix
   * element as a parameter in row-major order.
   *
   * Translation factors are discarded.
   * @since 1.0
   */
  template<typename Matrix3x3Type>
  const Matrix3x3Type toMatrix3x3() const {
    return Matrix3x3Type(xBasis.x, xBasis.y, xBasis.z,
                         yBasis.x, yBasis.y, yBasis.z,
                         zBasis.x, zBasis.y, zBasis.z);
  }

  /**
   * Convert a Leap::Matrix object to another 4x4 matrix type.
   *
   * The new type must define a constructor function that takes each matrix
   * element as a parameter in row-major order.
   * @since 1.0
   */
  template<typename Matrix4x4Type>
  const Matrix4x4Type toMatrix4x4() const {
    return Matrix4x4Type(xBasis.x, xBasis.y, xBasis.z, 0.0f,
                         yBasis.x, yBasis.y, yBasis.z, 0.0f,
                         zBasis.x, zBasis.y, zBasis.z, 0.0f,
                         origin.x, origin.y, origin.z, 1.0f);
  }

  /**
   * Writes the 3x3 Matrix object to a 9 element row-major float or
   * double array.
   *
   * Translation factors are discarded.
   *
   * Returns a pointer to the same data.
   * @since 1.0
   */
  template<typename T>
  T* toArray3x3(T* output) const {
    output[0] = xBasis.x; output[1] = xBasis.y; output[2] = xBasis.z;
    output[3] = yBasis.x; output[4] = yBasis.y; output[5] = yBasis.z;
    output[6] = zBasis.x; output[7] = zBasis.y; output[8] = zBasis.z;
    return output;
  }

  /**
   * Convert a 3x3 Matrix object to a 9 element row-major float array.
   *
   * Translation factors are discarded.
   *
   * Returns a FloatArray struct to avoid dynamic memory allocation.
   * @since 1.0
   */
  FloatArray toArray3x3() const {
    FloatArray output;
    toArray3x3((float*)output);
    return output;
  }

  /**
   * Writes the 4x4 Matrix object to a 16 element row-major float
   * or double array.
   *
   * Returns a pointer to the same data.
   * @since 1.0
   */
  template<typename T>
  T* toArray4x4(T* output) const {
    output[0]  = xBasis.x; output[1]  = xBasis.y; output[2]  = xBasis.z; output[3]  = 0.0f;
    output[4]  = yBasis.x; output[5]  = yBasis.y; output[6]  = yBasis.z; output[7]  = 0.0f;
    output[8]  = zBasis.x; output[9]  = zBasis.y; output[10] = zBasis.z; output[11] = 0.0f;
    output[12] = origin.x; output[13] = origin.y; output[14] = origin.z; output[15] = 1.0f;
    return output;
  }

  /**
   * Convert a 4x4 Matrix object to a 16 element row-major float array.
   *
   * Returns a FloatArray struct to avoid dynamic memory allocation.
   * @since 1.0
   */
  FloatArray toArray4x4() const {
    FloatArray output;
    toArray4x4((float*)output);
    return output;
  }

  /**
   * Write the matrix to a string in a human readable format.
   * @since 1.0
   */
  std::string toString() const {
    std::stringstream result;
    result << "xBasis:" << xBasis.toString() << " yBasis:" << yBasis.toString()
           << " zBasis:" << zBasis.toString() << " origin:" << origin.toString();
    return result.str();
  }

  /**
   * Write the matrix to an output stream in a human readable format.
   * @since 1.0
   */
  friend std::ostream& operator<<(std::ostream& out, const Matrix& matrix) {
    return out << matrix.toString();
  }

  /**
   * The rotation and scale factors for the x-axis.
   * @since 1.0
   */
  Vector xBasis;
  /**
   * The rotation and scale factors for the y-axis.
   * @since 1.0
   */
  Vector yBasis;
  /**
   * The rotation and scale factors for the z-axis.
   * @since 1.0
   */
  Vector zBasis;
  /**
   * The translation factors for all three axes.
   * @since 1.0
   */
  Vector origin;
};

}; // namespace Leap

#endif // __LeapMath_h__
