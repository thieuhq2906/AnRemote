// AnRemote - cau noi Wi-Fi -> hong ngoai cho dieu hoa Toshiba.
//
// API (HTTP, cong 80, ten mDNS: anremote.local):
//   GET  /api/state                -> trang thai hien tai (JSON)
//   GET|POST /api/set?power=1&mode=cool&temp=25&fan=0&swing=0&turbo=0&econo=0
//                                  -> cap nhat, phat lenh IR, tra ve trang thai moi
// Tham so nao khong gui thi giu nguyen gia tri cu.

#include <Arduino.h>

#if defined(ESP8266)
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>
ESP8266WebServer server(80);
#else
#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
WebServer server(80);
#endif

#include <WiFiManager.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <ir_Toshiba.h>

#ifndef IR_LED_PIN
#define IR_LED_PIN 4  // D2 tren D1 mini / NodeMCU, GPIO4 tren ESP32
#endif

static const char *kHostName = "anremote";
static const char *kSetupApName = "AnRemote-Setup";

IRToshibaAC ac(IR_LED_PIN);

struct AcState {
  bool power = false;
  String mode = "cool";  // auto | cool | dry | heat | fan
  uint8_t temp = 25;     // 17..30
  uint8_t fan = 0;       // 0 = auto, 1..5
  bool swing = false;
  bool turbo = false;
  bool econo = false;
};

AcState st;

static uint8_t modeCode(const String &mode) {
  if (mode == "auto") return kToshibaAcAuto;
  if (mode == "dry") return kToshibaAcDry;
  if (mode == "heat") return kToshibaAcHeat;
  if (mode == "fan") return kToshibaAcFan;
  return kToshibaAcCool;
}

static bool isValidMode(const String &mode) {
  return mode == "auto" || mode == "cool" || mode == "dry" || mode == "heat" ||
         mode == "fan";
}

static bool argBool(const String &name, bool current) {
  if (!server.hasArg(name)) return current;
  String v = server.arg(name);
  v.toLowerCase();
  return v == "1" || v == "true" || v == "on";
}

static String stateJson() {
  String out = "{";
  out += "\"power\":" + String(st.power ? "true" : "false");
  out += ",\"mode\":\"" + st.mode + "\"";
  out += ",\"temp\":" + String(st.temp);
  out += ",\"fan\":" + String(st.fan);
  out += ",\"swing\":" + String(st.swing ? "true" : "false");
  out += ",\"turbo\":" + String(st.turbo ? "true" : "false");
  out += ",\"econo\":" + String(st.econo ? "true" : "false");
  out += "}";
  return out;
}

// Dieu hoa Toshiba nhan toan bo trang thai trong moi lenh, nen luon gui du.
static void transmit(bool swingChanged) {
  ac.setMode(modeCode(st.mode));
  ac.setTemp(st.temp);
  ac.setFan(st.fan);
  if (st.turbo) {
    ac.setTurbo(true);
  } else if (st.econo) {
    ac.setEcono(true);
  } else {
    ac.setTurbo(false);
    ac.setEcono(false);
  }
  if (!st.power) ac.off();
  // Dao gio la mot lenh ngan rieng, chi gui khi nguoi dung doi.
  if (swingChanged && st.power) {
    ac.setSwing(st.swing ? kToshibaAcSwingOn : kToshibaAcSwingOff);
  }
  ac.send();
  Serial.println(ac.toString());
}

static void handleState() {
  server.send(200, "application/json", stateJson());
}

static void handleSet() {
  AcState next = st;

  next.power = argBool("power", st.power);
  next.swing = argBool("swing", st.swing);
  next.turbo = argBool("turbo", st.turbo);
  next.econo = argBool("econo", st.econo);
  if (next.turbo && next.econo) next.econo = false;

  if (server.hasArg("mode")) {
    String mode = server.arg("mode");
    mode.toLowerCase();
    if (!isValidMode(mode)) {
      server.send(400, "application/json", "{\"error\":\"mode\"}");
      return;
    }
    next.mode = mode;
  }
  if (server.hasArg("temp")) {
    long t = server.arg("temp").toInt();
    if (t < kToshibaAcMinTemp || t > kToshibaAcMaxTemp) {
      server.send(400, "application/json", "{\"error\":\"temp\"}");
      return;
    }
    next.temp = (uint8_t)t;
  }
  if (server.hasArg("fan")) {
    long f = server.arg("fan").toInt();
    if (f < 0 || f > 5) {
      server.send(400, "application/json", "{\"error\":\"fan\"}");
      return;
    }
    next.fan = (uint8_t)f;
  }

  bool swingChanged = next.swing != st.swing;
  st = next;
  transmit(swingChanged);
  server.send(200, "application/json", stateJson());
}

static void handleRoot() {
  String body = "AnRemote dang chay.\n";
  body += "IP: " + WiFi.localIP().toString() + "\n";
  body += "Trang thai: /api/state\n";
  body += "Thu bat may: /api/set?power=1&mode=cool&temp=25\n";
  server.send(200, "text/plain; charset=utf-8", body);
}

void setup() {
  Serial.begin(115200);
  Serial.println();
  ac.begin();

  // Lan dau: mach phat Wi-Fi "AnRemote-Setup", vao do de chon Wi-Fi nha.
  WiFi.mode(WIFI_STA);
  WiFiManager wm;
  wm.setConfigPortalTimeout(300);
  if (!wm.autoConnect(kSetupApName)) {
    Serial.println("Chua co Wi-Fi, khoi dong lai...");
    delay(1000);
    ESP.restart();
  }
  Serial.print("Da ket noi, IP: ");
  Serial.println(WiFi.localIP());

  if (MDNS.begin(kHostName)) {
    MDNS.addService("http", "tcp", 80);
  }

  server.on("/", handleRoot);
  server.on("/api/state", HTTP_GET, handleState);
  server.on("/api/set", handleSet);
  server.onNotFound([]() {
    server.send(404, "application/json", "{\"error\":\"not_found\"}");
  });
  server.begin();
}

void loop() {
  server.handleClient();
#if defined(ESP8266)
  MDNS.update();
#endif
}
