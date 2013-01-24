#!/usr/bin/perl

use common::sense;
use Graph::Directed;

use constant {
# plantes
	   BARREN => "barren",
	   GAS => "gas",
	   ICE => "ice",
	   LAVA => "lava",
	   OCEANIC => "oceanic",
	   PLASMA => "plasma",
	   STORM => "storm",
	   TEMPERATE => "temperate",
# resources / raw materials
	   AQUENOUS_LIQUIDS => "aquenous_liquids",
	   AUTOTROPS => "autotrops",
	   BASE_METALS => "base_metals",
	   CARBON_COMPOUNDS => "carbon_compounds",
	   COMPLEX_ORGANISMS => "complex_organisms",
	   FELSIC_MAGMA => "felsic_magma",
	   HEAVY_METALS => "heavy_metals",
	   IONIC_SOLUTIONS => "ionic_solutions",
	   MICRO_ORGANISMS => "micro_organisms",
	   NOBLE_GAS => "noble_gas",
	   NOBLE_METALS => "noble_metals",
	   NON_CS_CRYSTALS => "non_cs_crystals",
	   PLANKTIC_COLONIES => "planktic_colonies",
	   REACTIVE_GAS => "reactive_gas",
	   SUSPENDED_PLASMA => "suspended_plasma",
# preocessed materials
	   BACTERIA => "bacteria",
	   BIOFUELS => "biofuels",
	   BIOMASS => "biomass",
	   CHIRAL_STRUCTURES => "chiral_structures",
	   ELECTROLYTES => "electrolytes",
	   INDUSTRIAL_FIBRES => "industrial_fibres",
	   OXIDIZING_COMPOUND => "oxidizing_compound",
	   OXYGEN => "oxygen",
	   PLASMOIDS => "plasmoids",
	   PRECIOUS_METALS => "precious_metals",
	   PROTEINS => "proteins",
	   REACTIVE_METALS => "reactive_metals",
	   SILICON => "silicon",
	   TOXIC_METALS => "toxic_metals",
	   WATER => "water",
# refined commodities
	   BIOCELLS => "biocells",
	   CONSTRUCTION_BLOCKS => "construction_blocks",
	   CONSUMER_ELECTRONICS => "consumer_electronics",
	   COOLANT => "coolant",
	   ENRICHED_URANIUM => "enriched_uranium",
	   FERTILIZER => "fertilizer",
	   GENETIALLY_ENHANCED_LIVESTOCK => "genetially_enhanced_livestock",
	   LIVESTOCK => "livestock",
	   MECHANICAL_PARTS => "mechanical_parts",
	   MICROFIBER_SHIELDING => "microfiber_shielding",
	   MINIATURE_ELECTRONICS => "miniature_electronics",
	   NANITES => "nanites",
	   OXYDES => "oxydes",
	   POLYARAMIDS => "polyaramids",
	   POLYTEXTILES => "polytextiles",
	   ROCKET_FUEL => "rocket_fuel",
	   SILICATE_GLASS => "silicate_glass",
	   SUPERCONDUCTORS => "superconductors",
	   SUPERTENSILE_PLASTICS => "supertensile_plastics",
	   SYNTHETIC_OIL => "synthetic_oil",
	   TEST_CULTURES => "test_cultures",
	   TRANSMITTER => "transmitter",
	   VIRAL_AGENT => "viral_agent",
	   WATER_COOLED_CPU => "water_cooled_cpu",
# specialized comodities
	   BIOTECH_RESEARCH_REPORTS => "biotech_research_reports",
	   CAMERA_DRONES => "camera_drones",
	   CONDENSATES => "condensates",
	   CRYOPROTECTANT_SOLUTION => "cryoprotectant_solution",
	   DATA_CHIPS => "data_chips",
	   GET_MATRIX_BIOPASTE => "get_matrix_biopaste",
	   GUIDANCE_SYSTEMS => "guidance_systems",
	   HAZMAT_DETECTION_SYSTEMS => "hazmat_detection_systems",
	   HERMETIC_MEMBRANES => "hermetic_membranes",
	   HIGH_TECH_TRANSMITTERS => "high_tech_transmitters",
	   INDUSTRIAL_EXPLOSIVES => "industrial_explosives",
	   NEOCOMS => "neocoms",
	   NUCLEAR_REACTORS => "nuclear_reactors",
	   PLANETARY_VEHICLES => "planetary_vehicles",
	   ROBOTICS => "robotics",
	   SMARTFAB_UTILS => "smartfab_utils",
	   SUPERCOMPUTERS => "supercomputers",
	   SYNTHETIC_SYNAPSES => "synthetic_synapses",
	   TRANSCRANIAL_MICROCONTROLLERS => "transcranial_microcontrollers",
	   UKOMI_SUPER_CONDUCTORS => "ukomi_super_conductors",
	   VACCINES => "vaccines",
# advanced comodities
	   BROADCAST_NODE => "broadcast_node",
	   INTEGRITY_RESPONSE_DRONES => "integrity_response_drones",
	   NANO_FACTORY => "nano_factory",
	   ORGANIC_MORTAR_APPLICATORS => "organic_mortar_applicators",
	   RECURSIVE_COMPUTING_MODULE => "recursive_computing_module",
	   SELF_HARMONIZING_POWER_CORE => "self_harmonizing_power_core",
	   STERILE_CONDUITS => "sterile_conduits",
	   WELWARE_MAINFRAME => "welware_mainframe",
};

my $g = Graph::Directed->new;

