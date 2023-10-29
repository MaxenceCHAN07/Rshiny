# Rshiny - CHAN Maxence, Letexier Flavio, Mondou-Laurent Robin

Notre projet nous permet de créer des statistiques et KPI en fonction de données réelles de l'enseigne Vélo'v.
Pour cela nous sommes aller extraire nos données avec un API public des données de Vélo'v

Notre application a pour but de permettre aux utilisateurs Vélo'v de suivre en temps réel la disponibilités du parc Vélo'v (stations ouvertes ou fermées, nombre de places disponibles dans les stations, nombre de vélos disponibles...)

Nous avons pour cela développer une application Rshiny déployée sur shinyapps.io qui répond aux cahier des charges.
Sur ce repository vous pourrez retrouver le script de notre application, la notice d'utilisation de l'application pour l'utilisateur, le schéma relationnel des tables et un schéma de l'architecture

fichier_initial.R représente le fichier où nous avons fait la première connexion à l'API et où nous avons fait la première connexion à la base de données FreeSQLDatabase, nous avons ensuite créer des tables dans Rstudio que nous avons insérer dans la vrai base de données FreeSQLDatabase

app.R est tout simplement notre application Rshiny

geocodage.csv représente le fichier avec les codes postaux des stations
