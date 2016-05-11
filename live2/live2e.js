/* live2e.js
	K Brown
	University of York
	160303

	live input testing and WIP for live convolution

*/

(function testliveconv() {
var context;
var bufferLoader;
var urllist;
var convolver;
var liveStream;
var lsgain;
var opgain;
var loaded = false;
var micrdy = false;
var self = this;
var selectedind = 0;

function init() {


	var tmp = document.getElementById("OpenAirURLs");
	tmp.addEventListener( "change", selConvSource );

  window.AudioContext = window.AudioContext || window.webkitAudioContext;
  context = new AudioContext();

	selConvSource();
	
  navigator.getUserMedia = navigator.getUserMedia || navigator.mozGetUserMedia || navigator.webkitGetUserMedia;
  initMic();
}

function allready() {
	return loaded & micrdy;
}


function finishedLoading(thebufferlist) {
	console.log('finished loading');
	loaded = true;
	trygo();
}

function trygo() {
	if( allready() ) {
		console.log('starting' );
		start();
	}
}

function selConvSource() {
	var e = document.getElementById("OpenAirURLs");
	var ind = e.selectedIndex;
	if ( ind === undefined ) {
		ind = 0;
	}
	selectedind = ind;
	var url = e.options[ind].value;
	var urllist = [];
	urllist[0] = url;		
  bufferLoader = new BufferLoader(
    context,
		urllist,
    finishedLoading
    );
  bufferLoader.load();
}

function start() {
	console.log('conv');
	//console.log(convolver);
	if (convolver !== undefined ) {
		
		convolver.disconnect();
		convolver = undefined;
		//console.log(convolver);
	}
	if ( lsgain === undefined ) {
		lsgain = context.createGain();
		lsgain.gain.value = 1.0;
		liveStream.connect(lsgain);
	}
	if (selectedind == 0 ) { // special case: no conv at all
		lsgain.connect(context.destination);
	} else {
		opgain = context.createGain();
		opgain.gain.value = 1.0;	
		convolver = context.createConvolver();
		if (selectedind == 1 ) { // special case: null ir doent need normalization
			convolver.normalize = false;
		}else{
			convolver.normalize = true; // certain IRs NEED norming otherwise vol is much too much too loud
		}
		convolver.buffer = bufferLoader.bufferList[0];
		console.log( 'IR len samps = ' + convolver.buffer.length );
		lsgain.connect(convolver);
		convolver.connect(opgain)
		opgain.connect(context.destination);
	}
}

function terminate() {
	liveStream.disconnect();
	convolver.disconnect();
}

function initMic() {
  if (!navigator.getUserMedia) {
    window.alert('getUserMedia not supported on your browser!');
  	return;
  }
  	
  navigator.getUserMedia(
  	{ audio: true },
  	function(stream) {
  		liveStream = context.createMediaStreamSource(stream);
  		micrdy = true;
  		trygo();
    }, 
    function(err) {
    	console.log('The following gUM error occured: ' + err);
    }
  );
}

init();

}());
