#include "WProgram.h"
void setup();
void loop();
int ledPin =  13;    // LED connected to digital pin 13
int inByte = 0;         // incoming serial byte
char inChar = 'x';
void setup() {
  Serial.begin(9600);
  pinMode(ledPin, OUTPUT); 
}
 
int quiet_count = 0;

void loop()
{
  inChar = Serial.read();
  
  if(inChar == 'a') {
     digitalWrite(ledPin, HIGH);   // set the relay on
     Serial.println("START");
      Serial.print("char: "); 
     Serial.println( inChar);
      //delay(1000);                  // wait for a second
      inChar = 'x';
      
    
  }
  else if ( (inChar == 'b')) {
     digitalWrite(ledPin, LOW);    // set the relay off
     Serial.println("STOP");
     Serial.print("char: "); 
     Serial.println( inChar);
     inChar = 'x';
   //delay(1000);                  // wait for a second
  }else {
  
  }
  
  // otherwise echo anything else sent to us
 // while(Serial.available()) {
  //  inByte = Serial.read();
  //  Serial.print(inByte);
 // }
  delay(100);
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

