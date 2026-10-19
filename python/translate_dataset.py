# Translates column names and category values from Catalan to English.
# The original file is not modified. Output: data/processed/accidents_EN.csv
import pandas as pd, glob
# Run from the project folder: python3 python/translate_dataset.py
src = 'data/raw/accidents_raw.csv'
d = pd.read_csv(src, dtype=str, keep_default_na=False)

COLS = {
 "Any":"year","zona":"zone","dat":"date","via":"road","pk":"km_point","nomMun":"municipality",
 "nomCom":"county","nomDem":"province","F_MORTS":"n_dead","F_FERITS_GREUS":"n_serious_injured",
 "F_FERITS_LLEUS":"n_minor_injured","F_VICTIMES":"n_victims","F_UNITATS_IMPLICADES":"n_units",
 "F_VIANANTS_IMPLICADES":"n_pedestrians","F_BICICLETES_IMPLICADES":"n_bicycles",
 "F_CICLOMOTORS_IMPLICADES":"n_mopeds","F_MOTOCICLETES_IMPLICADES":"n_motorcycles",
 "F_VEH_LLEUGERS_IMPLICADES":"n_light_vehicles","F_VEH_PESANTS_IMPLICADES":"n_heavy_vehicles",
 "F_ALTRES_UNIT_IMPLICADES":"n_other_units","F_UNIT_DESC_IMPLICADES":"n_unknown_units",
 "C_VELOCITAT_VIA":"speed_limit","D_ACC_AMB_FUGA":"hit_and_run","D_BOIRA":"fog",
 "D_CARACT_ENTORN":"road_profile","D_CARRIL_ESPECIAL":"special_lane",
 "D_CIRCULACIO_MESURES_ESP":"special_traffic_measures","D_CLIMATOLOGIA":"weather",
 "D_FUNC_ESP_VIA":"road_special_function","D_GRAVETAT":"severity",
 "D_INFLUIT_BOIRA":"infl_fog","D_INFLUIT_CARACT_ENTORN":"infl_road_profile",
 "D_INFLUIT_CIRCULACIO":"infl_traffic","D_INFLUIT_ESTAT_CLIMA":"infl_weather",
 "D_INFLUIT_INTEN_VENT":"infl_wind","D_INFLUIT_LLUMINOSITAT":"infl_light",
 "D_INFLUIT_MESU_ESP":"infl_special_measures","D_INFLUIT_OBJ_CALCADA":"infl_object_on_road",
 "D_INFLUIT_SOLCS_RASES":"infl_ruts_ditches","D_INFLUIT_VISIBILITAT":"infl_visibility",
 "D_INTER_SECCIO":"intersection","D_LIMIT_VELOCITAT":"speed_limit_source","D_LLUMINOSITAT":"light",
 "D_REGULACIO_PRIORITAT":"priority_control","D_SENTITS_VIA":"directions",
 "D_SUBTIPUS_ACCIDENT":"accident_subtype","D_SUBTIPUS_TRAM":"junction_type","D_SUBZONA":"subzone",
 "D_SUPERFICIE":"surface","D_TIPUS_VIA":"road_type","D_TITULARITAT_VIA":"road_owner",
 "D_TRACAT_ALTIMETRIC":"gradient","D_VENT":"wind","grupDiaLab":"day_group","hor":"hour",
 "grupHor":"time_of_day","tipAcc":"accident_type","tipDia":"weekday_group"}

