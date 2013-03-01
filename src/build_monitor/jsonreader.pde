//#include <Ethernet.h>
//#include <avr/pgmspace.h>
#include "jsonreader.h"

//#define LOCATION_HOME

// ethernet shield vars
byte mac[] = {0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED};   // mac adress

#ifdef LOCATION_HOME
byte ip[] = {192, 168, 2, 95};                        // this ip 
byte server[] = {192, 168, 2, 101};                // search.twitter.com
char* search = "/~ivanjensen1/servesJsonApiUri";  // the search request
#else
byte ip[] = {10, 10, 30, 247};                        // this ip 
byte server[] = {10, 10, 2, 32};                // "builds"
char* search = "/pd/userContent/active";  // the search request
#endif

char maxId[11] = "0";                                // since_id
char buf[180];        // buffer for parsing json
byte firstRun = 1;    // mark the first run
byte charCount = 0;
int buildsOk = UNDEFINED_BUILD_PROBLEM;


//--- parse json response -------------------------------------------------

/*
 * Skip all headers of the HTTP response.
 */
void skipHeaders(Client client) {
  char c[4];
  while (client.connected()) {
    if (client.available()) {
      c[3] = c[2];
      c[2] = c[1];
      c[1] = c[0];
      c[0] = client.read();
      // Serial.print(c[0]);
      if ((c[0] == 0x0a) && (c[1] == 0x0d) && (c[2] == 0x0a) && (c[3] == 0x0d)) {
        return;
      }
    }
  }  
}



/*
 * Reads a char of the client.
 * Returns -1 if the client is no longer connected.
 */
int readChar(Client client) {
  int c = -1;
  while (client.connected()) {
    if (client.available()) {
      c = client.read();
      break;
    }
  }
  return c;
}



/*
 * Reads until one of the matching chars is found.
 */
int readMatchingChar(Client client, char *match) {
  int c = -1;
  while (!strchr(match, c)) {
    c = readChar(client);
    if (c == -1) break;
  } 
  return c;
}



/*
 * Skips the string until the given char is found.
 */
void skip(Client client, char match) {
  // Serial.println("SKIP");
  int c = 0;
  while (true) {
    c = readChar(client);
    // Serial.print(c);
    if ((c == match) || (c == -1)) {
      break;
    }
  }
}



/*
 * Reads a token from the given string. Token is seperated by the 
 * given delimiter.
 */
int readToken(Client client, char *buf, char *delimiters) {
  int c = 0;
  while (true) {
    c = readChar(client);
    if (strchr(delimiters, c) || (c == -1)) {
      break;
    }
    *buf++ = c;
  }
  *buf = '\0';
  return c;
}



/*
 * Reads a json string.
 */
void readString(Client client, char *s) {
  int c, c1 = 0;
  // Serial.println("READS");
  while (c != -1) {
    c1 = c;
    c = readChar(client);
    if ((c == '"') && (c1 != '\\')) {
      break;
    }
    *s++ = c;
  }
  *s = 0;
}



/*
 * Reads a json value. Value is returned in buf.
 */
int readValue(Client client, char *buf) {
  int c;
  // Serial.println("READV");
  skip(client, ':');
  c = readChar(client);
  if (c == '"') {
    readString(client, buf);
    // Serial.println(buf);
    c = readChar(client);
  }
  else {
    *buf++ = c;
    c = readToken(client, buf, ",}");
    // Serial.println(buf);
  }
  return c;
}



#define STATE_NONE 0
#define STATE_KEY 1
#define STATE_JOBS 2
#define STATE_JOB 3

/*
 * Reads and parses the json response.
 * Found tweets are written to the keyboard of the typewriter.
 */ 
void readResponse(Client client) {
  // Serial.println("headers");
  int buildCount = 0;
  skipHeaders(client);
  buildsOk = BUILDS_GOOD;
  skip(client, '{');   // } <- fool the editor's bracket matching
  byte state = STATE_KEY;
  char c, last_c = 0;
  while (client.connected()) {
    if (client.available()) {
      switch (state) {
        case STATE_KEY:
	  skip(client, '"');
	  readString(client, buf);
	  // Serial.print("key1:");
	  // Serial.println(buf);
	  if (strstr(buf, "jobs")) {
	    skip(client, '[');
	    state = STATE_JOBS;
	  } 
	  else {
	    c = readValue(client, buf);
	    // Serial.print("val1:");
	    // Serial.println(buf);
            // { <- fool the editor's bracket matching
	    if (c == '}') {
	      state = STATE_NONE;
	      // Serial.println("done");
              if (buildCount == 0) {
                // No builds found to report - show as a problem
                buildsOk = UNDEFINED_BUILD_PROBLEM;
              }
              return;
	    }
	  }
          break;
        case STATE_JOBS:
	  // Serial.println("Entered STATE_JOBS");
	  c = readMatchingChar(client, "{]");   // } <- fool the editor's bracket matching
	  if (c == ']') {
	    skip(client, ',');
	    state = STATE_KEY;
	  }
	  else if (c == '{') {  // } <- fool the editor's bracket matching
	    state = STATE_JOB;
	    // Serial.println("Entering STATE_JOB");
	  }
	  else 
          break;
        case STATE_JOB:
	  skip(client, '"');
	  readString(client, buf);
	  // Serial.print("key2:");
	  // Serial.println(buf);
	  if (strcmp(buf, "color") == 0) {
	    Serial.print("color:");            
	    // c = readValue(client, user);
	    // Serial.println(user);
	    c = readValue(client, buf);
	    Serial.println(buf);
            buildCount++;  // we have at least one
            if (strcmp(buf, "blue") != 0 && strcmp(buf, "blue_anime") != 0 && strcmp(buf, "disabled") != 0) {
              buildsOk = BUILDS_BAD;  
            }

	  }
	  else {
	    c = readValue(client, buf);
	  }
          // { <- fool the editor's bracket matching
	  if (c == '}') {
	    state = STATE_JOBS;
	  }
	  break;
        default:
          ;
      }
    }
  }
}


/*
 * Queries the search URI and returns the JSON API URI.
 */ 
char* getJsonUri(Client uriClient) {
  uriClient.print("GET ");
  uriClient.print(search);
  uriClient.println(" HTTP/1.0");
  uriClient.println();

  skipHeaders(uriClient);

  char uri[180];
  char c;
  int i;
  for (i = 0 ; i < 180 ; i++) {
    c = readChar(uriClient);
    if ((c == '\n') || (c == 0)) {
      break;
    }
    uri[i] = c;
  }
  uri[i] = '\0';

  Serial.print("got json URI: ");
  Serial.println(uri);
  uriClient.flush();
  return uri;
}


/* Returns:
 *  UNDEFINED_BUILD_PROBLEM - unexpected problem (no builds, no connection to server, etc)
 *  BUILDS_GOOD - all builds ok
 *  BUILDS_BAD - at least one build broken
 */
int buildStatus() {
  Ethernet.begin(mac, ip);

  buildsOk = UNDEFINED_BUILD_PROBLEM;
  Serial.println("\nconnecting ...");
  Client client(server, 80);
  if (client.connect()) {
    char* jsonUri = getJsonUri(client);
    client.stop();

    if (client.connect()) {
      Serial.print("\nconnecting to: ");
      Serial.println(jsonUri);

      client.print("GET ");
      client.print(jsonUri);
      client.println(" HTTP/1.0");
      client.println();
      readResponse(client);
  
      Serial.println("disconnecting");
      client.stop();
    } else {
      Serial.println("failed to get JSON data");
    }
  } else {
    Serial.println("failed to get active URI");
  }
  return buildsOk;
}
