#!/usr/bin/env python3
import datetime
import math
import json
import urllib.request
import sys

LAT = 7.37565
LON = -72.6479
AU_KM = 149597870.7

MOON_PHASES = {
    "New Moon": {"icon": "🌑", "nf": "󰽢", "es": "Luna Nueva"},
    "Waxing Crescent": {"icon": "🌒", "nf": "󰽣", "es": "Luna Creciente"},
    "First Quarter": {"icon": "🌓", "nf": "󰽤", "es": "Cuarto Creciente"},
    "Waxing Gibbous": {"icon": "🌔", "nf": "󰽥", "es": "Gibosa Creciente"},
    "Full Moon": {"icon": "🌕", "nf": "󰽦", "es": "Luna Llena"},
    "Waning Gibbous": {"icon": "🌖", "nf": "󰽧", "es": "Gibosa Menguante"},
    "Last Quarter": {"icon": "🌗", "nf": "󰽨", "es": "Cuarto Menguante"},
    "Waning Crescent": {"icon": "🌘", "nf": "󰽩", "es": "Luna Menguante"}
}

def format_hour(h):
    h = h % 24
    hour = int(h)
    minute = int((h - hour) * 60)
    am_pm = "AM"
    if hour >= 12:
        am_pm = "PM"
    if hour > 12:
        hour -= 12
    if hour == 0:
        hour = 12
    return f"{hour:02d}:{minute:02d} {am_pm}"

def format_dec(deg):
    sign = "+" if deg >= 0 else "-"
    deg = abs(deg)
    d = int(deg)
    m = int((deg - d) * 60)
    s = int(((deg - d) * 60 - m) * 60)
    return f"{sign}{d}° {m:02d}' {s:02d}\""

def get_constellation(lon):
    lon = lon % 360
    if lon < 28.8 or lon >= 351.6: return "Piscis"
    elif lon < 53.5: return "Aries"
    elif lon < 90.2: return "Tauro"
    elif lon < 118.3: return "Géminis"
    elif lon < 137.9: return "Cáncer"
    elif lon < 174.2: return "Leo"
    elif lon < 218.0: return "Virgo"
    elif lon < 241.0: return "Libra"
    elif lon < 248.0: return "Escorpio"
    elif lon < 266.3: return "Ofiuco"
    elif lon < 299.7: return "Sagitario"
    elif lon < 327.9: return "Capricornio"
    else: return "Acuario"

def get_moon_distance_meeus(d):
    T = d / 36525.0
    
    # Meeus formulas (in degrees)
    D = (297.8501921 + 445267.1114034 * T) % 360
    M = (134.9633964 + 477198.8675055 * T) % 360
    M_prime = (357.5291092 + 35999.0502909 * T) % 360
    F = (93.2720950 + 483202.0175233 * T) % 360
    
    # Convert to radians
    D_rad = math.radians(D)
    M_rad = math.radians(M)
    M_prime_rad = math.radians(M_prime)
    F_rad = math.radians(F)
    
    # Main terms for distance in km
    dist = (
        385000.56 
        - 20905.355 * math.cos(M_rad) 
        - 3699.111 * math.cos(2 * D_rad - M_rad) 
        - 2955.968 * math.cos(2 * D_rad) 
        - 569.925 * math.cos(2 * M_rad)
        + 108.74 * math.cos(M_rad + M_prime_rad)
        - 152.138 * math.cos(2 * D_rad - M_rad - M_prime_rad)
        - 48.423 * math.cos(2 * D_rad - M_rad + M_prime_rad)
        - 31.025 * math.cos(2 * F_rad)
    )
    return dist

