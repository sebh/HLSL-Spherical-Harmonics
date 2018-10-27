
// SphericalHarmonics.hlsl from https://github.com/sebh/HLSL-Spherical-Harmonics

// Great documents about spherical harmonics: 
// [1]  http://silviojemma.com/public/papers/lighting/spherical-harmonic-lighting.pdf
// [2]  https://www.ppsloan.org/publications/StupidSH36.pdf
// [3]  https://cseweb.ucsd.edu/~ravir/papers/envmap/envmap.pdf
// [4]  https://d3cw3dd2w32x2b.cloudfront.net/wp-content/uploads/2011/06/10-14.pdf
// [5]  https://github.com/kayru/Probulator
// [6]  https://www.ppsloan.org/publications/SHJCGT.pdf
// [7]  http://www.patapom.com/blog/SHPortal/
// [8]  https://grahamhazel.com/blog/2017/12/22/converting-sh-radiance-to-irradiance/
// [9]  http://www.ppsloan.org/publications/shdering.pdf
// [10] http://limbicsoft.com/volker/prosem_paper.pdf
// [11] https://bartwronski.files.wordpress.com/2014/08/bwronski_volumetric_fog_siggraph2014.pdf
//

//
//**** HOW TO PROJECT RADIANCE FROM A SPHERE INTO SH?
// 
//		// Initialise sh to 0
//		sh2 shR = shZero();
//		sh2 shG = shZero();
//		sh2 shB = shZero();
//		
//		// Accumulate coefficients according to surounding direction/color tuples.
//		for (float az = 0.5f; az < axisSampleCount; az += 1.0f)
//			for (float ze = 0.5f; ze < axisSampleCount; ze += 1.0f)
//			{
//				float3 rayDir = shGetUniformSphereSample(az / axisSampleCount, ze / axisSampleCount);
//				float3 color = [...];
//		
//				sh2 sh = shEvaluate(rayDir);
//				shR = shAdd(shR, shScale(sh, color.r));
//				shG = shAdd(shG, shScale(sh, color.g));
//				shB = shAdd(shB, shScale(sh, color.b));
//			}
//		
//		// integrating over a sphere so each sample has a weight of 4*PI/samplecount (uniform solid angle, for each sample)
//		float shFactor = 4.0 * shPI / (axisSampleCount * axisSampleCount);
//		shR = shScale(shR, shFactor );
//		shG = shScale(shG, shFactor );
//		shB = shScale(shB, shFactor );
//
//
//**** HOW TO VIZUALISE A SPHERICAL FUNCTION REPRESENTED AS SH?
//
//		sh2 shR = fromSomewhere.Load(...);
//		sh2 shG = fromSomewhere.Load(...);
//		sh2 shB = fromSomewhere.Load(...);
//		float3 rayDir = compute(...);										// the direction for which you want to know the color
//		float3 rgbColor = max(0.0f, shUnproject(shR, shG, shB, rayDir));	// A "max" is usually recomended to avoid negative values (can happen with SH)
//



#define shPI 3.1415926536f



// Generate uniform distribution of direction over a sphere. (from [1])
// azimuthX and zenithY are both in [0, 1]. You can use random value, stratified, etc.
// Top and bottom sphere pole (+-zenith) are along the Y axis.
float3 shGetUniformSphereSample(float azimuthX, float zenithY)
{
	float phi = 2.0f * shPI * azimuthX;
	float theta = 2.0f * acos(sqrt(1.0f - zenithY));
	float3 dir = float3(sin(theta)*cos(phi), cos(theta), sin(theta)*sin(phi)); 
	return dir;
}



#define sh2 float4
// TODO sh3

sh2 shZero()
{
	return float4(0.0f, 0.0f, 0.0f, 0.0f);
}

