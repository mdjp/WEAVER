function sdmresults = dosdm( IRsc,Fs,params )

SKIPDISPLAYS=0;
if nargin < 1
	load( 'dosdm.mat' );
else
end

sdmresults=[];
%% Read the data
% Read impulse response
%load([ir_filename '.mat'])
ir_left = [IRsc(:,1),IRsc(:,2),-IRsc(:,2),IRsc(:,3),-IRsc(:,3),IRsc(:,4),-IRsc(:,4)]; 
ir_filename = sanitize(params.inp.files{params.curind});

%% Create SDM struct for analysis with a set of parameters
% Parameters required for the calculation
% Load default array and define some parameters with custom values
fs = Fs;
%a = createSDMStruct('DefaultArray','SPS200','fs',fs,'showArray',0);
a = createSDMStruct('DefaultArray','BFormatKB','fs',fs,'showArray',1);

%% Calculate the SDM coefficients
% Solve the DOA of each time window assuming wide band reflections, white
% noise in the sensors and far-field (plane wave propagation model inside the array)
DOA{1} = SDMPar(ir_left, a);
sdmresults = DOA{1};

if SKIPDISPLAYS
	disp( 'Skipping right array proc, displays & resynth room resp' );
	return;
end

%% Download a stereofile (originally from free music archive)
audio_filename = 'paper_navy_swan_song';
if ~exist([audio_filename ,'.mp3'],'file')
    disp('Downloading an example music file from free music archive.')
    url_of_the_song = 'https://mediatech.aalto.fi/~tervos/demoJAES/samples/Song1_CR1.mp3';
    outfilename = websave([audio_filename '.mp3'],url_of_the_song);
end

% If websave not supported, you have to download IRs and source signals
% manually from the urls given below
% 'https://mediatech.aalto.fi/~tervos/IR_living_room.mat'
% 'https://mediatech.aalto.fi/~tervos/demoJAES/samples/Song1_CR1.mp3'

% Read stereo signal
[S,korgsr] = audioread([audio_filename '.mp3']);


% Here we are using the top-most microphone as the estimate for the
% pressure in the center of the array !! WELL NOT TRUE - BFORMAT W is
% composed of elements of each of the tetrahdra?

P{1} = ir_left(:,1);

ir_right = ir_left;
% Same for right channel
DOA{2} = SDMPar(ir_right, a);
P{2} = ir_right(:,1);

%% Create a struct for visualization with a set of parameters
% Load default setup for very small room and change some of the variables
v = createVisualizationStruct('DefaultRoom','VerySmall',...
    'name',ir_filename,'fs',fs);
% For visualization purposes, set the text interpreter to latex
set(0,'DefaultTextInterpreter','latex')

%% Draw analysis parameters and impulse responses
parameterVisualization(P, v);

%% Draw time frequency visualization ------------------
% Drawing only the lateral plane
timeFrequencyVisualization(P, v)

%% Draw the spatio temporal visualization ----------------------
spatioTemporalVisualization(P, DOA, v)

%% %% Create synthesis struct with the given parameters
% Load default 5.1 setup and define some parameters with custom values
s = createSynthesisStruct('defaultArray','2.1',...
    'snfft',length(P{1}),...
    'fs',fs,...
    'c',343);
% You always need to define 'snfft'

%% Synthesize the spatial impulse response with NLS
H = cell(1,2);
for channel = 1:2
    H{channel} = synthesizeSDMCoeffs(P{channel},DOA{channel}, s);
end

%% Convolution with the source signal

% Choose 10 seconds and resample
Sr = resample(S(1:44.e3*10,:),480,441);
numOfLsp = size(s.lspLocs,1);
Y = zeros(size(Sr,1),numOfLsp);

% Resample H to 48e3 [Hz] sampling frequency for auralization
H{1} = resample(H{1},1,4);
H{2} = resample(H{2},1,4);

for channel = 1:2;
    for lsp = 1:numOfLsp
        % Convolution with Matlab's overlap-add
        Y(:,lsp) = Y(:,lsp) +  fftfilt(H{channel}(:,lsp),Sr(:,channel));
    end
end
% Y contains the auralization of the spatial IRs with S

%% Saving the auralization to a file
% Save the file to the default folder with a custom filename.
% Save the result as wav, as wav can handle upto 256 channels.
disp('Started Auralization');tic
savename = [ir_filename '_' audio_filename '.wav'];
if max(abs(Y(:))) > 1
    Y = Y/max(abs(Y(:)))*.9;
    disp('Sound normalized, since otherwise would have clipped')
end
disp(['Ended Auralization in ' num2str(toc) ' seconds.'])
disp('Started writing the auralization wav file')
disp([savename  ' on the disk.']);tic
audiowrite(savename,Y/10,s.fs/4)
info = audioinfo(savename);
disp('Wrote ... ');
disp(info)
disp(['... in ' num2str(toc) ' seconds'])
%% Playback using Matlab or other applications
kplayit = 1;
if kplayit
	sound( Y(:,1:2), 48000 );
end
% <--- EOF demoBinauralRendering.m

end
