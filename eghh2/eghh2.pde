/* @pjs preload="hmexterior.jpg"; "auddata16ind4.txt"; "metadata12ind6.txt"; "metadata12ind4.txt" */

/*
  eghh2.pde
  K Brown
  24.4.2016 15:34
  Univ of York 2016
  TODO - convert to web and integrate with sound generation
*/

// CONFIG
//boolean bdotests = true;
int bdotests = 1;
int DEBUG = 0;

// JS: put js prototypes here 
interface JavaScript
{	
	void doticker( int frame ); // purely to demonstrate
	class AudioClass;
	void AudioClass.audioStep();
	void AudioClass.createAudioEvent( float [] aparams );
}
JavaScript javascript = null;
void setJavaScript(JavaScript js) { javascript = js; }


// flock glob(s)
Flock flock;

// clock globs for now - to conv to class?
//size(1920-1,1200-1); // unf MUST do this here, & cant redo see docn PROJECTOR
// the -1 get rid of scrollbars even though css says {display:block;}
//size(1920-1,1080-1);   // ELECPC224 SCREEN
//size(1280-1,800-1);  // MBP
// CHROME: dont sub 1
// FFOX: sub 1
//int scnw = 1920-1;
//int scnh = 1080-1;
int scnw = 1920;
int scnh = 1080;

int cx, cy;
float secondsRadius;
float clockDiameter;
PVector handend;
Tick ticker;
int clocklast;
float galpha = 25;
int ftt=1;

// data
float [] ffar; // total blocks calcd by matlab. May as well do the mapping in matlab!
float [] ffir16ar; // resampled audio to viz? WIP
int ffarblocki=0;
int ffarblocksz = 12;
/* floats and mappings: see createAudioEvent : pass this in as float[ffarblocksz] (though [0] n/u by audio)
float time00 // 0.0-55.0 : onset time of this event
float aud01 // mapped to start frq eg 4000 Hz
float aud02 // mapped to end frq eg 200 Hz
float aud03 // mapped to dur eg 1000 ms
float vis04 // mapped to nboids spawned
float vis05 // mapped to inicolour
float vis06 // maped to inisize
float vis07 // mapped to inidirn
float vis08 // mapped to dsize
float vis09 // mapped to dcolour
float vis10 // mapped to dur/dnapha
'//' delim between blocks : will be converted as NaN - ignore this
// that should do - prob hard to glean 9 params for an event in matlab - but can use v for a and a for v as well if necc;
*/
float kNaN = (0/1)*0;

PImage img;


// audio
AudioClass audio;

/* --------- SETUP AND DRAW ------------------- */

void setup() {
  size(scnw,scnh);   // ELECPC224 SCREEN
  //println(":Setup");
  
  loadData();
  frameRate(60);
  stdColorMode();
  imageMode(CORNER); // default anyway, uses upper left as origin (0,0)
  initclock(); // this needs modding to pre parse all the audio data into events @ times
  initboids();
  audio = new AudioClass(); // self initialising
}

void draw() {
  if ( bdotests==1 ) {
    dotests();
  }
  runclock(); // this needs modding to generate audio and visual events based on parsed data
  
  flock.run(); // update graphics as necc
  if (audio) {
		audio.audioStep(); // update audio as necc
  }
}


void loadData() {
  String lines[];
  lines = loadStrings("auddata16ind4.txt");
  //println("there are " + lines.length + " lines");
  for (int i = 0 ; i < lines.length; i++) { 
    //println(lines[i]);
  }
  ffir16ar = float( lines );

  //lines = loadStrings("metadata12ind4.txt");
  lines = loadStrings("metadata12ind6.txt"); // I think the prob is all events occur in 1st 1s time span!
  //println("there are " + lines.length + " lines");
  for (int i = 0 ; i < lines.length; i++) { 
    //println(lines[i]);
  }

  ffar = float( lines );
  img = loadImage( "hmexterior.jpg" );
	img.resize(scnw, scnh);
}

// -------------------- TESTS --------------------------------------------

int frame=0;
int diver = 60;

int once = 1;
void dotests() {
  if (once==1) {
    once=0;
    // any one off tests here!
  }
  // continuous tests here
  //doticker( frame++, diver );
}

/* ----------------------FUNCTIONS & CLASSES ----------------------------*/
void mousePressed() {
  if (mouseButton == LEFT) {
    // Add a new boid into the System
    flock.addBoid(new Boid(mouseX,mouseY, -1,  colorfromparams(mouseX*mouseY,1,1), colorfromparams(mouseX/mouseY,1,1) ) );
  }else if (mouseButton == RIGHT) {
    flock.delall();
  }
}


