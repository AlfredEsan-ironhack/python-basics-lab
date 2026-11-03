# HDFS Assignment — Acmeshell Group

Ironhack Data Engineering bootcamp, Week 4 (Hadoop / HDFS).
Author: Alfred Esan

| Part | Topic | Status |
|---|---|---|
| A | Acmeshell scenario: HDFS command line (11 questions) | Done |
| B | HDFS practical in Hue (10 tasks) | Not started |
| C | HDFS & distributed systems MCQ (20 questions) | Done |

> Lines marked **TODO** still need my real output. Nothing in this document is invented:
> every output below was copied from my own terminal session.

---

## Environment

| Item | Value |
|---|---|
| Cluster | Cloudera training VM `Cloudera-Training-DevSH-5.7f` (CDH 5.7, Hadoop 2.6, CentOS 6.6) |
| Mode | Single node (NameNode, DataNode, ResourceManager, NodeManager on one machine) |
| User | `training` (HDFS home: `/user/training`, local home: `/home/training`) |
| Replication | 1 (only one DataNode exists, so a second copy has nowhere to go) |
| Trash | Was disabled (`fs.trash.interval = 0`). Enabled and tested before Part B: `hdfs getconf -confKey fs.trash.interval` now returns `1440` (24 hours) |
| Evidence | Full session recorded with `script`, cleaned with `col -b`: [`evidence/part_a_log_clean.txt`](evidence/part_a_log_clean.txt) |

**Two filesystems, one rule:** commands starting with `hdfs dfs` act on HDFS. Everything else (`cat`, `ls`, `rm`) acts on the VM's local Linux disk.

---

## Part A — Scenario

Acmeshell Group owns two companies, **QuickTechie** and **BlueWorld**. Each keeps its employee list in its own text file. The task is to land both files in HDFS, combine them, and move copies between HDFS and the local disk.

| Direction | Command used |
|---|---|
| Local → HDFS | `hdfs dfs -put` |
| HDFS → local | `hdfs dfs -get`, `hdfs dfs -getmerge` |
| Read | `cat` (local), `hdfs dfs -cat` (HDFS) |
| List | `ls` (local), `hdfs dfs -ls` (HDFS) |

---

### Ques 1 — Check all available HDFS command-line options

```bash
hdfs dfs 2>&1 | head -15
```

```
Usage: hadoop fs [generic options]
	[-appendToFile <localsrc> ... <dst>]
	[-cat [-ignoreCrc] <src> ...]
	[-checksum <src> ...]
	[-chgrp [-R] GROUP PATH...]
	[-chmod [-R] <MODE[,MODE]... | OCTALMODE> PATH...]
	[-chown [-R] [OWNER][:[GROUP]] PATH...]
	[-copyFromLocal [-f] [-p] [-l] <localsrc> ... <dst>]
	[-copyToLocal [-p] [-ignoreCrc] [-crc] <src> ... <localdst>]
	[-count [-q] [-h] [-v] <path> ...]
	[-cp [-f] [-p | -p[topax]] <src> ... <dst>]
	[-createSnapshot <snapshotDir> [<snapshotName>]]
	[-deleteSnapshot <snapshotDir> <snapshotName>]
	[-df [-h] [<path> ...]]
	[-du [-s] [-h] <path> ...]
```

Running `hdfs dfs` with no arguments prints every available option (first 15 lines shown). `hdfs dfs -help` prints the full description of each.

- `2>&1`: Hadoop prints the usage on stderr (channel 2) because no command was given. The pipe only passes stdout (channel 1), so `2>&1` redirects stderr into stdout for `head` to receive.
- The header says `hadoop fs`: `hdfs dfs` and `hadoop fs` are the same shell; `hadoop fs` also works on other filesystems (local, S3).
- Ran at the end of the session, which is why it appears last in the log.

### Ques 2 — Get help on individual commands

```bash
hdfs dfs -help put
```

