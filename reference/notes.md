## Background Information
### Paper #1: [Virtual laser scanning with HELIOS++: A novel take on ray tracing-based simulation of topographic full-waveform 3D laser scanning](https://arxiv.org/pdf/2101.09154.pdf)
#### Summary
HELIOS++ is an open-source, general purpose laser-scanning simulation tool. HELIOS++ is capable of performing static and mobile terrestrial LiDAR simulation and UAV and airborne LiDAR scanning. The authors have managed to get their software to perform well enough to run simulations with it, and have proved that LiDAR simulation software is useful for the four following reasons: data acquisition, method evaluation, method training, and sensing experimentation. The simulation relies on two premises in order to be effective: there exists an adequate 3D model of the scene and the scanner, and the world to beam interactions can be reduced to a computationally feasible yet physically realistic process. HELIOS++ supports sensors for static tripods, ground vehicles, multicopters, and airplanes. There are a number of virtual laser scanning softwares that already exist for various platforms, including satellites, airborne laser simulation, mobile laser simulation, terrestrial laser simulation, UAV laser simulation, and more.
#### Takeaways
Some interesting features to look at are including satellite, material simulation, ROS integration. Overall, they give an extensive background to the field and why this is a useful piece of software. In terms of evaluation, they mostly use proven simulation methods, but do concede that no simulation that is fast will also be accurate, and that is solely dependent on the complexity of the scene. The evaluation was mostly focused on crude data output within a certain timeframe.
### Paper #2: [LiDARsim: Realistic LiDAR Simulation by Leveraging the Real World](https://arxiv.org/pdf/2006.09348.pdf)
#### Summary
The main problem this paper aims to fix is that LiDAR simulations are not inherently accurate. Many aspects of the real world are not present in simulation, and using a deep neural network, they are able to produce deviations to the simulation to further the accuracy of the simulation. This paper mainly focuses on self driving vehicles. A problem they point out is that most simulation software focuses on the trajectory and controls, but not the synthetic sensory input. Accurate sensor input would allow for end to end testing in simulation. They discuss the process of simulating a real sensor, which is prone to “ray dropping” and other various forms of noise that depend on materials and more. They evaluate their model with the KITTI Vision benchmark suite.
#### Takeaways
A data driven solution is actually relatively successful. Evaluation methods are out there, such as the KITTI data set, allowing simulations to easily be checked for their accuracy. An interesting application would be to integrate some sort of (data driven model or not) noise to the simulation.

