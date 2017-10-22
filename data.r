maarat = read.csv2(file = "data/Helsingin_pyorailijamaarat.csv", stringsAsFactors = FALSE)
saa = read.csv(file = "data/weather_data.csv", stringsAsFactors = FALSE)

saa$LPNN = as.factor(saa$LPNN)
levels(saa$LPNN) = c("Kaisaniemi", "Kumpula")

saa$DATE_TIME = as.Date(x = saa$DATE_TIME, format = "%d.%m.%Y %H:%M")

maarat$Päivämäärä = substr(
  x = maarat$Päivämäärä,
  start = 3,
  stop = length(maarat$Päivämäärä)
)

kuukaudet = c(
  "tammi",
  "helmi",
  "maalis",
  "huhti",
  "touko",
  "kesä",
  "heinä",
  "elo",
  "syys",
  "loka",
  "marras",
  "joulu"
)

for (i in 1:length(kuukaudet)) {
  maarat$Päivämäärä  = gsub(x = maarat$Päivämäärä,
                            pattern = kuukaudet[i],
                            replacement = i)
}

maarat$Päivämäärä = as.Date(x = maarat$Päivämäärä, format = "%d %m %Y %H:%M")

#merged = maarat[, colSums(is.na(maarat)) == 0]
