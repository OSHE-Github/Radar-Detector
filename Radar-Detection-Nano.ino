#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ── Pin assignments ──────────────────────────────────────────────
const int BUZZER_PIN  = 3;
const int LED_PIN     = 6;
const byte INPUT_PIN  = 2; // Must be an interrupt-capable pin (Nano: 2 or 3)
                            // Pin 6 is NOT interrupt-capable on the Nano —
                            // change this if you meant a different board

// ── Frequency detection ──────────────────────────────────────────
const int MIDDLE_C         = 262;   // Hz
const long SAMPLE_MS       = 500L;  // Sampling window in ms
const float FREQ_THRESHOLD = 10.0;  // Hz — anything above this counts as "detected"

volatile long count          = 0L;
unsigned long prevSampleTime = 0L;

// ── OLED setup ───────────────────────────────────────────────────
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1  // No reset pin
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// ── ISR ──────────────────────────────────────────────────────────
void addPulse() {
  count++;
} // <-- was missing

void setup() {
  pinMode(LED_PIN,    OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT); // <-- was missing
  pinMode(INPUT_PIN,  INPUT);
  Serial.begin(115200);

  // Start OLED (0x3C is the standard I2C address for most cheap modules)
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED not found");
    while (true); // Halt if display missing — helps diagnose wiring issues
  }

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Radar ready...");
  display.display();
     delay(1000);

  attachInterrupt(digitalPinToInterrupt(INPUT_PIN), addPulse, RISING);
}

void loop() {
  if (millis() - prevSampleTime >= SAMPLE_MS) {
    prevSampleTime += SAMPLE_MS;

    detachInterrupt(digitalPinToInterrupt(INPUT_PIN));
    long snapshot = count; // Copy before resetting
    count = 0L;
    attachInterrupt(digitalPinToInterrupt(INPUT_PIN), addPulse, RISING);

    // Count was rising edges over SAMPLE_MS, so multiply by 2 to get full cycles
    // if your signal is a clean square wave; remove the *2 if you're unsure
    float frequency = (float)snapshot / (SAMPLE_MS / 1000.0);

    Serial.print(frequency);
    Serial.println(" Hz");

    if (frequency > FREQ_THRESHOLD) {
      // ── Motion detected ─────────────────────────────────────
      digitalWrite(LED_PIN, HIGH);
      tone(BUZZER_PIN, MIDDLE_C, 1000);

      display.clearDisplay();
      display.setTextSize(1);
      display.setCursor(0, 0);
      display.println("DETECTED");
      display.setTextSize(1);
      display.setCursor(0, 28);
      display.print("Freq: ");
      display.print(frequency, 1);
      display.println(" Hz");
      display.display();

      delay(1000);
      digitalWrite(LED_PIN, LOW);
      // tone() stops on its own after the 1000ms duration

    } else {
      // ── No motion ────────────────────────────────────────────
      display.clearDisplay();
      display.setTextSize(1);
      display.setCursor(0, 0);
      display.println("No motion");
      display.setCursor(0, 16);
      display.print("Freq: ");
      display.print(frequency, 1);
      display.println(" Hz");
      display.display();
    }
  }
}