color colorfromparams( float fa, float fb, float fc ) { // 0.0-1.0
  float hh=fa*TWO_PI;
  float ss=0.666*fb;
  float bb=1.333*(1-fb);
  color c = HSBtoRGB( hh,ss,bb ); // 0-twopi,0-2/3, 0-4/3
  //println(hex( c ));
  return c;
}


// returns arrray[blocksize] on success, -1 on fail ie past eof, or any NaNs at all in cur data block
float [] getcurrblock( float [] src, int blocki, int blocksize ) {
	float tmp;
	int maxlen = src.length();
	int stofst = blocki * blocksize;
	if ( (stofst+blocksize) > (maxlen-1) ) {
		return -1;
	}
	float [] data = new float[blocksize];
	for( int i = 0; i < (blocksize-1); i++ ) { // last SHOULD be a NaN to allow between-block comments
		tmp = src[stofst+i];
		if ( tmp != tmp ) { // true if NaN
			return -1;
		} else {
			data[i] = tmp;
		}
	}
	tmp = src[stofst+blocksize-1];
	kassert( tmp != tmp );
	return data;
}


void runclock() {
  
  int s = redrawcbg( galpha );
  drawhand( s, 5 ); 
  
  if ( s != clocklast ) {
    clocklast = s;
    if (s == 0 ) {
      flock.delall();
      ticker.consumewrapped();
      ffarblocki = 0;
    }
    float angle = map(s, 0, 60, 0, TWO_PI) - HALF_PI;
    //if ( angle < 0 ) {
    //  angle+=TWO_PI;
    //}
    
 /* -- PARSE DATA form params - for now mapping mainly in matlab -
    floats and mappings: see createAudioEvent : pass this in as float[ffarblocksz] (though [0] n/u by audio)
	float time00 // 0.0-55.0 : onset time of this event BUT as it stands only up to 1 event can be procd per 'tick'
	float aud01 // mapped to start frq eg 4000 Hz
	float aud02 // mapped to end frq eg 200 Hz
	float aud03 // mapped to dur eg 1000 ms
	float vis04 // mapped to nboids spawned
	float vis05 // mapped to inicolour 1 0.0-1.0
	float vis06 // mapped to inisize 2-10?
	float vis07 // mapped to inidirn (angle 0-tupi)
	float vis08 // mapped to incolor 2 0.0-1.0
	float vis09 // resvd for dcolour
	float vis10 // resvd for dur/dnapha etc
	==11 + comment = 12 lines
 */
    float [] thisblock = getcurrblock( ffar, ffarblocki, ffarblocksz );
    int blokok = 0;
    deblog( "Blocki = "+ffarblocki );
    if ( thisblock==null || ( thisblock.length != ffarblocksz ) || (thisblock[0]==-1) ) {
	    deblog( "EOF@"+ffarblocki );
    } else {
    	blokok = 1;
    	for ( float val : thisblock ) {
    		deblogx( val + ", " );
    	}
    }
    
    if ( ( blokok ) && ( thisblock[0] <= s ) ) {
		ffarblocki++;
		
	    int Nb = thisblock[4];
	    angle = thisblock[7];
	    color fillc = colorfromparams( 1-thisblock[5], 1-thisblock[8], 1.0 );
	    color strokec = colorfromparams( thisblock[5], thisblock[8], 1.0 );
	    float inisize = thisblock[6];
	    for (int i = 0; i < Nb; i++) {
	      flock.addBoid(
	        new Boid( handend.x, handend.y, angle, fillc, strokec, inisize ) // todo add yet more params per boid
	      );
				if ( audio ) {
					audio.createAudioEvent( thisblock, i );
				}
	    }
   	 }

	// Eo MAP/ SPAWN
	
	
    int maxboids = 50;
    int len = flock.boids.size();
    if ( len > maxboids ) {
      for ( int i=len-maxboids; i >= 0; i-- ) {
        flock.boids.remove(i);
      }
    }
  }
}

color HSBtoRGB( float h,float s, float v ) {
//  h=h*TWO_PI;
//  s=s*2/3;
//  v=v*4/3;
  
  float r=v*(1+s*(cos(h)-1));
  float g=v*(1+s*(cos(h-2.09439)-1));
  float b=v*(1+s*(cos(h+2.09439)-1));
  return color(r*255.0,g*255.0,b*255.0);
}


void initboids() {
  flock = new Flock();
}

void initclock() {
  int radius = min(width, height) / 2;
  secondsRadius = radius * 0.875;
  clockDiameter = radius * 1.8;
  cx = width / 2;
  cy = height / 2;
  handend = new PVector();
  ticker = new Tick();
  clocklast = -1;
}

