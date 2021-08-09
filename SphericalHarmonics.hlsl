
// SphericalHarmonics.hlsl from https://github.com/sebh/HLSL-Spherical-Harmonics

// Great documents about spherical harmonics: 
// [1]  http://www.cse.chalmers.se/~uffe/xjobb/Readings/GlobalIllumination/Spherical%20Harmonic%20Lighting%20-%20the%20gritty%20details.pdf
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
// Provided functions are commented. A "SH function" means a "spherical function represented as spherical harmonics".
// You can also find a FAQ below.
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



#ifndef SPHERICAL_HARMONICS_HLSL
#define SPHERICAL_HARMONICS_HLSL



#define shPI 3.1415926536f



// Generates a uniform distribution of directions over a unit sphere. 
// Adapted from http://www.pbr-book.org/3ed-2018/Monte_Carlo_Integration/2D_Sampling_with_Multidimensional_Transformations.html#fragment-SamplingFunctionDefinitions-6
// azimuthX and zenithY are both in [0, 1]. You can use random value, stratified, etc.
// Top and bottom sphere pole (+-zenith) are along the Y axis.
float3 shGetUniformSphereSample(float azimuthX, float zenithY)
{
	float phi = 2.0f * shPI * azimuthX;
	float z = 1.0f - 2.0f * zenithY;
	float r = sqrt(max(0.0f, 1.0f - z * z));
	return float3(r * cos(phi), z, r * sin(phi));
}



#define sh2 float4
// TODO sh3

sh2 shZero()
{
	return float4(0.0f, 0.0f, 0.0f, 0.0f);
}

// Evaluates spherical harmonics basis for a direction dir.
// This follows [2] Appendix A2 order when storing in x, y, z and w.
// (evaluating the associated Legendre polynomials using the polynomial forms)
sh2 shEvaluate(float3 dir)
{
	sh2 result;
	result.x = 0.28209479177387814347403972578039f;			// L=0 , M= 0
	result.y =-0.48860251190291992158638462283836f * dir.y;	// L=1 , M=-1
	result.z = 0.48860251190291992158638462283836f * dir.z;	// L=1 , M= 0
	result.w =-0.48860251190291992158638462283836f * dir.x;	// L=1 , M= 1
	return result;
}

// Recovers the value of a SH function in the direction dir.
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

// Projects a cosine lobe function, with peak value in direction dir, into SH. (from [4])
// The integral over the unit sphere of the SH representation is PI.
sh2 shEvaluateCosineLobe(float3 dir)
{
	sh2 result;
	result.x = 0.8862269254527580137f;			// L=0 , M= 0
	result.y =-1.0233267079464884885f * dir.y;	// L=1 , M=-1
	result.z = 1.0233267079464884885f * dir.z;	// L=1 , M= 0
	result.w =-1.0233267079464884885f * dir.x;	// L=1 , M= 1
	return result;
}

// Projects a Henyey-Greenstein phase function, with peak value in direction dir, into SH. (from [11])
// The integral over the unit sphere of the SH representation is 1.
sh2 shEvaluatePhaseHG(float3 dir, float g)
{
	sh2 result;
	const float factor = 0.48860251190291992158638462283836 * g;
	result.x = 0.28209479177387814347403972578039;	// L=0 , M= 0
	result.y =-factor * dir.y;						// L=1 , M=-1
	result.z = factor * dir.z;						// L=1 , M= 0
	result.w =-factor * dir.x;						// L=1 , M= 1
	return result;
}

// Adds two SH functions together.
sh2 shAdd(sh2 shL, sh2 shR)
{
	return shL + shR;
}

// Scales a SH function uniformly by v.
sh2 shScale(sh2 sh, float v)
{
	return sh * v;
}

// Operates a rotation of a SH function.
sh2 shRotate(sh2 sh, float3x3 rotation)
{
	// TODO verify and optimize
	sh2 result;
	result.x = sh.x;
	float3 tmp = float3(sh.w, sh.y, sh.z);		// undo direction component shuffle to match source/function space
	result.yzw = mul(tmp, rotation).yzx;		// apply rotation and re-shuffle
	return result;
}

// Integrates the product of two SH functions over the unit sphere.
float shFuncProductIntegral(sh2 shL, sh2 shR)
{
	return dot(shL, shR);
}

// Computes the SH coefficients of a SH function representing the result of the multiplication of two SH functions. (from [4])
// If sources have N bands, this product will result in 2N*1 bands as signal multiplication can add frequencies (think about two lobes intersecting).
// To avoid that, the result can be truncated to N bands. It will just have a lower frequency, i.e. less details. (from [2], SH Products p.7)
// Note: - the code from [4] has been adapted to match the mapping from [2] we use. 
//		 - !!! Be aware that this code has note yet be tested !!!
sh2 shProduct(sh2 shL, sh2 shR)
{
	const float factor = 1.0f / (2.0f * sqrt(shPI));
	return factor * sh2(
		dot(shL, shR),
		shL.y*shR.w + shL.w*shR.y,
		shL.z*shR.w + shL.w*shR.z,
		shL.w*shR.w + shL.w*shR.w,
	);
}

// Convolves a SH function using a Hanning filtering. This helps reducing ringing and negative values. (from [2], Windowing p.16)
// A lower value of w will reduce ringing (like the frequency of a filter)
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

// Convolves a SH function using a cosine lob. This is tipically used to transform radiance to irradiance. (from [3], eq.7 & eq.8)
sh2 shDiffuseConvolution(sh2 sh)
{
	sh2 result = sh;
	// L0
	result.x   *= shPI;
	// L1
	result.yzw *= 2.0943951023931954923f;
	return result;
}



#endif // SPHERICAL_HARMONICS_HLSL


