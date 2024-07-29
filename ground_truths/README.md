This folder contains modified versions of ground truths from popular benchmarks. These modifications are:
- All of these versions contain only four columns with the same names: _target_ds_, _target_attr_, _candidate_ds_, _candidate_attr_
- For large ground truths (i.e. D3L and TUS Big) we have gathered a sample of the original data.

The data included in this folder presents the following characteristics:
- D3L:
	- Link: https://github.com/alex-bogatu/DataSpiders
	- **Sample** of 100 query columns, with k >= 100
- Nextia
	- Link: ------------------------------
	- 50 query columns, with k >= 10
- Santos Small
	- Link: https://zenodo.org/records/7758091 (santos_benchmark.zip)
	- 50 query columns, with k >= 10
- Santos Big
	- Link: https://zenodo.org/records/7758091 (real_data_lake_benchmark.zip)
    - 80 query columns (with no joins defined)
- TUS Small
	- Link: https://github.com/RJMillerLab/table-union-search-benchmark
    - 100 query columns, with k >= 60
- TUS Big
	- Link: https://github.com/RJMillerLab/table-union-search-benchmark
    - **Sample** of 100 query columns, with k >= 60
