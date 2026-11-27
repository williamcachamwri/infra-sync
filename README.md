# infra-sync

Automated state checkpoint synchronization pipeline via GitHub Actions.

## Structure
- `data/counter.txt` — Latest synchronized checkpoint sequence ID.
- `data/changelog.log` — Rolling log of the latest 100 state checkpoints.
- `scripts/run_batch.sh` — Batch checkpoint runner.
