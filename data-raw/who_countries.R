# =============================================================================
# data-raw/who_countries.R
#
# Build the country-related datasets shipped with DSIR.
#
# This script is the SINGLE SOURCE OF TRUTH for who_countries, wpro_cty,
# afro_cty, amro_cty, emro_cty, euro_cty, searo_cty, and pic_cty.
#
# All vectors are derived from the master `who_countries` tibble below.
# When you need to update country assignments (e.g. a new region change
# announced by the World Health Assembly), edit the master tibble here,
# then re-run this script in full.
#
# Run from the package root with:
#   source("data-raw/who_countries.R")
#
# Sources:
# - WHO regions: WHO official "Countries/areas by WHO region" PDF
#   <https://apps.who.int/violence-info/>
# - May 2025 amendment: Indonesia moved from SEAR to WPR (WHO EB156)
# - ISO3 / ISO2 / M49 codes: UN Statistics Division
#   <https://unstats.un.org/unsd/methodology/m49/>
#
# Scope: WHO Member States only (194 countries).
# Excluded:
#   - Associate Members: Puerto Rico (AMR), Tokelau (WPR)
#   - Non-Member areas: West Bank and Gaza Strip (EMR)
# =============================================================================

library(tibble)
library(dplyr)
library(usethis)

# -----------------------------------------------------------------------------
# Master table: one row per Member State.
# Built region-by-region for readability and so that a region change is a
# matter of moving one row between blocks.
# -----------------------------------------------------------------------------

afr_rows <- tribble(
  ~name_official,                         ~iso3,  ~iso2, ~m49_code,
  "Algeria",                              "DZA",  "DZ",  "012",
  "Angola",                               "AGO",  "AO",  "024",
  "Benin",                                "BEN",  "BJ",  "204",
  "Botswana",                             "BWA",  "BW",  "072",
  "Burkina Faso",                         "BFA",  "BF",  "854",
  "Burundi",                              "BDI",  "BI",  "108",
  "Cabo Verde",                           "CPV",  "CV",  "132",
  "Cameroon",                             "CMR",  "CM",  "120",
  "Central African Republic",             "CAF",  "CF",  "140",
  "Chad",                                 "TCD",  "TD",  "148",
  "Comoros",                              "COM",  "KM",  "174",
  "Congo",                                "COG",  "CG",  "178",
  "Côte d'Ivoire",                        "CIV",  "CI",  "384",
  "Democratic Republic of the Congo",     "COD",  "CD",  "180",
  "Equatorial Guinea",                    "GNQ",  "GQ",  "226",
  "Eritrea",                              "ERI",  "ER",  "232",
  "Eswatini",                             "SWZ",  "SZ",  "748",
  "Ethiopia",                             "ETH",  "ET",  "231",
  "Gabon",                                "GAB",  "GA",  "266",
  "Gambia",                               "GMB",  "GM",  "270",
  "Ghana",                                "GHA",  "GH",  "288",
  "Guinea",                               "GIN",  "GN",  "324",
  "Guinea-Bissau",                        "GNB",  "GW",  "624",
  "Kenya",                                "KEN",  "KE",  "404",
  "Lesotho",                              "LSO",  "LS",  "426",
  "Liberia",                              "LBR",  "LR",  "430",
  "Madagascar",                           "MDG",  "MG",  "450",
  "Malawi",                               "MWI",  "MW",  "454",
  "Mali",                                 "MLI",  "ML",  "466",
  "Mauritania",                           "MRT",  "MR",  "478",
  "Mauritius",                            "MUS",  "MU",  "480",
  "Mozambique",                           "MOZ",  "MZ",  "508",
  "Namibia",                              "NAM",  "NA",  "516",
  "Niger",                                "NER",  "NE",  "562",
  "Nigeria",                              "NGA",  "NG",  "566",
  "Rwanda",                               "RWA",  "RW",  "646",
  "Sao Tome and Principe",                "STP",  "ST",  "678",
  "Senegal",                              "SEN",  "SN",  "686",
  "Seychelles",                           "SYC",  "SC",  "690",
  "Sierra Leone",                         "SLE",  "SL",  "694",
  "South Africa",                         "ZAF",  "ZA",  "710",
  "South Sudan",                          "SSD",  "SS",  "728",
  "Togo",                                 "TGO",  "TG",  "768",
  "Uganda",                               "UGA",  "UG",  "800",
  "United Republic of Tanzania",          "TZA",  "TZ",  "834",
  "Zambia",                               "ZMB",  "ZM",  "894",
  "Zimbabwe",                             "ZWE",  "ZW",  "716",
) %>% mutate(who_region = "AFR")