Output (end of the `-put` help, from my log):

```
  exists, unless the -f flag is given.
  Flags:
  -p  Preserves access and modification times, ownership and the mode.
  -f  Overwrites the destination if it already exists.
  -l  Allow DataNode to lazily persist the file to disk. Forces
         replication factor of 1. This flag will result in reduced
         durability. Use with care.
```

The command name goes after `-help`, without its dash.

### Ques 3 — Create an empty directory `Employee` in HDFS

```bash
hdfs dfs -mkdir /user/training/Employee
hdfs dfs -ls /user/training
```

```
Found 2 items
drwx------   - training supergroup          0 2026-10-29 06:55 /user/training/.Trash
drwxrwxrwx   - training supergroup          0 2026-10-29 11:15 /user/training/Employee
```

The leading `d` marks a directory. Creating a directory only adds an entry to the NameNode's metadata; no DataNode stores anything.

### Ques 4 — Create `quicktechie.txt` on the local system

```bash
cat > quicktechie.txt <<'EOF'
1, Michael, California
2, Kris, London
3, Martin, Hong Kong
4, Carol, Canada
5, Sita, India
EOF
cat quicktechie.txt
```

```
1, Michael, California
2, Kris, London
3, Martin, Hong Kong
4, Carol, Canada
5, Sita, India
```

`cat > file <<'EOF' ... EOF` (a "heredoc") writes every line up to `EOF` into the file. Data copied exactly as given in the assignment.

### Ques 5 — Create `Blueworld.txt` on the local system

```bash
cat > Blueworld.txt <<'EOF'
6, John, New York
7, Ben, London
8, Carl, Tokyo
9, Smith, Singapore
10, Will, Jordon
EOF
cat Blueworld.txt
```

```
6, John, New York
7, Ben, London
8, Carl, Tokyo
9, Smith, Singapore
10, Will, Jordon
```

Note: "Jordon" is spelled this way in the assignment's source data (probably meant "Jordan"). I kept the source value unchanged.

### Ques 6 — Put both files into HDFS

```bash
hdfs dfs -put quicktechie.txt Blueworld.txt /user/training/Employee/
hdfs dfs -ls /user/training/Employee
```

```
Found 2 items
-rw-rw-rw-   1 training supergroup         85 2026-10-29 11:18 /user/training/Employee/Blueworld.txt
-rw-rw-rw-   1 training supergroup         92 2026-10-29 11:18 /user/training/Employee/quicktechie.txt
```

The `1` is the replication factor (single-node cluster). The sizes match the local files (85 and 92 bytes).

### Ques 7 — Merge all files in `Employee` into `MergedEmployee.txt`

```bash
hdfs dfs -getmerge /user/training/Employee MergedEmployee.txt
cat MergedEmployee.txt
```

```
6, John, New York
7, Ben, London
8, Carl, Tokyo
9, Smith, Singapore
10, Will, Jordon
1, Michael, California
2, Kris, London
3, Martin, Hong Kong
4, Carol, Canada
5, Sita, India
```

`-getmerge` reads every file in the HDFS directory, concatenates them in name order, and writes **one local file**.

**Why BlueWorld comes first:** HDFS sorts names character by character, and uppercase `B` sorts before lowercase `q`. This is the correct behaviour of the command.

I also stored a copy in HDFS, in a separate folder so it can never be merged with the originals again:

```bash
hdfs dfs -mkdir /user/training/Merged
hdfs dfs -put MergedEmployee.txt /user/training/Merged/
hdfs dfs -ls /user/training/Merged
```

```
Found 1 items
-rw-rw-rw-   1 training supergroup        177 2026-11-03 10:22 /user/training/Merged/MergedEmployee.txt
```

177 bytes = 85 + 92, so nothing was lost or duplicated.

### Ques 8 — Read the content of the file

