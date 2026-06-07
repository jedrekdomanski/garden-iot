# 🌱 Garden IoT — Automated Irrigation System

An ESP32-based automated garden irrigation system that measures soil moisture, controls a water relay, and streams telemetry to AWS with real-time visualization via Grafana Cloud.

## Motivation

The idea behind this project was simple — being able to travel, go on holidays, or simply leave home for a day or two without worrying that the vegetables and herbs would die. Instead of relying on someone to water the plants or coming back to a dried-out garden, the system takes care of it automatically. It monitors soil moisture around the clock and waters only when needed, while giving full visibility into what's happening remotely through the Grafana dashboard.

![System Architecture](ESP32%20Irrigation%20Controller-2026-06-07-211518.png)

## How it works

The ESP32 is a low-cost, low-power microcontroller with built-in WiFi and Bluetooth, widely used in IoT projects. It features a dual-core 240MHz processor, 520KB of RAM, and a deep sleep mode that draws only ~10µA — making it ideal for battery-powered or solar-powered applications. In this project it runs Arduino firmware compiled with PlatformIO and uses its built-in ADC to read the soil moisture sensor.

The ESP32 wakes from deep sleep every hour, measures soil moisture, decides whether to water, reports all events to AWS, then goes back to sleep. The entire active cycle takes only a few seconds, making it extremely power efficient.

### Measurement & watering logic

1. Powers the capacitive soil moisture sensor
2. Takes 10 averaged ADC readings for accuracy
3. Maps the raw value to a 0–100% moisture percentage using calibrated dry/wet values
4. If moisture is below the threshold (35%), opens the water relay for 5 seconds
5. Reports the outcome (`watering_started` / `watering_skipped`) to AWS
6. Goes back to deep sleep for 1 hour

### Events reported

| Event | Description |
|---|---|
| `device_boot` | Device woke up and connected to WiFi |
| `measurement_taken` | Soil moisture reading with raw value and percentage |
| `watering_started` | Relay opened, irrigation triggered |
| `watering_finished` | Relay closed, irrigation complete |
| `watering_skipped` | Soil moisture sufficient, watering not needed |
| `device_sleeping` | Device entering deep sleep |

## AWS Architecture

### Ingest pipeline
- **API Gateway** — HTTPS endpoint secured with a custom API key authorizer Lambda
- **Ingest Lambda** — validates and writes events to DynamoDB, forwards to EventBridge
- **DynamoDB** — stores all events with a 1-year TTL auto-expiry
- **EventBridge** — routes `watering_started` events to the alert Lambda
- **SES** — sends email alerts when irrigation is triggered

### Visualization pipeline
- **Query Lambda** — queries DynamoDB and returns JSON, supports `from`, `to`, and `limit` parameters
- **Grafana Cloud** — polls `GET /metrics` via the Infinity datasource and renders the dashboard

## Grafana Dashboard

Three panels:
- **Soil Moisture** — time series of moisture % over time
- **Current Moisture** — stat panel with color thresholds (green > 45%, yellow > 25%, red below)
- **Event Log** — full table of all device events with timestamps

## Project structure

```
├── firmware/
│   └── garden/
│       ├── src/main.cpp        # ESP32 firmware
│       ├── include/secrets.h   # Generated secrets (git ignored)
│       ├── scripts/load_env.py # Injects .env into build
│       └── platformio.ini
└── terraform/
    ├── lambda/
    │   ├── ingest/handler.py   # Ingest Lambda
    │   ├── query/handler.py    # Query Lambda
    │   ├── authorizer/handler.py
    │   └── alert/handler.py
    ├── api_gateway.tf
    ├── dynamodb.tf
    ├── lambda.tf
    ├── eventbridge.tf
    ├── grafana.tf
    └── ses.tf
```

## Setup

### Prerequisites
- PlatformIO
- Terraform >= 1.6
- AWS CLI with a configured profile
- Grafana Cloud account (free tier)

### Firmware

1. Copy `firmware/.env.example` to `firmware/.env` and fill in your WiFi credentials and API endpoint
2. Build and flash with PlatformIO:
```bash
cd firmware/garden
pio run --target upload
```

### Infrastructure

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and set your alert email
2. Deploy:
```bash
cd terraform
terraform init
terraform apply
```
3. Get your API endpoint and key:
```bash
terraform output api_endpoint
terraform output -raw api_key
```

### Grafana Cloud

1. Install the **Infinity** datasource plugin
2. Add a new Infinity datasource with header `x-api-key` set to your API key and allowed host set to your API Gateway domain
3. Create panels using `GET https://<api-endpoint>/metrics` as the data source URL

## Hardware

| Component | Details |
|---|---|
| ESP32 DevKit | Dual-core 240MHz, built-in WiFi, deep sleep ~10µA |
| Capacitive soil moisture sensor | GPIO 32 (ADC) |
| Relay module | GPIO 27 — switches power to the water pump |
| Water pump | Controlled via relay module |