void stdColorMode() {
  colorMode( RGB, 255.0, 255.0, 255.0, 255.0 );
}


void debDrawIR(float curalpha) {
	int ntodo = ffir16ar.length;
	if (ntodo < 1 )
		return;
	
	int cursampind = 0;
	int npersec = ntodo / 60;
	int todos0 = ntodo - ( npersec*60 );
	float angleperstep = TWO_PI / float(ntodo);
	float curangle = 0.0-(TWO_PI/4);
	float ex, ey;
	float stx, sty;
  stroke(100,100,100, curalpha);
  strokeWeight(1.0);
  stx = cx+(clockDiameter/2*cos(curangle));
	sty = cy+(clockDiameter/2*sin(curangle));
	float SCALEFAC = 25*clockDiameter/16; // the 30 is because curr audio isnt normalised

	for ( int s = 0; s < 60; s++ ) {
		int nnn;
		if ( s == 0 )
			nnn=todos0;
		else
			nnn=npersec; 
		for ( int i = 0; i < nnn; i++ ) {
			float thissamp = ffir16ar[cursampind];
			thissamp *= SCALEFAC;
			float thisrad =  (clockDiameter/2) + thissamp;
			ex = cx+(thisrad*cos(curangle));
			ey = cy+(thisrad*sin(curangle));
	    line(stx, sty, ex, ey);
			stx = ex;
			sty = ey;
			curangle += angleperstep;
			cursampind++;
		}
	}
}


int redrawcbg( float curalpha ) {

  int s = ticker.update();
  if ( (ticker.peekwrapped()!=0) || (ticker.juststarted()!=0) ) {
    ticker.consumewrapped();
    curalpha = 255.0;
  }   
    
  //background(0);
  float imgcuralpha = curalpha > 240 ? 255 : curalpha;
  tint(255,255,255, imgcuralpha);  // Apply transparency without changing color
  //background(img);
  image( img, 0, 0 );
  noTint();
    
  // Draw the clock background ARGB
  fill(10,10,10, curalpha);// note its rgb if specd as int (or argb?tbc), els if float, grey: alpha is float
  noStroke();
  ellipse(cx, cy, clockDiameter, clockDiameter); //<>//

	// zero marker in blue
  stroke(50,50,200,curalpha);
  strokeWeight(3);
  handend.x = cx
  handend.y = cy - secondsRadius;
  line(cx, cy, handend.x, handend.y);
    
  /* Draw the minute ticks
  stroke(255,100,100, curalpha);
  strokeWeight(3.0);
  beginShape(POINTS);
  for (int a = 0; a < 360; a+=6) {
    float angle = radians(a);
    float x = cx + cos(angle) * secondsRadius;
    float y = cy + sin(angle) * secondsRadius;
    vertex(x, y);
  }
  endShape();
  */
  
  debDrawIR(curalpha);
  drawhand( s, curalpha );
  return s;
}

void drawhand( int s, float curalpha ) {
  // hand
  // Angles for sin() and cos() start at 3 o'clock;
  // subtract HALF_PI to make them start at the top
  float sr = map(s, 0, 60, 0, TWO_PI) - HALF_PI;
  // Draw the hand of the clock
  stroke(255.0,(curalpha*2)%255.0);
  strokeWeight(1);
  handend.x = cx + cos(sr) * secondsRadius;
  handend.y = cy + sin(sr) * secondsRadius;
  line(cx, cy, handend.x, handend.y);
}



class Tick {
  int s;
  int lasts;
  int bwrapped;
  int bjs;
  long tmillis;
  
  Tick() {
    s=0;
    lasts = 0;
    bwrapped = 0;
    tmillis=0;
    bjs=1;
  }
  
  int update() {
    tmillis = millis();
    int snow = second();
    if ( snow != lasts ) {
      lasts = snow;
      s++;
      if ( s >= 60 ) {
        bwrapped = 1;
        s=0;
      }
    }
    return s;
  }
   //<>// //<>//
  int peekwrapped() {
    return bwrapped;
  }

  int juststarted() {
    return bjs;
  }
   //<>// //<>//
  int consumewrapped() {
    bjs=0;
    int tmp = bwrapped;
    bwrapped = 0;
    return tmp;
  }
  
}


// The Flock (a list of Boid objects)

class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids

  Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
  }
  
  void delall() {
    int len = boids.size();
    for ( int i=len-1; i >= 0; i-- ) {
      boids.remove(i);
    }
  }

  void run() {
    for (Boid b : boids) {
      b.run(boids);  // Passing the entire list of boids to each boid individually
    }
  }

  void addBoid(Boid b) {
    boids.add(b);
  }

} // eo flock class;



