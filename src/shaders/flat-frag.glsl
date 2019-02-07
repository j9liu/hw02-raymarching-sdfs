#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;

in vec2 fs_Pos;
out vec4 out_Col;

// Define color/shader IDs.
#define BACKGROUND 0

// Get the ray that goes through this fragment shader position
vec3 rayCast() {
  vec3 forward = normalize(u_Ref - u_Eye);
  vec3 right = cross(forward, u_Up);
  vec3 up = cross(right, forward);
  float len = length(u_Ref - u_Eye);

  vec3 v = up * len * tan(22.5f);
  vec3 h = right * len * (u_Dimensions.x / u_Dimensions.y) * tan(22.5f);
  vec3 p = u_Ref + fs_Pos.x * h + fs_Pos.y * v;
  return normalize(p - u_Eye);
}

// Define the SDFs of this scene
float sphereSDF(vec3 p, float r) {
	return length(p) - r;
}

float bowlSDF(vec3 p, float h, float r1, float r2) {
	vec2 q = vec2(length(p.xz), p.y);
    vec2 k1 = vec2(r2,h);
    vec2 k2 = vec2(r2 - r1, 2.0 * h);
    vec2 ca = vec2(q.x - min(q.x,(q.y < 0.0)?r1:r2), abs(q.y)-h);
    vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot(k2, k2), 0.0, 1.0 );
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s * sqrt( min(dot(ca, ca),dot(cb, cb)) );
}

float opUnion(float d1, float d2) {
	return min(d1, d2);
}

float opSubtraction(float d1, float d2) {
	return max(-d1, d2);
}

float opIntersection(float d1, float d2) {
	return max(d1, d2);
}

float sceneSDF(vec3 p) {
    return bowlSDF(p, 1.0f, 1.0f, 5.0f);
}

#define epsilon 0.0005f
vec3 getNormal(vec3 p) {
	return normalize(vec3(sceneSDF(vec3(p.x + epsilon, p.y, p.z))
						- sceneSDF(vec3(p.x - epsilon, p.y, p.z)),
						  sceneSDF(vec3(p.x, p.y + epsilon, p.z))
					    - sceneSDF(vec3(p.x, p.y - epsilon, p.z)),
					      sceneSDF(vec3(p.x, p.y, p.z + epsilon))
					    - sceneSDF(vec3(p.x, p.y, p.z - epsilon))));
}

vec4 getColor(int id, vec3 position) {
	switch(id) {
		case BACKGROUND:
			return vec4(mix(vec3(fs_Pos.xy, fs_Pos.x) / 5.0f, vec3(25.0f, 17.0f, 51.0f) / 255.0, vec3(104.0f, 12.0f, 69.0f)/255.0f), 1.0f);
		default:
			return vec4(vec3(.4f), 1.0f);
	}
}

// March along the ray
#define max_steps 15
#define cutoff 1000.0f
void march(vec3 direction) {
	float t = 0.0f;
	int temp = 1;
	vec3 pos;
	for(int i = 0; i < max_steps; i++) {
		pos = u_Eye + t * direction;
		float dist = sceneSDF(pos);
		if(dist < 0.001) {
			out_Col = getColor(1, pos);
			return;
		}

		t += dist;

		if(t >= cutoff) {
			out_Col = getColor(0, pos);
			return;
		}
	}
}

void main() {
  vec3 dir = rayCast();
  march(dir);
}