VALS = {
 "Si":"Yes","No":"No","No n'hi ha":"None","Sense especificar":"Unspecified","Sense Especificar":"Unspecified",
 "Altres":"Other","NA":"NA",
 "Zona urbana":"Urban","Carretera":"Interurban road","Travessera":"Through-town road",
 "A nivell":"Level","Mixt":"Mixed","Desmunt":"Cutting","Terraplé":"Embankment",
 "Carril bus":"Bus lane","Carril bici":"Bike lane","Carril acceleració":"Acceleration lane",
 "Carril central":"Centre lane","Carril d'alentiment":"Deceleration lane","Carril lent":"Slow lane",
 "Carril avançament":"Overtaking lane","Habilitació voral/carril addicional":"Shoulder used as extra lane",
 "Carril reversible":"Reversible lane","Carril habilitat en sentit contrari habitual":"Contraflow lane",
 "Obres":"Roadworks","Accident trànsit anterior":"Previous accident","Esdeveniment extraordinari":"Special event",
 "Serveis de neteja o manteniment":"Cleaning/maintenance","Cons":"Cones","Control policial":"Police check",
 "Bon temps":"Good weather","Pluja dèbil":"Light rain","Pluja forta":"Heavy rain","Calamarsa":"Hail","Nevant":"Snowing",
 "Sense funció especial":"None","Ronda, cinturo o circumval.lacio":"Ring road/bypass","Variant":"Bypass variant",
 "Accident greu":"Serious","Accident mortal":"Fatal",
 "En secció":"Road section (no junction)","Dintre intersecció":"Inside junction",
 "Arribant o eixint intersecció fins 50m":"Within 50 m of junction",
 "Genérica via":"Default for road","Senyal velocitat":"Speed sign",
 "De dia, dia clar":"Day, clear","De nit, il·luminació artificial suficient":"Night, adequate street light",
 "De nit, sense llum artificial":"Night, no street light","Alba o capvespre":"Dawn/dusk",
 "De nit, il·luminació artificial insuficient":"Night, poor street light","De dia, dia fosc":"Day, overcast/dark",
 "Senyal Stop o cedeix pas":"Stop/yield sign","Semàfor":"Traffic light","Sols norma prioritat de pas":"Priority rule only",
 "Sols marques viàries (inclou pas vianants)":"Road markings only (incl. crossing)","Persona autoritzada":"Authorised person",
 "Doble sentit":"Two-way","Un sol sentit":"One-way",
 "Atropellament":"Pedestrian hit","Envestida (frontal lateral)":"Front-to-side collision",
 "Resta sortides de via":"Other run-off-road","Caiguda en la via":"Fall on road",
 "Fregament o col·lisió lateral":"Sideswipe","Col·lisió frontal":"Head-on collision","Encalç":"Rear-end",
 "Xoc contra objecte/obstacle sense sortida prèvia de via":"Hit object on road",
 "Sortida de via amb xoc o col·lisió":"Run-off-road with impact","Sortida de via amb bolcada":"Run-off-road with rollover",
 "Xoc amb animal a la calçada":"Hit animal","Sortida de via amb atropellament":"Run-off-road hitting pedestrian",
 "Encreuament o intersecció en X o +":"X/+ crossroads","Intersecció en T o Y":"T/Y junction","Giratòria":"Roundabout",
 "Enllaç d'entrada o eixida":"On/off ramp","Pas a nivell":"Level crossing",
 "Sec i net":"Dry and clean","Mullat":"Wet","Relliscós":"Slippery","Inundat":"Flooded","Gelat":"Icy","Nevat":"Snowy",
 "Via urbana( inclou carrer i carrer residencial)":"Urban street","Carretera convencional":"Conventional road",
 "Autovia":"Autovia (free dual carriageway)","Autopista":"Autopista (motorway)","Camí rural/pista forestal":"Rural/forest track",
 "Autonòmica":"Regional (Generalitat)","Estatal":"State","Provincial":"Provincial","Municipal":"Municipal",
 "Pla":"Flat","Rampa o pendent":"Slope","Canvi rasant":"Crest","Gual":"Dip",
 "Calma, vent molt suau":"Calm","Vent moderat":"Moderate wind","Vent fort":"Strong wind",
 "Feiners":"Weekday","CapDeSetmana":"Weekend","Matí":"Morning","Tarda":"Afternoon","Nit":"Night",
 "Col.lisió de vehicles en marxa":"Collision between moving vehicles","Sortida de la calcada sense especificar":"Run-off-road",
 "Bolcada a la calcada":"Fall/overturn on road","Col.lisió d'un vehicle contra un obstacle de la calcada":"Collision with obstacle",
 "dill-dij":"Mon-Thu","div":"Fri","dis":"Sat","dg":"Sun"}

keep = {"Any","dat","via","pk","nomMun","nomCom","nomDem","hor","C_VELOCITAT_VIA"}
for c in d.columns:
    if c not in keep and not c.startswith("F_"):
        d[c] = d[c].map(lambda v: VALS.get(v, v))
d = d.rename(columns=COLS)
d.to_csv("data/processed/accidents_EN.csv", index=False)

# check: values that were not translated
for c in d.columns:
    if c in COLS.values() and d[c].nunique() <= 20 and not c.startswith("n_"):
        left = [v for v in d[c].unique() if v in {k for k in VALS if VALS[k]!=k} ]
        if left: print("NOT TRANSLATED", c, left)
print(d.shape); print(d.head(3).T.head(25))
