%% Double Ridged Horn Antenna Generator 
% Add-on Dependancy: 
% Antenna Toolbox by MathWorks
%Tutorial: Select Home tab, Click Add-Ons, Then Get Add-Ons, 
% Search Antenna Toolbox, Install  

%% 8-40 GHz Double-Ridged Horn - Geometry Generator
% Purpose: Create high-res 3D model for FreeCAD export
% Clear workspace
clear; clc;

%% 1. Define Design Parameters
targetFrequency = 8e9;  % 8 GHz
c = 2.99792458e8;       % Speed of light

%% 2. Create and Design the Antenna
% Create the double-ridged horn object
antennaObject = hornRidge; 

% Design the antenna geometry for 8 GHz
antennaObject = design(antennaObject, targetFrequency);

% Display dimensions
disp('Antenna Dimensions (meters):');
disp(antennaObject);

%% 3. Calculate "Safe" Mesh Size
% We use 8 GHz for the mesh size because 40Ghz Crashes
% This is sufficient for 3D printing and CAD import.
wavelength_8GHz = c / targetFrequency; 

% We set the triangle edge length to roughly 3.7mm
safeEdgeLength = wavelength_8GHz / 10; 

fprintf('Meshing with Safe Edge Length: %0.4f meters\n', safeEdgeLength);

%% 4. Mesh the Antenna
figure;
mesh(antennaObject, 'MaxEdgeLength', safeEdgeLength);
title('Generated Mesh for Export');

%% 5. Export to STL for FreeCAD
fileName = 'DoubleRidgedHorn_8_40GHz_Fixed.stl';

% Export
stlwrite(antennaObject, fileName);

fprintf('SUCCESS: Exported %s to your folder.\n', fileName);