### Paper #3: Simulation of a Geiger-Mode Imaging LADAR System for Performance Assessment
#### Summary
This paper proposes a method for simulating a Geiger-mode LiDAR. Older LiDARs use linear-mode technology. Geiger-mode has the ability to shoot single photons instead of a beam, which lowers power usage and can increase data density and speed. This is particularly useful for systems collecting geographic data, as they require much more data at faster speeds.This paper discusses in depth how they utilize a Gaussian beam profile in order to simulate the laser beam. They break up the simulation into three parts: geometric modeling, radiometric modeling, and detection modeling. Geometric modeling is determining the point on geometry at which the laser pulse reflects. As LiDAR sensors typically move while scanning the data, it is important to keep in mind where the laser is coming from. They perform various geometric transformations in order to properly position the point. Next is radiometric modeling, which is the model used to calculate the number of incident photons that enter the sensor. The radiometric models deal with various noise sources as well, such as the sun. Because of how the light is generated, the beam is typically of non-uniform intensity. A Gaussian beam profile is used to simulate this. The authors also take into account the reflectance of the surface which affects the scattering properties of the beam. Finally, detection modeling is implemented, which determines the amount of time that passes before the sensor detects its first returning photon. This is more specific to the Geiger-mode sensor, which is saturated as soon as the first photon is returned, but a probability model is used to determine if the sensor successfully detects the photons. That way, an accurate time can be provided. The simulation was written in C++ and implements these three systems. They provided a 3D model of a city, and then were able to provide parameters to the simulation for the LiDAR. They showed that their simulations generally matched the reference data they had.
#### Takeaways
This paper gave a great outline for structuring a simulation. It does not work in real time, as it is a much more detailed and accurate simulation. They do, however, use the same beam model as HELIOS++ (Carlsson, T.; Steinvall, O.; Letalick, D. Signature Simulation and Signal Analysis for 3-D Laser Radar; FOI-R-0163-SE; FOI-Swedish Defence Research Agency: Linköping, Sweden, 2001.). Their evaluation was for a very specific use case of topographic data collection, so it was easier to find reference to compare to.
### Paper #4: DART-Lux: An unbiased and rapid Monte Carlo radiative transfer method for simulating remote sensing images
#### Summary
DART (discrete anisotropic radiative transfer) is a radiative transfer model, which was designed for modeling the interactions between the Earth’s atmosphere and remote sensors. DART-Lux is a new model that integrates a Monte Carlo method into DART in order to increase the efficiency for simulating remote sensors such as LiDAR. These methods allow for both urban and natural sensing. 
#### Takeaways
This paper showed me that taking an existing model for something and applying it elsewhere can be very effective. DART is not necessarily made for LiDAR systems, but using a ray-tracing method it can be adapted for LiDARs in space. The advantage of DART is that it provides physical accuracy to the simulation.
### Paper #5: [Lidar Simulation for Robotic Application Development: Modeling and Evaluation](https://icave2.cse.buffalo.edu/resources/sensor-modeling/Lidar%20Simulation%20for%20Robotic%20Application.pdf)
#### Summary
This is a PHD paper that discusses a LiDAR and robotics simulator built for a course at Carnegie Mellon. They break up their simulator into three parts: sensor modeling, scene generation, and simulator evaluation. They take a parametric approach to the sensor modeling, and tune the parameters in order to match real-world data as closely as possible. However, tuning these sensors is useless unless the virtual world closely resembles the real world. In order to get a decent model, they use a data driven approach- by adjusting certain parameters and measuring against a data set, they can calculate proper parameters. The future work of this paper includes a few interesting things. This includes non-parametric modeling, which  is basically the use of neural-networks and trained models for the LiDAR model. They explain that a parametric model is sufficient for deciding on features or proper environments to use them in. However, for complex robotics simulations, non-parametric models may come in handy.

### Paper #6: NeRF-LiDAR: Generating Realistic LiDAR Point Clouds with Neural Radiance Fields
#### Summary
NeRFs, or neural radiance fields, are a cutting edge way of converting images to 3D models (original paper here). This paper explores the idea of using NeRFs to generate point cloud data. They use a parametric model for the LiDAR, and simulate raydrop by learning it from the original LiDAR data in the nuScenes dataset. Then, as an evaluation, they showed that the 3D segmentation models performed similarly on real-world data and the simulated data.
#### Takeaways
NeRFs are a great way to get realistic virtual environments. While it's not as customizable, it can be a great tool for evaluation, as there are plenty of datasets that include real LiDAR data and photographic data to generate LiDAR and environment pairings. 

### Paper #7: Learning to Simulate Realistic LiDARs
#### Summary
This paper created LiDAR data generation using a neural network that is able to generate point clouds based on just a picture. 
#### Takeaways
It mentions that simulators like CARLA do not drop rays based on material properties, but on just random models. Additionally, no simulators offer intensity data, which can be useful.

### Paper #8: [Discrete Anisotropic Radiative Transfer (DART 5) for Modeling Airborne and Satellite Spectroradiometer and LIDAR Acquisitions of Natural and Urban Landscapes](https://www.mdpi.com/2072-4292/7/2/1667)
#### Summary
DART is a 3D model that computes radiation propagation through the Earth atmosphere system. It simulates the radiative budget and relfectance of various landscapes. DART is comprised of four processing modules: Direction, Phase, Maket and Dart. Direction is the direction the light propogates, the phase function computes the scattering of light for all elements in the scene, maket builds the spatial arrangement of elements in a scene, and Dart computes the radiation propogation using a Ray tracing or Ray-Carlo approach (Ray-Carlo is ray tracing with the Monte-Carlo technique of casting multiple stochastic rays). The original DART algorithm can be applied to modeling a LiDAR signal. The Monte-Carlo photon tracing method is often used for simulating LiDAR signals, but is computationally expensive. DART volumes are divided into boxes with their own scattering properties to reduce the computation time.

#### Takeaways
DART5 contains a few equations and theories that can be very important for building a LiDAR simulation. The idea to use a Ray-Carlo technique for simulating the light rays is great, and with GPU acceleration can be made to be much faster. It would also allow me to implement BRDFs easily.

