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

// Light parameters
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
	// Dot product between ray and plane normal
	float denom = dot(planeNormal, rayDir);

	// Check if bigger than zero, if false then the ray and plane are parallel
	if(denom > 0)
	{
		// Get vector from ray origin to plane
		vec3 rayToPlane = planePoint - rayOrigin;
		
		// Calculate distance from ray to intersection point (based on equation)
		float dist = dot(rayToPlane, planeNormal) / denom;
		
		// Calculate contact point
		contactPoint = rayOrigin + (dist * rayDir);
		
		// Return true if distance isn't negative (i.e. plane is behind ray origin/eye)
		return (abs(dist) >= 0);
	}

	return false;
}

bool raySphereIntersection(vec3 rayOrigin, vec3 rayDir,
	out vec3 contactPoint, out vec3 contactNormal)
{
	// Find vector between origin and center of sphere
	// then calculate it's projection on the ray (From (O)rigin to projected point P)
	vec3 originToCenter = sphereCenter - rayOrigin;
	float oToP = dot(originToCenter, rayDir);

	// Check if sphere isn't behind ray's origin
	//(if false, then sphere is in front of the origin but the intersection is not guaranteed)
	if(oToP > 0)
	{
		return false;
	}

	// Calculate distance between sphere's center and the ray
	float d2 = dot(originToCenter, originToCenter) - oToP*oToP;

	// Check if the ray actually intersects with sphere
	//(if false, then the distance is less than the radius so there is an intersection)
	if(d2 > sphereRadius*sphereRadius)
	{
		return false;
	}

	// Calculate distance between the the intersection point I1 and
	//the projected point P (projection of the sphere's center on the ray)
	float i1ToP = sqrt(sphereRadius*sphereRadius - d2);

	// Calculate distance between origin and first intersection I1
	float oToI1 = oToP - i1ToP;
	// Calculate distance between origin and second intersection I2
	float oToI2 = oToP + i1ToP;

	// Calculate which point is closer to camera/eye
	if(abs(oToI2) < abs(oToI1))
	{
		oToI1 = oToI2;
	}

	// Calculate contact point
	contactPoint = rayOrigin + (oToI1 * rayDir);

	// Calculate Normal
	contactNormal = normalize(contactPoint - sphereCenter);

	return true;
}

vec3 getTwoBounceColor(vec3 rayDir, vec3 contactPoint, vec3 contactNormal, vec3 lightPos, bool sphere)
{
	// Find reflect
	vec3 reflectDir = normalize(reflect(rayDir, contactNormal));
	vec3 reflectCont, reflectNormal;


	if(sphere)
	{
		if(rayPlaneIntersection(contactPoint, reflectDir, reflectCont))
		{
			// Get light direction from contactPoint to lightPos then normalize
			vec3 lightDir = normalize(lightPos - reflectCont);
			// Get distance from contact point to light to determine intensity
			float dist = distance(reflectCont, lightPos);
			// Calculate total intensity
			float diffusiveLight = (beamIntensity * max(0, dot(lightDir, planeNormal))) / (dist*dist);


			vec4 planeTex = texture(planeTex, getPlaneTexCoords(reflectCont));

			return (vec3(planeTex.x,planeTex.y,planeTex.z) * sphereReflectivity);
		}
		else
		{
			// If no intersections return background color
			return vec3(1,1,1);
		}
	}
	else
	{
		// Check intersections
		if(raySphereIntersection(contactPoint, reflectDir, reflectCont, reflectNormal))
		{
			// Get light direction from contactPoint to lightPos then normalize
			vec3 lightDir = normalize(lightPos - reflectCont);
			// Get distance from contact point to light to determine intensity
			float dist = distance(reflectCont, lightPos);
			// Calculate total intensity
			float diffusiveLight = (beamIntensity * max(0, dot(lightDir, reflectNormal))) / (dist*dist);

			return (sphereColor * planeReflectivity) + diffusiveLight;
		}
		else
		{
			// If no intersections return background color
			return vec3(1,1,1);
		}
	}
}

vec3 getOneBounceColor(vec3 rayDir, vec3 contactPoint, vec3 contactNormal, vec3 lightPos, bool sphere)
{
	// Get light direction from contactPoint to lightPos then normalize
	vec3 lightDir = normalize(lightPos - contactPoint);
	// Get distance from contact point to light to determine intensity
	float dist = distance(contactPoint, lightPos);
	// Calculate total intensity
	float diffusiveLight = (beamIntensity * max(0, dot(lightDir, contactNormal))) / (dist*dist);
	
	// Specular lighting
	// Calculate reflection vector
	vec3 R = reflect(lightDir, contactNormal);

	// Return color based on being sphere or not
	if(sphere)
	{
		// Calculate specular intensity
		float specular = (beamIntensity * pow(max(0, dot(R, -rayDir)), sphereReflectivity)) / (dist*dist);
		return (sphereColor * diffusiveLight * specular * lightColor) * getTwoBounceColor(rayDir, contactPoint, contactNormal, lightPos, sphere);
	}
	else
	{
		// Calculate specular intensity
		float specular = (beamIntensity * pow(max(0, dot(R, -rayDir)), planeReflectivity)) / (dist*dist);
		// Calculate shadow
		vec3 shadowRay = normalize(lightPos - contactPoint);
		vec3 shadowCont, shadowNormal;
		if(raySphereIntersection(contactPoint, -shadowRay, shadowCont, shadowNormal))
		{
			diffusiveLight = 0;
		}

		return (diffusiveLight * specular * lightColor) * getTwoBounceColor(rayDir, contactPoint, contactNormal, lightPos, sphere);
	}
}

void main()
{
	color = vec4(0, 0, 0, 1);
	const float divideBy = 400;

	vec3 incomingRayDirection = -normalize(vec3(uv * fovHalfAngle, -1.0));

	vec3 contPoint;
	vec3 contPointNormal;

	//TODO
	if(raySphereIntersection(eyePosition, incomingRayDirection, contPoint, contPointNormal))
	{
		// TODO: make this loop with values from beamCenter
		for(float i = 3; i <= 7; i+=0.5)
		{
			for(float j = 3; j <= 7; j+=0.5)
			{
				vec3 light = vec3(i,j,5);
				vec3 oneBounce = getOneBounceColor(incomingRayDirection, contPoint, contPointNormal, light, true);
				color += vec4(oneBounce, 1);
			}
		}
	}
	else if(rayPlaneIntersection(eyePosition, incomingRayDirection, contPoint))
	{
		// TODO: make this loop with values from beamCenter
		for(float i = 3; i <= 7; i+=0.5)
		{
			for(float j = 3; j <= 7; j+=0.5)
			{
				vec3 light = vec3(i,j,5);
				vec3 oneBounce = getOneBounceColor(incomingRayDirection, contPoint, planeNormal, light, false);
				vec4 planeTex = texture(planeTex, getPlaneTexCoords(contPoint));
				color += planeTex * vec4(oneBounce,1);
			}
		}
	}

	color.rgb = saturate(color.rgb / divideBy);
}