def get_astronomy_calculation():
    local_now = datetime.datetime.now()
    utc_now = datetime.datetime.now(datetime.timezone.utc)
    tz_offset = (local_now - utc_now.replace(tzinfo=None)).total_seconds() / 3600.0
    
    j2000 = datetime.datetime(2000, 1, 1, 12, 0, 0, tzinfo=datetime.timezone.utc)
    diff = utc_now - j2000
    d = diff.days + diff.seconds / 86400.0
    T = d / 36525.0
    
    # Obliquity of the Ecliptic
    obliq = math.radians(23.4392911 - 0.01300416 * T)
    
    # --- SUN ---
    g = math.radians(357.5291092 + 35999.0502909 * T)
    L = math.radians(280.46646 + 36000.76983 * T)
    lambda_s = L + math.radians(1.914602 * math.sin(g) + 0.020008 * math.sin(2 * g))
    
    # Sun distance in AU and KM (Earth observer to Sun)
    Rs_au = 1.00014 - 0.01671 * math.cos(g) - 0.00014 * math.cos(2 * g)
    Rs_km = Rs_au * AU_KM
    
    # Sun Declination
    sun_dec = math.degrees(math.asin(math.sin(obliq) * math.sin(lambda_s)))
    sun_const = get_constellation(math.degrees(lambda_s))
    
    # --- MOON ---
    D = (297.8501921 + 445267.1114034 * T) % 360
    M = (134.9633964 + 477198.8675055 * T) % 360
    M_prime = (357.5291092 + 35999.0502909 * T) % 360
    F = (93.2720950 + 483202.0175233 * T) % 360
    L_m = (218.3164477 + 481267.8812237 * T) % 360
    
    D_rad = math.radians(D)
    M_rad = math.radians(M)
    M_prime_rad = math.radians(M_prime)
    F_rad = math.radians(F)
    
    # Moon Longitude and Latitude
    lambda_m = L_m + 6.2888 * math.sin(M_rad) + 1.2740 * math.sin(2 * D_rad - M_rad) + 0.6583 * math.sin(2 * D_rad) + 0.2136 * math.sin(2 * M_rad) - 0.1851 * math.sin(M_prime_rad) - 0.1144 * math.sin(2 * F_rad)
    beta_m = 5.1281 * math.sin(F_rad) + 0.2806 * math.sin(M_rad + F_rad) + 0.2777 * math.sin(F_rad - M_rad) - 0.1732 * math.sin(2 * D_rad - F_rad)
    
    beta_rad = math.radians(beta_m)
    lambda_rad = math.radians(lambda_m)
    
    # Moon Declination
    sin_dec_m = math.sin(beta_rad) * math.cos(obliq) + math.cos(beta_rad) * math.sin(obliq) * math.sin(lambda_rad)
    moon_dec = math.degrees(math.asin(sin_dec_m))
    moon_const = get_constellation(lambda_m)
    
    # Earth-Moon distance (Meeus)
    rm_km = get_moon_distance_meeus(d)
    
    # Moon-Sun distance
    moon_sun_km = math.sqrt(Rs_km**2 + rm_km**2 - 2 * Rs_km * rm_km * math.cos(D_rad))
    moon_sun_au = moon_sun_km / AU_KM
    
    return {
        "sun_constellation": sun_const,
        "moon_constellation": moon_const,
        "sun_distance_earth": f"{Rs_au:.4f} UA ({int(Rs_km):,} km)".replace(",", "."),
        "moon_distance_sun": f"{moon_sun_au:.4f} UA ({int(moon_sun_km):,} km)".replace(",", "."),
        "sun_distance_earth_ua": f"{Rs_au:.4f} UA",
        "sun_distance_earth_km": f"{int(Rs_km):,} km".replace(",", "."),
        "moon_distance_sun_ua": f"{moon_sun_au:.4f} UA",
        "moon_distance_sun_km": f"{int(moon_sun_km):,} km".replace(",", "."),
        "sun_declination": format_dec(sun_dec),
        "moon_declination": format_dec(moon_dec)
    }