```bash
cat MergedEmployee.txt
hdfs dfs -cat /user/training/Merged/MergedEmployee.txt
```

Both commands (local copy, then HDFS copy) printed the same 10 lines:

```
6, John, New York
7, Ben, London
8, Carl, Tokyo
9, Smith, Singapore
10, Will, Jordon
1, Michael, California
2, Kris, London
3, Martin, Hong Kong
4, Carol, Canada
5, Sita, India
```

### Ques 9 — Copy the file to a new local file `Copied.txt`

```bash
hdfs dfs -get /user/training/Merged/MergedEmployee.txt Copied.txt
ls -l Copied.txt
cat Copied.txt
```

```
-rw-rw-rw- 1 training training 177 Nov  3 10:26 Copied.txt
```

Same 177 bytes and the same 10 lines as `MergedEmployee.txt`. `-get` copies HDFS → local; the last argument is the new name.

### Ques 10 — Add content to the new file using Hue

Hue edits files in HDFS only, so the local `Copied.txt` was uploaded first:

```bash
hdfs dfs -put Copied.txt /user/training/Merged/
hdfs dfs -ls /user/training/Merged
```

```
Found 2 items
-rw-rw-rw-   1 training supergroup        177 2026-11-03 10:26 /user/training/Merged/Copied.txt
-rw-rw-rw-   1 training supergroup        177 2026-11-03 10:22 /user/training/Merged/MergedEmployee.txt
```

Then in Hue (`localhost:8888`, user `training`): File Browser → `/user/training/Merged` → `Copied.txt` → Edit file → added one line → Save.

Line added: `11, Alfred, Netherlands`

After saving:

```bash
hdfs dfs -ls /user/training/Merged
```

```
Found 2 items
-rw-rw-rw-   1 training supergroup        201 2026-11-03 10:54 /user/training/Merged/Copied.txt
-rw-rw-rw-   1 training supergroup        177 2026-11-03 10:22 /user/training/Merged/MergedEmployee.txt
```

**Size check (predicted before looking):** the line is 23 characters plus 1 line break = 24 bytes. 177 + 24 = **201**, exactly what HDFS reports. So Hue saved precisely the added line, and did not convert the file to Windows line endings (that would have added one byte to every line).

Screenshots: `screenshots/q10_hue_before.png`, `screenshots/q10_hue_after.png` (**TODO:** add if taken).

A second `-ls` a minute later showed the same 201 bytes with the time changed from 10:54 to 10:55: I had clicked Save twice, and each save wrote a new file.

HDFS files are write-once: Hue does not change bytes inside the old file, it writes a complete new file with the same name and replaces the old one.

### Ques 11 — Get the file back from HDFS to the local file system

```bash
rm -f Copied_from_hdfs.txt .Copied_from_hdfs.txt.crc
hdfs dfs -get /user/training/Merged/Copied.txt Copied_from_hdfs.txt
cat Copied_from_hdfs.txt
diff Copied.txt Copied_from_hdfs.txt
```

```
6, John, New York
7, Ben, London
8, Carl, Tokyo
9, Smith, Singapore
10, Will, Jordon
1, Michael, California
2, Kris, London
3, Martin, Hong Kong
4, Carol, Canada
5, Sita, India
11, Alfred, Netherlands
```

```
10a11
> 11, Alfred, Netherlands
```

- `rm -f` first: an earlier `-get` had already created `Copied_from_hdfs.txt`, and `-get` refuses to overwrite a local file. The `.crc` is removed too, to avoid the checksum issue described below.
- A new local name keeps the original `Copied.txt` untouched, so the two can be compared.
- `10a11` means "after line 10 of the first file, add line 11 of the second". `>` marks a line that exists only in the second file.

**Before-and-after proof:**

| Run | `diff Copied.txt Copied_from_hdfs.txt` | Meaning |
|---|---|---|
| Before the Hue edit | *(no output)* | The two copies were identical |
| After the Hue edit | `10a11` / `> 11, Alfred, Netherlands` | The added line is the only difference |

