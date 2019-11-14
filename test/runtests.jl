using Test
using KMLTracks


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
end


@testset "read_kml_file" begin
    fname = "sample.kml"
    kmldoc = read_kml_file(fname)
    @test length(kmldoc.placemark.track.points) == 45
end

