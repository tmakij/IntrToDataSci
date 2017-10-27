#Intoduction to Data Science - Mini Project
library(RODBC)
library(RODM)
library(tidyverse)
library(extRemes)
library(stringr)
library(lubridate)
library(modelr)
library(MASS)

setwd("D:/Kurssit/Intro_Data_Sci/MiniProject")

con <- odbcConnect("ilmastotietokanta", uid = "LAAPAS_MIKKO",
                   pwd = "*****", believeNRows=FALSE)


hourly_weather_qc <- sqlQuery(con,paste0("SELECT LPNN, to_number(to_char(OBSTIME, 'YYYY')) YEAR,to_number(to_char(OBSTIME, 'MM')) MONTH, to_number(to_char(OBSTIME,'DD')) DAY, to_char(OBSTIME,'HH24:MI') HOUR, to_char(OBSTIME,'DD.MM.YYYY HH24:MI') DATE_TIME, P_SEA_AVG, RH_AVG, T_AVG, T_MIN, T_MAX, WD_AVG, WG_MAX, WS_AVG, WS_MAX
                            FROM HOURLY_WEATHER_QC
                           WHERE LPNN in (304,339) and OBSTIME between to_date('01.01.2014 00:00','DD.MM.YYYY HH24:MI') and to_date('31.12.2016 23:59','DD.MM.YYYY HH24:MI')
                           ORDER by OBSTIME"))

hrad_qc <- sqlQuery(con,paste0("SELECT LPNN, to_number(to_char(OBSTIME, 'YYYY')) YEAR,to_number(to_char(OBSTIME, 'MM')) MONTH, to_number(to_char(OBSTIME,'DD')) DAY, to_char(OBSTIME,'HH24:MI') HOUR, to_char(OBSTIME,'DD.MM.YYYY HH24:MI') DATE_TIME, SUN_DUR_U
                            FROM HRAD_QC
                           WHERE LPNN in (304,339) and OBSTIME between to_date('01.01.2014 00:00','DD.MM.YYYY HH24:MI') and to_date('31.12.2016 23:59','DD.MM.YYYY HH24:MI')
                           ORDER by OBSTIME"))

prec_qc <- sqlQuery(con,paste0("SELECT LPNN, to_number(to_char(OBSTIME, 'YYYY')) YEAR,to_number(to_char(OBSTIME, 'MM')) MONTH, to_number(to_char(OBSTIME,'DD')) DAY, to_char(OBSTIME,'HH24:MI') HOUR, to_char(OBSTIME,'DD.MM.YYYY HH24:MI') DATE_TIME, RI_MAX, R_1H
                            FROM PREC_QC
                               WHERE GAUGE=50 and LPNN in (304,339) and OBSTIME between to_date('01.01.2014 00:00','DD.MM.YYYY HH24:MI') and to_date('31.12.2016 23:59','DD.MM.YYYY HH24:MI')
                               ORDER by OBSTIME"))

weather_data <- hourly_weather_qc %>% left_join(hrad_qc,by =c("LPNN","YEAR","MONTH","DAY","HOUR","DATE_TIME"))
weather_data <- weather_data %>% left_join(prec_qc,by =c("LPNN","YEAR","MONTH","DAY","HOUR","DATE_TIME"))

#WD divided to  8 wind directions N,NE,E jne.
weather_data <- weather_data %>%
   mutate(WD_AVG_DIR=ifelse(WD_AVG >= 338 | WD_AVG < 23,"N",
                     ifelse(WD_AVG >= 23 & WD_AVG < 68,"NE",
                            ifelse(WD_AVG >= 68 & WD_AVG < 113,"E",
                                   ifelse(WD_AVG >= 113 & WD_AVG < 158,"SE",
                                          ifelse(WD_AVG >= 158 & WD_AVG < 203,"S",
                                                 ifelse(WD_AVG >= 203 & WD_AVG < 248,"SW",
                                                        ifelse(WD_AVG >= 248 & WD_AVG < 293,"W",
                                                               ifelse(WD_AVG >= 293 & WD_AVG < 338,"NW",NA)))))))))


write_csv(weather_data,"weather_data.csv")

# read bicycle data
bicycles <- read_csv2("Helsingin_pyorailijamaarat_V2.csv")

#Vain mittauspisteet miss? kattavasti 2014-2016.
bicycles <- select(bicycles,Time,Kaisaniemi,Munkkiniemen_silta_etel,Munkkiniemen_silta_pohj,Hesperian_puisto,Pitkasilta_lansi,Etelaesplanadi,Baana)

bicycles$Time = substr(
   x = bicycles$Time,
   start = 3,
   stop = length(bicycles$Time)
)

kuukaudet = c(
   "tammi",
   "helmi",
   "maalis",
   "huhti",
   "touko",
   "kes?",
   "hein?",
   "elo",
   "syys",
   "loka",
   "marras",
   "joulu"
)

for (i in 1:length(kuukaudet)) {
   bicycles$Time  = gsub(x = bicycles$Time,
                             pattern = kuukaudet[i],
                             replacement = i)
}

saa <- read_csv("weather_data.csv")

bicycles$DATE_TIME = dmy_hm(bicycles$Time)
saa$DATE_TIME = dmy_hm(saa$DATE_TIME)


kaisaniemi <- filter(saa,LPNN==304)
kaisaniemi <- kaisaniemi %>% left_join(bicycles,by="DATE_TIME")
kaisaniemi <- select(kaisaniemi,-SUN_DUR_U,-Time)

#yhdistet??n Munkkiniemen sillan molemmat puolet
kaisaniemi <- mutate(kaisaniemi,Munkkiniemen_silta=Munkkiniemen_silta_etel+Munkkiniemen_silta_pohj)

#Muutetaan sateen -1 (ei sadetta) nollaksi niin se ei sotke p?iv?- ja kuukausiarvoja
kaisaniemi$R_1H[kaisaniemi$R_1H < 0] <- 0

kaisaniemi_long<- gather(kaisaniemi,
                         key = obs_point,
                         value = sum,
                         Kaisaniemi,
                         Munkkiniemen_silta,
                         Hesperian_puisto,
                         Pitkasilta_lansi,
                         Etelaesplanadi,
                         Baana)

#Daily and monthly aggregates
kaisaniemi_monthly <- kaisaniemi %>%
   group_by(YEAR,MONTH) %>%
   summarise(T_AVG = mean(T_AVG, na.rm = T),
             R_SUM = sum(R_1H, na.rm = T),
             WS_AVG = mean(WS_AVG, na.rm = T),
             Kaisaniemi = sum(Kaisaniemi, na.rm = T),
             Munkkiniemen_silta = sum(Munkkiniemen_silta,na.rm = T),
             Hesperian_puisto = sum(Hesperian_puisto,na.rm = T),
             Pitkasilta_lansi = sum(Pitkasilta_lansi,na.rm = T),
             Etelaesplanadi = sum(Etelaesplanadi,na.rm = T),
             Baana = sum(Baana,na.rm = T))

kaisaniemi_monthly <- transform(kaisaniemi_monthly, DATE = as.Date(paste(YEAR, MONTH, 1, sep = "-")))

kaisaniemi_mon_long <- gather(kaisaniemi_monthly,
                              key = obs_point,
                              value = sum,
                              Kaisaniemi,
                              Munkkiniemen_silta,
                              Hesperian_puisto,
                              Pitkasilta_lansi,
                              Etelaesplanadi,
                              Baana)

ggplot(data=kaisaniemi_mon_long)+
   geom_col(aes(x=DATE,y=sum))+
   facet_wrap(~ obs_point,ncol=1)+theme_bw()+ylim(0,150000)+
   labs(title="2014-2016 monthly amount of cyclists at six observation points in Helsinki",x="Time",y="Amount of cyclists")
ggsave("monthly_amoun_of_cyclists_facet.png")


kaisaniemi_daily <- kaisaniemi %>%
   group_by(YEAR,MONTH,DAY) %>%
   summarise(T_AVG = mean(T_AVG, na.rm = T),
             R_SUM = sum(R_1H, na.rm = T),
             WS_AVG = mean(WS_AVG, na.rm = T),
             WG_MAX = max(WG_MAX, na.rm = T),
             Kaisaniemi = sum(Kaisaniemi, na.rm = T),
             Munkkiniemen_silta = sum(Munkkiniemen_silta,na.rm = T),
             Hesperian_puisto = sum(Hesperian_puisto,na.rm = T),
             Pitkasilta_lansi = sum(Pitkasilta_lansi,na.rm = T),
             Etelaesplanadi = sum(Etelaesplanadi,na.rm = T),
             Baana = sum(Baana,na.rm = T))

kaisaniemi_daily <- transform(kaisaniemi_daily, DATE = as.Date(paste(YEAR, MONTH, DAY, sep = "-")))

kaisaniemi_daily_long <- gather(kaisaniemi_daily,
                              key = obs_point,
                              value = sum,
                              Kaisaniemi,
                              Munkkiniemen_silta,
                              Hesperian_puisto,
                              Pitkasilta_lansi,
                              Etelaesplanadi,
                              Baana)

kaisaniemi_daily_long_2016 <- filter(kaisaniemi_daily_long, YEAR == 2016)

ggplot(data=kaisaniemi_daily_long_2016)+
   geom_col(aes(x=DATE,y=sum))+
   facet_wrap(~ obs_point,ncol=1)+theme_bw()+ylim(0,8000)+
   labs(title="2016 daily amount of cyclists at six observation points in Helsinki",x="Time",y="Amount of cyclists")
ggsave("2016_daily_amount_of_cyclists_facet.png")

kaisaniemi_june_2016 <- filter(kaisaniemi,YEAR == 2016 & MONTH == 6)

kaisaniemi_june_2016_long <- gather(kaisaniemi_june_2016,
                                key = obs_point,
                                value = sum,
                                Kaisaniemi,
                                Munkkiniemen_silta,
                                Hesperian_puisto,
                                Pitkasilta_lansi,
                                Etelaesplanadi,
                                Baana)

ggplot(data=kaisaniemi_june_2016_long)+
   geom_col(aes(x=DATE_TIME,y=sum))+
   facet_wrap(~ obs_point,ncol=1)+theme_bw()+ylim(0,1000)+
   labs(title="June 2016 hourly amount of cyclists at six observation points in Helsinki",x="Time",y="Amount of cyclists")
ggsave("june_2016_hourly_amount_of_cyclists_facet.png")

ggplot(kaisaniemi_daily_long, aes(T_AVG, sum)) +
   geom_point(alpha=0.1)+
   geom_smooth(se=T,color="black",size=1)+theme_bw()+
   labs(title="2014-2016 daily amount of cyclists vs. daily mean temperature", y="Amount of cyclists", x="Daily mean temperature [C]")+
   facet_wrap(~obs_point)+geom_vline(xintercept = c(0,10,20),linetype="dashed")
ggsave("daily_temp_vs_cyclists.png")

ggplot(kaisaniemi_daily_long, aes(WS_AVG, sum)) +
   geom_point(alpha=0.1)+
   geom_smooth(se=T,color="black",size=1)+theme_bw()+
   labs(title="2014-2016 daily amount of cyclists vs. daily mean wind speed", y="Amount of cyclists", x="Daily mean wind speed [m/s]")+
   facet_wrap(~obs_point)
ggsave("daily_wind_vs_cyclists.png")

ggplot(kaisaniemi_daily_long, aes(R_SUM, sum)) +
   geom_point(alpha=0.1)+
   geom_smooth(se=T,color="black",size=1,method="loess")+theme_bw()+xlim(0,10)+
   labs(title="2014-2016 daily amount of cyclists vs. daily precipitation sum", y="Amount of cyclists", x="Daily precipitation sum [mm]")+
   facet_wrap(~obs_point)
ggsave("daily_prec_vs_cyclists.png")

######## monthly
ggplot(kaisaniemi_mon_long, aes(T_AVG, sum)) +
   geom_point()+
   geom_smooth(se=T,color="black",size=1)+theme_bw()+
   labs(title="2014-2016 monthly amount of cyclists vs. monthly mean temperature", y="Amount of cyclists", x="Monthly mean temperature [C]")+
   facet_wrap(~obs_point)
ggsave("monthly_temp_vs_cyclists.png")

ggplot(kaisaniemi_mon_long, aes(WS_AVG, sum)) +
   geom_point()+
   geom_smooth(se=T,color="black",size=1)+theme_bw()+
   labs(title="2014-2016 monthly amount of cyclists vs. monthly mean wind speed", y="Amount of cyclists", x="Monthly mean wind speed [m/s]")+
   facet_wrap(~obs_point)
ggsave("monthly_wind_vs_cyclists.png")

ggplot(kaisaniemi_mon_long, aes(R_SUM, sum)) +
   geom_point()+
   geom_smooth(se=T,color="black",size=1)+theme_bw()+
   labs(title="2014-2016 monthly amount of cyclists vs. monthly precipitation sum", y="Amount of cyclists", x="Monthly precipitation sum [mm]")+
   facet_wrap(~obs_point)
ggsave("monthly_prec_vs_cyclists.png")

#hourly
ggplot(kaisaniemi_long, aes(HOUR, sum)) +
   geom_point(alpha=0.01)+
   geom_smooth(se=T,color="black",size=1)+theme_bw()+
   labs(title="2014-2016 monthly amount of cyclists vs. monthly mean temperature", y="Amount of cyclists", x="Monthly mean temperature [C]")+
   facet_wrap(~obs_point)
ggsave("monthly_temp_vs_cyclists.png")

ggplot(kaisaniemi_mon_long, aes(WS_AVG, sum)) +
   geom_point()+
   geom_smooth(se=T,color="black",size=1)+theme_bw()+
   labs(title="2014-2016 monthly amount of cyclists vs. monthly mean wind speed", y="Amount of cyclists", x="Monthly mean wind speed [m/s]")+
   facet_wrap(~obs_point)
ggsave("monthly_wind_vs_cyclists.png")

ggplot(kaisaniemi_mon_long, aes(R_SUM, sum)) +
   geom_point()+
   geom_smooth(se=T,color="black",size=1)+theme_bw()+
   labs(title="2014-2016 monthly amount of cyclists vs. monthly precipitation sum", y="Amount of cyclists", x="Monthly precipitation sum [mm]")+
   facet_wrap(~obs_point)
ggsave("monthly_prec_vs_cyclists.png")

ggplot(kaisaniemi_long, aes(HOUR, sum)) +
   geom_point()+
   geom_smooth(se=T,color="black",size=1)+theme_bw()+
   labs(title="2014-2016 monthly amount of cyclists vs. monthly mean temperature", y="Amount of cyclists", x="Monthly mean temperature [C]")+
   facet_wrap(~obs_point)
ggsave("monthly_temp_vs_cyclists.png")


# MODEL
#Baana
baana <- filter(kaisaniemi_daily_long,obs_point == "Baana")

ggplot(baana,aes(DATE,sum))+geom_point()+theme_bw()

#correlations between cyclists and some weather variables,
#In this sense only temperature have somewhat meaningfull correlation
round(cor(baana$T_AVG,baana$sum),2) # 0.73
round(cor(baana$R_SUM,baana$sum),2) # -0.11
round(cor(baana$WS_AVG,baana$sum),2) # -0.25

#week days
baana <- baana %>%
   mutate(wday = wday(DATE, label = TRUE))

ggplot(baana, aes(T_AVG, sum)) +
   geom_point()+theme_bw()

#Linear model sum ~ T_AVG
lm_temp <- lm(sum ~ T_AVG, data = baana)
summary(lm_temp)

grid <- baana %>%
   data_grid(T_AVG) %>%
   add_predictions(lm_temp, "sum")

ggplot(baana, aes(T_AVG, sum)) +
   geom_point() +
   geom_point(data = grid, colour = "red", size = 4)



#--------------------------
#non-linear least squares: temp
nls_temp <- nls(sum ~ exp(a + b * T_AVG), data = baana, start = list(a = 1, b = 1))
summary(nls_temp)

# add fitted curve: temp
grid_nls_temp <- baana %>% data_grid(T_AVG) %>% add_predictions(nls_temp)

ggplot(baana, aes(T_AVG, sum)) +
   geom_point()+
   geom_point(data = grid_nls_temp,aes(T_AVG,pred), colour = "red", size = 3)


#loess fitting with different variables

# sum ~ temp + wind + prec: variability and seasonal cycle too small
mod_loess <- loess(sum ~ T_AVG + WS_AVG + R_SUM, data = baana)
summary(mod_loess)

# sum ~ temp + wind + prec + wday: better, but still overestimates winter and underestimates summer
mod_loess2<- loess(sum ~ T_AVG + as.numeric(wday) + WS_AVG + R_SUM, data = baana)
summary(mod_loess2)

# loess takes only max 4 predictors, so let's change prec (lowest correlated) to month of year
mod_loess3<- loess(sum ~ T_AVG + as.numeric(wday) + WS_AVG + MONTH, data = baana)
summary(mod_loess3)

# fit a loess line
plot(sum ~ DATE, baana)
lines(baana$DATE, predict(mod_loess), col = "red")
lines(baana$DATE, predict(mod_loess2), col = "blue")
lines(baana$DATE, predict(mod_loess3), col = "green")

# Now correlation of observed and predicted cyclists is up to 0.89, but therre's still something going on during winter

cor(baana$sum,predict(mod_loess))
cor(baana$sum,predict(mod_loess2))
cor(baana$sum,predict(mod_loess3))


#Other observation points
kaisa <- filter(kaisaniemi_daily_long,obs_point == "Kaisaniemi")
munkkiniemi <- filter(kaisaniemi_daily_long,obs_point == "Munkkiniemen_silta")
hesperia <- filter(kaisaniemi_daily_long,obs_point == "Hesperian_puisto")
pitkasilta <- filter(kaisaniemi_daily_long,obs_point == "Pitkasilta_lansi")
espa <- filter(kaisaniemi_daily_long,obs_point == "Etelaesplanadi")

baana <- baana %>%
   mutate(wday = wday(DATE, label = TRUE))
kaisa <- kaisa %>%
   mutate(wday = wday(DATE, label = TRUE))
munkkiniemi <- munkkiniemi %>%
   mutate(wday = wday(DATE, label = TRUE))
hesperia <- hesperia %>%
   mutate(wday = wday(DATE, label = TRUE))
pitkasilta <- pitkasilta %>%
   mutate(wday = wday(DATE, label = TRUE))
espa <- espa %>%
   mutate(wday = wday(DATE, label = TRUE))
