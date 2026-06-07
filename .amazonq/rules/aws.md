# Garden IoT workspace rules

## AWS CLI
- Always use `--profile jedrek` in all AWS CLI commands
- Default AWS region is `eu-central-1`

## Project context
- This is a single-device personal IoT project for automated garden irrigation
- Device is an ESP32, `device_id` is always `esp32-garden`
- DynamoDB table name is `garden-iot-events`
- Terraform state is local, no remote backend

## Terraform
- Terraform directory is `/Users/jedrek/workspace/garden-iot/terraform`
- Always run `terraform plan` before `terraform apply`
- Use `--profile jedrek` in the AWS provider profile

## Firmware
- Arduino IDE is used for compiling and flashing
- Board is ESP32 devkit
- Secrets are never hardcoded — always generated from `firmware/.env` via `generate_secrets.py`
- Production sleep duration is `3600` seconds
- `secrets.h` and `.env` are never committed to the repository

## Code style
- Lambda functions are written in Python 3.12
- Minimal comments, self-explanatory code
