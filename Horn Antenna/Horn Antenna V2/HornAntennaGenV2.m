%% Double Ridged Horn Antenna Generator V2 
% Add-on Dependancy: 
% Antenna Toolbox by MathWorks
%Tutorial: Select Home tab, Click Add-Ons, Then Get Add-Ons, 
% Search Antenna Toolbox, Install  

% Clear workspace
clear; clc;
% Define the operating frequency range (8 GHz to 40 GHz)
freq = linspace(8e9, 40e9, 51);

% Create the Double-Ridged Horn Antenna object
ant = hornRidge;

%% --- Apply Calculated Dimensions ---
% Note: MATLAB Antenna Toolbox uses meters for all length units.

% 1. Mouth (Aperture) Dimensions
ant.FlareWidth  = 0.084;  % 84 mm (H-plane Width)
ant.FlareHeight = 0.062;  % 62 mm (E-plane Height)

% 2. Length
ant.FlareLength = 0.140;  % 140 mm (Axial Length)

%% --- Feed and Ridge Tuning (Critical for 40 GHz) ---
% To ensure operation up to 40 GHz, the feed waveguide must be small
% enough to prevent higher-order modes, and the ridge gap must be tight.
% These values approximate a wideband WRD feed.
ant.Width      = 0.020;   % 20 mm Waveguide Width
ant.Height     = 0.010;   % 10 mm Waveguide Height
ant.RidgeGap   = 0.0015;  % 1.5 mm Gap (Essential for high-freq impedance)
ant.RidgeWidth = 0.005;   % 5 mm Ridge Width

%% --- Export as STL ---

figure;
show(ant);
title('Double Ridged Horn (8-40 GHz) - 84x62mm Aperture');

mesh(ant, 'MaxEdgeLength', 0.002); 

% 2. Define filename
filename = 'HornAntenna_8_40GHz.stl';

% 3. Export
stlwrite(ant, filename);
disp(['Export Complete: ', filename]);
