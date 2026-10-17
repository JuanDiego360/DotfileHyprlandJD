#!/usr/bin/env python3
import datetime
import math
import json
import urllib.request
import sys

LAT = 7.37565
LON = -72.6479
AU_KM = 149597870.7
phi = math.radians(LAT)

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

PLANET_ELEMENTS = {
    "Mercurio": {
        "a": 0.387098, "e": 0.205630, "I": 7.0049, "Omega": 48.33167, "omega": 29.124, 
        "M0": 174.796, "n": 4.0923344, "color": "#a6adc8"
    },
    "Venus": {
        "a": 0.723332, "e": 0.006773, "I": 3.3947, "Omega": 76.68069, "omega": 54.891, 
        "M0": 50.115, "n": 1.6021302, "color": "#f9e2af"
    },
    "Marte": {
        "a": 1.523662, "e": 0.093412, "I": 1.8506, "Omega": 49.57854, "omega": 286.537, 
        "M0": 19.388, "n": 0.5240207, "color": "#f38ba8"
    },
    "Júpiter": {
        "a": 5.203363, "e": 0.048393, "I": 1.3053, "Omega": 100.55615, "omega": 275.066, 
        "M0": 19.895, "n": 0.0830853, "color": "#cba6f7"
    },
    "Saturno": {
        "a": 9.537070, "e": 0.054150, "I": 2.4845, "Omega": 113.71504, "omega": 18.269, 
        "M0": 316.967, "n": 0.0334442, "color": "#fab387"
    }
}

def format_hour(h):
    h = h % 24
    hour = int(h)
    minute = int((h - hour) * 60)
    return f"{hour:02d}:{minute:02d}"

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

def get_planetary_data(d, T, obliq, x_earth, y_earth, lst_hours, local_hour):
    planets = []
    dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N"]
    
    for name, el in PLANET_ELEMENTS.items():
        a = el["a"]
        e = el["e"]
        I = math.radians(el["I"])
        Omega = math.radians(el["Omega"])
        omega = math.radians(el["omega"])
        M0 = math.radians(el["M0"])
        n = math.radians(el["n"])
        
        M = (M0 + n * d) % (2 * math.pi)
        
        # Kepler Solve
        E = M
        for _ in range(5):
            E = E - (E - e * math.sin(E) - M) / (1 - e * math.cos(E))
            
        x_orb = a * (math.cos(E) - e)
        y_orb = a * math.sqrt(1 - e**2) * math.sin(E)
        
        x_hel = x_orb * (math.cos(omega)*math.cos(Omega) - math.sin(omega)*math.sin(Omega)*math.cos(I)) - y_orb * (math.sin(omega)*math.cos(Omega) + math.cos(omega)*math.sin(Omega)*math.cos(I))
        y_hel = x_orb * (math.cos(omega)*math.sin(Omega) + math.sin(omega)*math.cos(Omega)*math.cos(I)) - y_orb * (math.sin(omega)*math.sin(Omega) - math.cos(omega)*math.cos(Omega)*math.cos(I))
        z_hel = x_orb * math.sin(omega)*math.sin(I) + y_orb * math.cos(omega)*math.sin(I)
        
        x_geo = x_hel - x_earth
        y_geo = y_hel - y_earth
        z_geo = z_hel
        
        x_eq = x_geo
        y_eq = y_geo * math.cos(obliq) - z_geo * math.sin(obliq)
        z_eq = y_geo * math.sin(obliq) + z_geo * math.cos(obliq)
        
        ra = math.atan2(y_eq, x_eq)
        dec = math.atan2(z_eq, math.sqrt(x_eq**2 + y_eq**2))
        
        ra_hours = (math.degrees(ra) % 360) / 15.0
        dec_deg = math.degrees(dec)
        
        H = (lst_hours - ra_hours) % 24
        H_rad = math.radians(H * 15.0)
        
        sin_alt = math.sin(phi)*math.sin(dec) + math.cos(phi)*math.cos(dec)*math.cos(H_rad)
        alt = math.asin(sin_alt)
        alt_deg = math.degrees(alt)
        
        cos_az_num = math.sin(dec)*math.cos(phi) - math.cos(dec)*math.sin(phi)*math.cos(H_rad)
        sin_az_num = -math.sin(H_rad)*math.cos(dec)
        az = math.atan2(sin_az_num, cos_az_num)
        az_deg = math.degrees(az) % 360
        
        # 16-wind compass
        dir_idx = int((az_deg + 11.25) / 22.5) % 16
        direction = dirs[dir_idx]
        
        # Rise/Set
        cos_H0 = (math.sin(math.radians(-0.567)) - math.sin(phi)*math.sin(dec)) / (math.cos(phi)*math.cos(dec))
        if -1.0 <= cos_H0 <= 1.0:
            H0 = math.degrees(math.acos(cos_H0)) / 15.0
            transit_local = (local_hour - H) % 24
            rise_local = (transit_local - H0) % 24
            set_local = (transit_local + H0) % 24
            rise_str = format_hour(rise_local)
            set_str = format_hour(set_local)
        else:
            if cos_H0 < -1.0:
                rise_str = "Circumpolar"
                set_str = "No se pone"
            else:
                rise_str = "No sale"
                set_str = "No sale"
                
        visible = alt_deg > 0
        
        planets.append({
            "name": name,
            "alt": f"{alt_deg:.1f}°",
            "az": f"{az_deg:.0f}° ({direction})",
            "rise": rise_str,
            "set": set_str,
            "visible": "Sí" if visible else "No",
            "color": el["color"]
        })
    return planets

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
    
    # Sidereal Time and local hour
    local_hour = local_now.hour + local_now.minute / 60.0
    gst = (280.46061837 + 360.98564736629 * d) % 360
    lst = (gst + LON) % 360
    lst_hours = lst / 15.0
    
    planets_data = get_planetary_data(d, T, obliq, -Rs_au * math.cos(lambda_s), -Rs_au * math.sin(lambda_s), lst_hours, local_hour)
    
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
        "moon_declination": format_dec(moon_dec),
        "planets": planets_data
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
                
            day_len_hours = (ss - sr) % 24
            h_len = int(day_len_hours)
            m_len = int((day_len_hours - h_len) * 60)
            
            calc.update({
                "phase_name_en": phase_en,
                "phase_name_es": phase_meta["es"],
                "illumination": f"{illum}%",
                "moon_icon": phase_meta["icon"],
                "moon_nf_icon": phase_meta["nf"],
                "moonrise": "No sale" if "No moonrise" in moonrise_str else format_hour(parse_time(moonrise_str)),
                "moonset": "No se pone" if "No moonset" in moonset_str else format_hour(parse_time(moonset_str)),
                "moon_transit": format_hour(moon_transit),
                "sunrise": format_hour(parse_time(sunrise_str)),
                "sunset": format_hour(parse_time(sunset_str)),
                "sun_transit": format_hour(sun_transit),
                "distance": f"{int(get_moon_distance_meeus(d)):,} km".replace(",", "."),
                "day_duration": f"{h_len}h {m_len:02d}m"
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
        
        # Sun transit
        # Obliquity
        T = d / 36525.0
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
        
        day_len_hours = (sunset_local - sunrise_local) % 24
        h_len = int(day_len_hours)
        m_len = int((day_len_hours - h_len) * 60)
        
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
            "distance": f"{int(get_moon_distance_meeus(d)):,} km".replace(",", "."),
            "day_duration": f"{h_len}h {m_len:02d}m"
        })
        return calc

if __name__ == "__main__":
    data = get_astronomy_data()
    print(json.dumps(data))
