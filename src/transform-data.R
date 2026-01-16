library(tidyverse)
library(here)
library(readxl)
library(janitor)
library(hms)
library(data.table)


## load data
tango_1_events <- read_tsv("https://raw.githubusercontent.com/biodiversity-aq/TANGO_1/refs/heads/main/data/03_output/tango_1_events.tsv", show_col_types = FALSE) 
tango_1_samples <- read_tsv("https://raw.githubusercontent.com/biodiversity-aq/TANGO_1/refs/heads/main/data/03_output/tango_1_samples.tsv", show_col_types = FALSE)
tango_2_events <- read_tsv("https://raw.githubusercontent.com/biodiversity-aq/TANGO_2/refs/heads/main/data/03_output/tango_2_events.tsv", show_col_types = FALSE)
tango_2_samples <- read_tsv("https://raw.githubusercontent.com/biodiversity-aq/TANGO_2/refs/heads/main/data/03_output/tango_2_samples.tsv", show_col_types = FALSE)

si <- read_xlsx(here("data", "01_raw", "Stable_Isotopes_Metadata.xlsx")) %>% 
  clean_names(case = "lower_camel") %>%
  rename(sampleID = sampleTangoId,
         organismID = urchinId,
         verbatimLatitude = latitude,
         verbatimLongitude = longitude,
         verbatimDepth = depth,
         locality = region) %>%
  mutate(
    minimumDepthInMeters = verbatimDepth,
    maximumDepthInMeters = verbatimDepth,
    decimalLatitude = round(verbatimLatitude, 4),
    decimalLongitude = round(verbatimLongitude, 4),
    sex = case_when(sex == "M" ~ "male", 
                    sex =="F" ~ "female", 
                    TRUE ~ ""),
    geodeticDatum = "EPSG:4326",
    basisOfRecord = "MaterialSample",
    materialEntityID = sampleID
  )


# TANGO 1 data
si_tango1 <- si %>% 
  filter(expedition == "TANGO1") %>% 
  left_join(tango_1_samples, by = c("sampleID" = "sampleID")) %>% 
  left_join(tango_1_events, by = c("eventID" = "eventID")) %>%
  # TODO: what is symbiotes analysis for? they are duplicated entry of the same sample. I select rows without symbiotes analysis
  filter(is.na(parameter) | parameter != "Symbiotes analysis") %>%
  left_join(tango_1_events, by = c("eventID" = "eventID")) %>%
  select(-matches("[0-9]$")) %>%  # remove columns ending with numbers like recordedBy1, recordedBy2, etc.
  select(!where(~ all(is.na(.)))) %>% # remove columns that are empty
  # thank Mr. C for duplicating the sea urchin sampleID for his random samples 凸(ಠ_ಠ凸)
  filter(scientificName == "Sterechinus neumayeri") %>%
  # select Darwin Core terms
  select(
    # IDs
    materialEntityID,
    organismID,
    siteId,
    # event
    eventID,
    parentEventID.x,
    date,
    # eventDate.x,  # eventDate from original TANGO 1 data, inconsistent with the one provided by Manon
    eventTime.x,
    eventRemarks.x,
    samplingProtocol.x,
    minimumDepthInMeters.x,
    maximumDepthInMeters.x,
    decimalLatitude.x,
    decimalLongitude.x,
    coordinateUncertaintyInMeters.x,  
    verbatimLatitude,
    verbatimLongitude,
    verbatimDepth,
    locality.x,
    higherGeographyID.x,
    
    # occurrence
    scientificName,
    scientificNameID,
    scientificNameAuthorship,
    kingdom,
    phylum,
    class,
    order,
    family,
    genus,
    specificEpithet,
    identificationQualifier,
    verbatimIdentification,
    identifiedBy,
    identifiedByID,
    sex,
    preparations,
    recordedBy,
    recordedByID,
    
    # emof
    sizeAmbitus,
    height,
    d13C,
    d15N,
    d34S
  ) %>% 
  rename(
    siteID = siteId,
    parentEventID = parentEventID.x,
    # eventDateTango = eventDate.x,  # eventDate from original TANGO 1 data, inconsistent with the one provided by Manon
    eventDate = date,  # eventDate from Manon's dataset
    eventTime = eventTime.x,
    eventRemarks = eventRemarks.x,
    samplingProtocol = samplingProtocol.x,
    minimumDepthInMeters = minimumDepthInMeters.x,
    maximumDepthInMeters = maximumDepthInMeters.x,
    decimalLatitude = decimalLatitude.x,
    decimalLongitude = decimalLongitude.x,
    coordinateUncertaintyInMeters = coordinateUncertaintyInMeters.x,
    locality = locality.x,
    higherGeographyID = higherGeographyID.x
  )
  
# TANGO 2 data
# cannot do a simple join because sampleIDs are within range of values sampleIdsStart and sampleIdsStop
si_t2 <- si %>% 
  filter(expedition == "TANGO2") 

# 1) Convert to data.table
ev <- as.data.table(tango_2_events)
si_2 <- as.data.table(si_t2)

# 2) If sample IDs are numeric already, keep them.
#    If they are strings like "S0123" or "T2_0123", extract the numeric part:
to_num <- function(x) as.integer(gsub(".*?(\\d+).*", "\\1", as.character(x)))

si_2[, sample_num := to_num(sampleID)]
ev[, start_num  := to_num(sampleIdsStart)]
ev[, stop_num   := to_num(sampleIdsStop)]

