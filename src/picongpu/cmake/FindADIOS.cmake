# - Find ADIOS library, routines for scientific, parallel IO
#   https://www.olcf.ornl.gov/center-projects/adios/
#
# Use this module by invoking find_package with the form:
#   find_package(ADIOS
#     [version] [EXACT]     # Minimum or EXACT version, e.g. 1.6.0
#     [REQUIRED]            # Fail with an error if ADIOS or a required
#                           #   component is not found
#     [QUIET]               # ...
#     [COMPONENTS <...>]    # Compiled in components, ignored
#   )
#
# Module that finds the includes and libraries for a working ADIOS install.
# This module invokes the `adios_config` script that should be installed with
# the other ADIOS tools.
#
# To provide a hint to the module where to find the ADIOS installation,
# set the ADIOS_ROOT environment variable.
#
# This module will define the following variables:
#   ADIOS_INCLUDE_DIRS   - Include directories for the ADIOS headers.
#   ADIOS_LIBRARIES      - ADIOS libraries.
#   ADIOS_FOUND          - TRUE if FindADIOS found a working install
#   ADIOS_VERSION        - Version in format Major.Minor.Patch
#
# Not used for now:
#   ADIOS_DEFINITIONS    - Compiler definitions you should add with
#                          add_definitions(${ADIOS_DEFINITIONS})
#

################################################################################
# Copyright 2014 Axel Huebl, Felix Schmitt                          
#
# This file is part of PIConGPU.
#
# PIConGPU is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PIConGPU is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PIConGPU.
# If not, see <http://www.gnu.org/licenses/>.
################################################################################

################################################################################
# Required cmake version
################################################################################

cmake_minimum_required(VERSION 2.8.5)


################################################################################
# ADIOS
################################################################################

# we start by assuming we found ADIOS and falsify it if some
# dependencies are missing (or if we did not find ADIOS at all)
set(ADIOS_FOUND TRUE)

# check at ADIOS_ROOT
find_path(ADIOS_ROOT_DIR
  NAMES include/adios.h lib/libadios.so
  PATHS ENV ADIOS_ROOT
  DOC "ADIOS ROOT location"
)

# check `adios_config` program
execute_process(COMMAND adios_config -l
                OUTPUT_VARIABLE ADIOS_LINKFLAGS
                RESULT_VARIABLE ADIOS_CONFIG_RETURN)
if(NOT ADIOS_CONFIG_RETURN EQUAL 0)
    set(ADIOS_CONFIG_RETURN FALSE)
    message(STATUS "Can NOT find adios_config helper - check your PATH")
else()
    set(ADIOS_CONFIG_RETURN TRUE)
    # trim trailing newlines
    string(REGEX REPLACE "(\r?\n)+$" "" ADIOS_LINKFLAGS "${ADIOS_LINKFLAGS}")
endif()

# we found something in ADIOS_ROOT and adios_config works
if(ADIOS_ROOT_DIR AND ADIOS_CONFIG_RETURN)
    # ADIOS headers
    list(APPEND ADIOS_INCLUDE_DIRS ${ADIOS_ROOT_DIR}/include)

    # check for compiled in dependencies
    message(STATUS "ADIOS linker flags (unparsed): ${ADIOS_LINKFLAGS}")

    # find all library paths -L
    set(ADIOS_LIBRARY_DIRS "")# ${CMAKE_PREFIX_PATH}
    string(REGEX MATCHALL "-L([A-Za-z_0-9/\\.-]+)" _ADIOS_LIBDIRS "${ADIOS_LINKFLAGS}")
    foreach(_LIBDIR ${_ADIOS_LIBDIRS})
        string(REPLACE "-L" "" _LIBDIR ${_LIBDIR})
        list(APPEND ADIOS_LIBRARY_DIRS ${_LIBDIR})
    endforeach()

    #message(STATUS "ADIOS DIRS to look for libs: ${ADIOS_LIBRARY_DIRS}")

    # parse all -lname libraries and find an absolute path for them
    string(REGEX MATCHALL "-l([A-Za-z_0-9\\.-]+)" _ADIOS_LIBS "${ADIOS_LINKFLAGS}")

    foreach(_LIB ${_ADIOS_LIBS})
        string(REPLACE "-l" "lib" _LIB ${_LIB})

        # find static lib: absolute path in -L then default
        set(_LE "a")
        unset(_LIB_DIR CACHE)
        unset(_LIB_DIR)
        set(_LIB_PREF "")
        find_path(_LIB_DIR NAMES "${_LIB}.${_LE}" PATHS ${ADIOS_LIBRARY_DIRS})
        if(NOT _LIB_DIR)
            set(_LIB_PREF "lib/")
            find_path(_LIB_DIR NAMES "${_LIB_PREF}${_LIB}.${_LE}")
        endif(NOT _LIB_DIR)

        # not found? find shared lib!
        if(NOT _LIB_DIR)
            set(_LE "so")
            set(_LIB_PREF "")
            find_path(_LIB_DIR NAMES "${_LIB}.${_LE}" PATHS ${ADIOS_LIBRARY_DIRS})
            if(NOT _LIB_DIR)
                set(_LIB_PREF "lib/")
                find_path(_LIB_DIR NAMES "${_LIB_PREF}${_LIB}.${_LE}")
            endif(NOT _LIB_DIR)
        endif(NOT _LIB_DIR)

        # found?
        if(_LIB_DIR)
            message(STATUS "Found ${_LIB} in ${_LIB_DIR}/${_LIB_PREF}")
            list(APPEND ADIOS_LIBRARIES "${_LIB_DIR}/${_LIB_PREF}${_LIB}.${_LE}")
        else(_LIB_DIR)
            set(ADIOS_FOUND FALSE)
            message(STATUS "ADIOS: Could NOT find library '${_LIB}.a'/'${_LIB}.so'")
        endif(_LIB_DIR)

    endforeach()

    # simplify lists and check for missing components (not implemented)
    set(ADIOS_MISSING_COMPONENTS "")
    foreach(COMPONENT ${ADIOS_FIND_COMPONENTS})
        string(TOUPPER ${COMPONENT} COMPONENT)
        list(APPEND ADIOS_MISSING_COMPONENTS ${COMPONENT})
    endforeach()
    #message(STATUS "ADIOS required components: ${ADIOS_FIND_COMPONENTS}")

    # add the version string
    execute_process(COMMAND adios_config -v
                    OUTPUT_VARIABLE ADIOS_VERSION)
    # trim trailing newlines
    string(REGEX REPLACE "(\r?\n)+$" "" ADIOS_VERSION "${ADIOS_VERSION}")

else(ADIOS_ROOT_DIR AND ADIOS_CONFIG_RETURN)
    set(ADIOS_FOUND FALSE)
endif(ADIOS_ROOT_DIR AND ADIOS_CONFIG_RETURN)

# unset checked variables if not found
if(NOT ADIOS_FOUND)
    unset(ADIOS_INCLUDE_DIRS)
    unset(ADIOS_LIBRARIES)
endif(NOT ADIOS_FOUND)


################################################################################
# FindPackage Options
################################################################################

# handles the REQUIRED, QUIET and version-related arguments for find_package
find_package_handle_standard_args(ADIOS
    REQUIRED_VARS ADIOS_LIBRARIES ADIOS_INCLUDE_DIRS
    VERSION_VAR ADIOS_VERSION
)