### Paper #9: [Range determination with waveform recording laser systems using a Wiener Filter](https://www.sciencedirect.com/science/article/pii/S0924271606001080)
#### Summary
The backscattered waveform from a laser pulse depends on the transmitted waveform. In order to model the backscattered pulse, the transmitted pulse, spatial energy distribution and material properties of the surface must be specified. Various shapes, such as Gaussian, exponential, and rectangles can be used for the pulse. Pulses also have sptial energy distributions, which is how intense the laser is over the shape of the pulse. And finally, the backscattering can depend on the material and reflective properties of the object, as well as the atmospheric transmission of the wave. In this paper, a Wiener filter is used to estimate the surface function of the object in order to generate a backscatter waveform. 

### Paper #10 [VALIDATION OF LIDAR CALIBRATION USING A LIDAR SIMULATOR](https://isprs-archives.copernicus.org/articles/XLIII-B1-2020/39/2020/isprs-archives-XLIII-B1-2020-39-2020.pdf)
#### Summary
This paper focuses on using a LIDAR simulation to validate the calibration of a real LIDAR sensor. Real LIDARs have systematic noise from the sensor itself which can be measured and simulated, so this can be used to seperate the intrinsic from the extrinsic noise. They used a VLP16 in their simulation, and constructed a virtual room in which to place the LIDAR. Offsets were generated independantly for each of the 16 lasers, and intrinsic noise was estimated with the LIDAR tilted at a 1 degree angle. If it was perfectly perpendicular, then it would be impossible to estimate the systematic noise of the sensor. 

### Paper #11 [Measurement and modeling of Bidirectional Reflectance Distribution Function (BRDF) on material surface](https://www.sciencedirect.com/science/article/pii/S0263224113003072)
#### Summary
A BRDF, or Bidirectional Reflectance Distribution Function is a parameterised description of directional reflection characteristics for a material. It relates the incident irradiance from a fiven direction to its contribution to the relfected radiance in a another direction, and is used in computer graphics, remote sensing, environmental monitoring, and other fields of research. BRDF can be used to study reflection characteristics of a material surface, which is useful for many things. This paper describes a device that is able to obtain the BRDF of a real physical material. This includes the distribution of the microfacets (or microgeometry), the geometrical attenuation factor (shadowing and masking), and the fresnel reflection coefficient.

### Paper #12 [DEVELOPMENT OF LIDAR MEASUREMENT SIMULATOR CONSIDERING TARGET SURFACE REFLECTION](https://conference.sdo.esoc.esa.int/proceedings/sdc8/paper/21/SDC8-paper21.pdf)
This paper employs a LIDAR simulation to evaluate navigation algorithms of remote sensors. The reflectance of the LIDAR lasers is important to measure the intensity of the signal. This paper uses a BRDF to obtain the intensity values. The scan pattern of the LIDAR is very unique to the LIDAR model. Six materials that were commenly used on rocket bodies were selected. They were also able to detect the material based on the output data of the LIDAR.

### Paper #13 [A GPU-Accelerated Framework for Simulating LiDAR Scanning](https://www.researchgate.net/publication/359804842_A_GPU-accelerated_framework_for_simulating_LiDAR_scanning)
#### Summary
This paper presents a parameterized LIDAR simulation built with OpenGL compute shaders. The goal of this simulator was specifically to generate massive datasets for neural networks. "The objective of recent work in this field is to generate visually plausible results. However, they are mainly based on perfect ray-casters [4], [19] rather than physically accurate sensors." For the virtual environment, they created their own forest scene from scratch with other people's CAD models and a custom terrain generator. They are also specifically preparing the data for models that do semantic segmentation, so the various parts of the forest need to be labeled appropriately. They use a BRDF to model the sensor errors. For each ray, there are a certain amount of pulses, which determine the total energy of the beam. This helps determine the intensity values later on. They use [this](https://cadxfem.org/inf/Fast%20MinimumStorage%20RayTriangle%20Intersection.pdf) to find the triangle and ray intersections. They used a different BRDF for each material depending on the type of material (Lambertian on water, Cook-Torrance on buildings, etc).

### Paper #13 [Physics-based Simulation of Continuous-Wave LIDAR for Localization, Calibration and Tracking](https://arxiv.org/abs/1912.01652)
#### Summary
This paper implements BRDF for reflections with a LIDAR simulation. They implemented the Oren-Nayar model, which is more specific than the Lambertian model, which most LIDAR models assume.

