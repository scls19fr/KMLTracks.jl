using Test
using KMLTracks
using TimeZones


@testset "parse_kml_string" begin
    s = """<?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
        <ExtendedData>
            <Data name="GPSModelName">
                <value>MyGPS</value>
            </Data>
        </ExtendedData>
        <Placemark>
            <gx:Track>
                <altitudeMode>absolute</altitudeMode>
                    <when>2019-11-07T08:44:12Z</when><gx:coord>0.309042 46.586349 111.4</gx:coord>
                    <when>2019-11-07T08:44:16Z</when><gx:coord>0.309042 46.586349 111.1</gx:coord>
                    <when>2019-11-07T08:44:20Z</when><gx:coord>0.309042 46.586349 111.3</gx:coord>
            </gx:Track>
        </Placemark>
    </kml>"""
    kmldoc = parse_kml_string(s)
    @test length(kmldoc.placemark.track.points) == 3
    pt = kmldoc.placemark.track.points[1]
    @test pt.time == ZonedDateTime(2019, 11, 07, 8, 44, 12, tz"UTC")
    @test pt.longitude == 0.309042
    @test pt.latitude == 46.586349
    @test pt.altitude == 111.4
end

@testset "read_kml_file" begin
    fname = "sample.kml"
    kmldoc = read_kml_file(fname)
    @test length(kmldoc.placemark.track.points) == 45
    pt = kmldoc.placemark.track.points[1]
    @test pt.time == ZonedDateTime(2019, 11, 07, 8, 44, 12, tz"UTC")
    @test pt.longitude == 0.309042
    @test pt.latitude == 46.586349
    @test pt.altitude == 111.4

    pt = kmldoc.placemark.track.points[45]
    @test pt.time == ZonedDateTime(2019, 11, 07, 8, 47, 8, 1, tz"UTC")
    @test pt.longitude == 0.295266
    @test pt.latitude == 46.575615
    @test pt.altitude == 267.6
end

@testset "parse_kml_string_coma_issue" begin
    s = """<?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
        <ExtendedData>
            <Data name="GPSModelName">
                <value>MyGPS</value>
            </Data>
        </ExtendedData>
        <Placemark>
            <gx:Track>
                <altitudeMode>absolute</altitudeMode>
                    <when>2019-11-07T08:44:12Z</when><gx:coord>0,309042 46,586349 111,4</gx:coord>
                    <when>2019-11-07T08:44:16Z</when><gx:coord>0,309042 46,586349 111,1</gx:coord>
                    <when>2019-11-07T08:44:20Z</when><gx:coord>0,309042 46,586349 111,3</gx:coord>
            </gx:Track>
        </Placemark>
    </kml>"""
    kmldoc = parse_kml_string(s)
    @test length(kmldoc.placemark.track.points) == 3
    pt = kmldoc.placemark.track.points[1]
    @test pt.time == ZonedDateTime(2019, 11, 07, 8, 44, 12, tz"UTC")
    @test pt.longitude == 0.309042
    @test pt.latitude == 46.586349
    @test pt.altitude == 111.4
end