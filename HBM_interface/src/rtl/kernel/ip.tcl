create_ip                  \
  -name        blk_mem_gen \
  -vendor      xilinx.com  \
  -library     ip          \
  -version     8.4         \
  -module_name hbm_bram
set_property -dict [
    list                                                                     \
      CONFIG.Memory_Type                                {True_Dual_Port_RAM} \
      CONFIG.Enable_32bit_Address                       {false}              \
      CONFIG.Use_Byte_Write_Enable                      {false}              \
      CONFIG.Byte_Size                                  {9}                  \
      CONFIG.Write_Width_A                              {256}                \
      CONFIG.Write_Depth_A                              {2048}               \
      CONFIG.Read_Width_A                               {256}                \
      CONFIG.Enable_A                                   {Always_Enabled}     \
      CONFIG.Write_Width_B                              {256}                \
      CONFIG.Read_Width_B                               {256}                \
      CONFIG.Enable_B                                   {Always_Enabled}     \
      CONFIG.Register_PortA_Output_of_Memory_Primitives {false}              \
      CONFIG.Register_PortB_Output_of_Memory_Primitives {false}              \
      CONFIG.Use_RSTA_Pin                               {false}              \
      CONFIG.Use_RSTB_Pin                               {false}              \
      CONFIG.Port_A_Write_Rate                          {50}                 \
      CONFIG.Port_B_Clock                               {100}                \
      CONFIG.Port_B_Write_Rate                          {50}                 \
      CONFIG.Port_B_Enable_Rate                         {100}                \
      CONFIG.use_bram_block                             {Stand_Alone}        \
      CONFIG.EN_SAFETY_CKT                              {false}              \
  ] [get_ips hbm_bram]
set_property generate_synth_checkpoint 0 [get_files hbm_bram.xci]

create_ip            \
  -name mult_gen     \
  -vendor xilinx.com \
  -library ip        \
  -version 12.0      \
  -module_name mult_gen_0
set_property -dict [
  list                                          \
    CONFIG.PortAWidth {64}                      \
    CONFIG.PortBWidth {64}                      \
    CONFIG.PortAType {Unsigned}                 \
    CONFIG.PortBType {Unsigned}                 \
    CONFIG.Multiplier_Construction {Use_Mults}  \
    CONFIG.PipeStages {18}                      \
    CONFIG.OutputWidthHigh {127}                \
  ] [get_ips mult_gen_0]
set_property generate_synth_checkpoint 0 [get_files mult_gen_0.xci]

create_ip                     \
  -name  axi_protocol_checker \
  -vendor xilinx.com          \
  -library ip                 \
  -version 2.0                \
  -module_name axi_protocol_checker_0
set_property -dict [
  list \
    CONFIG.ADDR_WIDTH {64}                       \
    CONFIG.DATA_WIDTH {256}                      \
    CONFIG.MAX_AR_WAITS {256}                    \
    CONFIG.MAX_AW_WAITS {256}                    \
    CONFIG.MAX_B_WAITS {256}                     \
    CONFIG.MAX_CONTINUOUS_RTRANSFERS_WAITS {256} \
    CONFIG.MAX_CONTINUOUS_WTRANSFERS_WAITS {256} \
    CONFIG.MAX_R_WAITS {256}                     \
    CONFIG.MAX_WLAST_TO_AWVALID_WAITS {256}      \
    CONFIG.MAX_WRITE_TO_BVALID_WAITS {256}       \
    CONFIG.MAX_W_WAITS {256}                     \
  ] [get_ips axi_protocol_checker_0]
set_property generate_synth_checkpoint 0 [get_files axi_protocol_checker_0.xci]

create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0
set_property -dict [
  list                                  \
    CONFIG.C_PROBE7_WIDTH {16}          \
    CONFIG.C_PROBE6_WIDTH {1}           \
    CONFIG.C_PROBE5_WIDTH {16}          \
    CONFIG.C_PROBE4_WIDTH {16}          \
    CONFIG.C_PROBE3_WIDTH {1}           \
    CONFIG.C_PROBE2_WIDTH {4}           \
    CONFIG.C_PROBE1_WIDTH {1}           \
    CONFIG.C_PROBE0_WIDTH {1}           \
    CONFIG.C_NUM_OF_PROBES {8}          \
    CONFIG.C_EN_STRG_QUAL {1}           \
    CONFIG.C_INPUT_PIPE_STAGES {2}      \
    CONFIG.C_ADV_TRIGGER {true}         \
    CONFIG.C_PROBE7_MU_CNT {4}          \
    CONFIG.C_PROBE6_MU_CNT {4}          \
    CONFIG.C_PROBE5_MU_CNT {4}          \
    CONFIG.C_PROBE4_MU_CNT {4}          \
    CONFIG.C_PROBE3_MU_CNT {4}          \
    CONFIG.C_PROBE2_MU_CNT {4}          \
    CONFIG.C_PROBE1_MU_CNT {4}          \
    CONFIG.C_PROBE0_MU_CNT {4}          \
    CONFIG.ALL_PROBE_SAME_MU_CNT {4}    \
    CONFIG.C_ENABLE_ILA_AXI_MON {false} \
    CONFIG.C_MONITOR_TYPE {Native}      \
  ] [get_ips ila_0]
generate_target {instantiation_template} [get_files ila_0.xci]
set_property generate_synth_checkpoint false [get_files ila_0.xci]

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_sync
set_property -dict [
  list                                                    \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM}   \
    CONFIG.Input_Data_Width {256}                         \
    CONFIG.Input_Depth {64}                               \
    CONFIG.Output_Data_Width {256}                        \
    CONFIG.Output_Depth {64}                              \
    CONFIG.Data_Count_Width {6}                           \
    CONFIG.Write_Data_Count_Width {6}                     \
    CONFIG.Read_Data_Count_Width {6}                      \
    CONFIG.Full_Threshold_Negate_Value {61}               \
    CONFIG.Performance_Options {First_Word_Fall_Through}  \
    CONFIG.Use_Extra_Logic {true}                         \
    CONFIG.Full_Threshold_Assert_Value {63}               \
    CONFIG.Empty_Threshold_Assert_Value {4}               \
    CONFIG.Empty_Threshold_Negate_Value {5}               \
  ] [get_ips fifo_sync]
generate_target {instantiation_template} [get_files fifo_sync.xci]
set_property generate_synth_checkpoint false [get_files fifo_sync.xci]