Together these prove the edit is stored in HDFS, came back to the local disk intact, and was the only change. Both runs are in the evidence log.

---

## Issues I hit and how I solved them

### 1. Checksum error on `-put` (Ques 7)

After `-getmerge`, I rewrote `MergedEmployee.txt` with a plain shell redirect (`hdfs dfs -cat ... > MergedEmployee.txt`) to change the order. The next upload failed:

```
org.apache.hadoop.fs.ChecksumException: Checksum error: file:/home/training/MergedEmployee.txt at 0 exp: -483698445 got: -1841709396
put: Checksum error: file:/home/training/MergedEmployee.txt at 0 exp: -483698445 got: -1841709396
```

**Cause:** `-getmerge` writes a hidden checksum file next to its output (`.MergedEmployee.txt.crc`). The shell redirect changed the content but not the checksum. On upload, Hadoop recalculated the checksum (`got`), compared it with the stored one (`exp`), saw a mismatch, and treated the file as corrupted.

**How I confirmed it:**
- `ls -la ~ | grep crc` showed `.MergedEmployee.txt.crc` (12 bytes).
- The error's hex dump starts `312c204d69636861656c` = `1, Michael`, i.e. the rewritten QuickTechie-first version, while the `.crc` belonged to the BlueWorld-first version from `-getmerge`.

**Fix:** delete both files, re-run `-getmerge`, upload again:

```bash
rm -f ~/MergedEmployee.txt ~/.MergedEmployee.txt.crc
hdfs dfs -getmerge /user/training/Employee MergedEmployee.txt
hdfs dfs -put MergedEmployee.txt /user/training/Merged/
```

**Lesson:** don't edit a file written by Hadoop's local filesystem with other tools and then `-put` it back, unless you also remove its `.crc` file. It is the same protection HDFS uses on every block to detect silent disk corruption.

### 2. `rm` asked for confirmation and deleted nothing

On this CentOS VM, `rm` behaves like `rm -i` and asks before each file. Pressing Enter without typing `y` means "no", so the first cleanup left both files in place. Fixed with `rm -f`.

### 3. Ques 9 ran before the HDFS copy existed

