# HLSL-Spherical-Harmonics

## Description

A collection of HLSL functions one can include to use spherical harmonics in shaders.
This is practical when generating and consuming SH on the GPU. 

Using Git, this repository can be integrated in your project as a _submodule_.

Files description:
* SphericalHarmonics.hlsl: the HLSL file containing all the SH functions.
* sh2.nb : A Mathematica notebook to verify and visualize SH functions correctness.
* sh2.pdf: A compiled pdf to simply read sh2.nb.

## Examples

<a href="https://twitter.com/SebHillaire/status/1054010642523480064" target="blank">Precomputed occlusion as SH</a> for cloud ambient lighting. Result as <a href="https://twitter.com/SebHillaire/status/1054358976043892736" target="blank">video</a> and as images (1st image: directional occlusion as SH, 2nd image: final cloud render):

<img src="https://pbs.twimg.com/media/DqCYBNTX0AEFlF_.jpg" alt="cloud" width="346px"/>
<img src="https://pbs.twimg.com/media/DqCYHtYXcAELUkR.jpg" alt="cloud" width="400px"/>   

## Future

* As of today, only 2nd order SH functions are provided. 3rd order SH could be added.
* Do not hesitate to send suggestions or improvements.