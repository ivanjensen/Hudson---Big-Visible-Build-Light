#include <SPI.h>
#include <stdlib.h>
#include <Ethernet.h>

#include "command.h"
#include "jsonreader.h"

const int maxLeds = 3;
int ledPins2 [maxLeds] = {1, 2, 4};  // pins for LEDs for first command
int ledPins [maxLeds] = {3, 5, 6};  // pins for LEDs for second command

int ledValues [maxLeds] = {0, 0, 0};
int ledValues2 [maxLeds] = {0, 0, 0};

const int maxCommands = 2;
ACTION new_action(int (*execute)(COMMAND *)) {
  ACTION action;
  action.execute = *execute;
  return action;
}
  

ACTION actions[maxCommands] = {
  new_action(&setLight),
  new_action(&setLight2)
};


void setup() {  
  Serial.begin(9600);  
  updateLeds();
  updateLeds2();
}


void loop() {
  COMMAND command;
  switch (buildStatus()) {
    case BUILDS_GOOD: 
      command.command = 0;
      command.arg1 = 0;
      command.arg2 = 255;
      command.arg3 = 0;
      break;
    
    case BUILDS_BAD:
      command.command = 0;
      command.arg1 = 255;
      command.arg2 = 0;
      command.arg3 = 0;  
      break;
      
    case UNDEFINED_BUILD_PROBLEM:
      command.command = 0;
      command.arg1 = 0;
      command.arg2 = 0;
      command.arg3 = 255; 
      break;
  }
  
  ACTION action = findAction(&command);
  action.execute(&command);
  delay(20000);
}


int setLight(COMMAND * command) {
  ledValues[0] = command->arg1;
  ledValues[1] = command->arg2;
  ledValues[2] = command->arg3;
  updateLeds();
}

int setLight2(COMMAND * command) {
  ledValues2[0] = command->arg1;
  ledValues2[1] = command->arg2;
  ledValues2[2] = command->arg3;
  updateLeds2();
}


ACTION findAction(COMMAND *command) {
  return actions[command->command]; 
}

void updateLeds() {
  for (int x = 0; x < maxLeds; x++) {
    analogWrite(ledPins[x], ledValues[x]);
  }   
}

void updateLeds2() {
  for (int x = 0; x < maxLeds; x++) {
    analogWrite(ledPins2[x], ledValues2[x]);
  }   
}


