"""
    OrbitInfo

Struct containing orbit, start time,
and observer location info.
"""
mutable struct OrbitInfo{T1,T2,T3,T4,T5,T6,T7,T8}
    start_time::T1
    start_time_julian_date::T2
    site_loc_lla::T3
    site_loc_ecef::T4
    tle_file_name::T5
    tle::T6
    orb::T7
    eop::T8
end


"""
    initorbitinfo(source_tle::String, target_tle::String, start_time,
                  site_loc_lla)

Initialize the struct OrbitInfo for multiple satellites. Provide
the file names of the individual TLE files.
"""
function initorbitinfo(source_tle::String, target_tle::String, start_time,
                       site_loc_lla)
    start_time_julian_date = DatetoJD(start_time...)
    site_loc_ecef = GeodetictoECEF(site_loc_lla...)
    tle = [read_tle(source_tle)[1], read_tle(target_tle)[1]]
    orb = [init_orbit_propagator(Val(:sgp4), tle[1], sgp4_gc_wgs84),
           init_orbit_propagator(Val(:sgp4), tle[2], sgp4_gc_wgs84)]
    eop = get_iers_eop(:IAU1980)
    tle_names = [source_tle, target_tle]
    return OrbitInfo(start_time, start_time_julian_date,
                     site_loc_lla, site_loc_ecef,
                     tle_names, tle, orb, eop)
end


"""
    initorbitinfo(source_tle::TLE, target_tle::TLE, start_time,
                  site_loc_lla)

Initialize the struct OrbitInfo for multiple satellites. Provide
the already loaded TLE files as `SatelliteToolbox` `TLE` structs.
"""
function initorbitinfo(source_tle::TLE, target_tle::TLE, start_time,
                       site_loc_lla)
    start_time_julian_date = DatetoJD(start_time...)
    site_loc_ecef = GeodetictoECEF(site_loc_lla...)
    tle = [source_tle, target_tle]
    orb = [init_orbit_propagator(Val(:sgp4), tle[1], sgp4_gc_wgs84),
           init_orbit_propagator(Val(:sgp4), tle[2], sgp4_gc_wgs84)]
    eop = get_iers_eop(:IAU1980)
    tle_names = [source_tle.name, target_tle.name]
    return OrbitInfo(start_time, start_time_julian_date,
                     site_loc_lla, site_loc_ecef,
                     tle_names, tle, orb, eop)
end


"""
    initorbitinfo(source_tle::String, start_time, site_loc_lla)

Initialize the struct OrbitInfo for single satellite. Provide
the file name of the individual TLE file.
"""
function initorbitinfo(source_tle::String, start_time, site_loc_lla)
    start_time_julian_date = DatetoJD(start_time...)
    site_loc_ecef = GeodetictoECEF(site_loc_lla...)
    tle = read_tle(source_tle)[1]
    orb = init_orbit_propagator(Val(:sgp4), tle, sgp4_gc_wgs84)
    eop = get_iers_eop(:IAU1980)
    return OrbitInfo(start_time, start_time_julian_date,
                     site_loc_lla, site_loc_ecef,
                     source_tle, tle, orb, eop)
end


"""
    initorbitinfo(source_tle::TLE, start_time, site_loc_lla)

Initialize the struct OrbitInfo for single satellite. Provide
the already loaded TLE file as a `SatelliteToolbox` `TLE` struct.
"""
function initorbitinfo(source_tle::TLE, start_time, site_loc_lla)
    start_time_julian_date = DatetoJD(start_time...)
    site_loc_ecef = GeodetictoECEF(site_loc_lla...)
    tle = source_tle
    orb = init_orbit_propagator(Val(:sgp4), tle, sgp4_gc_wgs84)
    eop = get_iers_eop(:IAU1980)
    return OrbitInfo(start_time, start_time_julian_date,
                     site_loc_lla, site_loc_ecef,
                     source_tle.name, tle, orb, eop)
