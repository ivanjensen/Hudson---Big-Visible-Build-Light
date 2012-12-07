#ifndef Command_H
#define Command_H

#include <WProgram.h>
#include <wiring.h>

struct command {
  byte command;
  byte arg1;
  byte arg2;
  byte arg3;
};

typedef struct command COMMAND;

struct action {
  int (*execute)(COMMAND *);
  char *name;
};

typedef struct action ACTION;

#endif
