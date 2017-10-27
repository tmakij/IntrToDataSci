maarat = read.csv2(file = "data/Helsingin_pyorailijamaarat.csv", stringsAsFactors = FALSE)
saa = read.csv(file = "data/weather_data.csv", stringsAsFactors = FALSE)

saa$LPNN = as.factor(saa$LPNN)
levels(saa$LPNN) = c("Kaisaniemi", "Kumpula")

saa$DATE_TIME = as.Date(x = saa$DATE_TIME, format = "%d.%m.%Y %H:%M")
saa$date = saa$DATE_TIME

maarat$Päivämäärä     = substr(
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
  maarat$Päivämäärä      = gsub(x = maarat$Päivämäärä,
                                pattern = kuukaudet[i],
                                replacement = i)
}

maarat$Päivämäärä  = as.Date(x = maarat$Päivämäärä, format = "%d %m %Y %H:%M")
maarat$date = maarat$Päivämäärä

baanaData = data.frame(cyc = maarat$Baana)
#baanaData$cyc = maarat$Baana
baanaData$date = maarat$Päivämäärä

#setDT(saa)
#setDT(baanaData)

# for (i in 1:nrow(baanaData)) {
#
# }

library(dplyr)
merged = left_join(baanaData, saa, by = c("date"))
merged = merged[merged$LPNN == "Kumpula",]
#merged = baanaData[saa, on = c('date')]
#merge(x= baanaData, y= saa, by= 'date', all.x= TRUE)
loess(cyc ~ T_AVG + WS_AVG + R_1H + MONTH, data = merged)
# merged$HOUR = as.numeric(substring(merged$HOUR, 0, 2))
# lmfit = lm(formula = cyc ~ T_AVG + WS_AVG + R_1H + DAY + MONTH + HOUR, data = merged)
# lm_temp <- lm(cyc ~ T_AVG, data = merged)
# summary(lm_temp)
# summary(lmfit)
#cor(merged$cyc, predict(lmfit))

#merged = maarat[, colSums(is.na(maarat)) == 0]