end


"""
    SatelliteRAE

Holds information on a given satellite range,
azimuth, and elevation from a observer position.
"""
struct SatelliteRAE{A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11}
    name::A1
    sat_tle::A2
    julian_date_range::A3
    obs_lla::A4
    obs_ecef::A5
    Δt::A6
    ts::A7
    sat_range::A8
    sat_azimuth::A9
    sat_elevation::A10
    sat_ecef::A11
end


"""
    calcenumatrix(obs_lla)

Calculate the ECEF to ENU transformation matrix
using the observer's position in LLA.

**NOTE:** Latitudes and longitudes are in radians.
"""
function calcenumatrix(obs_lla)
    lat = obs_lla[1]  # rad
    lon = obs_lla[2]  # rad
    h = obs_lla[3]  # meters
    return [         -sin(lon)           cos(lon)        0;
            -sin(lat)*cos(lon) -sin(lat)*sin(lon) cos(lat);
             cos(lat)*cos(lon)  cos(lat)*sin(lon) sin(lat)]
end



"""
    calcelevation(sat_tle, julian_date_range, eop, obs_ecef)

Calculates the elevation of a given satellite relative to the
observer for every second between the range specified in
`julian_date_range`.
"""
function calcelevation(sat_tle, julian_date_range, eop, obs_lla;
                       name="Satellite")
    obs_ecef = GeodetictoECEF(obs_lla[1], obs_lla[2], obs_lla[3])
    sat_orb = init_orbit_propagator(Val{:sgp4}, sat_tle)
    Δt = 1/60/60/24  # days (1 second)
    ts = Array(julian_date_range[1]:Δt:julian_date_range[2])
    # Propagate orbit to ts
    sat_orb, rs, vs = propagate_to_epoch!(sat_orb, ts)
    # Allocate space for storage
    sat_ranges = Array{Float64}(undef, length(ts))
    azs = Array{Float64}(undef, length(ts))
    els = Array{Float64}(undef, length(ts))
    sat_ecefs = Array{Float64}(undef, 3, length(ts))
    # Calculate ENU transformation matrix
    R_ENU = calcenumatrix(obs_lla)
    for i in 1:length(ts)
        # Convert orbits to state vectors
        sat_teme = kepler_to_sv(sat_orb[i])
        # Transform TEME to ECEF frame and extract position
        sat_ecef = svECItoECEF(sat_teme, TEME(), ITRF(), sat_teme.t, eop).r
        # Calculate user-to-sat vector
        user_to_sat = sat_ecef - obs_ecef
        # Caluclate satellite range
        sat_range = norm(user_to_sat)
        # Normalize `user_to_sat`
        user_to_sat_norm = user_to_sat./sat_range
        # Transform normalized user-to-sat vector to ENU
        enu = R_ENU*user_to_sat_norm  # [East, North, South]
        # Calculate satellite azimuth
        az = atan(enu[1], enu[2])
        # Calculate satellite elevation
        el = asin(enu[3]/norm(enu))
        # Save values
        sat_ranges[i] = sat_range
        azs[i] = rad2deg(az)
        els[i] = rad2deg(el)
        sat_ecefs[:,i] = sat_ecef
    end
    return SatelliteRAE(name, sat_tle, julian_date_range,
                        obs_lla, obs_ecef, Δt, ts, sat_ranges,
                        azs, els, sat_ecefs)
end


"""
    getCurrentGPSNORADIDS()
"""
function getCurrentGPSNORADIDS()
    directory = string(homedir(), "/.GNSSTools")
    if ~isdir(directory)
        mkpath(directory)
    end
    ids_file = string(directory, "/GPSData.txt")
    if ~isfile(ids_file)
        run(`curl -o $(ids_file) ftp://ftp.agi.com/pub/Catalog/Almanacs/SEM/GPSData.txt`);
    end
    
end

getCurrentGPSNORADIDS()
