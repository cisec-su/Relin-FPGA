if { $::argc < 5 } {
  puts "ERROR: package.tcl requires (at least) 5 arguments:\n"
  puts "<kernel_name> <target> <part> <build_dir> <temp_dir> <for_sim>\n"
  exit
}

set kernel_name [lindex $::argv 0]
set target      [lindex $::argv 1]
set part        [lindex $::argv 2]
set build_dir   [lindex $::argv 3]
set temp_dir    [lindex $::argv 4]
set for_sim     [expr {$::argc eq 6 ? yes : no}]

puts $kernel_name
puts $target
puts $part
puts $build_dir
puts $temp_dir
puts $for_sim 

set project_dir "[exec pwd]"
set kernel_dir  "${project_dir}/src/rtl/${kernel_name}"
set xo_path     "${build_dir}/${kernel_name}.xo"

set path_to_tmp_project "${temp_dir}/_${kernel_name}"
set path_to_packaged    "${temp_dir}/${kernel_name}"

set ::argv [list ${kernel_dir} ${part} ${path_to_tmp_project} ${path_to_packaged} ${for_sim}]
source "$kernel_dir/project.tcl"

if {$for_sim == no} { 
  package_xo                                \
    -xo_path      ${xo_path}                \
    -kernel_name  ${kernel_name}            \
    -ip_directory ${path_to_packaged}       \
    -kernel_xml   ${kernel_dir}/kernel.xml  \
    -verbose                                \
    -force
}