function id2 = checkhost2e()
	try
		opt=evalc( 'system(''getmac'')' );
		opt=char(opt);
		optmac = evalc( 'system(''netstat -I en0'')' );
	catch err
		disp(err);
	end
	%{

	**elecpc224:
	Physical Address    Transport Name
	=================== ==========================================================
	7C-05-07-0C-C6-D1   \Device\Tcpip_{0AF8D461-8BA2-4536-8BFC-FDCA9FA6B5AF}

	**LANGMAC116
	34:36:3b:c9:1d:64

	**ELECPC269
	Physical Address    Transport Name                                            
	=================== ==========================================================
	40-16-7E-A4-5B-C4   \Device\Tcpip_{8ECB0C27-937C-49F2-ACAE-F3B7D82D6E3C}      
	
	%}
	% eek - i think its in unicode?? strsplit doesnt work...
	
	if ~isempty(strfind( opt, '7C-05-07-0C-C6-D1' ))
		id2=2; % ELECPC224
	elseif ~isempty(strfind( opt, '5C-26-0A-80-CC-CF' ))
		id2=1; % BL7
	elseif ~isempty(strfind( optmac, '34:36:3b:c9:1d:64' ))
		id2=3; % LANGMAC
    elseif ~isempty(strfind( optmac, '00:23:32:bd:9f:ca' ))
		id2=4; % MACKYB
    elseif ~isempty(strfind( opt, '40-16-7E-A4-5B-C4' ))
		id2=5; % ELECPC269
    elseif ~isempty(strfind( optmac, '10:dd:b1:dc:bd:22' ))
		id2=6; % WeaverMBP
	else
		id2=0;
	end
end
