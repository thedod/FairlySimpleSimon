
/* Simon Sings - a memory game for 4 leds, 4 switches and a buzzer.
 "Sings" is the sound-enhanced version of "Fairly Simple Simon".
 No relation to the Singh family :)
 
 Breadboard diagram, video, etc. at http://bit.ly/simonsings
 
 After reset, Simon plays a bar from "Simple Simon says", and
 you start playing a game at level 4.
 
 Playing a game at level N:
 1) Simon picks a random sequence of N LED flashes.
 2) Simon waits for you to press any button when ready.
 3) Simon "says" the sequence. Memorize it.
 4) You should then repeat the sequence on the buttons.
    * If you're right, Simon plays the song, and you start
      a level N+1 game at step 1.
    * If you push a wrong button, Simon plays a sad tune,
      and you go back to step 2.
 
 cc-by-sa by @TheRealDod,
 Nov 23, 2010
 */
#include "pitches.h"
const int NLEDS = 4; 
const int LEDPINS[NLEDS] = {
  5,6,9,10}; // Need to be PWM pins, and we need 3 and 11 free (for tone())
const int SWITCHPINS[NLEDS] = {
  15,16,17,18}; // Analog inputs 1-4
const int SWITCHPRESSED = 1; // 1 or 0, for normally-open/closed switches
const int SPEAKERPIN = 4;
const int NOTES[NLEDS] = {
  NOTE_C4, NOTE_D4, NOTE_E4, NOTE_F4};

const int FADESTEPS = 8;
const int FADEINDURATION = 200;
const int FADEOUTDURATION = 150;
const int SEQDELAY = 50; // Millis between led flashes.
const int PAUSEB4SEQ = 500; // Millis before starting the sequence.
const int MINLEVEL = 4;
const int MAXLEVEL = 16;
int gameLevel;
int simonSez[MAXLEVEL]; // sequence of 0..NLEDS-1


// -- song-array note fields --
// Tone
const int NOTETONE = 0;
const int SILENCE = 0;
const int ENDOFSONG = -1;
// Duration
const int NOTEDURATION = 1;
const int SINGLEBEAT = 125; // Note duration (millis) is multiplied by this
const float PAUSEFACTOR=0.2; // relative length of silence after playing a note
// LED
const int NOTELED = 2;
const int ALLLEDS = -1;

int WINSONG[][3] = {
  {SILENCE,2,ALLLEDS}
  ,{NOTE_E4,1,2}
  ,{NOTE_E4,1,2}
  ,{NOTE_E4,1,2}
  ,{NOTE_F4,1,3}
  ,{NOTE_E4,1,2}
  ,{NOTE_D4,3,1}
  ,{NOTE_G4,1,ALLLEDS}
  ,{NOTE_G4,1,ALLLEDS}
  ,{NOTE_G4,1,ALLLEDS}
  ,{NOTE_A4,2,ALLLEDS}
  ,{NOTE_G4,5,ALLLEDS}
  ,{ENDOFSONG,ENDOFSONG,ENDOFSONG}
};

int LOSESONG[][3] = {
  {NOTE_B5,2,3},{NOTE_A5,2,2},{NOTE_GS5,2,1},{NOTE_G5,8,ALLLEDS},{ENDOFSONG,ENDOFSONG,ENDOFSONG}
};

void setup() {
  // Analog in 0 should *not* be connected.
  // It's mama's little PRNG :)
  randomSeed(analogRead(0));
  pinMode(SPEAKERPIN,OUTPUT);
  noTone(SPEAKERPIN);
  gameLevel=MINLEVEL;
  for (byte l=0; l<NLEDS; l++) {
    pinMode(LEDPINS[l], OUTPUT);
  }
  //Serial.begin(9600);
  // Visual feedback after reset. Also good as a cable check :)
  playWinSequence(); 
}

void loop() {
  int done;
  initGameSequence(gameLevel);
  done = 0;
  while (!done) {
    getSwitchStroke();
    delay(PAUSEB4SEQ);
    playGameSequence(gameLevel);
    if (playerGuess(gameLevel)) {
      playWinSequence();
      done = 1;
      if (gameLevel<MAXLEVEL) {
        gameLevel++;
      }
    } 
    else {
      playLoseSequence();
    }
  }
}

void initGameSequence(int gameLevel) {
  // assertion: gameLevel<=MAXLEVEL
  for (int i=0; i<gameLevel; i++) {
    simonSez[i]=random(NLEDS);
  }
}

void playGameSequence(int gameLevel) {
  for (int i=0; i<gameLevel; i++) {
    playLed(simonSez[i]); // Fade LED and play its note
  }
}

void fadeLed(int theLed,int val,int duration) {
  int fadeStep=256/FADESTEPS;
  int fadeDelay=duration/FADESTEPS;
  for (int i=0; i<256; i+=fadeStep) {
    if (theLed>=0) {
      analogWrite(LEDPINS[theLed],val?i:255-i);
    } 
    else { // ALLLEDS
      for (int j=0; j<NLEDS; j++) {
        analogWrite(LEDPINS[j],val?i:255-i);
      }
    }
    delay(fadeDelay);
  }
  // force val (in case fadeStep doesn't divide 256)
  if (theLed>=0) {
    digitalWrite(LEDPINS[theLed],val); 
  }
  else {
    for (int j=0; j<NLEDS; j++) {
      digitalWrite(LEDPINS[j],val); 
    }
  }
}

void playLed(int theLed) { // Fade LED and play its note
  tone(SPEAKERPIN,NOTES[theLed]);
  fadeLed(theLed,HIGH,FADEINDURATION); // Fade in
  noTone(SPEAKERPIN);
  fadeLed(theLed,LOW,FADEOUTDURATION); // Fade out
}

int playerGuess(int gameLevel) {
  for (int i=0 ; i<gameLevel ; i++) {
    int guess=getSwitchStroke();
    //Serial.print(guess,DEC);
    //Serial.print(",");
    //Serial.println(simonSez[i]);
    if (guess!=simonSez[i]) {
      return 0;
    } 
    else {
      playLed(guess); // Fade LED and play its note
    }
  }
  return 1;
}

void playSong(int song[][3]) {
  for (int note=0; song[note][NOTETONE]!=ENDOFSONG; note++) {
    int theDuration=SINGLEBEAT*song[note][NOTEDURATION];
    int theTone=song[note][NOTETONE];
    if (theTone) {
      tone(SPEAKERPIN,theTone);
    }
    int theLed=song[note][NOTELED];
    fadeLed(theLed,HIGH,theDuration); // Fade in
    noTone(SPEAKERPIN);
    fadeLed(theLed,LOW,theDuration*PAUSEFACTOR); // Fade out + silence between note
  }
}

int playWinSequence() {
  playSong(WINSONG);
}

int playLoseSequence() {
  playSong(LOSESONG);
}

int getSwitchStroke() {
  while (get1stPressedSwitch()>=0) {
    // flush everything until no switch is pressed
    delay(50);
  }
  while (get1stPressedSwitch()<0) {
    // wait for next press
    delay(50);
  }
  return get1stPressedSwitch();
}

int get1stPressedSwitch() {
  for (int i=0; i<NLEDS; i++) {
    if (digitalRead(SWITCHPINS[i])==SWITCHPRESSED) {
      return i;
    }
  }
  return -1;
}