#### Takeaways
LiDAR pulse shape has an affect on the laser and how it behaves, and different shapes can be implemented in the simulation depending on the sensor that is being simulated.

### Paper #14 [Sensor Calibration and Simulation](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=3aa4f4e761c50fc2742551cebd0fccdf76bcc18b)

### Paper #15 [Blensor](https://www.blensor.org/misc/downloads/Gschwandtner11b.pdf)
"This is in fact closely related to ray-tracing techniques in computer graphics." They use a normal distribution with a mean and a variance, which is a fair approach for me. They also take into account the BRDF of the material in the blend file.

## Notes & Annotations
### Scan Patterns
According to the Helios paper, there are many types of scan patterns that depend on the deflector in the simulation. A rotating mirror creates many parallel lines with even point density, a fibre-optic scanner creates a similar pattern but without moving parts (the laser is spread through many evenly spaced fibre-optic cables), an oscillating mirror creates a sig-zag pattern, with high point densities at the extrema, and the palmer scanner (a slanted oscillating mirror) creates circular scan patterns.

### Scan Frequency and Sample Frequency
Scan frequency is the speed at which the LiDAR can complete a full frame of data, while the sample frequency is amount of points generated by the LiDAR per second. So for example, if a LiDAR has a 10Hz scan frequency, it completes a full sweep of points and creates a packet 10 times per second. If that same LiDAR has a 32KHz scan frequency, that means that over 10 packets, it collects 32,000 points, where each frame contains 3,200 points. This also means that if the same sensor runs at a 20Hz scan frequency, each frame contains 1,600 points, but still has a 32KHz sample frequency.

### LiDAR Pulses
In order to sense the environment around itself, a LiDAR sends out pulses of light. Sending out a constant beam would make it really difficult to know how long it took for the light to come back to the sensor, so a pulse is sent out and the sensor waits for the pulse to come back. These pulses can be configured to do many different things. The pulse shape is the temporal profile of the pulse- how long does it take to rise and fall? How long is the pulse itself? What is its peak intensity? There are many things to consider when picking a pulse shape. For example, a longer pulse requires more energy, so they require higher power levels. Additionally, a longer pulse will travel further, but sacrifice resolution, as a shorter pulse will be more exact. 

### Temporal Resolution
The temporal resolution of a LiDAR depends on many things. The pulse rate, scanning pattern, field of view, rotation speed, and processing time all affect how quickly a LiDAR can process new data. The VLP-16 has 16 laser/detector pairs, and can rotate at 5Hz to 20Hz, allowing it to generate up to 300,000 points per second. 

### Return Mode
Single return mode means the sensor records and processes the first return of the laser pulse, while dual return mode means it records and processes the first and last returns of the laser pulse. 

### What is a simulation step?
#### According to the [Carlsson Paper](https://www.foi.se/rest-api/report/FOI-R--0163--SE)
A simulation step projects the 3D view to a depth buffer, with normal data. Each pixel is treated as a laser beam and receiver cell. Each pixel is then divided into a subarea, where each subarea is basically a surface with the properties of the center pixel. Then, the irradiance of the beam is calculated, along with the speckle and turbulance, in order to determine the total laser pule energy is each subarea to represent the reflected pulse power. (Speckle is the random pattern that a laser beam exhibits when reflected off of a rough surface, and turbulance is how much of the light actually makes it to the surface due to disturbances in the air and its refractive index).

#### According to [HELIOS++](https://arxiv.org/pdf/2101.09154.pdf)
HELIOS+ structures each scene with the platform, which is where the sensor is attached, waypoints, which define the path of movment for the sensor, and parts, which are items in the virtual world that could obstruct the sensor. Each step can be visualized in real time. Various scan deflectors can be selected, which will define the pattern that the sensor will emit the lasers in (see section above). Finally, the waveforms themselves are formed by a central ray and many subrays, as specified by the Carlsson paper. Beam divergence (the subrays) are calculated using a Gaussian power distribution. Each subray is assigned its respective intensity and cast into the scene, and the total power returned depends on all of the subrays and their intersections. Various subray configurations and densities can be configured as well. Finally, the pulse shape, which is the temportal profile of the beam, is approximated according to the Carlsson paper with a specific power equation. For each pulse, the subrays are collected as a full waveform, and the power is a sum of the subray's waveforms, shifted according to their respective ranges depending on their power. 

