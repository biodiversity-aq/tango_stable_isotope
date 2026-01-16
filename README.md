# TANGO Stable Isotope Data

[![R](https://img.shields.io/badge/R-%3E%3D%204.0-blue.svg)](https://www.r-project.org/)
[![renv](https://img.shields.io/badge/renv-enabled-green.svg)](https://rstudio.github.io/renv/)

> Data transformation pipeline for stable isotope measurements from TANGO (Trophic structure in Antarctic benthic ecology Gathering Observations) expeditions 1 and 2.

This repository processes stable isotope data (δ13C, δ15N, δ34S) from *Sterechinus neumayeri* (sea urchin) specimens collected during TANGO 1 and TANGO 2 expeditions in Antarctic waters. The pipeline transforms raw data into Darwin Core format for standardized biodiversity data sharing.

---

## Features

* **Data Integration**: Combines stable isotope measurements with TANGO expedition occurrence and event data
* **Darwin Core Compliance**: Outputs standardized Darwin Core occurrence and measurement-or-fact (MoF) tables
* **Quality Control**: Handles coordinate precision, depth measurements, and taxonomic information
* **Range-based Matching**: Implements sophisticated sample ID matching for TANGO 2 data
* **Reproducible Environment**: Uses `renv` for package dependency management

---

## Requirements

* **R** (>= 4.0)
* **RStudio** (recommended)
* **renv** package (automatically installed when opening the project)

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/biodiversity-aq/tango_stable_isotope.git
cd tango_stable_isotope
```

### 2. Set Up R Environment with renv

This project uses [renv](https://rstudio.github.io/renv/) for reproducible package management. When you first open the project in RStudio or start R in this directory, `renv` will automatically activate via the `.Rprofile` file.

#### Option A: Using RStudio (Recommended)

1. Open the `tango_stable_isotope.Rproj` file in RStudio
2. `renv` will automatically activate and prompt you to restore the project library
3. Run the following command to install all required packages:

```r
renv::restore()
```

This will install all packages specified in the `renv.lock` file (if present) or create a new project library.

#### Option B: Using R Console

1. Start R in the project directory
2. The `.Rprofile` will automatically load `renv`
3. Restore the project library:

```r
renv::restore()
```

#### First Time Setup (If renv.lock doesn't exist)

If this is a fresh setup without an `renv.lock` file, you'll need to install the required packages:

```r
# Required packages
install.packages(c("tidyverse", "here", "readxl", "janitor", "hms", "data.table"))

# Capture the project dependencies
renv::snapshot()
```

---

## Usage

### Running the Data Transformation Pipeline

Once the environment is set up with `renv`, you can run the data transformation:

#### In RStudio

1. Open `src/transform-data.R`
2. Click "Source" or press `Ctrl+Shift+S` (Windows/Linux) or `Cmd+Shift+S` (Mac)

#### In R Console

```r
source("src/transform-data.R")
```

The script will:
1. Download TANGO 1 and TANGO 2 expedition data from GitHub
2. Read local stable isotope metadata from `data/01_raw/Stable_Isotopes_Metadata.xlsx`
3. Join and transform the datasets
4. Generate Darwin Core outputs:
   - `data/02_output/occurrence.txt` - Occurrence records with taxonomic and event data
   - `data/02_output/mof.txt` - Extended measurements-or-facts table with isotope values

### Data Directory Structure

```
data/
├── 01_raw/              # Raw input data
│   ├── Stable_Isotopes_Metadata.xlsx    # Primary isotope measurements
│   ├── TANGO_1_DATA.xlsx                # TANGO 1 expedition data (reference)
│   └── TANGO_2_DATA.xlsx                # TANGO 2 expedition data (reference)
└── 02_output/           # Processed Darwin Core outputs
    ├── occurrence.txt   # Occurrence table
    └── mof.txt          # Measurement-or-fact table
```

---

## Working with renv

### Common renv Commands

```r
# Check project status
renv::status()

# Install a new package and add to dependencies
install.packages("package_name")
renv::snapshot()

# Update all packages to latest versions
renv::update()

# Remove unused packages
renv::clean()

# Reset library to match renv.lock
renv::restore()

# Deactivate renv (temporary)
renv::deactivate()

# Reactivate renv
renv::activate()
```

### Understanding renv Files

* **`.Rprofile`**: Automatically activates `renv` when R starts in this directory
* **`renv/activate.R`**: The `renv` activation script
* **`renv.lock`** (if present): JSON file recording exact package versions and sources
* **`renv/library/`** (gitignored): Project-specific package library

### Troubleshooting renv

If you encounter issues:

```r
# Repair the local library
renv::repair()

# Completely rebuild the library
renv::restore(rebuild = TRUE)

# Clear the cache and reinstall
renv::purge()
renv::restore()
```

---

## Data Processing Details

### Input Data Sources

The pipeline integrates three data sources:

1. **Stable Isotope Measurements** (`data/01_raw/Stable_Isotopes_Metadata.xlsx`)
   - δ13C, δ15N, δ34S measurements
   - Specimen morphometrics (size, height)
   - Collection metadata (date, location, depth)

2. **TANGO 1 Expedition Data** (from GitHub repository)
   - Event and sample records
   - Collection methodology
   - Collector information

3. **TANGO 2 Expedition Data** (from GitHub repository)
   - Event and sample records with sample ID ranges
   - Collection methodology
   - Collector information

### Output Format

#### Occurrence Table (`occurrence.txt`)
Darwin Core formatted table containing:
- Taxonomic identification (*Sterechinus neumayeri*)
- Event information (date, time, location, depth)
- Material sample identifiers
- Collector information
- Geographic coordinates (WGS84)

#### Measurement-or-Fact Table (`mof.txt`)
Extended measurements including:
- Stable isotope ratios (δ13C, δ15N, δ34S) in per mille
- Morphometric measurements (height, size ambitus) in mm
- Standardized measurement types and units

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Development Workflow

When adding or modifying code:

1. Ensure `renv` is activated
2. Install any new packages with `install.packages()`
3. Update the lockfile with `renv::snapshot()`
4. Test the transformation pipeline
5. Commit both code changes and `renv.lock` updates

---

## License

Please refer to the repository license file for terms of use.

---

## Credits and Acknowledgments

### Project Team
* **biodiversity-aq** organization

### Data Sources
* TANGO 1 expedition: https://github.com/biodiversity-aq/TANGO_1
* TANGO 2 expedition: https://github.com/biodiversity-aq/TANGO_2

### Key References
* Darwin Core Standard: https://dwc.tdwg.org/
* OBIS Extended Measurement or Fact: https://obis.org/manual/dataformat/#measurementorfact

### Dependencies
This project uses the following R packages:
* `tidyverse` - Data manipulation and visualization
* `here` - Project-relative path handling
* `readxl` - Excel file reading
* `janitor` - Data cleaning
* `hms` - Time data handling
* `data.table` - Efficient data operations

---

## Contact

For questions or issues, please open an issue in this repository or contact the biodiversity-aq team.

---

*This README follows the [cookiecutter](https://cookiecutter.readthedocs.io/) template style for consistent documentation.*