def get_astronomy_data():
    local_now = datetime.datetime.now()
    utc_now = datetime.datetime.now(datetime.timezone.utc)
    tz_offset = (local_now - utc_now.replace(tzinfo=None)).total_seconds() / 3600.0
    
    j2000 = datetime.datetime(2000, 1, 1, 12, 0, 0, tzinfo=datetime.timezone.utc)
    diff = utc_now - j2000
    d = diff.days + diff.seconds / 86400.0
    
    # Base local calculations
    calc = get_astronomy_calculation()
    
    # Try fetching online for rising/setting times (wttr.in)
    try:
        url = f"http://wttr.in/{LAT},{LON}?format=j1"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            res_data = json.loads(response.read().decode('utf-8'))
            astronomy = res_data["weather"][0]["astronomy"][0]
            
            phase_en = astronomy["moon_phase"]
            illum = astronomy["moon_illumination"]
            phase_meta = MOON_PHASES.get(phase_en, MOON_PHASES["New Moon"])
            
            sunrise_str = astronomy["sunrise"]
            sunset_str = astronomy["sunset"]
            moonrise_str = astronomy["moonrise"]
            moonset_str = astronomy["moonset"]
            
            def parse_time(t_str):
                try:
                    dt = datetime.datetime.strptime(t_str.strip(), "%I:%M %p")
                    return dt.hour + dt.minute / 60.0
                except:
                    return 12.0
            
            sr = parse_time(sunrise_str)
            ss = parse_time(sunset_str)
            sun_transit = (sr + ss) / 2.0
            
            mr = parse_time(moonrise_str)
            ms = parse_time(moonset_str)
            if mr > ms:
                moon_transit = ((mr + ms + 24) / 2.0) % 24
            else:
                moon_transit = (mr + ms) / 2.0
                
            calc.update({
                "phase_name_en": phase_en,
                "phase_name_es": phase_meta["es"],
                "illumination": f"{illum}%",
                "moon_icon": phase_meta["icon"],
                "moon_nf_icon": phase_meta["nf"],
                "moonrise": sunrise_str if "No moonrise" in moonrise_str else moonrise_str,
                "moonset": sunset_str if "No moonset" in moonset_str else moonset_str,
                "moon_transit": format_hour(moon_transit),
                "sunrise": sunrise_str,
                "sunset": sunset_str,
                "sun_transit": format_hour(sun_transit),
                "distance": f"{int(get_moon_distance_meeus(d)):,} km".replace(",", ".")
            })
            return calc
    except Exception as e:
        # Fallback offline rising/setting
        # age & phase
        age = (d - 5.14) % 29.530588853
        phase_pct = age / 29.530588853
        illum = 50 * (1 - math.cos(2 * math.pi * phase_pct))
        
        # Sun times from calculated angles
        phi = math.radians(LAT)
        g = math.radians(357.528 + 0.9856003 * d)
        
        # Sun transit
        # Obliquity
        obliq = math.radians(23.4392911 - 0.01300416 * T)
        lambda_s = math.radians(280.46646 + 36000.76983 * T)
        sun_dec_val = math.asin(math.sin(obliq) * math.sin(lambda_s))
        
        # Transit local (halfway)
        transit_local = 11.92
        cos_H0 = (math.sin(math.radians(-0.833)) - math.sin(phi) * math.sin(sun_dec_val)) / (math.cos(phi) * math.cos(sun_dec_val))
        
        sunrise_local = 5.66
        sunset_local = 18.19
        if -1.0 <= cos_H0 <= 1.0:
            H0 = math.degrees(math.acos(cos_H0))
            h_diff = H0 / 15.0
            sunrise_local = (transit_local - h_diff) % 24
            sunset_local = (transit_local + h_diff) % 24
            
        # Determine phase name
        if phase_pct < 0.03 or phase_pct >= 0.97:
            phase_en = "New Moon"
        elif phase_pct < 0.22:
            phase_en = "Waxing Crescent"
        elif phase_pct < 0.28:
            phase_en = "First Quarter"
        elif phase_pct < 0.47:
            phase_en = "Waxing Gibbous"
        elif phase_pct < 0.53:
            phase_en = "Full Moon"
        elif phase_pct < 0.72:
            phase_en = "Waning Gibbous"
        elif phase_pct < 0.78:
            phase_en = "Last Quarter"
        else:
            phase_en = "Waning Crescent"
            
        phase_meta = MOON_PHASES[phase_en]
        
        moonrise_local = (sunrise_local + age * (24.0 / 29.53)) % 24
        moonset_local = (moonrise_local + 12.0) % 24
        moon_transit_local = (moonrise_local + 6.0) % 24
        
        calc.update({
            "phase_name_en": phase_en,
            "phase_name_es": phase_meta["es"],
            "illumination": f"{int(illum)}%",
            "moon_icon": phase_meta["icon"],
            "moon_nf_icon": phase_meta["nf"],
            "moonrise": format_hour(moonrise_local),
            "moonset": format_hour(moonset_local),
            "moon_transit": format_hour(moon_transit_local),
            "sunrise": format_hour(sunrise_local),
            "sunset": format_hour(sunset_local),
            "sun_transit": format_hour(transit_local),
            "distance": f"{int(get_moon_distance_meeus(d)):,} km".replace(",", ".")
        })
        return calc

if __name__ == "__main__":
    data = get_astronomy_data()
    print(json.dumps(data))
