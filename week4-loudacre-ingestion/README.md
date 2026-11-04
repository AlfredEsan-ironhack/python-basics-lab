# Project 4: Loudacre Ingestion (MySQL → HDFS → Hive/Impala)

Ironhack Data Engineering bootcamp, Week 4. Author: Alfred Esan.

Copy tables from a relational database into a Hadoop data lake with **Sqoop**, then make them queryable with **Hive** and **Impala**, in three file formats (text, Avro, Parquet).

```
MySQL (loudacre)  ──Sqoop──►  HDFS (/Loudacre, /user/training)  ──Hive Metastore──►  Hive / Impala tables
```

| Part | Brief | Status |
|---|---|---|
| A | `Problem_Scenario_loudacre`: 7 Sqoop questions | Done |
| B | `Hive-Impala_Exercise`: 6 Hive/Impala questions | Done |

All outputs below are copied from my own terminal session (`evidence/project4_log_clean.txt`). Nothing is invented.

## Environment

| Component | Version |
|---|---|
| VM | Cloudera Training DevSH 5.7 (CentOS 6, single-node cluster) |
| Sqoop | 1.4.6-cdh5.7.0 |
| Hive | 1.1.0-cdh5.7.0 (via `beeline`, HiveServer2) |
| Impala | 2.5.0-cdh5.7.0 (`impala-shell`) |
| MySQL | 5.1.73, database `loudacre` |

Connection details were stored once in a shell variable to avoid repeating them:

```bash
CONN="--connect jdbc:mysql://localhost/loudacre --username training --password training"
```

(Training-VM password only. In real work: `-P` or `--password-file`.)

---

## Part A: Loudacre (Sqoop)

Method for every import: count rows in MySQL first, check Sqoop's `Retrieved N records`, then count lines in HDFS. All three must match.

| Q | Task | Command (key options) | MySQL | Sqoop | HDFS |
|---|---|---|---|---|---|
| 1 | List databases | `sqoop list-databases --connect jdbc:mysql://localhost ...` | 6 databases | 6 listed | |
| 2 | Make `/Loudacre` | `hdfs dfs -mkdir /Loudacre` | | | created, owner `training` |
| 3 | Import `accounts`, `accountdevice`, `webpage` separately | `--table <t> --target-dir /Loudacre/<t>` | 129,761 / 194,764 / 53 | 129,761 / 194,764 / 53 | `wc -l` accounts = 129,761 |
| 4 | `accounts` into `/user/training`, 10 mappers, `:` separator, split by state | `--table accounts -m 10 --fields-terminated-by ':' --split-by state` | 129,761 | 129,761 | `wc -l` = 129,761 |
| 5 | Full names (`first last`) | `--query "SELECT CONCAT(first_name,' ',last_name) AS full_name FROM accounts WHERE \$CONDITIONS" -m 1 --target-dir /user/training/account_fullnames` | 129,761 | 129,761 | `wc -l` = 129,761 (`Donald Becton`, ...) |
| 6 | `accountdevice` with `device_id` between 10 and 50 | `--where "device_id BETWEEN 10 AND 50"` | 156,825 | 156,825 | |
| 7 | Account number for Roger Miller in `customerservicerep` | `--columns acct_num --where "cs_name='Roger Miller'" -m 1` | `198` | 1 record | `198` |

