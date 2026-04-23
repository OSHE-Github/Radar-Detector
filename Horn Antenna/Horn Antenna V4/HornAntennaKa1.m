close all; clear; clc;

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

% Set up project directory and file name
script_dir = fileparts(mfilename('fullpath'));
stl_filename = fullfile(script_dir, 'HornAntennaV4.stl'); 

if ~exist(stl_filename, 'file')
    error('STL File NOT FOUND! Ensure "HornAntennaV4.stl" is in: %s', script_dir);
end

physical_constants;
unit = 1e-3; % All dimensions in mm

% -------------------------------------------------------------------------
% 2. ANTENNA & SIMULATION SETTINGS (Ka-Band WR-28)
% -------------------------------------------------------------------------
a = 7.112;      % WR-28 internal width
b = 3.556;      % WR-28 internal height
f_start = 26.5e9; 
f_stop  = 40.0e9; 
f0      = 33.25e9; % Center frequency for pattern
TE_mode = 'TE10';

% -------------------------------------------------------------------------
% 3. GEOMETRY SETUP
% -------------------------------------------------------------------------
CSX = InitCSX();
CSX = AddMetal(CSX, 'my_model'); 

% Import the STL
% Priority 10. Scale 1 (mm). 
CSX = ImportSTL(CSX, 'my_model', 10, stl_filename, 'Transform', {'Scale', 1});

% MANUAL BOUNDS: Adjust these to fit your HornAntennaV4 size!
% These define the "box" for the mesh and simulation.
stl_min = [-20, -20, -18];   
stl_max = [20, 20, 60];    

% --- INTUITIVE FEED EXTENSION ---
% We add 15mm of straight waveguide at the back (Z=0 to Z=-15)
% This ensures waves stabilize and the port "plugs in" properly.
feed_len = 15;

% -------------------------------------------------------------------------
% 4. MESH SETUP
% -------------------------------------------------------------------------
% Resolution: 20 steps per wavelength at 40 GHz
max_res = c0 / (f_stop) / unit / 20; 

mesh.x = [stl_min(1)-15 0 stl_max(1)+15];
mesh.x = SmoothMeshLines(mesh.x, max_res, 1.4);
mesh.y = [stl_min(2)-15 0 stl_max(2)+15];
mesh.y = SmoothMeshLines(mesh.y, max_res, 1.4);
% Mesh Z includes the new feed extension (-15) and some air in front
mesh.z = [-feed_len-5 0 stl_max(3)+25];
mesh.z = SmoothMeshLines(mesh.z, max_res, 1.4);
CSX = DefineRectGrid(CSX, unit, mesh);

% -------------------------------------------------------------------------
% 5. PORTS & BOUNDARIES
% -------------------------------------------------------------------------
FDTD = InitFDTD('EndCriteria', 1e-4);
FDTD = SetGaussExcite(FDTD, 0.5*(f_start+f_stop), 0.5*(f_stop-f_start));
FDTD = SetBoundaryCond(FDTD, {'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8'});

% Add the Port at the end of the extension (Z = -15)
p_z = -feed_len;
[CSX, port] = AddRectWaveGuidePort(CSX, 0, 1, [-a/2 -b/2 p_z-1], [a/2 b/2 p_z], 2, a*unit, b*unit, TE_mode, 1);

% Far-field Box (Radiated Pattern)
[CSX, nf2ff] = CreateNF2FFBox(CSX, 'nf2ff', [stl_min(1)-5 stl_min(2)-5 -feed_len], [stl_max(1)+5 stl_max(2)+5 stl_max(3)+10]);

% -------------------------------------------------------------------------
% 6. RUN SIMULATION
% -------------------------------------------------------------------------
Sim_Path = 'tmp_STL_Sim'; 
Sim_CSX  = 'model.xml';

% Robust folder creation
if exist(Sim_Path, 'dir')
    try rmdir(Sim_Path, 's'); catch; end
end
mkdir(Sim_Path);

WriteOpenEMS([Sim_Path '/' Sim_CSX], FDTD, CSX);
CSXGeomPlot([Sim_Path '/' Sim_CSX]); % STOP: Verify port is plugged in here!
RunOpenEMS(Sim_Path, Sim_CSX);

% -------------------------------------------------------------------------
% 7. RESULTS & PLOTS
% -------------------------------------------------------------------------
freq = linspace(f_start, f_stop, 201);
port = calcPort(port, Sim_Path, freq);
s11  = port.uf.ref ./ port.uf.inc;

% Plot S11 (Return Loss)
figure;
plot(freq/1e9, 20*log10(abs(s11)), 'k-', 'Linewidth', 2);
grid on; title('Reflection Coefficient S_{11} (Ka-Band)');
xlabel('Frequency (GHz)'); ylabel('|S11| (dB)');

% Far-field calculation
thetaRange = (0:2:359) - 180;
nf2ff = CalcNF2FF(nf2ff, Sim_Path, f0, thetaRange*pi/180, [0 90]*pi/180);
fprintf('Max Directivity: %.2f dBi\n', 10*log10(nf2ff.Dmax));

% Plot 2D Radiation Pattern
figure;
plotFFdB(nf2ff, 'xaxis', 'theta', 'param', [1 2]);
title(['Radiation Pattern @ ' num2str(f0/1e9) ' GHz']);