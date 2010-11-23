/* Utility to check wiring for "Simon Sings" game. 
 Breadboard diagram, game code, etc. at http://bit.ly/simonsings

 The following jumpers come out of the board: +5V, Ground, reset, speaker,
 4 switch jumpers and 4 LED jumpers. This tool helps you check that all is
 connected correctly, and sort out between the jumpers (it's easy to tell 
 between LED and switch jumpers because they come from different parts of
 the board, but this tool can help you tell which LED/switch is which).
 
 With the Arduino running this:
 * Connect the switch jumpers to SWITCHPINS (otherwise, LEDs will act funny).
 * Take a LED jumper and connect to one of the LEDPINS. Now that you know which
   LED is on, connect the jumper to the corresponding LEDPIN. Repeat with all LEDPINS
 * Push a switch. One of the LEDs will blink (and you'll hear its corresponding tone).
   If it's not the one associated with the button, replace SWITCHPINS between where the
   button's jumper is and where it should be.
  
 Fault detection tips:
 * If all leds blink *unless* you press their buttons, and there's a constant tone from the
   speaker, you need to reverse the definition of SWITCHPRESSED (both in the code here and
   in the game's code) because your buttons are normally-closed and mine are normaly-open
   (or is it the other way around? Whadever).
 * If a LED is constantly off, there's a problem with the wiring of the LED/resistor.
 * If a LED sometimes blinks and sometimes doesn't, there's a problem with the wiring of
   the corresponding switch/pull-up-resistor.
 * If all LEDs blink whether you push a button or not, check the +5V jumper :)
  
 cc-by-sa by @TheRealDod,
 Nov 23, 2010
 
 */
#include "pitches.h"
const int NLEDS = 4;
const int SPEAKERPIN = 4;
const int LEDPINS[NLEDS] = {
  5,6,9,10}; // Need to be PWM pins, and we need 3 and 11 free (for tone())
const int SWITCHPINS[NLEDS] = {
  15,16,17,18}; // Analog inputs 1-4
const int NOTES[NLEDS] = {
  NOTE_C4, NOTE_D4, NOTE_E4, NOTE_F4};
const int SWITCHPRESSED = HIGH; // HIGH or LOW, depends on type of switch
const int DELAY = 100;
int blinkState = HIGH;

void setup() {
  //Serial.begin(9600);
  for (int i=0 ; i<NLEDS ; i++) {
    pinMode(LEDPINS[i],OUTPUT);
  }
}

void loop() {
  blinkState = !blinkState;
  int note2play = 0;
  for (int i=0; i<NLEDS ; i++) {
    int pressed = digitalRead(SWITCHPINS[i])==SWITCHPRESSED;
    if (pressed) {
      note2play = NOTES[i];
    }
    digitalWrite(LEDPINS[i],!pressed||blinkState);
  }
  if (note2play) {
    tone(SPEAKERPIN,note2play);
  } else {
    noTone(SPEAKERPIN);
  }
  delay(DELAY);
}