// The Boid class

class Boid {

  PVector location;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  long tmtime;
  long duration;
  float curalpha;
  float inialpha;
  color inicolorf;
  color inicolors;
  float inivscale;
  float inisize;

  Boid(float x, float y, float inivelangle, color iinicolorf, color iinicolors, float iinisize ) {
    acceleration = new PVector(0, 0);

    // This is a new PVector method not yet implemented in JS
    // velocity = PVector.random2D();
 //<>// //<>//
    float angle;
    // Leaving the code temporarily this way so that this example runs in JS
    if ( inivelangle > TWO_PI || inivelangle < 0 ) {
      angle = random(TWO_PI);
    }else{
      angle = inivelangle;
    }
    inivscale = 2.0;
    velocity = new PVector(cos(angle)*inivscale, sin(angle)*inivscale);

    location = new PVector(x, y);
    r = iinisize; // eg 3 to 10
    maxspeed = 6;
    maxforce = 0.05;
    tmtime = millis();
    duration = 2000;
    curalpha = 255.0;
    inialpha = 255.0;
    inicolors = iinicolors;
    inicolorf = iinicolorf;
  }

  void run(ArrayList<Boid> boids) {
    flock(boids);
    update();
    borders();
    render();
  }

  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids) {
    PVector sep = separate(boids);   // Separation
    PVector ali = align(boids);      // Alignment
    PVector coh = cohesion(boids);   // Cohesion
    // Arbitrarily weight these forces
    sep.mult(1.5);
    ali.mult(1.0);
    coh.mult(1.0);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
  }

  // Method to update location
  void update() {
    // Update velocity
    velocity.add(acceleration);
    // Limit speed
    velocity.limit(maxspeed);
    location.add(velocity);
    // Reset accelertion to 0 each cycle
    acceleration.mult(0);
    long newmillis = millis();
    long deltat = newmillis-tmtime;
    curalpha = map(deltat, 0, duration, inialpha, 0);
    if ( curalpha < 1.0 ) {
      curalpha = 0.0;
    }
  }

  // A method that calculates and applies a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, location);  // A vector pointing from the location to the target
    // Scale to maximum speed
    desired.normalize();
    desired.mult(maxspeed);
 //<>// //<>//
    // Above two lines of code below could be condensed with new PVector setMag() method
    // Not using this method until Processing.js catches up
    // desired.setMag(maxspeed);

    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    return steer;
  }

  void render() {
    if ( curalpha < 1.0 ) {
      return;
    }
    color fillc = color( red(inicolorf), green(inicolorf), blue(inicolorf), curalpha ); 
    color strokec = color( red(inicolors), green(inicolors), blue(inicolors), curalpha );
    
    // Draw a triangle rotated in the direction of velocity
    fill( fillc, curalpha );
    stroke( strokec, curalpha );
    pushMatrix();
    translate(location.x, location.y);

    float theta = velocity.heading2D() + radians(90);
    // heading2D() above is now heading() but leaving old syntax until Processing.js catches up
    rotate(theta);
    beginShape(TRIANGLES);
    vertex(0, -r*2);
    vertex(-r, r*2);
    vertex(r, r*2);
    endShape();
    popMatrix();
  }

  // Wraparound
  void borders() {
/*
    if (location.x < -r) location.x = width+r;
    if (location.y < -r) location.y = height+r;
    if (location.x > width+r) location.x = -r;
    if (location.y > height+r) location.y = -r;
    if (location.x < -r) location.x = width+r;   
*/
    if  ( (location.x < -r) || (location.x > width+r) ) { 
      velocity.x = -velocity.x;
    }
    if ( (location.y < -r) || (location.y > height+r) ) {
      velocity.y = -velocity.y;
    }
  }

  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids) {
    float desiredseparation = 25.0f;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(location, other.location);
        diff.normalize();
        diff.div(d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // sum.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } 
    else {
      return new PVector(0, 0);
    }
  }

  // Cohesion
  // For the average location (i.e. center) of all nearby boids, calculate steering vector towards that location
  PVector cohesion (ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all locations
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.location); // Add location
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the location
    } 
    else {
      return new PVector(0, 0);
    }
  }
} // eo boid class

void deblog( String ss ) {
  if (DEBUG) {
  	println(ss);
  }
}

void deblogx( String ss ) {
  if (DEBUG) {
  	print(ss);
  }
}

void kassert( int bval ) {
  if (DEBUG) {
    if( bval ) {
   	;
    }else{
      println("kAssert Fail");
    }
  }
}