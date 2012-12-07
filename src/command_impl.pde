#include "command.h"

void resetCommand(COMMAND * cmd) {
   cmd->command = NULL;
   cmd->arg1 = NULL;
   cmd->arg2 = NULL;
   cmd->arg3 = NULL;
}

COMMAND * listenForCommand() {
  int byteCount = 0;
  byte input;
  COMMAND cmd;
  
  for ( ; ; ) {
    input = waitAndRead();
    Serial.println(input, DEC);
    if (byteCount != 0 && input == '#') {
      // '#' out of sequence will reset the command read
        byteCount = 0;
        resetCommand(&cmd);
        continue;
    }
    
    switch (byteCount) {
      case 0: {
        if (input != '#') {
          // Wait for a '#' before processing.
           continue; 
        }  
      }
      case 1: {
         cmd.command = input; 
         break;
      }
      case 2: {
         cmd.arg1 = input; 
         break;
      }
      case 3: {
        cmd.arg2 = input;
        break;
      }
      case 4: {
        if (cmd.command < 0 || cmd.command >= maxCommands) {
          byteCount = 0;
          resetCommand(&cmd);  
          continue;
        }
        cmd.arg3 = input;

        Serial.flush();
        return &cmd;
      }
      default: {
          byteCount = 0;
          resetCommand(&cmd);  
          continue;
      }
    }
    byteCount++;
  }          
  return NULL;
}

byte waitAndRead() {
    while (Serial.available() == 0) {
	  // do nothing
    }
    return (byte) Serial.read();
}
