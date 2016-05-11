function [IRsc,Fs,params] = loadIR( ind, durov )
%% loadIR
%{
	K Brown
	Audio Lab
	18/4/2016
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



%% ~CFG ---------------------------
if nargin < 1
	ind = 1;
end
params.inp.files = { ...
	[ p.filesroot 'HamMau' p.sep 'hm2_000_bformat_48k.wav' ], ...
	[ p.filesroot 'Forest' p.sep 'koli_snow_site1_4way_bformat' ], ...
	[ p.filesroot 'Alquin' p.sep 'alcuin_s1r1_bformat.wav' ], ...
	[ p.filesroot 'MaesHw' p.sep 'mh3_000_bformat_48k.wav' ], ...
	[ p.filesroot 'genned' p.sep 'nullIR_48k.wav' ], ...
	[ p.filesroot 'sonix' p.sep 'm_bf_2m30stretch100.wav' ], ...
};
params.inp.mictypes = { ...
	'SPS422B', ...
	'st450', ...
	'?',...
	'?',...
	'?',...
	'?',...
};
params.inp.expsrs = [...
	48000, ...
	96000, ...
	48000, ...
	48000, ...
	48000, ...
	48000, ...
]; %#ok<*NBRAK>
params.inp.durs = [...
	inf,...
	inf,...
	inf,...
	inf, ...
	inf, ...
	inf, ...
];
params.inp.examinedlatFRsamps = [...
	555,...
	-1,...
	-1,...
	-1,...
	-1,...
	-1,...
];



%{
  B-format:
	W omni (pressure) scaled by sqrt(2)
	X-+ rear->front pressure gradient
	Y-+ right->left		"
	Z-+ down->upcoef	"
%}

%% MAIN

gnfs = length(params.inp.files);

for i = ind
	[IRsc,Fs] = doafile( params, i, durov );
end

end

%% functions

	function [IRsc,Fs] = doafile( params, i, durov )
		
		fn = params.inp.files{i};
		dursamps = durov*params.inp.expsrs(i);
		if durov < params.inp.durs(i)
			dursamps = durov*params.inp.expsrs(i);
		try
			[IRsc,Fs] = audioread( fn, [1,dursamps] );
		catch err
			disp(err.message);
		end
		assert( ~isempty(IRsc) );
		if Fs ~= params.inp.expsrs(i)
			error( fprintf( 'sr mismatch exp %i act %i\n', Fs, params.inp.expsrs(i) ));
		end
		
		nchans = size( IRsc, 2 ); assert( nchans == 4 );
		nsamps = size( IRsc, 1 );
	end

end % eof

