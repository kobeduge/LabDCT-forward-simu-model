# LabDCT forward simulation model
Code for simulating diffraction patterns of laboratory X-ray diffraction contrast tomography (LabDCT).
Comparison between simulated and experimental projections are also available.
The scripts may be continuously updated as work progresses.

# Preparations for running the code
Installing external Matlab toolboxes that are freely accessible:
1. DIPimage: http://www.diplib.org/, for image processing.
2. Multi-Parametric Toolbox 3 (mpt3): https://www.mpt3.org/, for generating Voronoi cells and polyheron mesh in 3D.
3. MTEX toolbox: https://mtex-toolbox.github.io/, for analyzing and plotting crystallographic data.

For convenience, I have attached the DIPimage 2.9, mtex 5.1.1 and mpt3 scripts in the folder.
One can just colone the whole master file for running the code without the need to download these toolboxes.

It is also recommended to have 'computer vision system toolbox' installed with your own Matlab package.

All the codes have been tested executable with Matlab 2014b or above.
However, it is preferentially to run the code with a Matlab version 2018b or later.

# How to run the code
## step 1 - run 'input_main.m'
This step is to setup grain structure input, which can be either virtual rendered grain structure or from experimentally characterized structure written in h5 file. One can change values of variables 'grain_file' and 'grain_flag' to modify input option.

## step 2 - run 'diffLabDCTsim_poly_3Dmesh.m'
This requires input from step 1 to run the simulations of diffraction images.
Note to remember check the experimental parameter defined in 'exp_parameters.m'.
Images will be saved in the '\TFT\' folder and data saved in the '\DA\' folder.

If the meshed input structure already exists, one can skip the first step and directly run 'diffLabDCTsim_poly_3Dmesh_abs_DQE.m'.

# Others
If you wish to compare the simulated diffraction image with the experimental one as well as analyzing experimental LabDCT data.
You can run 'diffLabDCTsim_poly_3Dmesh_comp_exp_v3_abs_DQE.m' provided you have the meshed input of the experimental grain structure
and also the experimental diffraction images, which by default named as 'proj0000.tiff' alike.

The output images will be saved in the '\TFT_cmp\' folder and data saved in the '\DA_cmp\' folder.

Examples of input and one experimental LabDCT projection image can be found in the '\Examples\' folder.

# Remind
Always start with simulations for one projection at a certain rotation angle before running simulations for a whole dataset, e.g. 181 projections for a full rotation of 360 degrees.

# License
This package is free to use, ditribute and adapt for non-commercial use only.
See the __LICENSE__ file for license rights and limitations(CC BY-NC 4.0)


## Contact via hfang@mek.dtu.dk or haixingfang868@gmail.com

