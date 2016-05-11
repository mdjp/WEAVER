function [w,x,y,Fs] = fakeIR( Fs, plottit )

if nargin < 1
	Fs = 44100;
end
if nargin < 2
	plottit = true;
end

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
IRo=zeros(No,nitems);

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
	rng(i);
	ra = rand( 1,nitems );
	angles = ( ra * 2 * pi ) - (pi);
	angles(1) = 0.1;

	rb = rand( 1,nitems );
	times = ( rb * dur );
	times = sort(times);
	times = log(100*times);
	time = times-min(times);
	times = times*dur/max(abs(times));
	offsets = max( floor( times * Fs ),1 );

	rc = rand( 1,nitems );
	mainlevels = ( rc .* log(sort(times,'descend')) );
	mainlevels = -mainlevels;
	mainlevels = mainlevels / max(mainlevels);
	mainlevels = mainlevels *.85;
	mainlevels = fliplr(mainlevels);
	mainlevels(1) = .95;

	IRo(Wo,:) = sqrt(2)*mainlevels;
	IRo(Xo,:) = mainlevels.*cos(angles);
	IRo(Yo,:) = mainlevels.*sin(angles);

	if plottit
		figure;
		stem(times,mainlevels,'-ob');
		fullscn2(gcf);
		hold all;
		quiver( times, mainlevels, IRo(Xo,:), IRo(Yo,:), ':r'  );
		title( sprintf( 'I = %d', i ) );
	end
	w = zeros( ns,1 );
	x = zeros( ns,1 );
	y = zeros( ns,1 );
	w(offsets) = IRo(Wo,:);
	x(offsets) = IRo(Xo,:);
	y(offsets) = IRo(Yo,:);


	if plottit && 0
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