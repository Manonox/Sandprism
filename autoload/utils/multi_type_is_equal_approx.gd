extends Node
class_name MultiTypeIsEqualApprox



const _has_is_equal_approx_types := [
	TYPE_VECTOR2,
	TYPE_RECT2,
	TYPE_VECTOR3,
	TYPE_TRANSFORM2D,
	TYPE_VECTOR4,
	TYPE_PLANE,
	TYPE_QUATERNION,
	TYPE_AABB,
	TYPE_BASIS,
	TYPE_TRANSFORM3D,
	TYPE_COLOR
]


static func is_equal_approx(a, b) -> bool:
	var type := typeof(a)
	assert(type == typeof(b))
	match type:
		TYPE_FLOAT:
			return is_equal_approx(a, b)
		TYPE_VECTOR2, TYPE_RECT2, TYPE_VECTOR3, TYPE_TRANSFORM2D, TYPE_VECTOR4, TYPE_PLANE, TYPE_QUATERNION, TYPE_AABB, TYPE_BASIS, TYPE_TRANSFORM3D, TYPE_COLOR:
			#print(a, b, a.is_equal_approx(b))
			return a.is_equal_approx(b)
		_:
			return a == b