amr_rows <- tribble(
  ~name_official,                         ~iso3,  ~iso2, ~m49_code,
  "Antigua and Barbuda",                  "ATG",  "AG",  "028",
  "Argentina",                            "ARG",  "AR",  "032",
  "Bahamas",                              "BHS",  "BS",  "044",
  "Barbados",                             "BRB",  "BB",  "052",
  "Belize",                               "BLZ",  "BZ",  "084",
  "Bolivia (Plurinational State of)",     "BOL",  "BO",  "068",
  "Brazil",                               "BRA",  "BR",  "076",
  "Canada",                               "CAN",  "CA",  "124",
  "Chile",                                "CHL",  "CL",  "152",
  "Colombia",                             "COL",  "CO",  "170",
  "Costa Rica",                           "CRI",  "CR",  "188",
  "Cuba",                                 "CUB",  "CU",  "192",
  "Dominica",                             "DMA",  "DM",  "212",
  "Dominican Republic",                   "DOM",  "DO",  "214",
  "Ecuador",                              "ECU",  "EC",  "218",
  "El Salvador",                          "SLV",  "SV",  "222",
  "Grenada",                              "GRD",  "GD",  "308",
  "Guatemala",                            "GTM",  "GT",  "320",
  "Guyana",                               "GUY",  "GY",  "328",
  "Haiti",                                "HTI",  "HT",  "332",
  "Honduras",                             "HND",  "HN",  "340",
  "Jamaica",                              "JAM",  "JM",  "388",
  "Mexico",                               "MEX",  "MX",  "484",
  "Nicaragua",                            "NIC",  "NI",  "558",
  "Panama",                               "PAN",  "PA",  "591",
  "Paraguay",                             "PRY",  "PY",  "600",
  "Peru",                                 "PER",  "PE",  "604",
  "Saint Kitts and Nevis",                "KNA",  "KN",  "659",
  "Saint Lucia",                          "LCA",  "LC",  "662",
  "Saint Vincent and the Grenadines",     "VCT",  "VC",  "670",
  "Suriname",                             "SUR",  "SR",  "740",
  "Trinidad and Tobago",                  "TTO",  "TT",  "780",
  "United States of America",             "USA",  "US",  "840",
  "Uruguay",                              "URY",  "UY",  "858",
  "Venezuela (Bolivarian Republic of)",   "VEN",  "VE",  "862",
) %>% mutate(who_region = "AMR")

sear_rows <- tribble(
  ~name_official,                         ~iso3,  ~iso2, ~m49_code,
  "Bangladesh",                           "BGD",  "BD",  "050",
  "Bhutan",                               "BTN",  "BT",  "064",
  "Democratic People's Republic of Korea","PRK",  "KP",  "408",
  "India",                                "IND",  "IN",  "356",
  "Maldives",                             "MDV",  "MV",  "462",
  "Myanmar",                              "MMR",  "MM",  "104",
  "Nepal",                                "NPL",  "NP",  "524",
  "Sri Lanka",                            "LKA",  "LK",  "144",
  "Thailand",                             "THA",  "TH",  "764",
  "Timor-Leste",                          "TLS",  "TL",  "626",
) %>% mutate(who_region = "SEAR")