# available planets
my %planets = (
       BARREN => 0,
       GAS => 0,
       ICE => 0,
       LAVA => 0,
       OCEANIC => 0,
       PLASMA => 0,
       STORM => 0,
       TEMPERATE => 0,
       );

# available raw materials
my %raw_materials = (
	AQUENOUS_LIQUIDS => 0,
	AUTOTROPS => 0,
	BASE_METALS => 0,
	CARBON_COMPOUNDS => 0,
	COMPLEX_ORGANISMS => 0,
	FELSIC_MAGMA => 0,
	HEAVY_METALS => 0,
	IONIC_SOLUTIONS => 0,
	MICRO_ORGANISMS => 0,
	NOBLE_GAS => 0,
	NOBLE_METALS => 0,
	NON_CS_CRYSTALS => 0,
	PLANKTIC_COLONIES => 0,
	REACTIVE_GAS => 0,
	SUSPENDED_PLASMA => 0,
	);
# planet -> ressource mappings
$g.add_edge(BARREN, AQUENOUS_LIQUIDS);
$g.add_edge(GAS, AQUENOUS_LIQUIDS);
$g.add_edge(ICE, AQUENOUS_LIQUIDS);
$g.add_edge(OCEANIC, AQUENOUS_LIQUIDS);
$g.add_edge(STORM, AQUENOUS_LIQUIDS);
$g.add_edge(TEMPERATE, AQUENOUS_LIQUIDS);

$g.add_edge(TEMPERATE, AUTOTROPS);

$g.add_edge(BARREN, BASE_METALS);
$g.add_edge(GAS, BASE_METALS);
$g.add_edge(LAVA, BASE_METALS);
$g.add_edge(PLASMA, BASE_METALS);
$g.add_edge(STORM, BASE_METALS);

$g.add_edge(BARREN, CARBON_COMPOUNDS);
$g.add_edge(OCEANIC, CARBON_COMPOUNDS);
$g.add_edge(TEMPERATE, CARBON_COMPOUNDS);

$g.add_edge(OCEANIC, COMPLEX_ORGANISMS);
$g.add_edge(TEMPERATE, COMPLEX_ORGANISMS);

$g.add_edge(LAVA, FELSIC_MAGMA);

$g.add_edge(ICE, HEAVY_METALS);
$g.add_edge(LAVA, HEAVY_METALS);
$g.add_edge(PLASMA, HEAVY_METALS);

$g.add_edge(GAS, IONIC_SOLUTIONS);
$g.add_edge(STORM, IONIC_SOLUTIONS);

$g.add_edge(BARREN, MICRO_ORGANISMS);
$g.add_edge(ICE, MICRO_ORGANISMS);
$g.add_edge(OCEANIC, MICRO_ORGANISMS);
$g.add_edge(TEMPERATE, MICRO_ORGANISMS);

$g.add_edge(GAS, NOBLE_GAS);
$g.add_edge(ICE, NOBLE_GAS);
$g.add_edge(STORM, NOBLE_GAS);

$g.add_edge(BARREN, NOBLE_METALS);
$g.add_edge(PLASMA, NOBLE_METALS);

$g.add_edge(LAVA, NON_CS_CRYSTALS);
$g.add_edge(PLASMA, NON_CS_CRYSTALS);

$g.add_edge(ICE, PLANKTIC_COLONIES);
$g.add_edge(OCEANIC, PLANKTIC_COLONIES);

$g.add_edge(GAS, REACTIVE_GAS);

$g.add_edge(LAVA, SUSPENDED_PLASMA);
$g.add_edge(PLASMA, SUSPENDED_PLASMA);
$g.add_edge(STORM, SUSPENDED_PLASMA);

# available processed materials
my $processed_materials = (
	BACTERIA => 0,
	BIOFUELS => 0,
	BIOMASS => 0,
	CHIRAL_STRUCTURES => 0,
	ELECTROLYTES => 0,
	INDUSTRIAL_FIBRES => 0,
	OXIDIZING_COMPOUND => 0,
	OXYGEN => 0,
	PLASMOIDS => 0,
	PRECIOUS_METALS => 0,
	PROTEINS => 0,
	REACTIVE_METALS => 0,
	SILICON => 0,
	TOXIC_METALS => 0,
	WATER => 0,
	);
# raw materials -> processed materials mappings
$g.add_edge(MICRO_ORGANISMS, BACTERIA);
$g.add_edge(CARBON_COMPOUNDS, BIOFUELS);
$g.add_edge(PLANKTIC_COLONIES, BIOMASS);
$g.add_edge(NON_CS_CRYSTALS, CHIRAL_STRUCTURES);
$g.add_edge(IONIC_SOLUTIONS, ELECTROLYTES);
$g.add_edge(AUTOTROPS, INDUSTRIAL_FIBRES);
$g.add_edge(REACTIVE_GAS, OXIDIZING_COMPOUND);
$g.add_edge(NOBLE_GAS, OXYGEN);
$g.add_edge(SUSPENDED_PLASMA, PLASMOIDS);
$g.add_edge(NOBLE_METALS, PRECIOUS_METALS);
$g.add_edge(COMPLEX_ORGANISMS, PROTEINS);
$g.add_edge(BASE_METALS, REACTIVE_METALS);
$g.add_edge(FELSIC_MAGMA, SILICON);
$g.add_edge(HEAVY_METALS, TOXIC_METALS);
$g.add_edge(AQUENOUS_LIQUIDS, WATER);

# processed material => refined commodities
