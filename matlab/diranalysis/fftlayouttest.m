% test which way round an fft is in lower half?

sr=44100;
s=zeros(1,44160);
f=2000;
len=length(s)
t=(0:(len-1))/sr;
s=sin(2*pi*f*t);

%sound( s, sr );

nfft=128;
hop=nfft/2;
[spec.spec,spec.f,spec.t]=spectrogram(s, nfft, hop, nfft, sr );
wind = hann(nfft)';
sti = 1;
eni = sti+128-1;
ncols = length(spec.t)
X=zeros(nfft,ncols);
for col=1:ncols
	X(1:nfft,col) = fft( s(sti:eni).*wind );
	sti=sti+hop;
	eni=eni+hop;
	if eni > length(s)
		break;
	end
end

mySpectrogram(spec,'',sr,-70 );
figure;
f = ((1:nfft)-1) / nfft * sr;
mns=sum( abs(X),2 );
plot( f, mns);
figure;
plot( abs( X(1:(end/2),1 ) ) );

% SO FFT is 0:NYQ:0 not -NYQ:0:NYQ !!!
% so use FFT(1:(end/2))










disp('fin');

