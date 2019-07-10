import std.math;
import std.conv;
import std.stdio;
import std.typecons;

struct vec3
{
public:
  this(float e0, float e1, float e2) { e[0] = e0; e[1] = e1; e[2] = e2; }
  pragma(inline, true)
  {
    float x() { return e[0]; }
    float y() { return e[1]; }
    float z() { return e[2]; }
    float r() { return e[0]; }
    float g() { return e[1]; }
    float b() { return e[2]; }
    vec3 opUnary(string op)() if (op == "+") { return *this; }
    vec3 opUnary(string op)() if (op == "-") { return vec3(-e[0], -e[1], -e[2]); }
    float opIndex(size_t i) { return e[i]; }
    float opIndex(size_t i) { return e[i]; }

    float length() { return sqrt(e[0]*e[0] + e[1]*e[1] + e[2]*e[2]); }
    float squared_length() { return e[0]*e[0] + e[1]*e[1] + e[2]*e[2]; }

    vec3 unit_vector()
    {
      return this / this.length();
    }

    void make_unit_vector()
    {
      float l = 1.0 / sqrt(e[0]*e[0] + e[1]*e[1] + e[2]*e[2]);
      e[0] *= l;
      e[1] *= l;
      e[2] *= l;
    };

    vec3 opBinary(string op)(vec3 rhs)
    {
      if (op == "+") return vec3(e[0] + rhs.e[0], e[1] + rhs.e[1], e[2] + rhs.e[2]); 
      else if (op == "-") return vec3(e[0] - rhs.e[0], e[1] - rhs.e[1], e[2] - rhs.e[2]);
      else if (op == "*") return vec3(e[0] * rhs.e[0], e[1] * rhs.e[1], e[2] * rhs.e[2]);
      else if (op == "/") return vec3(e[0] / rhs.e[0], e[1] / rhs.e[1], e[2] / rhs.e[2]);
      else assert(0, "Operator "~op~" not implemented");
    }

    vec3 opBinary(string op)(float rhs)
    {
      if (op == "*") return vec3(e[0] * rhs, e[1] * rhs, e[2] * rhs);
      if (op == "/") return vec3(e[0] / rhs, e[1] / rhs, e[2] / rhs);
      else assert(0, "Operator "~op~" not implemented");
    }

    vec3 opBinaryRight(string op)(float lhs)
    {
      if (op == "*") return vec3(e[0] * lhs, e[1] * lhs, e[2] * lhs);
      if (op == "/") return vec3(lhs / e[0], lhs / e[1], lhs / e[2]);
      else assert(0, "Operator "~op~" not implemented");
    }

    float dot(vec3 v) { return e[0] * v.x + e[1] * v.y + e[2] * v.z; } 
    vec3 cross(vec3 v) { return vec3( (this.e[1] * v.e[2] - this.e[2] * v.e[1]),
					  (-(this.e[0] * v.e[2] - this.e[2] * v.e[0])),
					  (this.e[0] * v.e[1] - this.e[1] * v.e[0]) ); }
  }

private:
  float[3] e;
}

struct ray
{
public:
  this(vec3 origin, vec3 direction) { a = origin; b = direction; }
  pragma(inline, true)
  {
    vec3 point_at_parameter(float t) { return a + t*b; }
    vec3 origin() { return a; }
    vec3 direction() { return b; }
    vec3 a;
    vec3 b;
  }
}

struct hit_record {
  float t;
  vec3 p;
  vec3 normal;
}

abstract class hitable {
public:
  Nullable!hit_record hit(ray r, float t_min, float t_max);
}

class sphere: hitable {
public:
  this() {}
  this(vec3 cen, float r) { centre = cen; radius = r; };
  override Nullable!hit_record hit(ray r, float t_min, float t_max) {
    Nullable!hit_record rec;
    vec3 oc = r.origin - centre;
    float a = r.direction.dot(r.direction);
    float b = r.direction.dot(oc);
    float c = oc.dot(oc) - radius * radius;
    float discriminant = b*b - a*c;
    if (discriminant > 0.0)
      {
	float temp = (-b - sqrt(b*b - a*c))/a;
	if (temp < t_max && temp > t_min) {
	  rec = hit_record().nullable;
	  rec.get.t = temp;
	  rec.get.p = r.point_at_parameter(rec.get.t);
	  rec.get.normal = (rec.get.p - centre) / radius;
	  return rec;
	}
	temp = (-b + sqrt(b*b - a*c))/a;
	if (temp < t_max && temp > t_min) {
	  rec = hit_record().nullable;
	  rec.get.t = temp;
	  rec.get.p = r.point_at_parameter(rec.get.t);
	  rec.get.normal = (rec.get.p - centre) / radius;
	  return rec;
	}
      }
    return rec;
  };
  vec3 centre;
  float radius;
}

class hitable_list : hitable {
public:
  this() {}
  this(hitable[] l) { list = l; }
  override Nullable!hit_record hit(ray r, float t_min, float t_max) {
    Nullable!hit_record temp_rec;
    float closest_so_far = t_max;
    foreach (hitable h; list) {
      auto this_rec = h.hit(r, t_min, closest_so_far);
      if (!this_rec.isNull) {
	closest_so_far = this_rec.get.t;
	temp_rec = this_rec;
      }
    }
    return temp_rec;
  }
  hitable[] list;
}

vec3 color(ray r, hitable world)
{
  auto hit = world.hit(r, 0, 100.0);
  if (!hit.isNull) {
    return 0.5*vec3(hit.normal.x + 1, hit.normal.y + 1, hit.normal.z + 1);
  } else {
    vec3 unit_direction = r.direction.unit_vector;
    float t = 0.5*(unit_direction.y + 1);
    return (1-t)*vec3(1, 1, 1) + t*vec3(0.5, 0.7, 1);
  }
}

vec3 lower_left_corner = vec3(-2.0, -1.0, -1.0);
vec3 horizontal = vec3(4.0, 0.0, 0.0);
vec3 vertical = vec3(0.0, 2.0, 0.0);
vec3 origin = vec3(0.0, 0.0, 0.0);

public void colour_pixel(shared(uint)* pixel, float u, float v, hitable world)
{
  ray r = ray(origin, lower_left_corner + u*horizontal + v*vertical);
  vec3 col = color(r, world);

  *pixel = (to!uint(col.r * 0xff) << 16) + (to!uint(col.g * 0xff) << 8) + to!uint(col.b * 0xff);
}