eur_rows <- tribble(
  ~name_official,                         ~iso3,  ~iso2, ~m49_code,
  "Albania",                              "ALB",  "AL",  "008",
  "Andorra",                              "AND",  "AD",  "020",
  "Armenia",                              "ARM",  "AM",  "051",
  "Austria",                              "AUT",  "AT",  "040",
  "Azerbaijan",                           "AZE",  "AZ",  "031",
  "Belarus",                              "BLR",  "BY",  "112",
  "Belgium",                              "BEL",  "BE",  "056",
  "Bosnia and Herzegovina",               "BIH",  "BA",  "070",
  "Bulgaria",                             "BGR",  "BG",  "100",
  "Croatia",                              "HRV",  "HR",  "191",
  "Cyprus",                               "CYP",  "CY",  "196",
  "Czechia",                              "CZE",  "CZ",  "203",
  "Denmark",                              "DNK",  "DK",  "208",
  "Estonia",                              "EST",  "EE",  "233",
  "Finland",                              "FIN",  "FI",  "246",
  "France",                               "FRA",  "FR",  "250",
  "Georgia",                              "GEO",  "GE",  "268",
  "Germany",                              "DEU",  "DE",  "276",
  "Greece",                               "GRC",  "GR",  "300",
  "Hungary",                              "HUN",  "HU",  "348",
  "Iceland",                              "ISL",  "IS",  "352",
  "Ireland",                              "IRL",  "IE",  "372",
  "Israel",                               "ISR",  "IL",  "376",
  "Italy",                                "ITA",  "IT",  "380",
  "Kazakhstan",                           "KAZ",  "KZ",  "398",
  "Kyrgyzstan",                           "KGZ",  "KG",  "417",
  "Latvia",                               "LVA",  "LV",  "428",
  "Lithuania",                            "LTU",  "LT",  "440",
  "Luxembourg",                           "LUX",  "LU",  "442",
  "Malta",                                "MLT",  "MT",  "470",
  "Monaco",                               "MCO",  "MC",  "492",
  "Montenegro",                           "MNE",  "ME",  "499",
  "Netherlands (Kingdom of the)",         "NLD",  "NL",  "528",
  "North Macedonia",                      "MKD",  "MK",  "807",
  "Norway",                               "NOR",  "NO",  "578",
  "Poland",                               "POL",  "PL",  "616",
  "Portugal",                             "PRT",  "PT",  "620",
  "Republic of Moldova",                  "MDA",  "MD",  "498",
  "Romania",                              "ROU",  "RO",  "642",
  "Russian Federation",                   "RUS",  "RU",  "643",
  "San Marino",                           "SMR",  "SM",  "674",
  "Serbia",                               "SRB",  "RS",  "688",
  "Slovakia",                             "SVK",  "SK",  "703",
  "Slovenia",                             "SVN",  "SI",  "705",
  "Spain",                                "ESP",  "ES",  "724",
  "Sweden",                               "SWE",  "SE",  "752",
  "Switzerland",                          "CHE",  "CH",  "756",
  "Tajikistan",                           "TJK",  "TJ",  "762",
  "Türkiye",                              "TUR",  "TR",  "792",
  "Turkmenistan",                         "TKM",  "TM",  "795",
  "Ukraine",                              "UKR",  "UA",  "804",
  "United Kingdom of Great Britain and Northern Ireland",
                                          "GBR",  "GB",  "826",
  "Uzbekistan",                           "UZB",  "UZ",  "860",
) %>% mutate(who_region = "EUR")

emr_rows <- tribble(
  ~name_official,                         ~iso3,  ~iso2, ~m49_code,
  "Afghanistan",                          "AFG",  "AF",  "004",
  "Bahrain",                              "BHR",  "BH",  "048",
  "Djibouti",                             "DJI",  "DJ",  "262",
  "Egypt",                                "EGY",  "EG",  "818",
  "Iran (Islamic Republic of)",           "IRN",  "IR",  "364",
  "Iraq",                                 "IRQ",  "IQ",  "368",
  "Jordan",                               "JOR",  "JO",  "400",
  "Kuwait",                               "KWT",  "KW",  "414",
  "Lebanon",                              "LBN",  "LB",  "422",
  "Libya",                                "LBY",  "LY",  "434",
  "Morocco",                              "MAR",  "MA",  "504",
  "Oman",                                 "OMN",  "OM",  "512",
  "Pakistan",                             "PAK",  "PK",  "586",
  "Qatar",                                "QAT",  "QA",  "634",
  "Saudi Arabia",                         "SAU",  "SA",  "682",
  "Somalia",                              "SOM",  "SO",  "706",
  "Sudan",                                "SDN",  "SD",  "729",
  "Syrian Arab Republic",                 "SYR",  "SY",  "760",
  "Tunisia",                              "TUN",  "TN",  "788",
  "United Arab Emirates",                 "ARE",  "AE",  "784",
  "Yemen",                                "YEM",  "YE",  "887",
) %>% mutate(who_region = "EMR")

