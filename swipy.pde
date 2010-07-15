#define CLOCK2 10
#define DATA2 9
#define CARD2 23

#define TRACK1_LEN 60
uint8_t track1[TRACK1_LEN];
uint8_t track1shifted[TRACK1_LEN];

#define BYTELENGTH 7 // 6 + 1 parity

#define PIEZO 3

void beep(uint8_t pin, long freq, long dur) {
  long d = 500000/ freq;

  for (long i=0; i< freq * dur / 2000; i++) {
    digitalWrite(pin, HIGH);
    delayMicroseconds(d);
    digitalWrite(pin, LOW);
    delayMicroseconds(d);
  }  
}


void setup()
{
 // Serial.begin(9600); // USB is always 12 Mbit/sec
 
  pinMode(5, OUTPUT);
  pinMode(PIEZO, OUTPUT);
  digitalWrite(5, LOW);
  
  beep(PIEZO, 4000, 200);
}

//http://stripesnoop.sourceforge.net/devel/magtek-app.pdf

void loop()
{
  while (digitalRead(CARD2));
  uint8_t zeros = 0;
  // card was swiped!
  // check clocked in data
  for (uint8_t t1 = 0; t1 < TRACK1_LEN; t1++) {
    track1[t1] = 0;
    for (uint8_t b=0; b < BYTELENGTH; b++) {
      
      // wait while clock is high
      while (digitalRead(CLOCK2));
      // we sample on the falling edge!
      uint8_t x = digitalRead(DATA2);
      if (!x) {
      // data is LSB and inverted!
        track1[t1] |= _BV(b);
      }
      // heep hanging out while its low
      while (!digitalRead(CLOCK2));
    }
    
    if ((t1 == 0) && (track1[t1] == 0)) {
     // get rid of leading 0's
     zeros++;
     t1--;
     continue;
    }
    
    if (zeros < 4) {
      t1--;
     continue;
    }
    if ((t1 == 1) && (track1[t1] == 0)) {
     t1 = -1;
     zeros = 1;
     continue;
    }
  }
  
  // check start sentinel
  if ((track1[0] == 0x45) && (track1[1] == 0x62)) {
    // sentinal OK!
    /*
    Serial.println("Swiped!");
    for (uint8_t i = 0; i < TRACK1_LEN; i++) {
      Serial.print(track1[i] & 0x3F, HEX); 
      Serial.print(" "); 
    }
    Serial.println();
    */

    // FIND PAN
    uint8_t i=2;
    while ((track1[i] & 0x3F) != 0x3E) {
     // Serial.print((track1[i] & 0x3F)+0x20, BYTE); 
      Keyboard.print((track1[i] & 0x3F)+0x20, BYTE);
      i++;
    }
    i++;
    char fname[16], lname[16];
    
    // LAST NAME
     uint8_t j=0;
    while ((track1[i] & 0x3F) != 0xF) {
     // Serial.print((track1[i] & 0x3F)+0x20, BYTE); 
      lname[j++] = (track1[i] & 0x3F)+0x20;
      i++;
    }
    lname[j] = 0;
    i++;
    j=0;
    // FIRST NAME
    while ((track1[i] & 0x3F) != 0x3E) {
      //Serial.print((track1[i] & 0x3F)+0x20, BYTE); 
      fname[j++] = (track1[i] & 0x3F)+0x20;
      i++;
    }
    fname[j] = 0;
    i++;
    char y1, y2, m1, m2;
    y1 = (track1[i++] & 0x3F)+0x20;
    y2 = (track1[i++] & 0x3F)+0x20;
    m1 = (track1[i++] & 0x3F)+0x20;
    m2 = (track1[i++] & 0x3F)+0x20;

    Keyboard.print('\t');
    Keyboard.print(m1, BYTE);
    Keyboard.print(m2, BYTE);
    Keyboard.print(y1, BYTE);
    Keyboard.print(y2, BYTE);
    
    Keyboard.print('\t'); // tab to amount
    Keyboard.print('\t'); // tab to invoice
    Keyboard.print('\t'); // tab to description
    Keyboard.print("HOPE conference kits from Adafruit.com");
    Keyboard.print('\t'); // tab to customer ID
    Keyboard.print('\t'); // tab to first name
    Keyboard.print(fname);
    Keyboard.print('\t'); // tab to last name
    Keyboard.print(lname);
    
    beep(PIEZO, 4000, 200);
  } else {
    beep(PIEZO, 1000, 200);
   // Serial.println("Failed!");
  }
  
  // this was an experiment in error correcting, 
// i wouldnt use it unless you know what you're doing
  /*
  switch ((track1[0] & 0x3F)) {
    case 0x05: {
     Serial.println("Swiped!");
     break;
    }
    
    case 0x0A: {
      shifttrack(track1, track1shifted, 0);
      break;
    }
    
     case 0x20: {
      shifttrack(track1, track1shifted, 1);

      break;
    }
  }
  
    for (uint8_t i = 0; i < TRACK1_LEN; i++) {
      Serial.print(track1[i], HEX); 
      Serial.print(" "); 
    }
    Serial.println();
  if (track1[0] == 0x45) {
    for (uint8_t t1 = 0; t1 < TRACK1_LEN; t1++) {
      Serial.print((track1[t1] & 0x3F)+0x20, BYTE); 
      Serial.print(" "); 
    }
  }
  Serial.println();
  */
  //Serial.println(zeros, DEC);
    while (! digitalRead(CARD2));
    return;
 
}

// this was an experiment in error correcting, 
// i wouldnt use it unless you know what you're doing
void shifttrack(byte track[], byte shift[], uint8_t dir) {
  if (dir) {
    // shift right
     uint8_t x =0;
    
    for (uint8_t i = 0; i < TRACK1_LEN; i++) {
      shift[i] = ((track[i] << 1) | x) & 0x3F;
      x = (track[i]>>6) & 0x1; // snag the parity bit
    } 
  } else {
    uint8_t x =0;
    
    for (uint8_t i = 0; i < TRACK1_LEN; i++) {
      x = track[i+1] & 0x1; // snag the bit
      shift[i] = ((track1[i] >> 1) | (x << 6));

    } 
  }
  
  for (uint8_t i = 0; i < TRACK1_LEN; i++) {
    track[i] = shift[i];
  }
}
