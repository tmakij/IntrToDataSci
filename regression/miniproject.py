import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime

# some data already altered with R and partly manually
cyclistdata = pd.read_csv("data/cyclists.csv")
weatherdata = pd.read_csv("data/weather.csv")

# modify date format
weatherdata['DATE_TIME'] = weatherdata['DATE_TIME'] + "T" + weatherdata['HOUR']

weatherdata['DATE_TIME'] = pd.to_datetime(weatherdata['DATE_TIME'])

# filter out kumpula weather
weatherdata = weatherdata[(weatherdata['LPNN'] == 'Kaisaniemi')]

# Remove useless weather columns
weather_values_to_remove = ["P_SEA_AVG", "ID", "YEAR","MONTH", "DAY","HOUR"]
for val in weather_values_to_remove:
    del weatherdata[val]

fromValues = ['tammi','helmi','maalis','huhti','touko','kesa','heina','elo','syys','loka','marras','joulu']

toValues = ["01","02","03","04","05","06","07","08","09","10","11","12"]

# re-format dates
cyclistdata['date'] = cyclistdata['date'].str.replace('tammi','01')
cyclistdata['date'] = cyclistdata['date'].str.replace('helmi','02')
cyclistdata['date'] = cyclistdata['date'].str.replace('maalis','03')
cyclistdata['date'] = cyclistdata['date'].str.replace('huhti','04')
cyclistdata['date'] = cyclistdata['date'].str.replace('touko','05')
cyclistdata['date'] = cyclistdata['date'].str.replace('kesa','06')
cyclistdata['date'] = cyclistdata['date'].str.replace('heina','07')
cyclistdata['date'] = cyclistdata['date'].str.replace('elo','08')
cyclistdata['date'] = cyclistdata['date'].str.replace('syys','09')
cyclistdata['date'] = cyclistdata['date'].str.replace('loka','10')
cyclistdata['date'] = cyclistdata['date'].str.replace('marras','11')
cyclistdata['date'] = cyclistdata['date'].str.replace('joulu','12')
cyclistdata['date'] = cyclistdata['date'].map(lambda x: str(x)[3:])
cyclistdata['date'] = cyclistdata['date'].map(lambda x: str(x)[6:10] + "-" + str(x)[3:5] + "-" + str(x)[:2] + "T" + str(x)[11:16])

cyclistdata['date'] = pd.to_datetime(cyclistdata['date'])

cyclistdata.rename(columns={'date': 'DATE_TIME'}, inplace=True)

# combine cyclistdata with weatherdata
combined = pd.merge(weatherdata, cyclistdata, on='DATE_TIME')
#combined['DATE_TIME'] = pd.to_datetime(combined['DATE_TIME'])

# set index as datetimeindex
#combined = combined.set_index(pd.DatetimeIndex(combined['DATE_TIME']))

# filter by hour of day
morningdata = combined[(combined['DATE_TIME'].dt.hour >= 6) & (combined['DATE_TIME'].dt.hour <= 12)]
afternoondata = combined[(combined['DATE_TIME'].dt.hour > 12) & (combined['DATE_TIME'].dt.hour < 18)]
eveningdata = combined[(combined['DATE_TIME'].dt.hour >= 18) & (combined['DATE_TIME'].dt.hour <= 23)]
nightdata = combined[(combined['DATE_TIME'].dt.hour >= 0) & (combined['DATE_TIME'].dt.hour <= 5)]

#RH_AVG: mean relative humidity during the previous hour [%]
#- T_AVG: mean temperature during the previous hour [C]
#- T_MIN: min temperature during the previous hour [C]
#- T_MAX: max temperature during the previous hour [C]
#- WD_AVG: average wind direction during the previous hour [deg 1-360, no wind = 0]
#- WG_MAX: max 3 seconds gust wind speed during the previous hour [m/s]
#- WS_AVG: mean wind speed during the previous hour [m/s]
#- WS_MAX: max 10 minutes wind speed during the previous hour [m/s]
#- SUN_DUR_U: Sunshine duration during the previous hour [h]
#- RI_MAX: max intensity of precipitation during the previous hour [mm/h]
#- R_1H: precipitation sum during the previous hour [mm, no rain = -1]
#- WD_AVG_DIR: WD_AVG divided to 8 sectors (N, NE, E, SE, S, SW, W, NW)

def createGraph(data, key, title, xlabel, filename):
    data_baana = data.groupby(key)['Baana'].mean()
    data_espa = data.groupby(key)['Etelaesplanadi'].mean()
    
    f = plt.figure(figsize=(10, 7))
    plt.title(title)
    plt.plot(data_baana, label="Baana")
    plt.plot(data_espa, label="Etelä-esplanadi");
    plt.legend()
    plt.ylabel('Amount of bikers')
    plt.xlabel(xlabel)
    plt.show()
    f.savefig(filename)

def createTimeOfDayGraphs(key, title, xlabel, filename):
    createGraph(combined, key, title + ' (TOTAL)', xlabel, 'total_' + filename)
    createGraph(morningdata, key, title + ' (MORNING)', xlabel, 'morning_' + filename)
    createGraph(afternoondata, key, title + ' (AFTERNOON)', xlabel, 'afternoon_' + filename)
    createGraph(eveningdata, key, title + ' (EVENING)', xlabel, 'evening_' + filename)
    createGraph(nightdata, key, title + ' (NIGHT)', xlabel, 'night_' + filename)
    
createTimeOfDayGraphs('T_AVG', 'Amount of bikers relative to mean temperature \n during the previous hour', 'Temperature Celcius', 'temperature.png')
createTimeOfDayGraphs('WD_AVG', 'Amount of bikers relative to average wind direction\n during the previous hour', 'Wind direction [deg 1-360, no wind = 0]', 'wind_direction.png')
createTimeOfDayGraphs('WS_AVG', 'Amount of bikers relative to mean wind speed\n during the previous hour [m/s]', 'Wind speed m/s', 'wind_speed.png')
createTimeOfDayGraphs('R_1H', 'Amount of bikers relative to precipitation sum\n during the previous hour', 'Precipitation sum [mm, no rain = -1]', 'rainfall.png')

##############################################################