### Writing to an LAS file: [LAS File Format](https://www.asprs.org/wp-content/uploads/2019/03/LAS_1_4_r14.pdf)

### BRDFs for Materials 
What is a BRDF? A BRDF, or Bidirectional Reflectance Distribution Function, is a four dimensional function that defines how light reflects off of an opaque surface. A BRDF is a subset of a BSDF, or Bidirectional Surface Distribution Function. We only need the BRDF because we only care about how light is reflected back into the sensor. A BRDF considers the incoming light direction and the outgoing light direction. In addition, it takes into account the incident irradiance of the light source, as well as the reflected radiance of the material. In order to use the BRDF in the simulation, I need to get the incident angle of the light (relative to the surface normal) and the observation angle (from the detectors point of view). The BRDF function will determine the amount of light that the sensor gets back. Interestingly, there are various BRDF libraries, such as [this one](https://cdfg.csail.mit.edu/wojciech/brdfdatabase).

### Oren-Nayar light model
The Oren-Nayar light model is a diffuse relfection model that uses a Gaussian distribution to calculate the reflectance of a rough surface, given a the incoming/outgoing angles and the surface roughness.

### Characterizing LIDAR Noise
What defines the noise in the LIDAR data? Mainly, the intensity of the point values is what causes noise in a LIDSAR simulation. Raydrop happens when the intensity of a point is reduced to zero, which means that that inital laser beam never returns to the sensor [see LIDARsim]. Let's say we define a BRDF, which is an equation that returns the total reflectance of light given the incoming and outgoing light direction for a given material.

## Questions / Thoughts
* Each step of the simulation should be a moment in time- pick a fixed timestep to move the simulation, and then calculate the sensors response. The time it takes for the laser to propogate is too small for the sensor to process. Additionally, keep an eye on the RPLiDAR S3 for testing purposes. In terms of evaluation, setting up the most basic environment possible and checking the results would be a great first step. Then, you can compare the parametric model with noise, without noise, and the real data.
* Related Work vs Background Information: Related work is other papers and project, how is mine similar/different, what did I learn from it. Background is something you need to understand to appreciate the work.
* Interesting Idea: What if I made a program to automatically calibrate sensor noise? I can develop a benchmark material, and then make sure that ray drop / intensity values line up correctly.
* How will I implement the calibration? Given a known material, I can collect the average intensity, minimum intensity, maximum intensity, the standard deviation, and more. Then, in simulation, I can detect the material and use the baseline intensity, and use the noise distribution to disperse outliers (take note of the various exceptions that must be made due to the various lighting models, particularly with glossy surfaces). Now that I can generate the data for known materials, I can attempt to generate for unknown materials by lerping between similar materials (perhaps a chalkboard is somewhere between wood and concrete).
* Check out this book: https://www.sciencedirect.com/book/9780125444224/handbook-of-optical-constants-of-solids
* Maybe I should be collecting min, max, and average for every incident angle, then I can just calculate the normal of the collision and pick a number based on a Gaussian distribution.

## Example Use Case
Let's say the user has a brick material benchmark. They calibrate the LIDAR, and are able to obtain the data for each and every angle of the lasers on the sensor. Given it is a known material, they also have the BRDF values for it (or, it can be derived in simulation). Now, lets say they have a material that is unknown- they do not have a benchmark material for it. But, we know that it is similar to the brick material, and has the same BRDF model. How can we simulate this material with information we already have?

Lets say at 90 degrees, the brick responds with a 0.75 intensity. We know the brick is using the Oren-Nayer model, due to its diffuse properties. Now, lets say our new material is concrete. This new material has the same BRDF model as the brick, as it is also a mostly diffuse material. We know the BRDF parameters for it as well. 

## Why ApolloSim?
First of all, the name Helios, the Greek god of the sun (specifically the rays of the sun), was taken by [HELIOS++](https://arxiv.org/pdf/2101.09154.pdf). I'm using a language called Odin for the first time, so I wanted to stick with the theme of a god's name; so I went with Apollo, the god of truth and prophecy, because people use simulations to see the future. 

# Testing
## Testing Wood vs Wall
Wood distance: 0.389
Wall Distance: 0.457