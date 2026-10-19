# Codebook – accident dataset (Option 1)

`data/processed/accidents_EN.csv` is a translated copy of the original (`data/raw/accidents_raw.csv`), produced by `python/translate_dataset.py`. The original file is untouched.
One row = one accident with at least one death or serious injury. 24,478 rows, 2010–2023.

**"Unknown" codes to watch for:** `NA`, `Unspecified`, `999` (speed limit) and `999999` (km_point).

## Time and place
| English name | Original | Meaning |
|---|---|---|
| year | Any | Year |
| date | dat | Date (dd/mm/yyyy) – used to build the before/after variable |
| hour | hor | Time of day as a decimal number with comma ("23,33" ≈ 23:20) |
| time_of_day | grupHor | Morning / Afternoon / Night |
| weekday_group | tipDia | Mon–Thu, Fri, Sat, Sun |
| day_group | grupDiaLab | Weekday / weekend |
| zone | zona | Urban or Interurban road |
| subzone | D_SUBZONA | Like zone, but separates through-town roads |
| road | via | Road name, e.g. AP-7, N-II, C-32. The key for the ex_toll variable |
| km_point | pk | Kilometre point on the road (999999 = unknown) |
| municipality / county / province | nomMun / nomCom / nomDem | Municipality / comarca (county) / province |

## Parties involved (counts)
| Name | Meaning |
|---|---|
| n_dead, n_serious_injured, n_minor_injured, n_victims | Dead, seriously injured, slightly injured, total victims |
| n_units | Number of vehicles/units involved |
| n_pedestrians, n_bicycles, n_mopeds, n_motorcycles | Pedestrians, bicycles, mopeds, motorcycles |
| n_light_vehicles, n_heavy_vehicles | Light vehicles (cars, vans) / heavy (trucks, buses) |
| n_other_units, n_unknown_units | Other units (possibly e-scooters?) / unknown type |

## The accident
| Name | Original | Meaning |
|---|---|---|
| severity | D_GRAVETAT | Serious / Fatal |
| accident_type | tipAcc | Main type: collision, run-off-road, pedestrian hit, fall/overturn … |
| accident_subtype | D_SUBTIPUS_ACCIDENT | Detailed: head-on, rear-end, sideswipe … |
| hit_and_run | D_ACC_AMB_FUGA | Driver fled the scene |

## The road
| Name | Original | Meaning |
|---|---|---|
| road_type | D_TIPUS_VIA | Urban street, conventional road, autovia (free dual carriageway), autopista (motorway). **Inconsistent over time – see note below** |
| road_owner | D_TITULARITAT_VIA | Who owns the road (State, Generalitat, province, municipality). NA for most urban streets |
| speed_limit | C_VELOCITAT_VIA | Speed limit km/h (999 = unknown) |
| speed_limit_source | D_LIMIT_VELOCITAT | Default limit for the road type or a speed sign |
| directions | D_SENTITS_VIA | One-way / two-way |
| intersection | D_INTER_SECCIO | Road section, inside junction, or within 50 m of junction |
| junction_type | D_SUBTIPUS_TRAM | X-crossing, T-junction, roundabout, ramp |
| priority_control | D_REGULACIO_PRIORITAT | Stop/yield sign, traffic light, markings … (71% NA) |
| special_lane | D_CARRIL_ESPECIAL | Bus lane, bike lane, acceleration lane … |
| road_special_function | D_FUNC_ESP_VIA | Ring road, bypass, through-town road |
| road_profile | D_CARACT_ENTORN | Road level with terrain, in a cutting or on an embankment |
| gradient | D_TRACAT_ALTIMETRIC | Flat, slope, crest, dip |
| special_traffic_measures | D_CIRCULACIO_MESURES_ESP | Roadworks, police check, previous accident … |

## Conditions
| Name | Original | Meaning |
|---|---|---|
| weather | D_CLIMATOLOGIA | Weather |
| surface | D_SUPERFICIE | Road surface: dry, wet, slippery, icy … |
| light | D_LLUMINOSITAT | Daylight / dark with or without street lighting |
| fog, wind | D_BOIRA, D_VENT | Fog, wind |
| infl_* | D_INFLUIT_* | "Did this factor influence the accident?" (Yes/No/Unspecified) – police assessment for fog, weather, light, visibility, wind, object on road, etc. "Unspecified" is its own category – do not treat it as "No" without thinking. |

## Important data-quality notes
- **road_type:** "Autopista" is used almost only in 2013–2015; the AP-7 is coded as "Conventional road" in other years. Use `road` (road name) to identify motorways / former toll roads.
- **n_other_units** and **accident_type = "Other"** rise sharply from 2020 (likely e-scooters) – a time trend, not a toll effect.
- Missingness increases over time for several variables (e.g. gradient, directions) – the NA share alone can separate before/after.
