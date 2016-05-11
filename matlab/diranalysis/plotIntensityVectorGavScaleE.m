function [az, el] = plotIntensityVector(IR, fs, NFFT, dur, scale, fn )


if(nargin == 0)
	load;
end
[~,nam,~]=fileparts( fn );

% Script to test FO_ISM function

close all;
clc;

durS = dur*fs;

IR = IR( 1:durS, : );


W=IR(:,1);
X=IR(:,2);
Y=IR(:,3);
Z=IR(:,4);


[Wspec, F, T,P] = spectrogram(W,NFFT,NFFT/2,NFFT,fs);
[Xspec, F, T,P] = spectrogram(X,NFFT,NFFT/2,NFFT,fs);
[Yspec, F, T,P] = spectrogram(Y,NFFT,NFFT/2,NFFT,fs);
[Zspec, F, T,P] = spectrogram(Z,NFFT,NFFT/2,NFFT,fs);
E = ((Wspec.^2)/2) + ((Xspec.^2) + (Yspec.^2) + (Zspec.^2))/4;     
Ix = real(conj(Wspec).* Xspec).*(sqrt(2));  
Iy = real(conj(Wspec).* Yspec).*(sqrt(2));  
Iz = real(conj(Wspec).* Zspec).*(sqrt(2));  

theta = atan2(-Iy, -Ix);

%Vx = -(abs(E).*cos(theta))';
%Vy = -(abs(E).*sin(theta))';

Vx = -cos(theta)';
Vy = -sin(theta)';
E = E';
absE = abs(E);


thresh = mean( absE(:) ) /10;
[nullindex(1,:)] = find( absE(:) < thresh );
Vx(nullindex) = 0;
Vy(nullindex) = 0;
absEN = absE /sqrt( max(max(absE)) );

Vx = Vx.*absEN;
Vy = Vy.*absEN;


%sign(thet_neg) = -1;


%%

figure(3)
imagesc(flipud(((20*log10(abs(Wspec./max(abs(W))))))), [-40 0]);
colormap(flipud(gray));
colorbar
hold on

[x,y] = meshgrid(1:size(theta,1), 1:size(theta,2));
x=fliplr(x);
quiver(y,x, Vx, Vy, scale, 'r', 'LineWidth', 2.0 );
set(gca,'XTick',[1:5:size(theta,2)]);
set(gca,'YTick',[7:7:size(theta,1)]);
set(gca,'XTicklabel',round(T(1:5:end)*1000)/1000);
set(gca,'YTicklabel',round(flipud(F(7:7:end))*1000)/1000);
ylabel('Frequency (Hz)');
xlabel('Time (s)');
title( nam, 'Interpreter','none' );

hold off


end

