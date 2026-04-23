close all
clear
clc

% -------------------------------------------------------------------------
% 1. PATH SETUP
% -------------------------------------------------------------------------
if exist('C:\openEMS\matlab', 'dir')
    addpath('C:\openEMS\matlab');
elseif exist('/opt/openEMS/share/openEMS/matlab', 'dir')
    addpath('/opt/openEMS/share/openEMS/matlab');
else
    % Fallback to the path in your original snippet if the above fail
    try
        addpath('C:\Users\itsme\OneDrive\Documents\openEMS\matlab');
    catch
        warning('Check your openEMS installation path!');
    end
end

% -------------------------------------------------------------------------
% 2. CONFIGURATION & FILENAMES
% -------------------------------------------------------------------------
stl_filename = 'HornAntennaV4.stl'; % <--- CHANGE THIS TO YOUR FILENAME
physical_constants;
unit = 1e-3; % STL is in mm

% Ka-Band WR-28 Waveguide Dimensions (Internal)
a = 7.112; 
b = 3.556; 

% Frequency range (26.5 - 40 GHz)
f_start = 26.5e9;
f_stop  = 40.0e9;
f0      = 33.25e9; % Center frequency for pattern calculation
TE_mode = 'TE10';

% -------------------------------------------------------------------------
% 3. SETUP FDTD & BOUNDARIES
% -------------------------------------------------------------------------
FDTD = InitFDTD('EndCriteria', 1e-4);
FDTD = SetGaussExcite(FDTD, 0.5*(f_start+f_stop), 0.5*(f_stop-f_start));
BC   = {'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8'}; 
FDTD = SetBoundaryCond(FDTD, BC);

% -------------------------------------------------------------------------
% 4. GEOMETRY & STL IMPORT (REPLACEMENT)
% -------------------------------------------------------------------------
CSX = InitCSX();
CSX = AddMetal(CSX, 'my_model'); 

% Use ImportSTL instead of AddSTL
% Syntax: ImportSTL(CSX, 'PropertyName', Priority, 'Filename', 'Transform', ...)
CSX = ImportSTL(CSX, 'my_model', 10, stl_filename, 'Transform', {'Scale', 1});

% Determine STL size to automate Mesh and Simulation Box
% Manually define the bounding box of your STL (in mm)
% Replace these values with the actual dimensions from your CAD software
stl_min = [-15, -15, 0];   % [MinX, MinY, MinZ]
stl_max = [15, 15, 60];    % [MaxX, MaxY, MaxZ]

% Define resolution (20 steps per wavelength at max freq)
max_res = c0 / (f_stop) / unit / 20; 

% Create Mesh based on STL bounds + 20mm padding for the "air" around it
mesh.x = [stl_min(1)-20 0 stl_max(1)+20];
mesh.x = SmoothMeshLines(mesh.x, max_res, 1.4);
mesh.y = [stl_min(2)-20 0 stl_max(2)+20];
mesh.y = SmoothMeshLines(mesh.y, max_res, 1.4);
mesh.z = [stl_min(3)-15 0 stl_max(3)+30];
mesh.z = SmoothMeshLines(mesh.z, max_res, 1.4);
CSX = DefineRectGrid(CSX, unit, mesh);

% -------------------------------------------------------------------------
% 5. PORTS & FAR-FIELD BOX
% -------------------------------------------------------------------------
% SETUP PORT: Adjust 'start/stop' if your STL throat isn't at the origin
% This places a port at Z=0, assuming the waveguide starts there.
p_z = 0; 
start = [-a/2, -b/2, p_z-2]; 
stop  = [ a/2,  b/2, p_z];
[CSX, port] = AddRectWaveGuidePort(CSX, 0, 1, start, stop, 2, a*unit, b*unit, TE_mode, 1);

% SETUP NF2FF: Surround the model (5mm gap)
start_nf = stl_min - 5;
stop_nf  = stl_max + 5;
[CSX, nf2ff] = CreateNF2FFBox(CSX, 'nf2ff', start_nf, stop_nf);

% -------------------------------------------------------------------------
% 6. RUN SIMULATION
% -------------------------------------------------------------------------
Sim_Path = 'tmp_STL_Ka_Sim';
Sim_CSX  = 'model.xml';
if exist(Sim_Path, 'dir'); rmdir(Sim_Path, 's'); end
mkdir(Sim_Path);

WriteOpenEMS([Sim_Path '/' Sim_CSX], FDTD, CSX);
CSXGeomPlot([Sim_Path '/' Sim_CSX]); % Visual check: Port should be at the throat!
RunOpenEMS(Sim_Path, Sim_CSX);

% -------------------------------------------------------------------------
% 7. POST-PROCESSING
% -------------------------------------------------------------------------
freq = linspace(f_start, f_stop, 201);
port = calcPort(port, Sim_Path, freq);
s11  = port.uf.ref ./ port.uf.inc;

% Plot S11
figure;
plot(freq/1e9, 20*log10(abs(s11)), 'k-', 'Linewidth', 2);
grid on; title('Reflection Coefficient S_{11}');
xlabel('f / GHz'); ylabel('|S_{11}| (dB)');

% Calculate Far-Field Patterns
thetaRange = (0:2:359) - 180;
nf2ff = CalcNF2FF(nf2ff, Sim_Path, f0, thetaRange*pi/180, [0 90]*pi/180);

% Display Directivity
Dlog = 10*log10(nf2ff.Dmax);
fprintf('Max Directivity: %.2f dBi\n', Dlog);

% Plot 2D Pattern
figure;
plotFFdB(nf2ff, 'xaxis', 'theta', 'param', [1 2]);
title(['Pattern @ ' num2str(f0/1e9) ' GHz']);

% 3D Pattern Visualization
phiRange = 0:5:360;
thetaRange = 0:2:180;
nf2ff = CalcNF2FF(nf2ff, Sim_Path, f0, thetaRange*pi/180, phiRange*pi/180);
figure;
plotFF3D(nf2ff);