**Where does the data end up, and in what format?** (teacher's question) In HDFS, by default `/user/<user>/<table>/`, or wherever `--target-dir` points. Plain comma-separated text, one file per mapper (`part-m-00000` ... ), plus an empty `_SUCCESS` marker. Sqoop runs a map-only MapReduce job on YARN, hence `part-m`.

### Q4 finding: data skew

`--split-by state` cut the alphabetical range of state codes into 10 slices. Accounts exist in only 4 states:

| State | Accounts | Share |
|---|---|---|
| CA | 92,416 | 71% |
| OR | 13,575 | 10% |
| AZ | 12,754 | 10% |
| NV | 11,016 | 9% |

Result: of 10 output files, 7 were empty, `part-m-00000` (AZ) = 1.8 MB, `part-m-00002` (CA) = 13.5 MB, `part-m-00009` (NV + OR) = 3.5 MB. Total 18,911,238 bytes = Sqoop's `Bytes Written`. Sqoop itself warned: *"You are strongly encouraged to choose an integral split column."* Splitting on `acct_num` (Q3) gave 4 nearly equal files of ~4.7 MB.

### Q4 finding: bad separator choice

The task asks for `:` as the field separator, but the timestamps contain colons:

```
29561:2012-07-05 14:07:25.0:null:Lydia:Lee:...
```

A reader cannot tell separator colons from timestamp colons. Rule: never use a separator that occurs in the data (tab, `|` or Hive's default `\001` are safer).

### Other observations

- Sqoop writes SQL NULL as the text `null`. Hive reads it as NULL for a TIMESTAMP column only because the text fails to parse. For string columns, `--null-string '\\N' --null-non-string '\\N'` is the correct fix.
- Q7 says "customer name", but `customerservicerep.cs_name` is most likely the service rep's name.
- The brief describes Loudacre as an electronics retailer and mentions "Dualcore" (another Cloudera course's company). The VM data is a mobile phone network.

---

## Part B: Hive and Impala

Before Q1: `SHOW TABLES` showed only `device` (no clash), and every row of `/Loudacre/accounts` has exactly 12 comma-separated fields (`129761 12`), so no address contains a comma.

| Q | Task | How | Check |
|---|---|---|---|
| 1 | External table on `accounts` | `CREATE EXTERNAL TABLE accounts (...12 columns...) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/Loudacre/accounts'` | `COUNT(*)` = 129,761 (21 s) |
| 2 | External Avro table | `sqoop import ... --as-avrodatafile --target-dir /Loudacre/accounts_avro`; schema `accounts.avsc` put in `/Loudacre/schemas/`; `CREATE EXTERNAL TABLE accounts_avro STORED AS AVRO LOCATION '/Loudacre/accounts_avro' TBLPROPERTIES ('avro.schema.url'='hdfs:///Loudacre/schemas/accounts.avsc')` | 12 columns from the schema, `COUNT(*)` = 129,761 |
| 3 | Parquet table | `sqoop import ... --as-parquetfile --target-dir /Loudacre/accounts_parquet`; `CREATE EXTERNAL TABLE accounts_parquet (...) STORED AS PARQUET LOCATION ...` | `COUNT(*)` = 129,761 |
| 4 | Sqoop `basestations` directly into Hive | `sqoop import ... --table basestations --hive-import --hive-table basestations -m 1` | MySQL 377 = Sqoop 377 = Hive 377. `Table Type: MANAGED_TABLE`, location `/user/hive/warehouse/basestations` |
| 5 | Only first and last name, visible in Hive and Impala | `sqoop import ... --columns "first_name,last_name" --target-dir /Loudacre/account_names`; external Hive table `account_names`; Impala `INVALIDATE METADATA` | Hive sample OK; Impala `COUNT(*)` = 129,761 |
| 6 | Group accounts by city, order by name, in Hive and Impala | see below | identical results in both engines |

I made the Avro and Parquet copies myself with Sqoop rather than using `training_materials/data/static_data`, whose README says students should not use it for exercises.

### Q6

The question is ambiguous, so both readings:

```sql
-- (a) accounts per city, cities A-Z
SELECT city, COUNT(*) AS num_accounts FROM accounts GROUP BY city ORDER BY city;

-- (b) account holders per city, names A-Z within each city
SELECT city, last_name, first_name FROM accounts ORDER BY city, last_name, first_name;
```

First rows (identical in Hive and Impala): (a) Alhambra 1487, Anaheim 1544, Bakersfield 3010, Bend 1528, Berkeley 1698 ... (b) Alhambra / Abrams / Jodi, Alhambra / Adams / James, Alhambra / Adams / Modesto ...

There are 56 cities. Full (a) result: `evidence/q6a_impala.csv`.

| Query (with `LIMIT 20`) | Hive | Impala |
|---|---|---|
| (a) GROUP BY + ORDER BY | 49.9 s (2 MapReduce jobs) | 3.35 s |
| (b) ORDER BY | 22.9 s (1 MapReduce job) | 0.55 s |

Hive turns each query into MapReduce jobs on YARN; (a) needed two (group, then sort), with the intermediate result written to HDFS between them. Impala's daemons are always running, so there is no job start-up.

### Format comparison (same 129,761 rows)

| Format | Size in HDFS | Bytes Hive read for `COUNT(*)` |
|---|---|---|
| Text (CSV) | 18.0 MB | 18,918,855 |
| Avro | 12.1 MB | 12,766,819 |
| Parquet | 5.6 MB | **27,214** |

Parquet is 31% of the text size because it stores and compresses each column separately. For `COUNT(*)` Hive read only 27 KB: the row counts are stored in each Parquet file's footer, so the data itself did not need to be read.

### Other observations

- **Managed vs external:** Q1, Q2, Q3 and Q5 are external tables (dropping them keeps the data). Q4's `--hive-import` created a managed table in Hive's warehouse (dropping it deletes the data).
- **Dates in Avro/Parquet:** Sqoop stores `datetime` as milliseconds since 1970 (`long`, so `BIGINT` in Hive). `from_unixtime(CAST(acct_create_dt/1000 AS BIGINT))` gives `2008-10-23 16:05:05` for account 1, the same as MySQL.
- **Parquet row order:** `SELECT ... LIMIT 3` on `accounts_parquet` returned accounts 32441-32443, not 1-3. Without `ORDER BY`, rows come in file order, and Sqoop's Parquet writer names files with random IDs.
- **Hive delimiter:** `--hive-import` used Hive's default field separator `\u0001` (Ctrl-A), shown in `DESCRIBE FORMATTED`.
- **Precision:** longitude for station 3 is `-110.2941` in the Cloudera TSV file but `-110.294` in Hive. MySQL stores it as `FLOAT` (single precision), the likely cause.
- **Warning during Q4:** `chgrp: ... User does not belong to hive` when Hive moved the file into its warehouse. The data loaded correctly (377 rows); only the file's group could not be changed.
- **Impala needs a refresh:** tables created in Hive were invisible to Impala until `INVALIDATE METADATA`, because Impala caches the catalogue.

## Evidence

| File | Content |
|---|---|
| `evidence/project4_log_clean.txt` | Full terminal session (recorded with `script`, cleaned with `col -b`) |
| `evidence/q6a_impala.csv` | Q6 (a) full result from Impala (56 cities) |