# 3) Range join: keep SI rows, bring in matching event columns
#    (Inclusive start/stop)
setkey(si_2, sample_num)
setkey(ev, start_num, stop_num)

# now contains all columns from ev + si (data.table-style join result)
si_tango2 <- ev[si_2, on = .(start_num <= sample_num, stop_num >= sample_num)] %>%
  # some sampleID are not found in event/samples sheet, assume they are these:
  mutate(scientificName = "Sterechinus neumayeri",
         scientificNameID = "urn:lsid:marinespecies.org:taxname:160831",
         kingdom = "Animalia",
         phylum = "Echinodermata",
         class = "Echinoidea",
         order = "Camarodonta",
         family = "Echinidae",
         genus = "Sterechinus",
         specificEpithet = "neumayeri",
         scientificNameAuthorship = "(Meissner, 1900)",
         # because the sampleIDs are not found, we also need to set event info 
         parentEventID = "https://www.wikidata.org/wiki/Q137398578",
         eventId = case_when(is.na(eventId) ~ "DIV_UNKOWN",
                             TRUE ~ eventId),
         ) %>%
  # collapse recordedBy and recordedByID
  rowwise() %>%
  mutate(
    recordedBy = paste(
      na.omit(c_across(starts_with("collector") & !ends_with("Orcid"))),
      collapse = " | "
    ),
    recordedBy = if_else(recordedBy == "", NA_character_, recordedBy),
    recordedByID = paste(
      na.omit(c_across(ends_with("Orcid"))),
      collapse = " | "
    ),
    recordedByID = if_else(recordedByID == "", NA_character_, recordedByID)
  ) %>%
  ungroup() %>%
  # select Darwin Core terms
  select(
    # IDs
    materialEntityID,
    organismID,
    siteId,
    # event
    eventId,
    parentEventID,
    date, # use date provided by Manon because it is more accurate, some date are not the same as eventDate in the original TANGO 2 data
    eventTime,
    eventRemarks,
    samplingProtocol,
    i.minimumDepthInMeters,
    i.maximumDepthInMeters,
    decimalLatitude,
    decimalLongitude,
    verbatimLatitude,
    verbatimLongitude,
    verbatimDepth,
    i.locality,
    higherGeographyId,
    
    # occurrence
    scientificName,
    scientificNameID,
    scientificNameAuthorship,
    kingdom,
    phylum,
    class,
    order,
    family,
    genus,
    specificEpithet,
    recordedBy,
    recordedByID,
    
    # emof
    sizeAmbitus,
    height,
    d13C,
    d15N,
    d34S
    ) %>%
  rename(
    eventID = eventId,
    eventDate = date,
    higherGeographyID = higherGeographyId,
    siteID = siteId,
    minimumDepthInMeters = i.minimumDepthInMeters,
    maximumDepthInMeters = i.maximumDepthInMeters,
    locality = i.locality
  )

# combine TANGO 1 and TANGO 2 data
occ <- bind_rows(si_tango1, si_tango2) %>%
  mutate(
    expedition = case_when(parentEventID == "https://www.wikidata.org/entity/Q119843670" ~ "TANGO_1",
                           parentEventID == "https://www.wikidata.org/wiki/Q137398578" ~ "TANGO_2",
                           TRUE ~ NA_character_),
    occurrenceID = paste(expedition, eventID, organismID, materialEntityID, sep = "-"),
    coordinateUncertaintyInMeters = 25,
  ) %>%
  select(occurrenceID, everything())  # make occurrenceID first column

emof <- occ %>%
  pivot_longer(
    cols = c(sizeAmbitus, height, d13C, d15N, d34S),
    names_to = "verbatimMeasurementType",
    values_to = "measurementValue"
  ) %>%
  mutate(
    measurementValue = case_when(
      verbatimMeasurementType %in% c("d13C", "d15N", "d34S") ~ round(measurementValue, 2),
      verbatimMeasurementType %in% c("height", "sizeAmbitus") ~ round(measurementValue, 0),
      TRUE ~ measurementValue
    ),
    measurementType = case_when(
      verbatimMeasurementType == "d13C" ~ "The δ13C measured in the considered sea urchin specimen, expressed in per mille and relative to the international reference Vienna Pee Dee Belemnite.",
      verbatimMeasurementType == "d15N" ~ "The δ15N measured in the considered sea urchin specimen, expressed in per mille and relative to the international reference Atmospheric Air.",
      verbatimMeasurementType == "d34S" ~ "The δ34S measured in the considered sea urchin specimen, expressed in per mille and relative to the international reference Vienna Canyon Diablo Troilite.",
      verbatimMeasurementType == "height" ~ "Height of sea urchin in mm",
      verbatimMeasurementType == "sizeAmbitus" ~ "Size ambitus of sea urchin in mm",
      TRUE ~ NA_character_
    ),
    measurementUnit = case_when(
      verbatimMeasurementType %in% c("d13C", "d15N", "d34S") ~ "per mille",
      verbatimMeasurementType %in% c("height", "sizeAmbitus") ~ "mm",
      TRUE ~ NA_character_
    )
  ) %>%
  select(
    occurrenceID,
    verbatimMeasurementType,
    measurementType,
    measurementValue
  ) 

# write output
write_tsv(occ, here("data", "02_output", "occurrence.txt"), na = "")
write_tsv(emof, here("data", "02_output", "emof.txt"), na = "")






