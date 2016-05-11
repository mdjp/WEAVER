function diranalysisK2e()
% Author K Brown
% e: find top 200 peaks in actual signal then map these to fft frame times
% for events - works a bit better but prob really need to not run viz in
% second steps but as fast as poss!!!



tmp=[];tmp1=[];tmp2=[];tmp3=[];tmp4=[];
Fs=44100;

%hopsize=256; % Do directional analysis with STFT
%winsize=512;
hopsize=128;
winsize=256;

%% pulkki

if 0 % pulkki sigs
	
% this section and SIRR analysis functions: Author: V. Pulkki
% Example of directional analysis of simulated B-format recording
%
%--------------------------------------------------------------------------
% This source code is provided without any warranties as published in 
% DAFX book 2nd edition, copyright Wiley & Sons 2011, available at 
% http://www.dafx.de. It may be used for educational purposes and not 
% for commercial applications without further permission.
%--------------------------------------------------------------------------	
	
	
	sig1=2*(mod([1:Fs]',40)/80-0.5) .* min(1,max(0,(mod([1:Fs]',Fs/5)-Fs/10)));
	sig2=2*(mod([1:Fs]',32)/72-0.5) .* min(1,max(0,(mod([[1:Fs]+Fs/6]',Fs/3)-Fs/6)));
	% Simulate two sources in directions of -45 and 30 degrees
	w=(sig1+sig2)/sqrt(2);
	x=sig1*cos(50/180*pi)+sig2*cos(-170/180*pi);
	y=sig1*sin(50/180*pi)+sig2*sin(-170/180*pi);
	% Add fading in diffuse noise with  36 sources evenly in the horizontal plane
	for dir=0:10:350
		noise=(rand(Fs,1)-0.5).*(10.^((([1:Fs]'/Fs)-1)*2)); %#ok<*NBRAK>
		w=w+noise/sqrt(2);
		x=x+noise*cos(dir/180*pi);
		y=y+noise*sin(dir/180*pi);
	end
	
	[Azimuth,Energy,Diffuseness] = pulkki2dDirAn( w, x, y, Fs );
	plotEADs( Azimuth,Energy,Diffuseness );
	tilefigs(1);
	fNOP();
	close all;
	
end
 

%% ken fakeIR

if 0
	[w,x,y] = fakeIR( Fs, true ); %#ok<*UNRCH>
	[Azimuth,Energy,Diffuseness] = pulkki2dDirAn( w, x, y, Fs );
	plotEADs( Azimuth,Energy,Diffuseness );
	[eventindsH, info] = findEventIndsH();
	tilefigs(1);
	fNOP();
	close all;
end


%% main - cant put in an if & keep inner funcs - so make global
ind = 1; %ham
ind = 4; %maes
ovlen = 0.35;

ind = 6; %stretched yminst 2m30s
if ind==6
	Fs=48000;
	winsize=512;
	hopsize=256;
	ovlen = 60*2.5;
end
[IRsc,Fs,params] = loadIR( ind, ovlen );
params.curind = ind;

%%
if 0
	ind=5; % nullIR!
	ovlen = 0.1;
	[IRsc,Fs,params] = loadIR( ind, ovlen );
	params.curind = ind;
	addpath( 'C:\User Files\GoogleDrive\EGHH\SDM Code\SDM toolbox' );
	addpath( '/Users/kennethbrown/GoogleDrive/EGHH/SDM Code/SDM toolbox' );
	sdmresults = dosdm( IRsc,Fs,params );
	% NO IT DOESNT WORK: cant use B-FOrmat - need A-Format IR's & mic spacings!

fNOP();
end
%%

w=IRsc(:,1); x=IRsc(:,2); y=IRsc(:,3);

[Azimuth,Energy,Diffuseness] = pulkki2dDirAn( w, x, y, Fs, winsize, hopsize );
plotEADs( Azimuth,Energy,Diffuseness );
	
info = findEventIndsH();
	
ok = formmetadata();
fprintf( '%s', kswitch( ok, 'fm:ok','fm:failed' ) );

fNOP();
disp('fin');
return;

%tilefigs(1);
	
%% functions

%{
/* floats and mappings: see createAudioEvent : pass this in as float[ffarblocksz] (though [0] n/u by audio)
float time00 // 0.0-55.0 : onset time of this event
float aud01 // mapped to start frq eg 4000 Hz
float aud02 // mapped to end frq eg 200 Hz
float aud03 // mapped to dur eg 1.000s
float vis04 // mapped to nboids spawned eg 2-7
float vis05 // mapped to inicolour ?
float vis06 // maped to inisize eg 3-7
float vis07 // mapped to inidirn eg 0-tupi
float vis08 // mapped to dsize amt to reduce per tick 1/60
float vis09 // mapped to dcolour  "
float vis10 // mapped to dur/dnapha "
'//' delim between blocks : will be converted as NaN - ignore this
// that should do - prob hard to glean 9 params for an event in matlab - but can use v for a and a for v as well if necc;
%}


	function ok = formmetadata()
		ok=false;
		NEVITEMS = 12;
		fn = sprintf( 'metadata12ind%i.txt', ind );

		%Xtype=1; % use method?
		myevents = info.events;
		nevents = length( myevents.ts );
		
		scaleevents(); % preprocess as necc...
		
		fp = fopen( fn, 'w' );
		if fp < 3
			disp('Fn Error %s',fn);
			return;
		end
		close all;
		for fi = 1:nevents
			Athisitems11 = geneventmapping(fi); % si x 11 subitems 11 flaots each
			assert( size(Athisitems11,2) == 11 );
			for si = 1:size( Athisitems11, 1)
				fprintf( fp, '%g\n', Athisitems11(si,:) );
				fprintf( fp, '// That was item %i,%i\n', fi,si );
			end
		end
		fprintf( fp, 'EOF %i events for %i %s ', nevents, ind, params.inp.files{ind} ); % EOF marker - will be converterd to NaN on float conv
		fclose(fp);

		fnaud16 = sprintf( 'auddata16ind%i.txt', ind );

		fp = fopen( fnaud16, 'w' );
		fprintf( fp, '%g\n', info.w16/max(abs(info.w16)) );
		fclose(fp);
		ok = true;
		disp('FIN');
		return;
	%{
      zinds: [1x15 double]
       amts: [1x15 double]
     azAdeg: [21x15 double]
    mnazdeg: [1x15 double]
      Adiff: [21x15 double]
     mndiff: [1x15 double]
         ts: [1x15 double]	
	%}
		
		function scaleevents()
			% ts -> 0-59
			myevents.ts = myevents.ts * 59 / myevents.maxt;
			% amts -> 0.0-1.0;
			myevents.amts = myevents.amts./max(abs(myevents.amts));
			% az is 0-360
			% diff is 0-1 (1==diffuse)
		end
		
		function mapped = kmap( src, srcs, srce, dests, deste )
			mapped = (src-srcs)/(srce-srcs);
			mapped = (mapped * ( deste-dests ) ) + dests;
		end
		
		function thisitems11 = geneventmapping(evti)
			thisitems11 = zeros(1,NEVITEMS-1);
			% add more rows as necc for sub events...

			t=myevents.ts(evti); % const for this main event
			% for now dont gen any sub events (eg split into sep boids all
			% @ same time!)
			
			% map all in parallel jic WIP!!!
			Afs = kmap( myevents.mnazdeg, -180, 180, 200, 4000 );
			Afe = kmap( myevents.amts, 0, 1, 4000, 200 );
			Andur = kmap( myevents.amts, 0, 1, 0.5, 2.5 );
			Anboids = round((1-myevents.mndiff)*10)+1; % or 1 and loop this section nboids times
			Ainic = myevents.mndiff; % eg for each bin in non-mean array
			Ainisz = round(kmap( myevents.amts, 0, 1, 3, 15 ));
			Ainidir = kmap( myevents.mnazdeg, 0, 360, 0, 2*pi );
			Adsz = kmap(myevents.amts, 0, 1, 1.1, 0.9  ) ...
				.* kmap(myevents.mndiff, 0, 1, 0.9, 1.5);
			Adc = (-myevents.mndiff+1)*0.01;
			Addur = myevents.amts*0;

			thisitems11(1) = t;
			% for now no subevents - just select evti WIP!!!
			thisitems11(2) = Afs(evti);
			thisitems11(3) = Afe(evti);
			thisitems11(4) = Andur(evti);
			thisitems11(5) = Anboids(evti);
			thisitems11(6) = Ainic(evti);
			thisitems11(7) = Ainisz(evti);
			thisitems11(8) = Ainidir(evti);
			thisitems11(9) = Adsz(evti);
			thisitems11(10) = Adc(evti);
			thisitems11(11) = Addur(evti);
		end
	end	

	function vizevents = findEventIndsH()
		debnbins = size( Energy,1 );
		binfrqs = (1:debnbins)*(Fs/2)/debnbins;
		bins2lose = find( binfrqs > 4000, 1, 'first' );
		
		Energy(bins2lose:end,:) = [];
		Azimuth(bins2lose:end,:) = [];
		Diffuseness(bins2lose:end,:) = [];
		
		nts = size( Energy,2 );
		norgsamps = length(w);
		
		FS16 = 16000;
		vizevents.w16 = resample( w, FS16, Fs );
		assert( abs( length(vizevents.w16) - (norgsamps*(FS16/Fs) ) ) < .001 );
		
		ts = (1:norgsamps)/Fs;
		te = ((((1:nts)-1)*hopsize)+(winsize/2))/Fs;
		
		function tatind = mkwindt( zindsamp )
			tatind = ((((zindsamp)-1)*hopsize)+(winsize/2))/Fs;
		end
		
		%vizevents.events = findeventsM1(); // not enough events at least
		%for hammau
		vizevents.events = findeventsM2();
		
		function [vals,locs, wids, proms] = findpeaksK( sig, MAXEVENTS )
			len = length(sig);
			vals = [];
			locs = [];
			proms = [];
			wids = [];
			
			nsig = sig / max(abs((sig)));
			nsig( nsig < (eps*2) ) = [];
			nsiglen = length(nsig);
			nsig = sort( nsig, 'ascend' );
			nsig = nsig( 1 : (floor(nsiglen/4)) );
			noisefloor = mean(nsig);
			
			hadpeak = 0;
			thismax = 0;
			locthismax = 0;
			nnsig = sig;
			nnsig( nnsig <= noisefloor ) = 0;
			for ik = 1:len
				val = nnsig(ik);
				if val == 0
					if hadpeak
						vals = [vals thismax];
						locs = [locs locthismax];
						hadpeak = 0;
						thismax = 0;
						continue;
					end
				else % val > 0
					hadpeak = 1;
					if val > thismax
						locthismax = ik;
						thismax = val;
					end
				end
			end
			svs = sort( vals, 'descend' );

			threshval = svs( min( MAXEVENTS, end ));
			locs( vals < threshval ) = [];
			vals( vals < threshval ) = [];
			proms = vals;
		end
		
		function info = findeventsM2()
			figure;
			szw=length(w);
			subplot( 4,1,1);
			plot( ts, w, 'c' ); hold all;
			
			MnE = sum(Energy, 1 );
	
			MAXEVENTS = 200;
			[~,locs,~,proms] = findpeaksK( w, MAXEVENTS );
			
			function zi = locs2z( srcwi )
				zi = floor( srcwi / hopsize ) + 1;
				zi = unique( zi );
			end
			
			zinds = locs2z( locs );
			zinds( zinds > length(MnE) ) = [];
			
			info.zinds = zinds;
			info.amts = MnE(zinds);
			info.azAdeg = Azimuth(:,zinds);
			info.mnazdeg =  mean(info.azAdeg,1);
			figure;
			stem( zinds , info.mnazdeg,':m' ); hold on;
			axis tight;
			axi=axis;
			fac=axi(4);
			info.Adiff = Diffuseness(:,zinds);
			info.mndiff = mean(info.Adiff,1);
			stem( zinds , info.mndiff*fac,':c' );
			info.ts = mkwindt(zinds);
			info.maxt = mkwindt( length(Azimuth) );
			figure; ribbon( zinds, info.azAdeg' );
			fNOP();
		end
		
		function info = findeventsM1()
			figure;
			szw=length(w);
			subplot( 4,1,1);
			plot( ts, w, 'c' ); hold all;
			
			MnE = sum(Energy, 1 );
			
			[~,locs,~,proms] = findpeaks( MnE );
			[~,spromis] = sort(proms,'descend');
			top59i = spromis( 1: min(59,end) );
			sorginds = locs(top59i);
			top59v = MnE( sorginds );
			subplot(4,1,2:4);
			plot( te, MnE, 'k' ); hold all;
			plot( te(sorginds), top59v, 'or' );
			axis tight;
			axi=axis;
			ofstamty = axi(4)/50;
			ofstamtx = axi(2)/100;
			text( (mkwindt(sorginds)+ofstamtx), top59v+ofstamty, num2str((1:length( sorginds ))' ));
			fNOP();
			
			zinds = sort(sorginds);
			info.zinds = zinds;
			info.amts = MnE(zinds);
			info.azAdeg = Azimuth(:,zinds);
			info.mnazdeg =  mean(info.azAdeg,1);
			figure;
			stem( zinds , info.mnazdeg,':m' ); hold on;
			axis tight;
			axi=axis;
			fac=axi(4);
			info.Adiff = Diffuseness(:,zinds);
			info.mndiff = mean(info.Adiff,1);
			stem( zinds , info.mndiff*fac,':c' );
			info.ts = mkwindt(zinds);
			figure; ribbon( zinds, info.azAdeg' );
			fNOP();
		end

	end % findEventIndsH


end % file func