```
get: `/user/training/Merged/MergedEmployee.txt': No such file or directory
```

I ran `-get` before creating `/user/training/Merged` and uploading the merged file. Fixed by running the steps in order: `-mkdir` → `-put` → `-get`.

### 4. Trash was disabled

`hdfs getconf -confKey fs.trash.interval` returned `0`, so deletes were permanent (`hdfs dfs -rm` printed `Deleted ...` instead of `Moved ... to trash`). Part B task 10 needs the trash, so I enabled it (`fs.trash.interval = 1440` minutes) and tested it with a throwaway file:

```
/user/training/.Trash/Current/user/training/trashtest.txt
/user/training/.Trash/Current/user/training/trashtest.txt1793282280604
```

The file went to `.Trash/Current` under its original path. The second entry is the same file name deleted twice: Hadoop appended a timestamp so the second delete would not overwrite the first.

---

## Part B — Hue practical

## Part B: HDFS practical in Hue

No CSV was provided, so I used two Cloudera course files that ship with the training VM:
- `sales_data_01.csv`: Loudacre base stations (`data/base_stations.tsv`, 377 rows, 15191 bytes)
- `sales_data_02.csv`: Loudacre order SKUs (`devsh/examples/example-data/orderskus.txt`, 5 orders, 114 bytes)

Both were tab-separated. I checked no value contained a comma (`grep -c ","` → 0), converted tabs to commas with `tr`, and confirmed line counts and byte sizes were unchanged. Note: `sales_data_01.csv` holds tower data, not sales; the name follows the task's pattern.

| Task | What I did | Result / proof |
|---|---|---|
| 1 | Inspected `/user/training` | Owner `training`, group `supergroup`, `drwxrwxrwx` (777). Wide open on this training VM; production home folders are usually 755 |
| 2 | Created `lab1/input`, `lab1/output` | Listed with `hdfs dfs -ls -R` |
| 3 | Uploaded both CSVs to `lab1/input` | HDFS sizes match local sizes (15191, 114) |
| 4 | File details | 15191 and 114 bytes, replication 1 (single DataNode), block size 134217728 (128 MB). Each file uses one block but only its real size on disk |
| 5 | Viewed contents | First lines match the source files |
| 6 | Renamed to `sales_data_01.csv`, `sales_data_02.csv` | File times unchanged (14:49, 15:24): rename is metadata-only. The folder's time changed because its name list changed |
| 7 | Copied both to `lab1/output` | Copies got a new time (15:35) because the data is rewritten. `md5sum` identical: `21a64ff8…`, `79cee1b8…` |
| 8 | Created `lab1/archive`, moved originals there | `input` empty. Archive files keep their original times: a move is a path change only |
| 9 | `chmod 644` on both archive files | `-rw-r--r--`. 6 = owner read+write, 4 = group read, 4 = others read |
| 10 | Deleted from `output`, found in `.Trash/Current/user/training/lab1/output/`, restored, downloaded from `archive` | Restored files unchanged (`79cee1b8…`). Download in `~/Downloads`, same size and fingerprint |

Notes:
- Trash was off by default (`fs.trash.interval = 0`). I enabled it (1440 minutes) in `core-site.xml`, restarted HDFS and Hue, and tested it with a dummy delete before this task.
- My backup `hdfs dfs -mv` restore command failed with "No such file" because Hue's Restore had already moved the files back; the next `-ls` confirms they were restored.

---

## Part C — MCQ answers

The answer key in the quiz document is shifted by one from question 14 onwards, because the sharding question has no number but is counted as 14 in the key. The table below lines answers up with the questions as printed.

| Q | Answer | Reason |
|---|---|---|
| 1 | b — Hadoop Distributed File System | |
| 2 | c — 128 MB | 64 MB was the Hadoop 1 default |
| 3 | b — NameNode | DataNodes hold block contents, not metadata |
| 4 | c — 3 | This VM uses 1 because it has a single DataNode |
| 5 | b — Merges FsImage and EditLog | A checkpoint helper, not a failover backup |
| 6 | b — At most two of C, A, P | |
| 7 | b — Bandwidth and fault tolerance via placement | Replicas on different racks survive a rack failure |
| 8 | c — RPC | |
| 9 | b — Missed heartbeats → re-replication | |
| 10 | b — Replicas converge over time | |
| 11 | b — DataNode signals it is alive | |
| 12 | b — NameNode | Without HA, nothing can find any block if it fails |
| 13 | b — Write once, read many | Appends are allowed; edits in the middle are not |
| * (sharding) | b — Partitioning data across nodes | Listed as 14 in the key |
| 14 | b — Consensus | Listed as 15 in the key |
| 15 | c — HA with QJM | Listed as 16 in the key |
| 16 | b — Two nodes both believe they are leader | Listed as 17 in the key |
| 17 | b — `hdfs fsck` | Listed as 18 in the key |
| 18 | a — Majority agreement balances consistency and availability | Listed as 19 in the key |
| 19 | b — Low-latency random access to small files is **not** an HDFS trait | Listed as 20 in the key |

**Two clarifications on the question text:**

- **Q3, option c** groups "Secondary NameNode" with "Standby NameNode (HA)". They are different: the Secondary NameNode only merges FsImage and EditLog and cannot take over; the Standby NameNode in an HA setup can.
- **Q8, option c** says "RPC (SSH)". Hadoop RPC runs over TCP (the NameNode usually listens on port 8020); SSH is only used by admin scripts to start daemons on remote nodes.
