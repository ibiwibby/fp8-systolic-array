# Logical 100 MHz timing constraint for the synthesizable core.
# No package pins are assigned because systolic_mul is not a board-level top.
create_clock -name clk -period 10.000 -waveform {0.000 5.000} [get_ports clk]
