function procIRs3( params )
%% procIRs3
%{
	K Brown
	Audio Lab
	18/4/2016
	event detect using diff(IR^2)
%}


%% INIT CODE - PATHS
global p;
tmp=[];tmp1=[]; tmp2=[]; deb=[]; %#ok<*NASGU>

clc;
close all hidden;

thismfilename=mfilename; fprintf( '\n@%s: Starting %s on ', datestr(now), thismfilename );

p.khostid=checkhost2e();	% see which machine we're running on so can use different paths, path sep etc etc
if p.khostid==2 % ELECPC224
	fprintf( 'ELECPC\n' );
	%disp('wrong host'); return;
	p.sep='\'; %#ok<UNRCH>
	p.GDROOT = 'C:\User Files\GoogleDrive';
	addpath(genpath([ p.GDROOT '\XFER\funcs' ] ));
	addpath(genpath([ p.GDROOT '\XFER\kbmatlab' ] ));
elseif p.khostid==3 || p.khostid == 6 % LANGMAC/WeaverMBP
	fprintf( 'MAC\n' );
	%disp('wrong host'); return;
	p.sep='/';
	p.GDROOT = '/Users/kennethbrown/GoogleDrive';
	addpath(genpath([ p.GDROOT '/XFER/funcs' ] ));
	addpath(genpath([ p.GDROOT '/XFER/kbmatlab' ] ));
else
	disp('Wrong Host\n'); return;
end
p.genversion=mfilename;
p.gendate=date;
p.filesroot = [p.GDROOT p.sep 'EGHH' p.sep 'DATA ALL' p.sep];

% CFG ---------------------------

p.DEBUG=1;
p.PLOTQ=1;

ctl.windS = 64;
ctl.NFFT = 64;
% IntensityAnalysis uses 50% fixed overlap
ctl.hopS = floor(ctl.windS/2); assert(ctl.hopS==ctl.windS/2);
p.nchans = 4;
ctl.MINSPECTDB=-90;
ctl.WCHANIND=1;
ctl.XCHANIND=2;
ctl.YCHANIND=3;
ctl.ZCHANIND=4;
dur = 0.2;
scale=0.1;

%% ~CFG ---------------------------


if nargin < 1
	params.inp.files = { ...
		...% [ p.filesroot 'HamMau' p.sep 'hm2_000_bformat_48k.wav' ], ...
		...% [ p.filesroot 'Forest' p.sep 'koli_snow_site1_4way_bformat' ], ...
		...%[ p.filesroot 'Alquin' p.sep 'alcuin_s1r1_bformat.wav' ], ...
		[ p.filesroot 'MaesHw' p.sep 'mh3_000_bformat_48k.wav' ], ...
	};
	params.inp.mictypes = { ...
		...%'SPS422B', ...
		...%'st450', ...
		...%'?',...
		'?',...
	};
	params.inp.expsrs = [...
		...%48000, ...
		...%96000, ...
		...%48000, ...
		48000, ...
	]; %#ok<*NBRAK>
	params.inp.durs = [...
		...%
		...%
		...%
		0.2, ...
	];
end

%{
  B-format:
	W omni (pressure)
	X-+ rear->front pressure gradient
	Y-+ right->left		"
	Z-+ down->upcoef	"
%}

%% MAIN

gnfs = length(params.inp.files);
for i = 1:gnfs
	[Fs,spec] = doafile( params, i );
end


%% functions

	function [Fs,wspec,events] = doafile( params, i )
		events = {};
		
		fn = params.inp.files{i};
		try
			[IR,Fs] = audioread( fn );
		catch err
			disp(err.message);
		end
		assert( ~isempty(IR) );
		if Fs ~= params.inp.expsrs(i)
			error( fprintf( 'sr mismatch exp %i act %i\n', Fs, params.inp.expsrs(i) ));
		end
		
		nchans = size( IR, 2 ); assert( nchans == p.nchans );
		nsamps = size( IR, 1 );
		durStot = nsamps/Fs;
		if durStot > params.inp.durs[i]
			lastsamp = ceil(floor(params.inp.durs(i)*Fs)/ctl.hopS)*ctl.hopS;
			IR( (lastsamp+1):end,: ) = [];
		end

		if 1 % gen wspec, remove hf bins, 
			[wspec.spec,wspec.f,wspec.t]=spectrogram(IR(:,ctl.WCHANIND), ctl.windS, ctl.windS-ctl.hopS, ctl.windS, Fs );
			cutoff=4500;
			okbins = wspec.f <= cutoff;
			wspec.spec = wspec.spec(okbins,:);
			wspec.f = wspec.f(okbins);

			figure;
			mySpectrogram( wspec, '', Fs, ctl.MINSPECTDB );
		end
		
		
		
		fNOP();
		
	end


	function params = makeparamsST()
		params=[];
	end
	
end % eof