wpr_rows <- tribble(
  ~name_official,                         ~iso3,  ~iso2, ~m49_code,
  "Australia",                            "AUS",  "AU",  "036",
  "Brunei Darussalam",                    "BRN",  "BN",  "096",
  "Cambodia",                             "KHM",  "KH",  "116",
  "China",                                "CHN",  "CN",  "156",
  "Cook Islands",                         "COK",  "CK",  "184",
  "Fiji",                                 "FJI",  "FJ",  "242",
  "Indonesia",                            "IDN",  "ID",  "360",
  "Japan",                                "JPN",  "JP",  "392",
  "Kiribati",                             "KIR",  "KI",  "296",
  "Lao People's Democratic Republic",     "LAO",  "LA",  "418",
  "Malaysia",                             "MYS",  "MY",  "458",
  "Marshall Islands",                     "MHL",  "MH",  "584",
  "Micronesia (Federated States of)",     "FSM",  "FM",  "583",
  "Mongolia",                             "MNG",  "MN",  "496",
  "Nauru",                                "NRU",  "NR",  "520",
  "New Zealand",                          "NZL",  "NZ",  "554",
  "Niue",                                 "NIU",  "NU",  "570",
  "Palau",                                "PLW",  "PW",  "585",
  "Papua New Guinea",                     "PNG",  "PG",  "598",
  "Philippines",                          "PHL",  "PH",  "608",
  "Republic of Korea",                    "KOR",  "KR",  "410",
  "Samoa",                                "WSM",  "WS",  "882",
  "Singapore",                            "SGP",  "SG",  "702",
  "Solomon Islands",                      "SLB",  "SB",  "090",
  "Tonga",                                "TON",  "TO",  "776",
  "Tuvalu",                               "TUV",  "TV",  "798",
  "Vanuatu",                              "VUT",  "VU",  "548",
  "Viet Nam",                             "VNM",  "VN",  "704",
) %>% mutate(who_region = "WPR")

# -----------------------------------------------------------------------------
# Short-name overrides.
# Only listed when name_short differs from name_official.
# All other countries get name_short = name_official.
# -----------------------------------------------------------------------------

short_overrides <- tribble(
  ~name_official,                                         ~name_short,
  "Bolivia (Plurinational State of)",                     "Bolivia",
  "Democratic People's Republic of Korea",                "DPR Korea",
  "Democratic Republic of the Congo",                     "DR Congo",
  "Iran (Islamic Republic of)",                           "Iran",
  "Lao People's Democratic Republic",                     "Lao PDR",
  "Micronesia (Federated States of)",                     "Micronesia",
  "Netherlands (Kingdom of the)",                         "Netherlands",
  "Republic of Moldova",                                  "Moldova",
  "Syrian Arab Republic",                                 "Syria",
  "United Kingdom of Great Britain and Northern Ireland", "United Kingdom",
  "United Republic of Tanzania",                          "Tanzania",
  "United States of America",                             "United States",
  "Venezuela (Bolivarian Republic of)",                   "Venezuela",
)

# -----------------------------------------------------------------------------
# Pacific Island Countries (PICs).
# Source: WHO WPR. Member states only — French/US territories and Tokelau
# (Associate Member) are excluded because they are not in this dataset.
# -----------------------------------------------------------------------------

pic_iso3 <- c("COK", "FJI", "KIR", "MHL", "FSM", "NRU", "NIU", "PLW",
              "PNG", "WSM", "SLB", "TON", "TUV", "VUT")

