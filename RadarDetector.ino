//Includes
#include <SPI.h>

//Detector to Microcontroller connections
int Detector_V_UP = 16; // Analog value from 0-1V based on strength of signal detected
int Detector_V_DN = 17; // inverse V_UP signal so 1-0V based on signal strength detected

//Synthesizer to Microcontroller connections
int CSB_A10  = 24;
int CE_A11   = 25;
int SDI_MOSI = 26;
int SCK_SCK  = 27;
int Muxout   = 40;

//Microcontroller to LED
int LED_RED = 41;

void setup() 
{
  pinMode(LED_RED, OUTPUT);

  Serial.begin(115200);

  // AD8314 analog inputs
  pinMode(Detector_V_UP, INPUT);
  pinMode(Detector_V_DN, INPUT);

  // LMX2592 control pins
  pinMode(CSB_A10, OUTPUT);
  pinMode(CE_A11, OUTPUT);
  pinMode(Muxout, INPUT); // lock condition of synthesizer

  digitalWrite(CSB_A10, HIGH);   // inactive
  digitalWrite(CE_A11, LOW);     // keep synth off until ready

  // SPI1 on Teensy 4.1
  SPI1.setMOSI(SDI_MOSI);
  SPI1.setSCK(SCK_SCK);
  SPI1.begin();

  // Enable synthesizer
  digitalWrite(CE_A11, HIGH);
  delay(10);


}

void loop() 
{
  //start Synthesizer
  digitalWrite(CE_A11, HIGH);

  //main detection section
  float Det_Voltage = analogRead(Detector_V_UP)*(5.0 / 1023.0); // voltage received by Detector
  if(Det_Voltage > 0.05 && Det_Voltage < 0.2)
  {
    //weak signal detected
    digitalWrite(41, LOW);
  }
  if(Det_Voltage > 0.35 && Det_Voltage < 0.5)
  {
    //medium signal detected
    digitalWrite(41, HIGH);
  }
  if(Det_Voltage > 0.5 && Det_Voltage < 1)
  {
    //strong signal detected
    digitalWrite(41, HIGH);
  }



  
}
