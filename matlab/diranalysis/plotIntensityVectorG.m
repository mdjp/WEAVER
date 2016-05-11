function [az, el, psiW, Ea, Ix, Iy, Iz ] = plotIntensityVectorG(IR, fs, NFFT, dur, scale, fn, cutoffhz )


if(nargin == 0)
	load;
end
[~,nam,~]=fileparts( fn );

% Script to test FO_ISM function

if dur > 0
	durS = dur*fs;
	IR = IR( 1:durS, : );
end

W=IR(:,1);
X=IR(:,2);
Y=IR(:,3);
Z=IR(:,4);

% fft
[Wspec, F, T,P] = spectrogram(W,NFFT,NFFT/2,NFFT,fs);
[Xspec, F, T,P] = spectrogram(X,NFFT,NFFT/2,NFFT,fs);
[Yspec, F, T,P] = spectrogram(Y,NFFT,NFFT/2,NFFT,fs);
[Zspec, F, T,P] = spectrogram(Z,NFFT,NFFT/2,NFFT,fs);

% remove hf bins above cutoff?
if cutoffhz > 0
	okrows = F<=cutoffhz;
	F=F(okrows);
	Wspec = Wspec( okrows,:);
	Xspec = Xspec( okrows,:);
	Yspec = Yspec( okrows,:);
	Zspec = Zspec( okrows,:);
end

Ea = ((Wspec.^2)/2) + ((Xspec.^2) + (Yspec.^2) + (Zspec.^2))/4;

Z0 = 413.3; % @20degC
Ix = real(conj(Wspec).* Xspec).*(sqrt(2) ); % from pilkki merimma SIRR, eqn [10], but omit zivide by Z0
Iy = real(conj(Wspec).* Yspec).*(sqrt(2) );  
Iz = real(conj(Wspec).* Zspec).*(sqrt(2) );  

% calc atans before scale down to decrease rounding errs
theta = atan2(-Iy, -Ix);
% from Michael's code... add el
az = atan2(Iy , Ix);
el = atan2(Iz,(sqrt(((Ix).^2)+((Iy).^2))));

%Vx = -(abs(E).*cos(theta))';
%Vy = -(abs(E).*sin(theta))';

Vx = -cos(theta)';
Vy = -sin(theta)';
E = Ea';

% kbinsert1: diffuseness estimate from Lokki,T, Diffuseness & intensity
% analysis of spatial impulse responses, which in turn w2as from Merimaa &
% Pulkki SIRR 2004
% P corresp to WSpec and U corresp to directional spectra XYZ
%{
normI = sqrt( Ix.^2 + Iy.^2 +Iz.^2 );
Emu = abs(Wspec).^2 + ( ( abs(Xspec).^2 + abs(Yspec).^2 + abs(Zspec).^2 ) / 2 ); % IS THIS CORRECT what is mod(X') in sirr?
thiW = sqrt(2) * normI ./ Emu;
debmaxest = max(max(thiW)); % eek root 2!!!
figure;
imagesc(flipud(((20*log10(abs(thiW./max(max(abs(thiW)))))))), [-90 0]);
colormap(flipud(gray));
%}

% kb insert2
%{
absE = abs(E).^0.25;
Dn = ((Wspec.^2)/2) + ((Xspec.^2) + (Yspec.^2) + (Zspec.^2))/4;
%thresh = mean( absE(:) ) /100;
%[nullindex(1,:)] = find( absE(:) < thresh );
%Vx(nullindex) = 0;
%Vy(nullindex) = 0;
absEN = absE / ( max(max(absE)) );
%absEN = absEN.^2;
thiW = absEN;
Vx = Vx.*absEN;
Vy = Vy.*absEN;
% eo kbinsert2

%sign(thet_neg) = -1;
%}


% have another go at calc diffuseness:
nbins=size(Wspec,1);
ntsteps=size(Wspec,2);
Xprime=zeros( nbins, ntsteps, 3 );
binfrq = fs/(NFFT/2);
hoptime = (NFFT/2)/fs;


Wspec3 = zeros( size( Xprime ));
Xprime(:,:,1) = Xspec;
Xprime(:,:,2) = Yspec;
Xprime(:,:,3) = Zspec;
Wspec3(:,:,1) = Wspec;
Wspec3(:,:,2) = Wspec;
Wspec3(:,:,3) = Wspec;


	function kn = knorm( vecord3 )
		assert( size( vecord3,3 ) == 3 );
		kn = sqrt( sum( (vecord3.^2), 3 ) );
		squeeze(kn);
	end

	function kap = kabspow( vecord3, pp )
		assert( size( vecord3,3 ) == 3 );
		vecord3 = abs(vecord3);
		vecord3 = vecord3.^pp;
		kap = ( sum( vecord3, 3 ) );
		squeeze(kap);
	end



num = 2 * Z0 * knorm( real( conj( Wspec3 ).* Xprime ) ); 
denom = (abs(Wspec).^2) + ( kabspow( Xprime,2 ) /2 );
psiW = 1.0-(num./denom);
psiW = (num./denom);

figure(2);
psiWN = psiW / max(abs(psiW(:)));
waterfall( ((1:nbins)-1)*binfrq, (1:ntsteps)*hoptime, flipud(psiWN') );



% since truncated at 4k vals all wrong...
absE = abs(E).^0.5;
Dn = ((Wspec.^2)/2) + ((Xspec.^2) + (Yspec.^2) + (Zspec.^2))/4;
thresh = mean( absE(:) ) / 20;
[nullindex(1,:)] = find( absE(:) < thresh );
absE(nullindex) = 0;
Vx(nullindex) = 0;
Vy(nullindex) = 0;
absEN = absE / ( max(max(absE)) );
%absEN = absEN.^2;
psiW = absEN;
Vx = Vx.*absEN;
Vy = Vy.*absEN;



% kb insert 3


%%

figure(3)
imagesc(flipud(((20*log10(abs(Wspec./max(abs(W))))))), [-40 0]);
colormap(flipud(gray));
colorbar
hold on


[x,y] = meshgrid(1:size(theta,1), 1:size(theta,2));
x=fliplr(x);
quiver(y,x, Vx, Vy, scale, 'r', 'LineWidth', 1.0 );
set(gca,'XTick',[1:5:size(theta,2)]);
set(gca,'YTick',[7:7:size(theta,1)]);
set(gca,'XTicklabel',round(T(1:5:end)*1000)/1000);
set(gca,'YTicklabel',round(flipud(F(7:7:end))*1000)/1000);
ylabel('Frequency (Hz)');
xlabel('Time (s)');
title( [nam 'flip'], 'Interpreter','none' );

hold off

%{
 no frominspection the flip version is correct....
figure(4)
imagesc(flipud(((20*log10(abs(Wspec./max(abs(W))))))), [-40 0]);
colormap(flipud(gray));
colorbar
hold on


[x,y] = meshgrid(1:size(theta,1), 1:size(theta,2));
%x=fliplr(x);
quiver(y,x, Vx, Vy, scale, 'r', 'LineWidth', 1.0 );
set(gca,'XTick',[1:5:size(theta,2)]);
set(gca,'YTick',[7:7:size(theta,1)]);
set(gca,'XTicklabel',round(T(1:5:end)*1000)/1000);
set(gca,'YTicklabel',round(flipud(F(7:7:end))*1000)/1000);
ylabel('Frequency (Hz)');
xlabel('Time (s)');
title( nam, 'Interpreter','none' );
%}

hold off





end





