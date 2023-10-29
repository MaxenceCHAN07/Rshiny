#Installation des packages nécessaires s'ils ne sont pas déjà installés
if (!require(shinydashboard)) {
  install.packages("shinydashboard")
}

if (!require(shinyjs)) {
  install.packages("shinyjs")
}
if (!require(httr)) {
  install.packages("httr")
}

if (!require(jsonlite)) {
  install.packages("jsonlite")
}

if (!require(leaflet)) {
  install.packages("leaflet")
}

if (!require(tidygeocoder)) {
  install.packages('tidygeocoder')
}
if (!require(car)) {
  install.packages('car')
}

if (!require(shinyauthr)) {
  install.packages('shinyauthr')
}

if (!require(ggplot2)) {
  install.packages("ggplot2")
}

if (!require(DT)) {
  install.packages("DT")
}

if (!require(gridExtra)) {
  install.packages("gridExtra")
}

#Chargements des packages
library(gridExtra)
library(DT)
library(ggplot2)
library(shinyauthr)
library(httr)
library(car)
library(leaflet)
library(dplyr, warn.conflicts = FALSE)
library(tidygeocoder)
library(httr)
library(jsonlite)
library(shiny)
library(shinyjs)
library(shinydashboard)

#Extraction de données ave l'API
raw_data <- GET('https://api.jcdecaux.com/vls/v3/stations?contract=Lyon&apiKey=fc41d1b1016a6b95f0f755048a0690a80719ab50')
df <- fromJSON(rawToChar(raw_data$content), flatten = TRUE)


#Geocodage des stations

#Code mis en commentaire pour éviter de géocoder à chaque ouverture de l'application
#Pour cela nous avons générer un fichier csv avec la liste des codes postaux

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

# Créez une application Shiny avec un format dashboard
ui <-  
  dashboardPage(skin = "red",
                dashboardHeader(
                  title = "Vélo'v", uiOutput("logoutbtn")
                ),
                #Création des onglets du dashboard
                dashboardSidebar(
                  sidebarMenu(
                    menuItem("Accueil", tabName = "accueil"),
                    menuItem("Données brutes", tabName = "donnees"),
                    menuItem("KPI", tabName = "chiffres_cles"),
                    menuItem("Bouton", tabName = "boutons")
                  )
                ),
                #Ici on va venir manipuler l'interface des onglets et ajouter nos données, stats, graphs, map...
                dashboardBody(
                  useShinyjs(),
                  extendShinyjs(text = "shinyjs.refresh_page = function() { location.reload(); }", functions = "refresh_page"),
                  
                  #Utilisation de script CSS pour modifier la charte graphique
                  tags$style(
                    HTML("
        .map {
            font-weight: bold;
            color : white;
            background : #A7C7E7;
        }
        
        .gras {
          font-weight:bold;
          font-size : 100;
        }
        "
                    )
                    
                  ),
                  
                  tabItems(
                    tabItem("accueil",
                            fluidRow(
                              column(
                                width = 8,
                                box(
                                  title = "Map des stations des vélo'v",
                                  status = "primary",
                                  solidHeader = TRUE,
                                  width = NULL,
                                  "Choose to subset the genes that are up or down regulated",
                                  br(),
                                  br(),
                                  #Renvoyer la carte "mymap" générer dans le server
                                  leafletOutput("mymap")
                                )
                              ),
                              column(
                                width = 4,
                                fluidRow(
                                  box(width = 10,
                                      #Création de filtre avec liste déroulante
                                      selectInput("postcode", "Filtrez selon le code postal des stations la carte",
                                                  choices = c("Tous", unique(df$geocode)),
                                                  multiple = TRUE, selected = "Tous"),
                                      selectInput("statusfilter", "Filtrez selon le statut des stations",
                                                  choices = c("Tous", unique(df$status)),
                                                  multiple = TRUE,
                                                  selected = "Tous"
                                      )
                                  ))))),
                    
                    tabItem("donnees",
                            #Affichage des données brutes 
                            DTOutput("data")),
                    
                    tabItem("chiffres_cles",
                            h2("Key Performance Indicator (KPI)", style = "font-size: 36px; font-weight : bold;"),
                            br(),
                            fluidRow(
                              div(style = "margin-left : 20px;",
                                  #Filtre avec liste déroulante
                                  selectInput("postcodekpi", "Filtrez selon le code postal les KPI",
                                              choices = c("Tous", unique(df$geocode)),
                                              multiple = TRUE,
                                              selected = "Tous"
                                  )),
                              
                              infoBox("Nombre de vélos disponibles", 
                                      textOutput("velos_disponibles"), 
                                      icon = icon("bicycle"), width = 3.1),
                              infoBox("Nombre de stations ouvertes", 
                                      textOutput("stations_ouvertes"), 
                                      icon = icon("square-parking", style = "color : black;"), width = 3.1),
                              infoBox("Nombre de stations avec banking (terminal de paiement)", 
                                      textOutput("stations_banking"), 
                                      icon = icon("credit-card", style = "color : gold;"), width = 3.1),
                            ),
                            #Permet d'afficher les graphiques sur le meme axe y et côte à côte
                            div(
                              style = "display: flex; flex-direction: row; justify-content: space-between;",
                              tags$div(style = "width: 50%;", plotOutput("hist")),  # Ajustez la largeur en pourcentage
                              tags$div(style = "width: 50%;", plotOutput("hist2"))  # Ajustez la largeur en pourcentage
                            )),
                    tabItem("boutons",
                            h2("Cliquez sur le bouton Exporter les graphiques",style =
                                 "font-size: 36px; font-weight : bold;"),
                            br(),
                            #Création du bouton pour télécharger les graphiques de la page KPI
                            downloadButton(outputId =  "exporter", label = "Exporter les graphiques"),
                            br(),
                            br(),
                            br(),
                            h2("Cliquez sur le bouton Refresh les données",style =
                                 "font-size: 36px; font-weight : bold;"),
                            br(),
                            useShinyjs(),
                            #Création du bouton refresh
                            actionButton("refresh", "Refresh")
                            
                    )
                  )
                )
  )

