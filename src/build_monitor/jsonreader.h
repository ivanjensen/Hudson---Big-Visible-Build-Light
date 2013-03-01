#ifndef Jsonreader_H
#define Jsonreader_H

// buildStatus return values
#define UNDEFINED_BUILD_PROBLEM 0
#define BUILDS_GOOD 1
#define BUILDS_BAD 2

/* Returns:
 *  UNDEFINED_BUILD_PROBLEM - unexpected problem (no builds, no connection to server, etc)
 *  BUILDS_GOOD - all builds ok
 *  BUILDS_BAD - at least one build broken
 */
int buildsStatus();

#endif
