
################################################################
# This is a generated script based on design: sim
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2021.1
set current_vivado_version [version -short]

# if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
#    puts ""
#    catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

#    return 1
# }

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source sim_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# kernel

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7vx485tffg1157-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name sim

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:axi_protocol_checker:2.0\
xilinx.com:ip:smartconnect:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
kernel\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parekernelype [get_property TYPE $parentObj]
  if { $parekernelype ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parekernelype>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set s_axi_control [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {12} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $s_axi_control


  # Create ports
  set clk [ create_bd_port -dir I clk ]
  set interrupt [ create_bd_port -dir O -type intr interrupt ]
  set pc_asserted [ create_bd_port -dir O pc_asserted ]
  set pc_status [ create_bd_port -dir O -from 159 -to 0 pc_status ]
  set resetn [ create_bd_port -dir I -type rst resetn ]

  # Create instance: kernel_0, and set properties
  set block_name kernel
  set block_cell_name kernel_0
  if { [catch {set kernel_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $kernel_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_0

  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_0_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_0_bram

  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_1

  # Create instance: axi_bram_ctrl_10, and set properties
  set axi_bram_ctrl_10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_10 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_10

  # Create instance: axi_bram_ctrl_10_bram, and set properties
  set axi_bram_ctrl_10_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_10_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_10_bram

  # Create instance: axi_bram_ctrl_11, and set properties
  set axi_bram_ctrl_11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_11 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_11

  # Create instance: axi_bram_ctrl_11_bram, and set properties
  set axi_bram_ctrl_11_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_11_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_11_bram

  # Create instance: axi_bram_ctrl_2, and set properties
  set axi_bram_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_2 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_2

  # Create instance: axi_bram_ctrl_3, and set properties
  set axi_bram_ctrl_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_3 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_3

  # Create instance: axi_bram_ctrl_4, and set properties
  set axi_bram_ctrl_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_4 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_4

  # Create instance: axi_bram_ctrl_5, and set properties
  set axi_bram_ctrl_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_5 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_5

  # Create instance: axi_bram_ctrl_6, and set properties
  set axi_bram_ctrl_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_6 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_6

  # Create instance: axi_bram_ctrl_7, and set properties
  set axi_bram_ctrl_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_7 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_7

  # Create instance: axi_bram_ctrl_8, and set properties
  set axi_bram_ctrl_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_8 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_8

  # Create instance: axi_bram_ctrl_9, and set properties
  set axi_bram_ctrl_9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_9 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_9

  # Create instance: axi_bram_ctrl_12, and set properties
  set axi_bram_ctrl_12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_12 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_12

  # Create instance: axi_bram_ctrl_12_bram, and set properties
  set axi_bram_ctrl_12_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_12_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_12_bram

  # Create instance: axi_bram_ctrl_13, and set properties
  set axi_bram_ctrl_13 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_13 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_13

  # Create instance: axi_bram_ctrl_13_bram, and set properties
  set axi_bram_ctrl_13_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_13_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_13_bram

  # Create instance: axi_bram_ctrl_14, and set properties
  set axi_bram_ctrl_14 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_14 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_14

  # Create instance: axi_bram_ctrl_14_bram, and set properties
  set axi_bram_ctrl_14_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_14_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_14_bram

  # Create instance: axi_bram_ctrl_15, and set properties
  set axi_bram_ctrl_15 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_15 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_15

  # Create instance: axi_bram_ctrl_15_bram, and set properties
  set axi_bram_ctrl_15_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_15_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_15_bram

  # Create instance: axi_bram_ctrl_16, and set properties
  set axi_bram_ctrl_16 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_16 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_16

  # Create instance: axi_bram_ctrl_16_bram, and set properties
  set axi_bram_ctrl_16_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_16_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_16_bram

  # Create instance: axi_bram_ctrl_17, and set properties
  set axi_bram_ctrl_17 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_17 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_17

  # Create instance: axi_bram_ctrl_17_bram, and set properties
  set axi_bram_ctrl_17_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_17_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_17_bram

  # Create instance: axi_bram_ctrl_18, and set properties
  set axi_bram_ctrl_18 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_18 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_18

  # Create instance: axi_bram_ctrl_18_bram, and set properties
  set axi_bram_ctrl_18_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_18_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_18_bram

  # Create instance: axi_bram_ctrl_19, and set properties
  set axi_bram_ctrl_19 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_19 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_19

  # Create instance: axi_bram_ctrl_19_bram, and set properties
  set axi_bram_ctrl_19_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_19_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_19_bram

  # Create instance: axi_bram_ctrl_1_bram, and set properties
  set axi_bram_ctrl_1_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_1_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_1_bram

  # Create instance: axi_bram_ctrl_20, and set properties
  set axi_bram_ctrl_20 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_20 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_20

  # Create instance: axi_bram_ctrl_20_bram, and set properties
  set axi_bram_ctrl_20_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_20_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_20_bram

  # Create instance: axi_bram_ctrl_21, and set properties
  set axi_bram_ctrl_21 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_21 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_21

  # Create instance: axi_bram_ctrl_21_bram, and set properties
  set axi_bram_ctrl_21_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_21_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_21_bram

  # Create instance: axi_bram_ctrl_22, and set properties
  set axi_bram_ctrl_22 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_22 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_22

  # Create instance: axi_bram_ctrl_22_bram, and set properties
  set axi_bram_ctrl_22_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_22_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_22_bram

  # Create instance: axi_bram_ctrl_23, and set properties
  set axi_bram_ctrl_23 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_23 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_23

  # Create instance: axi_bram_ctrl_23_bram, and set properties
  set axi_bram_ctrl_23_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_23_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_23_bram

  # Create instance: axi_bram_ctrl_24, and set properties
  set axi_bram_ctrl_24 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_24 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_24

  # Create instance: axi_bram_ctrl_24_bram, and set properties
  set axi_bram_ctrl_24_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_24_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_24_bram

  # Create instance: axi_bram_ctrl_25, and set properties
  set axi_bram_ctrl_25 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_25 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_25

  # Create instance: axi_bram_ctrl_25_bram, and set properties
  set axi_bram_ctrl_25_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_25_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_25_bram

  # Create instance: axi_bram_ctrl_26, and set properties
  set axi_bram_ctrl_26 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_26 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_26

  # Create instance: axi_bram_ctrl_26_bram, and set properties
  set axi_bram_ctrl_26_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_26_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_26_bram

  # Create instance: axi_bram_ctrl_27, and set properties
  set axi_bram_ctrl_27 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_27 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_27

  # Create instance: axi_bram_ctrl_27_bram, and set properties
  set axi_bram_ctrl_27_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_27_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_27_bram

  # Create instance: axi_bram_ctrl_28, and set properties
  set axi_bram_ctrl_28 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_28 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_28

  # Create instance: axi_bram_ctrl_28_bram, and set properties
  set axi_bram_ctrl_28_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_28_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_28_bram

  # Create instance: axi_bram_ctrl_29, and set properties
  set axi_bram_ctrl_29 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_29 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_29

  # Create instance: axi_bram_ctrl_29_bram, and set properties
  set axi_bram_ctrl_29_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_29_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_29_bram

  # Create instance: axi_bram_ctrl_2_bram, and set properties
  set axi_bram_ctrl_2_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_2_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_2_bram

  # Create instance: axi_bram_ctrl_30, and set properties
  set axi_bram_ctrl_30 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_30 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_30

  # Create instance: axi_bram_ctrl_30_bram, and set properties
  set axi_bram_ctrl_30_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_30_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_30_bram

  # Create instance: axi_bram_ctrl_31, and set properties
  set axi_bram_ctrl_31 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_31 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl_31

  # Create instance: axi_bram_ctrl_31_bram, and set properties
  set axi_bram_ctrl_31_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_31_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_31_bram

  # Create instance: axi_bram_ctrl_3_bram, and set properties
  set axi_bram_ctrl_3_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_3_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_3_bram

  # Create instance: axi_bram_ctrl_4_bram, and set properties
  set axi_bram_ctrl_4_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_4_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_4_bram

  # Create instance: axi_bram_ctrl_5_bram, and set properties
  set axi_bram_ctrl_5_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_5_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_5_bram

  # Create instance: axi_bram_ctrl_6_bram, and set properties
  set axi_bram_ctrl_6_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_6_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_6_bram

  # Create instance: axi_bram_ctrl_7_bram, and set properties
  set axi_bram_ctrl_7_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_7_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_7_bram

  # Create instance: axi_bram_ctrl_8_bram, and set properties
  set axi_bram_ctrl_8_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_8_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_8_bram

  # Create instance: axi_bram_ctrl_9_bram, and set properties
  set axi_bram_ctrl_9_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_9_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_9_bram

  # Create instance: axi_protocol_checker_tb, and set properties
  set axi_protocol_checker_tb [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_checker:2.0 axi_protocol_checker_tb ]
  set_property -dict [ list \
   CONFIG.MAX_AR_WAITS {256} \
   CONFIG.MAX_AW_WAITS {256} \
   CONFIG.MAX_B_WAITS {256} \
   CONFIG.MAX_CONTINUOUS_RTRANSFERS_WAITS {256} \
   CONFIG.MAX_CONTINUOUS_WTRANSFERS_WAITS {256} \
   CONFIG.MAX_R_WAITS {256} \
   CONFIG.MAX_WLAST_TO_AWVALID_WAITS {256} \
   CONFIG.MAX_WRITE_TO_BVALID_WAITS {256} \
   CONFIG.MAX_W_WAITS {256} \
 ] $axi_protocol_checker_tb

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_0

  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_1

  # Create instance: smartconnect_2, and set properties
  set smartconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_2 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_2

  # Create instance: smartconnect_3, and set properties
  set smartconnect_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_3 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_3

  # Create instance: smartconnect_4, and set properties
  set smartconnect_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_4 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_4

  # Create instance: smartconnect_5, and set properties
  set smartconnect_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_5 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_5

  # Create instance: smartconnect_6, and set properties
  set smartconnect_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_6 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_6

  # Create instance: smartconnect_7, and set properties
  set smartconnect_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_7 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_7

  # Create instance: smartconnect_8, and set properties
  set smartconnect_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_8 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_8

  # Create instance: smartconnect_9, and set properties
  set smartconnect_9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_9 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_9

  # Create instance: smartconnect_10, and set properties
  set smartconnect_10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_10 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_10

  # Create instance: smartconnect_11, and set properties
  set smartconnect_11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_11 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_11

  # Create instance: smartconnect_12, and set properties
  set smartconnect_12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_12 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_12

  # Create instance: smartconnect_13, and set properties
  set smartconnect_13 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_13 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_13

  # Create instance: smartconnect_14, and set properties
  set smartconnect_14 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_14 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_14

  # Create instance: smartconnect_15, and set properties
  set smartconnect_15 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_15 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_15

  # Create instance: smartconnect_16, and set properties
  set smartconnect_16 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_16 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_16

  # Create instance: smartconnect_17, and set properties
  set smartconnect_17 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_17 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_17

  # Create instance: smartconnect_18, and set properties
  set smartconnect_18 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_18 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_18

  # Create instance: smartconnect_19, and set properties
  set smartconnect_19 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_19 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_19

  # Create instance: smartconnect_20, and set properties
  set smartconnect_20 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_20 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_20

  # Create instance: smartconnect_21, and set properties
  set smartconnect_21 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_21 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_21

  # Create instance: smartconnect_22, and set properties
  set smartconnect_22 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_22 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_22

  # Create instance: smartconnect_23, and set properties
  set smartconnect_23 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_23 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_23

  # Create instance: smartconnect_24, and set properties
  set smartconnect_24 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_24 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_24

  # Create instance: smartconnect_25, and set properties
  set smartconnect_25 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_25 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_25

  # Create instance: smartconnect_26, and set properties
  set smartconnect_26 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_26 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_26

  # Create instance: smartconnect_27, and set properties
  set smartconnect_27 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_27 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_27

  # Create instance: smartconnect_28, and set properties
  set smartconnect_28 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_28 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_28

  # Create instance: smartconnect_29, and set properties
  set smartconnect_29 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_29 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_29

  # Create instance: smartconnect_30, and set properties
  set smartconnect_30 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_30 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_30

  # Create instance: smartconnect_31, and set properties
  set smartconnect_31 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_31 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_31

  # Create interface connections
  connect_bd_intf_net -intf_net kernel_0_m00_axi [get_bd_intf_pins kernel_0/m00_axi] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m01_axi [get_bd_intf_pins kernel_0/m01_axi] [get_bd_intf_pins smartconnect_1/S00_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets kernel_0_m01_axi] [get_bd_intf_pins axi_protocol_checker_tb/PC_AXI] [get_bd_intf_pins smartconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m02_axi [get_bd_intf_pins kernel_0/m02_axi] [get_bd_intf_pins smartconnect_2/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m03_axi [get_bd_intf_pins kernel_0/m03_axi] [get_bd_intf_pins smartconnect_3/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m04_axi [get_bd_intf_pins kernel_0/m04_axi] [get_bd_intf_pins smartconnect_4/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m05_axi [get_bd_intf_pins kernel_0/m05_axi] [get_bd_intf_pins smartconnect_5/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m06_axi [get_bd_intf_pins kernel_0/m06_axi] [get_bd_intf_pins smartconnect_6/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m07_axi [get_bd_intf_pins kernel_0/m07_axi] [get_bd_intf_pins smartconnect_7/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m08_axi [get_bd_intf_pins kernel_0/m08_axi] [get_bd_intf_pins smartconnect_8/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m09_axi [get_bd_intf_pins kernel_0/m09_axi] [get_bd_intf_pins smartconnect_9/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m10_axi [get_bd_intf_pins kernel_0/m10_axi] [get_bd_intf_pins smartconnect_10/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m11_axi [get_bd_intf_pins kernel_0/m11_axi] [get_bd_intf_pins smartconnect_11/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m12_axi [get_bd_intf_pins kernel_0/m12_axi] [get_bd_intf_pins smartconnect_12/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m13_axi [get_bd_intf_pins kernel_0/m13_axi] [get_bd_intf_pins smartconnect_13/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m14_axi [get_bd_intf_pins kernel_0/m14_axi] [get_bd_intf_pins smartconnect_14/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m15_axi [get_bd_intf_pins kernel_0/m15_axi] [get_bd_intf_pins smartconnect_15/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m16_axi [get_bd_intf_pins kernel_0/m16_axi] [get_bd_intf_pins smartconnect_16/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m17_axi [get_bd_intf_pins kernel_0/m17_axi] [get_bd_intf_pins smartconnect_17/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m18_axi [get_bd_intf_pins kernel_0/m18_axi] [get_bd_intf_pins smartconnect_18/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m19_axi [get_bd_intf_pins kernel_0/m19_axi] [get_bd_intf_pins smartconnect_19/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m20_axi [get_bd_intf_pins kernel_0/m20_axi] [get_bd_intf_pins smartconnect_20/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m21_axi [get_bd_intf_pins kernel_0/m21_axi] [get_bd_intf_pins smartconnect_21/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m22_axi [get_bd_intf_pins kernel_0/m22_axi] [get_bd_intf_pins smartconnect_22/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m23_axi [get_bd_intf_pins kernel_0/m23_axi] [get_bd_intf_pins smartconnect_23/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m24_axi [get_bd_intf_pins kernel_0/m24_axi] [get_bd_intf_pins smartconnect_24/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m25_axi [get_bd_intf_pins kernel_0/m25_axi] [get_bd_intf_pins smartconnect_25/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m26_axi [get_bd_intf_pins kernel_0/m26_axi] [get_bd_intf_pins smartconnect_26/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m27_axi [get_bd_intf_pins kernel_0/m27_axi] [get_bd_intf_pins smartconnect_27/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m28_axi [get_bd_intf_pins kernel_0/m28_axi] [get_bd_intf_pins smartconnect_28/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m29_axi [get_bd_intf_pins kernel_0/m29_axi] [get_bd_intf_pins smartconnect_29/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m30_axi [get_bd_intf_pins kernel_0/m30_axi] [get_bd_intf_pins smartconnect_30/S00_AXI]
  connect_bd_intf_net -intf_net kernel_0_m31_axi [get_bd_intf_pins kernel_0/m31_axi] [get_bd_intf_pins smartconnect_31/S00_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_10_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_10/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_10_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_10_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_10/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_10_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_11_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_11/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_11_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_11_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_11/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_11_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_12_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_12/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_12_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_12_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_12/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_12_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_13_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_13/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_13_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_13_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_13/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_13_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_14_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_14/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_14_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_14_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_14/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_14_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_15_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_15/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_15_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_15_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_15/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_15_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_16_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_16/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_16_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_16_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_16/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_16_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_17_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_17/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_17_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_17_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_17/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_17_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_18_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_18/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_18_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_18_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_18/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_18_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_19_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_19/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_19_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_19_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_19/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_19_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_1_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_1_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_20_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_20/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_20_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_20_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_20/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_20_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_21_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_21/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_21_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_21_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_21/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_21_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_22_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_22/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_22_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_22_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_22/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_22_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_23_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_23/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_23_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_23_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_23/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_23_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_24_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_24/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_24_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_24_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_24/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_24_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_25_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_25/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_25_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_25_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_25/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_25_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_26_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_26/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_26_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_26_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_26/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_26_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_27_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_27/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_27_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_27_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_27/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_27_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_28_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_28/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_28_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_28_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_28/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_28_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_29_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_29/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_29_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_29_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_29/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_29_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_2_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_2_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_30_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_30/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_30_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_30_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_30/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_30_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_31_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_31/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_31_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_31_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_31/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_31_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_3_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_3/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_3_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_3_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_3/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_3_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_4_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_4/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_4_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_4_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_4/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_4_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_5_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_5/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_5_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_5_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_5/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_5_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_6_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_6/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_6_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_6_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_6/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_6_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_7_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_7/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_7_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_7_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_7/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_7_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_8_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_8/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_8_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_8_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_8/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_8_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_9_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_9/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_9_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_9_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_9/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_9_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net s_axi_control_1 [get_bd_intf_ports s_axi_control] [get_bd_intf_pins kernel_0/s_axi_control]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_10_M00_AXI [get_bd_intf_pins axi_bram_ctrl_10/S_AXI] [get_bd_intf_pins smartconnect_10/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_11_M00_AXI [get_bd_intf_pins axi_bram_ctrl_11/S_AXI] [get_bd_intf_pins smartconnect_11/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_12_M00_AXI [get_bd_intf_pins axi_bram_ctrl_12/S_AXI] [get_bd_intf_pins smartconnect_12/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_13_M00_AXI [get_bd_intf_pins axi_bram_ctrl_13/S_AXI] [get_bd_intf_pins smartconnect_13/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_14_M00_AXI [get_bd_intf_pins axi_bram_ctrl_14/S_AXI] [get_bd_intf_pins smartconnect_14/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_15_M00_AXI [get_bd_intf_pins axi_bram_ctrl_15/S_AXI] [get_bd_intf_pins smartconnect_15/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_16_M00_AXI [get_bd_intf_pins axi_bram_ctrl_16/S_AXI] [get_bd_intf_pins smartconnect_16/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_17_M00_AXI [get_bd_intf_pins axi_bram_ctrl_17/S_AXI] [get_bd_intf_pins smartconnect_17/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_18_M00_AXI [get_bd_intf_pins axi_bram_ctrl_18/S_AXI] [get_bd_intf_pins smartconnect_18/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_19_M00_AXI [get_bd_intf_pins axi_bram_ctrl_19/S_AXI] [get_bd_intf_pins smartconnect_19/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M00_AXI [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins smartconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_20_M00_AXI [get_bd_intf_pins axi_bram_ctrl_20/S_AXI] [get_bd_intf_pins smartconnect_20/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_21_M00_AXI [get_bd_intf_pins axi_bram_ctrl_21/S_AXI] [get_bd_intf_pins smartconnect_21/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_22_M00_AXI [get_bd_intf_pins axi_bram_ctrl_22/S_AXI] [get_bd_intf_pins smartconnect_22/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_23_M00_AXI [get_bd_intf_pins axi_bram_ctrl_23/S_AXI] [get_bd_intf_pins smartconnect_23/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_24_M00_AXI [get_bd_intf_pins axi_bram_ctrl_24/S_AXI] [get_bd_intf_pins smartconnect_24/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_25_M00_AXI [get_bd_intf_pins axi_bram_ctrl_25/S_AXI] [get_bd_intf_pins smartconnect_25/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_26_M00_AXI [get_bd_intf_pins axi_bram_ctrl_26/S_AXI] [get_bd_intf_pins smartconnect_26/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_27_M00_AXI [get_bd_intf_pins axi_bram_ctrl_27/S_AXI] [get_bd_intf_pins smartconnect_27/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_28_M00_AXI [get_bd_intf_pins axi_bram_ctrl_28/S_AXI] [get_bd_intf_pins smartconnect_28/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_29_M00_AXI [get_bd_intf_pins axi_bram_ctrl_29/S_AXI] [get_bd_intf_pins smartconnect_29/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_2_M00_AXI [get_bd_intf_pins axi_bram_ctrl_2/S_AXI] [get_bd_intf_pins smartconnect_2/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_30_M00_AXI [get_bd_intf_pins axi_bram_ctrl_30/S_AXI] [get_bd_intf_pins smartconnect_30/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_31_M00_AXI [get_bd_intf_pins axi_bram_ctrl_31/S_AXI] [get_bd_intf_pins smartconnect_31/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_3_M00_AXI [get_bd_intf_pins axi_bram_ctrl_3/S_AXI] [get_bd_intf_pins smartconnect_3/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_4_M00_AXI [get_bd_intf_pins axi_bram_ctrl_4/S_AXI] [get_bd_intf_pins smartconnect_4/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_5_M00_AXI [get_bd_intf_pins axi_bram_ctrl_5/S_AXI] [get_bd_intf_pins smartconnect_5/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_6_M00_AXI [get_bd_intf_pins axi_bram_ctrl_6/S_AXI] [get_bd_intf_pins smartconnect_6/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_7_M00_AXI [get_bd_intf_pins axi_bram_ctrl_7/S_AXI] [get_bd_intf_pins smartconnect_7/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_8_M00_AXI [get_bd_intf_pins axi_bram_ctrl_8/S_AXI] [get_bd_intf_pins smartconnect_8/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_9_M00_AXI [get_bd_intf_pins axi_bram_ctrl_9/S_AXI] [get_bd_intf_pins smartconnect_9/M00_AXI]

  # Create port connections
  connect_bd_net -net Net [get_bd_ports clk] [get_bd_pins kernel_0/ap_clk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins axi_bram_ctrl_10/s_axi_aclk] [get_bd_pins axi_bram_ctrl_11/s_axi_aclk] [get_bd_pins axi_bram_ctrl_12/s_axi_aclk] [get_bd_pins axi_bram_ctrl_13/s_axi_aclk] [get_bd_pins axi_bram_ctrl_14/s_axi_aclk] [get_bd_pins axi_bram_ctrl_15/s_axi_aclk] [get_bd_pins axi_bram_ctrl_16/s_axi_aclk] [get_bd_pins axi_bram_ctrl_17/s_axi_aclk] [get_bd_pins axi_bram_ctrl_18/s_axi_aclk] [get_bd_pins axi_bram_ctrl_19/s_axi_aclk] [get_bd_pins axi_bram_ctrl_2/s_axi_aclk] [get_bd_pins axi_bram_ctrl_20/s_axi_aclk] [get_bd_pins axi_bram_ctrl_21/s_axi_aclk] [get_bd_pins axi_bram_ctrl_22/s_axi_aclk] [get_bd_pins axi_bram_ctrl_23/s_axi_aclk] [get_bd_pins axi_bram_ctrl_24/s_axi_aclk] [get_bd_pins axi_bram_ctrl_25/s_axi_aclk] [get_bd_pins axi_bram_ctrl_26/s_axi_aclk] [get_bd_pins axi_bram_ctrl_27/s_axi_aclk] [get_bd_pins axi_bram_ctrl_28/s_axi_aclk] [get_bd_pins axi_bram_ctrl_29/s_axi_aclk] [get_bd_pins axi_bram_ctrl_3/s_axi_aclk] [get_bd_pins axi_bram_ctrl_30/s_axi_aclk] [get_bd_pins axi_bram_ctrl_31/s_axi_aclk] [get_bd_pins axi_bram_ctrl_4/s_axi_aclk] [get_bd_pins axi_bram_ctrl_5/s_axi_aclk] [get_bd_pins axi_bram_ctrl_6/s_axi_aclk] [get_bd_pins axi_bram_ctrl_7/s_axi_aclk] [get_bd_pins axi_bram_ctrl_8/s_axi_aclk] [get_bd_pins axi_bram_ctrl_9/s_axi_aclk] [get_bd_pins axi_protocol_checker_tb/aclk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins smartconnect_1/aclk] [get_bd_pins smartconnect_10/aclk] [get_bd_pins smartconnect_11/aclk] [get_bd_pins smartconnect_12/aclk] [get_bd_pins smartconnect_13/aclk] [get_bd_pins smartconnect_14/aclk] [get_bd_pins smartconnect_15/aclk] [get_bd_pins smartconnect_16/aclk] [get_bd_pins smartconnect_17/aclk] [get_bd_pins smartconnect_18/aclk] [get_bd_pins smartconnect_19/aclk] [get_bd_pins smartconnect_2/aclk] [get_bd_pins smartconnect_20/aclk] [get_bd_pins smartconnect_21/aclk] [get_bd_pins smartconnect_22/aclk] [get_bd_pins smartconnect_23/aclk] [get_bd_pins smartconnect_24/aclk] [get_bd_pins smartconnect_25/aclk] [get_bd_pins smartconnect_26/aclk] [get_bd_pins smartconnect_27/aclk] [get_bd_pins smartconnect_28/aclk] [get_bd_pins smartconnect_29/aclk] [get_bd_pins smartconnect_3/aclk] [get_bd_pins smartconnect_30/aclk] [get_bd_pins smartconnect_31/aclk] [get_bd_pins smartconnect_4/aclk] [get_bd_pins smartconnect_5/aclk] [get_bd_pins smartconnect_6/aclk] [get_bd_pins smartconnect_7/aclk] [get_bd_pins smartconnect_8/aclk] [get_bd_pins smartconnect_9/aclk]
  connect_bd_net -net Net1 [get_bd_ports resetn] [get_bd_pins kernel_0/ap_rst_n] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_10/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_11/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_12/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_13/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_14/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_15/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_16/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_17/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_18/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_19/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_20/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_21/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_22/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_23/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_24/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_25/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_26/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_27/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_28/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_29/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_3/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_30/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_31/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_4/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_5/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_6/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_7/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_8/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_9/s_axi_aresetn] [get_bd_pins axi_protocol_checker_tb/aresetn] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins smartconnect_1/aresetn] [get_bd_pins smartconnect_10/aresetn] [get_bd_pins smartconnect_11/aresetn] [get_bd_pins smartconnect_12/aresetn] [get_bd_pins smartconnect_13/aresetn] [get_bd_pins smartconnect_14/aresetn] [get_bd_pins smartconnect_15/aresetn] [get_bd_pins smartconnect_16/aresetn] [get_bd_pins smartconnect_17/aresetn] [get_bd_pins smartconnect_18/aresetn] [get_bd_pins smartconnect_19/aresetn] [get_bd_pins smartconnect_2/aresetn] [get_bd_pins smartconnect_20/aresetn] [get_bd_pins smartconnect_21/aresetn] [get_bd_pins smartconnect_22/aresetn] [get_bd_pins smartconnect_23/aresetn] [get_bd_pins smartconnect_24/aresetn] [get_bd_pins smartconnect_25/aresetn] [get_bd_pins smartconnect_26/aresetn] [get_bd_pins smartconnect_27/aresetn] [get_bd_pins smartconnect_28/aresetn] [get_bd_pins smartconnect_29/aresetn] [get_bd_pins smartconnect_3/aresetn] [get_bd_pins smartconnect_30/aresetn] [get_bd_pins smartconnect_31/aresetn] [get_bd_pins smartconnect_4/aresetn] [get_bd_pins smartconnect_5/aresetn] [get_bd_pins smartconnect_6/aresetn] [get_bd_pins smartconnect_7/aresetn] [get_bd_pins smartconnect_8/aresetn] [get_bd_pins smartconnect_9/aresetn]
  connect_bd_net -net kernel_0_interrupt [get_bd_ports interrupt] [get_bd_pins kernel_0/interrupt]
  connect_bd_net -net axi_protocol_checker_tb_pc_asserted [get_bd_ports pc_asserted] [get_bd_pins axi_protocol_checker_tb/pc_asserted]
  connect_bd_net -net axi_protocol_checker_tb_pc_status [get_bd_ports pc_status] [get_bd_pins axi_protocol_checker_tb/pc_status]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m00_axi] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m10_axi] [get_bd_addr_segs axi_bram_ctrl_10/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m11_axi] [get_bd_addr_segs axi_bram_ctrl_11/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m12_axi] [get_bd_addr_segs axi_bram_ctrl_12/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m13_axi] [get_bd_addr_segs axi_bram_ctrl_13/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m14_axi] [get_bd_addr_segs axi_bram_ctrl_14/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m15_axi] [get_bd_addr_segs axi_bram_ctrl_15/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m16_axi] [get_bd_addr_segs axi_bram_ctrl_16/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m17_axi] [get_bd_addr_segs axi_bram_ctrl_17/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m18_axi] [get_bd_addr_segs axi_bram_ctrl_18/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m19_axi] [get_bd_addr_segs axi_bram_ctrl_19/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m01_axi] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m20_axi] [get_bd_addr_segs axi_bram_ctrl_20/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m21_axi] [get_bd_addr_segs axi_bram_ctrl_21/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m22_axi] [get_bd_addr_segs axi_bram_ctrl_22/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m23_axi] [get_bd_addr_segs axi_bram_ctrl_23/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m24_axi] [get_bd_addr_segs axi_bram_ctrl_24/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m25_axi] [get_bd_addr_segs axi_bram_ctrl_25/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m26_axi] [get_bd_addr_segs axi_bram_ctrl_26/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m27_axi] [get_bd_addr_segs axi_bram_ctrl_27/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m28_axi] [get_bd_addr_segs axi_bram_ctrl_28/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m29_axi] [get_bd_addr_segs axi_bram_ctrl_29/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m02_axi] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m30_axi] [get_bd_addr_segs axi_bram_ctrl_30/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m31_axi] [get_bd_addr_segs axi_bram_ctrl_31/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m03_axi] [get_bd_addr_segs axi_bram_ctrl_3/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m04_axi] [get_bd_addr_segs axi_bram_ctrl_4/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m05_axi] [get_bd_addr_segs axi_bram_ctrl_5/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m06_axi] [get_bd_addr_segs axi_bram_ctrl_6/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m07_axi] [get_bd_addr_segs axi_bram_ctrl_7/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m08_axi] [get_bd_addr_segs axi_bram_ctrl_8/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces kernel_0/m09_axi] [get_bd_addr_segs axi_bram_ctrl_9/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces s_axi_control] [get_bd_addr_segs kernel_0/s_axi_control/reg0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_gid_msg -ssname BD::TCL -id 2053 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