// Evaluate spherical harmonics from direction. (from [2] Appendix A2)
// (evaluating the associated legendre polynomial using the polynomial form)
sh2 shEvaluate(float3 dir)
{
	sh2 result;
	result.x = 0.28209479177387814347403972578039f;			// L=0 , M= 0
	result.y =-0.48860251190291992158638462283836f * dir.y;	// L=1 , M=-1
	result.z = 0.48860251190291992158638462283836f * dir.z;	// L=1 , M= 0
	result.w =-0.48860251190291992158638462283836f * dir.x;	// L=1 , M= 1
	return result;
}

// Recover the value of a function represented as SH in the direction dir.
float shUnproject(sh2 functionSh, float3 dir)
{
	sh2 sh = shEvaluate(dir);
	return dot(functionSh, sh);
}
float3 shUnproject(sh2 functionShX, sh2 functionShY, sh2 functionShZ, float3 dir)
{
	sh2 sh = shEvaluate(dir);
	return float3(dot(functionShX, sh), dot(functionShY, sh), dot(functionShZ, sh));
}

// Project a cosine lobe function, with peak value in direction dir, into SH (from [4])
// Integral over unit sphere is PI.
sh2 shEvaluateCosineLobe(float3 dir)
{
	sh2 result;
	result.x = 0.8862269254527580137f;			// L=0 , M= 0
	result.y =-1.0233267079464884885f * dir.y;	// L=1 , M=-1
	result.z = 1.0233267079464884885f * dir.z;	// L=1 , M= 0
	result.w =-1.0233267079464884885f * dir.x;	// L=1 , M= 1
	return result;
}

// Project a Henyey-Greenstein phase function, with peak value in direction dir, into SH. (from [11])
// Integral over unit sphere is 1.
sh2 evaluatePhaseHG(float3 dir, float g)
{
	sh2 result;
	const float factor = 0.48860251190291992158638462283836 * g;
	result.x = 0.28209479177387814347403972578039;	// L=0 , M= 0
	result.y =-factor * dir.y;						// L=1 , M=-1
	result.z = factor * dir.z;						// L=1 , M= 0
	result.w =-factor * dir.x;						// L=1 , M= 1
	return result;
}

// Adds two functions represented by SH coefficients
sh2 shAdd(sh2 shL, sh2 shR)
{
	return shL + shR;
}

// Scale a function uniformly
sh2 shScale(sh2 sh, float v)
{
	return sh * v;
}

// Operate a rotation of the function represented by SH.
sh2 shRotate(sh2 sh, float3x3 rotation)
{
	// TODO verify and optimize
	sh2 result;
	result.x = sh.x;
	float3 tmp = float3(sh.w, sh.y, sh.z);		// undo direction component shuffle to match source/function space
	result.yzw = mul(tmp, rotation).yzx;		// apply rotation and re-shuffle
	return result;
}

// Integrate the product of two functions a and b represented by SH coefficients
float shFuncProductIntegral(sh2 shL, sh2 shR)
{
	return dot(shL, shR);
}

// Compute the SH coefficients of the projection of two functions that have been multiplied (from [4])
sh2 shProduct(sh2 shL, sh2 shR)
{
	const float factor = 1.0f / (2.0f * sqrt(shPI));
	return factor * sh2(
		shL.x*shR.w + shL.w+shR.x,
		shL.y*shR.w + shL.w*shR.y,
		shL.z*shR.w + shL.w*shR.z,
		dot(shL,shR)
	);
}

// Convolve the function using a Hanning filtering. This helps reducing ringing and negative values. (from [2], Windowing p.16)
// A lower value of w will reduce ringing (like the width of a filter)
sh2 shHanningConvolution( sh2 sh, float w ) 
{
	sh2 result = sh;
	float invW = 1.0 / w;
	float factorBand1 =(1.0 + cos( shPI * invW )) / 2.0f;
	result.y *= factorBand1;
	result.z *= factorBand1;
	result.w *= factorBand1;
	return result;
}

// Convolve the sh using a cosine lob. This is interesting to transform radiance to irradiance. (from [3], eq.7 & eq.8)
sh2 shDiffuseConvolution(sh2 sh)
{
	sh2 result = sh;
	// L0
	result.x   *= shPI;
	// L1
	result.yzw *= 2.0943951023931954923f;
	return result;
}


