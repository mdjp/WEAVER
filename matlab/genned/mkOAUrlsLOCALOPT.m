function mkOAUrlsLOCALOPT()


warning( 'off','MATLAB:dispatcher:pathWarning' );
addpath(genpath('C:\User Files\GoogleDrive\XFER\funcs'));
addpath(genpath('C:\User Files\GoogleDrive\XFER\kbmatlab'));
addpath(genpath('/Users/kennethbrown/GoogleDrive/XFER/funcs'));
addpath(genpath('/Users/kennethbrown/GoogleDrive/XFER/kbmatlab'));

%root = 'C:\REPOS\300001\OpenAirBUP\OPENAIRLIB_N\SITES\DEFAULT\FILES\AURALIZATION\DATA';
%srch = [root '\**\*.wav'];

root = '/Users/kennethbrown/Desktop/Local/WEAVER/ASSETS/OpenAirBUPx/OPENAIRLIB_N/SITES/DEFAULT/FILES/AURALIZATION/DATA';
lenroot=length(root);
srch = [root '/**/*.wav'];
sep = '/';

tree = rdir( srch );
ni = length(tree);
fp=fopen( 'OALocalURLsMAC.js','w');
fprintf( fp,'var tmp = document.getElementById("OpenAirURLsDiv");\n' );
fprintf( fp,'tmp.innerHTML = // ecmascript6 can use backticks for multiline "template" literals\n' );
fprintf( fp,'`<select id="OpenAirURLs">\n');

fprintf( fp, '<option value = "nullIR_St_48k.wav">Mic Live Stream Only</option>\n');
fprintf( fp, '<option value = "nullIR_St_48k.wav">nullIR_St_48k.wav</option>\n');



info = struct;
for i = 1:ni
	info(i).url = tree(i).name;
	info(i).urlname =info(i).url((lenroot+2):end);
	info(i).urlname( info(i).urlname == sep ) = '-';
	info(i).nchans = howmanychans( info(i).url );
end


filesdone=zeros(1,ni);
for type = [1 2 3 4 5] % sort in blocks in chans 2, 1, 4(Bfmt), 6(5.1), other order
	for i = 1:ni
		nchans = info(i).nchans;
		urlname = info(i).urlname;
		if type == 1 % stereo
			fprintf( '#%i - %i chans %s\n', i, nchans, urlname );
			if nchans ~= 2
				continue;
			end
		end
		if type == 2 % mono
			if nchans ~= 1
				continue;
			end
		end
		if type == 3 % bfmt
			if nchans ~= 4
				continue;
			end
		end
		if type == 4 % 5.1
			if nchans ~= 6
				continue;
			end
		end
		if filesdone(i) == 1
			continue;
		end
		filesdone(i) = 1;
		fprintf( fp, '<option value = "%s">%s</option>\n', info(i).url, urlname );
	end
end
fprintf( fp,'</select>`;');
fclose(fp);

disp('Fin');

	function nc = howmanychans( xurl )
		ainfo = audioinfo( xurl );
		nc = ainfo.NumChannels;
		%[tmp,Fs] = audioread( xurl );
	end

end