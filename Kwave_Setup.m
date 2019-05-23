%k-wave main file for compress sensing integration with ultrasound


% ----------- create the copmutational grid --------------------- 
Nx = 500;        %number of grid points in the x direction
Ny = 500;        %number of grid points in the y direction      
Nz = 500;        %number of grid points in the z direction
dx = 0.1e-3;    %grid point spacing in the x direction [m]
dy = 0.1e-3;    %grid point spacing in the y direction [m]
dz = 0.1e-3;    %grid point spacing in the z direction [m]
kgrid = kWaveGrid(Nx, dx, Ny, dy, Nz, dz);

% define a binary sensor mask 
% sensor mask used to define where our pressure field will be recorded

sensor_x_pos = Nx/2;        % grid points
sensor_y_pos = Ny/2;        % grid points
sensor_radius = Nx/2-22;    % grid points 
sensor_arc_angle = 3*pi/2;  % radians

% ------- define the properties of the homogeneous propagation medium ----
medium.sound_speed = 1500;  % [m/s]                 
medium.alpha_coeff = 0.75;  % [dB/(MHz^y cm)]
medium.alpha_power = 1.5;   
medium.density = 1000;      % [kg/m^3] density for water being used for now
% -------- define medium properties for non homogenous medium
%medium.sound_speed = 1500 * ones(Nx, Ny);   % [m/s]
%medium.sound_speed(1:Nx/2, :) = 1800;       % [m/s]
%medium.density = 1000 * ones(Nx, Ny);
%medium.density(:, Ny/4:Ny) = 1200; 


% ---------- defining time array -------------------
kgrid.makeTime(medium.sound_speed);

%----------- defining properties of input signal -------------------
source_strength = 1e6;     % [MPa]
tone_burst_freq = 0.5e6;   % [Hz]
tone_burst_cycles = 5; 

%---------- create the input signal using toneBurst ----------------
input_signal = toneBurst(1/kgrid.dt, tone_burst_freq, tone_burst_cycles);

% scal3 the source magnitude by the source strength divided by the 
% impedance (the source is assigned to the particle velocity)
input_signal = input_signal(1:Nx); %Nx matches length of multiplication below
input_signal = (source_strength ./(medium.sound_speed * medium.density)) .* input_signal; 

%------------ define physical properties of transducer -------------------
transducer.number_elements = 1;      % total number of transducer elements
transducer.element_width = 1;       % width of each element (in grid points)
transducer.element_length = 12;     % length of each element (in grid points)
transducer.element_spacing = 0;     % spacing (kerf width) between the elements (in grid points)
% inf in this context means the transudcer is not curved (e.g. flat,
% linear)
transducer.radius = inf;            % radius of curvature of transducer

%calculate the width of the transudcer in grid points 
transducer_width = transducer.number_elements * transducer.element_width + (transducer.number_elements-1) * transducer.element_spacing; 

%use this to position the transducer in the middle of the computational
%grid
transducer.position = round([1,Ny/2-transducer_width/2,Nz/2-transducer.element_length/2]);

%properties used to derive beamforming delays
transducer.sound_speed = 1540;              % sound speed [m/s]
transducer.focus_distance = 20e-3;          %focus distance [m]
transducer.elevation_focus_distance = 19e-3;%focus distance in the elevation plane [m]
transducer.steering_angle = 0;              %steering angle 

%apodization
transducer.transmit_apodization = 'Rectangular'; 
transducer.receive_apodization = 'Rectangular'; 

%define the transudcer elements that are currently active; 
transducer.active_elements = zeros(transducer.number_elements, 1); 
transducer.active_elements = 1;

%append the input signal used to derive the transducer
transducer.input_signal = input_signal; 

%create the transducer using the defined settings 
transducer = kWaveTransducer(kgrid, transducer);

%[sensor_data] = kspaceFirstOrder3D(kgrid, medium, transducer, sensor, input_args(i); 