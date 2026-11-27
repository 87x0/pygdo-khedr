import requests

from gdo.base.GDT import GDT
from gdo.base.Method import Method


class wind(Method):
    """$wind - live wind at the SKF-monitored C-Power / Thornton Bank offshore park (Open-Meteo, CC-BY 4.0)
    plus the calmest day of the coming week (= best maintenance window). Hackathon helper, Team CGX."""

    SITE, LAT, LON = 'Thornton Bank (C-Power, North Sea)', 51.55, 2.95

    @classmethod
    def gdo_trig(cls) -> str:
        return 'wind'

    def gdo_execute(self) -> GDT:
        try:
            r = requests.get('https://api.open-meteo.com/v1/forecast', timeout=15, params={
                'latitude': self.LAT, 'longitude': self.LON, 'wind_speed_unit': 'ms', 'timezone': 'UTC',
                'current': 'wind_speed_10m,wind_gusts_10m,wind_direction_10m,temperature_2m',
                'daily': 'wind_speed_10m_max', 'hourly': 'wind_speed_100m', 'forecast_days': 7})
            r.raise_for_status()
            d = r.json()
        except (requests.RequestException, ValueError) as ex:
            return self.reply('err_khedr_wind', (str(ex)[:120],))
        c = d['current']
        hub = d['hourly']['wind_speed_100m']
        hub_now = hub[min(range(len(hub)), key=lambda i: abs(i - int(c['time'][11:13])))]
        days = d['daily']
        calm_i = min(range(len(days['time'])), key=lambda i: days['wind_speed_10m_max'][i])
        return self.reply('msg_khedr_wind', (
            self.SITE, c['time'][11:16], c['wind_speed_10m'], hub_now, c['wind_gusts_10m'],
            c['wind_direction_10m'], c['temperature_2m'], days['time'][calm_i], days['wind_speed_10m_max'][calm_i]))
