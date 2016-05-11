function [w,x,y,z,Fs] = mknullIR()

Fs = 48000;

warning( 'off','MATLAB:dispatcher:pathWarning' );
addpath(genpath('C:\User Files\GoogleDrive\XFER\funcs'));
addpath(genpath('C:\User Files\GoogleDrive\XFER\kbmatlab'));
addpath(genpath('/Users/kennethbrown/GoogleDrive/XFER/funcs'));
addpath(genpath('/Users/kennethbrown/GoogleDrive/XFER/kbmatlab'));

%dur = 0.1;
%ns = floor(dur*Fs);
ns = 2048; % 2048 doesnt seem to work in chrome mac
ns = 2;
dur = ns/Fs;
Wo = 1; Xo = 2; Yo = 3; Zo = 4; No = 4;

%{
W=S/sqrt(2)
X=S*cos(theta)*cos(phi)
Y=S*sin(theta)*cos(phi)
Z=S*sin(phi);
%}
S=zeros(ns,1);
DEGS=66;
theta = ones(ns,1)*2*pi*DEGS/360;
phi = S;
S(1)=1.0;

% using az 45degrees and el 0 should produce equal WXY levels and Z=0;
% http://www.ambisonia.com/Members/mleese/file-format-for-b-format/
% "The W channel is attenuated by -3 dB (1/sqrt(2)) relative to the
% unnormalized ...spherical harmonic component. This is the case for all
% orders That is to say, a source at +45° azimuth (zero elevation) would
% produce equal signals in W, X, and Y."


W=S./sqrt(2);
X=S.*cos(theta).*cos(phi);
Y=S.*sin(theta).*cos(phi);
Z=S.*sin(phi);

figure;
plot( W, 'dk' ); hold on;
plot( X, '.r' );
plot( Y, '.g' );
plot( Z, '.b' );

nullIR = [W,X,Y,Z];
fn = 'nullIR_B_48k.wav';
audiowrite( fn, nullIR, Fs );

nullIR = [S,S];
fn = 'nullIR_St_48k.wav';
audiowrite( fn, nullIR, Fs );

disp(['Fin:' fn ]);










end