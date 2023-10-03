//
//  MapStyles.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 18.08.2023.
//

import Foundation
import GLMap

// Help - https://gurumaps.app/docs/mapcss/
struct MapStyles {
    //  Displays the loaded OSM data.
    private static let source = """
    node {
        icon-image: "poi_circle_small.svg";
        icon-scale: 1;
        icon-tint: blue;
        [fixme] {icon-tint: red;}
        |z17- {icon-scale: 2;}
    }
    line {
        linecap: round;
        width: 1pt;
        color:brown;
        [fixme] {color:red;}
        [bbox] {color:yellow;
                width: 2pt;
                dashes: 12,12;
                dashes-color: red;
                dashes-width: eval( zlinear( 16, 3pt, 4pt ) );
                }
        |z17- {width: 3pt;}
    }
    area {
        width:1pt;
        color:black;
        [fixme] {color:red;}
        |z17- {width:3pt;}
    }
    """
    
    //  Displays objects that have been modified but not sent to the server (green).
    private static let saved = """
    node {
        icon-image: "poi_circle_small.svg";
        icon-scale: 2;
        icon-tint: green;
    }
    line {
        linecap: round;
        width: 3pt;
        color:green;
    }
    area {
        width:3pt;
        color:green;
    }
    """
    
    //  Displays the object that was tapped and whose properties are currently being edited (yellow).
    private static let edit = """
    node {
        icon-image: "poi_circle_small.svg";
        icon-scale: 2;
        icon-tint: yellow;
    }
    line {
        linecap: round;
        width: 3pt;
        color:yellow;
    }
    area {
        width:3pt;
        color:yellow;
    }
    """
    
    //  Highlights objects that fell under the tap, if there was not one object under the tap, but several.
    private static let tapped = """
        node {
            icon-image: "poi_circle_small.svg";
            icon-scale: 1;
            icon-tint: orange;
            |z17- {icon-scale: 2;}
        }
        line {
            linecap: round;
            width: 2pt;
            color:orange;
            |z17- {width: 3pt;}
        }
        area {
            width:2pt;
            color:orange;
            |z17- {width:3pt;}
        }
    """
    private static let overpass = """
    node {
        icon-image: "poi_circle_small.svg";
        icon-scale: 2;
        icon-tint: orange;
    }
    """
    
    static let sourceStyle = GLMapVectorCascadeStyle.createStyle(source)!
    
    //  Displays objects that have been modified but not sent to the server (green).
    static let savedStyle = GLMapVectorCascadeStyle.createStyle(saved)!
    
    //  Displays the object that was tapped and whose properties are currently being edited (yellow).
    static let editStyle = GLMapVectorCascadeStyle.createStyle(edit)!
    
    //  Highlights objects that fell under the tap, if there was not one object under the tap, but several.
    static let tappedStyle = GLMapVectorCascadeStyle.createStyle(tapped)!
    
    static let overpassStyle = GLMapVectorCascadeStyle.createStyle(overpass)!
}
