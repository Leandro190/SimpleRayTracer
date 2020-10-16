#version 330

in vec2 uv;
uniform sampler2D planeTex;
out vec4 color;

#define M_PI 3.141592653589793
#define epsilon 0.0001f
#define saturate(x) clamp(x, 0, 1)

const vec3 eyePosition = vec3(0, 0, 0);
const float fovHalfAngle = M_PI / 8;

const vec3 planePoint = vec3(0, -1, -4);
const vec3 planeNormal = normalize(vec3(0, 1, 1));
const vec3 planeTangent = normalize(vec3(1, 0, 0));
const vec3 planeBitangent = normalize(vec3(0, 1, -1));

const vec3 sphereCenter = vec3(0, 0, -4);
const float sphereRadius = 0.75;

const vec3 beamCenter = vec3(5, 5, 5);
const float beamWidth = 2;
const float beamIntensity = 300;

const vec3 sphereColor = vec3(0.8, 0.8, 0.8);
const vec3 lightColor = vec3(1, 1, 1);

const float sphereReflectivity = 0.8;
const float planeReflectivity = 0.1;

//returns texture coordinates for a given point on the plane
vec2 getPlaneTexCoords(vec3 contactPoint)
{
	vec3 disp = contactPoint - planePoint;
	return 0.2 * vec2(dot(disp, planeTangent), 1 - dot(disp, planeBitangent));
}

//suggested helper functions

bool rayPlaneIntersection(vec3 rayOrigin, vec3 rayDir,
	out vec3 contactPoint)
{

}

bool raySphereIntersection(vec3 rayOrigin, vec3 rayDir,
	out vec3 contactPoint, out vec3 contactNormal)
{
	// Find vector between origin and center of sphere
	// then calculate it's projection on the ray (From (O)rigin to projected point P)
	vec3 originToCenter = sphereCenter - rayOrigin;
	float OToP = dot(originToCenter, rayDir);

	// Check if sphere isn't behind ray's origin
	//(if false, then sphere is in front of the origin but the intersection is not guaranteed)
	if(OToP < 0)
	{
		return false;
	}

	// Calculate distance between sphere's center and the ray
	d2 = dot(originToCenter, originToCenter) - OToP*OToP;

	// Check if the ray actually intersects with sphere
	//(if false, then the distance is less than the radius so there is an intersection)
	if(d2 > sphereRadius*sphereRadius)
	{
		return false;
	}

	// Calculate distance between the the intersection point I1 and
	//the projected point P (projection of the sphere's center on the ray)
	float I1ToP = sqrt(sphereRadius*sphereRadius - d2);

	// Calculate distance between origin and first intersection I1
	float OToI1 = OToP - I1ToP;

	// Calculate contact point
	contactPoint = rayOrigin + (OToI1 * rayDir);

	// Calculate Normal
	contactNormal = normalize(contactPoint - sphereCenter);

	return true;
}

vec3 getOneBounceColor(vec3 rayDir, vec3 contactPoint, vec3 contactNormal, vec3 lightPos, bool sphere);

vec3 getTwoBounceColor(vec3 rayDir, vec3 contactPoint, vec3 contactNormal, vec3 lightPos, bool sphere);

void main()
{
	color = vec4(0, 0, 0, 1);
	const float divideBy = 400;

	vec3 incomingRayDirection = -normalize(vec3(uv * fovHalfAngle, -1.0));

	//TODO
	

	color.rgb = saturate(color.rgb / divideBy);
}