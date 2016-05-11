function [Azimuth,Energy,Diffuseness] = pulkki2dDirAn( w, x, y, Fs, winsize, hopsize )

if nargin < 6
	hopsize=256; % Do directional analysis with STFT
end
if nargin < 5
	winsize=512;
end

i=2;
alpha=1./(0.02*Fs/winsize);
Intens=zeros(hopsize,2)+eps;
Energy=zeros(hopsize,2)+eps;
for time=1:hopsize:(length(x)-winsize)
	% moving to frequency domain
	W=fft(w(time:(time+winsize-1)).*hanning(winsize));
	X=fft(x(time:(time+winsize-1)).*hanning(winsize));
	Y=fft(y(time:(time+winsize-1)).*hanning(winsize));
	W=W(1:hopsize);X=X(1:hopsize);Y=Y(1:hopsize);
	%Intensity computation
	tempInt = real(conj(W) * [1 1 ] .* [X Y])/sqrt(2);%Instantaneous
	Intens = tempInt * alpha + Intens * (1 - alpha); %Smoothed
	%plot( Intens(:,1)); hold all; plot(Intens(:,2));
	%drawnow;
	%pause(.1);
	%cla
	% Compute direction from intensity vector
	Azimuth(:,i) = round(atan2(Intens(:,2), Intens(:,1))*(180/pi));
	%Energy computation
	tempEn=0.5 * (sum(abs([X Y]).^2, 2) * 0.5 + abs(W).^2 + eps);%Inst
	Energy(:,i) = tempEn*alpha + Energy(:,(i-1)) * (1-alpha); %Smoothed
	%Diffuseness computation
	Diffuseness(:,i) = 1 - sqrt(sum(Intens.^2,2)) ./ (Energy(:,i));
	i=i+1;
end

end % func

