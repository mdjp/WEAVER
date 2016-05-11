/* AudioClass.js
	K Brown
	University of York
	240412

	WAA routines for integration w pProcessing.js

*/

'use strict';

function AudioClass() {

var sep = '/';
var urlroot = '..'+sep+'..'+sep+'DATA'+sep;
var urllist = [
	//urlroot+'MaesHw'+sep+'mh3_000_ortf_48k.wav', // stereo IR for now!
	//urlroot+'HamMau'+sep+'hm2_000_ortf_48k.wav', // stereo IR for now!
	urlroot+'HamMau'+sep+'hm2_000_ortf_MLresamp44k1.wav', // stereo IR for now!
	urlroot+'MaesHw'+sep+'shotST44k1.wav', // stereo IR for now!
	urlroot+'genned'+sep+'rnoise44k1.wav', // mono genned noise 1.5s
	
	//urlroot+'MaesHw'+sep+'metadataNNN.wav', // format tbd: contains direction info per frq encoded into a wav container 
	//urlroot+'HamMau'+sep+'hm2_000_ortf_48k.wav', // stereo IR for now!
	//urlroot+'HamMau'+sep+'metadataNNN.wav', 
];
var actx;
var gconv;
var gpan;
var pn = {}; // holder for panner node vars
var listener;
var ln = {}; // holder for ln vars
var ggain;

var playingnotes=[];
var ga = {}; // global audio statii
ga.DEBUG = true;

var bl;	// buffer loader

var self;
self = this;
var loaded = 0;
var graphinitialised = 0;

if (document.readyState != 'loading'){
	main();   
} else {
	document.addEventListener(
	'DOMContentLoaded', main );   
}

function main() {

	initBaseAudio();
	if ( ( urllist != undefined ) && ( urllist.length > 0 ) ) {
		console.log('About to load URL list');
		getresources(); // calls init when fin
	} else {
		console.log('Probable error: didnt detect an URL list!!!');
		initAudioGraph();
	}
}

function finishedLoading() {
	console.log('finished loading');
	self.loaded = 1;
	initAudioGraph();
}

function getresources() {
	bl= new BufferLoader(
		actx,
		urllist,
		finishedLoading
	);	
	bl.load();
}

function initBaseAudio() {
	window.AudioContext = window.AudioContext || window.webkitAudioContext;
  	actx = new AudioContext();
	navigator.getUserMedia = navigator.getUserMedia || navigator.mozGetUserMedia || navigator.webkitGetUserMedia;
}

function create3DPanner() {

	pn.p = new THREE.Vector3( 0,0,1 ); // position
	pn.p.maxd = 10;
	pn.p.refd = 5;
	pn.o = new THREE.Vector3( 0,0,-1 ); // orientation

//	var pannode = ctx.createSpatialPanner(); // chrome doesnt support spatial panner
	gpan = actx.createPanner();
	gpan.panningModel = 'equalpower'; // or 'HRTF'
	
	gpan.distanceModel = 'linear'; // or 'inverse' or 'exponential', 
	//see dox @ http://webaudio.github.io/web-audio-api/#idl-def-DistanceModelType
	
	gpan.refDistance = pn.p.refd;
	gpan.maxDistance = pn.p.maxd;

	gpan.rolloffFactor = 1;
	gpan.coneInnerAngle = 60;
	gpan.coneOuterAngle = 120;
	gpan.coneOuterGain = 0.05;
	
	gpan.setPosition(pn.p.x, pn.p.y, pn.p.z );
	gpan.setOrientation(pn.o.x, pn.o.y, pn.o.z );

	/*var listener = actx.listener; // audioListener Deprecated but its replacement
	 spatialListener not impl in chrome!
	*/

	listener = actx.listener;

	ln.p = new THREE.Vector3( 0,0,0 ); // position
	ln.o={};
	ln.o.f = new THREE.Vector3( 0,0,1 ); // 'front' vector
	ln.o.u = new THREE.Vector3( 0,1,0 ); // 'up' vector
	listener.setPosition( ln.p.x, ln.p.y, ln.p.z );
	listener.setOrientation(ln.o.f.x, ln.o.f.y, ln.o.f.z, ln.o.u.x, ln.o.u.y, ln.o.u.z ); // right,up
	// set up listener and panner position information
}

function kassert( exprresult ) {
	if ( exprresult != true ) {
		console.log('Assert Fail');
	}
}

function initAudioGraph() {

	// individual note chains will connect to conv
	if ( !self.loaded )
		return;
	
	var cbuf = bl.bufferList[0];
	if (cbuf === undefined )
		return;
		
	gconv = actx.createConvolver();
	gconv.buffer = cbuf;

	create3DPanner();
	kassert(gpan !== undefined);
	
	ggain = actx.createGain();
	ggain.gain.value = 1.0; // set using value but modify using gain

	gconv.connect(gpan);
	gpan.connect( ggain );
	ggain.connect(actx.destination);
	self.graphinitialised = 1;
}

function hasfinished( noteitem ) {
	if ( actx.currentTime > ( noteitem.endtime + 0.001 ) ) {
		return true;
	} else {
		return false;
	}
}

this.checkAudioEvents = function() {
	var len;
	var i;
	var pn;
	len = playingnotes.length;
	for ( i=len-1; i>=0; i-- ) {
		pn = playingnotes[i];
		if ( hasfinished( pn ) ) {
			if (ga.DEBUG) {
				console.log('purging '+i );
			}
			
			// first purge all objs scheduled vals that might have any remaining
			pn.osc.frequency.cancelScheduledValues( 0 );
			pn.filt.frequency.cancelScheduledValues( 0 );
			pn.gain.gain.cancelScheduledValues( 0 );
			pn.ngain.gain.cancelScheduledValues( 0 );
			
			// following is unclear wrt spec: does stop autodiconnect? does a gc of the node stop & disconnect?
			// whats worse is how can it be tested wrt processor/resources usage?
			// note the node is only the main thread interface of the sound thread's processing nodes...
			// TBD
			// also: try/catch everything because stop on already timed out node causes trap!
			// however all below code MIGHT be redundant IFF underlying system is intelligent enough to release all resources on
			// timed out nodes!
			
			// also - what happens to a disconnected 'chain'  - does the disconnect ripple back?
			
			// safe way Im trying to do below assumes nothing is done implicitly on timeout

		/*			
			try {
				pn.osc.stop(0);
			}catch(err) {}
			try {
				pn.osc.disconnect();
			}catch(err) {}
			pn.osc = undefined;
			
			try {
				pn.shot.stop(0);
			}catch(err) {}
			try {
				pn.shot.disconnect();
			}catch(err) {}
			pn.shot=undefined;
			
			try {
				pn.noise.stop(0);
			}catch(err) {}
			try {
				pn.noise.disconnect();
			}catch(err) {}
			pn.noise=undefined;

			pn.filt.disconnect();
			pn.filt = undefined;

			pn.gain.disconnect();
			pn.gain = undefined;

			pn.ngain.disconnect();
			pn.ngain = undefined;

			pn=undefined;
*/
			playingnotes.splice( i, 1 );
		} 
	}
}

this.createAudioEvent = function( aparamsf, ind ) {

	if ( !self.loaded ) {
		return;
	}
	if ( !self.graphinitialised ) {
		initAudioGraph();
	}
	// floats passed from processing to params need to already be suitably mapped
	// KEEP IN SYNC WITH PROCESSING CODE.
	var pp = {};
	pp.nu =   aparamsf[0]; // onset time real s;
	pp.frqs = aparamsf[1]; // eg 4000;
	pp.frqe = aparamsf[2]; // eg 100;
	pp.dur =  aparamsf[3]; // eg 2.5 (ms);
	 // for now mapfrom Ainic ~~ mndiff 
	//pp.diffuamt = (1-aparamsf[5])*(1-aparamsf[5]);
	pp.diffuamt = aparamsf[5];
	
	var ae = new Object();

	ae.o={}; // osc
	ae.f={}; // filt
	ae.g={}; // osc gain
	ae.n={}; // noise/gain

	ae.o.v0 = pp.frqs;
	ae.o.v1 = pp.frqe;

	ae.f.v0 = 5000;
	ae.f.v1 = 200;
	ae.f.Q = {};
	ae.f.g = 1.0;
	ae.f.Q.v0 = 10; // for lp, high q's nvg

	ae.g.v0 = .1;
	ae.g.v1 = 0.001;
	
	ae.n.v0 = pp.diffuamt;
	ae.n.v1 = 0; // traps out if end val is 0	
	ae.n.v1 = 0.001;

	ae.dur = pp.dur;
	ae.starttime = actx.currentTime;
	ae.endtime = ae.starttime+ae.dur;
	if ( ga.DEBUG ) {
		console.log(ae.starttime+' -note- '+ae.endtime );
	}
	
	ae.osc = actx.createOscillator();
	ae.osc.frequency.value  = ae.o.v0;
	//ae.osc.type = 'triangle';
	ae.osc.type = 'square';
	ae.osc.onended = function() {
		self.checkAudioEvents();
	}
	
	ae.filt = actx.createBiquadFilter();
	ae.filt.type = 'lowpass';
	ae.filt.Q.value = ae.f.Q.v0;
	ae.filt.gain.value = ae.f.g; // only relev for 'peaking' types etc
	ae.filt.frequency.value = ae.f.v0;
	
	ae.gain = actx.createGain();
	ae.gain.value = ae.g.v0;
	
	ae.shot = actx.createBufferSource();
	ae.shot.buffer = bl.bufferList[1];

	ae.noise = actx.createBufferSource();
	ae.noise.buffer = bl.bufferList[2];

	ae.ngain = actx.createGain();
	ae.ngain.value = ae.n.v0;
	
	// NOT DESTROYED YET
	ae.lfo1O = actx.createOscillator();
	ae.lfo1O.type = 'sine';
	ae.lfo1O.frequency.value  = 5;
	ae.lfo1G = actx.createGain();
	ae.lfo1G.gain.value  = 500;
	
	
	
	// nb cancelScheduledValues is avail for any > starttime
	playingnotes.push( ae );
	console.log('push to len'+playingnotes.length );

	ae.lfo1O.connect( ae.lfo1G );
	ae.lfo1G.connect( ae.osc.frequency );

	ae.osc.connect( ae.filt );
	ae.filt.connect( ae.gain );
	ae.gain.connect( gconv );
	ae.shot.connect( gconv );
	ae.noise.connect( ae.ngain );
	ae.ngain.connect( gconv );

//	ae.osc.frequency.setValueAtTime( ae.o.v0, ae.starttime );
	ae.filt.frequency.setValueAtTime( ae.f.v0, ae.starttime );
	ae.gain.gain.setValueAtTime( ae.g.v0, ae.starttime );
	ae.ngain.gain.setValueAtTime( ae.n.v0, ae.starttime );

//	ae.filt.frequency.exponentialRampToValueAtTime( ae.f.v1, ae.starttime+( ae.dur ) ); // ae.dur*3/3
	ae.gain.gain.exponentialRampToValueAtTime( ae.g.v1, ae.endtime );
	ae.ngain.gain.exponentialRampToValueAtTime( ae.n.v1, ae.endtime );
	//ae.osc.frequency.linearRampToValueAtTime( ae.o.v1, ae.endtime );
	//ae.filt.frequency.linearRampToValueAtTime( ae.f.v1, ae.endtime );
	//ae.gain.gain.linearRampToValueAtTime( ae.g.v1, ae.endtime );
	ae.osc.start(0);
	ae.lfo1O.start(0);
	ae.shot.start(0);
	ae.noise.start(0);
	ae.osc.stop( ae.endtime+0.005 );
	ae.shot.stop( ae.endtime+0.005 );
	ae.noise.stop( ae.endtime+0.005 );
	ae.lfo1O.stop( ae.endtime+0.005 );
}

this.audioStep = function() {
	self.checkAudioEvents();
}

}; // eo AudioClass
