### Scan Patterns:
According to the Helios paper, there are many types of scan patterns that depend on the deflector in the simulation. A rotating mirror creates many parallel lines with even point density, a fibre-optic scanner creates a similar pattern but without moving parts (the laser is spread through many evenly spaced fibre-optic cables), an oscillating mirror creates a sig-zag pattern, with high point densities at the extrema, and the palmer scanner (a slanted oscillating mirror) creates circular scan patterns.

### What is a simulation step?
#### According to the [Carlsson Paper](https://www.foi.se/rest-api/report/FOI-R--0163--SE)
A simulation step projects the 3D view to a depth buffer, with normal data. Each pixel is treated as a laser beam and receiver cell. Each pixel is then divided into a subarea, where each subarea is basically a surface with the properties of the center pixel. Then, the irradiance of the beam is calculated, along with the speckle and turbulance, in order to determine the total laser pule energy is each subarea to represent the reflected pulse power. (Speckle is the random pattern that a laser beam exhibits when reflected off of a rough surface, and turbulance is how much of the light actually makes it to the surface due to disturbances in the air and its refractive index).

#### According to [HELIOS++](https://arxiv.org/pdf/2101.09154.pdf)

#### According to [PHD Paper by Tallavajhula](https://icave2.cse.buffalo.edu/resources/sensor-modeling/Lidar%20Simulation%20for%20Robotic%20Application.pdf)