# -----------------------------------------------------------------------------
# Assemble the master tibble.
# -----------------------------------------------------------------------------

who_countries <- bind_rows(
    afr_rows, amr_rows, sear_rows, eur_rows, emr_rows, wpr_rows
  ) %>%
  left_join(short_overrides, by = "name_official") %>%
  mutate(
    name_short = coalesce(name_short, name_official),
    is_pic     = iso3 %in% pic_iso3
  ) %>%
  select(iso3, iso2, m49_code, name_official, name_short, who_region, is_pic) %>%
  arrange(name_official)

# -----------------------------------------------------------------------------
# Sanity checks (fail loudly if anything is off).
# -----------------------------------------------------------------------------

stopifnot(
  "who_countries should have 194 rows"     = nrow(who_countries) == 194,
  "iso3 should be unique"                  = !anyDuplicated(who_countries$iso3),
  "iso2 should be unique"                  = !anyDuplicated(who_countries$iso2),
  "m49_code should be unique"              = !anyDuplicated(who_countries$m49_code),
  "no NA in critical columns"              = !anyNA(who_countries[, c("iso3", "name_official", "who_region")]),
  "Namibia ISO2 must remain the literal string 'NA'" =
    identical(who_countries$iso2[who_countries$iso3 == "NAM"], "NA"),
  "no actual NA values in iso2 column"     = !anyNA(who_countries$iso2),
  "who_region values are the 6 WHO codes"  = setequal(unique(who_countries$who_region),
                                                       c("AFR","AMR","SEAR","EUR","EMR","WPR")),
  "AFR has 47"                             = sum(who_countries$who_region == "AFR")  == 47,
  "AMR has 35"                             = sum(who_countries$who_region == "AMR")  == 35,
  "SEAR has 10"                            = sum(who_countries$who_region == "SEAR") == 10,
  "EUR has 53"                             = sum(who_countries$who_region == "EUR")  == 53,
  "EMR has 21"                             = sum(who_countries$who_region == "EMR")  == 21,
  "WPR has 28"                             = sum(who_countries$who_region == "WPR")  == 28,
  "14 PICs"                                = sum(who_countries$is_pic) == 14,
  "all PICs are in WPR"                    = all(who_countries$who_region[who_countries$is_pic] == "WPR")
)

# -----------------------------------------------------------------------------
# Derive convenience character vectors.
# Sorted alphabetically by ISO3 for predictability.
# -----------------------------------------------------------------------------

afro_cty  <- sort(who_countries$iso3[who_countries$who_region == "AFR"])
amro_cty  <- sort(who_countries$iso3[who_countries$who_region == "AMR"])
searo_cty <- sort(who_countries$iso3[who_countries$who_region == "SEAR"])
euro_cty  <- sort(who_countries$iso3[who_countries$who_region == "EUR"])
emro_cty  <- sort(who_countries$iso3[who_countries$who_region == "EMR"])
wpro_cty  <- sort(who_countries$iso3[who_countries$who_region == "WPR"])
pic_cty   <- sort(who_countries$iso3[who_countries$is_pic])

stopifnot(
  "wpro_cty length"  = length(wpro_cty)  == 28,
  "pic_cty length"   = length(pic_cty)   == 14,
  "all PICs are in wpro_cty" = all(pic_cty %in% wpro_cty)
)

# -----------------------------------------------------------------------------
# Save to data/.
# Each call generates one .rda in data/ and lazily exposes the object as
# DSIR::<name>.
# -----------------------------------------------------------------------------

usethis::use_data(who_countries, overwrite = TRUE)
usethis::use_data(wpro_cty,      overwrite = TRUE)
usethis::use_data(afro_cty,      overwrite = TRUE)
usethis::use_data(amro_cty,      overwrite = TRUE)
usethis::use_data(searo_cty,     overwrite = TRUE)
usethis::use_data(euro_cty,      overwrite = TRUE)
usethis::use_data(emro_cty,      overwrite = TRUE)
usethis::use_data(pic_cty,       overwrite = TRUE)

message("\nDone. ", nrow(who_countries), " countries written to data/.")
