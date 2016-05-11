function strok = sanitize( striNG )
	if nargin < 1
		striNG = '1//2\\3__4--5';
		
	end
		
	bads = ['/','\','_'];
	REP = '-';
	strok = striNG;
	for cc=bads
		[~,inds] = find( striNG == cc );
		strok( inds ) = REP;
	end
end

