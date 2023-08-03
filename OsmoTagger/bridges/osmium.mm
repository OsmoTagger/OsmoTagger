//
//  osmium.m
//  OSM editor
//
//  Created by Evgen Bodunov on 15.10.22.
//

#include "osmium.h"
#include "tool/export/ruleset.hpp"
#include "tool/export/export_format_json.hpp"
#include "tool/export/export_handler.hpp"

#include <string>
#include <osmium/area/assembler.hpp>
#include <osmium/area/multipolygon_manager.hpp>
#include <osmium/handler/check_order.hpp>
#include <osmium/index/map.hpp>
#include <osmium/io/any_input.hpp>
#include <osmium/io/reader_with_progress_bar.hpp>
#include <osmium/memory/buffer.hpp>
#include <osmium/osm.hpp>
#include <osmium/relations/manager_util.hpp>
#include <osmium/util/string.hpp>
#include <osmium/util/verbose_output.hpp>
#include <osmium/visitor.hpp>
#include <osmium/handler/node_locations_for_ways.hpp>
#include <osmium/index/map/all.hpp>

using index_type = osmium::index::map::Map<osmium::unsigned_object_id_type, osmium::Location>;
using location_handler_type = osmium::handler::NodeLocationsForWays<index_type, index_type>;

extern "C" NSString* osmium_convert(NSString *input, NSString *output) {
    try {
        // The Reader is initialized here with an osmium::io::File, but could
        // also be directly initialized with a file name.
        const osmium::io::File input_file{input.UTF8String};

        osmium::area::Assembler::config_type assembler_config;
        osmium::area::MultipolygonManager<osmium::area::Assembler> mp_manager{assembler_config};

        printf("First pass (of two) through input file (reading relations)...\n");
        osmium::relations::read_relations(input_file, mp_manager);
        printf("First pass done.\n");

        printf("Second pass (of two) through input file...\n");
        
        options_type options{};
        options.id = "@id";
        options.version = "version";
        Ruleset linear_ruleset;
        Ruleset area_ruleset;
        geometry_types geometry_types;
        
        osmium::io::overwrite output_overwrite = osmium::io::overwrite::allow;
        osmium::io::fsync fsync = osmium::io::fsync::yes;
        
        linear_ruleset.init_filter();
        area_ruleset.init_filter();

        auto handler = std::make_unique<ExportFormatJSON>("geojson", output.UTF8String, output_overwrite, fsync, options);
        
        ExportHandler export_handler{std::move(handler), linear_ruleset, area_ruleset, geometry_types, true, true};
        osmium::handler::CheckOrder check_order_handler;

        std::string index_type_name = "flex_mem";
        if (index_type_name == "none") {
            osmium::io::ReaderWithProgressBar reader{true, input_file};
            osmium::apply(reader, check_order_handler, export_handler, mp_manager.handler([&export_handler](osmium::memory::Buffer&& buffer) {
                osmium::apply(buffer, export_handler);
            }));
            reader.close();
        } else {
            const auto& map_factory = osmium::index::MapFactory<osmium::unsigned_object_id_type, osmium::Location>::instance();
            auto location_index_pos = map_factory.create_map(index_type_name);
            auto location_index_neg = map_factory.create_map(index_type_name);
            location_handler_type location_handler{*location_index_pos, *location_index_neg};
            
            osmium::io::ReaderWithProgressBar reader{true, input.UTF8String};
            osmium::apply(reader, check_order_handler, location_handler, export_handler, mp_manager.handler([&export_handler](osmium::memory::Buffer&& buffer) {
                osmium::apply(buffer, export_handler);
            }));
            reader.close();
//            m_vout << "About "
//                   << show_mbytes(location_index_pos->used_memory() + location_index_neg->used_memory())
//                   << " MBytes used for node location index (in main memory or on disk).\n";
        }

//        const auto incomplete_relations = mp_manager.relations_database().count_relations();
//        if (incomplete_relations > 0) {
//            throw osmium::geometry_error{"Found " + std::to_string(incomplete_relations) + " incomplete relation(s)"};
//        }

        printf("Second pass done.\n");
        export_handler.close();

//        m_vout << "Wrote " << export_handler.count() << " features.\n";
//        m_vout << "Encountered " << export_handler.error_count() << " errors.\n";

    } catch (const std::exception& e) {
        // All exceptions used by the Osmium library derive from std::exception.
        std::cerr << e.what() << '\n';
        return [NSString stringWithUTF8String:e.what()];
    }
    return nullptr;
}

