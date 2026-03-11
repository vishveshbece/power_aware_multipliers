set_db init_lib_search_path /home/install/FOUNDRY/digital/45nm/LIBS/lib/max
set_db library slow.lib
read_hdl -sv rtl/multiplier_top.sv
elaborate multiplier_top
read_sdc constraints.sdc
synthesize -to_mapped
report_area > reports/area.rpt
report_timing > reports/timing.rpt
report_power > reports/power.rpt
write_hdl > synth/netlist.v
