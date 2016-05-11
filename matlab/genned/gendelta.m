sr=44100;
nfs=1024;
dur = 1/10;
nts=dur*sr;
t=1:nts;
t=t/sr;
f=linspace(20,4000,nts);
phases=rand(1,nfs)*pi;
phases = phases -(pi/2);
for ff=1:nfs
	s(ff,:)=sin( (2*pi*f(ff)*t)+phases(ff) );
end
s=sum(s,1);
s=s/max(max(abs(s)));

plot(s);
