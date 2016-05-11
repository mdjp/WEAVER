function [az, el] = IntensityAnalysis(IR, Fs, WindowSize, NFFT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function performs intensity vector analysis of B-Format Impulse    %
% Responses.                                                              %
%                                                                         %
% Input data: IR = B-Format Impulse Response.                             %
%             Fs = Sampeling Frequency.                                   %
%             WindowSize = the size of the hanning window used for Short  %
%             Time Foure Transform (STFT).                                %
%             NFFT = The number of frequency bins used for the STFT       %
%                                                                         %
% Output data: az = azimuth angle of arrival radians.                     %
%              el = elevation angle of arrival radians.                   %
%                                                                         %
%       Coded by Michael James Lovedee-Turner, PhD Music Technology       %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mathmatic principles based on:                                          %
%G. Kearney, "Auditory Scene Synthesis using Virtual Acoustic Recording   %
%and Reproduction" Ph.D Dissertation, Department of Electronics and       %
%Electrical Engineering, Trinity College Dublin, Dublin, 2010.            %
%                                                                         %
%  Code adapted from:                                                     %
% Lovedee-Turner, M. (2015). An Algorithmic Approach to the Analysis      %
% and Manipulation of B-Format Impulse Responses For Real-Time            %
% Head Rotation. Master Thesis. University of York.                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Creats a filter and applies it to the impulse response

cutoff = 4000;

[b, a] = butter(1,cutoff ./(0.5*Fs),'low'); % Low pass filter removing all freq above 5k

IR = filter(b, a, IR);

%% Creats the hanning windows function.
L = length(IR(:,1)); % Length of IR.
StepSize = (WindowSize/2); % Steps Size Half the Window Size.
wi = hann(WindowSize, 'periodic');  % Generate the Hann function to window a frame
Nframes = floor(L / StepSize) - 1; % -1 prevents input overrun in the final frame
fin = WindowSize; % End point for windowed signal 
start = 1; % Start point for windowed signal
col = 1; % Starting Column for STFT

W = zeros(NFFT,Nframes);
X = zeros(NFFT,Nframes);
Y = zeros(NFFT,Nframes);
Z = zeros(NFFT,Nframes);

%% Applies the Short time Fourier Transform to get frequency domain representation of the Impulse Response.
for n = 1 : Nframes
   
 WW = wi .* IR(start:fin,1); % Applies Hann Window to W Channel
 XW = wi .* IR(start:fin,2); % Applies Hann Window to X Channel
 YW = wi .* IR(start:fin,3); % Applies Hann Window to Y Channel
 ZW = wi .* IR(start:fin,4); % Applies Hann Window to Z Channel
 
 W(1:NFFT, col) = fft(WW, NFFT); % Calculates the FFT of W Channel in NFFT frequency bins
 X(1:NFFT, col) = fft(XW, NFFT); % Calculates the FFT of X Channel in NFFT frequency bins
 Y(1:NFFT, col) = fft(YW, NFFT); % Calculates the FFT of Y Channel in NFFT frequency bins
 Z(1:NFFT, col) = fft(ZW, NFFT); % Calculates the FFT of Z Channel in NFFT frequency bins
    
 start = start + StepSize; % Progresses the start point
 fin = fin + StepSize; % Progresses the end point
 col = col + 1;% Colum starting point for STFT
 
end

%% Calculate the instantaneous intensity for each channel.

 Ix = ((sqrt(2))) .* real(conj(W) .* X); % Intensity Calculation for X
 Iy = ((sqrt(2))) .* real(conj(W) .* Y); % Intensity Calculation for Y
 Iz = ((sqrt(2))) .* real(conj(W) .* Z); % Intensity Calculation for Z
 
 
 %% Calculates the angle of arrival in radians for the Azimuth.
 az = atan2(Iy, Ix); % Calculates the angle of arrival along the Azimuth.
 el = atan2(Iz,(sqrt(((Ix).^2)+((Iy).^2)))); % Calculates the Angle of arrival along Elevation.
 
end

