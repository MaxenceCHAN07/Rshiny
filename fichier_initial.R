#Installation des packages si besoin
if (!require(httr)) {
  install.packages("httr")
}

if (!require(jsonlite)) {
  install.packages("jsonlite")
}

if (!require(dplyr)) {
  install.packages("dplyr")
}

if (!require(DBI)) {
  install.packages("DBI")
}

if (!require(RMySQL)) {
  install.packages("RMySQL")
}

#Chargement des packages
library(httr)
library(jsonlite)
library(dplyr)
library(DBI)
library(RMySQL)

#Extraction des données avec l'API
raw_data <- GET('https://api.jcdecaux.com/vls/v3/stations?contract=Lyon&apiKey=fc41d1b1016a6b95f0f755048a0690a80719ab50')

df <- fromJSON ( rawToChar ( raw_data$content ) , flatten =  TRUE ) #Conversion des données en bloc de données

#Geocodage
#reverse <- df %>%
#reverse_geocode(lat = position.latitude, long = position.longitude, method = 'osm',
#address = address, full_results = TRUE)

#reverse <- data.frame(df$`reverse$postcode`)
#reverse <- cbind(reverse,df$number)

#Faire fichier CSV geocodage
#write.csv2(reverse, file = "geocodage.csv")

#Lecture du fichier CSV
geocode_csv <- read.csv2(file = "geocodage.csv", sep = ";",header = TRUE)
geocode <- geocode_csv$df..reverse.postcode.
df <- cbind(df, geocode)

#Connexion à la base de données FreeSQLDatabase
#bdd <- dbConnect(MySQL(),
#                   user = "sql11645724" ,
#                   password = "C7MWFfpDxs" ,
#                   host = "sql11.freesqldatabase.com" ,
#                   dbname = "sql11645724",)

# Créez une table pour les données générales
df_general <- df %>%
  select(number, contractName, name, address, banking, bonus, status, lastUpdate, connected, overflow)

# Créez une table pour les informations de position
df_position <- df %>%
  select(number, position.latitude, position.longitude,geocode)

# Créez des tables pour les informations sur les stands
df_totalStands <- df %>%
  select(number, totalStands.capacity, totalStands.availabilities.bikes, totalStands.availabilities.stands, totalStands.availabilities.mechanicalBikes, totalStands.availabilities.electricalBikes, totalStands.availabilities.electricalInternalBatteryBikes, totalStands.availabilities.electricalRemovableBatteryBikes)

df_mainStands <- df %>%
  select(number, mainStands.capacity, mainStands.availabilities.bikes, mainStands.availabilities.stands, mainStands.availabilities.mechanicalBikes, mainStands.availabilities.electricalBikes, mainStands.availabilities.electricalInternalBatteryBikes, mainStands.availabilities.electricalRemovableBatteryBikes)

df_overflowStands <- df %>%
  select(number, overflowStands.capacity, overflowStands.availabilities.bikes, overflowStands.availabilities.stands, overflowStands.availabilities.mechanicalBikes, overflowStands.availabilities.electricalBikes, overflowStands.availabilities.electricalInternalBatteryBikes, overflowStands.availabilities.electricalRemovableBatteryBikes)


#Ecriture des tables dans la base de données
dbWriteTable(bdd, "General", df_general)
dbWriteTable(bdd, "Position", df_position)
dbWriteTable(bdd, "TotalStands", df_totalStands)
dbWriteTable(bdd, "MainStands", df_mainStands)
dbWriteTable(bdd, "OverflowStands", df_overflowStands)

