function [w,x,y,Fs] = fakeIR( Fs, plottit )

if nargin < 1
	Fs = 44100;
end
if nargin < 2
	plottit = true;
end

warning( 'off','MATLAB:dispatcher:pathWarning' );
addpath(genpath('C:\User Files\GoogleDrive\XFER\funcs'));
addpath(genpath('C:\User Files\GoogleDrive\XFER\kbmatlab'));
addpath(genpath('/Users/kennethbrown/GoogleDrive/XFER/funcs'));
addpath(genpath('/Users/kennethbrown/GoogleDrive/XFER/kbmatlab'));


nitems = 35;
dur = 1.0;
ns = floor(dur*Fs);

p.lbrts=get(0, 'MonitorPositions');
try
	p.lbwh=p.lbrts(2,:)+[ ( p.lbrts(1,1)-p.lbrts(2,1) ) 0 0 0 ];
catch %#ok<CTCH> %single mon eg remote access
	p.lbwh=p.lbrts(1,:);
end

Wo = 1; Xo = 2; Yo = 3; Zo = 4; No = 4;

%{
W=S/sqrt(2)
X=S*cos(theta)*cos(phi)
Y=S*sin(theta)*cos(phi)
Z=S*sin(phi);
%}


%{
Damians notes: let eS = some rand almost descending event deltas at times t,
remainder of eventual signal will be 0;
let theta be some rand angles, per event.
eIR(Wo,1:nevents) = sqrt(2).*eS;
eIR(Xo,1:nvents) = eS.*cos(angles);
eIR(Yo,1:nvents) = eS.*sin(angles);
eIR(Zo,:) = 0;
%}

for i = 26  % make range to test diff rngs
%for i = 1:100  % make range to test diff rngs



	if 1
	IRo=zeros(No,nitems);
	rng(i);
	ra = rand( 1,nitems );
	angles = ( ra * 2 * pi ) - (pi);
	angles(1) = 0.1;

	rb = rand( 1,nitems )*90;
	times = rb;
	times = sort(times);
	times = log(10+times)-log(10);
	times = times-min(times);
	times = times+(1/20);
	times = times*dur/max(abs(times));

	offsets = max( floor( times * Fs ),1 );

	rc = rand( 1,nitems );
	mainlevels = ( rc .* (dur-times) );
	mainlevels = mainlevels-min(mainlevels);
	mainlevels = 0.85 * mainlevels / max(mainlevels);
	mainlevels(1) = .95;
	end

	if 0
	nitems = 6;
	IRo=zeros(No,nitems);
	angles = pi*[0 .5 1.0 1.5 2.0 2.5 ];
	times = [.2 .4 .6 .7 .8 .85 ];
	mainlevels = [.9 .8 .5 .6 .4 .2];
	end

	IRo(Wo,:) = sqrt(2).*mainlevels;
	IRo(Xo,:) = mainlevels.*cos(angles);
	IRo(Yo,:) = mainlevels.*sin(angles);

	if plottit
		figure;
		stem(times,mainlevels,'-ob');
		fullscn2(gcf);
		hold all;
		U = IRo(Xo,:);
		V = IRo(Yo,:);
		quiver( times, mainlevels, U, V, 0, ':r' );
		title( sprintf( 'I = %d', i ) );
		
		headlocs(2,:) = mainlevels + IRo(Yo,:);
		headlocs(1,:) = times + IRo(Xo,:);
		for jj=1:nitems
			text( headlocs(1,jj), headlocs(2,jj), sprintf('%g',floor(angles(jj)*180/pi)) );
		end
		fNOP();
		axis equal tight
		
	end
	w = zeros( ns,1 );
	x = zeros( ns,1 );
	y = zeros( ns,1 );
	w(offsets) = IRo(Wo,:);
	x(offsets) = IRo(Xo,:);
	y(offsets) = IRo(Yo,:);
	
	DOFILT=0;
	if DOFILT==1
		amt = 10/Fs;
		w = ksmoo( w, amt );
		x = ksmoo( x, amt );
		y = ksmoo( y, amt );
	end	
	DOFILT=0;
	if DOFILT==2
		filtfrq = 4000;
		d1 = designfilt('lowpassiir','FilterOrder',9, ...
		'HalfPowerFrequency',filtfrq/Fs,'DesignMethod','butter');
		w = filtfilt( d1,w );
		x = filtfilt( d1,x );
		y = filtfilt( d1,y );
		% no get ringing & neg componets to the IR
	end	


	if plottit && 1
		figure;
		plot( w, 'dk' ); hold on;
		plot( x, '.r' );
		plot( y, '.b' );
	end
	
	fNOP();
	
end

disp('Fin');

% gavins event onset method pseudocode:
% events = finddescendingzerocrossings(diff(qqqfilt( hilbert( IR(Wo,:).^2 ) )));


	function fullscn2( figh )
		set(figh,'Position', p.lbwh );
	end













end