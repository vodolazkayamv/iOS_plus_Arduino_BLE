 #include <SoftwareSerial.h>
 #include <TroykaMQ.h>
  
 #define BUTTON_PIN  2
 #define LED_PIN     3
  
 #define VIN 5.0
  
 #define PIN_MQ2         A2
 #define PIN_MQ2_HEATER  9
  
  
 SoftwareSerial mySerial(7, 8); // RX, TX  
 MQ2 mq2(PIN_MQ2, PIN_MQ2_HEATER);
  
 String Data = "";
 
 boolean ledEnabled = false;
   
  void setup()
  {
    pinMode(LED_PIN, OUTPUT);
    pinMode(BUTTON_PIN, INPUT_PULLUP);
    Serial.begin(9600);
    mySerial.begin(9600);
  
    // включаем нагреватель
    mq2.heaterPwrHigh();
    Serial.println("Heated sensor");
  }
   
  void loop()
  {
    Data = "";
    ledEnabled = !digitalRead(BUTTON_PIN);
    digitalWrite(LED_PIN, ledEnabled);
    //mySerial.println(ledEnabled);
    //Serial.println(ledEnabled);
  
    float v = analogRead(A0) * VIN / 1023.0;
    v = v*1000;
    //float temperature2 = 25 + ((v - 750)/10);
    float temperature = (v / 10) - 50;
    mySerial.print(temperature);
    Serial.println(temperature);
  
  
  
  
    // если прошёл интервал нагрева датчика
    // и калибровка не была совершена
    if (!mq2.isCalibrated() && mq2.heatingCompleted()) {
      // выполняем калибровку датчика на чистом воздухе
      mq2.calibrate();
      // выводим сопротивление датчика в чистом воздухе (Ro) в serial-порт
      Serial.print("Ro = ");
      Serial.println(mq2.getRo());
    }
    // если прошёл интервал нагрева датчика
    // и калибровка была совершена
    if (mq2.isCalibrated() && mq2.heatingCompleted()) {
      // выводим отношения текущего сопротивление датчика
      // к сопротивлению датчика в чистом воздухе (Rs/Ro)
      Serial.print("Ratio: ");
      Serial.print(mq2.readRatio());
      // выводим значения газов в ppm
      
      Serial.print("LPG: ");
      Serial.print(mq2.readLPG());
      float LPG = mq2.readLPG();
      mySerial.print(LPG);   
      Serial.print(" ppm ");
      
      Serial.print(" Methane: ");
      Serial.print(mq2.readMethane());
      float Methane = mq2.readMethane();
      mySerial.print(Methane);
      Serial.print(" ppm ");
      
      Serial.print(" Smoke: ");
      Serial.print(mq2.readSmoke());
      float Smoke = mq2.readSmoke();
      mySerial.print(Smoke);
      Serial.print(" ppm ");
      
      Serial.print(" Hydrogen: ");
      Serial.print(mq2.readHydrogen());
      float Hydrogen = mq2.readHydrogen();
      mySerial.print(Hydrogen);
      Serial.println(" ppm ");

    }
    delay(5000);
  }