server <- function(input, output, session) {
  
  load_data <- reactive({
    
    raw_data <- GET('https://api.jcdecaux.com/vls/v3/stations?contract=Lyon&apiKey=fc41d1b1016a6b95f0f755048a0690a80719ab50')
    df <- fromJSON(rawToChar(raw_data$content), flatten = TRUE)
    
  })
  
  observe({
    # Filtrer les données en fonction de la sélection de postcode
    filtered_data <- df
    if (!"Tous" %in% input$postcode) {
      filtered_data <- filtered_data %>% filter(geocode %in% input$postcode)
    }
    
    # Mettre à jour les options du filtre statusfilter
    updateSelectInput(session, "statusfilter", choices = c("Tous", unique(filtered_data$status)), selected = "Tous")
  })
  
  output$mymap <- renderLeaflet({
    
    # Filtre les données en fonction des sélections "postcode" et "statusfilter"
    
    if ("Tous" %in% input$postcode) {
      filtered_data <- df
    } else {
      filtered_data <- df %>%
        filter(geocode %in% input$postcode)
    }
    
    if ("Tous" %in% input$statusfilter) {
      filtered_data <- filtered_data
    } else {
      filtered_data <- filtered_data %>%
        filter(status %in% input$statusfilter)
    }
    
    # Cette partie génère une carte Leaflet pour afficher les stations de vélos
    # Puis, elle ajoute des marqueurs pour chaque station sur la carte
    # Les marqueurs sont regroupés en clusters pour une meilleure lisibilité
    leaflet() %>%
      setView(lng = 4.835659, lat = 45.764043, zoom = 11) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = filtered_data$position.longitude,
        lat = filtered_data$position.latitude,
        radius = 10,
        fillOpacity = 0.7,
        stroke = FALSE,
        popup = paste(
          div(class = "map", "Nom de la Station : "), filtered_data$name,
          div(class = "map", "Nombre de vélos disponibles : "), filtered_data$totalStands.availabilities.bikes,
          div(class = "map", "Nombre de places disponibles : "), filtered_data$totalStands.availabilities.stands,
          div(class = "map", "Station ouverte ? : "), filtered_data$status
        ),
        clusterOptions = markerClusterOptions()
      )
  })
  
  output$hist <- renderPlot({
    
    # Cette partie génère un histogramme pour la répartition du nombre de places disponibles par station
    # Les données sont filtrées en fonction de la sélection "postcodekpi"
    filtered_data2 <- df
    
    if (!is.null(input$postcodekpi) && "Tous" %in% input$postcodekpi) {
      filtered_data2 <- df
    } else {
      filtered_data2 <- filtered_data2 %>%
        filter(geocode %in% input$postcodekpi)
    }
    
    ggplot(filtered_data2, aes(x = totalStands.capacity)) +
      geom_histogram(binwidth = 5, color = "black", fill = "lightblue", size = 1.2) +
      labs(
        title = "Répartition du nombre de places disponibles par station",
        x = "Nombre de places disponibles",
        y = "Nombre de stations"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(face = "bold", hjust = 0.5, size = 15, margin = margin(b = 30))
      )
  })
  
  output$hist2 <- renderPlot({
    
    # Cette partie génère un autre histogramme pour la répartition du nombre de vélos électriques par station
    # Les données sont à nouveau filtrées en fonction de la sélection "postcodekpi"
    filtered_data2 <- df
    
    if (!is.null(input$postcodekpi) && "Tous" %in% input$postcodekpi) {
      filtered_data2 <- df
    } else {
      filtered_data2 <- filtered_data2 %>%
        filter(geocode %in% input$postcodekpi)
    }
    
    ggplot(filtered_data2, aes(x = totalStands.availabilities.electricalBikes)) +
      geom_histogram(binwidth = 5, color = "red", fill = "lightgreen", size = 1.2) +
      ggtitle("Répartition du nombre de vélos électriques par station") +
      labs(
        x = "Nombre de vélos électriques disponibles",
        y = "Nombre de stations"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(face = "bold", hjust = 0.5, size = 15, margin = margin(b = 30))
      )
  })
  
  
  filtered_data2 <- reactive({
    # Cette partie crée une réactivité pour filtrer les données en fonction de la sélection "postcodekpi"
    # Si "Tous" est sélectionné, les données ne sont pas filtrées
    if ("Tous" %in% input$postcodekpi) {
      filtered_data2 <- df
    } else {
      filtered_data2 <- df %>%
        filter(geocode %in% input$postcodekpi)
    }
  })
  
  output$velos_disponibles <- renderText({
    # Cette partie affiche le nombre total de vélos disponibles
    # Les données sont basées sur la réactivité "filtered_data2"
    sum(filtered_data2()$totalStands.availabilities.bikes)
  })
  
  output$stations_ouvertes <- renderText({
    # Cette partie affiche le nombre de stations ouvertes
    # Les données sont basées sur la réactivité "filtered_data2"
    sum(filtered_data2()$status == "OPEN")
  })
  
  output$stations_banking <- renderText({
    # Cette partie affiche le nombre de stations avec l'option Banking
    # Les données sont basées sur la réactivité "filtered_data2"
    sum(filtered_data2()$banking == TRUE)
  })
  
  output$data <- DT::renderDataTable({
    # Cette partie génère un tableau de données interactif avec les données brutes
    # Les données sont chargées avec la fonction "load_data()"
    # Les options de présentation sont définies, comme le nombre de lignes par page
    datatable(load_data(), 
              options = list(pageLength = 10, scrollX = TRUE))
  })
  
  observe({
    # Filtrer les données en fonction de la sélection de postcodekpi
    filtered_data_kpi <- df
    if (!"Tous" %in% input$postcodekpi) {
      filtered_data_kpi <- filtered_data_kpi %>% filter(geocode %in% input$postcodekpi)
    }

  
  output$exporter <- downloadHandler(
    # Cette partie gère le téléchargement de graphiques combinés
    # Elle crée deux histogrammes, les combine, puis les sauvegarde sous forme d'image
    
    filename = function() {
      "combined_graphs.png" # Nom du fichier de sortie
    },
    content = function(file) {
      png(file, width = 1200, height = 600) # Spécifiez la largeur et la hauteur du graphique
      par(mfrow = c(1, 2)) # Divisez la zone de tracé en 1 ligne et 2 colonnes
      
      # Tracer le premier graphique
      hist_plot_1 <- ggplot(filtered_data_kpi, aes(x = totalStands.capacity)) +
        geom_histogram(binwidth = 5, color = "black", fill = "lightblue", size = 1.2) +
        labs(
          title = "Répartition du nombre de places disponibles par station",
          x = "Nombre de places disponibles",
          y = "Nombre de stations"
        ) +
        theme_minimal() +
        theme(
          plot.title = element_text(
            face = "bold",
            hjust = 0.5,
            size = 15,
            margin = margin(b = 30)
          )
        )
      
      # Tracer le deuxième graphique
      hist_plot_2 <- ggplot(filtered_data_kpi, aes(x = totalStands.availabilities.electricalBikes)) +
        geom_histogram(binwidth = 5, color = "red", fill = "lightgreen", size = 1.2) +
        ggtitle("Répartition du nombre de vélos électriques par station") +
        labs(
          x = "Nombre de vélos électriques disponibles",
          y = "Nombre de stations"
        ) +
        theme_minimal() +
        theme(
          plot.title = element_text(
            face = "bold",
            hjust = 0.5,
            size = 15,
            margin = margin(b = 30)
          )
        )
      
      # Utilisez grid.arrange pour combiner les deux graphiques
      combined_plots <- grid.arrange(hist_plot_1, hist_plot_2, ncol = 2)
      
      print(combined_plots)
      dev.off()
    }
  )
  })
  
  observeEvent(input$refresh, {
    # Cette partie réagit à un événement "refresh" en rechargeant la page Shiny
    shinyjs::js$refresh_page()
  })
  
  selectedPostalCodes <- reactive({
    # Cette partie crée une réactivité pour déterminer les codes postaux sélectionnés
    # Si des codes postaux sont sélectionnés, ils sont renvoyés
    # Sinon, tous les codes postaux uniques du dataframe sont renvoyés
    if (!is.null(input$postcode) && length(input$postcode) > 0) {
      return(input$postcode)
    } else {
      return(unique(df$geocode))
    }
  })
  }
  
  shinyApp(ui,server)