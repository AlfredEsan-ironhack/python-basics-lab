# NiFi CSV → JSON ingestion (QuickCart)

## What it does
Watches a folder for new CSV files, converts each one to JSON with NiFi
record processors, and writes the result to an output folder.
Failed files are routed to an errors folder.

## Flow
ListFile → FetchFile → ConvertRecord (CSVReader → JsonRecordSetWriter)
→ UpdateAttribute (rename .csv to .json) → PutFile
Failures (FetchFile, ConvertRecord) → PutFile (errors)

## Stack
Apache NiFi 2.10.0 in Docker (WSL2), single-user HTTPS login via .env

## How to run
1. Create `.env` with NIFI_USER and NIFI_PASSWORD (12+ characters)
2. `mkdir -p data/{in,out,errors}`
3. `docker compose up -d`
4. Open https://localhost:8443/nifi and log in
5. Import `flows/csv-to-json.json`, enable the controller services, start the group
6. Drop a CSV into `data/in` and check `data/out`

## Results
(screenshots + a short note on what you saw)

## What I learned / next steps
- ListFile state = only new files get processed (like Kafka offsets)
- Conversion is not validation: a future order date (2028-03-29) passed through
- Next: add ValidateRecord to send bad rows to errors